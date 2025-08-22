import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/presentation/dashboard_view.dart';
import 'package:bhago/features/dashboard/presentation/pages/sections/setting_page.dart';

class WelcomeAuthPage extends StatelessWidget {
  const WelcomeAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Future<void> _continue() async {
      // Simulate successful auth and persist it
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('auth_ok', true);

      // Decide where to go next
      final s = context.read<SettingsProvider>();
      final goSettings = !(s.onboarded || s.isComplete);
      final next = goSettings ? const SettingPage() : const DashboardView();

      // Replace this page
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => next),
      );
    }

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
                  // Logo badge
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color:const Color.fromARGB(255, 113, 112, 112),fontWeight: FontWeight.w600),
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
                      onPressed: _continue,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Simple "G" avatar (replace with real Google icon if you have assets)
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

                  // Another method
                  TextButton(
                    onPressed: () {},
                    child:  Text('Use another method',  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black,fontWeight: FontWeight.w600),),
                  ),

                  const SizedBox(height: 18),
               
                  const SizedBox(height: 14),

                  // Footer links
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child:  Text('Privacy Policy'
                        ,  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color:const Color.fromARGB(255, 113, 112, 112),fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('·', style: TextStyle( color: scheme.onSurfaceVariant,height: 10),),
                      TextButton(
                        onPressed: () {},
                        child:  Text('Terms of Service',  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color:const Color.fromARGB(255, 113, 112, 112),fontWeight: FontWeight.w600),),
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
