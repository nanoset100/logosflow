import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/notice_model.dart';

class NoticeDetailScreen extends StatelessWidget {
  final NoticeModel notice;

  const NoticeDetailScreen({super.key, required this.notice});

  Color get _categoryColor => notice.category == NoticeCategory.denomination
      ? const Color(0xFF1565C0)
      : AppColors.primary;

  String get _categoryLabel => notice.category == NoticeCategory.denomination
      ? '교단·학교 소식'
      : '우리 교회 소식';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('공지사항'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.08)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 + 고정 뱃지
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _categoryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _categoryLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: _categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (notice.isPinned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin_rounded,
                            size: 12, color: Colors.orange),
                        SizedBox(width: 3),
                        Text(
                          '고정',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // 제목
            Text(
              notice.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // 작성자 + 날짜
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 15, color: AppColors.textHint),
                const SizedBox(width: 5),
                Text(
                  notice.author,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 5),
                Text(
                  notice.formattedDate,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(
                color: AppColors.primary.withValues(alpha: 0.1)),
            const SizedBox(height: 20),
            // 본문
            Text(
              notice.content,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                height: 1.85,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
