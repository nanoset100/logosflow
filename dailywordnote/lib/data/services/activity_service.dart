import 'package:shared_preferences/shared_preferences.dart';

/// 이번 주 활동 통계 서비스 (SharedPreferences 로컬 저장)
class ActivityService {
  static const String _prefix = 'act_';
  static const String _streakKey = 'streak_count';
  static const String _streakDateKey = 'streak_last_date';

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 오늘 특정 활동을 완료했음을 기록
  /// type: 'sermon' | 'devotion' | 'bible'
  Future<void> recordActivity(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_prefix}${type}_${_dateKey(DateTime.now())}';
    await prefs.setBool(key, true);
  }

  /// 이번 주(월~일) 해당 활동이 기록된 일수 반환
  Future<int> getWeeklyCount(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final weekday = now.weekday; // 1=월, 7=일
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));

    int count = 0;
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (day.isAfter(DateTime(now.year, now.month, now.day))) break;
      final key = '${_prefix}${type}_${_dateKey(day)}';
      if (prefs.getBool(key) == true) count++;
    }
    return count;
  }

  /// 연속 접속 일수 갱신 후 반환 (하루 단위)
  Future<int> updateAndGetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _dateKey(now);
    final lastStr = prefs.getString(_streakDateKey);
    int streak = prefs.getInt(_streakKey) ?? 0;

    if (lastStr == null) {
      streak = 1;
    } else if (lastStr == todayStr) {
      // 오늘 이미 기록됨 - 변경 없음
    } else {
      final lastDate = DateTime.parse(lastStr);
      final today = DateTime(now.year, now.month, now.day);
      final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        streak += 1;
      } else {
        streak = 1;
      }
    }

    await prefs.setString(_streakDateKey, todayStr);
    await prefs.setInt(_streakKey, streak);
    return streak;
  }
}
