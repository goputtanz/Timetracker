import 'package:flutter/foundation.dart';

enum TimerStatus { ready, tracking, breakTime }

@immutable
class TimerState {
  final TimerStatus status;
  final Duration totalTime;
  final Duration breakTime;
  final DateTime? startTime;
  final DateTime? breakStartTime;
  final int breakCount;
  final List<Map<String, dynamic>> weeklyStats;
  final Duration currentSessionTime;
  final bool workNotificationSent;
  final bool breakNotificationSent;
  final String earnings;

  const TimerState({
    this.status = TimerStatus.ready,
    this.totalTime = Duration.zero,
    this.breakTime = Duration.zero,
    this.startTime,
    this.breakStartTime,
    this.breakCount = 0,
    this.weeklyStats = const [],
    this.currentSessionTime = Duration.zero,
    this.workNotificationSent = false,
    this.breakNotificationSent = false,
    this.earnings = '',
  });

  TimerState copyWith({
    TimerStatus? status,
    Duration? totalTime,
    Duration? breakTime,
    DateTime? startTime,
    DateTime? breakStartTime,
    int? breakCount,
    List<Map<String, dynamic>>? weeklyStats,
    Duration? currentSessionTime,
    bool? workNotificationSent,
    bool? breakNotificationSent,
    String? earnings,
  }) {
    return TimerState(
      status: status ?? this.status,
      totalTime: totalTime ?? this.totalTime,
      breakTime: breakTime ?? this.breakTime,
      startTime: startTime ?? this.startTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakCount: breakCount ?? this.breakCount,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      currentSessionTime: currentSessionTime ?? this.currentSessionTime,
      workNotificationSent: workNotificationSent ?? this.workNotificationSent,
      breakNotificationSent:
          breakNotificationSent ?? this.breakNotificationSent,
      earnings: earnings ?? this.earnings,
    );
  }
}

sealed class TimerIntent {}

class StartTimerIntent extends TimerIntent {}

class StopTimerIntent extends TimerIntent {}

class StartBreakIntent extends TimerIntent {}

class EndBreakIntent extends TimerIntent {}

class AppPausedIntent extends TimerIntent {}

class AppResumedIntent extends TimerIntent {}

class TickIntent extends TimerIntent {}
