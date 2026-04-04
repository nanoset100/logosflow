import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/services/sermon_service.dart';
import '../devotion/group_devotion_screen.dart';

class SermonListScreen extends StatefulWidget {
  final String? churchCode;
  final String? pastorName;
  final String? churchName;

  const SermonListScreen({
    super.key,
    this.churchCode,
    this.pastorName,
    this.churchName,
  });

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
    if (widget.churchCode != null) {
      setState(() => _churchCode = widget.churchCode);
    } else {
      final code = await _authService.getSavedChurchCode();
      setState(() => _churchCode = code);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_churchCode == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = widget.pastorName != null
        ? '${widget.pastorName} 설교'
        : '설교 노트';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: StreamBuilder<List<SermonModel>>(
        stream: _sermonService.getSermons(_churchCode!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.error_outline, size: 48, color: Colors.grey),
                   SizedBox(height: 16),
                   Text('데이터를 불러올 수 없습니다.'),
                ],
              ),
            );
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
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 등록된 설교가 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.churchName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.churchName!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
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
                      builder: (_) => GroupDevotionScreen(sermon: sermon),
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
          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
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
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    '${sermon.formattedDate} (${sermon.dayOfWeek})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sermon.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.menu_book,
                      size: 16, color: Color(0xFF757575)),
                  const SizedBox(width: 8),
                  Text(
                    sermon.bibleVerse,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sermon.summary.replaceAll(RegExp(r'[#*_`>]'), '').trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person,
                      size: 16, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 8),
                  Text(
                    sermon.pastor,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
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
