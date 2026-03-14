import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/models/sermon_model.dart';
import '../../../../data/models/user_progress_model.dart';

class GroupDevotionSection extends StatelessWidget {
  final SermonModel sermon;
  final UserProgressModel? progress;
  final VoidCallback onTap;

  const GroupDevotionSection({
    super.key,
    required this.sermon,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = progress?.completedCount ?? 0;
    final rawSummary =
        sermon.summary.replaceAll(RegExp(r'[#*_`>]'), '').trim();
    final summaryPreview = rawSummary.length > 90
        ? '${rawSummary.substring(0, 90)}...'
        : rawSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_rounded,
                size: 22, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            const Text(
              '이번 주 구역 예배 교재',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E5C8A), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3949AB).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '5일 묵상 교재',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    sermon.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${sermon.pastor} 목사님  ·  ${sermon.bibleVerse}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    summaryPreview,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < completedCount
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.22),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: i < completedCount
                                  ? const Color(0xFF3949AB)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$completedCount / 5일 완료',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '구역 예배 교재 보러 가기  →',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3949AB),
                      ),
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
