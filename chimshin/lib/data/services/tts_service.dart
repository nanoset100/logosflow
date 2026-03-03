import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum VoiceType {
  male,   // 👨 alloy (남성)
  female, // 👩 nova  (여성)
}

class TtsService {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isPaused = false;
  VoiceType _currentVoice = VoiceType.male;

  // .env에서 API 키 로드
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  VoiceType get currentVoice => _currentVoice;

  // AudioPlayer lazy 초기화 — 실제 사용 시점에 생성
  AudioPlayer _getPlayer() {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _isPaused = false;
      });
    }
    return _audioPlayer!;
  }

  void setVoice(VoiceType voice) {
    _currentVoice = voice;
  }

  String _getVoiceName(VoiceType voice) {
    switch (voice) {
      case VoiceType.male:
        return 'alloy'; // 👨 남성
      case VoiceType.female:
        return 'nova';  // 👩 여성
    }
  }

  Future<void> speak(String text, {double speed = 1.0}) async {
    if (_isPlaying) await stop();

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/audio/speech'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'tts-1',
        'input': text,
        'voice': _getVoiceName(_currentVoice),
        'speed': speed,
      }),
    );

    if (response.statusCode == 200) {
      final player = _getPlayer();
      await player.play(BytesSource(response.bodyBytes));
      _isPlaying = true;
      _isPaused = false;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'TTS 오류 ${response.statusCode}: ${error['error']?['message'] ?? '알 수 없는 오류'}');
    }
  }

  Future<void> pause() async {
    await _audioPlayer?.pause();
    _isPlaying = false;
    _isPaused = true;
  }

  Future<void> resume() async {
    await _audioPlayer?.resume();
    _isPlaying = true;
    _isPaused = false;
  }

  Future<void> stop() async {
    await _audioPlayer?.stop();
    _isPlaying = false;
    _isPaused = false;
  }

  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}
