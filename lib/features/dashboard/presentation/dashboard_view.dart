import 'package:bhago/features/dashboard/model/action_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/actions_controller.dart';
import 'pages/manage_actions_page.dart';
import 'widgets/side_bar.dart';

// ...imports unchanged...

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  bool _useWideLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape || size.width >= 900;
  }

  static const int _quickCountPortrait = 4;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ActionsController>();
    final useWide = _useWideLayout(context);

    final appBar = AppBar(
      title: const Text('BhaGo — Warehouse Management'),
      actions: [
       PopupMenuButton<ThemeMode>(
  tooltip: 'Theme',
  icon: const Icon(Icons.person),
  onSelected: (mode) {
  ;
  },
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: ThemeMode.system,
      child: Text('Profile'),
    ),
    const PopupMenuItem(
      value: ThemeMode.light,
      child: Text('Setting'),
    ),
   
  ],
),

      ],
    );

    final selected = ctrl.selectedAction;
    final content = selected.page;

    if (useWide) {
      // Desktop/Landscape — Sidebar + content
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            SideBar(
              width: 220,
              onOpenAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageActionsPage()),
                );
              },
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    } else {
      // PORTRAIT — show ALL actions as small scrollable buttons on HOME only
      final favs = ctrl.favorites;
      final primary = favs.take(_quickCountPortrait).toList();

      // If selected page is Home, stack quick-actions strip over the Home content
      final body = (selected.id == 'home')
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _AllActionsScroller(
                  actions: ctrl.allActions.where((a) => a.id != 'home').toList(),
                  onTap: (a) {
                    final favIndex = favs.indexWhere((f) => f.id == a.id);
                    if (favIndex >= 0) {
                      // already a favorite → switch selection in bottom bar
                      ctrl.setSelectedFavorite(favIndex);
                    } else {
                      // not a favorite → open page without changing favorites
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => a.page),
                      );
                    }
                  },
                ),

                Expanded(child: content),
              ],
            )
          : content;

      return Scaffold(
        appBar: appBar,
        body: body,

        // Bottom bar shows ONLY 4 important favorites (unchanged logic)
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (int i = 0; i < primary.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => ctrl.setSelectedFavorite(i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                         Icon(primary[i].icon, color: primary[i].color), // 🎨
                          const SizedBox(height: 2),
                          Text(
                            primary[i].label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Apps launcher (kept)
              Expanded(
                child: InkWell(
                  onTap: () => _openLauncherBottomSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_view, color: Colors.teal,),
                        SizedBox(height: 2),
                        Text('Apps'),
                      ],
                    ),
                  ),
                ),
              ),

              // Manage (kept)
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageActionsPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune,color: Colors.deepPurple,),
                        SizedBox(height: 2),
                        Text('All'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _openLauncherBottomSheet(BuildContext context) {
    final ctrl = context.read<ActionsController>();
    final actions = ctrl.allActions;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'All Pages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Manage',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageActionsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  itemCount: actions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, i) {
                    final a = actions[i];
                    return OutlinedButton(
                      onPressed: () {
                        final existing = ctrl.favorites.indexWhere((f) => f.id == a.id);
                        if (existing >= 0) {
                          ctrl.setSelectedFavorite(existing);
                        } else {
                          // keep: add to favorites on demand via launcher
                          ctrl.addFavorite(a.id);
                          ctrl.setSelectedFavorite(ctrl.favorites.length - 1);
                        }
                        Navigator.of(context).pop();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.icon),
                          const SizedBox(height: 6),
                          Text(
                            a.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tiny horizontally-scrollable buttons for all actions (on Home only)
class _AllActionsScroller extends StatelessWidget {
  const _AllActionsScroller({
    required this.actions,
    required this.onTap,
  });

  final List<ActionItem> actions;
  final void Function(ActionItem) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // compact height
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (final a in actions) ...[
              _MiniActionButton(item: a, onTap: () => onTap(a)),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({required this.item, required this.onTap});
  final ActionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
  
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 22),
              const SizedBox(width: 6),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
