import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local_database.dart';
import 'stats_contract.dart';
import '../settings/settings_view_model.dart';
import '../timer/timer_view_model.dart';

final statsProvider = NotifierProvider<StatsViewModel, StatsState>(
  StatsViewModel.new,
);

class StatsViewModel extends Notifier<StatsState> {
  @override
  StatsState build() {
    final initialState = StatsState(currentMonth: DateTime.now());

    // Listen to settings changes
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.currency != next.currency ||
          previous?.monthlyRate != next.monthlyRate ||
          previous?.workHours != next.workHours) {
        _loadStats(state.currentMonth);
      }
    });

    // Listen to timer changes to refresh stats when data changes
    ref.listen(timerProvider, (previous, next) {
      if (previous?.weeklyStats != next.weeklyStats) {
        _loadStats(state.currentMonth);
      }
    });

    // Trigger initial load
    Future.microtask(() => _loadStats(initialState.currentMonth));
    return initialState;
  }

  void processIntent(StatsIntent intent) {
    if (intent is LoadStatsIntent) {
      _loadStats(intent.month ?? state.currentMonth);
    } else if (intent is ChangeMonthIntent) {
      final newMonth = DateTime(
        state.currentMonth.year,
        state.currentMonth.month + intent.offset,
      );
      _loadStats(newMonth);
    } else if (intent is SelectWeekIntent) {
      state = state.copyWith(selectedWeekIndex: intent.index);
    }
  }

  Future<void> _loadStats(DateTime month) async {
    state = state.copyWith(isLoading: true, currentMonth: month);

    try {
      final sessions = await LocalDatabase.instance.getSessionsForMonth(month);

      // Group by week
      // We'll define weeks as 1-7, 8-14, 15-21, 22-end for simplicity matching the 4 bars

      final weeklyHours = List<double>.filled(4, 0.0);
      double totalMonthSeconds = 0;

      for (var session in sessions) {
        final dateStr = session['date'] as String;
        final date = DateTime.parse(dateStr);
        final seconds = session['seconds'] as int;

        // Simple binning by day of month
        // Days 1-7 -> Week 1 (index 0)
        // Days 8-14 -> Week 2 (index 1)
        // Days 15-21 -> Week 3 (index 2)
        // Days 22+ -> Week 4 (index 3)

        int weekIndex = 0;
        if (date.day >= 22) {
          weekIndex = 3;
        } else if (date.day >= 15) {
          weekIndex = 2;
        } else if (date.day >= 8) {
          weekIndex = 1;
        }

        weeklyHours[weekIndex] += seconds / 3600.0;
        totalMonthSeconds += seconds;
      }

      // Calculate Weekly Average
      final avgSeconds = totalMonthSeconds / 4;
      final weeklyAverage = _formatDuration(
        Duration(seconds: avgSeconds.round()),
      );

      // Calculate This Week's stats
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekSessions = await LocalDatabase.instance.getSessionsForWeek(
        startOfWeek,
      );

      double thisWeekSeconds = 0;
      for (var s in thisWeekSessions) {
        thisWeekSeconds += (s['seconds'] as int);
      }

      final thisWeekTotal = _formatDuration(
        Duration(seconds: thisWeekSeconds.round()),
      );

      // Calculate Earnings
      final settings = ref.read(settingsProvider);
      final workingDays = _calculateWorkingDays(now);

      final monthlyRate = double.tryParse(settings.monthlyRate) ?? 0;
      final dailyRate = workingDays > 0 ? monthlyRate / workingDays : 0;
      final dailyHours = settings.workHours / 60;
      final hourlyRate = dailyHours > 0 ? dailyRate / dailyHours : 0;

      final thisWeekEarnings = (thisWeekSeconds / 3600.0) * hourlyRate;

      state = state.copyWith(
        isLoading: false,
        weeklyHours: weeklyHours,
        weeklyAverage: weeklyAverage,
        thisWeekTotal: thisWeekTotal,
        thisWeekEarnings: thisWeekEarnings,
      );
    } catch (e) {
      // Handle error
      state = state.copyWith(isLoading: false);
      print('Error loading stats: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
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
}
