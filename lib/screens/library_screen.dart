import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/streak_banner.dart';
import 'reader_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _importBook(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'fb2', 'zip', 'mobi', 'azw', 'azw3'],
    );
    if (result == null || result.files.single.path == null) return;

    if (!context.mounted) return;
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(content: Text('Импорт книги...')),
    );

    final book = await state.addBookFromPath(result.files.single.path!);
    if (!context.mounted) return;

    if (book == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть файл. Поддерживаются EPUB, FB2, MOBI'),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Добавлено: ${book.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книжная полка'),
        actions: [
          IconButton(
            icon: Icon(state.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: state.toggleTheme,
          ),
        ],
      ),
      body: state.books.isEmpty
          ? ListView(
              children: [
                StreakBanner(streak: state.streak),
                const SizedBox(height: 48),
                Icon(
                  Icons.library_books_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Полка пуста',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Нажмите + чтобы добавить EPUB, FB2 или MOBI',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: state.books.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return StreakBanner(streak: state.streak);
                final book = state.books[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: BookCard(
                    book: book,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(book: book),
                        ),
                      );
                    },
                    onDelete: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Удалить книгу?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Отмена'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Удалить'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await state.removeBook(book.id);
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importBook(context),
        icon: const Icon(Icons.add),
        label: const Text('Книга'),
      ),
    );
  }
}
