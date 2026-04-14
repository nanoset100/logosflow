import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/services/prayer_service.dart';
import '../../../../data/models/prayer_request_model.dart';

class PrayerSection extends StatelessWidget {
  final String uid;
  final PrayerService prayerService;
  final VoidCallback onManage;

  const PrayerSection({
    super.key,
    required this.uid,
    required this.prayerService,
    required this.onManage,
  });

  Color _categoryColor(String category) {
    switch (category) {
      case '가족': return Colors.orange.shade300;
      case '직장': return Colors.blue.shade300;
      case '건강': return Colors.red.shade300;
      case '교회': return Colors.green.shade300;
      case '개인': return Colors.purple.shade300;
      default:    return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '나의 기도제목',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onManage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '관리하기',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<PrayerRequestModel>>(
          stream: prayerService.prayerStream(uid),
          builder: (context, snapshot) {
            final prayers = snapshot.data ?? [];
            final sorted = List.of(prayers)
              ..sort((a, b) {
                if (a.isAnswered == b.isAnswered) return 0;
                return a.isAnswered ? 1 : -1;
              });
            final display = sorted.take(3).toList();

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: display.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Text('🙏', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Text(
                            '기도제목을 추가해보세요',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        ...display.asMap().entries.map((e) {
                          final idx = e.key;
                          final prayer = e.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _categoryColor(prayer.category),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        prayer.category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        prayer.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                          decoration: prayer.isAnswered
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (prayer.isAnswered)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '응답',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (idx < display.length - 1)
                                Divider(
                                    height: 1,
                                    indent: 14,
                                    endIndent: 14,
                                    color: Colors.grey
                                        .withValues(alpha: 0.1)),
                            ],
                          );
                        }),
                        if (prayers.length > 3) ...[
                          Divider(
                              height: 1,
                              color: Colors.grey.withValues(alpha: 0.1)),
                          InkWell(
                            onTap: onManage,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(
                                  '전체 보기 >',
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
            );
          },
        ),
        const SizedBox(height: 12),
        const RepresentPrayerPromo(),
      ],
    );
  }
}

class RepresentPrayerPromo extends StatelessWidget {
  const RepresentPrayerPromo({super.key});

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.nanoset.repre_prayer_app';

  Future<void> _openStore() async {
    final uri = Uri.parse(_storeUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openStore,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Row(
          children: [
            const Text('🙏', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '더 많은 대표기도문이 필요하신가요?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '대표기도 앱 · 상황별 기도문 모음',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF66BB6A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.green.shade400),
          ],
        ),
      ),
    );
  }
}
