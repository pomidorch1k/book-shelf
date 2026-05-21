import 'dart:io';

import 'package:archive/archive.dart';
import 'package:fb2_parse/fb2_parse.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/book_content.dart';
import 'html_utils.dart';

class Fb2Parser {
  Future<ParsedBook> parse(String filePath) async {
    final resolvedPath = await _resolveFb2Path(filePath);
    final book = FB2Book(resolvedPath);
    await book.parse();

    final desc = book.description;
    final title = desc.bookTitle?.trim().isNotEmpty == true
        ? desc.bookTitle!.trim()
        : _fileName(filePath);
    var author = 'Неизвестный автор';
    if (desc.authors != null && desc.authors!.isNotEmpty) {
      final a = desc.authors!.first;
      final parts = <String>[];
      for (final field in [a.lastName, a.firstName, a.middleName]) {
        if (field != null && field.trim().isNotEmpty) {
          parts.add(field.trim());
        }
      }
      if (parts.isNotEmpty) {
        author = parts.join(' ');
      } else if (a.nickname != null && a.nickname!.trim().isNotEmpty) {
        author = a.nickname!.trim();
      }
    }

    final chapters = <BookChapter>[];
    final sections = book.body.sections;
    if (sections != null) {
      for (final section in sections) {
        final content = section.content?.trim() ?? '';
        if (!HtmlUtils.hasReadableText(content)) continue;
        final sectionTitle = section.title?.trim();
        chapters.add(
          BookChapter(
            title: sectionTitle?.isNotEmpty == true
                ? sectionTitle!
                : 'Глава ${chapters.length + 1}',
            html: HtmlUtils.wrapDocument(content),
          ),
        );
      }
    }

    if (chapters.isEmpty) {
      final fallback = await _chapterFromFlatBody(resolvedPath, book, title);
      if (fallback != null) chapters.add(fallback);
    }

    if (chapters.isEmpty) {
      throw const FormatException('FB2: текст книги не найден');
    }

    return ParsedBook(title: title, author: author, chapters: chapters);
  }

  Future<BookChapter?> _chapterFromFlatBody(
    String path,
    FB2Book book,
    String title,
  ) async {
    var res = await File(path).readAsString();

    res = res.replaceAllMapped(RegExp(r'<image([\s\S]+?)\/>'), (match) {
      final name = RegExp(r'="#([\s\S]+?)"')
          .firstMatch(match.group(1)!)
          ?.group(1);
      if (name == null) return match.group(0)!;
      for (final image in book.images) {
        if (image.name == name) {
          return '<img src="data:image/png;base64, ${image.bytes}"/>';
        }
      }
      return match.group(0)!;
    });

    res = res.replaceAllMapped(RegExp(r'<empty-line.?>'), (_) => '<br>');
    res = res.replaceAllMapped(
      RegExp(r'<a ([a-zA-Z:]*)href([\s\S]+?)>([\s\S]+?)<\/a>'),
      (match) => match.group(3) ?? '',
    );

    final bodyMatch = RegExp(r'<body>([\s\S]+)</body>').firstMatch(res);
    if (bodyMatch == null) return null;

    final content = bodyMatch.group(1)!.trim();
    if (!HtmlUtils.hasReadableText(content)) return null;

    final sectionTitle = RegExp(r'<title>([\s\S]+?)</title>')
        .firstMatch(content)
        ?.group(1)
        ?.trim();

    return BookChapter(
      title: sectionTitle?.isNotEmpty == true ? sectionTitle! : title,
      html: HtmlUtils.wrapDocument(content),
    );
  }

  Future<String> _resolveFb2Path(String filePath) async {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.fb2')) return filePath;

    if (lower.endsWith('.zip')) {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final fb2Entry = archive.files.firstWhere(
        (f) => f.isFile && f.name.toLowerCase().endsWith('.fb2'),
        orElse: () => throw const FormatException('ZIP: FB2 файл не найден'),
      );

      final dir = await getTemporaryDirectory();
      final out = File(p.join(dir.path, p.basename(fb2Entry.name)));
      await out.writeAsBytes(List<int>.from(fb2Entry.content));
      return out.path;
    }

    throw const FormatException('Неподдерживаемый формат FB2');
  }

  String _fileName(String path) {
    return p.basenameWithoutExtension(path);
  }
}
