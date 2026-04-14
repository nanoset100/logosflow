import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/models/sermon_model.dart';

class SavedSermonsSection extends StatelessWidget {
  final List<SermonModel> savedSermons;
  final VoidCallback onViewAll;
  final void Function(SermonModel) onTap;

  const SavedSermonsSection({
    super.key,
    required this.savedSermons,
    required this.onViewAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = savedSermons.take(3).toList();
    final total = savedSermons.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '저장한 설교',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (total > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '총 $total개',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const Spacer(),
            if (total > 0)
              GestureDetector(
                onTap: onViewAll,
                child: const Row(
                  children: [
                    Text(
                      '전체 보기',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18, color: AppColors.primary),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (total == 0)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: AppColors.textHint.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.bookmark_border,
                      size: 36, color: Colors.grey.shade300),
                  const SizedBox(width: 14),
                  const Text(
                    '저장한 설교가 없습니다',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                ...preview.asMap().entries.map((e) {
                  final idx = e.key;
                  final sermon = e.value;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => onTap(sermon),
                        borderRadius: BorderRadius.only(
                          topLeft: idx == 0
                              ? const Radius.circular(12)
                              : Radius.zero,
                          topRight: idx == 0
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottomLeft: idx == preview.length - 1
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottomRight: idx == preview.length - 1
                              ? const Radius.circular(12)
                              : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sermon.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${sermon.date.month}월 ${sermon.date.day}일',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 18, color: AppColors.textHint),
                            ],
                          ),
                        ),
                      ),
                      if (idx < preview.length - 1)
                        Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: AppColors.primary
                                .withValues(alpha: 0.08)),
                    ],
                  );
                }),
                if (total > 3) ...[
                  Divider(
                      height: 1,
                      color: AppColors.primary.withValues(alpha: 0.08)),
                  InkWell(
                    onTap: onViewAll,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '전체 보기 ›',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
