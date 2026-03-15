import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../devotion/group_devotion_screen.dart';
import '../admin/sermon_register_screen.dart';
import '../admin/members_screen.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/member_service.dart';
import '../../../data/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false;
  String? _churchCode;

  @override
  void initState() {
    super.initState();
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('church_code') ?? '';
    if (code.isEmpty) return;
    final adminResult = await AdminService().isAdmin(code);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await MemberService.recordActivity(churchCode: code, uid: uid);
    }
    if (uid != null) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await MemberService.syncFcmToken(churchCode: code, uid: uid, fcmToken: token);
        if (adminResult) {
          await MemberService.saveAdminToken(churchCode: code, fcmToken: token);
        }
      }
    }
    if (mounted) setState(() { _isAdmin = adminResult; _churchCode = code; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context),
      body: const _WordBridgeHomeBody(),
      floatingActionButton: _isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'members',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MembersScreen()),
                  ),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.people, color: Color(0xFF1565C0)),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'sermon',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SermonRegisterScreen()),
                  ),
                  backgroundColor: const Color(0xFF1565C0),
                  icon: const Icon(Icons.upload_rounded, color: Colors.white),
                  label: const Text(
                    '설교 등록',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, size: 26),
        color: const Color(0xFF1A1A2E),
        onPressed: () {},
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_book_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            '말씀브릿지',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  size: 26, color: Color(0xFF1A1A2E)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 기능은 준비 중입니다.')),
                );
              },
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF5350),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 홈 바디 ─────────────────────────────────────
class _WordBridgeHomeBody extends StatelessWidget {
  const _WordBridgeHomeBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. 인기 목회자 그리드 (상단)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '인기 목회자 말씀 묵상',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('📌', style: TextStyle(fontSize: 15)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '국내 대표 교회 목회자의 말씀을 만나보세요',
                style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.60,
                children:
                    _pastors.map((p) => _PastorCard(pastor: p)).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. 오늘의 말씀 배너 (하단으로 이동)
        const _DailyWordBanner(),

        const SizedBox(height: 24),

        // 3. CTA 버튼
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _CtaButton(),
        ),
        const SizedBox(height: 24),

