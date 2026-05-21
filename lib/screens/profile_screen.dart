import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/reader_settings.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/reader_settings_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _loadedUserId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _syncName(String name) {
    if (_nameCtrl.text != name) _nameCtrl.text = name;
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    await context.read<AppState>().updateProfile(avatarPath: file.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user!;
    if (_loadedUserId != user.id) {
      _loadedUserId = user.id;
      _syncName(user.displayName);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.powderBlue,
                  backgroundImage: user.avatarPath != null &&
                          File(user.avatarPath!).existsSync()
                      ? FileImage(File(user.avatarPath!))
                      : null,
                  child: user.avatarPath == null ||
                          !File(user.avatarPath!).existsSync()
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: AppColors.burntSienna,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.burntSienna,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: AppColors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Center(
            child: Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Отображаемое имя',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await state.updateProfile(displayName: _nameCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Профиль сохранён')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: state.isDark ? Icons.dark_mode : Icons.light_mode,
            title: 'Тема приложения',
            subtitle: state.isDark ? 'Тёмная' : 'Светлая',
            onTap: state.toggleTheme,
          ),
          _SettingsTile(
            icon: Icons.tune_rounded,
            title: 'Читалка по умолчанию',
            subtitle: _readerPresetLabel(state.readerSettings.readerTheme),
            onTap: _openReaderDefaults,
          ),
          _SettingsTile(
            icon: Icons.local_fire_department,
            title: 'Серия чтения',
            subtitle:
                '${state.streak.currentStreak} дней · рекорд ${state.streak.longestStreak}',
          ),
          _SettingsTile(
            icon: Icons.menu_book,
            title: 'Книг на полке',
            subtitle: '${state.books.length}',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Выйти?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Выйти'),
                    ),
                  ],
                ),
              );
              if (ok == true) await state.logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }

  String _readerPresetLabel(ReaderThemePreset preset) {
    return switch (preset) {
      ReaderThemePreset.dark => 'Тёмная',
      ReaderThemePreset.sepia => 'Сепия',
      ReaderThemePreset.light => 'Светлая',
    };
  }

  void _openReaderDefaults() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReaderSettingsSheet(onChanged: () {}),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
