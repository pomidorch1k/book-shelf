import 'dart:async';

import 'package:flutter/material.dart';
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
  bool _loading = true;
  String? _error;
  List<String> _pages = [];
  int _pageIndex = 0;
  Timer? _readTimer;
  late final PageController _pageController =
      PageController(initialPage: widget.book.lastChapterIndex);

  Size? _lastPageSize;
  ReaderSettings? _lastSettings;

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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    try {
      final data = await state.bookLoader.loadBook(widget.book.filePath);
      if (mounted) {
        setState(() {
          _data = data;
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

  void _paginate(Size pageSize, ReaderSettings settings) {
    if (_data == null) return;

    final textStyle = TextStyle(
      fontSize: settings.fontSize,
      height: settings.lineHeight,
      color: AppTheme.readerTheme(settings, context.read<AppState>().isDark).text,
    );

    final horizontal = settings.horizontalPadding * 2;
    final verticalReserve = 8.0;

    _pages = ReaderPaginator.paginate(
      text: _buildFullText(_data!),
      style: textStyle,
      maxWidth: pageSize.width - horizontal,
      maxHeight: pageSize.height - verticalReserve,
    );

    if (_pages.isEmpty) {
      _pages = ['Текст книги не найден.'];
    }

    final maxIndex = _pages.length - 1;
    if (_pageIndex > maxIndex) _pageIndex = maxIndex;
    if (_pageIndex < 0) _pageIndex = 0;

    _lastPageSize = pageSize;
    _lastSettings = settings.copyWith();
  }

  void _saveProgress() {
    if (_pages.isEmpty) return;
    context.read<AppState>().updateBookProgress(
          widget.book.id,
          _pageIndex,
          (_pageIndex + 1) / _pages.length,
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
          setState(() {
            _lastPageSize = null;
            _lastSettings = null;
          });
        }
      }),
    );
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() => _pageIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.readerSettings;
    final readerTheme = AppTheme.readerTheme(settings, state.isDark);

    return PopScope(
      onPopInvokedWithResult: (_, __) => _saveProgress(),
      child: Scaffold(
        backgroundColor: readerTheme.background,
        appBar: AppBar(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Страница',
                                  style: TextStyle(
                                    color: readerTheme.text.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _pages.isEmpty
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
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final pageSize = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );

                                final settingsChanged = _lastSettings == null ||
                                    _lastSettings!.fontSize != settings.fontSize ||
                                    _lastSettings!.lineHeight != settings.lineHeight ||
                                    _lastSettings!.horizontalPadding !=
                                        settings.horizontalPadding ||
                                    _lastSettings!.readerTheme != settings.readerTheme;

                                if (_lastPageSize != pageSize || settingsChanged) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    setState(() {
                                      _paginate(pageSize, settings);
                                      if (_pageController.hasClients &&
                                          _pageController.page?.round() != _pageIndex) {
                                        _pageController.jumpToPage(_pageIndex);
                                      }
                                    });
                                  });
                                }

                                if (_pages.isEmpty) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                return PageView.builder(
                                  controller: _pageController,
                                  itemCount: _pages.length,
                                  onPageChanged: (index) {
                                    setState(() => _pageIndex = index);
                                    _saveProgress();
                                    if (index == _pages.length - 1) {
                                      context
                                          .read<AppState>()
                                          .recordReadingSession(minutes: 5);
                                    }
                                  },
                                  itemBuilder: (_, index) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: settings.horizontalPadding,
                                      ),
                                      child: SingleChildScrollView(
                                        physics: const NeverScrollableScrollPhysics(),
                                        child: Text(
                                          _pages[index],
                                          style: TextStyle(
                                            fontSize: settings.fontSize,
                                            height: settings.lineHeight,
                                            color: readerTheme.text,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          _buildNav(readerTheme),
                        ],
                      ),
      ),
    );
  }

  Widget _buildNav(ReaderTheme readerTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
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
                    value: _pageIndex.toDouble(),
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
