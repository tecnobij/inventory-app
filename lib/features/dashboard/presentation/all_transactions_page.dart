// lib/features/dashboard/presentation/pages/sections/sale/all_transactions_page.dart
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/sales_dispatch_controller.dart';
import 'package:bhago/features/dashboard/presentation/pages/sections/sale/so_details_page.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});
  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  int? _partyId;
  DateTime? _from;               // inclusive
  DateTime? _to;                 // exclusive
  final _q = TextEditingController();

  List<Party> _parties = const [];
  bool _loading = true;

  VoidCallback? _ctrlListener;   // listen for ctrl.ready transition

  @override
  void initState() {
    super.initState();
    _q.addListener(() => setState(() {}));

    // Defer grabbing provider until a frame exists, then attach a listener.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<SalesDispatchController>();
      void ensureBoot() {
        if (!mounted) return;
        if (ctrl.ready) {
          // Run once, then remove the listener
          if (_ctrlListener != null) {
            ctrl.removeListener(_ctrlListener!);
            _ctrlListener = null;
          }
          _bootstrap();
          probeDates();
        }
      }

      // If already ready, boot now; else attach a listener
      if (ctrl.ready) {
        _bootstrap();
      } else {
        _ctrlListener = ensureBoot;
        ctrl.addListener(_ctrlListener!);
      }
    });
  }

  @override
  void dispose() {
    final ctrl = context.read<SalesDispatchController>();
    if (_ctrlListener != null) {
      ctrl.removeListener(_ctrlListener!);
      _ctrlListener = null;
    }
    _q.dispose();
    super.dispose();
  }
