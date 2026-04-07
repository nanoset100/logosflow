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

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return SermonModel(
      id: doc.id,
      churchCode: data['churchCode'] ?? '',
      title: data['title'] ?? '',
      date: parseDate(data['date']),
      pastor: data['pastor'] ?? '',
      bibleVerse: data['bibleVerse'] ?? '',
      summary: data['summary'] ?? '',
      audioUrl: data['audioUrl'],
      devotionals: _parseDevotionals(data['devotionals']),
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      createdAt: parseDate(data['createdAt']),
    );
  }

  static Map<String, String> _parseDevotionals(dynamic raw) {
    if (raw == null) return {};
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
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

  // JSON 직렬화 (로컬 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'churchCode': churchCode,
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'pastor': pastor,
      'bibleVerse': bibleVerse,
      'summary': summary,
      'audioUrl': audioUrl,
      'devotionals': devotionals,
      'keyPoints': keyPoints,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SermonModel.fromJson(Map<String, dynamic> data) {
    return SermonModel(
      id: data['id'] ?? '',
      churchCode: data['churchCode'] ?? '',
      title: data['title'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      pastor: data['pastor'] ?? '',
      bibleVerse: data['bibleVerse'] ?? '',
      summary: data['summary'] ?? '',
      audioUrl: data['audioUrl'],
      devotionals: Map<String, String>.from(data['devotionals'] ?? {}),
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
    );
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
