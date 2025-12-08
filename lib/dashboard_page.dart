import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/custom_colors.dart';
import 'theme/theme_controller.dart';
import 'presentation/timer/timer_contract.dart';
import 'presentation/timer/timer_view_model.dart';
import 'presentation/settings/settings_contract.dart';
import 'presentation/settings/settings_view_model.dart';
import 'presentation/widgets/custom_dialog.dart';
import 'presentation/widgets/staytics_button.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(timerProvider.notifier).processIntent(AppPausedIntent());
    } else if (state == AppLifecycleState.resumed) {
      ref.read(timerProvider.notifier).processIntent(AppResumedIntent());
    }
  }

  String _calculateTodayTotal(TimerState state) {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // Sum seconds from completed sessions today
    final completedSeconds = state.weeklyStats
        .where((s) => s['date'] == todayStr)
        .fold<int>(0, (sum, s) => sum + (s['seconds'] as int));

    // Add current session seconds
    final totalSeconds = completedSeconds + state.totalTime.inSeconds;

    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return '$hours:$minutes:$seconds';
  }

  String _getCurrencySymbol(String currency) {
    if (currency.contains('USD')) return '\$';
    if (currency.contains('INR')) return '₹';
    return currency;
  }

  String _calculateEarnings(
    TimerState timerState,
    SettingsState settingsState,
  ) {
    return timerState.earnings;
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final settingsState = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Time Tracker',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your work hours efficiently',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TimerSection(
                state: timerState,
                onIntent: ref.read(timerProvider.notifier).processIntent,
              ),
              const SizedBox(height: 24),
              if (settingsState.showEarnings)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: InfoCard(
                          icon: Icons.access_time,
                          label: 'Today',
                          value: _calculateTodayTotal(timerState),
                        ),
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: InfoCard(
                          icon: Icons.attach_money_outlined,
                          label: 'Earnings',
                          value: _calculateEarnings(timerState, settingsState),
                        ),
                      ),
                    ),
                  ],
                )
              else
                InfoCard(
                  icon: Icons.access_time,
                  label: 'Today',
                  value: _calculateTodayTotal(timerState),
                ),
            ],
          ),
          const SizedBox(height: 24),
          BreakTimeSection(state: timerState),
          const SizedBox(height: 24),
          ThisWeekSection(state: timerState),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class TimerSection extends StatelessWidget {
  final TimerState state;
  final Function(TimerIntent) onIntent;

  const TimerSection({super.key, required this.state, required this.onIntent});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _getSubtitle() {
    switch (state.status) {
      case TimerStatus.tracking:
        return 'Tracking time';
      case TimerStatus.breakTime:
        return 'Break time';
      case TimerStatus.ready:
        return 'Ready to start?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTracking = state.status == TimerStatus.tracking;
    final isBreak = state.status == TimerStatus.breakTime;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.timer_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (isTracking) {
                    showDialog(
                      context: context,
                      builder: (context) => CustomDialog(
                        title: 'Stop Timer?',
                        description: 'Are you sure you want to stop the timer?',
                        primaryButtonText: 'Stop',
                        onPrimaryPressed: () {
                          Navigator.pop(context);
                          onIntent(StopTimerIntent());
                        },
                        secondaryButtonText: 'Cancel',
                        onSecondaryPressed: () => Navigator.pop(context),
                        primaryButtonColor: Theme.of(
                          context,
                        ).extension<SpecialColors>()?.warningColor,
                      ),
                    );
                  } else if (isBreak) {
                    // Do nothing or maybe stop break?
                  } else {
                    onIntent(StartTimerIntent());
                  }
                },
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTracking
                        ? Theme.of(
                            context,
                          ).extension<SpecialColors>()!.stopButtonColor
                        : Theme.of(
                            context,
                          ).extension<SpecialColors>()!.playButtonColor,
                  ),
                  child: Center(
                    child: Icon(
                      isTracking
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ),
              if (isBreak)
                Positioned(top: 0, right: 0, child: _BreakIndicator()),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatDuration(state.totalTime),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),
          if (isTracking || isBreak)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StayticsButton(
                text: isBreak ? 'End Break' : 'Start Break',
                icon: Icons.coffee_outlined,
                onTap: () {
                  if (isBreak) {
                    onIntent(EndBreakIntent());
                  } else {
                    onIntent(StartBreakIntent());
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BreakIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).extension<SpecialColors>()!.breakIndicatorColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.coffee_outlined, size: 16),
          const SizedBox(width: 6),
          Text(
            'Break',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class BreakTimeSection extends StatelessWidget {
  final TimerState state;
  const BreakTimeSection({super.key, required this.state});

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) return '${duration.inSeconds}s';
    return '${duration.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // Sum break time and count from completed sessions today
    final dbBreakTime = state.weeklyStats
        .where((s) => s['date'] == todayStr)
        .fold<int>(0, (sum, s) => sum + ((s['break_time'] ?? 0) as int));

    final dbBreakCount = state.weeklyStats
        .where((s) => s['date'] == todayStr)
        .fold<int>(0, (sum, s) => sum + ((s['break_count'] ?? 0) as int));

    // Add current session break stats
    final totalBreakSeconds = dbBreakTime + state.breakTime.inSeconds;
    final totalBreakCount = dbBreakCount + state.breakCount;
    final totalBreakDuration = Duration(seconds: totalBreakSeconds);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Break Time',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Icon(
                Icons.coffee_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(
                    context,
                  ).extension<SpecialColors>()?.customSurfaceColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Total Break Time',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(totalBreakDuration),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BreakStatCard(
                  label: 'Breaks Today',
                  value: '$totalBreakCount',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BreakStatCard(
                  label: 'Avg Break',
                  value: totalBreakCount > 0
                      ? _formatDuration(
                          Duration(
                            seconds: totalBreakSeconds ~/ totalBreakCount,
                          ),
                        )
                      : '0m',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Break time is excluded from total hours',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class BreakStatCard extends StatelessWidget {
  final String label;
  final String value;

  const BreakStatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).extension<SpecialColors>()?.customSurfaceColor ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class ThisWeekSection extends StatelessWidget {
  final TimerState state;
  const ThisWeekSection({super.key, this.state = const TimerState()});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    // Default empty week
    final List<Map<String, dynamic>> defaultWeek = [
      {'day': 'Mon', 'seconds': 0, 'progress': 0.0},
      {'day': 'Tue', 'seconds': 0, 'progress': 0.0},
      {'day': 'Wed', 'seconds': 0, 'progress': 0.0},
      {'day': 'Thu', 'seconds': 0, 'progress': 0.0},
      {'day': 'Fri', 'seconds': 0, 'progress': 0.0},
      {'day': 'Sat', 'seconds': 0, 'progress': 0.0},
      {'day': 'Sun', 'seconds': 0, 'progress': 0.0},
    ];

    // Merge actual stats
    for (var stat in state.weeklyStats) {
      final index = defaultWeek.indexWhere((e) => e['day'] == stat['day']);
      if (index != -1) {
        // Aggregate seconds if multiple entries exist for the same day
        defaultWeek[index]['seconds'] =
            (defaultWeek[index]['seconds'] as int) + (stat['seconds'] as int);
      }
    }

    // Add current session time to today's stat
    if (state.status == TimerStatus.tracking ||
        state.status == TimerStatus.breakTime) {
      final now = DateTime.now();
      String getDayName(int weekday) {
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

      final todayName = getDayName(now.weekday);
      final index = defaultWeek.indexWhere((e) => e['day'] == todayName);
      if (index != -1) {
        defaultWeek[index]['seconds'] =
            (defaultWeek[index]['seconds'] as int) + state.totalTime.inSeconds;
      }
    }

    // Recalculate progress for all days
    for (var dayStat in defaultWeek) {
      final seconds = dayStat['seconds'] as int;
      dayStat['progress'] = (seconds / (9 * 3600)).clamp(0.0, 1.0);
    }

    final totalSeconds = defaultWeek.fold<int>(
      0,
      (sum, item) => sum + (item['seconds'] as int),
    );
    final totalDuration = Duration(seconds: totalSeconds);

    final averageSeconds = totalSeconds ~/ 7;
    final averageDuration = Duration(seconds: averageSeconds);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'This Week',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Icon(
                Icons.history_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(
                    context,
                  ).extension<SpecialColors>()?.customSurfaceColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Total Hours',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDuration(totalDuration),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...defaultWeek.map(
            (data) => Column(
              children: [
                DailyStatRow(
                  day: data['day'] as String,
                  time: _formatDuration(
                    Duration(seconds: data['seconds'] as int),
                  ),
                  progress: (data['progress'] as num).toDouble(),
                ),
                if (data != defaultWeek.last)
                  Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    thickness: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Average: ${_formatDuration(averageDuration)} per day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DailyStatRow extends StatelessWidget {
  final String day;
  final String time;
  final double progress;

  const DailyStatRow({
    super.key,
    required this.day,
    required this.time,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor:
                    Theme.of(
                      context,
                    ).extension<SpecialColors>()?.customSurfaceColor ??
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            time,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
