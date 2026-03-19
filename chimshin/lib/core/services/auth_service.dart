import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

      return {'code': code, ...data};
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
      // SDK 내부 오류가 발생했지만 실제로 로그인 된 경우 처리
      final current = _auth.currentUser;
      if (current != null) return current;
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalid-credential') || msg.contains('wrong-password') || msg.contains('user-not-found')) {
        throw Exception('이메일 또는 비밀번호가 올바르지 않습니다');
      }
      if (msg.contains('network') || msg.contains('connection') || msg.contains('unavailable') || msg.contains('hostname')) {
        throw Exception('인터넷 연결을 확인해주세요');
      }
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

  // ─── 교회코드 저장 / 로드 (SharedPreferences) ────
  Future<void> saveChurchCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('church_code', code);
  }

  Future<String?> getSavedChurchCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('church_code');
  }

  Future<void> clearChurchCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('church_code');
  }

  // ─── Apple 로그인 ─────────────────────────────────
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null) {
        throw Exception('Apple 인증 토큰을 받지 못했습니다. 잠시 후 다시 시도해주세요.');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
      );

      final result = await _auth.signInWithCredential(oauthCredential);
      return result.user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw Exception('Apple 로그인에 실패했습니다: ${e.message}');
    } on FirebaseAuthException catch (e) {
      throw Exception('Apple 로그인에 실패했습니다 (${e.code})');
    } catch (e) {
      final current = _auth.currentUser;
      if (current != null) return current;
      rethrow;
    }
  }

  // ─── 계정 삭제 ────────────────────────────────────
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // 1. Firestore 사용자 데이터 삭제
    try {
      final prayerSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('prayer_requests')
          .get();
      for (final doc in prayerSnap.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('users').doc(uid).delete();
    } catch (_) {}

    // 2. 로컬 데이터 정리
    await clearChurchCode();
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    // 3. Firebase Auth 계정 삭제
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('보안을 위해 로그아웃 후 다시 로그인한 뒤 계정을 삭제해주세요');
      }
      rethrow;
    }
  }

  // ─── 로그아웃 ─────────────────────────────────────
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    await clearChurchCode();
    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).update({'fcmToken': FieldValue.delete()});
        await FirebaseMessaging.instance.deleteToken();
        await FirebaseMessaging.instance.unsubscribeFromTopic('daily_devotion');
      } catch (_) {}
    }
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
