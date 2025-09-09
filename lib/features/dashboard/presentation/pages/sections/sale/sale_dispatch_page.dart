import 'package:bhago/features/dashboard/controller/sales_dispatch_controller.dart';
import 'package:bhago/features/dashboard/presentation/pages/sections/sale/so_details_page.dart';
import 'package:drift/drift.dart' as drift;
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
                    CreateSoTab(isMobile: isMobile),
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
 // local-only preview after "Confirm"

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
      child: Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    th('SO No',     flex: 2),
                    th('Customer',  flex: 3),
                    th('Date',      flex: 2),
                    th('Items',     flex: 1),
                    th('Amount',    flex: 2),
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
        ),
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




class CreateSoTab extends StatefulWidget {
  final bool isMobile;
  const CreateSoTab({super.key, required this.isMobile});

  @override
  State<CreateSoTab> createState() => _CreateSoTabState();
}

class _CreateSoTabState extends State<CreateSoTab> {
  final _form = GlobalKey<FormState>();
  DateTime _soDate = DateTime.now();
  int? _partyId;

  final List<_LineItemRow> _rows = [ _LineItemRow() ];

  List<Party> _customers = const [];
  List<Product> _products = const [];
  int? _defaultWarehouseId;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final ctrl = context.read<SalesDispatchController>();
    final customers = await ctrl.fetchCustomers();
    final products  = await ctrl.fetchProducts();
    final wid       = await ctrl.ensureDefaultWarehouse();

    setState(() {
      _customers = customers;
      _products  = products;
      _defaultWarehouseId = wid;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
    if (!ctrl.ready) {
      return const Center(child: Text('Finish onboarding to create Sales Orders.'));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile = widget.isMobile;

    InputDecoration _box(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );

    final selParty = _partyId == null ? null : _customers.firstWhere((p) => p.id == _partyId, orElse: () => _customers.first);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Sales Order', style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold)),
            SizedBox(height: isMobile ? 16 : 24),

            // Customer + Add Customer + Date (NO warehouse selection)
 

 isMobile
    ? Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomerPickerFormField(
                  customers: _customers,
                  initialValue: _partyId,
                  onChanged: (v) => setState(() => _partyId = v),
                  labelText: '',
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openAddCustomer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 10),
         if (_partyId != null && selParty != null) _CustomerMiniCard(
  party: _draftParty ?? selParty,   // <- prefer draft
  onEdit: _openEditCustomer,
),
          const SizedBox(height: 12),
          _dateField(context, _box), // ✅ date field restored on mobile
        ],
      )
    : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Row(
                  children: [
                     Expanded(
                child: CustomerPickerFormField(
                  customers: _customers,
                  initialValue: _partyId,
                  onChanged: (v) => setState(() => _partyId = v),
                  labelText: '',
                ),
              ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _openAddCustomer,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Customer'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_partyId != null) _CustomerMiniCard(
                  party: selParty!,
                  onEdit: _openEditCustomer,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _dateField(context, _box)), // already present on desktop
        ],
      ),


            const SizedBox(height: 24),

            // Line items with product GST, live totals
            _LineItemsSection(
              rows: _rows,
              products: _products,
              onAddRow: () => setState(() => _rows.add(_LineItemRow())),
              onRemoveRow: (i) => setState(() => _rows.removeAt(i)),
              onChanged: () => setState(() {}),
            ),

            const SizedBox(height: 24),
            _TotalsPreview(rows: _rows),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  if (_rows.isEmpty) { _snack(context, 'Add at least one line item'); return; }
                  if (_defaultWarehouseId == null) { _snack(context, 'No default warehouse configured'); return; }
                  if (_partyId == null) { _snack(context, 'Select customer'); return; }

                  final items = <SoItemInput>[];
                  int subtotal = 0, tax = 0, total = 0;
                  for (final r in _rows) {
                    if (r.productId == null || r.qty == null || r.unitPriceMinor == null) {
                      _snack(context, 'Complete all line items'); return;
                    }
                    items.add(SoItemInput(
                      productId: r.productId!, qty: r.qty!, unitPriceMinor: r.unitPriceMinor!,
                    ));
                    final lineNet = r.qty! * r.unitPriceMinor!;
                    final gstPct  = r.gstPct ?? 0;
                    final t       = (lineNet * gstPct / 100).round();
                    subtotal += lineNet; tax += t;
                  }
                  total = subtotal + tax;

                  final ctrl = context.read<SalesDispatchController>();
                 final choice = await showDialog<_PaymentChoice>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _PaymentDialog(
    ctrl: ctrl,                       // <-- pass it
    partyId: _partyId!,
    orderTotalMinor: total,
  ),
);

