import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/models/user_progress_model.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/services/tts_service.dart';
import '../../../data/services/saved_sermon_service.dart';

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
  final _savedService = SavedSermonService();
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  bool _isLoading = false;
  bool _ttsAvailable = true;
  VoiceType _selectedVoice = VoiceType.male;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isSaved = false;
  bool _saveLoading = false;

  @override
  void initState() {
    super.initState();
    try {
      _ttsService = TtsService();
      _posSub = _ttsService!.onPositionChanged.listen(
        (d) { if (mounted) setState(() => _position = d); },
      );
      _durSub = _ttsService!.onDurationChanged.listen(
        (d) { if (mounted) setState(() => _duration = d); },
      );
    } catch (e) {
      _ttsAvailable = false;
    }
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final saved = await _savedService.isSaved(widget.sermon.id);
    if (mounted) setState(() => _isSaved = saved);
  }

  Future<void> _toggleSave() async {
    setState(() => _saveLoading = true);
    try {
      if (_isSaved) {
        await _savedService.unsaveSermon(widget.sermon.id);
        if (mounted) {
          setState(() => _isSaved = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('저장이 해제되었습니다'), duration: Duration(seconds: 2)),
          );
        }
      } else {
        await _savedService.saveSermon(widget.sermon);
        if (mounted) {
          setState(() => _isSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('설교가 저장되었습니다 ⭐'), duration: Duration(seconds: 2)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saveLoading = false);
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _ttsService?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _playAudio() async {
    if (_ttsService == null) return;
    setState(() => _isLoading = true);
    try {
      await _ttsService!.speak(widget.sermon.summary);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오디오 오류: $e'), backgroundColor: Colors.red),
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
    setState(() {
      _position = Duration.zero;
      _duration = Duration.zero;
    });
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
    final isPaused = _ttsService?.isPaused ?? false;
    final activeColor = _selectedVoice == VoiceType.male
        ? AppColors.primary
        : AppColors.secondary;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TTS 불가 안내 ───────────────────────────
          if (!_ttsAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
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

          // ── 오디오 컨트롤 카드 ──────────────────────
          if (_ttsAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 상단: 레이블 + 음성 칩 ────────────
                  Row(
                    children: [
                      const Text(
                        '🎙️ 설교 듣기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      // 남성 칩
                      GestureDetector(
                        onTap: () => _changeVoice(VoiceType.male),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedVoice == VoiceType.male
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedVoice == VoiceType.male
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            '👨 남성',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedVoice == VoiceType.male
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 여성 칩
                      GestureDetector(
                        onTap: () => _changeVoice(VoiceType.female),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedVoice == VoiceType.female
                                ? AppColors.secondary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedVoice == VoiceType.female
                                  ? AppColors.secondary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            '👩 여성',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedVoice == VoiceType.female
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── 진행 슬라이더 ─────────────────────
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: progress,
                      activeColor: activeColor,
                      inactiveColor: Colors.grey.shade300,
                      onChanged: null, // 자동 진행만 표시
                    ),
                  ),

                  // ── 시간 표시 ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Text(
                          _fmt(_position),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint),
                        ),
                        const Spacer(),
                        Text(
                          _fmt(_duration),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 원형 컨트롤 버튼 ──────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 재생 / 일시정지 버튼 (원형)
                      ElevatedButton(
                        onPressed:
                            _isLoading ? null : (isActive ? _pauseOrResume : _playAudio),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(64, 64),
                          shape: const CircleBorder(),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Icon(
                                isActive && !isPaused
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 32,
                              ),
                      ),
                      const SizedBox(width: 20),
                      // 정지 버튼 (원형, 빨간색)
                      ElevatedButton(
                        onPressed: isActive ? _stopAudio : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          minimumSize: const Size(64, 64),
                          shape: const CircleBorder(),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.stop, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── 요약 텍스트 ────────────────────────────
          const Text(
            '설교 요약',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.sermon.summary,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          // ── 저장 버튼 ─────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _isSaved
                ? ElevatedButton.icon(
                    onPressed: _saveLoading ? null : _toggleSave,
                    icon: _saveLoading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bookmark, size: 20),
                    label: const Text('저장됨  (탭하여 해제)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _saveLoading ? null : _toggleSave,
                    icon: _saveLoading
                        ? SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.bookmark_border, size: 20),
                    label: const Text('⭐ 저장하기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),

          const SizedBox(height: 12),
        ],
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
