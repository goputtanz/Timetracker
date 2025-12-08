import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_contract.dart';
import '../../data/backup_repository.dart';
import '../../data/settings_repository.dart';
import '../../data/local_database.dart';
import '../../data/timer_repository.dart';
import '../../services/notification_service.dart';

class SettingsViewModel extends Notifier<SettingsState> {
  final _repository = SettingsRepository();

  @override
  SettingsState build() {
    _init();
    return const SettingsState();
  }

  Future<void> _init() async {
    final user = await BackupRepository().getCurrentUser();
    final settings = await _repository.loadSettings();

    TimeOfDay? breakReminderTime;
    if (settings['breakReminderTimeHour'] != null &&
        settings['breakReminderTimeMinute'] != null) {
      breakReminderTime = TimeOfDay(
        hour: settings['breakReminderTimeHour'],
        minute: settings['breakReminderTimeMinute'],
      );
    }

    List<TimeOfDay> breakReminderTimes = settings['breakReminderTimes'] ?? [];

    // Migration: If we have a single time but no list, add it to the list
    if (breakReminderTime != null && breakReminderTimes.isEmpty) {
      breakReminderTimes = [breakReminderTime];
      _repository.saveBreakReminderTimes(breakReminderTimes);
    }

    state = state.copyWith(
      currency: settings['currency'],
      monthlyRate: settings['monthlyRate'],
      showEarnings: settings['showEarnings'],
      showFakeData: settings['showFakeData'],
      breakReminders: settings['breakReminders'],
      backupEnabled: settings['backupEnabled'],
      workInterval: settings['workInterval'],
      workHours: settings['workHours'],
      breakDuration: settings['breakDuration'],
      breakReminderTime: breakReminderTime,
      breakReminderTimes: breakReminderTimes,
      googleUser: user,
    );
  }

  void processIntent(SettingsIntent intent) {
    if (intent is UpdateCurrencyIntent) {
      _repository.saveCurrency(intent.currency);
      state = state.copyWith(currency: intent.currency);
    } else if (intent is UpdateMonthlyRateIntent) {
      _repository.saveMonthlyRate(intent.rate);
      state = state.copyWith(monthlyRate: intent.rate);
    } else if (intent is ToggleShowEarningsIntent) {
      _repository.saveShowEarnings(intent.show);
      state = state.copyWith(showEarnings: intent.show);
    } else if (intent is ToggleShowFakeDataIntent) {
      _repository.saveShowFakeData(intent.show);
      state = state.copyWith(showFakeData: intent.show);
    } else if (intent is ToggleBreakRemindersIntent) {
      _repository.saveBreakReminders(intent.enabled);
      state = state.copyWith(breakReminders: intent.enabled);
      if (intent.enabled) {
        _rescheduleAllNotifications(state.breakReminderTimes);
      } else {
        _cancelAllNotifications();
      }
    } else if (intent is ToggleBackupIntent) {
      _repository.saveBackupEnabled(intent.enabled);
      state = state.copyWith(backupEnabled: intent.enabled);
    } else if (intent is UpdateGoogleUserIntent) {
      state = state.copyWith(googleUser: intent.user);
    } else if (intent is UpdateWorkIntervalIntent) {
      _repository.saveWorkInterval(intent.interval);
      state = state.copyWith(workInterval: intent.interval);
    } else if (intent is UpdateWorkHoursIntent) {
      _repository.saveWorkHours(intent.hours);
      state = state.copyWith(workHours: intent.hours);
    } else if (intent is AddBreakReminderTimeIntent) {
      final newTimes = [...state.breakReminderTimes, intent.time];
      _repository.saveBreakReminderTimes(newTimes);
      state = state.copyWith(breakReminderTimes: newTimes);
      if (state.breakReminders) {
        _scheduleNotification(intent.time, _getNotificationId(intent.time));
      }
    } else if (intent is RemoveBreakReminderTimeIntent) {
      final newTimes = state.breakReminderTimes
          .where((t) => t != intent.time)
          .toList();
      _repository.saveBreakReminderTimes(newTimes);
      state = state.copyWith(breakReminderTimes: newTimes);
      NotificationService().cancelNotification(_getNotificationId(intent.time));
      state = state.copyWith(
        googleUser: null,
        backupEnabled: false, // Disable backup when disconnected
      );
      _repository.saveBackupEnabled(false);
    } else if (intent is ResetDataIntent) {
      _resetAllData();
    }
  }

  Future<void> resetData() async {
    await _resetAllData();
  }

  Future<void> _resetAllData() async {
    await LocalDatabase.instance.deleteAllSessions();
    await TimerRepository().clearAllData();

    // Reset Timer State via TimerViewModel?
    // Ideally, we should notify TimerViewModel to reset, but for now,
    // clearing repository data and re-initializing settings/timer will work on next app start or refresh.
    // However, to update UI immediately, we might need a way to reload.
    // Since TimerViewModel watches repository on init, we might need to force a refresh there.
    // But SettingsViewModel doesn't directly control TimerViewModel.
    // For simplicity, we'll just clear data here. The user might need to restart app or we rely on UI updates.

    // Actually, we can just re-init settings to unlock the UI
    await _init();
  }

  int _getNotificationId(TimeOfDay time) {
    return 100 + time.hour * 60 + time.minute;
  }

  Future<void> _rescheduleAllNotifications(List<TimeOfDay> times) async {
    _cancelAllNotifications();
    for (final time in times) {
      await _scheduleNotification(time, _getNotificationId(time));
    }
  }

  Future<void> _cancelAllNotifications() async {
    // Cancel a range of potential IDs or track them.
    // For simplicity, we'll just cancel all notifications for now or use a known range.
    // Since we use hour*60+minute, IDs are unique.
    await NotificationService().cancelAllNotifications();
  }

  Future<void> _scheduleNotification(TimeOfDay time, int id) async {
    await NotificationService().scheduleDailyNotification(
      id: id,
      title: 'Break Reminder',
      body: 'It\'s time for your scheduled break!',
      time: time,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsViewModel, SettingsState>(() {
  return SettingsViewModel();
});