                  if (choice == null) return;

                  // Create SO
                  final soId = await ctrl.createSalesOrder(
                    partyId: _partyId!,
                    warehouseId: _defaultWarehouseId!,
                    soDate: _soDate,
                    items: items,
                  );

                  // If cash, record payment
                  if (choice.mode == PaymentMode.cash) {
                    final amt = (choice.cashAmountMinor ?? 0);
                    if (amt > 0) {
                      final methodId = await ctrl.ensureCashMethod();
                      await ctrl.addPaymentForSalesOrder(
                        partyId: _partyId!,
                        salesOrderId: soId,
                        methodId: methodId,
                        amountMinor: amt,
                        note: 'Payment at SO $soId',
                      );
                    }
                  }
                  if (!mounted) return;
                  _snack(context, 'Sales Order $soId created');

                  // Go to details page (shows all transactions + balances)
                Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<SalesDispatchController>(),    // reuse existing instance
      child: SalesOrderDetailsPage(soId: soId),
    ),
  ),
);

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

  Future<void> _openAddCustomer() async {
    final ctrl = context.read<SalesDispatchController>();
    final result = await showDialog<Party>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddCustomerDialog(ctrl: ctrl),
    );
    if (result != null) {
      final customers = await ctrl.fetchCustomers();
      setState(() {
        _customers = customers;
        _partyId = result.id;
      });
      _snack(context, 'Customer added');
    }
  }
Party? _draftParty;
Party? _draftCustomerOverride; // shows unsaved edits in UI (optional)




Future<void> _openEditCustomer() async {
  final ctrl = context.read<SalesDispatchController>();
  // pick current displayed party (draft if exists, else selected)
  final base = _draftCustomerOverride ?? _customers.firstWhere((p) => p.id == _partyId);
  final res = await showDialog<EditCustomerResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _EditCustomerDialog(ctrl: ctrl, party: base),
  );
  if (res == null) return;

  if (res.saved) {
  // persisted -> refresh and clear the draft
  final refreshed = await ctrl.fetchCustomers();
  setState(() {
    _customers = refreshed;
    _draftCustomerOverride = null;
  });
  ctrl.clearPartyDraft(res.party.id);        // <— clear in controller too
  _snack(context, 'Customer updated');
} else {
  // local only -> keep draft both locally and in controller
  setState(() => _draftCustomerOverride = res.party);
  ctrl.setPartyDraft(res.party);             // <— makes it available app-wide
  _snack(context, 'Using local changes (not saved)');
}
}

  Widget _dateField(BuildContext context, InputDecoration Function(String) box) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: _fmtDate(_soDate)),
      decoration: box('SO Date'),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _soDate,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 2),
        );
        if (picked != null) setState(() => _soDate = picked);
      },
    );
  }
}

String _fmtDate(DateTime d) =>
    "${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// ---------------- Customer mini card + edit ----------------
