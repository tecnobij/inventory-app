import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/core/auth_gate.dart';
import 'package:bhago/features/dashboard/controller/auth_provider.dart';
import 'package:bhago/features/dashboard/controller/sales_dispatch_controller.dart';
import 'package:bhago/features/dashboard/controller/theme_controller.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'features/dashboard/controller/actions_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // ⬅️ Single DB instance for the whole app
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),

        // Settings uses the SAME DB instance
      
        // Controllers (no duplicate ThemeController)
        ChangeNotifierProvider(create: (_) => ActionsController()..load()),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..load()),

  ChangeNotifierProvider<SettingsProvider>(
          create: (ctx) => SettingsProvider(ctx.read<AppDatabase>())..load(),
        ),
        // SalesDispatchController reuses SAME DB + Settings
        ChangeNotifierProvider<SalesDispatchController>(
          create: (ctx) => SalesDispatchController(
            db: ctx.read<AppDatabase>(),
            settings: ctx.read<SettingsProvider>(),
          ),
        ),
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
    final lightBase = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1DB954),
    );

    final darkBase = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF1DB954),
    );
    return MaterialApp(
      title: 'BhaGo',
      debugShowCheckedModeBanner: false,
      themeMode: themeCtrl.themeMode,
      theme: lightBase.copyWith(textTheme: _boldAll(lightBase.textTheme)),
      darkTheme: darkBase.copyWith(textTheme: _boldAll(darkBase.textTheme)),
      home:AuthGate(), // <— decide here
    );
  }
}

TextTheme _boldAll(TextTheme t) => t.copyWith(
  displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.w700),
  displayMedium: t.displayMedium?.copyWith(fontWeight: FontWeight.w700),
  displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w700),
  headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
  headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
  headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
  titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  bodyLarge: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
  bodyMedium: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
  bodySmall: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
  labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w700),
  labelSmall: t.labelSmall?.copyWith(fontWeight: FontWeight.w700),
);

