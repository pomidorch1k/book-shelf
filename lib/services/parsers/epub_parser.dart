import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../models/book_content.dart';
import 'html_utils.dart';

class EpubParser {
  Future<ParsedBook> parse(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final files = <String, List<int>>{};
    for (final entry in archive) {
      if (entry.isFile) {
        files[_normalizeArchivePath(entry.name)] = List<int>.from(entry.content);
      }
    }

    final containerKey = _findFile(files, 'META-INF/container.xml');
    if (containerKey == null) {
      throw const FormatException('EPUB: не найден container.xml');
    }

    final containerDoc = XmlDocument.parse(
      utf8.decode(files[containerKey]!, allowMalformed: true),
    );
    final rootfilePath = containerDoc
        .findAllElements('rootfile')
        .firstOrNull
        ?.getAttribute('full-path');
    if (rootfilePath == null) {
      throw const FormatException('EPUB: не найден путь к OPF');
    }

    final opfKey = _findFile(files, rootfilePath) ??
        _findFile(files, Uri.decodeComponent(rootfilePath));
    if (opfKey == null) {
      throw const FormatException('EPUB: не найден OPF файл');
    }

    final opfDoc = XmlDocument.parse(
      utf8.decode(files[opfKey]!, allowMalformed: true),
    );
    final opfDir = p.posix.dirname(opfKey);

    final title = _firstText(opfDoc, 'dc:title') ?? _fileName(filePath);
    final author = _firstText(opfDoc, 'dc:creator') ?? 'Неизвестный автор';

    final manifest = <String, _ManifestItem>{};
    for (final item in opfDoc.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type') ?? '';
      if (id == null || href == null) continue;
      manifest[id] = _ManifestItem(href: href, mediaType: mediaType);
    }

    final spineIds = <String>[];
    for (final itemref in opfDoc.findAllElements('itemref')) {
      final linear = itemref.getAttribute('linear')?.toLowerCase();
      if (linear == 'no') continue;
      final idref = itemref.getAttribute('idref');
      if (idref != null) spineIds.add(idref);
    }

    final chapters = <BookChapter>[];

    for (final id in spineIds) {
      final manifestItem = manifest[id];
      if (manifestItem == null) continue;
      if (!_isHtmlMedia(manifestItem.mediaType)) continue;
      if (HtmlUtils.isLikelyNavFile(manifestItem.href)) continue;

      final chapterKey = _resolveOpfHref(files, opfDir, manifestItem.href);
      if (chapterKey == null) continue;

      final html = _decodeBytes(files[chapterKey]!);
      if (!HtmlUtils.hasReadableText(html)) continue;

      final chapterTitle =
          HtmlUtils.extractTitle(html) ?? 'Глава ${chapters.length + 1}';
      chapters.add(
        BookChapter(
          title: chapterTitle,
          html: HtmlUtils.wrapDocument(html),
        ),
      );
    }

    if (chapters.isEmpty) {
      chapters.addAll(_chaptersFromAllHtml(files, opfDir));
    }

    if (chapters.isEmpty) {
      throw const FormatException('EPUB: текст книги не найден');
    }

    return ParsedBook(title: title, author: author, chapters: chapters);
  }

  List<BookChapter> _chaptersFromAllHtml(
    Map<String, List<int>> files,
    String opfDir,
  ) {
    final result = <BookChapter>[];
    final htmlKeys = files.keys
        .where((k) {
          final lower = k.toLowerCase();
          return (lower.endsWith('.xhtml') ||
                  lower.endsWith('.html') ||
                  lower.endsWith('.htm')) &&
              !HtmlUtils.isLikelyNavFile(k);
        })
        .toList()
      ..sort();

    for (final key in htmlKeys) {
      final html = _decodeBytes(files[key]!);
      if (!HtmlUtils.hasReadableText(html)) continue;
      result.add(
        BookChapter(
          title: HtmlUtils.extractTitle(html) ?? 'Часть ${result.length + 1}',
          html: HtmlUtils.wrapDocument(html),
        ),
      );
    }
    return result;
  }

  bool _isHtmlMedia(String mediaType) {
    final mt = mediaType.toLowerCase();
    return mt.contains('html') || mt.contains('xml');
  }

  String _decodeBytes(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes, allowMalformed: true);
    }
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  String? _resolveOpfHref(
    Map<String, List<int>> files,
    String opfDir,
    String href,
  ) {
    final decoded = Uri.decodeComponent(href);
    final combined = opfDir.isEmpty ? decoded : p.posix.join(opfDir, decoded);
    return _findFile(files, combined) ?? _findFile(files, decoded);
  }

  String? _findFile(Map<String, List<int>> files, String wanted) {
    final normalized = _normalizeArchivePath(wanted);
    if (files.containsKey(normalized)) return normalized;

    final decoded = _normalizeArchivePath(Uri.decodeComponent(wanted));
    if (files.containsKey(decoded)) return decoded;

    final lower = decoded.toLowerCase();
    for (final key in files.keys) {
      if (key.toLowerCase() == lower) return key;
      if (key.toLowerCase().endsWith('/$lower')) return key;
      if (p.basename(key).toLowerCase() == p.basename(lower).toLowerCase()) {
        return key;
      }
    }
    return null;
  }

  String _normalizeArchivePath(String path) {
    return path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/'), '');
  }

  String? _firstText(XmlDocument doc, String localName) {
    for (final el in doc.descendants.whereType<XmlElement>()) {
      if (el.name.local == localName || el.name.qualified == localName) {
        final text = el.innerText.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  String _fileName(String path) {
    final name = p.basename(path);
    if (name.toLowerCase().endsWith('.epub')) {
      return name.substring(0, name.length - 5);
    }
    return name;
  }
}

class _ManifestItem {
  _ManifestItem({required this.href, required this.mediaType});
  final String href;
  final String mediaType;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
