import 'package:cloud_firestore/cloud_firestore.dart';

class SermonModel {
  final String id;
  final String churchCode;
  final String title;
  final DateTime date;
  final String pastor;
  final String bibleVerse;
  final String summary;
  final String? audioUrl;
  final Map<String, String> devotionals; // day1~day5
  final List<String> keyPoints;
  final DateTime createdAt;

  SermonModel({
    required this.id,
    required this.churchCode,
    required this.title,
    required this.date,
    required this.pastor,
    required this.bibleVerse,
    required this.summary,
    this.audioUrl,
    required this.devotionals,
    required this.keyPoints,
    required this.createdAt,
  });

  // Firestore에서 가져오기
  factory SermonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SermonModel(
      id: doc.id,
      churchCode: data['churchCode'] ?? '',
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      pastor: data['pastor'] ?? '',
      bibleVerse: data['bibleVerse'] ?? '',
      summary: data['summary'] ?? '',
      audioUrl: data['audioUrl'],
      devotionals: Map<String, String>.from(data['devotionals'] ?? {}),
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Firestore에 저장
  Map<String, dynamic> toFirestore() {
    return {
      'churchCode': churchCode,
      'title': title,
      'date': Timestamp.fromDate(date),
      'pastor': pastor,
      'bibleVerse': bibleVerse,
      'summary': summary,
      'audioUrl': audioUrl,
      'devotionals': devotionals,
      'keyPoints': keyPoints,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // 날짜 포맷 (2026년 2월 23일)
  String get formattedDate {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  // 요일 (일요일)
  String get dayOfWeek {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${weekdays[date.weekday - 1]}요일';
  }
}
