import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WhisperService {
  static String _extractDetail(String body, int statusCode) {
    try {
      final err = jsonDecode(body) as Map<String, dynamic>;
      return err['detail'] as String? ?? 'STT 서버 오류 $statusCode';
    } catch (_) {
      return 'STT 서버 오류 $statusCode';
    }
  }

  static String get _baseUrl =>
      dotenv.env['WHISPER_SERVER_URL'] ?? 'http://localhost:8000';

  /// 오디오 파일 → Whisper STT → 텍스트 반환
  Future<String> transcribeFile(File audioFile, {String language = 'ko'}) async {
    final uri = Uri.parse('$_baseUrl/transcribe');
    final request = http.MultipartRequest('POST', uri)
      ..fields['language'] = language
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final streamed = await request.send().timeout(const Duration(minutes: 10));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception(_extractDetail(body, streamed.statusCode));
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }

  /// YouTube URL → Whisper STT → 텍스트 반환
  Future<String> transcribeYoutube(String url, {String language = 'ko'}) async {
    final uri = Uri.parse('$_baseUrl/transcribe/youtube');
    final response = await http.post(
      uri,
      body: {'url': url, 'language': language},
    ).timeout(const Duration(minutes: 15));

    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      throw Exception(_extractDetail(body, response.statusCode));
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }
}
