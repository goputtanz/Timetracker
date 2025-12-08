import 'package:equatable/equatable.dart';

class StatsState extends Equatable {
  final bool isLoading;
  final DateTime currentMonth;
  final List<double> weeklyHours; // Hours for Week 1, 2, 3, 4 (or 5)
  final String weeklyAverage;
  final String thisWeekTotal;
  final double thisWeekEarnings;
  final int selectedWeekIndex; // -1 if none selected

  const StatsState({
    this.isLoading = true,
    required this.currentMonth,
    this.weeklyHours = const [],
    this.weeklyAverage = '0h 0m',
    this.thisWeekTotal = '0h 0m',
    this.thisWeekEarnings = 0.0,
    this.selectedWeekIndex = -1,
  });

  StatsState copyWith({
    bool? isLoading,
    DateTime? currentMonth,
    List<double>? weeklyHours,
    String? weeklyAverage,
    String? thisWeekTotal,
    double? thisWeekEarnings,
    int? selectedWeekIndex,
  }) {
    return StatsState(
      isLoading: isLoading ?? this.isLoading,
      currentMonth: currentMonth ?? this.currentMonth,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      weeklyAverage: weeklyAverage ?? this.weeklyAverage,
      thisWeekTotal: thisWeekTotal ?? this.thisWeekTotal,
      thisWeekEarnings: thisWeekEarnings ?? this.thisWeekEarnings,
      selectedWeekIndex: selectedWeekIndex ?? this.selectedWeekIndex,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    currentMonth,
    weeklyHours,
    weeklyAverage,
    thisWeekTotal,
    thisWeekEarnings,
    selectedWeekIndex,
  ];
}

abstract class StatsIntent {}

class LoadStatsIntent extends StatsIntent {
  final DateTime? month;
  LoadStatsIntent({this.month});
}

class ChangeMonthIntent extends StatsIntent {
  final int offset; // -1 for prev, 1 for next
  ChangeMonthIntent(this.offset);
}

class SelectWeekIntent extends StatsIntent {
  final int index;
  SelectWeekIntent(this.index);
}
