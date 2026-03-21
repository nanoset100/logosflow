import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/services/tts_service.dart';
import '../../../data/services/saved_sermon_service.dart';
import '../../../data/services/activity_service.dart';


class SermonDetailScreen extends StatefulWidget {
  final SermonModel sermon;

  const SermonDetailScreen({
    super.key,
    required this.sermon,
  });

  @override
  State<SermonDetailScreen> createState() => _SermonDetailScreenState();
}

class _SermonDetailScreenState extends State<SermonDetailScreen> {
  final _shareButtonKey = GlobalKey();

  void _shareSermon(SermonModel sermon) {
    final preview = sermon.summary.length > 150
        ? '${sermon.summary.substring(0, 150)}...'
        : sermon.summary;

    final text = '''📖 ${sermon.title} - ${sermon.pastor} 목사님

$preview

👉 더 깊은 내용과 구역 예배 5일 묵상 교재는 [말씀노트] 앱에서 무료로 확인하세요!
https://apps.apple.com/app/id6744803990''';

    // iPad에서 share sheet 팝오버 위치 지정 (미지정 시 무반응)
    final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    Share.share(
      text,
      subject: '${sermon.title} - ${sermon.pastor} 목사님 설교',
      sharePositionOrigin: origin,
    );
  }

  @override
  void initState() {
    super.initState();
    ActivityService().recordActivity('sermon');
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
        actions: [
          IconButton(
            key: _shareButtonKey,
            icon: const Icon(Icons.share_outlined),
            tooltip: '공유하기',
            onPressed: () => _shareSermon(widget.sermon),
          ),
        ],
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

          // 본문 (요약 + 오디오 + 저장)
          Expanded(
            child: _SummaryTab(sermon: widget.sermon),
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

          // ── 요약 텍스트 (마크다운) ─────────────────
          const Text(
            '설교 요약',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: widget.sermon.summary,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                height: 1.7,
              ),
              strong: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              h3: const TextStyle(
                fontSize: 17,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                height: 2.0,
              ),
              listBullet: const TextStyle(
                fontSize: 16,
                color: AppColors.primary,
              ),
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
                        ? const SizedBox(
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

