import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sermon_model.dart';

class SermonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 교회의 설교 목록 가져오기 (최신순)
  Stream<List<SermonModel>> getSermons(String churchCode) {
    return _firestore
        .collection('churches')
        .doc(churchCode)
        .collection('sermons')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SermonModel.fromFirestore(doc))
          .toList();
    });
  }

  // 특정 설교 가져오기
  Future<SermonModel?> getSermon(String churchCode, String sermonId) async {
    try {
      final doc = await _firestore
          .collection('churches')
          .doc(churchCode)
          .collection('sermons')
          .doc(sermonId)
          .get();

      if (doc.exists) {
        return SermonModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 설교 추가 (목사용 - 나중에 구현)
  Future<String?> addSermon(SermonModel sermon) async {
    try {
      final docRef = await _firestore
          .collection('churches')
          .doc(sermon.churchCode)
          .collection('sermons')
          .add(sermon.toFirestore());

      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // 설교 수정 (목사용 - 나중에 구현)
  Future<bool> updateSermon(
    String churchCode,
    String sermonId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection('churches')
          .doc(churchCode)
          .collection('sermons')
          .doc(sermonId)
          .update(updates);

      return true;
    } catch (e) {
      return false;
    }
  }

  // 설교 삭제 (목사용 - 나중에 구현)
  Future<bool> deleteSermon(String churchCode, String sermonId) async {
    try {
      await _firestore
          .collection('churches')
          .doc(churchCode)
          .collection('sermons')
          .doc(sermonId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  // 이번 주 설교 가져오기 (가장 최근)
  Future<SermonModel?> getLatestSermon(String churchCode) async {
    try {
      final snapshot = await _firestore
          .collection('churches')
          .doc(churchCode)
          .collection('sermons')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SermonModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
