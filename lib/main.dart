import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/core/auth_gate.dart';
import 'package:bhago/features/dashboard/controller/auth_provider.dart';

import 'package:bhago/features/dashboard/controller/theme_controller.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import 'features/dashboard/controller/actions_controller.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize SQLite
  final db = AppDatabase();



  final themeCtrl = ThemeController();
  await themeCtrl.load();



  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: db), // ✅ inject DB globally
     ChangeNotifierProvider(
  create: (_) {
    final c = ActionsController();
    c.load(); // kick off SharedPreferences load + sanitize
    return c;
  },
),

        ChangeNotifierProvider.value(value: themeCtrl),
       ChangeNotifierProvider(create: (ctx) => AuthProvider()..load()),
        ChangeNotifierProvider(create: (ctx) => SettingsProvider(db)..load()),
          Provider<AppDatabase>(create: (_) => db, dispose: (_, d) => d.close()),
        ChangeNotifierProvider(
          create: (ctx) => SettingsProvider(ctx.read<AppDatabase>())..load(),
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

// class _HomeDecider extends StatelessWidget {
//   const _HomeDecider();

//   Future<bool> _isSignedIn() async {
//     final sp = await SharedPreferences.getInstance();
//     return sp.getBool('auth_ok') ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final s = context.watch<SettingsProvider>();

//     return FutureBuilder<bool>(
//       future: _isSignedIn(),
//       builder: (context, snap) {
//         if (!s.loaded || snap.connectionState != ConnectionState.done) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         final signedIn = snap.data ?? false;
//         if (!signedIn) {
//           // First time: show Welcome / Sign-in page
//           return const WelcomeAuthPage();
//         }

//         // Signed in: decide between Settings onboarding or Dashboard
//         final showSettings = !(s.onboarded );
//         return showSettings ? const WelcomeAuthPage() : const DashboardView();
//       },
//     );
//   }
// }
