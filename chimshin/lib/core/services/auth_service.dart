import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 로그인 사용자
  User? get currentUser => _auth.currentUser;

  // 로그인 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── 교회 코드 검증 (Firestore) ────────────────────
  Future<Map<String, dynamic>?> verifyChurchCode(String code) async {
    try {
      final doc = await _firestore.collection('churches').doc(code).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      if (data['isActive'] != true) return null;

      return data;
    } catch (e) {
      throw Exception('교회 코드 확인 중 오류가 발생했습니다');
    }
  }

  // ─── 이메일 로그인 ────────────────────────────────
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    } catch (e) {
      throw Exception('로그인 중 오류가 발생했습니다');
    }
  }

  // ─── 이메일 회원가입 ──────────────────────────────
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String churchCode,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    } catch (e) {
      // Firebase가 계정을 생성했지만 SDK 내부 오류가 발생한 경우
      // currentUser가 있으면 회원가입 성공으로 처리
      final current = _auth.currentUser;
      if (current != null) return current;
      throw Exception('회원가입 중 오류가 발생했습니다: ${e.runtimeType}');
    }
  }

  // ─── 로그아웃 ─────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Firebase 에러 메시지 한국어 변환 ─────────────
  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return '등록되지 않은 이메일입니다';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다';
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다';
      case 'invalid-email':
        return '이메일 형식이 올바르지 않습니다';
      case 'too-many-requests':
        return '잠시 후 다시 시도해주세요';
      default:
        return '오류가 발생했습니다 ($code)';
    }
  }
}
