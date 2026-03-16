import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  final _yt = YoutubeExplode();

  /// YouTube URL에서 자막 텍스트를 추출합니다.
  /// 자막이 없거나 오류 발생 시 Exception을 throw합니다.
  Future<String> getTranscript(String url) async {
    try {
      final videoId = VideoId(url);

      // 자막 트랙 목록 가져오기
      final manifest =
          await _yt.videos.closedCaptions.getManifest(videoId);

      if (manifest.tracks.isEmpty) {
        throw Exception(
            '이 영상에는 자막이 없습니다.\n"텍스트 붙여넣기" 방식으로 설교 내용을 직접 입력해주세요.');
      }

      // 한국어 우선, 없으면 첫 번째 트랙 사용
      final trackInfo = manifest.tracks.firstWhere(
        (t) => t.language.code == 'ko',
        orElse: () => manifest.tracks.first,
      );

      final track = await _yt.videos.closedCaptions.get(trackInfo);

      // 타임스탬프 제거 후 텍스트만 합치기
      final text = track.captions
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .join(' ');

      if (text.trim().isEmpty) {
        throw Exception(
            '자막 내용이 비어있습니다.\n"텍스트 붙여넣기" 방식으로 설교 내용을 직접 입력해주세요.');
      }

      return text;
    } on YoutubeExplodeException catch (e) {
      throw Exception(
          'YouTube 오류: ${e.message}\n"텍스트 붙여넣기" 방식으로 입력해주세요.');
    } catch (e) {
      // 우리가 직접 던진 사용자 친화적 메시지는 그대로 전달
      if (e is Exception) {
        final msg = e.toString();
        if (msg.contains('자막') || msg.contains('YouTube 오류')) rethrow;
      }
      // XmlParserException 등 라이브러리 내부 오류 → 친화적 메시지로 변환
      throw Exception(
          'YouTube 자막을 불러올 수 없습니다.\n'
          '이 영상은 자막을 지원하지 않거나 YouTube 정책상 제한되어 있습니다.\n'
          '"오디오 업로드" 탭에서 파일로 업로드하거나\n'
          '"텍스트 붙여넣기" 방식으로 직접 입력해주세요.');
    }
  }

  void dispose() {
    _yt.close();
  }
}
