import 'package:bhago/features/dashboard/controller/theme_controller.dart';
import 'package:bhago/features/dashboard/model/action_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ActionsController>();
    final useWide = _useWideLayout(context);

  final appBar = AppBar(
  elevation: 0,
  // If there is a Drawer (mobile), keep the hamburger in leading.
  automaticallyImplyLeading: !useWide,
  // Show the badge in leading on wide screens (dedicated width).
  leading: useWide
      ? const Padding(
          padding: EdgeInsets.only(left: 8),
          child: _LogoBadge(label: 'WarehouseOS'),
        )
      : null,
  leadingWidth: useWide ? 220 : null,

  // On mobile, put the badge in the title (it will ellipsis as needed).
  title: useWide
      ? null
      : const Padding(
          padding: EdgeInsets.only(left: 4),
          child: _LogoBadge(label: 'WarehouseOS'),
        ),
  titleSpacing: useWide ? 0 : 8,
  centerTitle: false,

  actions: [
  
    const SizedBox(width: 4),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          Positioned(
            right: 6,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ],
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(right: 12, left: 4),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        child: const Text('AC', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ),
  ],
);

    final selected = ctrl.selectedAction;
    final content = (selected.id == 'home') ? const _DashboardBody() : selected.page;

    if (useWide) {
      // Desktop/Landscape — Sidebar + content
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            // Sidebar
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
            // Main content
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
      // Mobile/Portrait
      return Scaffold(
        appBar: appBar,
        drawer: Drawer(child: _SideMenuMobile()),
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
            NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Reports'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
          onDestinationSelected: (i) {
            
            // keep dashboard content for now; wire other tabs to your ActionsController if needed
          },
        ),
      );
    }
  }

}

// ===================================================================
// Mobile drawer (simple list matching the mock)
// ===================================================================
class _SideMenuMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = const [
      _MenuItem(Icons.dashboard_customize_outlined, 'Dashboard'),
      _MenuItem(Icons.inventory_2_outlined, 'Products & Stock'),
      _MenuItem(Icons.shopping_cart_checkout_outlined, 'Purchase Orders'),
      _MenuItem(Icons.local_shipping_outlined, 'Sales/Dispatch'),
      _MenuItem(Icons.description_outlined, 'Quotations'),
      _MenuItem(Icons.groups_2_outlined, 'Party Management'),
      _MenuItem(Icons.account_balance_wallet_outlined, 'Credit/Payments'),
      _MenuItem(Icons.bar_chart_outlined, 'Reports'),
      _MenuItem(Icons.settings_outlined, 'Settings'),
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: _LogoBadge(label: 'WarehouseOS'),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final it = items[i];
                return ListTile(
                  leading: Icon(it.icon),
                  title: Text(it.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context),
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFD92D20)),
            title: const Text('Logout', style: TextStyle(color: Color(0xFFD92D20))),
            onTap: () {},
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem(this.icon, this.label);
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final appBarFg =
        Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min, // <-- critical
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'WO',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // No Flexible needed; text will ellipsis when constrained
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: appBarFg,
              ),
        ),
      ],
    );
  }
}

// ===================================================================
// Command palette (unchanged from your version)
// ===================================================================
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

    List<ActionItem> filtered = _all.where((a) {
      if (_q.isEmpty) return true;
      return a.label.toLowerCase().contains(_q) || a.id.toLowerCase().contains(_q);
    }).toList();

    filtered.sort((a, b) {
      if (a.id == 'home') return 1;
      if (b.id == 'home') return -1;
      if (_q.isEmpty) {
        final af = favIds.contains(a.id);
        final bf = favIds.contains(b.id);
        if (af != bf) return af ? -1 : 1;
      }
      return a.label.compareTo(b.label);
    });

    int crossAxisCount = 4;
    final w = MediaQuery.of(context).size.width;
    if (w < 380) crossAxisCount = 2;
    else if (w < 520) crossAxisCount = 3;

    return Scaffold(
      appBar: AppBar(title: const Text("Apps")),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
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
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
              if (_q.isEmpty && favIds.isNotEmpty) const SizedBox(height: 8),
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
                        setState(() {});
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

// ===================================================================
// DASHBOARD CONTENT (Home)
// ===================================================================
class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width >= 1200 ? 20.0 : 16.0;
    return ListView(
      padding: EdgeInsets.all(pad),
      children: const [
        _MetricsGrid(
          metrics: [
            _MetricData(title: 'Products', value: '1,248', deltaText: '+12%', icon: Icons.inventory_2_outlined, deltaPositive: true),
            _MetricData(title: 'Suppliers', value: '89', deltaText: '+3%', icon: Icons.groups_2_outlined, deltaPositive: true),
            _MetricData(title: 'Stock In Today', value: '156', subvalue: 'Out: 89', deltaText: '+8%', icon: Icons.trending_up, deltaPositive: true),
            _MetricData(title: 'Low-stock Alerts', value: '23', badge: 'Requires Attention', badgeColor: Color(0xFFD92D20), icon: Icons.error_outline),
          ],
        ),
        SizedBox(height: 16),
        _ChartsRow(),
        SizedBox(height: 16),
        _RecentActivityCard(),
        SizedBox(height: 12),
      ],
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String? subvalue;
  final String? deltaText;
  final bool deltaPositive;
  final String? badge;
  final Color? badgeColor;
  final IconData icon;
  const _MetricData({
    required this.title,
    required this.value,
    this.subvalue,
    this.deltaText,
    this.deltaPositive = true,
    this.badge,
    this.badgeColor,
    required this.icon,
  });
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});
  final List<_MetricData> metrics;

  int _cols(double w) {
    if (w >= 1400) return 4;
    if (w >= 1100) return 4;
    if (w >= 800) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = _cols(w);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.9, // tighter like the mock
      ),
      itemBuilder: (_, i) => _MetricCard(data: metrics[i]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(data.value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      if (data.subvalue != null) ...[
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(data.subvalue!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (data.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (data.badgeColor ?? Colors.red).withOpacity(.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (data.badgeColor ?? Colors.red).withOpacity(.25)),
                      ),
                      child: Text(
                        data.badge!,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: data.badgeColor ?? Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    )
                  else if (data.deltaText != null)
                    _DeltaText(text: data.deltaText!, positive: data.deltaPositive),
                ],
              ),
            ),
          ),
          _IconPill(icon: data.icon),
        ],
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  const _IconPill({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: scheme.onSurfaceVariant),
    );
  }
}

