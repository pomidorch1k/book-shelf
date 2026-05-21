class BookChapter {
  BookChapter({required this.title, required this.html});
  final String title;
  final String html;
}

class ParsedBook {
  ParsedBook({
    required this.title,
    required this.author,
    required this.chapters,
  });

  final String title;
  final String author;
  final List<BookChapter> chapters;
}
