import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_progress_model.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _docId(String userId, String sermonId) => '${userId}_$sermonId';

  // 실시간 진행 상황 스트림
  Stream<UserProgressModel?> getProgressStream(String userId, String sermonId) {
    return _firestore
        .collection('userProgress')
        .doc(_docId(userId, sermonId))
        .snapshots()
        .map((doc) => doc.exists ? UserProgressModel.fromFirestore(doc) : null);
  }

  // 특정 날 완료 여부 토글
  Future<void> toggleDay({
    required String userId,
    required String sermonId,
    required String churchCode,
    required String dayKey,
    required bool completed,
  }) async {
    await _firestore
        .collection('userProgress')
        .doc(_docId(userId, sermonId))
        .set({
      'userId': userId,
      'sermonId': sermonId,
      'churchCode': churchCode,
      dayKey: completed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 홈화면용 1회성 조회
  Future<UserProgressModel?> getProgress(
      String userId, String sermonId) async {
    final doc = await _firestore
        .collection('userProgress')
        .doc(_docId(userId, sermonId))
        .get();
    return doc.exists ? UserProgressModel.fromFirestore(doc) : null;
  }
}
