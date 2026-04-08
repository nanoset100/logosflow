import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<bool> isAdmin(String churchCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;
      final doc = await _firestore.collection('churches').doc(churchCode).get();
      if (!doc.exists) return false;
      final adminEmails = List<String>.from(doc.data()!['adminEmails'] ?? []);
      return adminEmails.contains(user.email);
    } catch (e) {
      return false;
    }
  }
}
