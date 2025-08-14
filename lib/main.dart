import 'package:bhago/features/dashboard/controller/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/dashboard/controller/actions_controller.dart';
import 'features/dashboard/presentation/dashboard_view.dart';
// import your baseLight/baseDark themes (or keep your ThemeData directly)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final actions = ActionsController();
  await actions.load();

  final themeCtrl = ThemeController();
  await themeCtrl.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: actions),
        ChangeNotifierProvider.value(value: themeCtrl),
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
      home: const DashboardView(),
    );
  }
}
