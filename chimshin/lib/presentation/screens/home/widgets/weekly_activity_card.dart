import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class WeeklyActivityCard extends StatelessWidget {
  final int sermonDays;
  final int devotionDays;
  final int bibleDays;
  final int streak;

  const WeeklyActivityCard({
    super.key,
    required this.sermonDays,
    required this.devotionDays,
    required this.bibleDays,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이번 주 활동',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActivityStat(emoji: '⛪', label: '예배', days: sermonDays),
                _VerticalDivider(),
                _ActivityStat(emoji: '💭', label: '묵상', days: devotionDays),
                _VerticalDivider(),
                _ActivityStat(emoji: '📚', label: '성경', days: bibleDays),
                _VerticalDivider(),
                _ActivityStat(emoji: '🔥', label: '연속', days: streak),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final String emoji;
  final String label;
  final int days;

  const _ActivityStat({
    required this.emoji,
    required this.label,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(
          '$days일',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: VerticalDivider(
        color: AppColors.primary.withValues(alpha: 0.1),
        thickness: 1,
        width: 1,
      ),
    );
  }
}
