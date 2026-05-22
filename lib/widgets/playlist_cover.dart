import 'dart:io';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class PlaylistCover extends StatelessWidget {
  const PlaylistCover({
    super.key,
    required this.playlist,
    this.borderRadius = 16,
  });

  final Playlist playlist;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: playlist.hasCover && File(playlist.coverPath!).existsSync()
            ? Image.file(
                File(playlist.coverPath!),
                fit: BoxFit.cover,
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.powderBlue,
                      AppColors.powderBlue.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 56,
                  color: AppColors.burntSienna,
                ),
              ),
      ),
    );
  }
}
