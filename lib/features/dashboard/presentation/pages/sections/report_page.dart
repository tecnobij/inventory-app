import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/controller/reports_controller.dart';
import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart'; // SegmentedTabs

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportsController(
        db: context.read<AppDatabase>(),
        settings: context.read<SettingsProvider>(),
      ),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
          
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: SegmentedTabs(
                tabs: const [
                  (Icons.inventory_2_outlined, 'Purchase Report'),
                  (Icons.receipt_long, 'Sales Report'),
                  (Icons.trending_up, 'P&L'),
                  (Icons.percent, 'GST Summary'),
                ],
              ),
            ),
          ),
          body: const SafeArea(
            child: TabBarView(
              children: [
                _PurchaseReportTab(),
                _SalesReportTab(),
                _PlReportTab(),
                _GstSummaryTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------- PURCHASES (real DB) -------------------------- */
class _PurchaseReportTab extends StatelessWidget {
  const _PurchaseReportTab();

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<ReportsController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 700;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<SummaryTotals>(
                stream: rc.watchPurchaseSummary(),
                builder: (context, snap) {
                  final s = snap.data ?? const SummaryTotals(txCount: 0, amountMinor: 0, uniqueParties: 0);
                  final items = [
                    SummaryItem('Total Payments (Out)', s.txCount.toString(), Icons.inventory_2_outlined),
                    SummaryItem('Total Amount', _inr(s.amountMinor), Icons.currency_rupee),
                    SummaryItem('Suppliers', s.uniqueParties.toString(), Icons.people_outline),
                  ];
                  return SummaryGrid(items: items);
                },
              ),
              const SizedBox(height: 24),
              _SectionTitle('Purchase by Supplier'),
              const SizedBox(height: 12),
              StreamBuilder<List<PartyTotal>>(
                stream: rc.watchPurchaseBySupplier(),
                builder: (context, snap) {
                  final rows = snap.data ?? const <PartyTotal>[];
                  if (rows.isEmpty) {
                    return _empty('No purchase payments found in the selected period.');
                  }
                  if (isMobile) {
                    return _PartyListMobile(rows: rows);
                  }
                  return _PartyTableDesktop(
                    titleCols: const ['Supplier', 'Transactions', 'Amount', '% of Total'],
                    flexes: const [3, 2, 2, 2],
                    rows: rows,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ---------------------------- SALES (real DB) ---------------------------- */
class _SalesReportTab extends StatelessWidget {
  const _SalesReportTab();

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<ReportsController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 700;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<SummaryTotals>(
                stream: rc.watchSalesSummary(),
                builder: (context, snap) {
                  final s = snap.data ?? const SummaryTotals(txCount: 0, amountMinor: 0, uniqueParties: 0);
                  final items = [
                    SummaryItem('Total Payments (In)', s.txCount.toString(), Icons.receipt_long),
                    SummaryItem('Total Amount', _inr(s.amountMinor), Icons.currency_rupee),
                    SummaryItem('Customers', s.uniqueParties.toString(), Icons.people_outline),
                  ];
                  return SummaryGrid(items: items);
                },
              ),
              const SizedBox(height: 24),
              _SectionTitle('Sales by Customer'),
              const SizedBox(height: 12),
              StreamBuilder<List<PartyTotal>>(
                stream: rc.watchSalesByCustomer(),
                builder: (context, snap) {
                  final rows = snap.data ?? const <PartyTotal>[];
                  if (rows.isEmpty) {
                    return _empty('No sales payments found in the selected period.');
                  }
                  if (isMobile) {
                    return _PartyListMobile(rows: rows);
                  }
                  return _PartyTableDesktop(
                    titleCols: const ['Customer', 'Transactions', 'Amount', '% of Total'],
                    flexes: const [3, 2, 2, 2],
                    rows: rows,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ------------------------------ P&L (real) ------------------------------ */
class _PlReportTab extends StatelessWidget {
  const _PlReportTab();

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<ReportsController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<PlTotals>(
        stream: rc.watchPl(),
        builder: (context, snap) {
          final p = snap.data ?? const PlTotals(revenueIn: 0, cogsOut: 0);
          final items = [
            SummaryItem('Revenue', _inr(p.revenueIn), Icons.trending_up),
            SummaryItem('COGS', _inr(p.cogsOut), Icons.shopping_bag_outlined),
            SummaryItem('Gross Profit', _inr(p.gross), Icons.ssid_chart_outlined),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SummaryGrid(items: items),
              const SizedBox(height: 24),
              _bordered(
                SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Trend chart (optional) — add later',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ---------------------------- GST (placeholder) ---------------------------- */
class _GstSummaryTab extends StatelessWidget {
  const _GstSummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _empty(
        'GST Summary needs invoices & line-items. Once those tables exist, we’ll compute CGST/SGST by product GST%.',
      ),
    );
  }
}

/* =============================== Responsive UI =============================== */

class SummaryItem {
  final String title;
  final String value;
  final IconData icon;
  SummaryItem(this.title, this.value, this.icon);
}

class SummaryGrid extends StatelessWidget {
  const SummaryGrid({super.key, required this.items});
  final List<SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // ~320px per card
      final cols = math.max(1, (c.maxWidth / 320).floor());
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 16 / 7,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _SummaryCard(item: items[i]),
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});
  final SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurfaceVar = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(item.title, style: TextStyle(color: onSurfaceVar))),
            Icon(item.icon, color: onSurfaceVar),
          ]),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    return Text(text, style: t);
  }
}

/* ------------------------- Desktop table vs Mobile list ------------------------- */

class _PartyTableDesktop extends StatelessWidget {
  const _PartyTableDesktop({
    required this.titleCols,
    required this.flexes,
    required this.rows,
  });

  final List<String> titleCols;
  final List<int> flexes;
  final List<PartyTotal> rows;

  @override
  Widget build(BuildContext context) {
    return _bordered(
      Column(
        children: [
          _tableHeader(titleCols, flexes),
          for (final r in rows) _partyRowDesktop(r, rows, flexes),
        ],
      ),
    );
  }
}

class _PartyListMobile extends StatelessWidget {
  const _PartyListMobile({required this.rows});
  final List<PartyTotal> rows;

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (s, x) => s + x.amountMinor);
    return Column(
      children: [
        for (final r in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.partyName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pill('Tx: ${r.txCount}'),
                    const SizedBox(width: 8),
                    _pill(_inr(r.amountMinor)),
                    const SizedBox(width: 8),
                    _pill('${_pct(r.amountMinor, total)}%'),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
}

/* --------------------------------- helpers UI -------------------------------- */

Widget _tableHeader(List<String> cols, List<int> flexes) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(children: [
        for (int i = 0; i < cols.length; i++)
          Expanded(flex: flexes[i], child: Text(cols[i], style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
    );

Widget _partyRowDesktop(PartyTotal r, List<PartyTotal> all, List<int> flexes) {
  final total = all.fold<int>(0, (s, x) => s + x.amountMinor);
  final pct = _pct(r.amountMinor, total);
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
    child: Row(
      children: [
        Expanded(flex: flexes[0], child: Text(r.partyName)),
        Expanded(flex: flexes[1], child: Text(r.txCount.toString())),
        Expanded(flex: flexes[2], child: Text(_inr(r.amountMinor))),
        Expanded(flex: flexes[3], child: Text('$pct%')),
      ],
    ),
  );
}

Widget _bordered(Widget child) => Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );

Widget _empty(String msg) => Container(
      height: 160,
      alignment: Alignment.center,
      child: Text(msg, style: TextStyle(color: Colors.grey.shade600)),
    );

/* --------------------------------- formatting -------------------------------- */

String _inr(int minor) {
  final s = minor.toString();
  if (s.length <= 3) return '₹$s';
  final head = s.substring(0, s.length - 3);
  final tail = s.substring(s.length - 3);
  final headWithCommas = RegExp(r'\B(?=(\d{2})+(?!\d))').hasMatch(head)
      ? head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},')
      : head;
  return '₹$headWithCommas,$tail';
}

String _pct(int part, int total) {
  if (total == 0) return '0.0';
  final v = (part * 100.0) / total;
  return v.toStringAsFixed(1);
}
