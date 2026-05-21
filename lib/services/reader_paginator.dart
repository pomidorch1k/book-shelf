import 'package:flutter/material.dart';

class ReaderPaginator {
  static List<String> paginate({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (text.trim().isEmpty) return [''];

    final pages = <String>[];
    final paragraphs = text.split(RegExp(r'\n{2,}'));

    var buffer = '';

    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;

      final candidate = buffer.isEmpty ? trimmed : '$buffer\n\n$trimmed';

      if (_fits(candidate, style, maxWidth, maxHeight)) {
        buffer = candidate;
        continue;
      }

      if (buffer.isNotEmpty) {
        pages.add(buffer);
        buffer = '';
      }

      if (_fits(trimmed, style, maxWidth, maxHeight)) {
        buffer = trimmed;
      } else {
        pages.addAll(_splitLongText(trimmed, style, maxWidth, maxHeight));
      }
    }

    if (buffer.isNotEmpty) {
      pages.add(buffer);
    }

    return pages.isEmpty ? [text] : pages;
  }

  static bool _fits(
    String text,
    TextStyle style,
    double maxWidth,
    double maxHeight,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return painter.height <= maxHeight;
  }

  static List<String> _splitLongText(
    String text,
    TextStyle style,
    double maxWidth,
    double maxHeight,
  ) {
    final pages = <String>[];
    final words = text.split(RegExp(r'\s+'));
    var buffer = '';

    for (final word in words) {
      final candidate = buffer.isEmpty ? word : '$buffer $word';
      if (_fits(candidate, style, maxWidth, maxHeight)) {
        buffer = candidate;
      } else {
        if (buffer.isNotEmpty) pages.add(buffer);
        buffer = word;
      }
    }

    if (buffer.isNotEmpty) pages.add(buffer);
    return pages;
  }
}
