import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore churches/{code} 문서의 adminEmails 배열에 현재 사용자 이메일이 있으면 관리자
  Future<bool> isAdmin(String churchCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      final doc = await _firestore.collection('churches').doc(churchCode).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final adminEmails = List<String>.from(data['adminEmails'] ?? []);
      return adminEmails.contains(user.email);
    } catch (e) {
      return false;
    }
  }
}
