import 'package:home_widget/home_widget.dart';
import '../presentation/timer/timer_contract.dart';

class HomeWidgetService {
  static const String appGroupId =
      'group.com.example.staytics'; // Replace with your actual App Group ID if using iOS
  static const String androidWidgetName = 'HomeWidgetProvider';

  Future<void> updateWidget(TimerState state, {String? earnings}) async {
    // Save data to the widget
    await HomeWidget.saveWidgetData<String>(
      'timer_status',
      state.status.toString(),
    );
    await HomeWidget.saveWidgetData<int>(
      'timer_seconds',
      state.totalTime.inSeconds,
    );
    await HomeWidget.saveWidgetData<bool>(
      'is_tracking',
      state.status == TimerStatus.tracking,
    );

    // Format duration for display
    final duration = state.totalTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final timeString = '${hours}h ${minutes}m';

    // Calculate additional stats

    final breakMinutes = state.breakTime.inMinutes;
    final avgBreak = state.breakCount > 0
        ? (state.breakTime.inMinutes / state.breakCount).round()
        : 0;
    final progress = (duration.inSeconds / (9 * 3600) * 100)
        .clamp(0, 100)
        .toInt();

    String statusText = 'IDLE';
    if (state.status == TimerStatus.tracking) statusText = 'TRACKING';
    if (state.status == TimerStatus.breakTime) statusText = 'ON BREAK';

    await HomeWidget.saveWidgetData<String>('timer_display', timeString);
    await HomeWidget.saveWidgetData<String>('today_hours', timeString);
    await HomeWidget.saveWidgetData<String>(
      'break_time_minutes',
      '${breakMinutes}m',
    );
    await HomeWidget.saveWidgetData<String>(
      'break_count',
      state.breakCount.toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      'avg_break_minutes',
      '${avgBreak}m',
    );
    await HomeWidget.saveWidgetData<String>('earnings', earnings ?? '\$0.00');
    await HomeWidget.saveWidgetData<int>('progress', progress);
    await HomeWidget.saveWidgetData<String>('status_text', statusText);

    // Update the widgets
    await HomeWidget.updateWidget(name: 'SmallHomeWidgetProvider');
    await HomeWidget.updateWidget(name: 'MediumHomeWidgetProvider');
  }
}
