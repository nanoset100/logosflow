import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/services/saved_sermon_service.dart';
import '../sermon/sermon_detail_screen.dart';

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
        title: Text('저장한 설교 (${_sermons.length})'),
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
                    return _SavedSermonCard(
                      sermon: _sermons[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SermonDetailScreen(sermon: _sermons[index]),
                        ),
                      ).then((_) => _loadSermons()),
                      onUnsave: () => _unsave(_sermons[index]),
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
          Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            '저장한 설교가 없습니다',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            '설교 요약 탭에서 저장하기를 눌러보세요',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ─── 저장된 설교 카드 ──────────────────────────────
class _SavedSermonCard extends StatelessWidget {
  final SermonModel sermon;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedSermonCard({
    required this.sermon,
    required this.onTap,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // 플레이 아이콘
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              // 제목 + 날짜
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sermon.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${sermon.date.month}월 ${sermon.date.day}일',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              // 저장 해제 버튼
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.grey.shade400, size: 22),
                onPressed: onUnsave,
                tooltip: '저장 해제',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
