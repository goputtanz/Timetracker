import 'dart:math';
import 'local_database.dart';

class FakeDataSeeder {
  static Future<void> seedSessions() async {
    final db = LocalDatabase.instance;
    await db.deleteAllSessions();

    final now = DateTime.now();
    final random = Random();

    // Generate data for the last 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));

      // Skip Sundays (optional, but realistic)
      if (date.weekday == 7) continue;

      // Random work duration: 2 to 9 hours (in seconds)
      final hours = 2 + random.nextInt(8);
      final minutes = random.nextInt(60);
      final seconds = (hours * 3600) + (minutes * 60);

      // Random break time: 10 to 60 minutes
      final breakMinutes = 10 + random.nextInt(51);
      final breakSeconds = breakMinutes * 60;

      // Random break count: 1 to 5
      final breakCount = 1 + random.nextInt(5);

      final progress = (seconds / (9 * 3600)).clamp(0.0, 1.0);

      final session = {
        'day': _getDayName(date.weekday),
        'date': date.toIso8601String().substring(0, 10),
        'seconds': seconds,
        'progress': progress,
        'break_time': breakSeconds,
        'break_count': breakCount,
      };

      await db.insertSession(session);
    }

    print('Fake data seeded successfully for 30 days.');
  }

  static String _getDayName(int weekday) {
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
}
