import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _keyCurrency = 'currency';
  static const String _keyMonthlyRate = 'monthly_rate';
  static const String _keyShowEarnings = 'show_earnings';
  static const String _keyShowFakeData = 'show_fake_data';
  static const String _keyBreakReminders = 'break_reminders';
  static const String _keyBackupEnabled = 'backup_enabled';
  static const String _keyWorkInterval = 'work_interval';
  static const String _keyWorkHours = 'work_hours';
  static const String _keyBreakDuration = 'break_duration';
  static const String _keyBreakReminderTimeHour = 'break_reminder_time_hour';
  static const String _keyBreakReminderTimeMinute =
      'break_reminder_time_minute';

  Future<void> saveCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, value);
  }

  Future<void> saveMonthlyRate(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMonthlyRate, value);
  }

  Future<void> saveShowEarnings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowEarnings, value);
  }

  Future<void> saveShowFakeData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowFakeData, value);
  }

  Future<void> saveBreakReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBreakReminders, value);
  }

  Future<void> saveBackupEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBackupEnabled, value);
  }

  Future<void> saveWorkInterval(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWorkInterval, value);
  }

  Future<void> saveWorkHours(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWorkHours, value);
  }

  Future<void> saveBreakDuration(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBreakDuration, value);
  }

  Future<void> saveBreakReminderTime(TimeOfDay? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time == null) {
      await prefs.remove(_keyBreakReminderTimeHour);
      await prefs.remove(_keyBreakReminderTimeMinute);
    } else {
      await prefs.setInt(_keyBreakReminderTimeHour, time.hour);
      await prefs.setInt(_keyBreakReminderTimeMinute, time.minute);
    }
  }

  Future<void> saveBreakReminderTimes(List<TimeOfDay> times) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = times
        .map((t) => '${t.hour}:${t.minute}')
        .toList();
    await prefs.setStringList('break_reminder_times', encoded);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    List<TimeOfDay> breakReminderTimes = [];
    final List<String>? encodedTimes = prefs.getStringList(
      'break_reminder_times',
    );
    if (encodedTimes != null) {
      breakReminderTimes = encodedTimes.map((e) {
        final parts = e.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
    }

    return {
      'currency': prefs.getString(_keyCurrency),
      'monthlyRate': prefs.getString(_keyMonthlyRate),
      'showEarnings': prefs.getBool(_keyShowEarnings),
      'showFakeData': prefs.getBool(_keyShowFakeData),
      'breakReminders': prefs.getBool(_keyBreakReminders),
      'backupEnabled': prefs.getBool(_keyBackupEnabled),
      'workInterval': prefs.getInt(_keyWorkInterval),
      'workHours': prefs.getInt(_keyWorkHours),
      'breakDuration': prefs.getInt(_keyBreakDuration),
      'breakReminderTimeHour': prefs.getInt(_keyBreakReminderTimeHour),
      'breakReminderTimeMinute': prefs.getInt(_keyBreakReminderTimeMinute),
      'breakReminderTimes': breakReminderTimes,
    };
  }
}
