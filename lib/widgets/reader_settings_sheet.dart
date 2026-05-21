import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reader_settings.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.readerSettings;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.burntSienna),
              const SizedBox(width: 10),
              Text(
                'Настройки читалки',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Размер шрифта: ${settings.fontSize.round()}'),
          Slider(
            value: settings.fontSize,
            min: 14,
            max: 28,
            divisions: 14,
            activeColor: AppColors.burntSienna,
            onChanged: (v) async {
              await state.updateReaderSettings(settings.copyWith(fontSize: v));
              onChanged();
            },
          ),
          Text('Межстрочный интервал: ${settings.lineHeight.toStringAsFixed(2)}'),
          Slider(
            value: settings.lineHeight,
            min: 1.2,
            max: 2.2,
            divisions: 10,
            activeColor: AppColors.burntSienna,
            onChanged: (v) async {
              await state.updateReaderSettings(settings.copyWith(lineHeight: v));
              onChanged();
            },
          ),
          Text('Поля: ${settings.horizontalPadding.round()}'),
          Slider(
            value: settings.horizontalPadding,
            min: 8,
            max: 40,
            divisions: 16,
            activeColor: AppColors.burntSienna,
            onChanged: (v) async {
              await state.updateReaderSettings(settings.copyWith(horizontalPadding: v));
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          Text('Тема читалки', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ReaderThemePreset>(
            segments: const [
              ButtonSegment(
                value: ReaderThemePreset.light,
                label: Text('Светлая'),
                icon: Icon(Icons.wb_sunny_outlined),
              ),
              ButtonSegment(
                value: ReaderThemePreset.sepia,
                label: Text('Тёплая'),
                icon: Icon(Icons.auto_stories_outlined),
              ),
              ButtonSegment(
                value: ReaderThemePreset.dark,
                label: Text('Тёмная'),
                icon: Icon(Icons.nights_stay_outlined),
              ),
            ],
            selected: {settings.readerTheme},
            onSelectionChanged: (set) async {
              await state.updateReaderSettings(
                settings.copyWith(readerTheme: set.first),
              );
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}
