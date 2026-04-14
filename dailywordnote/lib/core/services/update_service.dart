import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Google Play In-App Update 서비스
/// Play Store에 새 버전이 있으면 앱 안에서 바로 다운로드 & 설치
class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    // Android에서만 동작 (iOS는 App Store 자동 업데이트)
    if (!Platform.isAndroid) return;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      debugPrint('[UpdateService] availability: ${updateInfo.updateAvailability}');
      debugPrint('[UpdateService] immediate: ${updateInfo.immediateUpdateAllowed}');
      debugPrint('[UpdateService] flexible: ${updateInfo.flexibleUpdateAllowed}');

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        debugPrint('[UpdateService] 최신 버전입니다');
        return;
      }

      // 유연 업데이트 (Flexible): 백그라운드 다운로드 → 재시작 안내
      // 사용자가 앱을 계속 사용하면서 업데이트 가능
      if (updateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        if (!context.mounted) return;
        _showCompleteSnackBar(context);
        return;
      }

      // 즉시 업데이트 (Immediate): 전체 화면, 완료까지 대기
      // 긴급 보안 업데이트 등에 사용
      if (updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
    } catch (e) {
      // Play Store 미설치 기기, 에뮬레이터 등에서는 조용히 무시
      debugPrint('[UpdateService] In-App Update 불가: $e');
    }
  }

  /// Flexible 업데이트 다운로드 완료 후 재시작 안내
  static void _showCompleteSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('새 버전이 다운로드되었습니다!'),
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '지금 설치',
          textColor: Colors.white,
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }

  /// 현재 앱 버전 정보 (설정 화면 등에서 표시용)
  static Future<String> getVersionString() async {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version} (${info.buildNumber})';
  }
}
