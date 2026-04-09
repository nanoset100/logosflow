import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prayer_request_model.dart';

class PrayerService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference _col(String uid) =>
      _db.collection('users').doc(uid).collection('prayer_requests');

  Stream<List<PrayerRequestModel>> prayerStream(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PrayerRequestModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addPrayer(String uid, String title, String category) async {
    await _col(uid).add({
      'title': title,
      'category': category,
      'isAnswered': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePrayer(String uid, String prayerId) async {
    await _col(uid).doc(prayerId).delete();
  }

  Future<void> toggleAnswered(String uid, String prayerId, bool current) async {
    await _col(uid).doc(prayerId).update({'isAnswered': !current});
  }
}
