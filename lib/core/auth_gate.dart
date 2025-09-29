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
    return Selector2<AuthProvider, SettingsProvider, _AuthState>(
      selector: (_, auth, settings) => _AuthState(
        loggedIn: auth.loggedIn,
        loaded: settings.loaded,
        onboarded: settings.onboarded,
      ),
      builder: (context, state, _) {
        if (!state.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!state.loggedIn) {
          return const WelcomeAuthPage();
        }

        if (!state.onboarded) {
          return const SettingPage();
        }

        return const DashboardView();
      },
    );
  }
}

class _AuthState {
  final bool loggedIn;
  final bool loaded;
  final bool onboarded;

  _AuthState({
    required this.loggedIn,
    required this.loaded,
    required this.onboarded,
  });
}
