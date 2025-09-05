import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/controller/reports_controller.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide ReportsController here (or at a higher level once)
    return ChangeNotifierProvider(
      create: (_) => ReportsController(
        db: context.read<AppDatabase>(),
        settings: context.read<SettingsProvider>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            controller: _tab,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Purchase Report'),
              Tab(text: 'Sales Report'),
              Tab(text: 'P&L'),
              Tab(text: 'GST Summary'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: const [
            _PurchaseReportTab(),
            _SalesReportTab(),
            _PlReportTab(),
            _GstSummaryTab(),
          ],
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          StreamBuilder<SummaryTotals>(
            stream: rc.watchPurchaseSummary(),
            builder: (context, snap) {
              final s = snap.data ?? const SummaryTotals(txCount: 0, amountMinor: 0, uniqueParties: 0);
              return Row(
                children: [
                  Expanded(child: _summaryCard('Total Payments (Out)', s.txCount.toString(), Icons.inventory_2_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _summaryCard('Total Amount', _inr(s.amountMinor), Icons.currency_rupee)),
                  const SizedBox(width: 16),
                  Expanded(child: _summaryCard('Suppliers', s.uniqueParties.toString(), Icons.people_outline)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Purchase by Supplier', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder(
              stream: rc.watchPurchaseBySupplier(),
              builder: (context, snap) {
                final rows = snap.data ?? const <PartyTotal>[];
                if (rows.isEmpty) {
                  return _empty('No purchase payments found in the selected period.');
                }
                return _bordered(
                  Column(
                    children: [
                      _tableHeader(const ['Supplier', 'Transactions', 'Amount', '% of Total'], const [3, 2, 2, 2]),
                      for (final r in rows) _partyRow(r, rows),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------------- SALES (real DB) ---------------------------- */
class _SalesReportTab extends StatelessWidget {
  const _SalesReportTab();

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<ReportsController>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<SummaryTotals>(
            stream: rc.watchSalesSummary(),
            builder: (context, snap) {
              final s = snap.data ?? const SummaryTotals(txCount: 0, amountMinor: 0, uniqueParties: 0);
              return Row(
                children: [
                  Expanded(child: _summaryCard('Total Payments (In)', s.txCount.toString(), Icons.receipt_long)),
                  const SizedBox(width: 16),
                  Expanded(child: _summaryCard('Total Amount', _inr(s.amountMinor), Icons.currency_rupee)),
                  const SizedBox(width: 16),
                  Expanded(child: _summaryCard('Customers', s.uniqueParties.toString(), Icons.people_outline)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Sales by Customer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder(
              stream: rc.watchSalesByCustomer(),
              builder: (context, snap) {
                final rows = snap.data ?? const <PartyTotal>[];
                if (rows.isEmpty) {
                  return _empty('No sales payments found in the selected period.');
                }
                return _bordered(
                  Column(
                    children: [
                      _tableHeader(const ['Customer', 'Transactions', 'Amount', '% of Total'], const [3, 2, 2, 2]),
                      for (final r in rows) _partyRow(r, rows),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ P&L (real) ------------------------------ */
class _PlReportTab extends StatelessWidget {
  const _PlReportTab();

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<ReportsController>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<PlTotals>(
        stream: rc.watchPl(),
        builder: (context, snap) {
          final p = snap.data ?? const PlTotals(revenueIn: 0, cogsOut: 0);
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _plCard('Revenue', _inr(p.revenueIn))),
                  const SizedBox(width: 16),
                  Expanded(child: _plCard('COGS', _inr(p.cogsOut))),
                  const SizedBox(width: 16),
                  Expanded(child: _plCard('Gross Profit', _inr(p.gross))),
                ],
              ),
              const SizedBox(height: 24),
              _bordered(SizedBox(
                height: 200,
                child: Center(
                  child: Text('Trend chart (optional) — add later'),
                ),
              )),
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
    // Needs invoice + line items to compute tax from product GST%.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _empty(
        'GST Summary needs invoices & line-items. '
        'Once those tables exist, we’ll compute CGST/SGST by product GST%.',
      ),
    );
  }
}

/* ------------------------------- helpers UI ------------------------------ */
Widget _summaryCard(String title, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          Icon(icon, color: Colors.grey.shade400),
        ]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _plCard(String title, String value) => _summaryCard(title, value, Icons.bar_chart_outlined);

String _inr(int minor) {
  // if your "amount_minor" are actually paise, divide by 100. For now treat as whole.
  final s = minor.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final fromRight = s.length - i - 1;
    buf.write(s[i]);
    if (fromRight > 0 && fromRight % 3 == 0) buf.write(',');
  }
  return '₹$buf';
}

Widget _bordered(Widget child) => Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey.shade300),
    borderRadius: BorderRadius.circular(8),
  ),
  child: child,
);

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

Widget _partyRow(PartyTotal r, List<PartyTotal> all) {
  final total = all.fold<int>(0, (s, x) => s + x.amountMinor);
  final pct = total == 0 ? 0 : (r.amountMinor * 100) / total;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
    child: Row(
      children: [
        Expanded(flex: 3, child: Text(r.partyName)),
        Expanded(flex: 2, child: Text(r.txCount.toString())),
        Expanded(flex: 2, child: Text(_inr(r.amountMinor))),
        Expanded(flex: 2, child: Text('${pct.toStringAsFixed(1)}%')),
      ],
    ),
  );
}

Widget _empty(String msg) => Container(
  height: 160,
  alignment: Alignment.center,
  child: Text(msg, style: TextStyle(color: Colors.grey.shade600)),
);