class _DeltaText extends StatelessWidget {
  const _DeltaText({required this.text, required this.positive});
  final String text;
  final bool positive;
  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xFF039855) : const Color(0xFFD92D20);
    return Row(
      children: [
        Icon(positive ? Icons.trending_up : Icons.trending_down, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ChartsRow extends StatelessWidget {
  const _ChartsRow();
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1100;
    final left = const _ChartCard(title: 'Stock Movement (30 days)', filterLabel: 'Last 30 days');
    final right = const _ChartCard(
      title: 'Sales vs Purchase (MTD)',
      filterLabel: 'This Month',
      legends: [
        _Legend(label: 'Sales', dotColor: Color(0xFF12B76A)),
        _Legend(label: 'Purchase', dotColor: Color(0xFFFD853A)),
      ],
    );
    return isWide
        ? Row(children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)])
        : Column(children: [left, const SizedBox(height: 16), right]);
  }
}

class _Legend {
  final String label;
  final Color dotColor;
  const _Legend({required this.label, required this.dotColor});
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.filterLabel, this.legends = const []});
  final String title;
  final String filterLabel;
  final List<_Legend> legends;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SectionCard(
      header: _CardHeader(
        title: title,
        trailing: OutlinedButton.icon(
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: Text(filterLabel),
          onPressed: () {},
        ),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 6.8,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.show_chart, size: 28, color: Colors.grey),
                    const SizedBox(height: 6),
                    Text(
                      title.contains('Sales') ? 'Sales vs Purchase Chart' : 'Stock Movement Chart',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      title.contains('Sales') ? 'Bar chart placeholder' : 'Area chart placeholder',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (legends.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 18,
              children: legends
                  .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                        _LegendDot(color: e.dotColor),
                        const SizedBox(width: 6),
                        Text(e.label),
                      ]))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      header: const _CardHeader(
        title: 'Recent Activity',
        trailing: null,
      ),
      child: Column(
        children: const [
          _ActivityItem(kind: 'IN', title: 'Wireless Headphones', sku: 'SKU-001', qty: 50, time: '2 hours ago'),
          _ActivityItem(kind: 'OUT', title: 'USB Cable', sku: 'SKU-045', qty: 25, time: '3 hours ago'),
          _ActivityItem(kind: 'IN', title: 'Laptop Stand', sku: 'SKU-012', qty: 20, time: '4 hours ago'),
          _ActivityItem(kind: 'OUT', title: 'Mouse Pad', sku: 'SKU-089', qty: 15, time: '5 hours ago'),
          _ActivityItem(kind: 'IN', title: 'Desk Lamp', sku: 'SKU-156', qty: 30, time: '6 hours ago'),
          _ActivityItem(kind: 'OUT', title: 'Phone Stand', sku: 'SKU-203', qty: 12, time: '7 hours ago'),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.kind,
    required this.title,
    required this.sku,
    required this.qty,
    required this.time,
  });

  final String kind;
  final String title;
  final String sku;
  final int qty;
  final String time;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _StatusPill(kind: kind),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text(sku, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Qty: $qty', style: Theme.of(context).textTheme.titleSmall),
                Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final isIn = kind.toUpperCase() == 'IN';
    final bg = isIn ? const Color(0xFF101828) : const Color(0xFFF2F4F7);
    final fg = isIn ? Colors.white : const Color(0xFF101828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(isIn ? 'IN' : 'OUT', style: TextStyle(color: fg, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.header, required this.child});
  final _CardHeader? header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(height: 12),
              // No divider to match your second mock
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}
