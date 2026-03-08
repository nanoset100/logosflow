import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/notice_model.dart';
import '../../../data/services/notice_service.dart';
import 'notice_detail_screen.dart';

class NoticeScreen extends StatefulWidget {
  final String churchCode;
  final String churchName;

  const NoticeScreen({
    super.key,
    required this.churchCode,
    required this.churchName,
  });

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = NoticeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('침신/교회 소식'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: const Color(0xFF1565C0),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: '교단·학교 소식'),
            Tab(text: '우리 교회 소식'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NoticeList(
            notices: NoticeService.dummyDenominationNotices,
            emptyMessage: '등록된 교단 소식이 없습니다',
            accentColor: const Color(0xFF1565C0),
          ),
          _NoticeList(
            notices: NoticeService.dummyChurchNotices(widget.churchName),
            emptyMessage: '등록된 교회 소식이 없습니다',
            accentColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── 공지 리스트 ──────────────────────────────────
class _NoticeList extends StatelessWidget {
  final List<NoticeModel> notices;
  final String emptyMessage;
  final Color accentColor;

  const _NoticeList({
    required this.notices,
    required this.emptyMessage,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (notices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 고정 공지 먼저
    final pinned = notices.where((n) => n.isPinned).toList();
    final normal = notices.where((n) => !n.isPinned).toList();
    final sorted = [...pinned, ...normal];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _NoticeCard(
          notice: sorted[index],
          accentColor: accentColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoticeDetailScreen(notice: sorted[index]),
            ),
          ),
        );
      },
    );
  }
}

// ─── 공지 카드 ───────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  final Color accentColor;
  final VoidCallback onTap;

  const _NoticeCard({
    required this.notice,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: notice.isPinned ? Colors.orange : accentColor,
                width: 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 뱃지 + 날짜
              Row(
                children: [
                  if (notice.isPinned)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin_rounded,
                              size: 11, color: Colors.orange),
                          SizedBox(width: 2),
                          Text(
                            '공지',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text(
                    notice.formattedDate,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 제목
              Text(
                notice.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              // 미리보기
              Text(
                notice.previewContent,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              // 하단: 작성자
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    notice.author,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: accentColor.withValues(alpha: 0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
