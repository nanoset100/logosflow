import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';

class NoticeService {
  final _db = FirebaseFirestore.instance;

  // ─── 인메모리 로컬 교회 공지 (시연용) ────────────────
  // 실제 배포 시엔 Firestore에만 저장하고 스트림으로 구독
  static final List<NoticeModel> _localChurchNotices = [];

  static List<NoticeModel> getLocalChurchNotices(String churchName) {
    return [..._localChurchNotices, ...dummyChurchNotices(churchName)];
  }

  /// 교회 공지 추가 (시연용 로컬 + Firestore 뼈대)
  Future<void> addChurchNotice({
    required String churchCode,
    required String churchName,
    required String title,
    required String content,
    required String author,
  }) async {
    final notice = NoticeModel(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      author: author,
      date: DateTime.now(),
      category: NoticeCategory.church,
      isPinned: false,
    );

    // 로컬 인메모리 저장 (시연용)
    _localChurchNotices.insert(0, notice);

    // TODO(배포 전): Firestore 저장 활성화
    // await _db
    //     .collection('churches')
    //     .doc(churchCode)
    //     .collection('notices')
    //     .add(notice.toJson());
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
          title: '[침신대] 2026학년도 신학과 입시 안내',
          content:
              '2026학년도 침례신학대학교 신학과 신·편입학 전형 안내입니다.\n\n'
              '■ 원서 접수 기간: 2026년 4월 1일 ~ 4월 15일\n'
              '■ 전형 방법: 서류 심사 + 면접\n'
              '■ 지원 자격: 고등학교 졸업자 또는 동등 학력 소지자\n\n'
              '자세한 내용은 학교 입학처 홈페이지를 참조하시기 바랍니다.\n'
              '문의: 입학처 042-000-0000',
          author: '침례신학대학교',
          date: DateTime(2026, 3, 5),
          category: NoticeCategory.denomination,
          isPinned: true,
        ),
        NoticeModel(
          id: 'demo-d2',
          title: '[한국침례회] 2026 침례교 전국 연합 부흥회 개최',
          content:
              '한국침례회 총회 주관 2026년 전국 연합 부흥회를 아래와 같이 개최합니다.\n\n'
              '■ 일시: 2026년 4월 20일(월) ~ 22일(수)\n'
              '■ 장소: 수원 올림픽 체육관\n'
              '■ 강사: 이요한 목사 (서울중앙교회)\n\n'
              '전국 모든 침례교회 성도 여러분의 많은 참석 바랍니다.',
          author: '한국침례회 총회',
          date: DateTime(2026, 3, 1),
          category: NoticeCategory.denomination,
        ),
        NoticeModel(
          id: 'demo-d3',
          title: '[침신대] 2026 봄학기 신학 세미나 - 목회와 AI 시대',
          content:
              '현대 목회 환경에서 AI 기술의 활용과 영적 돌봄에 관한 신학 세미나를 개최합니다.\n\n'
              '■ 일시: 2026년 3월 25일(수) 오전 10시\n'
              '■ 장소: 침신대 강당\n'
              '■ 강사: 김신학 교수 (실천신학)\n\n'
              '재학생 및 현장 목회자 참여 환영합니다.',
          author: '침례신학대학교 신학연구원',
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
