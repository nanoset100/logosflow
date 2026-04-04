import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/prayer_request_model.dart';
import '../../../data/services/prayer_service.dart';

class PrayerRequestsScreen extends StatefulWidget {
  const PrayerRequestsScreen({super.key});

  @override
  State<PrayerRequestsScreen> createState() => _PrayerRequestsScreenState();
}

class _PrayerRequestsScreenState extends State<PrayerRequestsScreen> {
  final _prayerService = PrayerService();
  final _titleController = TextEditingController();
  String _selectedCategory = '개인';
  String? _uid;

  static const _categories = ['개인', '가족', '직장', '교회', '건강', '기타'];

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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

  void _showAddDialog() {
    _titleController.clear();
    _selectedCategory = '개인';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '새로운 기도제목 추가',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '기도제목을 입력하세요',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                maxLines: 2,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                '카테고리',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setLocal(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? _categoryColor(cat)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? _categoryColor(cat)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소',
                  style: TextStyle(color: AppColors.textHint)),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = _titleController.text.trim();
                if (title.isEmpty || _uid == null) return;
                await _prayerService.addPrayer(_uid!, title, _selectedCategory);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('나의 기도제목'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<PrayerRequestModel>>(
        stream: _prayerService.prayerStream(_uid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final prayers = snapshot.data ?? [];

          if (prayers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🙏', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    '기도제목이 없습니다',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '아래 + 버튼을 눌러 기도제목을 추가해보세요',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prayers.length,
            itemBuilder: (context, index) {
              final prayer = prayers[index];
              return Dismissible(
                key: Key(prayer.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white, size: 26),
                ),
                onDismissed: (_) =>
                    _prayerService.deletePrayer(_uid!, prayer.id),
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: prayer.isAnswered
                      ? Colors.green.shade50
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: prayer.isAnswered
                          ? Colors.green.shade200
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _categoryColor(prayer.category),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        prayer.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      prayer.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        decoration: prayer.isAnswered
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.green.shade400,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (prayer.isAnswered)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
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
                        Switch(
                          value: prayer.isAnswered,
                          onChanged: (_) => _prayerService.toggleAnswered(
                              _uid!, prayer.id, prayer.isAnswered),
                          activeColor: Colors.green,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }
}