        // 4. 크로스 프로모션
        const _CrossPromoSection(),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── 앱 소개 배너 ─────────────────────────────────
class _DailyWordBanner extends StatelessWidget {
  const _DailyWordBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 태그 칩
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 4),
                      Text(
                        'AI 말씀비서',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // 메인 헤드카피
                const Text(
                  '말씀이 삶이 되는 순간',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                // 서브카피
                Text(
                  '말씀브릿지 AI 말씀비서가 도와드립니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                // 미니 설명
                Text(
                  '주일 설교 AI 요약 → 5일 묵상\n한국 대표 목회자 말씀을 오늘 내 삶에!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 크로스 프로모션 섹션 ─────────────────────────────
class _CrossPromoSection extends StatelessWidget {
  const _CrossPromoSection();

  static const _apps = [
    _PromoApp(
      emoji: '🙏',
      name: '대표기도',
      description: 'AI가 대신 드리는 대표 기도',
      color: Color(0xFF5C6BC0),
      playUrl:
          'https://play.google.com/store/apps/details?id=com.nanoset.repre_prayer_app',
    ),
    _PromoApp(
      emoji: '📖',
      name: '왕초보 성경통독',
      description: '쉽게 읽는 성경 완독 챌린지',
      color: Color(0xFF2E7D32),
      playUrl:
          'https://play.google.com/store/apps/details?id=com.bible_app.king_beginner_bible',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🙏 함께 쓰면 더 좋은 앱',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _PromoCard(app: _apps[0])),
              const SizedBox(width: 12),
              Expanded(child: _PromoCard(app: _apps[1])),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoApp {
  final String emoji;
  final String name;
  final String description;
  final Color color;
  final String playUrl;
  const _PromoApp({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
    required this.playUrl,
  });
}

class _PromoCard extends StatelessWidget {
  final _PromoApp app;
  const _PromoCard({required this.app});

  Future<void> _launch() async {
    final uri = Uri.parse(app.playUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘 원형 배경
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: app.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(app.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 10),
            // 앱 이름
            Text(
              app.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 설명
            Text(
              app.description,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF757575),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Play 스토어 링크
            Row(
              children: [
                Text(
                  'Play 스토어',
                  style: TextStyle(
                    fontSize: 11,
                    color: app.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 10, color: app.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 목사님 카드 ──────────────────────────────────
class _PastorCard extends StatelessWidget {
  final _PastorData pastor;
  const _PastorCard({required this.pastor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDevotionScreen(
            sermon: _buildDummySermon(pastor),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // 대문짝만한 캐리커처 아바타
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: pastor.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  pastor.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          pastor.color.withValues(alpha: 0.85),
                          pastor.color,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(pastor.emoji,
                          style: const TextStyle(fontSize: 42)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 이름만
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                pastor.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ─── 하단 CTA 버튼 ────────────────────────────────
class _CtaButton extends StatelessWidget {
  const _CtaButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: () async {
            final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: 'nanoset@naver.com',
              queryParameters: {
                'subject': '말씀브릿지 교회 추가 신청',
              },
            );
            
            if (await canLaunchUrl(emailLaunchUri)) {
              await launchUrl(emailLaunchUri);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('메일 앱을 실행할 수 없습니다.')),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Text('📢', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '우리 교회/목사님 추가 신청하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '입점 문의 · 무료로 시작하세요',
                        style:
                            TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 목사님 데이터 ─────────────────────────────────
class _PastorData {
  final String name;
  final String church;
  final String emoji;
  final Color color;
  final String imagePath; // 실제 캐리커처 PNG 경로 (없으면 emoji fallback)
  const _PastorData({
    required this.name,
    required this.church,
    required this.emoji,
    required this.color,
    required this.imagePath,
  });
}

// ─── 더미 설교 데이터 생성 ───────────────────────────
SermonModel _buildDummySermon(_PastorData p) {
  final now = DateTime.now();
  final name = p.name.replaceAll(' 목사', '');
  return SermonModel(
    id: 'dummy_${p.name.hashCode.abs()}',
    churchCode: p.church,
    title: _dummyTitles[p.name] ?? '은혜 위에 은혜',
    date: now,
    pastor: name,
    bibleVerse: _dummyVerses[p.name] ?? '요한복음 1:16',
    summary: '### 핵심 교훈\n\n'
        '- **$name 목사님**의 말씀을 통해 하나님의 은혜를 새롭게 경험합니다.\n'
        '- 주님의 말씀이 우리 삶의 나침반이 되어야 합니다.\n\n'
        '> 이 말씀은 우리가 어떻게 살아야 하는지 명확한 방향을 제시합니다.',
    devotionals: {
      'day1': '오늘 말씀에서 받은 은혜를 한 가지 적어보며 주님께 감사합니다.',
      'day2': '나의 삶에서 믿음으로 순종해야 할 영역은 어디인지 묵상합니다.',
      'day3': '말씀 속에서 발견한 하나님의 성품을 묵상하고 닮기를 구합니다.',
      'day4': '이 말씀을 이웃과 함께 나눌 방법을 생각하고 실천합니다.',
      'day5': '한 주간 말씀대로 살았던 순간을 돌아보며 감사로 마무리합니다.',
    },
    keyPoints: [],
    createdAt: now,
  );
}

const _dummyTitles = {
  '이찬수 목사': '은혜 위에 은혜',
  '이재훈 목사': '복음의 능력',
  '오정현 목사': '사랑으로 하나 되라',
  '유기성 목사': '선한 목자를 따라서',
  '진재혁 목사': '온 세상에 복음을',
  '김은호 목사': '성령의 불꽃',
  '김삼환 목사': '하나님의 영광을 위하여',
  '이영훈 목사': '성령 충만한 삶',
  '소강석 목사': '새 하늘 새 땅을 바라보며',
};

const _dummyVerses = {
  '이찬수 목사': '요한복음 1:16',
  '이재훈 목사': '로마서 1:16',
  '오정현 목사': '에베소서 4:3',
  '유기성 목사': '시편 23:1',
  '진재혁 목사': '마태복음 28:19',
  '김은호 목사': '사도행전 1:8',
  '김삼환 목사': '이사야 43:7',
  '이영훈 목사': '에베소서 5:18',
  '소강석 목사': '요한계시록 21:1',
};

const _pastors = [
  _PastorData(
    name: '이찬수 목사',
    church: '분당우리교회',
    emoji: '✝️',
    color: Color(0xFF1565C0),
    imagePath: 'assets/images/pastors/pastor_lee_chansu.png',
  ),
  _PastorData(
    name: '이재훈 목사',
    church: '온누리교회',
    emoji: '🕊️',
    color: Color(0xFF2E7D32),
    imagePath: 'assets/images/pastors/pastor_lee_jaehoon.png',
  ),
  _PastorData(
    name: '오정현 목사',
    church: '사랑의교회',
    emoji: '❤️',
    color: Color(0xFFC62828),
    imagePath: 'assets/images/pastors/pastor_oh_junghyun.png',
  ),
  _PastorData(
    name: '유기성 목사',
    church: '선한목자교회',
    emoji: '🌿',
    color: Color(0xFF00695C),
    imagePath: 'assets/images/pastors/pastor_yoo_kisung.png',
  ),
  _PastorData(
    name: '진재혁 목사',
    church: '지구촌교회',
    emoji: '🌏',
    color: Color(0xFF4527A0),
    imagePath: 'assets/images/pastors/pastor_jin_jaehyuk.png',
  ),
  _PastorData(
    name: '김은호 목사',
    church: '오륜교회',
    emoji: '🔥',
    color: Color(0xFFE65100),
    imagePath: 'assets/images/pastors/pastor_kim_eunho.png',
  ),
  _PastorData(
    name: '김삼환 목사',
    church: '명성교회',
    emoji: '⭐',
    color: Color(0xFFF57F17),
    imagePath: 'assets/images/pastors/pastor_kim_samhwan.png',
  ),
  _PastorData(
    name: '이영훈 목사',
    church: '여의도순복음',
    emoji: '🌊',
    color: Color(0xFF0277BD),
    imagePath: 'assets/images/pastors/pastor_lee_younghoon.png',
  ),
  _PastorData(
    name: '소강석 목사',
    church: '새에덴교회',
    emoji: '🌸',
    color: Color(0xFF6A1B9A),
    imagePath: 'assets/images/pastors/pastor_so_kangseok.png',
  ),
];