Future<void> probeDates() async {
  final ctrl = context.read<SalesDispatchController>();
  final rows = await ctrl.db.customSelect(
    '''
    SELECT 'SO' AS t, id, typeof(COALESCE(so_date, created_at)) ty, COALESCE(so_date, created_at) v
    FROM sales_orders WHERE org_id=? ORDER BY COALESCE(so_date, created_at) DESC LIMIT 5
    UNION ALL
    SELECT 'PAY', id, typeof(COALESCE(paid_at, created_at)) ty, COALESCE(paid_at, created_at) v
    FROM payments WHERE org_id=? AND direction=0 ORDER BY COALESCE(paid_at, created_at) DESC LIMIT 5
    ''',
    variables: [drift.Variable<int>(ctrl.orgId), drift.Variable<int>(ctrl.orgId)],
  ).get();

  for (final r in rows) {
    debugPrint('PROBE ${r.read<String>("t")} id=${r.read<int>("id")} type=${r.read<String>("ty")} val=${r.read<Object>("v")}');
  }
}


  Future<void> _bootstrap() async {
    try {
      final ctrl = context.read<SalesDispatchController>();

      // Default current month
  
  

      final customers = await ctrl.fetchCustomers();

      if (!mounted) return;
    setState(() {
  _parties = customers;
  _from = null; // not used anymore
  _to   = null; // not used anymore
  _loading = false;
});


      // Optional sanity logs
      final so = await ctrl.db.customSelect(
        'SELECT COUNT(*) AS c FROM sales_orders WHERE org_id = ?',
        variables: [drift.Variable<int>(ctrl.orgId)],
      ).getSingle();
      final pin = await ctrl.db.customSelect(
        'SELECT COUNT(*) AS c FROM payments WHERE org_id = ? AND direction = 0',
        variables: [drift.Variable<int>(ctrl.orgId)],
      ).getSingle();
      final pr = await ctrl.db.customSelect(
        'SELECT COUNT(*) AS c FROM parties WHERE org_id = ?',
        variables: [drift.Variable<int>(ctrl.orgId)],
      ).getSingle();
      debugPrint('DBG => SO count: ${so.read<int>("c")}, PAYIN: ${pin.read<int>("c")}, Parties: ${pr.read<int>("c")}');
      debugPrint('DBG => Using range from=$_from to=$_to (exclusive)');
//final ctrl = context.read<SalesDispatchController>();
final test = await ctrl.db.customSelect('''
  SELECT COUNT(*) AS c FROM (
    SELECT so.id FROM sales_orders so WHERE so.org_id = ?
    UNION ALL
    SELECT pay.id FROM payments pay WHERE pay.org_id = ? AND pay.direction = 0
  )
''', variables: [drift.Variable<int>(ctrl.orgId), drift.Variable<int>(ctrl.orgId)]).getSingle();
debugPrint('LEDGER total rows (SO + PAYIN) = ${test.read<int>("c")}');

    } catch (e, st) {
      // Never leave spinner stuck if something fails
      debugPrint('BOOTSTRAP ERROR: $e\n$st');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();

    // If controller not ready, show a clear message (not a spinner).
    if (!ctrl.ready) {
      return const Scaffold(
        body: Center(child: Text('Finish onboarding to view transactions.')),
      );
    }
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Quick: All-time button to test if date filters were the issue
          TextButton(
            onPressed: () => setState(() { _from = null; _to = null; }),
            child: const Text('All time'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _filters(isMobile),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<List<LedgerVM>>(
                stream: ctrl.watchLedger(
                  partyId: _partyId,
               
                  query: _q.text,
                ),
                builder: (context, snap) {
                  print("Ledger error:${snap.error}");
                   if (snap.hasError) {
    return Center(
      child: Text(
        'Ledger error: ${snap.error}',
        
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

                  final rows = snap.data ?? const <LedgerVM>[];
                  final totalSales = rows.where((e) => e.kind == LedgerKind.sale)
                      .fold<int>(0, (s, e) => s + e.amountMinor);
                  final paymentsIn = rows.where((e) => e.kind == LedgerKind.paymentIn)
                      .fold<int>(0, (s, e) => s + e.amountMinor);
                  final netDelta = totalSales - paymentsIn;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _summaryRow(isMobile, totalSales, paymentsIn, netDelta),
                      const SizedBox(height: 12),
                      Expanded(child: _list(rows, isMobile)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* -------------------------- Filters -------------------------- */

  Widget _filters(bool isMobile) {
    InputDecoration _box(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );

    final left = [
      Expanded(
        child: DropdownButtonFormField<int?>(
          value: _partyId,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('All customers')),
            ..._parties.map((p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.name))),
          ],
          onChanged: (v) => setState(() => _partyId = v),
          decoration: _box('Customer'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final now = DateTime.now();
            final initFrom = _from ?? DateTime(now.year, now.month, 1);
            final initTo = (_to ?? DateTime(now.year, now.month + 1, 1)).subtract(const Duration(days: 1));
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
              initialDateRange: DateTimeRange(start: initFrom, end: initTo),
            );
            if (picked != null) {
              setState(() {
                _from = DateTime(picked.start.year, picked.start.month, picked.start.day);
                _to   = DateTime(picked.end.year, picked.end.month, picked.end.day + 1); // exclusive
              });
            }
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Text(
              (_from == null || _to == null)
                ? 'Pick date range'
                : '${_yyyyMmDd(_from!)} → ${_yyyyMmDd(_to!.subtract(const Duration(days: 1)))}',
            ),
          ),
        ),
      ),
    ];

    final right = [
      Expanded(
        child: TextField(
          controller: _q,
          textInputAction: TextInputAction.search,
          decoration: _box('Search (party / SO#)'),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(children: [Expanded(child: left[0]), const SizedBox(width: 8), Expanded(child: left[2])]),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: right[0]), const SizedBox(width: 8), right[2]]),
        ],
      );
    }
    return Row(children: [...left, const SizedBox(width: 12), ...right]);
  }

  void _resetFilters() {
    final now = DateTime.now();
    setState(() {
      _partyId = null;
      _q.clear();
      _from = DateTime(now.year, now.month, 1);
      _to   = DateTime(now.year, now.month + 1, 1);
    });
  }

  /* ----------------------- Summary ----------------------- */

  Widget _summaryRow(bool isMobile, int totalSales, int paymentsIn, int netDelta) {
    Widget card(String label, String value, IconData ic) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(ic, color: Colors.grey.shade500),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
      );
    }

    final a = Expanded(child: card('Total Sales', _inr(totalSales), Icons.shopping_bag_outlined));
    final b = Expanded(child: card('Payments In', _inr(paymentsIn), Icons.payments_outlined));
    final c = Expanded(child: card('Net (Sales - Payments)', _inr(netDelta), Icons.calculate_outlined));

    return isMobile
        ? Column(children: [
            Row(children: [a]), const SizedBox(height: 8),
            Row(children: [b]), const SizedBox(height: 8),
            Row(children: [c]),
          ])
        : Row(children: [a, const SizedBox(width: 12), b, const SizedBox(width: 12), c]);
  }

  /* ---------------------------- List ---------------------------- */

  Widget _list(List<LedgerVM> rows, bool isMobile) {
    if (rows.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: Text('No transactions found for selected filters.', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    if (isMobile) {
      return ListView.builder(
        itemCount: rows.length,
        itemBuilder: (_, i) => _tileMobile(rows[i]),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(children: const [
            Expanded(flex: 2, child: Text('Date/Time', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text('Party', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('Ref', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('Method/Note', style: TextStyle(fontWeight: FontWeight.bold))),
          ]),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
            ),
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) => _rowDesktop(rows[i]),
            ),
          ),
        ),
      ],
    );
  }

  /* ---------------------- Row renderers ---------------------- */

  Widget _rowDesktop(LedgerVM r) {
    final ctrl = context.read<SalesDispatchController>();
    final dt = r.dt?.toString().split('.').first ?? '-';
    final type = (r.kind == LedgerKind.sale) ? 'SALE' : 'PAYMENT';
    final refStr = (r.kind == LedgerKind.sale && r.soId != null)
        ? 'SO-${r.soId!.toString().padLeft(6, '0')}'
        : (r.paymentId != null ? 'PAY-${r.paymentId}' : '-');

    final refWidget = ( r.soId != null)
        ? InkWell(
            onTap: () {
              // Navigator.of(context).push(MaterialPageRoute(
              //   builder: (_) => Provider<SalesDispatchController>.value(
              //     value: ctrl,
              //     child: SalesOrderDetailsPage(soId: ),
              //   ),
              // ));
               Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<SalesDispatchController>(),    // reuse existing instance
      child: SalesOrderDetailsPage(soId: r.soId!),
    ),
  ),
);
            },
            child: const Text('Open', style: TextStyle(decoration: TextDecoration.underline)),
          )
        : Text(refStr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(children: [
        Expanded(flex: 2, child: Text(dt)),
        Expanded(flex: 2, child: Text(type)),
        Expanded(flex: 3, child: Text(r.party)),
        Expanded(flex: 2, child: refWidget),
        Expanded(flex: 2, child: Text(_inr(r.amountMinor))),
        Expanded(flex: 2, child: Text(
          (r.kind == LedgerKind.paymentIn)
              ? ((r.method?.isNotEmpty ?? false) ? r.method! : (r.note ?? '-'))
              : '-',
        )),
      ]),
    );
  }

  Widget _tileMobile(LedgerVM r) {
    final ctrl = context.read<SalesDispatchController>();
    final dt = r.dt?.toString().split('.').first ?? '-';
    final isSale = r.kind == LedgerKind.sale;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSale ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isSale ? Colors.blue.shade200 : Colors.green.shade200),
      ),
      child: Text(isSale ? 'SALE' : 'PAYMENT',
          style: TextStyle(fontSize: 11, color: isSale ? Colors.blue.shade700 : Colors.green.shade700)),
    );
    final ref = isSale && r.soId != null ? 'SO-${r.soId!.toString().padLeft(6, '0')}'
                                         : (r.paymentId != null ? 'PAY-${r.paymentId}' : '-');

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: (isSale && r.soId != null)
            ? () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Provider<SalesDispatchController>.value(
                    value: ctrl,
                    child: SalesOrderDetailsPage(soId: r.soId!),
                  ),
                ));
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              badge,
              const Spacer(),
              Text(_inr(r.amountMinor), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text(r.party, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(dt, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
              const SizedBox(width: 8),
              Text(ref, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ]),
            if (!isSale)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  (r.method?.isNotEmpty ?? false) ? 'Method: ${r.method}' : (r.note ?? '-'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  /* ------------------------------- Utils ------------------------------- */

  String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _inr(int n) {
    final s = n.toString();
    if (s.length <= 3) return '₹$s';
    final head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final headWithCommas =
        head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
    return '₹$headWithCommas,$tail';
  }
}
