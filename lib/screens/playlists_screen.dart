import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'reader_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  Future<void> _createPlaylist(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '📚');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый плейлист'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiCtrl,
              decoration: const InputDecoration(labelText: 'Эмодзи'),
              maxLength: 2,
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Название'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Создать')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty && context.mounted) {
      await context.read<AppState>().createPlaylist(
            nameCtrl.text.trim(),
            emoji: emojiCtrl.text.trim().isEmpty ? '📚' : emojiCtrl.text.trim(),
          );
    }
    nameCtrl.dispose();
    emojiCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Плейлисты')),
      body: state.playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.collections_bookmark_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Создайте первый плейлист',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.playlists.length,
              itemBuilder: (context, index) {
                final playlist = state.playlists[index];
                final books = state.books.where((b) => playlist.bookIds.contains(b.id)).toList();
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.powderBlue,
                      child: Text(playlist.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${books.length} книг'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'delete') {
                          await state.deletePlaylist(playlist.id);
                        } else if (v == 'add') {
                          if (context.mounted) {
                            await _showAddBooksDialog(context, playlist.id);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'add', child: Text('Добавить книги')),
                        PopupMenuItem(value: 'delete', child: Text('Удалить')),
                      ],
                    ),
                    children: books.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Добавьте книги в плейлист'),
                            ),
                          ]
                        : books
                            .map(
                              (book) => ListTile(
                                leading: const Icon(Icons.menu_book_outlined),
                                title: Text(book.title),
                                subtitle: Text(book.author),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReaderScreen(book: book),
                                    ),
                                  );
                                },
                              ),
                            )
                            .toList(),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createPlaylist(context),
        child: const Icon(Icons.create_new_folder_outlined),
      ),
    );
  }

  Future<void> _showAddBooksDialog(BuildContext context, String playlistId) async {
    final state = context.read<AppState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final playlist = state.playlists.firstWhere((p) => p.id == playlistId);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Книги в «${playlist.name}»',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: state.books.length,
                        itemBuilder: (_, i) {
                          final book = state.books[i];
                          final selected = playlist.bookIds.contains(book.id);
                          return CheckboxListTile(
                            value: selected,
                            title: Text(book.title),
                            subtitle: Text(book.author),
                            onChanged: (_) async {
                              await state.toggleBookInPlaylist(playlistId, book.id);
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
