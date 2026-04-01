import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/services/sermon_service.dart';
import '../../../data/services/ai_sermon_service.dart';
import '../../../data/services/youtube_service.dart';
import '../../../data/services/whisper_service.dart';

enum _InputMethod { direct, text, youtube, audio }

class SermonRegisterScreen extends StatefulWidget {
  const SermonRegisterScreen({super.key});

  @override
  State<SermonRegisterScreen> createState() => _SermonRegisterScreenState();
}

class _SermonRegisterScreenState extends State<SermonRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sermonService = SermonService();

  _InputMethod _method = _InputMethod.direct;

  // 공통 필드
  final _titleCtrl = TextEditingController();
  final _pastorCtrl = TextEditingController();
  final _bibleVerseCtrl = TextEditingController();
  DateTime _sermonDate = DateTime.now();

  // 요약 & 묵상 직접 입력
  final _summaryCtrl = TextEditingController();
  final _day1Ctrl = TextEditingController();
  final _day2Ctrl = TextEditingController();
  final _day3Ctrl = TextEditingController();
  final _day4Ctrl = TextEditingController();
  final _day5Ctrl = TextEditingController();

  // 텍스트 붙여넣기 / YouTube
  final _pasteCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();

  bool _isSaving = false;
  bool _isAiLoading = false;
  final _aiService = AiSermonService();
  final _youtubeService = YoutubeService();
  final _whisperService = WhisperService();
  File? _pickedAudioFile;
  String? _churchCode;

  @override
  void initState() {
    super.initState();
    _loadChurchCode();
  }

  Future<void> _loadChurchCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _churchCode = prefs.getString('church_code'));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pastorCtrl.dispose();
    _bibleVerseCtrl.dispose();
    _summaryCtrl.dispose();
    _day1Ctrl.dispose();
    _day2Ctrl.dispose();
    _day3Ctrl.dispose();
    _day4Ctrl.dispose();
    _day5Ctrl.dispose();
    _pasteCtrl.dispose();
    _youtubeCtrl.dispose();
    _youtubeService.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sermonDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _sermonDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_churchCode == null) {
      _showSnack('교회 코드를 찾을 수 없습니다');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final sermon = SermonModel(
        id: '',
        churchCode: _churchCode!,
        title: _titleCtrl.text.trim(),
        date: _sermonDate,
        pastor: _pastorCtrl.text.trim(),
        bibleVerse: _bibleVerseCtrl.text.trim(),
        summary: _summaryCtrl.text.trim(),
        audioUrl: null,
        devotionals: {
          'day1': _day1Ctrl.text.trim(),
          'day2': _day2Ctrl.text.trim(),
          'day3': _day3Ctrl.text.trim(),
          'day4': _day4Ctrl.text.trim(),
          'day5': _day5Ctrl.text.trim(),
        },
        keyPoints: [],
        createdAt: DateTime.now(),
      );

      final id = await _sermonService.addSermon(sermon);
      if (!mounted) return;

      if (id != null) {
        _showSnack('설교가 등록되었습니다');
        Navigator.of(context).pop();
      } else {
        _showSnack('저장 실패. 다시 시도해주세요');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── AI 분석 공통 로직 (요약 + 5일 묵상 자동 채우기) ──
  Future<void> _runAi(String text) async {
    if (text.trim().isEmpty) {
      _showSnack('분석할 텍스트를 먼저 입력해주세요');
      return;
    }
    setState(() => _isAiLoading = true);
    try {
      final result = await _aiService.analyze(text);
      setState(() {
        _summaryCtrl.text = result.summary;
        _day1Ctrl.text = result.devotionals['day1'] ?? '';
        _day2Ctrl.text = result.devotionals['day2'] ?? '';
        _day3Ctrl.text = result.devotionals['day3'] ?? '';
        _day4Ctrl.text = result.devotionals['day4'] ?? '';
        _day5Ctrl.text = result.devotionals['day5'] ?? '';
      });
      _showSnack('AI 분석 완료! 내용을 검토한 후 저장하세요');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  // ── 오디오 파일 선택 ──
  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _pickedAudioFile = File(result.files.single.path!));
    }
  }

  // ── 오디오 파일 → Whisper STT → AI 분석 ──
  Future<void> _runAiFromAudio() async {
    if (_pickedAudioFile == null) {
      _showSnack('오디오 파일을 먼저 선택해주세요');
      return;
    }
    setState(() => _isAiLoading = true);
    try {
      _showSnack('음성 인식 중... (파일 크기에 따라 수 분이 걸릴 수 있습니다)');
      final transcript = await _whisperService.transcribeFile(_pickedAudioFile!);
      if (!mounted) return;
      _showSnack('음성 인식 완료. AI 분석 중...');
      await _runAi(transcript);
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  // ── YouTube URL → 서버 /transcribe/youtube (yt-dlp + 쿠키 인증) → AI 분석 ──
  Future<void> _runAiFromYoutube() async {
    final url = _youtubeCtrl.text.trim();
    if (url.isEmpty) {
      _showSnack('YouTube URL을 먼저 입력해주세요');
      return;
    }
    setState(() => _isAiLoading = true);
    try {
      _showSnack('YouTube 오디오 추출 및 음성 인식 중... (수 분이 걸릴 수 있습니다)');
      final transcript = await _whisperService.transcribeYoutube(url);
      if (!mounted) return;
      _showSnack('음성 인식 완료. AI 분석 중...');
      await _runAi(transcript);
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('설교 등록')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 입력 방법 선택 ──
              _sectionTitle('입력 방법'),
              const SizedBox(height: 8),
              _methodSelector(),
              const SizedBox(height: 24),

              // ── 기본 정보 ──
              _sectionTitle('기본 정보'),
              const SizedBox(height: 12),
              _textField(_titleCtrl, '설교 제목', required: true),
              const SizedBox(height: 12),
              _textField(_pastorCtrl, '설교자 이름', required: true),
              const SizedBox(height: 12),
              _textField(_bibleVerseCtrl, '성경 본문 (예: 요한복음 3:16)', required: true),
              const SizedBox(height: 12),
              _datePicker(),
              const SizedBox(height: 24),

              // ── 텍스트 붙여넣기 전용 영역 ──
              if (_method == _InputMethod.text) ...[
                _sectionTitle('설교 텍스트'),
                const SizedBox(height: 8),
                _multilineField(_pasteCtrl, '설교 전문 텍스트를 여기에 붙여넣으세요...', lines: 8),
                const SizedBox(height: 8),
                _aiButton(
                  label: 'AI 자동 요약 생성',
                  onPressed: _isAiLoading ? null : () => _runAi(_pasteCtrl.text),
                ),
                const SizedBox(height: 24),
              ],

              // ── 오디오 파일 전용 영역 ──
              if (_method == _InputMethod.audio) ...[
                _sectionTitle('오디오 파일'),
                const SizedBox(height: 8),
                _audioFilePicker(),
                const SizedBox(height: 8),
                _aiButton(
                  label: 'AI 자동 생성 (음성 인식)',
                  onPressed: _isAiLoading ? null : _runAiFromAudio,
                ),
                const SizedBox(height: 24),
              ],

              // ── YouTube URL 전용 영역 ──
              if (_method == _InputMethod.youtube) ...[
                _sectionTitle('YouTube URL'),
                const SizedBox(height: 8),
                _textField(_youtubeCtrl, 'https://www.youtube.com/watch?v=...'),
                const SizedBox(height: 8),
                _aiButton(
                  label: 'AI 자동 생성',
                  onPressed: _isAiLoading ? null : _runAiFromYoutube,
                ),
                const SizedBox(height: 24),
              ],

              // ── 설교 요약 ──
              _sectionTitle('설교 요약'),
              const SizedBox(height: 8),
              _multilineField(_summaryCtrl, '설교 핵심 내용을 3~5문단으로 요약해 주세요', lines: 6),
              const SizedBox(height: 24),

              // ── 5일 묵상 ──
              _sectionTitle('5일 묵상'),
              const SizedBox(height: 4),
              const Text(
                '구역 예배 교재로 바로 사용할 수 있습니다',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _devotionalField(_day1Ctrl, '월요일', '오늘 말씀에서 깨달은 것은 무엇인가요?'),
              const SizedBox(height: 10),
              _devotionalField(_day2Ctrl, '화요일', '이 말씀을 내 삶에 어떻게 적용할 수 있을까요?'),
              const SizedBox(height: 10),
              _devotionalField(_day3Ctrl, '수요일', '오늘 이 말씀으로 어떻게 기도하시겠습니까?'),
              const SizedBox(height: 10),
              _devotionalField(_day4Ctrl, '목요일', '이번 주 실천할 한 가지는 무엇인가요?'),
              const SizedBox(height: 10),
              _devotionalField(_day5Ctrl, '금요일', '가족/구역원에게 나눌 말씀의 핵심은?'),
              const SizedBox(height: 32),

              // ── 저장 버튼 ──
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('설교 등록 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── 입력 방법 선택 위젯 ──
  Widget _methodSelector() {
    const labels = ['직접 입력', '텍스트 붙여넣기', 'YouTube URL', '오디오 파일'];
    const icons = [Icons.edit_note, Icons.content_paste, Icons.play_circle_outline, Icons.mic];
    return Row(
      children: _InputMethod.values.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value;
        final selected = _method == m;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < 3 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _method = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icons[idx], size: 20, color: selected ? Colors.white : AppColors.textSecondary),
                    const SizedBox(height: 4),
                    Text(
                      labels[idx],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      decoration: _inputDecoration(hint),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '필수 입력 항목입니다' : null : null,
    );
  }

  Widget _multilineField(TextEditingController ctrl, String hint, {int lines = 4}) {
    return TextFormField(
      controller: ctrl,
      maxLines: lines,
      decoration: _inputDecoration(hint),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              '설교 날짜: ${_sermonDate.year}년 ${_sermonDate.month}월 ${_sermonDate.day}일',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const Spacer(),
            const Text('변경', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _audioFilePicker() {
    final name = _pickedAudioFile?.path.split('/').last.split('\\').last;
    return GestureDetector(
      onTap: _isAiLoading ? null : _pickAudioFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: name != null ? AppColors.primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              name != null ? Icons.audio_file : Icons.upload_file,
              size: 20,
              color: name != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                name ?? 'mp3, m4a, wav, mp4 파일을 선택하세요',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: name != null ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name != null ? '변경' : '선택',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiButton({required String label, VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: _isAiLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome, size: 16),
      label: Text(
        _isAiLoading ? 'AI 분석 중...' : label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB0BEC5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _devotionalField(TextEditingController ctrl, String day, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(day,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: 3,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
