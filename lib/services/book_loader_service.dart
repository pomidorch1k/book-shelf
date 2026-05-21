import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/book_content.dart';
import 'parsers/epub_parser.dart';
import 'parsers/fb2_parser.dart';
import 'parsers/mobi_parser.dart';

enum BookFormat { epub, fb2, mobi, unknown }

class BookLoaderService {
  final _epub = EpubParser();
  final _fb2 = Fb2Parser();
  final _mobi = MobiParser();
  final _uuid = const Uuid();

  BookFormat formatFromPath(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.epub' => BookFormat.epub,
      '.fb2' => BookFormat.fb2,
      '.zip' => BookFormat.fb2,
      '.mobi' => BookFormat.mobi,
      '.azw' => BookFormat.mobi,
      '.azw3' => BookFormat.mobi,
      _ => BookFormat.unknown,
    };
  }

  Future<String> persistImportedFile(String sourcePath) async {
    final format = formatFromPath(sourcePath);
    if (format == BookFormat.unknown) {
      throw FormatException('Формат не поддерживается: ${p.extension(sourcePath)}');
    }

    final dir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(dir.path, 'books'));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath).toLowerCase();
    final destPath = p.join(booksDir.path, '${_uuid.v4()}$ext');
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<ParsedBook> loadBook(String filePath) async {
    switch (formatFromPath(filePath)) {
      case BookFormat.epub:
        return _epub.parse(filePath);
      case BookFormat.fb2:
        return _fb2.parse(filePath);
      case BookFormat.mobi:
        return _mobi.parse(filePath);
      case BookFormat.unknown:
        throw FormatException('Неподдерживаемый формат: $filePath');
    }
  }
}
