// lib/features/dashboard/presentation/dashboard_view.dart
import 'package:bhago/features/dashboard/presentation/pages/manage_actions_page.dart';
import 'package:bhago/features/dashboard/presentation/widgets/theme_toggle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/side_bar.dart';
import '../controller/actions_controller.dart';
import '../controller/dashboard_controller_.dart';
import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

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
    final actionsCtrl = context.watch<ActionsController>();
final selected     = actionsCtrl.selectedAction;
final content      = (selected.id == 'home') ? const _DashboardBody() : selected.page;
final appBarTitle  = selected.label;
    //final actionsCtrl = context.watch<ActionsController>();
    final useWide = _useWideLayout(context);
   // final selected = actionsCtrl.selectedAction;
   // final content = (selected.id == 'home') ? const _DashboardBody() : selected.page;
   // final appBarTitle = selected.label;

    // 💉 Provide DashboardController here (needs db + settings from upper DI)
    return ChangeNotifierProvider(
      create: (_) => DashboardController(
        db: context.read<AppDatabase>(),
        settings: context.read<SettingsProvider>(),
      ),
      child: Builder(
        builder: (context) {
          final appBar = AppBar(
            elevation: 0,
            automaticallyImplyLeading: !useWide,
            leading: useWide
                ? const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: _LogoBadge(label: 'WarehouseOS', size: 32),
                  )
                : null,
            leadingWidth: useWide ? 220 : null,
            title: Text(
              appBarTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w400),
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
                    // (badge can be wired to a db-backed notifications table later)
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12, left: 4),
                child: CircleAvatar(
                  radius: 16,
                  child: Text('AC', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              ThemeQuickToggle(),
            ],
          );

          if (useWide) {
            return Scaffold(
              floatingActionButton: const _HelpFab(),
              appBar: appBar,
              body: Row(
                children: [
                  buildSidebar(context),
                  const VerticalDivider(width: 1, thickness: 0.8),
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
                      child:  Padding(
                        padding: EdgeInsets.all(12.0),
                        child:content,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Scaffold(
              appBar: appBar,
              drawer: Drawer(child: _SideMenuMobile()),
              body: content,
              bottomNavigationBar: NavigationBar(
                selectedIndex: context.watch<ActionsController>().selectedFavoriteIndex,
                destinations: _buildNavigationDestinations(context),
                onDestinationSelected: (i) {
                  context.read<ActionsController>().setSelectedFavorite(i);
                },
              ),
            );
          }
        },
      ),
    );
  }

  List<NavigationDestination> _buildNavigationDestinations(BuildContext context) {
    final actionsCtrl = context.watch<ActionsController>();
    final favorites = actionsCtrl.favorites;

    return favorites.map((action) {
      return NavigationDestination(
        icon: Icon(action.icon),
        selectedIcon: Icon(action.icon),
        label: "",
      );
    }).toList();
  }
}

class _SideMenuMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actionsController = context.watch<ActionsController>();
    final items = actionsController.all;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  onTap: () {
                    Navigator.pop(context);
                    if (i != 0) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => it.page));
                    }
                  },
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

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.label, this.size = 32});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final appBarFg =
        Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _initials(label),
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appBarFg,
                ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'WO';
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final caps = RegExp(r'[A-Z]');
    final capChars = t.split('').where((c) => caps.hasMatch(c)).toList();
    if (capChars.length >= 2) return (capChars[0] + capChars[1]).toUpperCase();
    if (capChars.length == 1) return (t[0] + capChars[0]).toUpperCase();
    return t.substring(0, t.length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ===================================================================
// DASHBOARD CONTENT (Home) — now DB-backed
// ===================================================================
class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  String _comma(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromRight = s.length - i - 1;
      buf.write(s[i]);
      if (fromRight > 0 && fromRight % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<DashboardController>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Metrics (stream)
        StreamBuilder<DashboardMetrics>(
          stream: ctrl.watchMetrics(),
          builder: (context, snap) {
            final data = snap.data;
            final products = data?.products;
            final suppliers = data?.suppliers;
            final inToday = data?.stockInToday;
            final outToday = data?.stockOutToday;
            final low = data?.lowStockAlerts;
            
            final metrics = [
              _MetricData(
                title: 'Products',
                value: products == null ? '—' : _comma(products),
                icon: Icons.inventory_2_outlined,
                deltaText: null,
              ),
              _MetricData(
                title: 'Suppliers',
                value: suppliers == null ? '—' : _comma(suppliers),
                icon: Icons.groups_2_outlined,
                deltaText: null,
              ),
              _MetricData(
                title: 'Stock In Today',
                value: inToday == null ? '—' : _comma(inToday),
                subvalue: (outToday == null) ? null : 'Out: ${_comma(outToday)}',
                icon: Icons.trending_up,
                deltaText: null,
              ),
              _MetricData(
                title: 'Low-stock Alerts',
                value: low == null ? '—' : _comma(low),
                badge: (low == null || low == 0) ? null : 'Requires Attention',
                badgeColor: (low == null || low == 0) ? null : const Color(0xFFD92D20),
                icon: Icons.error_outline,
                deltaText: null,
              ),
            ];

            return _MetricsGrid(metrics: metrics);
          },
        ),
        const SizedBox(height: 16),

        const _ChartsRow(),
        const SizedBox(height: 16),

        // Recent activity (stream)
        StreamBuilder<List<RecentMoveVM>>(
          stream: ctrl.watchRecentMoves(limit: 6),
          builder: (context, snap) {
            final moves = snap.data ?? const [];
            return _RecentActivityCard(moves: moves, loading: !snap.hasData);
          },
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}

// Sidebar (unchanged styling)
//Sidebar shell with dark-mode friendly gradient and contrast.
 Widget buildSidebar(BuildContext context) { final theme = Theme.of(context); final scheme = theme.colorScheme; final isDark = theme.brightness == Brightness.dark; // Gently lift surfaces in dark mode so they’re not pitch black.
  Color lift(Color base, {double white = .08}) => isDark ? Color.alphaBlend(Colors.white.withOpacity(white), base) : base; final top = lift(scheme.surfaceVariant); final bottom = lift(scheme.surface, white: .06); // Pick text/icon color that actually contrasts with the blended bg.
   final midBg = Color.lerp(top, bottom, 0.5)!; final Brightness midBrightness = ThemeData.estimateBrightnessForColor(midBg); final Color fg = (midBrightness == Brightness.dark) ? Colors.white : const Color(0xFF111827); // near-black for light backgrounds 
   return Container( width: 220, decoration: BoxDecoration( gradient: LinearGradient( colors: [top, bottom], begin: Alignment.topCenter, end: Alignment.bottomCenter, ), border: Border( right: BorderSide(color: scheme.outlineVariant.withOpacity(isDark ? .3 : 1)), ), ), // Force tiles/icons/text to use the computed 'fg' 
   child: Theme( data: theme.copyWith( listTileTheme: ListTileThemeData( iconColor: fg, textColor: fg, selectedColor: scheme.primary, selectedTileColor: scheme.primary.withOpacity(isDark ? .16 : .10), ), iconTheme: IconThemeData(color: fg), textTheme: theme.textTheme.apply(bodyColor: fg, displayColor: fg), ), child: SideBar( width: 220, onOpenAll: () { Navigator.of(context).push( MaterialPageRoute(builder: (_) => const ManageActionsPage()), ); }, ), ), ); }
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
        childAspectRatio: 1.9,
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
                  if (data.badge != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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

// ----- CHARTS ROW (placeholder visuals kept) -----
class _ChartsRow extends StatelessWidget {
  const _ChartsRow();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1100;

    const left = _ChartCard(
      title: 'Stock Movement (30 days)',
      filterLabel: 'Last 30 days',
      legends: [
        _Legend(label: 'Stock In',  dotColor: Color(0xFF2E68FF)),
        _Legend(label: 'Stock Out', dotColor: Color(0xFFF04438)),
      ],
      placeholderTitle: 'Stock Movement Chart',
      placeholderSub: 'Area chart placeholder',
      placeholderIcon: Icons.trending_up,
    );

    const right = _ChartCard(
      title: 'Sales vs Purchase (MTD)',
      filterLabel: 'This Month',
      legends: [
        _Legend(label: 'Sales',    dotColor: Color(0xFF12B76A)),
        _Legend(label: 'Purchase', dotColor: Color(0xFFFD853A)),
      ],
      placeholderTitle: 'Sales vs Purchase Chart',
      placeholderSub: 'Bar chart placeholder',
      placeholderIcon: Icons.trending_up,
    );

    return isWide
        ? Row(children: const [Expanded(child: left), SizedBox(width: 16), Expanded(child: right)])
        : const Column(children: [left, SizedBox(height: 16), right]);
  }
}

class _Legend {
  final String label;
  final Color dotColor;
  const _Legend({required this.label, required this.dotColor});
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.filterLabel,
    required this.legends,
    required this.placeholderTitle,
    required this.placeholderSub,
    required this.placeholderIcon,
  });

  final String title;
  final String filterLabel;
  final List<_Legend> legends;
  final String placeholderTitle;
  final String placeholderSub;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SectionCard(
      header: _CardHeader(
        title: title,
        trailing: _FilterPill(label: filterLabel),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 7.0,
            child: _PlaceholderPanel(
              icon: placeholderIcon,
              title: placeholderTitle,
              subtitle: placeholderSub,
            ),
          ),
          if (legends.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 28,
              runSpacing: 8,
              children: legends
                  .map((e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LegendDot(color: e.dotColor),
                          const SizedBox(width: 8),
                          Text(e.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurface)),
                        ],
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.35),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: scheme.onSurfaceVariant.withOpacity(.6)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.moves, this.loading = false});
  final List<RecentMoveVM> moves;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      header: const _CardHeader(title: 'Recent Activity', trailing: null),
      child: Column(
        children: [
          if (loading && moves.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Loading...', style: Theme.of(context).textTheme.bodyMedium),
            ),
          if (!loading && moves.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No recent movements', style: Theme.of(context).textTheme.bodyMedium),
            ),
          for (final m in moves)
            _ActivityItem(
              kind: m.kind,
              title: m.productName,
              sku: m.sku,
              qty: m.qty,
              time: m.at == null ? '' : _ago(m.at!),
            ),
        ],
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} hours ago';
    return '${d.inDays} days ago';
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final grey = const Color(0xFFE5E7EB);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: grey, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: onPressed ?? () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 18),
          const SizedBox(width: 8),
          Text(label),
          const SizedBox(width: 2),
          const Icon(Icons.expand_more, size: 18),
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
                if (time.isNotEmpty)
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
    final isAdj = kind.toUpperCase() == 'ADJ';
    final bg = isIn ? const Color(0xFF101828) : isAdj ? const Color(0xFF475569) : const Color(0xFFF2F4F7);
    final fg = (isIn || isAdj) ? Colors.white : const Color(0xFF101828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(kind, style: TextStyle(color: fg, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
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

class _HelpFab extends StatelessWidget {
  const _HelpFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'helpFab',
      onPressed: () => _openMenu(context),
      shape: const CircleBorder(),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      child: const Icon(Icons.question_mark_rounded),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final pos = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu<String>(
      context: context,
      position: pos,
      color: const Color(0xFF111217),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      items: const [
        PopupMenuItem<String>(value: 'help', height: 44, child: Text('Help Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.1))),
        PopupMenuItem<String>(value: 'yt', height: 44, child: Text('YouTube videos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.1))),
        PopupMenuItem<String>(value: 'release', height: 44, child: Text('Release notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.1))),
        PopupMenuItem<String>(value: 'legal', height: 44, child: Text('Legal summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.1))),
        PopupMenuItem<String>(value: 'abuse', height: 44, child: Text('Report abuse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.1))),
        PopupMenuDivider(),
        PopupMenuItem<String>(value: 'lang', height: 44, child: Text('Change language...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.1))),
      ],
    );
  }
}
