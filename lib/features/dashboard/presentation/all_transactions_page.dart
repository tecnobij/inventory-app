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
  DateTime? _from; // inclusive (UI only)
  DateTime? _to;   // exclusive (UI only)
  final _q = TextEditingController();

  // Suggestion field bits (no Tooltip anywhere)
  final _partyTextCtrl = TextEditingController();
  final _partyFocus = FocusNode();

  List<Party> _parties = const [];
  bool _loading = true;

  VoidCallback? _ctrlListener;

  @override
  void initState() {
    super.initState();
    _q.addListener(() => setState(() {}));
    _partyTextCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<SalesDispatchController>();
      void ensureBoot() {
        if (!mounted) return;
        if (ctrl.ready) {
          if (_ctrlListener != null) {
            ctrl.removeListener(_ctrlListener!);
            _ctrlListener = null;
          }
          _bootstrap();
          // debug helper
          // ignore: discarded_futures
          probeDates();
        }
      }

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
    _partyTextCtrl.dispose();
    _partyFocus.dispose();
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
      final customers = await ctrl.fetchCustomers();

      if (!mounted) return;
      setState(() {
        _parties = customers;
        _from = null;
        _to   = null;
        _loading = false;
      });

      // If an id was preselected (deep link), hydrate the text
      if (_partyId != null) {
        final p = _parties.firstWhere((e) => e.id == _partyId, orElse: () => _parties.first);
        _partyTextCtrl.text = p.name;
      }
    } catch (e, st) {
      debugPrint('BOOTSTRAP ERROR: $e\n$st');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
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
     
      // 🔒 Disable all Tooltips in this page to avoid the ticker error
      body: TooltipVisibility(
        visible: false,
        child: SafeArea(
          top: false,
          child: Padding(
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
                       from: _from,            // ✅ pass inclusive start
    to: _to,       // ✅ pass exclusive end
                      query: _q.text,
                    ),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Text('Ledger error: ${snap.error}', style: const TextStyle(color: Colors.red)),
                        );
                      }

                      final rows = snap.data ?? const <LedgerVM>[];
                      final totalSales = rows.where((e) => e.kind == LedgerKind.sale)
                          .fold<int>(0, (s, e) => s + e.amountMinor);
                      final paymentsIn = rows.where((e) => e.kind == LedgerKind.paymentIn)
                          .fold<int>(0, (s, e) => s + e.amountMinor);
                      final netDelta = totalSales - paymentsIn;

                      // Mobile: single scroll (prevents overflow)
                      if (isMobile) {
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: rows.length + 2,
                          itemBuilder: (_, i) {
                            if (i == 0) return _summaryRow(true, totalSales, paymentsIn, netDelta);
                            if (i == 1) return const SizedBox(height: 12);
                            final r = rows[i - 2];
                            return _tileMobile(r);
                          },
                        );
                      }

                      // Desktop/tablet
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _summaryRow(false, totalSales, paymentsIn, netDelta),
                          const SizedBox(height: 12),
                          Expanded(child: _listDesktop(rows)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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

    final partySuggest = _partySuggestField(_box('Customer'));

    final datePick = InkWell(
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
    );

    final resetBtn = SizedBox(
    
      child: OutlinedButton.icon(
        onPressed: _resetFilters,
        icon: const Icon(Icons.refresh),
        label: const Text('Reset'),
      ),
    );

    if (isMobile) {
      return Card(
        
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(width: double.infinity, child: partySuggest),
              SizedBox(width: double.infinity, child: datePick),
             Row(
              children: [
                 Align(alignment: Alignment.centerRight, child: resetBtn),
               TextButton(
            onPressed: () => setState(() { _from = null; _to = null; }),
            child: const Text('All time'),
          ),
              ],
             )
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: partySuggest),
        const SizedBox(width: 8),
        Expanded(child: datePick),
        const SizedBox(width: 8),
        resetBtn,
      ],
    );
  }

  // Autocomplete with suggestions (no bottom sheet, no Tooltip)
  Widget _partySuggestField(InputDecoration decoration) {
    return RawAutocomplete<Party>(
      textEditingController: _partyTextCtrl,
      focusNode: _partyFocus,
      displayStringForOption: (p) => p.name,
      optionsBuilder: (TextEditingValue te) {
        final q = te.text.trim().toLowerCase();
        if (q.isEmpty) return _parties;
        return _parties.where((p) => p.name.toLowerCase().contains(q));
      },
      onSelected: (Party p) {
        setState(() {
          _partyId = p.id;
          _partyTextCtrl.text = p.name;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          decoration: decoration.copyWith(
            suffixIcon: (_partyTextCtrl.text.isNotEmpty || _partyId != null)
                ? IconButton(
                    // intentionally no tooltip
                    onPressed: () {
                      setState(() {
                        _partyId = null;
                        _partyTextCtrl.clear();
                      });
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
          onChanged: (_) {
            // If user starts typing after selecting, clear the filter id
            if (_partyId != null) setState(() => _partyId = null);
          },
          onSubmitted: (_) {
            // If exact match exists, pick it
            final exact = _parties.firstWhere(
              (p) => p.name.toLowerCase() == _partyTextCtrl.text.trim().toLowerCase(),
              orElse: () => _parties.isNotEmpty ? _parties.first : Party(id: -1, orgId: 0, name: '', partyType: _parties as PartyType),
            );
            if (exact.id != -1) {
              setState(() {
                _partyId = exact.id;
                _partyTextCtrl.text = exact.name;
              });
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final opts = options.toList(growable: false);
        if (opts.isEmpty) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, minWidth: 280),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: opts.length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
                itemBuilder: (_, i) {
                  final p = opts[i];
                  return InkWell(
                    onTap: () => onSelected(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _resetFilters() {
    final now = DateTime.now();
    setState(() {
      _partyId = null;
      _partyTextCtrl.clear();
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

  /* ---------------------------- Desktop list ---------------------------- */

  Widget _listDesktop(List<LedgerVM> rows) {
    if (rows.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: Text('No transactions found for selected filters.', style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    final header = Container(
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
    );

    final table = Column(
      children: [
        header,
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

    return LayoutBuilder(
      builder: (context, cons) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 980),
            child: SizedBox(
              width: cons.maxWidth < 980 ? 980 : cons.maxWidth,
              child: table,
            ),
          ),
        );
      },
    );
  }

  /* ---------------------- Row renderers ---------------------- */

  Widget _rowDesktop(LedgerVM r) {
    final dt = r.dt?.toString().split('.').first ?? '-';
    final type = (r.kind == LedgerKind.sale) ? 'SALE' : 'PAYMENT';
    final refStr = (r.kind == LedgerKind.sale && r.soId != null)
        ? 'SO-${r.soId!.toString().padLeft(6, '0')}'
        : (r.paymentId != null ? 'PAY-${r.paymentId}' : '-');

    final refWidget = (r.soId != null)
        ? InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<SalesDispatchController>(),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: context.read<SalesDispatchController>(),
                      child: SalesOrderDetailsPage(soId: r.soId!),
                    ),
                  ),
                );
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