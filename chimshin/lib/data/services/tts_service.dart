import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum VoiceType {
  male,   // 👨 alloy (남성)
  female, // 👩 nova  (여성)
}

class TtsService {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isPaused = false;
  VoiceType _currentVoice = VoiceType.male;

  static String get _baseUrl =>
      dotenv.env['WHISPER_SERVER_URL'] ?? 'http://localhost:8000';

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

  Future<void> speak(String text) async {
    if (_isPlaying) await stop();

    final response = await http.post(
      Uri.parse('$_baseUrl/ai/tts'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
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
