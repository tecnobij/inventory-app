import 'package:bhago/features/dashboard/controller/actions_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SideBar extends StatelessWidget {
  final double width;
  final VoidCallback onOpenAll;
  const SideBar({super.key, required this.width, required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ctrl = context.watch<ActionsController>();

    return Container(
      width: width,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  Text(
                    'Favorites',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: 'Manage apps',
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.tune),
                      onPressed: onOpenAll,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                itemCount: ctrl.favorites.length,
                onReorder: ctrl.reorderFavorites,
                proxyDecorator: (child, _, __) =>
                    Opacity(opacity: 0.95, child: Transform.scale(scale: 1.02, child: child)),
                buildDefaultDragHandles: false,
                itemBuilder: (context, i) {
                  final item = ctrl.favorites[i];
                  final selected = i == ctrl.selectedFavoriteIndex;

                  // ⬇️ Colors that enforce black tile on dark theme
                  final Color tileBg = isDark
                      ? Colors.black // force pure black in dark
                      : (selected ? Colors.grey.shade300 : theme.colorScheme.surface);

                  final Color borderColor = isDark
                      ? Colors.white.withOpacity(selected ? .20 : .10)
                      : theme.dividerColor.withOpacity(.5);

                  final Color iconColor = isDark
                      ? Colors.white70
                      : theme.colorScheme.onSurfaceVariant;

                  final Color textColor = isDark
                      ? Colors.white
                      : theme.colorScheme.onSurface;

                  final Color iconPillBg = isDark
                      ? Colors.black // force black icon pill too
                      : theme.colorScheme.surfaceVariant.withOpacity(.6);

                  return Container(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => ctrl.setSelectedFavorite(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              // App icon in pill
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: iconPillBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isDark
                                      ? Border.all(color: Colors.white.withOpacity(.08))
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Icon(item.icon, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 10),
                              // Label
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textColor, // readable on black
                                  ),
                                ),
                              ),
                              // Drag handle
                              ReorderableDragStartListener(
                                index: i,
                                child: Icon(
                                  Icons.drag_indicator,
                                  color: isDark
                                      ? Colors.white54
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: FilledButton.tonalIcon(
                onPressed: onOpenAll,
                icon: const Icon(Icons.apps),
                label: const Text('All apps'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
