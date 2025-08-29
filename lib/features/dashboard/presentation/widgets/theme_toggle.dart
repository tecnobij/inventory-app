import 'package:bhago/features/dashboard/controller/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


/// 1) QUICK TOGGLE — put this in AppBar.actions
class ThemeQuickToggle extends StatelessWidget {
  const ThemeQuickToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ThemeController>();

    IconData icon;
    String label;
    switch (ctrl.themeMode) {
      case ThemeMode.light:
        icon = Icons.light_mode_outlined;
        label = 'Light';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode_outlined;
        label = 'Dark';
        break;
      case ThemeMode.system:
      default:
        icon = Icons.auto_awesome;
        label = 'System';
    }

    return IconButton(
      tooltip: 'Theme: $label (tap to change)',
      icon: Icon(icon),
      onPressed: () {
        final next = switch (ctrl.themeMode) {
          ThemeMode.system => ThemeMode.light,
          ThemeMode.light  => ThemeMode.dark,
          ThemeMode.dark   => ThemeMode.system,
        };
        context.read<ThemeController>().setThemeMode(next);
      },
    );
  }
}

/// 2) SETTINGS CARD — put this on your Settings page
class ThemeSettingsCard extends StatelessWidget {
  const ThemeSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ThemeController>();
    final followSystem = ctrl.followSystem;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Choose how the app looks on your device.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            const SizedBox(height: 12),

            // Follow system switch
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: followSystem,
              onChanged: (v) => context.read<ThemeController>().setFollowSystem(v),
              title: const Text('Follow system theme'),
              subtitle: const Text('Use your device’s theme setting'),
            ),

            // Light/Dark segmented control (only when NOT following system)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: followSystem
                  ? const SizedBox.shrink()
                  : Padding(
                      key: const ValueKey('manual-theme'),
                      padding: const EdgeInsets.only(top: 8),
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.wb_sunny_outlined),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.nightlight_round),
                          ),
                        ],
                        // when not following system, only light/dark are valid
                        selected: {
                          ctrl.themeMode == ThemeMode.dark
                              ? ThemeMode.dark
                              : ThemeMode.light
                        },
                        onSelectionChanged: (set) {
                          final mode = set.first;
                          context.read<ThemeController>().setThemeMode(mode);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
