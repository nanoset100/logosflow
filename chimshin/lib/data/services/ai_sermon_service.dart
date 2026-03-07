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
  "summary": "[전체 요약] 설교의 배경·핵심 주제·주요 논증·결론을 논리적 흐름으로 3~4개의 긴 문단(총 10~15줄)으로 풍성하게 풀어쓸 것. 신학적 깊이와 평신도 이해를 함께 고려. 그 다음 줄을 띄운 후 [핵심 교훈] 제목 아래 설교의 가장 중요한 포인트 3~4가지를 '- 제목\\n내용' 형태의 글머리 기호로 각각 2~3문장씩 상세하게 작성할 것.",
  "day1": "월요일 - 오늘 말씀에서 깨달은 핵심 진리를 3~4문장으로 풍성하게",
  "day2": "화요일 - 이 말씀을 내 삶에 적용하는 구체적인 방법을 3~4문장으로",
  "day3": "수요일 - 이 말씀에 근거한 기도 제목과 기도문을 3~4문장으로",
  "day4": "목요일 - 이번 주 실천할 구체적인 한 가지 행동을 3~4문장으로",
  "day5": "금요일 - 구역/셀 모임에서 함께 나눌 핵심 질문과 적용을 3~4문장으로"
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
        'max_tokens': 4000,
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
