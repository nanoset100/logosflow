import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgressModel {
  final String userId;
  final String sermonId;
  final String churchCode;
  final Map<String, bool> completedDays; // day1~day5
  final DateTime? updatedAt;

  UserProgressModel({
    required this.userId,
    required this.sermonId,
    required this.churchCode,
    required this.completedDays,
    this.updatedAt,
  });

  factory UserProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProgressModel(
      userId: data['userId'] as String? ?? '',
      sermonId: data['sermonId'] as String? ?? '',
      churchCode: data['churchCode'] as String? ?? '',
      completedDays: {
        'day1': data['day1'] as bool? ?? false,
        'day2': data['day2'] as bool? ?? false,
        'day3': data['day3'] as bool? ?? false,
        'day4': data['day4'] as bool? ?? false,
        'day5': data['day5'] as bool? ?? false,
      },
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // 완료된 묵상 수
  int get completedCount => completedDays.values.where((v) => v).length;
}
