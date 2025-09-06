import 'package:bhago/features/dashboard/controller/sales_dispatch_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart';



class SalesDispatchPage extends StatelessWidget {
  const SalesDispatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SalesDispatchController(
        db: context.read<AppDatabase>(),
        settings: context.read<SettingsProvider>(),
      ),
      child: const _SalesDispatchScaffold(),
    );
  }
}

class _SalesDispatchScaffold extends StatelessWidget {
  const _SalesDispatchScaffold();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              SegmentedTabs(
                tabs: const [
                  (Icons.receipt_long, 'Sales Orders'),
                  (Icons.description, 'Invoices'),
                  (Icons.add, 'Create SO'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _SalesOrdersTab(isMobile: isMobile),
                    _InvoicesTab(isMobile: isMobile),
                    _CreateSoTab(isMobile: isMobile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------- Sales Orders Tab -------------------
class _SalesOrdersTab extends StatefulWidget {
  final bool isMobile;
  const _SalesOrdersTab({required this.isMobile});

  @override
  State<_SalesOrdersTab> createState() => _SalesOrdersTabState();
}

class _SalesOrdersTabState extends State<_SalesOrdersTab> {
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _q.addListener(() {
      context.read<SalesDispatchController>().setSoQuery(_q.text);
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
    if (!ctrl.ready) {
      return const Center(child: Text('Finish onboarding to use Sales & Dispatch.'));
    }

    return Padding(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _searchField(_q, 'Search SO number / customer...'),
                    const SizedBox(height: 12),
                    _filtersPill(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _searchField(_q, 'Search SO number / customer...')),
                    const SizedBox(width: 16),
                    _filtersPill(),
                  ],
                ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<SalesOrderVM>>(
              stream: ctrl.watchSalesOrders(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? const <SalesOrderVM>[];
                if (items.isEmpty) {
                  return _emptyState(
                    title: 'No Sales Orders',
                    subtitle: 'Create your first Sales Order to get started.',
                    cta: 'Create SO',
                    onTap: () => DefaultTabController.of(context).animateTo(2),
                  );
                }

                return widget.isMobile
                    ? ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) => _SoCard(item: items[i]),
                      )
                    : _SoTable(items: items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.filter_list, size: 18), SizedBox(width: 8), Text('Filters')],
        ),
      );

  Widget _searchField(TextEditingController c, String hint) => TextFormField(
        controller: c,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      );

  Widget _emptyState({
    required String title,
    required String subtitle,
    required String cta,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: Text(cta),
          ),
        ],
      ),
    );
  }
}

class _SoTable extends StatelessWidget {
  final List<SalesOrderVM> items;
  const _SoTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ctrl = context.read<SalesDispatchController>();

