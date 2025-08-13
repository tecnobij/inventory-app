import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/actions_controller.dart';
import 'pages/manage_actions_page.dart';
import 'widgets/side_bar.dart';

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
        IconButton(
          tooltip: 'Theme',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Theme toggle coming soon')),
            );
          },
          icon: const Icon(Icons.brightness_6_outlined),
        ),
      ],
    );

    final content = ctrl.selectedAction.page;

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
      // Portrait — Quick actions + Launcher + Manage
      final favs = ctrl.favorites;
      final primary = favs.take(_quickCountPortrait).toList();

      return Scaffold(
        appBar: appBar,
        body: content,
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
                          Icon(primary[i].icon),
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
              // Launcher (show all pages in a bottom sheet grid)
              Expanded(
                child: InkWell(
                  onTap: () => _openLauncherBottomSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_view),
                        SizedBox(height: 2),
                        Text('Apps'),
                      ],
                    ),
                  ),
                ),
              ),
              // Manage (open ManageActionsPage)
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
                        Icon(Icons.tune),
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
    final actions = ctrl.allActions; // make sure your controller exposes this

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
                        // 1) If already a favorite, just select it
                        final existing = ctrl.favorites.indexWhere(
                          (f) => f.id == a.id,
                        );
                        if (existing >= 0) {
                          ctrl.setSelectedFavorite(existing);
                        } else {
                          // 2) Otherwise add to favorites and select it
                          ctrl.addFavorite(a.id);
                          ctrl.setSelectedFavorite(ctrl.favorites.length - 1);
                          // (Optional) enforce a max favorites count here if you want
                        }
                        Navigator.of(
                          context,
                        ).pop(); // close the sheet, keep bottom bar
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
