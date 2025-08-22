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
    final ctrl = context.watch<ActionsController>();

    return Container(
      width: width,
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: logo + product name
        //    const _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  Text('Favorites',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      )),
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
            const SizedBox(height: 15),
            // Draggable favorites
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                itemCount: ctrl.favorites.length,
                onReorder: ctrl.reorderFavorites,
                proxyDecorator: (child, _, __) => Opacity(
                  opacity: 0.9,
                  child: Transform.scale(scale: 1.02, child: child),
                ),
                buildDefaultDragHandles: false,
                itemBuilder: (context, i) {
                  final item = ctrl.favorites[i];
                  final selected = i == ctrl.selectedFavoriteIndex;

                  final bg = selected
                      ? Colors.grey.shade300
                      : theme.colorScheme.surface;
                

                  return Container(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                     // border: Border.all(color: borderColor),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => ctrl.setSelectedFavorite(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Row(
                            children: [
                              // App icon in soft pill
                              Container(
                                width: 32,
                               // height: 32,
                                decoration: BoxDecoration(
                                
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Icon(item.icon, ),
                              ),
                              const SizedBox(width: 10),
                              // Label
                              Expanded(
                                child: Text(
                                  
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:TextStyle(fontSize:13,fontWeight: FontWeight.bold )
                                ),
                              ),
                              // Drag handle
                              ReorderableDragStartListener(
                                index: i,
                                child: Icon(Icons.drag_indicator,
                                    color: theme.colorScheme.onSurfaceVariant),
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

