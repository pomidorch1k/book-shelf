import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/playlist_cover.dart';
import 'reader_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  Future<void> _showAddBooks(BuildContext context, AppState state) async {
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
                      'Добавить книги',
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final playlist = state.playlists.firstWhere((p) => p.id == playlistId);
    final books = state.books.where((b) => playlist.bookIds.contains(b.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'cover') {
                final file = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (file != null && context.mounted) {
                  await state.updatePlaylistCover(playlistId, file.path);
                }
              } else if (v == 'remove_cover') {
                await state.updatePlaylistCover(playlistId, null);
              } else if (v == 'delete') {
                await state.deletePlaylist(playlistId);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'cover', child: Text('Сменить обложку')),
              if (playlist.hasCover)
                const PopupMenuItem(value: 'remove_cover', child: Text('Убрать обложку')),
              const PopupMenuItem(value: 'delete', child: Text('Удалить плейлист')),
            ],
          ),
        ],
      ),
      body: books.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 160,
                    child: PlaylistCover(playlist: playlist),
                  ),
                  const SizedBox(height: 20),
                  const Text('Плейлист пуст'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddBooks(context, state),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить книги'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (_, i) {
                final book = books[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(book.title),
                    subtitle: Text(book.author),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: books.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddBooks(context, state),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
