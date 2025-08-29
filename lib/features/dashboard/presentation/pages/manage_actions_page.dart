// manage_actions_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/actions_controller.dart';

class ManageActionsPage extends StatelessWidget {
  const ManageActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ActionsController>();
    final favIds = ctrl.favorites.map((e) => e.id).toSet();
    final all = ctrl.allActions;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('Favorites (drag to reorder)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _FavoritesEditor(),
            const SizedBox(height: 16),
            Text('All Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: all.map((a) {
                final isFav = favIds.contains(a.id);
                final isPinned = ctrl.isPinned(a.id);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.label),
                      if (isPinned) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.lock_outline, size: 16),
                      ],
                    ],
                  ),
                  avatar: Icon(a.icon, size: 18),
                  selected: isFav,
                  // 🔒 disable toggling for pinned items
                  onSelected: isPinned
                      ? null
                      : (sel) {
                          if (sel) {
                            ctrl.addFavorite(a.id);
                          } else {
                            ctrl.removeFavorite(a.id);
                          }
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesEditor extends StatelessWidget {
  const _FavoritesEditor();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ActionsController>();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(4),
        itemCount: ctrl.favorites.length,
        onReorder: ctrl.reorderFavorites, // reordering still allowed
        itemBuilder: (context, index) {
          final a = ctrl.favorites[index];
          final isPinned = ctrl.isPinned(a.id);
          return ListTile(
            key: ValueKey(a.id),
            leading: const Icon(Icons.drag_handle),
            title: Text(a.label),
            // 🔒 hide remove button for pinned, show lock instead
            trailing: isPinned
                ? const Icon(Icons.lock_outline, color: Colors.grey)
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => ctrl.removeFavorite(a.id),
                  ),
          );
        },
      ),
    );
  }
}
