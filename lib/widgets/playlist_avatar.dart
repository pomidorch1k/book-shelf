import 'dart:io';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class PlaylistAvatar extends StatelessWidget {
  const PlaylistAvatar({
    super.key,
    required this.playlist,
    this.radius = 24,
  });

  final Playlist playlist;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (playlist.hasCover && File(playlist.coverPath!).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(playlist.coverPath!)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.powderBlue,
      child: Icon(
        Icons.collections_bookmark_outlined,
        color: AppColors.burntSienna,
        size: radius,
      ),
    );
  }
}
