import 'package:cloud_firestore/cloud_firestore.dart';

class PrayerRequestModel {
  final String id;
  final String title;
  final String category;
  final bool isAnswered;
  final DateTime createdAt;

  PrayerRequestModel({
    required this.id,
    required this.title,
    required this.category,
    required this.isAnswered,
    required this.createdAt,
  });

  factory PrayerRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrayerRequestModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? '개인',
      isAnswered: data['isAnswered'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'isAnswered': isAnswered,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PrayerRequestModel copyWith({bool? isAnswered}) {
    return PrayerRequestModel(
      id: id,
      title: title,
      category: category,
      isAnswered: isAnswered ?? this.isAnswered,
      createdAt: createdAt,
    );
  }
}
