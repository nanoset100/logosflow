import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/models/user_progress_model.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/activity_service.dart';

class DevotionalsScreen extends StatefulWidget {
  final SermonModel sermon;

  const DevotionalsScreen({super.key, required this.sermon});

  @override
  State<DevotionalsScreen> createState() => _DevotionalsScreenState();
}

class _DevotionalsScreenState extends State<DevotionalsScreen> {
  final ProgressService _progressService = ProgressService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('주중 묵상'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _userId == null
          ? _buildList(days, null)
          : StreamBuilder<UserProgressModel?>(
              stream: _progressService.getProgressStream(
                  _userId!, widget.sermon.id),
              builder: (context, snapshot) {
                return _buildList(days, snapshot.data);
              },
            ),
    );
  }

  Widget _buildList(List<String> days, UserProgressModel? progress) {
    final completedCount = progress?.completedCount ?? 0;

    return Column(
      children: [
        // 설교 제목 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.primary.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.sermon.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.track_changes,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '이번 주 묵상 진행: $completedCount / 6일',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (completedCount == 6)
                    const Row(
                      children: [
                        Icon(Icons.star, size: 15, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          '완주!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        // 진행 바
        LinearProgressIndicator(
          value: completedCount / 6,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),

        // 묵상 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (context, index) {
              final dayKey = 'day${index + 1}';
              final devotional = widget.sermon.devotionals[dayKey] ?? '';
              final isCompleted = progress?.completedDays[dayKey] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCompleted
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.primary.withValues(alpha: 0.2),
                    width: isCompleted ? 1.5 : 1,
                  ),
                ),
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
                              color: isCompleted
                                  ? AppColors.primary.withValues(alpha: 0.6)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${days[index]}요일',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_userId != null)
                            GestureDetector(
                              onTap: () => _toggleDay(dayKey, !isCompleted),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isCompleted
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.check,
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
                      devotional.isEmpty
                          ? Text(
                              '묵상 내용이 없습니다',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textHint,
                                height: 1.5,
                              ),
                            )
                          : MarkdownBody(
                              data: devotional,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                  height: 1.6,
                                ),
                                strong: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                      if (isCompleted) ...[
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              '묵상 완료',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
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
        ),
      ],
    );
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
}
