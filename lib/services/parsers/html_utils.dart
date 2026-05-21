class HtmlUtils {
  static String wrapDocument(String html) {
    final trimmed = html.trim();
    final lower = trimmed.toLowerCase();
    if (lower.contains('<body')) return _sanitize(trimmed);
    if (lower.contains('<html')) return _sanitize(trimmed);
    return _sanitize(
      '<html><head><meta charset="utf-8"></head><body>$trimmed</body></html>',
    );
  }

  static String _sanitize(String html) {
    return html
        .replaceAll(RegExp(r'xmlns="[^"]*"'), '')
        .replaceAll(RegExp(r'xmlns:[a-z]+="[^"]*"'), '');
  }

  static bool hasReadableText(String html) {
    final text = stripTags(html);
    return text.length > 30;
  }

  static String stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<(script|style)[^>]*>[\s\S]*?</\1>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&[a-z]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? extractTitle(String html) {
    final patterns = [
      RegExp(r'<h1[^>]*>([\s\S]*?)</h1>', caseSensitive: false),
      RegExp(r'<h2[^>]*>([\s\S]*?)</h2>', caseSensitive: false),
      RegExp(r'<title[^>]*>([\s\S]*?)</title>', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(html);
      if (m != null) {
        final t = stripTags(m.group(1)!);
        if (t.isNotEmpty && t.length < 120) return t;
      }
    }
    return null;
  }

  static bool isLikelyNavFile(String href) {
    final h = href.toLowerCase();
    return h.contains('toc.') ||
        h.contains('nav.') ||
        h.contains('/toc') ||
        h.contains('contents.') ||
        h.contains('cover.') ||
        h.endsWith('toc.xhtml') ||
        h.endsWith('toc.html') ||
        h.contains('titlepage');
  }
}
