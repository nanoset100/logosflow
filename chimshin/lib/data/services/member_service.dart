import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MemberModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 성도, 집사, 권사, 장로 등
  final DateTime? joinedAt;
  final String? fcmToken;
  final int? birthMonth;
  final int? birthDay;
  final int? birthYear;

  MemberModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role = '성도',
    this.joinedAt,
    this.fcmToken,
    this.birthMonth,
    this.birthDay,
    this.birthYear,
  });

  String get birthdayText {
    if (birthMonth == null || birthDay == null) return '';
    return '$birthMonth/$birthDay';
  }

  factory MemberModel.fromFirestore(Map<String, dynamic> data) {
    return MemberModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? data['email']?.split('@')[0] ?? '이름 없음',
      email: data['email'] ?? '',
      role: data['role'] ?? '성도',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'],
      birthMonth: data['birthMonth'] as int?,
      birthDay: data['birthDay'] as int?,
      birthYear: data['birthYear'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'role': role,
    'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
    if (fcmToken != null) 'fcmToken': fcmToken,
  };
}

class MemberService {
  static final _firestore = FirebaseFirestore.instance;

  /// 교인 목록 스트림 (실시간)
  static Stream<List<MemberModel>> membersStream(String churchCode) {
    return _firestore
        .collection('churches')
        .doc(churchCode)
        .collection('members')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MemberModel.fromFirestore(d.data()))
            .toList());
  }

  /// 로그인/회원가입 시 교인 자동 등록
  static Future<void> registerMember({
    required String churchCode,
    required String uid,
    required String email,
    String? name,
    String role = '성도',
  }) async {
    final ref = _firestore
        .collection('churches')
        .doc(churchCode)
        .collection('members')
        .doc(uid);

    // 이미 등록된 경우 이름/역할만 업데이트하지 않음
    final existing = await ref.get();
    if (existing.exists) return;

    await ref.set({
      'uid': uid,
      'email': email,
      'name': name ?? email.split('@')[0],
      'role': role,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[Member] 교인 등록 완료: $email');
  }

  /// 교인 생일 업데이트
  static Future<void> updateBirthday({
    required String churchCode,
    required String uid,
    required int birthMonth,
    required int birthDay,
    int? birthYear,
  }) async {
    await _firestore
        .collection('churches')
        .doc(churchCode)
        .collection('members')
        .doc(uid)
        .update({
      'birthMonth': birthMonth,
      'birthDay': birthDay,
      if (birthYear != null) 'birthYear': birthYear,
    });
  }

  /// 목사님(관리자) FCM 토큰을 church 문서에 저장 (생일 알림 수신용)
  static Future<void> saveAdminToken({
    required String churchCode,
    required String fcmToken,
  }) async {
    await _firestore.collection('churches').doc(churchCode).update({
      'adminFcmTokens': FieldValue.arrayUnion([fcmToken]),
    });
  }

  /// FCM 토큰 동기화 (users/{uid}.fcmToken → members/{uid}.fcmToken)
  static Future<void> syncFcmToken({
    required String churchCode,
    required String uid,
    required String fcmToken,
  }) async {
    await _firestore
        .collection('churches')
        .doc(churchCode)
        .collection('members')
        .doc(uid)
        .update({'fcmToken': fcmToken});
  }

  /// 목사님 → 교인 기도 알림 발송
  static Future<bool> sendPrayerNotification({
    required String memberUid,
    required String churchCode,
    String? memberName,
  }) async {
    try {
      // 1. 교인 FCM 토큰 조회
      final memberDoc = await _firestore
          .collection('churches')
          .doc(churchCode)
          .collection('members')
          .doc(memberUid)
          .get();

      final fcmToken = memberDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('[Notify] FCM 토큰 없음 - $memberUid');
        return false;
      }

      final name = memberName ?? memberDoc.data()?['name'] ?? '성도';

      // 2. 서버로 개인 알림 발송
      final serverUrl = dotenv.env['WHISPER_SERVER_URL'] ?? '';
      final serverKey = dotenv.env['NOTIFY_SERVER_KEY'] ?? '';

      final response = await http.post(
        Uri.parse('$serverUrl/notify/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': '🙏 목사님의 기도',
          'body': '목사님이 오늘 $name님을 위해 기도하셨습니다',
          'data': {'type': 'prayer', 'memberUid': memberUid},
          'server_key': serverKey,
        }),
      );

      if (response.statusCode == 200) {
        // 3. 기도 기록 저장
        await _firestore
            .collection('churches')
            .doc(churchCode)
            .collection('members')
            .doc(memberUid)
            .collection('prayers')
            .add({
          'prayedAt': FieldValue.serverTimestamp(),
          'type': 'pastor_prayer',
        });
        debugPrint('[Notify] 기도 알림 발송 완료: $name');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[Notify] 기도 알림 실패: $e');
      return false;
    }
  }
}
