import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../models/book_content.dart';
import '../models/models.dart';
import '../models/reader_settings.dart';
import '../providers/app_state.dart';
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
  int _chapterIndex = 0;
  bool _immersive = false;
  final _scrollController = ScrollController();

  Timer? _readTimer;

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.book.lastChapterIndex;
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
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
          if (_chapterIndex >= data.chapters.length) {
            _chapterIndex = 0;
          }
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

  void _saveProgress() {
    if (_data == null) return;
    final progress = (_chapterIndex + 1) / _data!.chapters.length;
    context.read<AppState>().updateBookProgress(
          widget.book.id,
          _chapterIndex,
          progress,
        );
  }

  void _toggleImmersive() {
    final next = !_immersive;
    setState(() => _immersive = next);
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
        if (mounted) setState(() {});
      }),
    );
  }

  void _goToChapter(int index) {
    if (_data == null || index < 0 || index >= _data!.chapters.length) return;
    setState(() => _chapterIndex = index);
    _saveProgress();
    if (index == _data!.chapters.length - 1) {
      context.read<AppState>().recordReadingSession(minutes: 5);
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
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
                                        Expanded(
                                          child: Text(
                                            _data!.chapters[_chapterIndex].title,
                                            style: TextStyle(
                                              color: readerTheme.text,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${_chapterIndex + 1}/${_data!.chapters.length}',
                                          style: TextStyle(
                                            color: readerTheme.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                _ChapterView(
                                  html: _data!.chapters[_chapterIndex].html,
                                  settings: settings,
                                  readerTheme: readerTheme,
                                  scrollController: _scrollController,
                                ),
                                Positioned.fill(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 25,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: _chapterIndex > 0
                                              ? () => _goToChapter(_chapterIndex - 1)
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
                                          onTap: _chapterIndex < _data!.chapters.length - 1
                                              ? () => _goToChapter(_chapterIndex + 1)
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
            onPressed: _chapterIndex > 0
                ? () => _goToChapter(_chapterIndex - 1)
                : null,
            icon: Icon(Icons.chevron_left_rounded, color: readerTheme.accent, size: 36),
          ),
          Expanded(
            child: _data!.chapters.length > 1
                ? Slider(
                    value: _chapterIndex.toDouble(),
                    min: 0,
                    max: (_data!.chapters.length - 1).toDouble(),
                    divisions: _data!.chapters.length - 1,
                    activeColor: readerTheme.accent,
                    inactiveColor: readerTheme.accent.withValues(alpha: 0.25),
                    onChanged: (v) => _goToChapter(v.round()),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            onPressed: _chapterIndex < _data!.chapters.length - 1
                ? () => _goToChapter(_chapterIndex + 1)
                : null,
            icon: Icon(Icons.chevron_right_rounded, color: readerTheme.accent, size: 36),
          ),
        ],
      ),
    );
  }
}

class _ChapterView extends StatelessWidget {
  const _ChapterView({
    required this.html,
    required this.settings,
    required this.readerTheme,
    required this.scrollController,
  });

  final String html;
  final ReaderSettings settings;
  final ReaderTheme readerTheme;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        settings.horizontalPadding,
        0,
        settings.horizontalPadding,
        24,
      ),
      child: Html(
        data: html,
        style: {
          'html': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          'body': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(settings.fontSize),
            lineHeight: LineHeight(settings.lineHeight),
            color: readerTheme.text,
          ),
          'p': Style(
            margin: Margins.only(bottom: 14),
            color: readerTheme.text,
          ),
          'div': Style(color: readerTheme.text),
          'span': Style(color: readerTheme.text),
          'li': Style(color: readerTheme.text),
          'h1': Style(
            color: readerTheme.accent,
            fontWeight: FontWeight.w800,
            fontSize: FontSize(settings.fontSize + 6),
          ),
          'h2': Style(
            color: readerTheme.accent,
            fontWeight: FontWeight.w700,
            fontSize: FontSize(settings.fontSize + 4),
          ),
          'h3': Style(
            color: readerTheme.accent,
            fontWeight: FontWeight.w600,
            fontSize: FontSize(settings.fontSize + 2),
          ),
          'a': Style(color: readerTheme.accent),
        },
      ),
    );
  }
}
