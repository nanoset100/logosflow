import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon_model.dart';

class SavedSermonService {
  static const _kKey = 'saved_sermons';

  // 저장/해제 시 HomeScreen 등이 반응할 수 있도록 알림
  static final changeNotifier = ValueNotifier<int>(0);

  Future<List<SermonModel>> getSavedSermons() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? [];
    return raw
        .map((s) => SermonModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isSaved(String sermonId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? [];
    return raw.any((s) {
      final data = jsonDecode(s) as Map<String, dynamic>;
      return data['id'] == sermonId;
    });
  }

  Future<void> saveSermon(SermonModel sermon) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? [];

    // 중복 체크
    final alreadyExists = raw.any((s) {
      final data = jsonDecode(s) as Map<String, dynamic>;
      return data['id'] == sermon.id;
    });

    if (!alreadyExists) {
      raw.insert(0, jsonEncode(sermon.toJson())); // 최신 저장순
      await prefs.setStringList(_kKey, raw);
      changeNotifier.value++;
    }
  }

  Future<void> unsaveSermon(String sermonId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? [];
    raw.removeWhere((s) {
      final data = jsonDecode(s) as Map<String, dynamic>;
      return data['id'] == sermonId;
    });
    await prefs.setStringList(_kKey, raw);
    changeNotifier.value++;
  }
}
