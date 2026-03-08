import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: const _WordBridgeHomeBody(),
    );
  }

  AppBar _buildAppBar() {
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
              onPressed: () {},
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
        // 1. 오늘의 말씀 배너 카드
        const _DailyWordBanner(),
        const SizedBox(height: 24),

        // 2. 인기 목회자 그리드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 섹션 헤딩
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

              // 3x3 목사님 그리드
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children:
                    _pastors.map((p) => _PastorCard(pastor: p)).toList(),
              ),
              const SizedBox(height: 32),

              // 하단 CTA 버튼
              const _CtaButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 오늘의 말씀 배너 ─────────────────────────────
class _DailyWordBanner extends StatelessWidget {
  const _DailyWordBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
          // 배경 장식 원
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 본문
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🥄', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 4),
                      Text(
                        '오늘의 말씀 한 스푼',
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
                const Text(
                  '"믿음은 바라는 것들의\n실상이요, 보이지 않는\n것들의 증거니"',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.55,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '히브리서 11:1',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '묵상하기 →',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
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
      onTap: () => debugPrint('[WordBridge] 탭: ${pastor.name}'),
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
            const SizedBox(height: 14),
            // 아바타: 실제 캐리커처 PNG 또는 이모지 fallback
            Container(
              width: 60,
              height: 60,
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
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 목사님 이름만 (교회명 제거)
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
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pastor.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '말씀 보기',
                style: TextStyle(
                  fontSize: 10,
                  color: pastor.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
          onTap: () => debugPrint('[WordBridge] 교회/목사님 추가 신청'),
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
    imagePath: 'assets/images/pastors/pastor_so_gangseok.png',
  ),
];
