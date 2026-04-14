import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon_model.dart';
import 'sermon_service.dart';

/// 저장한 설교 서비스
/// - 교회 코드별로 분리 저장 (saved_sermon_ids_{churchCode})
/// - 설교 전체 데이터는 캐시로 별도 보관 (sermon_cache_{sermonId})
/// - 화면 열 때 Firebase 재조회 → 삭제된 설교 자동 제거, 오프라인 시 캐시 사용
class SavedSermonService {
  static final changeNotifier = ValueNotifier<int>(0);

  final _sermonService = SermonService();

  static String _idsKey(String churchCode) => 'saved_sermon_ids_$churchCode';
  static String _cacheKey(String sermonId) => 'sermon_cache_$sermonId';

  // ─── 내부 헬퍼 ──────────────────────────────────────────

  Future<List<String>> _getIds(String churchCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_idsKey(churchCode)) ?? [];
  }

  Future<void> _saveIds(String churchCode, List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_idsKey(churchCode), ids);
  }

  Future<void> _updateCache(SermonModel sermon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(sermon.id), jsonEncode(sermon.toJson()));
  }

  Future<SermonModel?> _fromCache(String sermonId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(sermonId));
    if (raw == null) return null;
    try {
      return SermonModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ─── 구버전 데이터 마이그레이션 ─────────────────────────
  // 기존 'saved_sermons' 키(교회 미분리)를 새 형식으로 자동 변환

  Future<void> _migrateIfNeeded() async {
    const oldKey = 'saved_sermons';
    final prefs = await SharedPreferences.getInstance();
    final oldList = prefs.getStringList(oldKey);
    if (oldList == null || oldList.isEmpty) return;

    for (final raw in oldList) {
      try {
        final sermon =
            SermonModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        final churchCode = sermon.churchCode;
        if (churchCode.isEmpty) continue;

        final ids = await _getIds(churchCode);
        if (!ids.contains(sermon.id)) {
          ids.insert(0, sermon.id);
          await _saveIds(churchCode, ids);
        }
        await _updateCache(sermon);
      } catch (_) {}
    }

    await prefs.remove(oldKey);
  }

  // ─── 공개 API ────────────────────────────────────────────

  /// 저장한 설교 목록 반환
  /// - Firebase 재조회 → 삭제된 설교 자동 제거
  /// - 오프라인 시 캐시 데이터 반환
  Future<List<SermonModel>> getSavedSermons(String churchCode) async {
    if (churchCode.isEmpty) return [];

    // 구버전 데이터 마이그레이션 (최초 1회)
    await _migrateIfNeeded();

    final ids = await _getIds(churchCode);
    if (ids.isEmpty) return [];

    final result = <SermonModel>[];
    final deletedIds = <String>[];

    for (final id in ids) {
      try {
        final sermon = await _sermonService.getSermon(churchCode, id);
        if (sermon != null) {
          await _updateCache(sermon);
          result.add(sermon);
        } else {
          // Firebase에 없음 → 삭제된 설교, ID 목록에서 제거
          deletedIds.add(id);
        }
      } catch (_) {
        // 네트워크 오류 → 캐시 폴백
        final cached = await _fromCache(id);
        if (cached != null) result.add(cached);
      }
    }

    // 삭제된 ID 정리
    if (deletedIds.isNotEmpty) {
      final updated = ids.where((id) => !deletedIds.contains(id)).toList();
      await _saveIds(churchCode, updated);
    }

    return result;
  }

  Future<bool> isSaved(String sermonId, String churchCode) async {
    if (churchCode.isEmpty) return false;
    final ids = await _getIds(churchCode);
    return ids.contains(sermonId);
  }

  Future<void> saveSermon(SermonModel sermon) async {
    final churchCode = sermon.churchCode;
    if (churchCode.isEmpty) return;

    final ids = await _getIds(churchCode);
    if (!ids.contains(sermon.id)) {
      ids.insert(0, sermon.id);
      await _saveIds(churchCode, ids);
      await _updateCache(sermon);
      changeNotifier.value++;
    }
  }

  Future<void> unsaveSermon(String sermonId, String churchCode) async {
    if (churchCode.isEmpty) return;
    final ids = await _getIds(churchCode);
    ids.remove(sermonId);
    await _saveIds(churchCode, ids);
    changeNotifier.value++;
  }
}
