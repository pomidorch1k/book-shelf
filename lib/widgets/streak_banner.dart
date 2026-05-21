import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class StreakBanner extends StatelessWidget {
  const StreakBanner({super.key, required this.streak});

  final ReadingStreak streak;

  @override
  Widget build(BuildContext context) {
    final progress = (streak.todayMinutes / streak.goalMinutes).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.burntSienna, AppColors.burntSiennaDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.burntSienna.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Text(
                '${streak.currentStreak} дней подряд',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.powderBlue.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'рекорд: ${streak.longestStreak}',
                  style: const TextStyle(color: AppColors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Сегодня: ${streak.todayMinutes} / ${streak.goalMinutes} мин',
            style: const TextStyle(color: AppColors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: AppColors.powderBlue,
              backgroundColor: AppColors.powderBlue.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}
