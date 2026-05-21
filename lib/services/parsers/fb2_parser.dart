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

    final title = book.title?.trim().isNotEmpty == true
        ? book.title!.trim()
        : _fileName(filePath);
    final author = book.author?.trim().isNotEmpty == true
        ? book.author!.trim()
        : 'Неизвестный автор';

    final chapters = <BookChapter>[];
    final body = book.body;
    if (body == null) {
      throw const FormatException('FB2: пустое тело книги');
    }
    final sections = body.sections;
    if (sections != null) {
      for (var i = 0; i < sections.length; i++) {
        final section = sections[i];
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
      final bodyHtml = body.content?.trim() ?? '';
      if (HtmlUtils.hasReadableText(bodyHtml)) {
        chapters.add(
          BookChapter(
            title: title,
            html: HtmlUtils.wrapDocument(bodyHtml),
          ),
        );
      }
    }

    if (chapters.isEmpty) {
      throw const FormatException('FB2: текст книги не найден');
    }

    return ParsedBook(title: title, author: author, chapters: chapters);
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
