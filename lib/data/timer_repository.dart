import 'package:shared_preferences/shared_preferences.dart';

class TimerRepository {
  static const String _keySessionStart = 'session_start';
  static const String _keyBreakStart = 'break_start';
  static const String _keyTotalTime = 'total_time';
  static const String _keyTotalBreakTime = 'total_break_time';
  static const String _keyBreakCount = 'break_count';
  static const String _keyAppCloseTime = 'app_close_time';
  static const String _keyWeeklyStats = 'weekly_stats';

  // ... existing methods ...

  Future<void> saveWeeklyStats(List<Map<String, dynamic>> stats) async {
    final prefs = await SharedPreferences.getInstance();
    // Simple JSON encoding for now, or just string manipulation since it's simple data
    // We'll store it as a list of strings "day|seconds|progress"
    final List<String> encoded = stats.map((e) {
      return '${e['day']}|${e['seconds']}|${e['progress']}';
    }).toList();
    await prefs.setStringList(_keyWeeklyStats, encoded);
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encoded = prefs.getStringList(_keyWeeklyStats);
    if (encoded == null) return [];

    return encoded.map((e) {
      final parts = e.split('|');
      return {
        'day': parts[0],
        'seconds': int.parse(parts[1]),
        'progress': double.parse(parts[2]),
      };
    }).toList();
  }

  Future<void> saveSessionStart(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionStart, time.toIso8601String());
  }

  Future<DateTime?> getSessionStart() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keySessionStart);
    return str != null ? DateTime.parse(str) : null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionStart);
    await prefs.remove(_keyTotalTime);
    await prefs.remove(_keyTotalBreakTime);
    await prefs.remove(_keyBreakCount);
    await prefs.remove(_keyBreakStart);
  }

  Future<void> saveBreakStart(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBreakStart, time.toIso8601String());
  }

  Future<DateTime?> getBreakStart() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyBreakStart);
    return str != null ? DateTime.parse(str) : null;
  }

  Future<void> clearBreakStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBreakStart);
  }

  Future<void> saveTotalTime(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTotalTime, duration.inSeconds);
  }

  Future<Duration> getTotalTime() async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(_keyTotalTime) ?? 0;
    return Duration(seconds: seconds);
  }

  Future<void> saveTotalBreakTime(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTotalBreakTime, duration.inSeconds);
  }

  Future<Duration> getTotalBreakTime() async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(_keyTotalBreakTime) ?? 0;
    return Duration(seconds: seconds);
  }

  Future<void> saveBreakCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBreakCount, count);
  }

  Future<int> getBreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBreakCount) ?? 0;
  }

  Future<void> saveAppCloseTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppCloseTime, time.toIso8601String());
  }

  Future<DateTime?> getAppCloseTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyAppCloseTime);
    return str != null ? DateTime.parse(str) : null;
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionStart);
    await prefs.remove(_keyBreakStart);
    await prefs.remove(_keyTotalTime);
    await prefs.remove(_keyTotalBreakTime);
    await prefs.remove(_keyBreakCount);
    await prefs.remove(_keyAppCloseTime);
    await prefs.remove(_keyWeeklyStats);
  }
}
