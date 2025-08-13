import 'package:bhago/features/dashboard/controller/actions_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SideBar extends StatelessWidget {
  final double width;
  final VoidCallback onOpenAll;
  const SideBar({super.key, required this.width, required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ActionsController>();
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Center(
              child: Text(
                'BhaGo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: ctrl.favorites.length,
              onReorder: ctrl.reorderFavorites,
              buildDefaultDragHandles: true,
              itemBuilder: (context, i) {
                final item = ctrl.favorites[i];
                final selected = i == ctrl.selectedFavoriteIndex; // <- fixed
                return ListTile(
                  key: ValueKey(item.id),
                  leading: Icon(item.icon),
                  selected: selected,
                  selectedTileColor: Theme.of(
                    context,
                  // ignore: deprecated_member_use
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  title: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => ctrl.setSelectedFavorite(i),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.tonalIcon(
              onPressed: onOpenAll,
              icon: const Icon(Icons.apps),
              label: const Text('All'),
            ),
          ),
        ],
      ),
    );
  }
}
