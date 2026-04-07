import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/models/user_progress_model.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/activity_service.dart';
import '../../../data/services/saved_sermon_service.dart';

class GroupDevotionScreen extends StatefulWidget {
  final SermonModel sermon;

  const GroupDevotionScreen({super.key, required this.sermon});

  @override
  State<GroupDevotionScreen> createState() => _GroupDevotionScreenState();
}

class _GroupDevotionScreenState extends State<GroupDevotionScreen> {
  final ProgressService _progressService = ProgressService();
  final SavedSermonService _savedService = SavedSermonService();
  String? _userId;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final saved = await _savedService.isSaved(widget.sermon.id);
    if (mounted) setState(() => _isSaved = saved);
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await _savedService.unsaveSermon(widget.sermon.id);
      if (mounted) {
        setState(() => _isSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보관함에서 삭제되었습니다')),
        );
      }
    } else {
      await _savedService.saveSermon(widget.sermon);
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보관함에 저장되었습니다')),
        );
      }
    }
  }

  void _share() {
    final rawSummary = widget.sermon.summary.replaceAll(RegExp(r'[#*_`>]'), '').trim();
    final preview = rawSummary.length > 150
        ? '${rawSummary.substring(0, 150)}...'
        : rawSummary;
    final text =
        '📖 ${widget.sermon.title} - ${widget.sermon.pastor} 목사님\n\n$preview\n\n'
        '👉 구역 예배 5일 묵상 교재는 [말씀브릿지] 앱에서 무료로 확인하세요!\n'
        'https://apps.apple.com/app/id6744803990';
    Share.share(text, subject: '${widget.sermon.title} - 구역 예배 교재');
  }

  Future<void> _toggleDay(String dayKey, bool newValue) async {
    if (_userId == null) return;
    try {
      await _progressService.toggleDay(
        userId: _userId!,
        sermonId: widget.sermon.id,
        churchCode: widget.sermon.churchCode,
        dayKey: dayKey,
        completed: newValue,
      );
      if (newValue) await ActivityService().recordActivity('devotion');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 데이터 검증 및 빈 화면 방어 (iPad 대응)
    if (widget.sermon.summary.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('데이터 확인')),
        body: const Center(
          child: Text(
            '데이터를 불러오는 중이거나 내용이 없습니다.\n잠시 후 다시 시도해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.sermon.pastor} 목사님 말씀'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? const Color(0xFF1565C0) : null,
            ),
            tooltip: _isSaved ? '보관함에서 삭제' : '보관함에 저장',
            onPressed: _toggleSave,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '공유하기',
            onPressed: _share,
          ),
        ],
      ),
      body: _userId == null
          ? _buildBody(null)
          : StreamBuilder<UserProgressModel?>(
              stream: _progressService.getProgressStream(
                  _userId!, widget.sermon.id),
              builder: (context, snapshot) {
                return _buildBody(snapshot.data);
              },
            ),
    );
  }

  Widget _buildBody(UserProgressModel? progress) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSummarySection(),
          const SizedBox(height: 8),
          _buildDevotionSection(progress),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── 설교 정보 헤더 ────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3949AB).withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF3949AB).withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 15,
                  color: Color(0xFF3949AB)),
              const SizedBox(width: 7),
              Text(
                '${widget.sermon.formattedDate} (${widget.sermon.dayOfWeek})',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF3949AB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.sermon.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.menu_book, size: 17,
                  color: AppColors.textSecondary),
              const SizedBox(width: 7),
              Text(
                widget.sermon.bibleVerse,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person, size: 17, color: AppColors.textHint),
              const SizedBox(width: 7),
              Text(
                '${widget.sermon.pastor} 목사님',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 전체 요약 + 핵심 교훈 (마크다운) ────────────────
  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF3949AB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '설교 요약 및 핵심 교훈',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            try {
              return MarkdownBody(
                data: widget.sermon.summary,
                styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                height: 1.75,
              ),
              strong: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              h3: const TextStyle(
                fontSize: 17,
                color: Color(0xFF3949AB),
                fontWeight: FontWeight.bold,
                height: 2.2,
              ),
              listBullet: const TextStyle(
                fontSize: 16,
                color: Color(0xFF3949AB),
              ),
              blockquote: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
              blockquoteDecoration: BoxDecoration(
                color: const Color(0xFF3949AB).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFF3949AB).withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
              ),
            ),
          );
            } catch (_) {
              return Text(
                widget.sermon.summary.replaceAll(RegExp(r'[#*_`>]'), '').trim(),
                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.75),
              );
            }
          }),
        ],
      ),
    );
  }

  // ─── 5일 묵상 나눔 ────────────────────────────────
  Widget _buildDevotionSection(UserProgressModel? progress) {
    const days = ['월', '화', '수', '목', '금'];
    final completedCount = progress?.completedCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '5일 묵상 나눔 교재',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 진행 바
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completedCount / 5,
                        backgroundColor:
                            AppColors.secondary.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary),
                        minHeight: 7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completedCount / 5일',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  if (completedCount == 5) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded,
                        size: 18, color: Colors.amber),
                    const Text(
                      '완주!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5일 카드 목록
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            final dayKey = 'day${index + 1}';
            final devotional = widget.sermon.devotionals[dayKey] ?? '';
            final isCompleted = progress?.completedDays[dayKey] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.secondary.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.secondary.withValues(alpha: 0.45)
                      : AppColors.primary.withValues(alpha: 0.18),
                  width: isCompleted ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 요일 뱃지 + 체크박스
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.secondary.withValues(alpha: 0.55)
                                : AppColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${days[index]}요일',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_userId != null)
                          GestureDetector(
                            onTap: () => _toggleDay(dayKey, !isCompleted),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.secondary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isCompleted
                                      ? AppColors.secondary
                                      : AppColors.textHint,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: isCompleted
                                    ? Colors.white
                                    : AppColors.textHint,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 묵상 본문
                    Text(
                      devotional.isEmpty ? '묵상 내용이 없습니다' : devotional,
                      style: TextStyle(
                        fontSize: 15,
                        color: devotional.isEmpty
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                        height: 1.65,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 15,
                              color: AppColors.secondary
                                  .withValues(alpha: 0.8)),
                          const SizedBox(width: 5),
                          Text(
                            '묵상 완료',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary
                                  .withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
