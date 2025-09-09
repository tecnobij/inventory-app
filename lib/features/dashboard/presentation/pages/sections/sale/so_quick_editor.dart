// lib/features/sales/widgets/so_quick_editor.dart
import 'package:bhago/features/dashboard/presentation/pages/sections/sale/add_customer_button.dart';
import 'package:drift/src/runtime/query_builder/query_builder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart';

class SoQuickEditor extends StatefulWidget {
  const SoQuickEditor({super.key});
  @override
  State<SoQuickEditor> createState() => _SoQuickEditorState();
}

class _SoQuickEditorState extends State<SoQuickEditor> {
  late AppDatabase db;
  List<Product> _products = [];              // ← Product (singular), not ProductsData
  final List<_Line> _lines = [ _Line() ];
  int subtotal = 0; // money_minor
  int tax = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    db = context.read<AppDatabase>();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final ps = await (db.select(db.products)
          ..where((t) => Expression.or(t.isActive.isNull() as Iterable<Expression<bool>>)))
        .get();                               // returns List<Product>
    setState(() => _products = ps);
    _recalc();
  }

  void _recalc() {
    int sub = 0, tx = 0;
    for (final l in _lines) {
      final qty = int.tryParse(l.qty.text) ?? 0;
      final rate = int.tryParse(l.rate.text) ?? 0; // assuming minor units already
      final line = qty * rate;
      final gstPct = _gstPct(l.productId);
      final gstAmt = ((line * gstPct) / 100).round();
      sub += line;
      tx  += gstAmt;
    }
    setState(() {
      subtotal = sub;
      tax = tx;
      total = sub + tx;
    });
  }

  int _gstPct(int? productId) {
    if (productId == null) return 0;
    final idx = _products.indexWhere((x) => x.id == productId);
    if (idx == -1) return 0;
    return _products[idx].gstPercent ?? 0;
  }

  @override
  void dispose() {
    for (final l in _lines) { l.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final addLineBtn = OutlinedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Add line'),
      onPressed: () => setState(() => _lines.add(_Line())),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with Add Customer
        Row(
          children: [
            const AddCustomerButton(),
            const Spacer(),
            addLineBtn,
          ],
        ),
        const SizedBox(height: 12),

        // Lines
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _editorHeader(context),
              const Divider(height: 1),
              for (int i = 0; i < _lines.length; i++) _lineRow(context, i),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _totalsCard(subtotal, tax, total),
        ),
      ],
    );
  }

  Widget _editorHeader(BuildContext ctx) {
    final grey = Theme.of(ctx).colorScheme.onSurfaceVariant;
    Widget h(String s, int f) => Expanded(flex: f, child: Text(s, style: TextStyle(color: grey, fontWeight: FontWeight.w700)));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          h('Product', 4),
          h('Qty',     2),
          h('Rate',    3),
          h('GST %',   2),
          h('Line Amt',3),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _lineRow(BuildContext ctx, int i) {
    final l = _lines[i];
    final gst = _gstPct(l.productId);
    final qty = int.tryParse(l.qty.text) ?? 0;
    final rate = int.tryParse(l.rate.text) ?? 0;
    final line = qty * rate;

    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint, isDense: true, filled: true,
      fillColor: Theme.of(ctx).colorScheme.surfaceVariant.withOpacity(.45),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Product
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<int>(
              value: l.productId,
              items: _products.map((p) => DropdownMenuItem<int>(
                value: p.id,
                child: Text(p.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) { setState(() { l.productId = v; }); _recalc(); },
              decoration: deco('Select product'),
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
          const SizedBox(width: 8),

          // Qty
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: l.qty,
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalc(),
              decoration: deco('0'),
            ),
          ),
          const SizedBox(width: 8),

          // Rate (minor)
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: l.rate,
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalc(),
              decoration: deco('0'),
            ),
          ),
          const SizedBox(width: 8),

          // GST% (read-only from product)
          Expanded(
            flex: 2,
            child: TextFormField(
              readOnly: true,
              decoration: deco('$gst'),
            ),
          ),
          const SizedBox(width: 8),

          // Line amount (excl GST, read-only)
          Expanded(
            flex: 3,
            child: TextFormField(
              readOnly: true,
              decoration: deco(line.toString()),
            ),
          ),

          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _lines.removeAt(i);
                if (_lines.isEmpty) _lines.add(_Line());
              });
              _recalc();
            },
          ),
        ],
      ),
    );
  }

  Widget _totalsCard(int sub, int tx, int tot) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _kv('Subtotal', _inr(sub)),
        _kv('GST',      _inr(tx)),
        const Divider(),
        _kv('Total',    _inr(tot), big: true),
      ]),
    );
  }

  Widget _kv(String k, String v, {bool big = false}) {
    return Row(
      children: [
        Expanded(child: Text(k, style: TextStyle(color: Colors.grey.shade700))),
        Text(v, style: TextStyle(fontWeight: FontWeight.w700, fontSize: big ? 18 : 14)),
      ],
    );
  }

  String _inr(int minor) {
    final s = minor.toString();
    if (s.length <= 3) return '₹$s';
    final head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final headWithCommas = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
    return '₹$headWithCommas,$tail';
  }
}

class _Line {
  int? productId;
  final qty  = TextEditingController(text: '1');
  final rate = TextEditingController(text: '0');
  void dispose() { qty.dispose(); rate.dispose(); }
}
