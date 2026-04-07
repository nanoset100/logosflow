import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/sermon_register_screen.dart';
import '../admin/members_screen.dart';
import '../sermon/sermon_list_screen.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/member_service.dart';

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
      automaticallyImplyLeading: false,
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
                childAspectRatio: 0.78,
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
                  '주일 설교 요약 → 5일 묵상\n한국 대표 목회자 말씀을 오늘 내 삶에!',
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
          builder: (_) => SermonListScreen(
            churchCode: pastor.churchCode,
            pastorName: pastor.name,
            churchName: pastor.church,
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
            const SizedBox(height: 6),
            Container(
              width: 80,
              height: 80,
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
                          style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  pastor.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
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
          onTap: () => _showChurchRequestSheet(context),
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
// ─── 교회 추가 신청 바텀시트 ──────────────────────────
void _showChurchRequestSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          // 아이콘
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.church_outlined, size: 32, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 16),
          const Text(
            '우리 교회/목사님 추가 신청',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          const Text(
            '아래 이메일로 신청해 주시면\n무료로 등록해 드립니다 🙏',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF757575), height: 1.5),
          ),
          const SizedBox(height: 24),
          // 이메일 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('신청 이메일', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 20, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    const Text('nanoset@naver.com',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: 'nanoset@naver.com'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이메일이 복사되었습니다 📋'), duration: Duration(seconds: 2)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('복사', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 신청 내용 안내
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📝 신청 시 포함할 내용', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5D4037))),
                SizedBox(height: 8),
                Text('• 교회명\n• 목사님 성함\n• 교회 홈페이지 또는 유튜브 채널 URL',
                  style: TextStyle(fontSize: 13, color: Color(0xFF795548), height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 닫기 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('닫기', style: TextStyle(color: Color(0xFF757575))),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PastorData {
  final String name;
  final String church;
  final String churchCode;
  final String emoji;
  final Color color;
  final String imagePath;
  const _PastorData({
    required this.name,
    required this.church,
    required this.churchCode,
    required this.emoji,
    required this.color,
    required this.imagePath,
  });
}

const _pastors = [
  _PastorData(
    name: '이찬수 목사',
    church: '분당우리교회',
    churchCode: '1001',
    emoji: '✝️',
    color: Color(0xFF1565C0),
    imagePath: 'assets/images/pastors/pastor_lee_chansu.png',
  ),
  _PastorData(
    name: '이재훈 목사',
    church: '온누리교회',
    churchCode: '1002',
    emoji: '🕊️',
    color: Color(0xFF2E7D32),
    imagePath: 'assets/images/pastors/pastor_lee_jaehoon.png',
  ),
  _PastorData(
    name: '오정현 목사',
    church: '사랑의교회',
    churchCode: '1009',
    emoji: '❤️',
    color: Color(0xFFC62828),
    imagePath: 'assets/images/pastors/pastor_oh_junghyun.png',
  ),
  _PastorData(
    name: '유기성 목사',
    church: '선한목자교회',
    churchCode: '1003',
    emoji: '🌿',
    color: Color(0xFF00695C),
    imagePath: 'assets/images/pastors/pastor_yoo_kisung.png',
  ),
  _PastorData(
    name: '진재혁 목사',
    church: '지구촌교회',
    churchCode: '1004',
    emoji: '🌏',
    color: Color(0xFF4527A0),
    imagePath: 'assets/images/pastors/pastor_jin_jaehyuk.png',
  ),
  _PastorData(
    name: '김은호 목사',
    church: '오륜교회',
    churchCode: '1005',
    emoji: '🔥',
    color: Color(0xFFE65100),
    imagePath: 'assets/images/pastors/pastor_kim_eunho.png',
  ),
  _PastorData(
    name: '김삼환 목사',
    church: '명성교회',
    churchCode: '1006',
    emoji: '⭐',
    color: Color(0xFFF57F17),
    imagePath: 'assets/images/pastors/pastor_kim_samhwan.png',
  ),
  _PastorData(
    name: '이영훈 목사',
    church: '여의도순복음',
    churchCode: '1007',
    emoji: '🌊',
    color: Color(0xFF0277BD),
    imagePath: 'assets/images/pastors/pastor_lee_younghoon.png',
  ),
  _PastorData(
    name: '소강석 목사',
    church: '새에덴교회',
    churchCode: '1008',
    emoji: '🌸',
    color: Color(0xFF6A1B9A),
    imagePath: 'assets/images/pastors/pastor_so_kangseok.png',
  ),
];
