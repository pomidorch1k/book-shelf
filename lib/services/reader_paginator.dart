import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PaginateRequest {
  PaginateRequest({
    required this.text,
    required this.fontSize,
    required this.lineHeight,
    required this.maxWidth,
    required this.maxHeight,
  });

  final String text;
  final double fontSize;
  final double lineHeight;
  final double maxWidth;
  final double maxHeight;
}

class ReaderPaginator {
  static Future<List<String>> paginateAsync(PaginateRequest request) {
    return compute(_paginateInIsolate, request);
  }

  static List<String> _paginateInIsolate(PaginateRequest request) {
    final style = TextStyle(
      fontSize: request.fontSize,
      height: request.lineHeight,
    );
    return paginate(
      text: request.text,
      style: style,
      maxWidth: request.maxWidth,
      maxHeight: request.maxHeight,
    );
  }

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
    if (text.isEmpty) return true;
    final height = _measureHeight(text, style, maxWidth);
    return height <= maxHeight;
  }

  static double _measureHeight(
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  static List<String> _splitLongText(
    String text,
    TextStyle style,
    double maxWidth,
    double maxHeight,
  ) {
    final pages = <String>[];
    final words = text.split(RegExp(r'\s+'));
    var start = 0;

    while (start < words.length) {
      var low = 1;
      var high = words.length - start;
      var best = 1;

      while (low <= high) {
        final mid = (low + high) >> 1;
        final chunk = words.sublist(start, start + mid).join(' ');
        if (_fits(chunk, style, maxWidth, maxHeight)) {
          best = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      pages.add(words.sublist(start, start + best).join(' '));
      start += best;
    }

    return pages;
  }
}
