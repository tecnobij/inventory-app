// lib/core/auth/auth_gate.dart
import 'package:bhago/features/dashboard/controller/auth_provider.dart';
import 'package:bhago/features/dashboard/presentation/pages/sections/welcome_auth_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/presentation/dashboard_view.dart';
import 'package:bhago/features/dashboard/presentation/pages/sections/setting_page.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

    // Wait until both providers finished initial load
   if (!settings.loaded) {
  return FutureBuilder(
    future: Future.delayed(const Duration(seconds: 3)),
    builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      // fallback: treat as not onboarded
      return const SettingPage();
    },
  );
}

    if (!auth.loggedIn) {
      return const WelcomeAuthPage();
    }

    // Authenticated → choose between onboarding/settings vs dashboard
    if (!settings.onboarded) {
      return const SettingPage();
    }
    return const DashboardView();
  }
}
