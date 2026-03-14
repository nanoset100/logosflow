import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/daily_bible_data.dart';
import '../../../../data/services/activity_service.dart';

class DailyBibleCard extends StatelessWidget {
  const DailyBibleCard({super.key});

  static const _bibleAppPackage = 'com.bible_app.king_beginner_bible';
  static const _bibleAppStore =
      'https://play.google.com/store/apps/details?id=com.bible_app.king_beginner_bible';

  Future<void> _openBibleApp() async {
    await ActivityService().recordActivity('bible');
    final appUri = Uri.parse('android-app://$_bibleAppPackage');
    final storeUri = Uri.parse(_bibleAppStore);
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DailyBibleData.getToday();
    final book = today['book'] as String;
    final chapter = today['chapter'] as int;
    final progress = DailyBibleData.getTodayProgress();

    final now = DateTime.now();
    final dateStr = '${now.month}월 ${now.day}일';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 성경',
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
                color: const Color(0xFFB8860B).withValues(alpha: 0.25)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFDF0), Color(0xFFFFF8E1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$book $chapter장',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFD7CCC8),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFB8860B)),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '신약 연간 읽기 ${(progress * 100).toStringAsFixed(0)}% 완료',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8D6E63),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openBibleApp,
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text('왕초보 성경통독으로 읽기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8860B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
