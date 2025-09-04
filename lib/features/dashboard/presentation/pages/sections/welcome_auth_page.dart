// lib/features/dashboard/presentation/pages/welcome_auth_page.dart
import 'package:bhago/features/dashboard/controller/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/presentation/dashboard_view.dart';
import 'package:bhago/features/dashboard/presentation/pages/sections/setting_page.dart';

class WelcomeAuthPage extends StatefulWidget {
  const WelcomeAuthPage({super.key});

  @override
  State<WelcomeAuthPage> createState() => _WelcomeAuthPageState();
}

class _WelcomeAuthPageState extends State<WelcomeAuthPage> {
  bool _busy = false;

  Future<void> _continue() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await context.read<AuthProvider>().signInWithGoogleStub();

      // ensure settings are loaded (in case app just launched)
      final s = context.read<SettingsProvider>();
      if (!s.loaded) {
        await s.load();
      }

      final goSettings = !s.onboarded;
      final next = goSettings ? const SettingPage() : const DashboardView();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => next),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'WO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Welcome to WarehouseOS',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color.fromARGB(255, 113, 112, 112),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 45),

                  // Continue with Google (black button)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _busy ? null : _continue,
                      child: _busy
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text('G', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
                                ),
                                const SizedBox(width: 10),
                                const Text('Continue with Google'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: _busy ? null : () {},
                    child: Text(
                      'Use another method',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const SizedBox(height: 14),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : () {},
                        child: Text(
                          'Privacy Policy',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color.fromARGB(255, 113, 112, 112),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text('·', style: TextStyle(color: scheme.onSurfaceVariant, height: 10)),
                      TextButton(
                        onPressed: _busy ? null : () {},
                        child: Text(
                          'Terms of Service',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color.fromARGB(255, 113, 112, 112),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
