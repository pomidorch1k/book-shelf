import 'dart:convert';
import 'dart:io';

import 'package:dart_mobi/dart_mobi.dart';
import 'package:path/path.dart' as p;

import '../../models/book_content.dart';
import 'html_utils.dart';

class MobiParser {
  Future<ParsedBook> parse(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final mobiData = await DartMobiReader.read(bytes);
    final rawml = mobiData.parseOpt(true, true, false);

    if (rawml.markup?.data == null) {
      throw const FormatException('MOBI: не удалось извлечь текст');
    }

    final html = utf8.decode(
      List<int>.from(rawml.markup!.data!),
      allowMalformed: true,
    );

    final title = HtmlUtils.extractTitle(html) ?? _fileName(filePath);
    const author = 'Неизвестный автор';

    final chapters = _splitIntoChapters(html);
    if (chapters.isEmpty) {
      throw const FormatException('MOBI: текст книги не найден');
    }

    return ParsedBook(title: title, author: author, chapters: chapters);
  }

  List<BookChapter> _splitIntoChapters(String html) {
    final normalized = html.replaceAll('\r\n', '\n');
    final breakPattern = RegExp(
      r'<mbp:pagebreak\s*/?>|<hr[^>]*class="[^"]*chapter[^"]*"[^>]*>',
      caseSensitive: false,
    );
    final parts = normalized.split(breakPattern);

    if (parts.length > 1) {
      final chapters = <BookChapter>[];
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i].trim();
        if (!HtmlUtils.hasReadableText(part)) continue;
        chapters.add(
          BookChapter(
            title: HtmlUtils.extractTitle(part) ?? 'Часть ${chapters.length + 1}',
            html: HtmlUtils.wrapDocument(part),
          ),
        );
      }
      if (chapters.isNotEmpty) return chapters;
    }

    final h2Parts = normalized.split(RegExp(r'(?=<h2[^>]*>)', caseSensitive: false));
    if (h2Parts.length > 1) {
      final chapters = <BookChapter>[];
      for (final part in h2Parts) {
        final trimmed = part.trim();
        if (!HtmlUtils.hasReadableText(trimmed)) continue;
        chapters.add(
          BookChapter(
            title: HtmlUtils.extractTitle(trimmed) ?? 'Глава ${chapters.length + 1}',
            html: HtmlUtils.wrapDocument(trimmed),
          ),
        );
      }
      if (chapters.isNotEmpty) return chapters;
    }

    if (HtmlUtils.hasReadableText(normalized)) {
      return [
        BookChapter(
          title: 'Книга',
          html: HtmlUtils.wrapDocument(normalized),
        ),
      ];
    }

    return [];
  }

  String _fileName(String path) {
    final name = p.basename(path);
    final lower = name.toLowerCase();
    for (final ext in ['.mobi', '.azw', '.azw3']) {
      if (lower.endsWith(ext)) {
        return name.substring(0, name.length - ext.length);
      }
    }
    return p.basenameWithoutExtension(path);
  }
}
