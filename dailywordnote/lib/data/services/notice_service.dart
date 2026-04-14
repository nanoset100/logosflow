import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';

class NoticeService {
  final _db = FirebaseFirestore.instance;

  /// 교회 공지 추가 (Firestore 저장)
  Future<void> addChurchNotice({
    required String churchCode,
    required String churchName,
    required String title,
    required String content,
    required String author,
  }) async {
    final notice = NoticeModel(
      id: '',
      title: title,
      content: content,
      author: author,
      date: DateTime.now(),
      category: NoticeCategory.church,
      isPinned: false,
    );

    await _db
        .collection('churches')
        .doc(churchCode)
        .collection('notices')
        .add(notice.toJson());
  }

  /// 교회 공지 삭제
  Future<void> deleteChurchNotice(String churchCode, String noticeId) async {
    await _db
        .collection('churches')
        .doc(churchCode)
        .collection('notices')
        .doc(noticeId)
        .delete();
  }

  // ─── 교단/학교 공지 (전체 공통) ────────────────────
  // Firestore: notices/{id}
  Stream<List<NoticeModel>> denominationNoticesStream() {
    return _db
        .collection('notices')
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NoticeModel.fromFirestore(d)).toList());
  }

  Future<List<NoticeModel>> getDenominationNotices() async {
    final snap = await _db
        .collection('notices')
        .orderBy('date', descending: true)
        .limit(30)
        .get();
    return snap.docs.map((d) => NoticeModel.fromFirestore(d)).toList();
  }

  // ─── 우리 교회 공지 (교회별) ──────────────────────
  // Firestore: churches/{churchCode}/notices/{id}
  Stream<List<NoticeModel>> churchNoticesStream(String churchCode) {
    return _db
        .collection('churches')
        .doc(churchCode)
        .collection('notices')
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NoticeModel.fromFirestore(d)).toList());
  }

  Future<List<NoticeModel>> getChurchNotices(String churchCode) async {
    final snap = await _db
        .collection('churches')
        .doc(churchCode)
        .collection('notices')
        .orderBy('date', descending: true)
        .limit(30)
        .get();
    return snap.docs.map((d) => NoticeModel.fromFirestore(d)).toList();
  }

  // ─── 시연용 더미 데이터 ───────────────────────────
  static List<NoticeModel> get dummyDenominationNotices => [
        NoticeModel(
          id: 'demo-d1',
          title: '[데일리 말씀노트] 앱 서비스 안내',
          content:
              '데일리 말씀노트 앱을 사용해 주셔서 감사합니다.\n\n'
              '■ 설교 등록: 담임 목사님의 설교를 직접 입력하거나 YouTube 링크로 등록하세요.\n'
              '■ 말씀 묵상: AI가 자동으로 요약하고 5일 묵상 내용을 제공합니다.\n'
              '■ 기도제목: 개인 기도제목을 기록하고 응답을 확인하세요.\n\n'
              '문의 및 불편사항은 앱 내 피드백 기능을 이용해 주세요.',
          author: '데일리 말씀노트 운영팀',
          date: DateTime(2026, 3, 5),
          category: NoticeCategory.denomination,
          isPinned: true,
        ),
        NoticeModel(
          id: 'demo-d2',
          title: '2026년 부활절 연합 예배 안내',
          content:
              '주님의 부활을 함께 기념하는 연합 예배에 초대합니다.\n\n'
              '■ 일시: 2026년 4월 5일(주일) 오전 6시\n'
              '■ 장소: 각 교회 본당\n'
              '■ 주제: 부활의 능력으로\n\n'
              '하나님의 은혜가 여러분 가정에 함께하시기를 바랍니다.',
          author: '데일리 말씀노트 운영팀',
          date: DateTime(2026, 3, 1),
          category: NoticeCategory.denomination,
        ),
        NoticeModel(
          id: 'demo-d3',
          title: 'AI 설교 요약 기능 업데이트 안내',
          content:
              'AI 설교 요약 기능이 더욱 향상되었습니다.\n\n'
              '■ 전체 요약: 3~4문단의 핵심 내용 요약\n'
              '■ 핵심 교훈: 글머리 구조로 정리\n'
              '■ 5일 묵상: 월~금 매일 묵상 가이드 제공\n\n'
              '새로운 기능을 활용해 더 깊은 말씀 묵상을 경험해 보세요.',
          author: '데일리 말씀노트 개발팀',
          date: DateTime(2026, 2, 20),
          category: NoticeCategory.denomination,
        ),
      ];

  static List<NoticeModel> dummyChurchNotices(String churchName) => [
        NoticeModel(
          id: 'demo-c1',
          title: '이번 주일 오후 예배 연합 안내',
          content:
              '사랑하는 성도 여러분, 이번 주일(3월 9일) 오후 예배는 인근 3개 교회 연합으로 진행됩니다.\n\n'
              '■ 일시: 2026년 3월 9일(주일) 오후 3시\n'
              '■ 장소: $churchName 본당\n'
              '■ 특별 찬양: 연합 찬양대\n\n'
              '많은 참석 부탁드립니다. 하나님의 은혜가 함께하시기를 바랍니다.',
          author: '담임목사',
          date: DateTime(2026, 3, 6),
          category: NoticeCategory.church,
          isPinned: true,
        ),
        NoticeModel(
          id: 'demo-c2',
          title: '3월 구역 모임 일정 안내',
          content:
              '3월 구역 모임 일정을 아래와 같이 안내해 드립니다.\n\n'
              '■ 1구역: 3월 11일(화) 오전 10시 / 김순희 집사 댁\n'
              '■ 2구역: 3월 12일(수) 오후 7시 / 교회 소예배실\n'
              '■ 3구역: 3월 13일(목) 오후 7시 / 이진수 집사 댁\n\n'
              '이번 주 구역 예배 교재는 앱의 [구역 예배 교재] 섹션을 활용해 주세요.',
          author: '교구 담당 부목사',
          date: DateTime(2026, 3, 4),
          category: NoticeCategory.church,
        ),
      ];
}
