import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

class SermonAiResult {
  final String summary;
  final Map<String, String> devotionals; // day1~day6

  SermonAiResult({required this.summary, required this.devotionals});
}

class AiSermonService {
  static String get _baseUrl => AppConfig.serverUrl;

  Future<SermonAiResult> analyze(String sermonText) async {
    if (sermonText.trim().isEmpty) {
      throw Exception('분석할 텍스트가 없습니다');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/ai/analyze'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'text': sermonText}),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'AI 오류 ${response.statusCode}: ${err['detail'] ?? '알 수 없는 오류'}');
    }

    final parsed = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    return SermonAiResult(
      summary: parsed['summary'] as String? ?? '',
      devotionals: {
        'day1': parsed['day1'] as String? ?? '',
        'day2': parsed['day2'] as String? ?? '',
        'day3': parsed['day3'] as String? ?? '',
        'day4': parsed['day4'] as String? ?? '',
        'day5': parsed['day5'] as String? ?? '',
        'day6': parsed['day6'] as String? ?? '',
      },
    );
  }
}
