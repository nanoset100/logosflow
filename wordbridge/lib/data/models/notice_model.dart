import 'package:cloud_firestore/cloud_firestore.dart';

enum NoticeCategory { denomination, church }

class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime date;
  final NoticeCategory category;
  final bool isPinned;

  const NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
    required this.category,
    this.isPinned = false,
  });

  String get previewContent {
    final plain = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return plain.length > 80 ? '${plain.substring(0, 80)}...' : plain;
  }

  String get formattedDate {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  factory NoticeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoticeModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      author: data['author'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: (data['category'] as String?) == 'church'
          ? NoticeCategory.church
          : NoticeCategory.denomination,
      isPinned: data['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'author': author,
        'date': Timestamp.fromDate(date),
        'category': category == NoticeCategory.church ? 'church' : 'denomination',
        'isPinned': isPinned,
      };
}
