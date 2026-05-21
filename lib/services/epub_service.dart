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

    void walk(epubx.EpubChapter? chapter, int depth) {
      if (chapter == null) return;
      final html = chapter.HtmlContent?.Text;
      if (html != null && html.trim().isNotEmpty) {
        final name = chapter.Title?.trim().isNotEmpty == true
            ? chapter.Title!.trim()
            : 'Глава ${chapters.length + 1}';
        chapters.add(BookChapter(title: name, html: html));
      }
      if (chapter.SubChapters != null) {
        for (final sub in chapter.SubChapters!) {
          walk(sub, depth + 1);
        }
      }
    }

    if (epub.Chapters != null) {
      for (final ch in epub.Chapters!) {
        walk(ch, 0);
      }
    }

    if (chapters.isEmpty) {
      chapters.add(BookChapter(
        title: 'Содержание',
        html: '<p>Не удалось извлечь текст из этой книги.</p>',
      ));
    }

    return EpubBookData(title: title, author: author, chapters: chapters);
  }

  String _fileName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    if (name.toLowerCase().endsWith('.epub')) {
      return name.substring(0, name.length - 5);
    }
    return name;
  }
}
