import 'package:flutter/material.dart';
import 'home/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    _ArchiveScreen(),
    _PrayerScreen(),
    _SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: const Color(0xFF9E9E9E),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border_rounded),
            activeIcon: Icon(Icons.bookmark_rounded),
            label: '보관함',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
            label: '기도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

// ─── 보관함 (placeholder) ─────────────────────────
class _ArchiveScreen extends StatelessWidget {
  const _ArchiveScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_rounded, size: 64, color: Color(0xFFBDBDBD)),
              SizedBox(height: 16),
              Text('보관함', style: TextStyle(fontSize: 18, color: Color(0xFF757575))),
              SizedBox(height: 8),
              Text('저장한 말씀이 여기에 표시됩니다', style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
            ],
          ),
        ),
      );
}

// ─── 기도 (placeholder) ──────────────────────────
class _PrayerScreen extends StatelessWidget {
  const _PrayerScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, size: 64, color: Color(0xFFBDBDBD)),
              SizedBox(height: 16),
              Text('기도', style: TextStyle(fontSize: 18, color: Color(0xFF757575))),
              SizedBox(height: 8),
              Text('나의 기도제목이 여기에 표시됩니다', style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
            ],
          ),
        ),
      );
}

// ─── 설정 (placeholder) ──────────────────────────
class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_rounded, size: 64, color: Color(0xFFBDBDBD)),
              SizedBox(height: 16),
              Text('설정', style: TextStyle(fontSize: 18, color: Color(0xFF757575))),
              SizedBox(height: 8),
              Text('앱 설정 메뉴가 여기에 표시됩니다', style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
            ],
          ),
        ),
      );
}
