import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/features/dashboard/controller/sales_dispatch_controller.dart';

class SalesOrderDetailsPage extends StatelessWidget {
  const SalesOrderDetailsPage({super.key, required this.ctrl, required this.soId});
  final SalesDispatchController ctrl;
  final int soId;
  String _fmtDate(DateTime? d) =>
      d == null ? '-' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    
    return FutureBuilder<_SoDetail>(
      future: _load(),
      builder: (context, snap) {
        final d = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(d == null ? 'Sales Order' : 'Sales Order SO-${soId.toString().padLeft(6, "0")}'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: d == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: ${d.partyName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Date: ${_fmtDate(d.date ?? DateTime.now())}'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                              ),
                              child: Row(
                                children: const [
                                  Expanded(flex: 5, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 3, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('GST%', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 3, child: Text('Line Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            for (final it in d.items)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                                child: Row(
                                  children: [
                                    Expanded(flex: 5, child: Text(it.productName)),
                                    Expanded(flex: 2, child: Text(it.qty.toString())),
                                    Expanded(flex: 3, child: Text(_inr(it.unitPriceMinor))),
                                    Expanded(flex: 2, child: Text('${it.gstPct ?? 0}%')),
                                    Expanded(flex: 3, child: Text(_inr(it.lineTotalMinor))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: [
                          _totalChip('Subtotal', d.subtotalMinor),
                          _totalChip('Tax', d.taxMinor),
                          _totalChip('Total', d.totalMinor),
                        ],
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _totalChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(width: 8),
        Text(_inr(value), style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Future<_SoDetail> _load() async {
    // header
    final h = await ctrl.db.customSelect(
      '''
      SELECT so.so_date, so.subtotal_minor, so.tax_minor, so.total_minor, p.name AS party_name
      FROM sales_orders so
      JOIN parties p ON p.id = so.party_id
      WHERE so.id = ?
      ''',
      variables: [drift.Variable<int>(soId)],
      readsFrom: {ctrl.db.salesOrders, ctrl.db.parties},
    ).getSingle();

    // items
    final itemsRows = await ctrl.db.customSelect(
      '''
      SELECT si.qty, si.unit_price_minor, si.line_total_minor, pr.name AS product_name, pr.gst_percent
      FROM sales_order_items si
      JOIN products pr ON pr.id = si.product_id
      WHERE si.sales_order_id = ?
      ORDER BY si.id ASC
      ''',
      variables: [drift.Variable<int>(soId)],
      readsFrom: {ctrl.db.salesOrderItems, ctrl.db.products},
    ).get();

    final items = itemsRows.map((r) => _SoItem(
      productName: r.read<String>('product_name'),
      qty: r.read<int>('qty'),
      unitPriceMinor: r.read<int>('unit_price_minor'),
      lineTotalMinor: r.read<int>('line_total_minor'),
      gstPct: r.readNullable<int>('gst_percent'),
    )).toList();

    return _SoDetail(
      date: h.readNullable<DateTime>('so_date'),
      partyName: h.read<String>('party_name'),
      subtotalMinor: h.readNullable<int>('subtotal_minor') ?? 0,
      taxMinor: h.readNullable<int>('tax_minor') ?? 0,
      totalMinor: h.readNullable<int>('total_minor') ?? 0,
      items: items,
    );
  }
}
class _SoDetail {
  final DateTime? date;
  final String partyName;
  final int subtotalMinor;
  final int taxMinor;
  final int totalMinor;
  final List<_SoItem> items;
  _SoDetail({
    required this.date,
    required this.partyName,
    required this.subtotalMinor,
    required this.taxMinor,
    required this.totalMinor,
    required this.items,
  });
}
class _SoItem {
  final String productName;
  final int qty;
  final int unitPriceMinor;
  final int lineTotalMinor;
  final int? gstPct;
  _SoItem({
    required this.productName,
    required this.qty,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    required this.gstPct,
  });
}
String _inr(int n) {
  final s = n.toString();
  if (s.length <= 3) return '₹$s';
  final head = s.substring(0, s.length - 3);
  final tail = s.substring(s.length - 3);
  final headWithCommas = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
  return '₹$headWithCommas,$tail';
}
