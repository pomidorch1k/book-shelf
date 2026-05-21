import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/epub_service.dart';
import '../theme/app_theme.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});

  final BookItem book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  EpubBookData? _data;
  bool _loading = true;
  int _chapterIndex = 0;
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
    super.dispose();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    try {
      final data = await state.epubService.loadBook(widget.book.filePath);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
          if (_chapterIndex >= data.chapters.length) {
            _chapterIndex = 0;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDark;
    final readerTheme = AppTheme.readerTheme(isDark);

    return PopScope(
      onPopInvokedWithResult: (_, __) => _saveProgress(),
      child: Scaffold(
        backgroundColor: readerTheme.background,
        appBar: AppBar(
          backgroundColor: readerTheme.background,
          foregroundColor: readerTheme.text,
          title: Text(
            widget.book.title,
            style: TextStyle(color: readerTheme.text, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.brightness_6_outlined, color: readerTheme.text),
              onPressed: () => context.read<AppState>().toggleTheme(),
            ),
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: readerTheme.accent))
            : _data == null
                ? Center(
                    child: Text('Ошибка загрузки книги', style: TextStyle(color: readerTheme.text)),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              style: TextStyle(color: readerTheme.text.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Html(
                            data: _data!.chapters[_chapterIndex].html,
                            style: {
                              'body': Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontSize: FontSize(18),
                                lineHeight: const LineHeight(1.65),
                                color: readerTheme.text,
                              ),
                              'p': Style(margin: Margins.only(bottom: 14)),
                              'h1': Style(
                                color: readerTheme.accent,
                                fontWeight: FontWeight.w800,
                              ),
                              'h2': Style(
                                color: readerTheme.accent,
                                fontWeight: FontWeight.w700,
                              ),
                              'a': Style(color: readerTheme.accent),
                            },
                          ),
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
          top: BorderSide(color: readerTheme.text.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _chapterIndex > 0
                ? () {
                    setState(() => _chapterIndex--);
                    _saveProgress();
                  }
                : null,
            icon: Icon(Icons.chevron_left_rounded, color: readerTheme.text, size: 36),
          ),
          Expanded(
            child: Slider(
              value: _chapterIndex.toDouble(),
              min: 0,
              max: (_data!.chapters.length - 1).toDouble(),
              divisions: _data!.chapters.length > 1 ? _data!.chapters.length - 1 : 1,
              activeColor: readerTheme.accent,
              inactiveColor: readerTheme.text.withValues(alpha: 0.2),
              onChanged: (v) {
                setState(() => _chapterIndex = v.round());
                _saveProgress();
              },
            ),
          ),
          IconButton(
            onPressed: _chapterIndex < _data!.chapters.length - 1
                ? () {
                    setState(() => _chapterIndex++);
                    _saveProgress();
                    if (_chapterIndex == _data!.chapters.length - 1) {
                      context.read<AppState>().recordReadingSession(minutes: 5);
                    }
                  }
                : null,
            icon: Icon(Icons.chevron_right_rounded, color: readerTheme.text, size: 36),
          ),
        ],
      ),
    );
  }
}
