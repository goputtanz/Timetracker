import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';

@immutable
class SettingsState {
  final String currency;
  final String monthlyRate;
  final bool showEarnings;
  final bool showFakeData;
  final bool breakReminders;
  final bool backupEnabled;
  final GoogleSignInAccount? googleUser;
  final int workInterval; // in minutes, 0 means disabled
  final int workHours; // in minutes
  final int breakDuration; // in minutes
  final TimeOfDay? breakReminderTime; // Deprecated, use breakReminderTimes
  final List<TimeOfDay> breakReminderTimes;

  const SettingsState({
    this.currency = 'USD',
    this.monthlyRate = '5000',
    this.showEarnings = true,
    this.showFakeData = false,
    this.breakReminders = false,
    this.backupEnabled = false,
    this.googleUser,
    this.workInterval = 60, // Default 1 hour
    this.workHours = 540, // Default 9 hours
    this.breakDuration = 15, // Default 15 minutes
    this.breakReminderTime,
    this.breakReminderTimes = const [],
  });

  SettingsState copyWith({
    String? currency,
    String? monthlyRate,
    bool? showEarnings,
    bool? showFakeData,
    bool? breakReminders,
    bool? backupEnabled,
    GoogleSignInAccount? googleUser,
    int? workInterval,
    int? workHours,
    int? breakDuration,
    TimeOfDay? breakReminderTime,
    List<TimeOfDay>? breakReminderTimes,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      monthlyRate: monthlyRate ?? this.monthlyRate,
      showEarnings: showEarnings ?? this.showEarnings,
      showFakeData: showFakeData ?? this.showFakeData,
      breakReminders: breakReminders ?? this.breakReminders,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      googleUser: googleUser ?? this.googleUser,
      workInterval: workInterval ?? this.workInterval,
      workHours: workHours ?? this.workHours,
      breakDuration: breakDuration ?? this.breakDuration,
      breakReminderTime: breakReminderTime ?? this.breakReminderTime,
      breakReminderTimes: breakReminderTimes ?? this.breakReminderTimes,
    );
  }

  @override
  List<Object?> get props => [
    currency,
    monthlyRate,
    showEarnings,
    showFakeData,
    breakReminders,
    backupEnabled,
    googleUser,
    workInterval,
    workHours,
    breakDuration,
    breakReminderTime,
    breakReminderTimes,
  ];
}

abstract class SettingsIntent {}

class UpdateCurrencyIntent extends SettingsIntent {
  final String currency;
  UpdateCurrencyIntent(this.currency);
}

class UpdateMonthlyRateIntent extends SettingsIntent {
  final String rate;
  UpdateMonthlyRateIntent(this.rate);
}

class ToggleShowEarningsIntent extends SettingsIntent {
  final bool show;
  ToggleShowEarningsIntent(this.show);
}

class ToggleShowFakeDataIntent extends SettingsIntent {
  final bool show;
  ToggleShowFakeDataIntent(this.show);
}

class ToggleBreakRemindersIntent extends SettingsIntent {
  final bool enabled;
  ToggleBreakRemindersIntent(this.enabled);
}

class ToggleBackupIntent extends SettingsIntent {
  final bool enabled;
  ToggleBackupIntent(this.enabled);
}

class UpdateGoogleUserIntent extends SettingsIntent {
  final GoogleSignInAccount? user;
  UpdateGoogleUserIntent(this.user);
}

class UpdateWorkIntervalIntent extends SettingsIntent {
  final int interval;
  UpdateWorkIntervalIntent(this.interval);
}

class UpdateWorkHoursIntent extends SettingsIntent {
  final int hours;
  UpdateWorkHoursIntent(this.hours);
}

class UpdateBreakDurationIntent extends SettingsIntent {
  final int duration;
  UpdateBreakDurationIntent(this.duration);
}

class UpdateBreakReminderTimeIntent extends SettingsIntent {
  final TimeOfDay? time;
  UpdateBreakReminderTimeIntent(this.time);
}

class AddBreakReminderTimeIntent extends SettingsIntent {
  final TimeOfDay time;
  AddBreakReminderTimeIntent(this.time);
}

class RemoveBreakReminderTimeIntent extends SettingsIntent {
  final TimeOfDay time;
  RemoveBreakReminderTimeIntent(this.time);
}

class DisconnectGoogleAccountIntent extends SettingsIntent {}

class ResetDataIntent extends SettingsIntent {}
