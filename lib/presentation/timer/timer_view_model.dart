import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/timer_repository.dart';
import '../../data/local_database.dart';
import '../../data/backup_repository.dart';
import '../settings/settings_view_model.dart';
import '../../services/notification_service.dart';
import '../../services/home_widget_service.dart';
import 'timer_contract.dart';

class TimerViewModel extends Notifier<TimerState> {
  final TimerRepository _repository = TimerRepository();
  Timer? _ticker;

  @override
  TimerState build() {
    _init();

    // Listen to settings changes to update earnings immediately
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.currency != next.currency ||
          previous?.monthlyRate != next.monthlyRate ||
          previous?.workHours != next.workHours ||
          previous?.showEarnings != next.showEarnings ||
          previous?.showFakeData != next.showFakeData) {
        _updateEarnings();
      }
    });

    ref.onDispose(() {
      _stopTicker();
    });
    return const TimerState();
  }

  Future<void> _init() async {
    await NotificationService().init();
    await NotificationService().requestPermissions();
    final totalTime = await _repository.getTotalTime();
    final totalBreakTime = await _repository.getTotalBreakTime();
    final breakCount = await _repository.getBreakCount();
    final sessionStart = await _repository.getSessionStart();
    final breakStart = await _repository.getBreakStart();
    final appCloseTime = await _repository.getAppCloseTime();

    // Fetch weekly stats from Local Database
    final now = DateTime.now();
    // Calculate start of the week (Monday)
    // If today is Monday (1), subtract 0 days.
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final dbSessions = await LocalDatabase.instance.getSessionsForWeek(
      startOfWeek,
    );
    final weeklyStats = List<Map<String, dynamic>>.from(dbSessions);

    TimerStatus status = TimerStatus.ready;
    Duration currentTotalTime = totalTime;
    Duration currentBreakTime = totalBreakTime;

    if (sessionStart != null) {
      status = TimerStatus.tracking;
      if (appCloseTime != null) {
        final elapsed = now.difference(appCloseTime);
        if (breakStart != null) {
          // App closed during break
          status = TimerStatus.breakTime;
          currentBreakTime += elapsed;
        } else {
          // App closed during tracking
          currentTotalTime += elapsed;
        }
      }
      _startTicker();
    }

    state = state.copyWith(
      status: status,
      totalTime: currentTotalTime,
      breakTime: currentBreakTime,
      startTime: sessionStart,
      breakStartTime: breakStart,
      breakCount: breakCount,
      weeklyStats: weeklyStats,
      currentSessionTime:
          Duration.zero, // Ideally calculate if app was closed during tracking
    );
    _updateEarnings();
  }

  void processIntent(TimerIntent intent) {
    if (intent is StartTimerIntent) {
      _startTimer();
    } else if (intent is StopTimerIntent) {
      _stopTimer();
    } else if (intent is StartBreakIntent) {
      _startBreak();
    } else if (intent is EndBreakIntent) {
      _endBreak();
    } else if (intent is AppPausedIntent) {
      _onAppPaused();
    } else if (intent is AppResumedIntent) {
      _onAppResumed();
    } else if (intent is TickIntent) {
      _onTick();
    }
  }

  void _startTimer() {
    final now = DateTime.now();
    _repository.saveSessionStart(now);
    state = state.copyWith(status: TimerStatus.tracking, startTime: now);
    _startTicker();
  }

  void _stopTimer() {
    _saveDailyStat();
    _repository.clearSession();
    _stopTicker();
    state = state.copyWith(
      status: TimerStatus.ready,
      totalTime: Duration.zero,
      breakTime: Duration.zero,
      breakCount: 0,
      currentSessionTime: Duration.zero,
      workNotificationSent: false,
      breakNotificationSent: false,
    );
  }

  Future<void> _saveDailyStat() async {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final seconds = state.totalTime.inSeconds;
    final progress = (seconds / (9 * 3600)).clamp(0.0, 1.0);

    final newStat = {
      'day': dayName,
      'date': now.toIso8601String().substring(0, 10),
      'seconds': seconds,
      'progress': progress,
      'break_time': state.breakTime.inSeconds,
      'break_count': state.breakCount,
    };

    // Save to Local Database
    await LocalDatabase.instance.insertSession(newStat);

    // Refresh from DB to ensure consistency
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final currentStats = await LocalDatabase.instance.getSessionsForWeek(
      startOfWeek,
    );

    // Trigger backup if enabled
    final settings = ref.read(settingsProvider);
    if (settings.backupEnabled) {
      await BackupRepository().uploadBackup();
    }

    state = state.copyWith(weeklyStats: currentStats);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  void _startBreak() {
    final now = DateTime.now();
    _repository.saveBreakStart(now);
    final newBreakCount = state.breakCount + 1;
    _repository.saveBreakCount(newBreakCount);
    state = state.copyWith(
      status: TimerStatus.breakTime,
      breakStartTime: now,
      breakCount: newBreakCount,
      currentSessionTime: Duration.zero,
      workNotificationSent: false,
      breakNotificationSent: false,
    );
  }

  void _endBreak() {
    _repository.clearBreakStart();
    state = state.copyWith(
      status: TimerStatus.tracking,
      breakStartTime: null,
      breakNotificationSent: false,
    );
  }

  void _onAppPaused() {
    _repository.saveAppCloseTime(DateTime.now());
    _repository.saveTotalTime(state.totalTime);
    _repository.saveTotalBreakTime(state.breakTime);
  }

  void _onAppResumed() {
    _init(); // Re-sync state
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      processIntent(TickIntent());
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick() {
    if (state.status == TimerStatus.tracking) {
      final newTotalTime = state.totalTime + const Duration(seconds: 1);
      final newSessionTime =
          state.currentSessionTime + const Duration(seconds: 1);

      final settings = ref.read(settingsProvider);
      if (newTotalTime.inMinutes >= settings.workHours) {
        _stopTimer(); // Auto-save
        return;
      }

      // Check for work interval notification
      // final settings = ref.read(settingsProvider); // Already read above
      if (settings.workInterval > 0 &&
          newSessionTime.inMinutes >= settings.workInterval &&
          !state.workNotificationSent) {
        NotificationService().showNotification(
          id: 1,
          title: 'Time for a break!',
          body:
              'You have been working for ${_formatDuration(newSessionTime)}. Take a break?',
        );
        state = state.copyWith(
          totalTime: newTotalTime,
          currentSessionTime: newSessionTime,
          workNotificationSent: true,
        );
        return;
      }

      state = state.copyWith(
        totalTime: newTotalTime,
        currentSessionTime: newSessionTime,
      );

      // Periodic save every minute to prevent data loss
      if (newTotalTime.inSeconds % 60 == 0) {
        _repository.saveTotalTime(newTotalTime);
        _repository.saveTotalBreakTime(state.breakTime);
      }

      // Update earnings and widget every 2 minutes
      if (newTotalTime.inSeconds % 120 == 0) {
        _updateEarnings();
      }
    } else if (state.status == TimerStatus.breakTime) {
      final newBreakTime = state.breakTime + const Duration(seconds: 1);

      // Check for break duration notification
      if (state.breakStartTime != null) {
        final currentBreakDuration = DateTime.now().difference(
          state.breakStartTime!,
        );
        final settings = ref.read(settingsProvider);

        if (settings.breakReminders &&
            settings.breakDuration > 0 &&
            currentBreakDuration.inMinutes >= settings.breakDuration &&
            !state.breakNotificationSent) {
          NotificationService().showNotification(
            id: 2,
            title: 'Break over!',
            body: 'Break time is up. Ready to get back to work?',
          );
          state = state.copyWith(
            breakTime: newBreakTime,
            breakNotificationSent: true,
          );
          return;
        }
      }

      state = state.copyWith(breakTime: newBreakTime);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '$hours h $minutes m';
    return '$minutes m';
  }

  int _calculateWorkingDays(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    int workingDays = 0;
    for (int i = 1; i <= daysInMonth; i++) {
      final day = DateTime(month.year, month.month, i);
      if (day.weekday >= 1 && day.weekday <= 5) {
        workingDays++;
      }
    }
    return workingDays;
  }

  @override
  set state(TimerState value) {
    final oldStatus = state.status;
    super.state = value;

    // Update widget immediately on status change
    if (oldStatus != value.status) {
      _updateWidget();
    }
  }

  void _updateEarnings() {
    final settings = ref.read(settingsProvider);
    String earnings = '';

    if (settings.showEarnings) {
      if (settings.showFakeData) {
        earnings = settings.currency.contains('USD')
            ? '\$ 8,888.88'
            : '₹ 8,888.88';
      } else {
        final now = DateTime.now();
        final workingDays = _calculateWorkingDays(now);

        final monthlyRate = double.tryParse(settings.monthlyRate) ?? 0;
        final dailyRate = workingDays > 0 ? monthlyRate / workingDays : 0;
        final dailyHours = settings.workHours / 60;
        final hourlyRate = dailyHours > 0 ? dailyRate / dailyHours : 0;

        final earned = (state.totalTime.inSeconds / 3600) * hourlyRate;
        final symbol = settings.currency.contains('USD') ? '\$' : '₹';
        earnings = '$symbol ${earned.toStringAsFixed(2)}';
      }
    }

    state = state.copyWith(earnings: earnings);
    HomeWidgetService().updateWidget(state, earnings: earnings);
  }

  void _updateWidget() {
    // Just trigger earnings update which handles widget update too
    _updateEarnings();
  }
}

final timerProvider = NotifierProvider<TimerViewModel, TimerState>(() {
  return TimerViewModel();
});