class _CustomerMiniCard extends StatelessWidget {
  final Party party;
  final VoidCallback onEdit;
  const _CustomerMiniCard({required this.party, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 72, child: Text(k, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
        Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
      ]),
    );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit, size: 16), label: const Text('Edit')),
          ]),
          const SizedBox(height: 6),
          row('Name', party.name),
          if ((party.phone ?? '').isNotEmpty)  row('Phone', party.phone!),
          if ((party.gstin ?? '').isNotEmpty)  row('GSTIN', party.gstin!),
          if ((party.farmName ?? '').isNotEmpty) row('Farm', party.farmName!),
          if ((party.address ?? '').isNotEmpty)  row('Address', party.address!),
        ]),
      ),
    );
  }
}


/// ============== Add Customer dialog (phone required; GSTIN optional) ==============
class _AddCustomerDialog extends StatefulWidget {
  const _AddCustomerDialog({required this.ctrl});
  final SalesDispatchController ctrl;

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _farm  = TextEditingController();
  final _addr  = TextEditingController();
  final _email = TextEditingController();
  final _gstin = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _farm.dispose(); _addr.dispose(); _email.dispose(); _gstin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration _box(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Text('Add Customer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 10),

                TextFormField(controller: _phone, decoration: _box('Phone *'), keyboardType: TextInputType.phone,
                  validator: (v){ final s=(v??'').trim(); return s.isEmpty ? 'Phone required' : null; }),
                const SizedBox(height: 10),
                TextFormField(controller: _name,  decoration: _box('Name (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _gstin, decoration: _box('GSTIN (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _email, decoration: _box('Email (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _farm,  decoration: _box('Farm name (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _addr,  decoration: _box('Address (optional)'), maxLines: 2),

                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : () async {
                        if (!_form.currentState!.validate()) return;
                        setState(() => _saving = true);
                        try {
                          final p = await widget.ctrl.addCustomer(
                            phone: _phone.text.trim(),
                            name: _name.text.trim().isEmpty ? null : _name.text.trim(),
                            gstin: _gstin.text.trim().isEmpty ? null : _gstin.text.trim(),
                            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
                            farmName: _farm.text.trim().isEmpty ? null : _farm.text.trim(),
                            address: _addr.text.trim().isEmpty ? null : _addr.text.trim(),
                          );
                          if (!mounted) return;
                          Navigator.pop(context, p);
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_saving ? 'Saving...' : 'Add'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============== Edit Customer dialog ==============


class _EditCustomerDialog extends StatefulWidget {
  const _EditCustomerDialog({required this.ctrl, required this.party});
  final SalesDispatchController ctrl;
  final Party party;

  @override
  State<_EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<_EditCustomerDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _farm;
  late final TextEditingController _addr;
  late final TextEditingController _email;
  late final TextEditingController _gstin;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name  = TextEditingController(text: widget.party.name);
    _phone = TextEditingController(text: widget.party.phone ?? '');
    _farm  = TextEditingController(text: widget.party.farmName ?? '');
    _addr  = TextEditingController(text: widget.party.address ?? '');
    _email = TextEditingController(text: widget.party.email ?? '');
    _gstin = TextEditingController(text: widget.party.gstin ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _farm.dispose(); _addr.dispose(); _email.dispose(); _gstin.dispose();
    super.dispose();
  }

  // Build a draft Party without touching DB
Party _buildDraftParty() {
  return widget.party.copyWith(
    name: _name.text.trim(),
    phone:    drift.Value(_phone.text.trim().isEmpty ? null : _phone.text.trim()),
    email:    drift.Value(_email.text.trim().isEmpty ? null : _email.text.trim()),
    gstin:    drift.Value(_gstin.text.trim().isEmpty ? null : _gstin.text.trim()),
    address:  drift.Value(_addr.text.trim().isEmpty ? null : _addr.text.trim()),
    farmName: drift.Value(_farm.text.trim().isEmpty ? null : _farm.text.trim()),
  );
}

  @override
  Widget build(BuildContext context) {
    InputDecoration _box(String hint) => InputDecoration(
      hintText: hint, isDense: true, filled: true, fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Text('Edit Customer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 10),

                TextFormField(controller: _name,  decoration: _box('Name')),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone, decoration: _box('Phone *'), keyboardType: TextInputType.phone,
                  validator: (v){ final s=(v??'').trim(); return s.isEmpty ? 'Phone required' : null; },
                ),
                const SizedBox(height: 10),
                TextFormField(controller: _gstin, decoration: _box('GSTIN (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _email, decoration: _box('Email (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _farm,  decoration: _box('Farm name (optional)')),
                const SizedBox(height: 10),
                TextFormField(controller: _addr,  decoration: _box('Address (optional)'), maxLines: 2),

                const SizedBox(height: 16),
                Row(children: [
                  // ✅ Confirm (local preview only)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () {
                        if (!_form.currentState!.validate()) return;
                        final draft = _buildDraftParty();
                        // Return without hitting DB
                        Navigator.pop(context, EditCustomerResult(party: draft, saved: false));
                      },
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Confirm (don’t update DB)', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ✅ Update (persist to DB)
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : () async {
                        if (!_form.currentState!.validate()) return;
                        setState(() => _saving = true);
                        try {
                          final p = await widget.ctrl.updateCustomer(
                            id: widget.party.id,
                            name: _name.text.trim(),
                            phone: _phone.text.trim(), // phone required
                            gstin: _gstin.text.trim().isEmpty ? null : _gstin.text.trim(),
                            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
                            farmName: _farm.text.trim().isEmpty ? null : _farm.text.trim(),
                            address: _addr.text.trim().isEmpty ? null : _addr.text.trim(),
                          );
                          if (!mounted) return;
                          // Return saved row
                          Navigator.pop(context, EditCustomerResult(party: p, saved: true));
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_saving ? 'Saving…' : 'Update (save to DB)'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class EditCustomerResult {
  /// The edited Party object (either a draft or the saved DB row)
  final Party party;
  /// true = was saved to DB; false = only confirm (local preview)
  final bool saved;
  const EditCustomerResult({required this.party, required this.saved});
}


/// ================== Line items & totals ==================
class _LineItemsSection extends StatelessWidget {
  const _LineItemsSection({
    required this.rows,
    required this.products,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onChanged,
  });

  final List<_LineItemRow> rows;
  final List<Product> products;
  final VoidCallback onAddRow;
  final void Function(int index) onRemoveRow;
  final VoidCallback onChanged;

  Product? _findProd(int? id) {
    if (id == null) return null;
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget header() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: const [
            Expanded(flex: 4, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('GST %', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text('Line Total', style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(width: 40),
          ],
        ),
      );
    }

    Widget row(int i) {
      final r = rows[i];
      final prod = _findProd(r.productId);

      final lineNet = (r.qty ?? 0) * (r.unitPriceMinor ?? 0);
      final gstPct  = r.gstPct ?? prod?.gstPercent ?? 0;
      final tax     = (lineNet * gstPct / 100).round();
      final lineTot = lineNet + tax;

      InputDecoration _box(String hint) => InputDecoration(
        hintText: hint, isDense: true, filled: true, fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      );

      return Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.grey.shade300), right: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Product
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<int>(
                value: r.productId,
                items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) {
                  final newProd = _findProd(v);
                  r.productId = v;
                  r.unitPriceMinor = newProd?.priceMinor ?? newProd?.mrpMinor ?? newProd?.costMinor ?? 0;
                  r.gstPct = newProd?.gstPercent ?? 0;
                  onChanged();
                },
                decoration: _box('Select product'),
              ),
            ),
            const SizedBox(width: 8),

            // Qty
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: r.qty?.toString(),
                keyboardType: TextInputType.number,
                decoration: _box('Qty'),
                onChanged: (v) { r.qty = int.tryParse(v.trim()); onChanged(); },
                validator: (_) => (r.qty == null || r.qty! <= 0) ? 'Req' : null,
              ),
            ),
            const SizedBox(width: 8),

            // Unit price
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: r.unitPriceMinor?.toString(),
                keyboardType: TextInputType.number,
                decoration: _box('Unit price'),
                onChanged: (v) { r.unitPriceMinor = int.tryParse(v.trim()); onChanged(); },
                validator: (_) => (r.unitPriceMinor == null || r.unitPriceMinor! < 0) ? 'Req' : null,
              ),
            ),
            const SizedBox(width: 8),

            // GST % (read-only)
            Expanded(
              flex: 2,
              child: Container(
                height: 44,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$gstPct%'),
              ),
            ),
            const SizedBox(width: 8),

            // Line total
            Expanded(
              flex: 3,
              child: Container(
                height: 44,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_inr(lineTot)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(tooltip: 'Remove', onPressed: () => onRemoveRow(i), icon: const Icon(Icons.close)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header(),
        for (int i = 0; i < rows.length; i++) row(i),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
          ),
          padding: const EdgeInsets.all(10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAddRow,
              icon: const Icon(Icons.add),
              label: const Text('Add line'),
            ),
          ),
        ),
      ],
    );
  }
}

class _LineItemRow {
  int? productId;
  int? qty;
  int? unitPriceMinor;
  int? gstPct; // cached from product
}

class _TotalsPreview extends StatelessWidget {
  const _TotalsPreview({required this.rows});
  final List<_LineItemRow> rows;

  @override
  Widget build(BuildContext context) {
    int subtotal = 0;
    int taxTotal = 0;
    for (final r in rows) {
      final q = r.qty ?? 0;
      final rate = r.unitPriceMinor ?? 0;
      final net = q * rate;
      final gst = r.gstPct ?? 0;
      final t = (net * gst / 100).round();
      subtotal += net;
      taxTotal += t;
    }
    final grand = subtotal + taxTotal;

    Widget chip(String label, String value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );

    return Wrap(spacing: 10, runSpacing: 10, children: [
      chip('Subtotal', _inr(subtotal)),
      chip('Tax', _inr(taxTotal)),
      chip('Total', _inr(grand)),
    ]);
  }
}

String _inr(int n) {
  final s = n.toString();
  if (s.length <= 3) return '₹$s';
  final head = s.substring(0, s.length - 3);
  final tail = s.substring(s.length - 3);
  final headWithCommas = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
  return '₹$headWithCommas,$tail';
}

/// ================= Payment Dialog (Cash / Credit) =================
enum PaymentMode { cash, credit }
class _PaymentChoice {
  final PaymentMode mode;
  final int? cashAmountMinor;
  _PaymentChoice({required this.mode, this.cashAmountMinor});
}

class _PaymentDialog extends StatefulWidget {
  final SalesDispatchController ctrl;
  final int partyId;
  final int orderTotalMinor;
  const _PaymentDialog({required this.ctrl, required this.partyId, required this.orderTotalMinor});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  PaymentMode _mode = PaymentMode.cash;
  final _amountCtrl = TextEditingController();
  Future<PartyStats>? _statsF;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.orderTotalMinor.toString();
    _statsF = widget.ctrl.getPartyStats(widget.partyId);
    
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _inr(int n) => _inrFmt(n);
  static String _inrFmt(int n) {
    final s = n.toString();
    if (s.length <= 3) return '₹$s';
    final head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final headWithCommas = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
    return '₹$headWithCommas,$tail';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Text('Payment', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              FutureBuilder<PartyStats>(
                future: _statsF,
                builder: (context, snap) {
                  final s = snap.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (s == null) const LinearProgressIndicator(minHeight: 2),
                      if (s != null) Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _pill('Lifetime Sales', _inr(s.lifetimeSales)),
                          _pill('Paid In', _inr(s.paidIn)),
                          _pill('Previous Due', _inr(s.due)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _modeTile(PaymentMode.cash, 'Cash (collect now)'),
                      if (_mode == PaymentMode.cash) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Amount to collect now',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withOpacity(.4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Order Total: ${_inr(widget.orderTotalMinor)}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                      const SizedBox(height: 8),
                      _modeTile(PaymentMode.credit, 'Credit (add to receivables)'),
                      if (_mode == PaymentMode.credit && s != null) ...[
                        const SizedBox(height: 6),
                        Text('New Due after this order: ${_inr(s.due + widget.orderTotalMinor)}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      int? amt;
                      if (_mode == PaymentMode.cash) {
                        amt = int.tryParse(_amountCtrl.text.trim());
                        if (amt == null || amt < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                          return;
                        }
                      }
                      Navigator.pop(context, _PaymentChoice(mode: _mode, cashAmountMinor: amt));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTile(PaymentMode m, String title) {
    return RadioListTile<PaymentMode>(
      value: m,
      groupValue: _mode,
      onChanged: (v) => setState(() => _mode = v!),
      title: Text(title),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
class CustomerPickerFormField extends FormField<int?> {
  CustomerPickerFormField({
    super.key,
    required List<Party> customers,
    int? initialValue,
    String labelText = '',
    FormFieldValidator<int?>? validator,
    ValueChanged<int?>? onChanged,
    bool enabled = true,
  }) : super(
          initialValue: initialValue,
          validator: validator ?? (v) => v == null ? 'Select customer' : null,
          builder: (state) {
            final theme = Theme.of(state.context);
            // Resolve selected name
            String selectedName = 'Select customer';
            if (state.value != null) {
              final p = customers.firstWhere(
                (e) => e.id == state.value,
                orElse: () => Party(
                  id: -1,
                  orgId: -1,
                  name: '',
                  phone: null,
                  email: null,
                  gstin: null,
                  address: null,
                  farmName: null,
                  partyType: PartyType.customer,
                  createdAt: null,
                  updatedAt: null,
                ),
              );
              if (p.id != -1) selectedName = p.name;
            }

            Future<void> _openSheet() async {
              if (!enabled) return;
              final picked = await showModalBottomSheet<Party>(
                context: state.context,
                isScrollControlled: true,
                builder: (_) => _CustomerPickerSheet(customers: customers),
              );
              if (picked != null) {
                state.didChange(picked.id);
                onChanged?.call(picked.id);
              }
            }

            final errorText = state.errorText;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _openSheet,
                  child: InputDecorator(
                    isEmpty: state.value == null,
                    decoration: InputDecoration(
                      labelText: labelText,
                      isDense: true,
                      filled: true,
                      enabled: enabled,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      errorText: errorText,
                      suffixIcon: const Icon(Icons.search),
                    ),
                    child: Text(
                      selectedName,
                      style: TextStyle(
                        color: selectedName == 'Select customer'
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet({required this.customers});
  final List<Party> customers;

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _q = TextEditingController();
  late List<Party> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.customers);
    _q.addListener(_apply);
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _apply() {
    final qq = _q.text.trim().toLowerCase();
    setState(() {
      if (qq.isEmpty) {
        _filtered = List.of(widget.customers);
      } else {
        _filtered = widget.customers.where((p) {
          bool match(String? s) => (s ?? '').toLowerCase().contains(qq);
          return match(p.name) || match(p.phone) || match(p.farmName) || match(p.gstin);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: isMobile ? 0.85 : 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _q,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by name / phone / farm / GSTIN',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _filtered[i];
                      return ListTile(
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: _sub(p),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

  }
  Text? _sub(Party p) {
    final chips = <String>[];
    if ((p.phone ?? '').isNotEmpty) chips.add(p.phone!);
    if ((p.farmName ?? '').isNotEmpty) chips.add('Farm: ${p.farmName}');
    if ((p.gstin ?? '').isNotEmpty) chips.add('GST: ${p.gstin}');
    return chips.isEmpty
        ? null
        : Text(chips.join('  •  '), maxLines: 1, overflow: TextOverflow.ellipsis);
  }

}