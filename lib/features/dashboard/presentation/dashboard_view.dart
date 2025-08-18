import 'package:bhago/features/dashboard/controller/theme_controller.dart';
import 'package:bhago/features/dashboard/model/action_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/actions_controller.dart';
import 'pages/manage_actions_page.dart';
import 'widgets/side_bar.dart';
import 'dart:ui' show ImageFilter;

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  static const int _quickCountPortrait = 4;

  bool _useWideLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape || size.width >= 900;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ActionsController>();
    final useWide = _useWideLayout(context);

    final appBar = AppBar(
      title: const Text(
        'BhaGo — Warehouse Management',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        PopupMenuButton<String>(
         icon: CircleAvatar(
    radius: 18, // Size of the circle
    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
    child: Icon(
      Icons.person,
      color: Theme.of(context).colorScheme.primary,
    ),
  ),
          onSelected: (value) async {
            if (value == 'logout') {
              final sp = await SharedPreferences.getInstance();
              await sp.clear();
            } else if (value == 'profile') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile page coming soon')),
              );
            } else if (value == 'settings') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings page coming soon')),
              );
            }
          },
          itemBuilder: (context) {
            final theme =
                Provider.of<ThemeController>(context, listen: false); // ✅ FIXED

            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    final followSystem = theme.followSystem;
                    final isDark = theme.themeMode == ThemeMode.dark;

                    return Row(
                      children: [
                        const Text('Theme',),
                        const Spacer(),
                        Switch.adaptive(
                          value: followSystem
                              ? MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark
                              : isDark,
                          onChanged: (on) {
                            theme.setFollowSystem(false);
                            theme.setThemeMode(
                                on ? ThemeMode.dark : ThemeMode.light);
                            setState(() {});
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ];
          },
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
      // Sidebar wrapped in a decorated container
      Container(
        width: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: SideBar(
          width: 220,
          onOpenAll: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageActionsPage()),
            );
          },
        ),
      ),
      const VerticalDivider(width: 1, thickness: 0.8),
      // Main content with subtle background
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.surface.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: content,
          ),
        ),
      ),
    ],
  ),
);

    } else {
      // Portrait mode
      final favs = ctrl.favorites;
      final primary = favs.take(_quickCountPortrait).toList();

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
                      ctrl.setSelectedFavorite(favIndex);
                    } else {
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
                          Icon(primary[i].icon, color: primary[i].color),
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
              Expanded(
                child: InkWell(
                  onTap: () => _openLauncherBottomSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_view, color: Colors.teal),
                        SizedBox(height: 2),
                        Text('Apps'),
                      ],
                    ),
                  ),
                ),
              ),
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
                        Icon(Icons.tune, color: Colors.deepPurple),
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

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      barrierDismissible: true,
      barrierLabel: 'Close', // ✅ FIXED
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, __, ___) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Opacity(
          opacity: curved.value,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 14 * curved.value, sigmaY: 14 * curved.value),
                child: const SizedBox.expand(),
              ),
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: 820, maxHeight: 620),
                    child: _CommandPalette(actionsCtrl: ctrl),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 240),
    );
  }
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette({required this.actionsCtrl});
  final ActionsController actionsCtrl;

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _queryCtrl = TextEditingController();
  late List<ActionItem> _all;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _all = widget.actionsCtrl.allActions;
    _queryCtrl.addListener(() {
      setState(() => _q = _queryCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favIds = widget.actionsCtrl.favorites.map((e) => e.id).toSet();

    // Filter actions by query; keep Home at the end if present
    List<ActionItem> filtered = _all.where((a) {
      if (_q.isEmpty) return true;
      return a.label.toLowerCase().contains(_q) || a.id.toLowerCase().contains(_q);
    }).toList();

    // Move 'home' to end (optional)
    filtered.sort((a, b) {
      if (a.id == 'home') return 1;
      if (b.id == 'home') return -1;
      // Prefer favorites first when no query
      if (_q.isEmpty) {
        final af = favIds.contains(a.id);
        final bf = favIds.contains(b.id);
        if (af != bf) return af ? -1 : 1;
      }
      return a.label.compareTo(b.label);
    });

    // Responsive column count
    int crossAxisCount = 4;
    final w = MediaQuery.of(context).size.width;
    if (w < 380) crossAxisCount = 2;
    else if (w < 520) crossAxisCount = 3;

    return Scaffold(
      appBar: AppBar(
        title: Text("Apps"),
      ),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // Header: search + manage
              // Row(
              //   children: [
                  
              //     const SizedBox(width: 8),
              //     Tooltip(
              //       message: 'Manage',
              //       child: IconButton(
              //         icon: const Icon(Icons.tune),
              //         onPressed: () {
              //           Navigator.of(context).pop();
              //           Navigator.of(context).push(MaterialPageRoute(
              //             builder: (_) => const ManageActionsPage(),
              //           ));
              //         },
              //       ),
              //     ),
              //     const SizedBox(width: 4),
              //     Tooltip(
              //       message: 'Close',
              //       child: IconButton(
              //         icon: const Icon(Icons.close),
              //         onPressed: () => Navigator.of(context).pop(),
              //       ),
              //     ),
              //   ],
              // ),
      
              const SizedBox(height: 12),
      
              // Favorites row (chips), only when no query
              if (_q.isEmpty && favIds.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.actionsCtrl.favorites.map((a) {
                      return InputChip(
                        avatar: Icon(a.icon, color: a.color, size: 18),
                        label: Text(a.label),
                        onPressed: () => _openAction(a),
                        onDeleted: () {
                          widget.actionsCtrl.removeFavorite(a.id);
                          setState(() {}); // refresh favorite chips
                        },
                      );
                    }).toList(),
                  ),
                ),
      
              if (_q.isEmpty && favIds.isNotEmpty) const SizedBox(height: 8),
      
              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, i) {
                    final a = filtered[i];
                    final isFav = favIds.contains(a.id);
                    return _AppTile(
                      item: a,
                      isFavorite: isFav,
                      onOpen: () => _openAction(a),
                      onToggleFavorite: () {
                        if (isFav) {
                          widget.actionsCtrl.removeFavorite(a.id);
                        } else {
                          widget.actionsCtrl.addFavorite(a.id);
                        }
                        setState(() {}); // refresh star badge
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAction(ActionItem a) {
    // If it's already a favorite, switch selection, else just push
    final favIndex = widget.actionsCtrl.favorites.indexWhere((f) => f.id == a.id);
    Navigator.of(context).pop();
    if (favIndex >= 0) {
      widget.actionsCtrl.setSelectedFavorite(favIndex);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => a.page));
    }
  }
}
class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.item,
    required this.isFavorite,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final ActionItem item;
  final bool isFavorite;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = item.color.withOpacity(0.10);
    final border = item.color.withOpacity(0.30);

    return InkWell(
      onTap: onOpen,
      onLongPress: onToggleFavorite,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            // Icon + label
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: item.color, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Star toggle (top-right)
            Positioned(
              right: 0,
              top: 0,
              child: IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.amber : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
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
  const _MiniActionButton({
    required this.item,
    required this.onTap,
  });

  final ActionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        height: 42,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: item.color.withOpacity(0.15),
          highlightColor: item.color.withOpacity(0.1),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.color.withOpacity(0.12),
                  item.color.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.color.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: item.color.withOpacity(0.15),
                  child: Icon(item.icon, size: 16, color: item.color),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
