import 'dart:io';

import 'package:epubx/epubx.dart' as epubx;

class BookChapter {
  BookChapter({required this.title, required this.html});
  final String title;
  final String html;
}

class EpubBookData {
  EpubBookData({
    required this.title,
    required this.author,
    required this.chapters,
  });

  final String title;
  final String author;
  final List<BookChapter> chapters;
}

class EpubService {
  Future<EpubBookData> loadBook(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final epub = await epubx.EpubReader.readBook(bytes);

    final title = epub.Title?.trim().isNotEmpty == true
        ? epub.Title!.trim()
        : _fileName(filePath);
    final author = epub.Author?.trim().isNotEmpty == true
        ? epub.Author!.trim()
        : 'Неизвестный автор';

    final chapters = <BookChapter>[];

    void walk(epubx.EpubChapter? chapter) {
      if (chapter == null) return;
      final html = _resolveChapterHtml(epub, chapter);
      if (html != null && _hasReadableText(html)) {
        final name = chapter.Title?.trim().isNotEmpty == true
            ? chapter.Title!.trim()
            : 'Глава ${chapters.length + 1}';
        chapters.add(BookChapter(title: name, html: _wrapHtml(html)));
      }
      if (chapter.SubChapters != null) {
        for (final sub in chapter.SubChapters!) {
          walk(sub);
        }
      }
    }

    if (epub.Chapters != null) {
      for (final ch in epub.Chapters!) {
        walk(ch);
      }
    }

    if (chapters.isEmpty) {
      chapters.addAll(_chaptersFromSpine(epub));
    }

    if (chapters.isEmpty) {
      chapters.add(BookChapter(
        title: 'Содержание',
        html: '<p>Не удалось извлечь текст из этой книги.</p>',
      ));
    }

    return EpubBookData(title: title, author: author, chapters: chapters);
  }

  List<BookChapter> _chaptersFromSpine(epubx.EpubBook epub) {
    final result = <BookChapter>[];
    final htmlFiles = epub.Content?.Html;
    if (htmlFiles == null) return result;

    var i = 0;
    for (final entry in htmlFiles.entries) {
      final content = entry.value.Content;
      if (content == null || !_hasReadableText(content)) continue;
      i++;
      result.add(BookChapter(
        title: 'Часть $i',
        html: _wrapHtml(content),
      ));
    }
    return result;
  }

  String? _resolveChapterHtml(epubx.EpubBook epub, epubx.EpubChapter chapter) {
    final inline = chapter.HtmlContent?.trim();
    if (inline != null && inline.isNotEmpty) {
      return inline;
    }

    final fileName = chapter.ContentFileName?.trim();
    if (fileName == null || fileName.isEmpty) return null;

    final htmlMap = epub.Content?.Html;
    if (htmlMap == null) return null;

    if (htmlMap.containsKey(fileName)) {
      return htmlMap[fileName]!.Content;
    }

    final normalized = fileName.replaceAll('\\', '/');
    for (final entry in htmlMap.entries) {
      final key = entry.key.replaceAll('\\', '/');
      if (key == normalized ||
          key.endsWith('/$normalized') ||
          normalized.endsWith('/$key') ||
          key.endsWith(normalized)) {
        return entry.value.Content;
      }
    }

    final allFiles = epub.Content?.AllFiles;
    if (allFiles != null) {
      for (final entry in allFiles.entries) {
        final key = entry.key.replaceAll('\\', '/');
        if (key.endsWith(normalized) || normalized.endsWith(key)) {
          final file = entry.value;
          if (file is epubx.EpubTextContentFile) {
            return file.Content;
          }
        }
      }
    }

    return null;
  }

  String _wrapHtml(String html) {
    final trimmed = html.trim();
    final lower = trimmed.toLowerCase();
    if (lower.contains('<body')) return trimmed;
    if (lower.contains('<html')) {
      return trimmed;
    }
    return '<html><head><meta charset="utf-8"></head><body>$trimmed</body></html>';
  }

  bool _hasReadableText(String html) {
    final text = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.length > 20;
  }

  String _fileName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    if (name.toLowerCase().endsWith('.epub')) {
      return name.substring(0, name.length - 5);
    }
    return name;
  }
}
