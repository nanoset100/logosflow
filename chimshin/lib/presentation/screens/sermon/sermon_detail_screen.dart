import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/models/user_progress_model.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/tts_service.dart';

class SermonDetailScreen extends StatefulWidget {
  final SermonModel sermon;
  final int initialTabIndex;

  const SermonDetailScreen({
    super.key,
    required this.sermon,
    this.initialTabIndex = 0,
  });

  @override
  State<SermonDetailScreen> createState() => _SermonDetailScreenState();
}

class _SermonDetailScreenState extends State<SermonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('설교 노트'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 설교 정보 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.sermon.formattedDate} (${widget.sermon.dayOfWeek})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 제목
                Text(
                  widget.sermon.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // 본문
                Row(
                  children: [
                    const Icon(Icons.menu_book, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      widget.sermon.bibleVerse,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 목사님
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    Text(
                      widget.sermon.pastor,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 탭바
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: '요약'),
                Tab(text: '핵심 포인트'),
                Tab(text: '주중 묵상'),
              ],
            ),
          ),

          // 탭 컨텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SummaryTab(sermon: widget.sermon),
                _KeyPointsTab(sermon: widget.sermon),
                _DevotionalsTab(sermon: widget.sermon, userId: _userId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 요약 탭 ───────────────────────────────────────
class _SummaryTab extends StatefulWidget {
  final SermonModel sermon;

  const _SummaryTab({required this.sermon});

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> {
  TtsService? _ttsService;
  bool _isLoading = false;
  bool _ttsAvailable = true;
  VoiceType _selectedVoice = VoiceType.male;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    try {
      _ttsService = TtsService();
    } catch (e) {
      _ttsAvailable = false;
    }
  }

  @override
  void dispose() {
    _ttsService?.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_ttsService == null) return;
    setState(() => _isLoading = true);
    try {
      await _ttsService!.speak(widget.sermon.summary, speed: _speed);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오디오 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pauseOrResume() async {
    if (_ttsService == null) return;
    if (_ttsService!.isPaused) {
      await _ttsService!.resume();
    } else {
      await _ttsService!.pause();
    }
    setState(() {});
  }

  Future<void> _stopAudio() async {
    await _ttsService?.stop();
    setState(() {});
  }

  void _changeVoice(VoiceType voice) {
    setState(() {
      _selectedVoice = voice;
      _ttsService?.setVoice(voice);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isActive = (_ttsService?.isPlaying ?? false) ||
        (_ttsService?.isPaused ?? false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '설교 요약',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // ── TTS 불가 안내 ───────────────────────────
          if (!_ttsAvailable)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '오디오 기능을 사용할 수 없습니다',
                      style: TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          // ── 음성 선택 ──────────────────────────────
          if (_ttsAvailable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎙️ 음성 선택',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _VoiceButton(
                        emoji: '👨',
                        label: '남성',
                        isSelected: _selectedVoice == VoiceType.male,
                        color: AppColors.primary,
                        onTap: () => _changeVoice(VoiceType.male),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _VoiceButton(
                        emoji: '👩',
                        label: '여성',
                        isSelected: _selectedVoice == VoiceType.female,
                        color: AppColors.secondary,
                        onTap: () => _changeVoice(VoiceType.female),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── 속도 조절 ──────────────────────
                Row(
                  children: [
                    const Text(
                      '🐢',
                      style: TextStyle(fontSize: 18),
                    ),
                    Expanded(
                      child: Slider(
                        value: _speed,
                        min: 0.5,
                        max: 2.0,
                        divisions: 6,
                        activeColor: _selectedVoice == VoiceType.male
                            ? AppColors.primary
                            : AppColors.secondary,
                        label: '${_speed}x',
                        onChanged: (v) => setState(() => _speed = v),
                      ),
                    ),
                    const Text(
                      '🐇',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_speed}x',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── 재생 컨트롤 ────────────────────
                Row(
                  children: [
                    // 재생 / 일시정지 / 재개 버튼
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : (isActive ? _pauseOrResume : _playAudio),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isActive
                                    ? ((_ttsService?.isPaused ?? false) ? '▶️' : '⏸️')
                                    : '▶️',
                                style: const TextStyle(fontSize: 18),
                              ),
                        label: Text(
                          _isLoading
                              ? '로딩 중...'
                              : (isActive
                                  ? ((_ttsService?.isPaused ?? false) ? '재개' : '일시정지')
                                  : '재생'),
                          style: const TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedVoice == VoiceType.male
                              ? AppColors.primary
                              : AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 정지 버튼 (Row 안 비-Expanded → minimumSize 명시 필수)
                    ElevatedButton(
                      onPressed: isActive ? _stopAudio : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(52, 52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '⏹️',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 요약 텍스트 ────────────────────────────
          Text(
            widget.sermon.summary,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 음성 선택 버튼 위젯 ────────────────────────────────
class _VoiceButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _VoiceButton({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              '$label 음성',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 핵심 포인트 탭 ────────────────────────────────
class _KeyPointsTab extends StatelessWidget {
  final SermonModel sermon;

  const _KeyPointsTab({required this.sermon});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '핵심 포인트',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...sermon.keyPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        point,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── 주중 묵상 탭 ──────────────────────────────────
class _DevotionalsTab extends StatefulWidget {
  final SermonModel sermon;
  final String? userId;

  const _DevotionalsTab({required this.sermon, this.userId});

  @override
  State<_DevotionalsTab> createState() => _DevotionalsTabState();
}

class _DevotionalsTabState extends State<_DevotionalsTab> {
  final ProgressService _progressService = ProgressService();

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금'];

    if (widget.userId == null) {
      return _buildList(days, null);
    }

    return StreamBuilder<UserProgressModel?>(
      stream: _progressService.getProgressStream(
          widget.userId!, widget.sermon.id),
      builder: (context, snapshot) {
        return _buildList(days, snapshot.data);
      },
    );
  }

  Widget _buildList(List<String> days, UserProgressModel? progress) {
    // 완료 수 헤더
    final completedCount = progress?.completedCount ?? 0;

    return Column(
      children: [
        // 진행 현황 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              const Icon(Icons.track_changes,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '이번 주 묵상 진행: $completedCount / 5일',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (completedCount == 5)
                const Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      '완주!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // 진행 바
        LinearProgressIndicator(
          value: completedCount / 5,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),

        // 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) {
              final dayKey = 'day${index + 1}';
              final devotional = widget.sermon.devotionals[dayKey] ?? '';
              final isCompleted = progress?.completedDays[dayKey] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCompleted
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.primary.withValues(alpha: 0.2),
                    width: isCompleted ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 요일 뱃지
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.primary.withValues(alpha: 0.6)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${days[index]}요일',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // 완료 체크박스
                          if (widget.userId != null)
                            GestureDetector(
                              onTap: () => _toggleDay(dayKey, !isCompleted),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isCompleted
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 20,
                                  color: isCompleted
                                      ? Colors.white
                                      : AppColors.textHint,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        devotional.isEmpty ? '묵상 내용이 없습니다' : devotional,
                        style: TextStyle(
                          fontSize: 15,
                          color: devotional.isEmpty
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              '묵상 완료',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleDay(String dayKey, bool newValue) async {
    if (widget.userId == null) return;
    try {
      await _progressService.toggleDay(
        userId: widget.userId!,
        sermonId: widget.sermon.id,
        churchCode: widget.sermon.churchCode,
        dayKey: dayKey,
        completed: newValue,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했습니다')),
        );
      }
    }
  }
}
