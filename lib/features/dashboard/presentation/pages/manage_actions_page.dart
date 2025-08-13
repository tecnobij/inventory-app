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
      appBar: AppBar(title: const Text('Manage Actions')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Favorites (drag to reorder)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _FavoritesEditor(),
          const SizedBox(height: 16),
          Text('All Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: all.map((a) {
              final isFav = favIds.contains(a.id);
              return FilterChip(
                label: Text(a.label),
                selected: isFav,
                avatar: Icon(a.icon, size: 18),
                onSelected: (sel) {
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
    );
  }
}

class _FavoritesEditor extends StatelessWidget {
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
        onReorder: ctrl.reorderFavorites,
        itemBuilder: (context, index) {
          final a = ctrl.favorites[index];
          return ListTile(
            key: ValueKey(a.id),
            leading: const Icon(Icons.drag_handle),
            title: Text(a.label),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => ctrl.removeFavorite(a.id),
            ),
          );
        },
      ),
    );
  }
}
