import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../../core/config/app_config.dart';

enum VoiceType {
  male,   // 👨 alloy (남성)
  female, // 👩 nova  (여성)
}

class TtsService {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isPaused = false;
  VoiceType _currentVoice = VoiceType.male;

  static String get _baseUrl => AppConfig.serverUrl;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  VoiceType get currentVoice => _currentVoice;

  // 재생 위치/길이 스트림
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;

  TtsService() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _isPaused = false;
    });
  }

  void setVoice(VoiceType voice) {
    _currentVoice = voice;
  }

  String _getVoiceName(VoiceType voice) {
    switch (voice) {
      case VoiceType.male:
        return 'alloy';
      case VoiceType.female:
        return 'nova';
    }
  }

  /// 캐시된 URL에서 바로 재생 (API 비용 없음)
  Future<void> speakFromUrl(String url) async {
    if (_isPlaying) await stop();
    await _audioPlayer.play(UrlSource(url));
    _isPlaying = true;
    _isPaused = false;
  }

  Future<void> speak(String text) async {
    if (_isPlaying) await stop();

    final response = await http.post(
      Uri.parse('$_baseUrl/ai/tts'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'X-App-Key': AppConfig.appSecretKey,
      },
      body: jsonEncode({
        'text': text,
        'voice': _getVoiceName(_currentVoice),
      }),
    );

    if (response.statusCode == 200) {
      await _audioPlayer.play(BytesSource(response.bodyBytes));
      _isPlaying = true;
      _isPaused = false;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'TTS 오류 ${response.statusCode}: ${error['detail'] ?? '알 수 없는 오류'}');
    }
  }

  /// 설교 등록 시 TTS를 Firebase Storage에 캐싱 - URL 반환
  static Future<String?> cacheForSermon({
    required String churchCode,
    required String sermonId,
    required String text,
    String voice = 'alloy',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.serverUrl}/ai/tts/cache'),
        headers: {'X-App-Key': AppConfig.appSecretKey},
        body: {
          'text': text,
          'voice': voice,
          'church_code': churchCode,
          'sermon_id': sermonId,
        },
      ).timeout(const Duration(minutes: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    _isPaused = true;
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
    _isPaused = false;
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _isPaused = false;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