    Widget th(String t, {int flex = 1}) => Expanded(
          flex: flex,
          child: Text(t, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        );

    Widget td(String t, {int flex = 1, bool bold = false}) => Expanded(
          flex: flex,
          child: Text(t, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                th('SO No', flex: 2),
                th('Customer', flex: 3),
                th('Date', flex: 2),
                th('Warehouse', flex: 2),
                th('Items', flex: 1),
                th('Amount', flex: 2),
                const SizedBox(width: 56, child: Text('')),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final s in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  td(s.soNo, flex: 2, bold: true),
                  td(s.customer, flex: 3),
                  td(_fmtDate(s.date), flex: 2),
                  td(s.warehouse, flex: 2),
                  td('${s.itemsCount}', flex: 1),
                  td(ctrl.inr(s.totalMinor), flex: 2, bold: true),
                  const SizedBox(width: 56, child: Icon(Icons.visibility_outlined, size: 20)),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '-' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _SoCard extends StatelessWidget {
  final SalesOrderVM item;
  const _SoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<SalesDispatchController>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(item.soNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _statusChip(item.status),
          ]),
          const SizedBox(height: 8),
          Text('Customer: ${item.customer}'),
          const SizedBox(height: 2),
          Text('Date: ${_fmtDate(item.date)}', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Items: ${item.itemsCount}', style: TextStyle(color: Colors.grey.shade700)),
            Text(ctrl.inr(item.totalMinor), style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  Widget _statusChip(SoStatus? s) {
    final label = s?.name.toUpperCase() ?? 'DRAFT';
    final dark = (s == SoStatus.confirmed || s == SoStatus.dispatched);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? Colors.black : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '-' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// ------------------- Invoices Tab -------------------
class _InvoicesTab extends StatefulWidget {
  final bool isMobile;
  const _InvoicesTab({required this.isMobile});

  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab> {
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _q.addListener(() => context.read<SalesDispatchController>().setInvQuery(_q.text));
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
    if (!ctrl.ready) return const Center(child: Text('Finish onboarding to use Sales & Dispatch.'));

    return Padding(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _searchField(_q, 'Search Invoice / SO / Customer...'),
                    const SizedBox(height: 12),
                    _einvoicePill(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _searchField(_q, 'Search Invoice / SO / Customer...')),
                    const SizedBox(width: 16),
                    _einvoicePill(),
                  ],
                ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<InvoiceVM>>(
              stream: ctrl.watchInvoices(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? const <InvoiceVM>[];
                if (items.isEmpty) {
                  return const Center(child: Text('No invoices yet.'));
                }
                return widget.isMobile
                    ? ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) => _InvCard(item: items[i]),
                      )
                    : _InvTable(items: items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _einvoicePill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.description, size: 18), SizedBox(width: 8), Text('e-invoice (future)')],
        ),
      );

  Widget _searchField(TextEditingController c, String hint) => TextFormField(
        controller: c,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      );
}

class _InvTable extends StatelessWidget {
  final List<InvoiceVM> items;
  const _InvTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ctrl = context.read<SalesDispatchController>();

    Widget th(String t, {int flex = 1}) => Expanded(
          flex: flex,
          child: Text(t, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        );

    Widget td(String t, {int flex = 1, bool bold = false}) => Expanded(
          flex: flex,
          child: Text(t, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                th('Invoice No', flex: 2),
                th('SO No', flex: 2),
                th('Customer', flex: 3),
                th('Date', flex: 2),
                th('Amount', flex: 2),
                th('Status', flex: 2),
                const SizedBox(width: 56),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final r in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  td(r.invNo, flex: 2, bold: true),
                  td(r.soNo, flex: 2),
                  td(r.customer, flex: 3),
                  td(_fmtDate(r.date), flex: 2),
                  td(ctrl.inr(r.totalMinor), flex: 2, bold: true),
                  td(r.status?.name.toUpperCase() ?? 'DRAFT', flex: 2),
                  const SizedBox(width: 56, child: Icon(Icons.download_outlined, size: 20)),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '-' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _InvCard extends StatelessWidget {
  final InvoiceVM item;
  const _InvCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<SalesDispatchController>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(item.invNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _statusChip(item.status),
          ]),
          const SizedBox(height: 8),
          Text('SO: ${item.soNo}', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Customer: ${item.customer}'),
          const SizedBox(height: 4),
          Text('Date: ${_fmtDate(item.date)}', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(ctrl.inr(item.totalMinor), style: const TextStyle(fontWeight: FontWeight.w700)),
            const Icon(Icons.download_outlined, size: 20),
          ]),
        ]),
      ),
    );
  }

  Widget _statusChip(InvoiceStatus? s) {
    final dark = s == InvoiceStatus.paid;
    final label = s?.name.toUpperCase() ?? 'DRAFT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: dark ? Colors.black : Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '-' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// ------------------- Create SO Tab -------------------
class _CreateSoTab extends StatefulWidget {
  final bool isMobile;
  const _CreateSoTab({required this.isMobile});

  @override
  State<_CreateSoTab> createState() => _CreateSoTabState();
}

class _CreateSoTabState extends State<_CreateSoTab> {
  final _form = GlobalKey<FormState>();
  DateTime _soDate = DateTime.now();
  int? _partyId;
  int? _warehouseId;

  // dynamic line items
  final List<_LineItemRow> _rows = [ _LineItemRow() ];

  List<Party> _customers = const [];
  List<Warehouse> _warehouses = const [];
  List<Product> _products = const [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final ctrl = context.read<SalesDispatchController>();
    final customers = await ctrl.fetchCustomers();
    final warehouses = await ctrl.fetchWarehouses();
    final products = await ctrl.fetchProducts();

    setState(() {
      _customers = customers;
      _warehouses = warehouses;
      _products = products;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
    if (!ctrl.ready) return const Center(child: Text('Finish onboarding to create Sales Orders.'));
    if (_loading) return const Center(child: CircularProgressIndicator());

    final isMobile = widget.isMobile;

    InputDecoration _box(String hint) => InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Sales Order', style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold)),
            SizedBox(height: isMobile ? 16 : 24),

            // Customer + Date
            isMobile
                ? Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _partyId,
                        items: _customers
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _partyId = v),
                        validator: (v) => v == null ? 'Select customer' : null,
                        decoration: _box('Customer *'),
                      ),
                      const SizedBox(height: 12),
                      _dateField(context, _box),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _partyId,
                          items: _customers
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _partyId = v),
                          validator: (v) => v == null ? 'Select customer' : null,
                          decoration: _box('Customer *'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _dateField(context, _box)),
                    ],
                  ),
            const SizedBox(height: 16),

            // Warehouse + Terms placeholder
            isMobile
                ? DropdownButtonFormField<int>(
                    value: _warehouseId,
                    items: _warehouses
                        .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _warehouseId = v),
                    validator: (v) => v == null ? 'Select warehouse' : null,
                    decoration: _box('Warehouse *'),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _warehouseId,
                          items: _warehouses
                              .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _warehouseId = v),
                          validator: (v) => v == null ? 'Select warehouse' : null,
                          decoration: _box('Warehouse *'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: SizedBox()), // reserved for "Payment Terms" etc.
                    ],
                  ),
            const SizedBox(height: 24),

