import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/services/campus_configuration_store.dart';
import 'core/services/campus_info_store.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/timetable/timetable_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await CampusConfigurationStore.initialize(timetableSchedule);
  await CampusInfoStore.initialize();
  runApp(SnapMarkApp(themeController: ThemeModeController(preferences)));
}

class SnapMarkApp extends StatelessWidget {
  const SnapMarkApp({required this.themeController, super.key});

  final ThemeModeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SnapMark',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.mode,
        builder: (context, child) => ThemeModeScope(
          controller: themeController,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
