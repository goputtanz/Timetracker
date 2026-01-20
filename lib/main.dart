import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/splash/splash_screen.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

import 'services/notification_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'data/fake_data_seeder.dart';

const bool kUseFakeData = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  if (kUseFakeData) {
    await FakeDataSeeder.seedSessions();
  }

  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Staytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
