import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/home/home_screen.dart';
import '../features/settings/settings_controller.dart';
import 'theme.dart';
import 'router.dart';

class SkillBridgeApp extends StatelessWidget {
  const SkillBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillsBridg Academy',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: context.watch<SettingsController>().themeMode,
      home: const HomeScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
