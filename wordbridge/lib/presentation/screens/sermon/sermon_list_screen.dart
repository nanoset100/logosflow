import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/services/sermon_service.dart';
import 'sermon_detail_screen.dart';

class SermonListScreen extends StatefulWidget {
  const SermonListScreen({super.key});

  @override
  State<SermonListScreen> createState() => _SermonListScreenState();
}

class _SermonListScreenState extends State<SermonListScreen> {
  final SermonService _sermonService = SermonService();
  final AuthService _authService = AuthService();
  String? _churchCode;

  @override
  void initState() {
    super.initState();
    _loadChurchCode();
  }

  Future<void> _loadChurchCode() async {
    final code = await _authService.getSavedChurchCode();
    setState(() {
      _churchCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_churchCode == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('설교 노트'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<SermonModel>>(
        stream: _sermonService.getSermons(_churchCode!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류가 발생했습니다: ${snapshot.error}'),
            );
          }

          final sermons = snapshot.data ?? [];

          if (sermons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 80,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 설교가 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sermons.length,
            itemBuilder: (context, index) {
              final sermon = sermons[index];
              return _SermonCard(
                sermon: sermon,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SermonDetailScreen(sermon: sermon),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SermonCard extends StatelessWidget {
  final SermonModel sermon;
  final VoidCallback onTap;

  const _SermonCard({
    required this.sermon,
    required this.onTap,
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
              // 날짜
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