            // Line items table (responsive)
            _LineItemsSection(
              rows: _rows,
              products: _products,
              onAddRow: () => setState(() => _rows.add(_LineItemRow())),
              onRemoveRow: (i) => setState(() => _rows.removeAt(i)),
            ),

            const SizedBox(height: 24),
            _TotalsPreview(rows: _rows, products: _products),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  if (_rows.isEmpty) {
                    _snack('Add at least one line item');
                    return;
                  }

                  final items = <SoItemInput>[];
                  for (final r in _rows) {
                    if (r.productId == null || r.qty == null || r.unitPriceMinor == null) {
                      _snack('Complete all line items');
                      return;
                    }
                    items.add(SoItemInput(
                      productId: r.productId!,
                      qty: r.qty!,
                      unitPriceMinor: r.unitPriceMinor!,
                    ));
                  }

                  final soId = await ctrl.createSalesOrder(
                    partyId: _partyId!,
                    warehouseId: _warehouseId!,
                    soDate: _soDate,
                    items: items,
                  );

                  if (mounted) {
                    _snack('Sales Order ${soId} created');
                    DefaultTabController.of(context).animateTo(0);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirm Sales Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context, InputDecoration Function(String) box) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _soDate,
          firstDate: DateTime(2020, 1, 1),
          lastDate: DateTime(2100, 12, 31),
        );
        if (picked != null) setState(() => _soDate = picked);
      },
      child: InputDecorator(
        decoration: box('SO Date *'),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Text(_fmtDate(_soDate)),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

/// ----- line item row model -----
class _LineItemRow {
  int? productId;
  int? qty;
  int? unitPriceMinor;
}

/// ----- line items UI -----
class _LineItemsSection extends StatelessWidget {
  final List<_LineItemRow> rows;
  final List<Product> products;
  final VoidCallback onAddRow;
  final void Function(int index) onRemoveRow;

  const _LineItemsSection({
    required this.rows,
    required this.products,
    required this.onAddRow,
    required this.onRemoveRow,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    InputDecoration _cell(String hint) => InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 48),
              ],
            ),
          ),
          const Divider(height: 1),
          // rows
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<int>(
                      value: rows[i].productId,
                      items: products
                          .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.code})')))
                          .toList(),
                      onChanged: (v) => rows[i].productId = v,
                      validator: (v) => v == null ? 'Select product' : null,
                      decoration: _cell('Select product'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: rows[i].qty?.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => rows[i].qty = int.tryParse(v),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Qty';
                        return null;
                      },
                      decoration: _cell('Qty'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: rows[i].unitPriceMinor?.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => rows[i].unitPriceMinor = int.tryParse(v),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Unit price';
                        return null;
                      },
                      decoration: _cell('Unit Price (minor)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: rows.length == 1 ? null : () => onRemoveRow(i),
                    icon: const Icon(Icons.delete_outline),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: OutlinedButton.icon(
                onPressed: onAddRow,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsPreview extends StatelessWidget {
  final List<_LineItemRow> rows;
  final List<Product> products;
  const _TotalsPreview({required this.rows, required this.products});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<SalesDispatchController>();
    int subtotal = 0;
    int tax = 0;

    for (final r in rows) {
      if (r.qty != null && r.unitPriceMinor != null) {
        final line = r.qty! * r.unitPriceMinor!;
        subtotal += line;
       final idx = products.indexWhere((x) => x.id == r.productId);
final pct = idx >= 0 ? (products[idx].gstPercent ?? 0) : 0;

       
        tax += (line * pct ~/ 100);
      }
    }
    final total = subtotal + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _kv('Subtotal:', ctrl.inr(subtotal)),
          const SizedBox(height: 8),
          _kv('GST:', ctrl.inr(tax)),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _kv('Grand Total:', ctrl.inr(total), big: true),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool big = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(fontSize: big ? 18 : 16, fontWeight: big ? FontWeight.bold : FontWeight.normal)),
          Text(v, style: TextStyle(fontSize: big ? 18 : 16, fontWeight: big ? FontWeight.bold : FontWeight.w500)),
        ],
      );
}
