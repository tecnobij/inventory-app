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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
