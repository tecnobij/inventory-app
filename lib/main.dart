import 'package:bhago/features/dashboard/controller/theme_controller.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/presentation/pages/sections/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/dashboard/controller/actions_controller.dart';
import 'features/dashboard/presentation/dashboard_view.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final actions = ActionsController();
  await actions.load();

  final themeCtrl = ThemeController();
  await themeCtrl.load();

  final settings = SettingsProvider();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: actions),
        ChangeNotifierProvider.value(value: themeCtrl),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();

    return MaterialApp(
      title: 'BhaGo',
      debugShowCheckedModeBanner: false,
      themeMode: themeCtrl.themeMode,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF1DB954)),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: const Color(0xFF1DB954)),
      home: const _HomeDecider(), // <— decide here
    );
  }
}

class _HomeDecider extends StatelessWidget {
  const _HomeDecider();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    if (!s.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final showSettings = !(s.onboarded || s.isComplete);
    return showSettings ? const SettingPage() : const DashboardView();
  }
}
