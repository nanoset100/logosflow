import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/models/user_progress_model.dart';

class TodayDevotionCard extends StatelessWidget {
  final String dayName;
  final String devotion;
  final UserProgressModel? progress;
  final VoidCallback onTap;

  const TodayDevotionCard({
    super.key,
    required this.dayName,
    required this.devotion,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 묵상',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: AppColors.secondary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          dayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (progress != null)
                        Text(
                          '${progress!.completedCount}/5일 완료',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress!.completedCount / 5,
                        backgroundColor:
                            AppColors.secondary.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    devotion.isEmpty
                        ? '주중 묵상은 월~금요일에 제공됩니다'
                        : devotion,
                    style: TextStyle(
                      fontSize: 15,
                      color: devotion.isEmpty
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
