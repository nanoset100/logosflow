import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SermonAiResult {
  final String summary;
  final Map<String, String> devotionals; // day1~day5

  SermonAiResult({required this.summary, required this.devotionals});
}

class AiSermonService {
  static const _model = 'gpt-4o-mini';
  static const _url = 'https://api.openai.com/v1/chat/completions';
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static const _systemPrompt =
      '당신은 한국 침례교회의 설교 전문 분석가입니다. '
      '설교 텍스트를 분석하여 성도들의 신앙 성장을 돕는 요약과 5일 묵상을 작성합니다. '
      '신학적으로 정확하고 평신도가 이해하기 쉬운 언어를 사용하세요. '
      '반드시 아래 JSON 형식만 반환하고 추가 설명은 쓰지 마세요.';

  Future<SermonAiResult> analyze(String sermonText) async {
    if (sermonText.trim().isEmpty) {
      throw Exception('분석할 텍스트가 없습니다');
    }

    // 토큰 절약: 10,000자 초과 시 앞부분만 사용
    final text = sermonText.length > 10000
        ? sermonText.substring(0, 10000)
        : sermonText;

    final userPrompt = '''다음 설교 텍스트를 분석하여 JSON으로만 응답해주세요:

$text

응답 형식 (JSON만, 한국어로):
{
  "summary": "설교의 핵심 내용을 3~5문단으로 요약. 신학적 깊이와 평신도 이해를 함께 고려.",
  "day1": "월요일 - 오늘 말씀에서 깨달은 핵심 진리를 2~3문장으로",
  "day2": "화요일 - 이 말씀을 내 삶에 적용하는 구체적인 방법을 2~3문장으로",
  "day3": "수요일 - 이 말씀에 근거한 기도 제목과 기도문을 2~3문장으로",
  "day4": "목요일 - 이번 주 실천할 구체적인 한 가지 행동을 2~3문장으로",
  "day5": "금요일 - 구역/셀 모임에서 함께 나눌 핵심 질문과 적용을 2~3문장으로"
}''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          'AI 오류 ${response.statusCode}: ${err['error']?['message'] ?? '알 수 없는 오류'}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final content = data['choices'][0]['message']['content'] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;

    return SermonAiResult(
      summary: parsed['summary'] as String? ?? '',
      devotionals: {
        'day1': parsed['day1'] as String? ?? '',
        'day2': parsed['day2'] as String? ?? '',
        'day3': parsed['day3'] as String? ?? '',
        'day4': parsed['day4'] as String? ?? '',
        'day5': parsed['day5'] as String? ?? '',
      },
    );
  }
}
