import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/services/saved_sermon_service.dart';
import '../devotion/group_devotion_screen.dart'; // 수정: SermonDetailScreen 대신 GroupDevotionScreen

class SavedSermonsScreen extends StatefulWidget {
  const SavedSermonsScreen({super.key});

  @override
  State<SavedSermonsScreen> createState() => _SavedSermonsScreenState();
}

class _SavedSermonsScreenState extends State<SavedSermonsScreen> {
  final _savedService = SavedSermonService();
  List<SermonModel> _sermons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSermons();
  }

  Future<void> _loadSermons() async {
    setState(() => _isLoading = true);
    final sermons = await _savedService.getSavedSermons();
    if (mounted) setState(() { _sermons = sermons; _isLoading = false; });
  }

  Future<void> _unsave(SermonModel sermon) async {
    await _savedService.unsaveSermon(sermon.id);
    if (mounted) {
      setState(() => _sermons.removeWhere((s) => s.id == sermon.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('저장이 해제되었습니다'),
          action: SnackBarAction(
            label: '되돌리기',
            onPressed: () async {
              await _savedService.saveSermon(sermon);
              _loadSermons();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('설교 노트'), // 수정: 제목 변경
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sermons.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sermons.length,
                  itemBuilder: (context, index) {
                    final sermon = _sermons[index];
                    return _SermonCard(
                      sermon: sermon,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDevotionScreen(sermon: sermon),
                        ),
                      ).then((_) => _loadSermons()),
                      onUnsave: () => _unsave(sermon),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey.shade300), // 아이콘 변경
          const SizedBox(height: 16),
          const Text(
            '아직 보관된 설교 노트가 없습니다',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            '홈 화면에서 설교를 눌러 저장해보세요',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ─── 침신 앱 스타일 설교 카드 ──────────────────────────
class _SermonCard extends StatelessWidget {
  final SermonModel sermon;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SermonCard({
    required this.sermon,
    required this.onTap,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 날짜와 저장 해제 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${sermon.formattedDate} (${sermon.dayOfWeek})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Colors.grey.shade400, size: 20),
                    onPressed: onUnsave,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: '저장 해제',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 제목
              Text(
                sermon.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // 본문
              Row(
                children: [
                  const Icon(Icons.menu_book, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    sermon.bibleVerse,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 요약
              Text(
                sermon.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              // 목사님
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(
                    sermon.pastor,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
