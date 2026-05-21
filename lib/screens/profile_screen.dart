import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';

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

  Future<void> _pickImage(bool isBanner) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    final state = context.read<AppState>();
    if (isBanner) {
      await state.updateProfile(bannerPath: file.path);
    } else {
      await state.updateProfile(avatarPath: file.path);
    }
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (user.bannerPath != null && File(user.bannerPath!).existsSync())
                    Image.file(File(user.bannerPath!), fit: BoxFit.cover)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.midnightBlue, AppColors.midnightBlueLight],
                        ),
                      ),
                    ),
                  Container(color: Colors.black.withValues(alpha: 0.25)),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.peach,
                        foregroundColor: AppColors.midnightBlue,
                      ),
                      onPressed: () => _pickImage(true),
                      icon: const Icon(Icons.photo_camera_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.peach,
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
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.midnightBlue,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _pickImage(false),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.midnightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: AppColors.peach, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Отображаемое имя',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
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
                  ),
                  const SizedBox(height: 16),
                  _SettingsTile(
                    icon: state.isDark ? Icons.dark_mode : Icons.light_mode,
                    title: 'Тема приложения',
                    subtitle: state.isDark ? 'Тёмная' : 'Светлая',
                    onTap: state.toggleTheme,
                  ),
                  _SettingsTile(
                    icon: Icons.local_fire_department,
                    title: 'Серия чтения',
                    subtitle: '${state.streak.currentStreak} дней · рекорд ${state.streak.longestStreak}',
                  ),
                  _SettingsTile(
                    icon: Icons.menu_book,
                    title: 'Книг на полке',
                    subtitle: '${state.books.length}',
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: OutlinedButton.icon(
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
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
