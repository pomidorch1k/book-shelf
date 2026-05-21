import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/book_content.dart';
import '../models/models.dart';
import '../models/reader_settings.dart';
import '../providers/app_state.dart';
import '../services/parsers/html_utils.dart';
import '../services/reader_paginator.dart';
import '../theme/app_theme.dart';
import '../widgets/reader_settings_sheet.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});

  final BookItem book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  ParsedBook? _data;
  String? _fullText;
  bool _loading = true;
  bool _paginating = false;
  String? _error;
  List<String> _pages = [];
  int _pageIndex = 0;
  bool _immersive = false;

  Timer? _readTimer;
  Timer? _saveDebounce;
  Timer? _repaginateDebounce;

  late final PageController _pageController =
      PageController(initialPage: widget.book.lastChapterIndex);

  Size? _cachedPageSize;
  String? _paginationCacheKey;
  TextStyle? _pageTextStyle;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.book.lastChapterIndex;
    _load();
    _readTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        context.read<AppState>().recordReadingSession(minutes: 1);
      }
    });
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _saveDebounce?.cancel();
    _repaginateDebounce?.cancel();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    try {
      final data = await state.bookLoader.loadBook(widget.book.filePath);
      final fullText = _buildFullText(data);
      if (mounted) {
        setState(() {
          _data = data;
          _fullText = fullText;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _buildFullText(ParsedBook data) {
    final buffer = StringBuffer();
    for (final chapter in data.chapters) {
      final plain = HtmlUtils.stripTags(chapter.html);
      if (plain.isEmpty) continue;
      if (chapter.title.trim().isNotEmpty) {
        buffer.writeln(chapter.title.trim());
        buffer.writeln();
      }
      buffer.writeln(plain);
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  String _paginationKey(Size pageSize, ReaderSettings settings) {
    return '${pageSize.width.toInt()}x${pageSize.height.toInt()}_'
        '${settings.fontSize}_${settings.lineHeight}_${settings.horizontalPadding}_'
        '${settings.readerTheme.name}';
  }

  void _scheduleRepagination(Size pageSize, ReaderSettings settings) {
    final key = _paginationKey(pageSize, settings);
    if (_paginationCacheKey == key && _pages.isNotEmpty) return;
    if (_fullText == null || _paginating) return;

    _repaginateDebounce?.cancel();
    _repaginateDebounce = Timer(const Duration(milliseconds: 120), () {
      _runPagination(pageSize, settings, key);
    });
  }

  Future<void> _runPagination(
    Size pageSize,
    ReaderSettings settings,
    String key,
  ) async {
    if (_fullText == null || !mounted) return;

    setState(() => _paginating = true);

    final readerTheme = AppTheme.readerTheme(
      settings,
      context.read<AppState>().isDark,
    );

    final horizontal = settings.horizontalPadding * 2;
    final request = PaginateRequest(
      text: _fullText!,
      fontSize: settings.fontSize,
      lineHeight: settings.lineHeight,
      maxWidth: pageSize.width - horizontal,
      maxHeight: pageSize.height - 8,
    );

    final pages = await ReaderPaginator.paginateAsync(request);

    if (!mounted) return;

    final safePages = pages.isEmpty ? ['Текст книги не найден.'] : pages;
    var pageIndex = _pageIndex;
    if (pageIndex >= safePages.length) pageIndex = safePages.length - 1;
    if (pageIndex < 0) pageIndex = 0;

    setState(() {
      _pages = safePages;
      _pageIndex = pageIndex;
      _paginating = false;
      _cachedPageSize = pageSize;
      _paginationCacheKey = key;
      _pageTextStyle = TextStyle(
        fontSize: settings.fontSize,
        height: settings.lineHeight,
        color: readerTheme.text,
      );
    });

    if (_pageController.hasClients && _pageController.page?.round() != pageIndex) {
      _pageController.jumpToPage(pageIndex);
    }
  }

  void _saveProgress() {
    if (_pages.isEmpty) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<AppState>().updateBookProgress(
            widget.book.id,
            _pageIndex,
            (_pageIndex + 1) / _pages.length,
          );
    });
  }

  void _toggleImmersive() {
    final next = !_immersive;
    setState(() {
      _immersive = next;
      _paginationCacheKey = null;
    });
    SystemChrome.setEnabledSystemUIMode(
      next ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _openReaderSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReaderSettingsSheet(onChanged: () {
        if (mounted) {
          setState(() => _paginationCacheKey = null);
        }
      }),
    );
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() => _pageIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.readerSettings;
    final readerTheme = AppTheme.readerTheme(settings, state.isDark);

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        _saveProgress();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Scaffold(
        backgroundColor: readerTheme.background,
        extendBodyBehindAppBar: _immersive,
        appBar: _immersive
            ? null
            : AppBar(
                backgroundColor: readerTheme.background,
                foregroundColor: readerTheme.text,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Text(
                  widget.book.title,
                  style: TextStyle(color: readerTheme.text, fontSize: 16),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: readerTheme.accent),
                    tooltip: 'Настройки читалки',
                    onPressed: _openReaderSettings,
                  ),
                ],
              ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: readerTheme.accent))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Ошибка: $_error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: readerTheme.text),
                      ),
                    ),
                  )
                : _data == null
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: _immersive
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Страница',
                                          style: TextStyle(
                                            color: readerTheme.text
                                                .withValues(alpha: 0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _paginating || _pages.isEmpty
                                              ? '...'
                                              : '${_pageIndex + 1} / ${_pages.length}',
                                          style: TextStyle(
                                            color: readerTheme.accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final pageSize = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
                                _scheduleRepagination(pageSize, settings);

                                return Stack(
                                  children: [
                                    if (_paginating && _pages.isEmpty)
                                      Center(
                                        child: CircularProgressIndicator(
                                          color: readerTheme.accent,
                                        ),
                                      )
                                    else if (_pages.isNotEmpty)
                                      PageView.builder(
                                        controller: _pageController,
                                        itemCount: _pages.length,
                                        allowImplicitScrolling: false,
                                        onPageChanged: (index) {
                                          setState(() => _pageIndex = index);
                                          _saveProgress();
                                        },
                                        itemBuilder: (_, index) {
                                          return RepaintBoundary(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    settings.horizontalPadding,
                                              ),
                                              child: Text(
                                                _pages[index],
                                                style: _pageTextStyle ??
                                                    TextStyle(
                                                      fontSize: settings.fontSize,
                                                      height: settings.lineHeight,
                                                      color: readerTheme.text,
                                                    ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    Positioned.fill(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 25,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.translucent,
                                              onTap: _pageIndex > 0
                                                  ? () => _goToPage(_pageIndex - 1)
                                                  : null,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 50,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.translucent,
                                              onTap: _toggleImmersive,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 25,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.translucent,
                                              onTap: _pageIndex < _pages.length - 1
                                                  ? () =>
                                                      _goToPage(_pageIndex + 1)
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: _immersive
                                ? const SizedBox.shrink()
                                : _buildNav(readerTheme),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildNav(ReaderTheme readerTheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: readerTheme.background,
        border: Border(
          top: BorderSide(color: readerTheme.accent.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _pageIndex > 0 ? () => _goToPage(_pageIndex - 1) : null,
            icon: Icon(Icons.chevron_left_rounded, color: readerTheme.accent, size: 36),
          ),
          Expanded(
            child: _pages.length > 1
                ? Slider(
                    value: _pageIndex.clamp(0, _pages.length - 1).toDouble(),
                    min: 0,
                    max: (_pages.length - 1).toDouble(),
                    divisions: _pages.length - 1,
                    activeColor: readerTheme.accent,
                    inactiveColor: readerTheme.accent.withValues(alpha: 0.25),
                    onChanged: (v) => _goToPage(v.round()),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            onPressed: _pageIndex < _pages.length - 1
                ? () => _goToPage(_pageIndex + 1)
                : null,
            icon: Icon(Icons.chevron_right_rounded, color: readerTheme.accent, size: 36),
          ),
        ],
      ),
    );
  }
}
