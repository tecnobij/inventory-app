import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhago/features/dashboard/controller/theme_controller.dart';

/// 1) QUICK TOGGLE — show current mode and toggle Light <-> Dark on tap
class ThemeQuickToggle extends StatelessWidget {
  const ThemeQuickToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ThemeController>();
    final isDark = ctrl.themeMode == ThemeMode.dark;

    return IconButton(
      tooltip: isDark ? 'Theme: Dark (tap for Light)' : 'Theme: Light (tap for Dark)',
      icon: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
      onPressed: () {
        context.read<ThemeController>().setThemeMode(
              isDark ? ThemeMode.light : ThemeMode.dark,
            );
      },
    );
  }
}

/// 2) SETTINGS CARD — only the 2 options (Light / Dark)
class ThemeSettingsCard extends StatelessWidget {
  const ThemeSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ThemeController>();
    final isDark = ctrl.themeMode == ThemeMode.dark;

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
            Text(
              'Choose Light or Dark theme.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Only Light/Dark segmented control (no "Follow system")
            SegmentedButton<ThemeMode>(
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
              selected: {isDark ? ThemeMode.dark : ThemeMode.light},
              onSelectionChanged: (set) {
                context.read<ThemeController>().setThemeMode(set.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
