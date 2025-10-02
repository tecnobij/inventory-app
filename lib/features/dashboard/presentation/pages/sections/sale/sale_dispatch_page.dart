import 'package:bhago/features/dashboard/controller/credit_payments_controller.dart';
import 'package:bhago/features/dashboard/controller/sales_dispatch_controller.dart';
import 'package:bhago/features/dashboard/presentation/all_transactions_page.dart';
import 'package:bhago/features/dashboard/presentation/pages/credit_payment/accountant_picker_page.dart';
import 'package:bhago/features/dashboard/presentation/pages/sections/product_and_stocks.dart';
import 'package:bhago/features/dashboard/presentation/pages/sections/sale/so_details_page.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              
                  (Icons.add, 'Create SO'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                   AllTransactionsPage(),
                  
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


// ===================== Create Sales Order (auto create/update customer on Confirm) =====================
/// Small dialog that shows accountants and returns the picked Party (or null).
Future<Party?> showAccountantPicker(BuildContext context, AppDatabase db, int orgId) {
  final ctrl = CreditPaymentsController(db);

  return showDialog<Party?>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 400,
          height: 480,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text('Pick Accountant', style: Theme.of(context).textTheme.titleLarge),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<List<Party>>(
                    stream: ctrl.watchAccountants(orgId),
                    builder: (context, snap) {
                      final list = snap.data ?? const <Party>[];
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (list.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(child: Text('No accountants available')),
                            IconButton(onPressed: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>AccountantPickerPage()));
                            }, icon: Row(children: [
                              Text('Add accountant'),
                              Icon(Icons.add),
                            ],),)
                          ],
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = list[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?')),
                            title: Text(p.name),
                            subtitle: (p.phone ?? '').isNotEmpty ? Text(p.phone!) : null,
                            onTap: () => Navigator.of(context).pop(p),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}



/// CreateSoTab and related widgets
class CreateSoTab extends StatefulWidget {
  final bool isMobile;
  const CreateSoTab({super.key, required this.isMobile});

  @override
  State<CreateSoTab> createState() => _CreateSoTabState();
}

class _CreateSoTabState extends State<CreateSoTab> {
  final _form = GlobalKey<FormState>();
  DateTime _soDate = DateTime.now();

  int? _partyId; // selected existing party id (if any)
  CustomerFormData? _custForm; // live customer fields coming from inline editor

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
  void dispose() {
    // dispose controllers held by each row
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
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

    final selParty = _partyId == null
        ? null
        : _customers.firstWhere((p) => p.id == _partyId, orElse: () => _customers.first);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Sales Order', style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold)),
            SizedBox(height: isMobile ? 16 : 24),

            // Customer + Date (inline editor with autocomplete)
            isMobile
                ? Column(
                    children: [
                      CustomerInlineEditor(
                        customers: _customers,
                        ctrl: ctrl,
                        initial: selParty,
                        onPick: (p) => setState(() => _partyId = p.id),
                        onFormChanged: (f) => _custForm = f,
                      ),
                      const SizedBox(height: 12),
                      _dateField(context, _box),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomerInlineEditor(
                          customers: _customers,
                          ctrl: ctrl,
                          initial: selParty,
                          onPick: (p) => setState(() => _partyId = p.id),
                          onFormChanged: (f) => _custForm = f,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _dateField(context, _box)),
                    ],
                  ),

            const SizedBox(height: 24),

            // Line items with product GST, live totals
            _LineItemsSection(
              rows: _rows,
              products: _products,
              onAddRow: () => setState(() => _rows.add(_LineItemRow())),
              onRemoveRow: (i) => setState(() {
                // dispose controllers before removing the row
                _rows[i].dispose();
                _rows.removeAt(i);
              }),
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
                  // if (_defaultWarehouseId == null) {
                  //    _snack(context, 'No default warehouse configured'); return;
                  //     }

                  // Build items + totals
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

                  // === Ensure we have a Party in DB (auto create/update) BEFORE payment dialog ===
                  int resolvedPartyId;
                  if (_partyId == null) {
                    // No selection – create if we have at least a name
                    final f = _custForm;
                    final name = f?.name.trim() ?? '';
                    if (name.isEmpty) { _snack(context, 'Select customer or enter a name'); return; }

                    final p = await ctrl.addCustomer(
                      phone: (f?.phone ?? ''),
                      name: name,
                      gstin: (f?.gstin?.isEmpty ?? true) ? null : f!.gstin!.toUpperCase(),
                      email: (f?.email?.isEmpty ?? true) ? null : f!.email,
                      farmName: (f?.farmName?.isEmpty ?? true) ? null : f!.farmName,
                      address: (f?.address?.isEmpty ?? true) ? null : f!.address,
                    );
                    resolvedPartyId = p.id;
                    _partyId = p.id;
                    // refresh local cache for next screens
                    _customers = await ctrl.fetchCustomers();
                  } else {
                    // Existing selection – update with whatever user typed (harmless if unchanged)
                    final f = _custForm;
                    if (f != null) {
                      await ctrl.updateCustomer(
                        id: _partyId!,
                        name: f.name.isEmpty ? (_customers.firstWhere((x) => x.id == _partyId!).name) : f.name,
                        phone: f.phone ?? '',
                        gstin: (f.gstin?.isEmpty ?? true) ? null : f.gstin!.toUpperCase(),
                        email: (f.email?.isEmpty ?? true) ? null : f.email,
                        farmName: (f.farmName?.isEmpty ?? true) ? null : f.farmName,
                        address: (f.address?.isEmpty ?? true) ? null : f.address,
                      );
                      _customers = await ctrl.fetchCustomers();
                    }
                    resolvedPartyId = _partyId!;
                  }

                  // Pick payment choice
                  final choice = await showDialog<PaymentChoice>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => PaymentDialog(
                      ctrl: ctrl,
                      partyId: resolvedPartyId,
                      orderTotalMinor: total,
                    ),
                  );
                  if (choice == null) return;
// If cash payment and amount > 0, force accountant selection BEFORE creating SO
// If cash payment and amount > 0, force accountant selection BEFORE creating SO
int? accountantPartyId;
if (choice.mode == PaymentMode.cash) {
  // choice.cashAmountMinor is now in minor units (paise)
  final amtMinor = (choice.cashAmountMinor ?? 0);
  if (amtMinor > 0) {
    // get orgId (required by picker & payment)
    final s = context.read<SettingsProvider>();
    if (s.orgId == null) {
      _snack(context, 'No org selected');
      return;
    }
    final orgId = s.orgId!;

    // show accountant picker and require selection
    final accountant = await showAccountantPicker(context, context.read<AppDatabase>(), orgId);
    if (accountant == null) {
      // User cancelled picker — do not place order
      _snack(context, 'Select an accountant to record cash payment');
      return;
    }
    accountantPartyId = accountant.id;
  }
}

// Create the Sales Order (only after required accountant selected)
final soId = await ctrl.createSalesOrder(
  partyId: resolvedPartyId,
 
  soDate: _soDate,
  items: items,
);

// If cash, record payment (with accountantPartyId if available)
// If cash, record payment (with accountantPartyId if available)
if (choice.mode == PaymentMode.cash) {
  final amtMinor = (choice.cashAmountMinor ?? 0); // already in paise
  if (amtMinor > 0) {
    final methodId = await ctrl.ensureCashMethod();

    // ensure orgId available (we validated earlier for accountant)
    final s = context.read<SettingsProvider>();
    final orgId = s.orgId!;

    await ctrl.addPaymentForSalesOrder(
      orgId: orgId,
      partyId: resolvedPartyId,
      salesOrderId: soId,
      methodId: methodId,
      amountMinor: amtMinor,
      note: 'Payment at SO $soId',
      accountantPartyId: accountantPartyId,
    );
  }
}

                  if (!mounted) return;
                  _snack(context, 'Sales Order $soId created');

                  // Navigate to details page for BOTH cash & credit flows
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<SalesDispatchController>(),
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

/* -------------------- Line items & totals -------------------- */
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

  Future<void> _goToProducts(BuildContext ctx) async {
    await Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const ProductPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    InputDecoration _box(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );

    // When there are no products, this “fake field” is shown and routes to ProductPage on tap.
    Widget _noProductsInput(BuildContext ctx, {String hint = 'No products found — tap to add'}) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _goToProducts(ctx),
        child: InputDecorator(
          decoration: _box(hint),
          child: Row(
            children: const [
              Icon(Icons.add_box_outlined, size: 18),
              SizedBox(width: 8),
              Text('Add product'),
              Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ),
      );
    }

    // Reusable product picker (desktop & mobile both use this)
    Widget _productPicker(BuildContext ctx, _LineItemRow r, {String? hint}) {
      if (products.isEmpty) {
        return _noProductsInput(ctx, hint: hint ?? 'No products found — tap to add');
      }
      return DropdownButtonFormField<int>(
        value: r.productId,
        items: products
            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
            .toList(),
        onChanged: (v) {
          final newProd = _findProd(v);
          r.productId = v;
          r.unitPriceMinor = newProd?.priceMinor ?? newProd?.mrpMinor ?? newProd?.costMinor ?? 0;
          r.unitPriceMinor=(r.unitPriceMinor!/100).toInt();
          r.gstPct = newProd?.gstPercent ?? 0;
          onChanged();
        },
        decoration: _box(hint ?? 'Select product'),
      );
    }

    Widget headerDesktop() {
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

    Widget rowDesktop(int i) {
      final r = rows[i];
      final prod = _findProd(r.productId);

      final lineNet = (r.qty ?? 0) * (r.unitPriceMinor ?? 0);
      final gstPct  = r.gstPct ?? prod?.gstPercent ?? 0;
      final tax     = (lineNet * gstPct / 100).round();
      final lineTot = lineNet + tax;

      return Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.grey.shade300), right: BorderSide(color: Colors.grey.shade300))),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Product (navigates if none)
            Expanded(
              flex: 4,
              child: _productPicker(
                context,
                r,
                hint: 'Select product',
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
                decoration: _box('Default'),
                onChanged: (v) { r.unitPriceMinor = int.tryParse(v.trim()); onChanged(); },
                validator: (_) => (r.unitPriceMinor == null || r.unitPriceMinor! < 0) ? 'Req' : null,
              ),
            ),
            const SizedBox(width: 8),

            // GST % (read-only)
            // Expanded(
            //   flex: 2,
            //   child: Container(
            //     height: 44,
            //     alignment: Alignment.centerLeft,
            //     padding: const EdgeInsets.symmetric(horizontal: 12),
            //     decoration: BoxDecoration(
            //       color: Colors.grey.shade100,
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: Text('${r.gstPct ?? prod?.gstPercent ?? 0}%'),
            //   ),
            // ),
            // GST % (editable)
// GST % (editable)
Expanded(
  flex: 2,
  child: TextFormField(
    key: ValueKey("gst-${r.productId}"), // forces rebuild when product changes
    initialValue: r.gstPct?.toString(),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: _box('GST %'),
    onChanged: (v) {
      r.gstPct = int.tryParse(v.trim());
      onChanged();
    },
    validator: (_) => (r.gstPct == null || r.gstPct! < 0) ? 'Req' : null,
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

    Widget _readOnlyPill(String text) {
      return Container(
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(text),
      );
    }

    Widget rowMobile(int i) {
      final r = rows[i];
      final prod = _findProd(r.productId);

      final lineNet = (r.qty ?? 0) * (r.unitPriceMinor ?? 0);
      final gstPct  = r.gstPct ?? prod?.gstPercent ?? 0;
      final tax     = (lineNet * gstPct / 100).round();
      final lineTot = lineNet + tax;

      return Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Item ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () => onRemoveRow(i),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Product (navigates if none)
              _productPicker(
                context,
                r,
                hint: 'Select product',
              ),
              const SizedBox(height: 10),

              // Qty + Unit price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: r.qty?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: _box('Qty'),
                      onChanged: (v) { r.qty = int.tryParse(v.trim()); onChanged(); },
                      validator: (_) => (r.qty == null || r.qty! <= 0) ? 'Req' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: r.unitPriceMinor?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: _box('Unit price'),
                      onChanged: (v) { r.unitPriceMinor = int.tryParse(v.trim()); onChanged(); },
                      validator: (_) => (r.unitPriceMinor == null || r.unitPriceMinor! < 0) ? 'Req' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // GST % + Line total
              Row(
                children: [
                  Expanded(child: _readOnlyPill('GST: ${r.gstPct ?? prod?.gstPercent ?? 0}%')),
                  const SizedBox(width: 8),
                  Expanded(child: _readOnlyPill('Total: ${_inr(lineTot)}')),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget addRowBar() {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
        ),
        padding: const EdgeInsets.all(10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              if (products.isEmpty) {
                _goToProducts(context);
              } else {
                onAddRow();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add line'),
          ),
        ),
      );
    }

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          for (int i = 0; i < rows.length; i++) rowMobile(i),
          addRowBar(),
        ],
      );
    }

    // Desktop/tablet
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerDesktop(),
        for (int i = 0; i < rows.length; i++) rowDesktop(i),
        addRowBar(),
      ],
    );
  }
}


class _LineItemRow {
  int? productId;
  int? qty;
  int? unitPriceMinor;
  int? gstPct;
  
  void dispose() {} // cached from product
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




enum PaymentMode { cash, credit }

class PaymentChoice {
  final PaymentMode mode;
  final int? cashAmountMinor;
  PaymentChoice({required this.mode, this.cashAmountMinor});
}

class PaymentDialog extends StatefulWidget {
  final SalesDispatchController ctrl;
  final int partyId;
  final int orderTotalMinor;
  const PaymentDialog({super.key, required this.ctrl, required this.partyId, required this.orderTotalMinor});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  PaymentMode _mode = PaymentMode.cash;
  final _amountCtrl = TextEditingController();
  Future<PartyStats>? _statsF;

  @override
  void initState() {
    super.initState();
    // show order total in RUPEES (friendly), but we'll return minor units when continuing
 
    // show without unnecessary trailing zeros if it's whole
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Amount to collect now (₹)',
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

                      Navigator.pop(context, PaymentChoice(mode: _mode, cashAmountMinor: amt));
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




/* ================== Customer Inline Editor (NO save/use-only) ================== */

// (Copied from your original file — keep unchanged)
class CustomerFormData {
  final int? id;
  final String name;
  final String? phone, gstin, email, farmName, address;

  CustomerFormData({
    required this.id,
    required this.name,
    this.phone,
    this.gstin,
    this.email,
    this.farmName,
    this.address,
  });

  CustomerFormData copyWith({
    int? id,
    String? name,
    String? phone,
    String? gstin,
    String? email,
    String? farmName,
    String? address,
  }) => CustomerFormData(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    gstin: gstin ?? this.gstin,
    email: email ?? this.email,
    farmName: farmName ?? this.farmName,
    address: address ?? this.address,
  );
}

class CustomerInlineEditor extends StatefulWidget {
  const CustomerInlineEditor({
    super.key,
    required this.customers,
    required this.ctrl,
    this.initial,
    required this.onPick,
    required this.onFormChanged,
  });

  final List<Party> customers;
  final SalesDispatchController ctrl;
  final Party? initial;
  final ValueChanged<Party> onPick;
  final ValueChanged<CustomerFormData> onFormChanged;

  @override
  State<CustomerInlineEditor> createState() => _CustomerInlineEditorState();
}

class _CustomerInlineEditorState extends State<CustomerInlineEditor> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  final _name   = TextEditingController();
  final _phone  = TextEditingController();
  final _gstin  = TextEditingController();
  final _email  = TextEditingController();
  final _farm   = TextEditingController();
  final _addr   = TextEditingController();

  Party? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _selected = widget.initial;
      _fillFromParty(widget.initial!);
      _search.text = _displayParty(widget.initial!);
    }
    _search.addListener(_mirrorSearchIntoFields);

    for (final c in [_name, _phone, _gstin, _email, _farm, _addr]) {
      c.addListener(_emit);
    }
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _search.dispose();
    _name.dispose();
    _phone.dispose();
    _gstin.dispose();
    _email.dispose();
    _farm.dispose();
    _addr.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onFormChanged(CustomerFormData(
      id: _selected?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      gstin: _gstin.text.trim().isEmpty ? null : _gstin.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      farmName: _farm.text.trim().isEmpty ? null : _farm.text.trim(),
      address: _addr.text.trim().isEmpty ? null : _addr.text.trim(),
    ));
  }

  void _fillFromParty(Party p) {
    _name.text  = p.name;
    _phone.text = (p.phone ?? '');
    _gstin.text = (p.gstin ?? '');
    _email.text = (p.email ?? '');
    _farm.text  = (p.farmName ?? '');
    _addr.text  = (p.address ?? '');
    _emit();
  }

  String _displayParty(Party p) {
    final phone = (p.phone ?? '').isEmpty ? '' : ' • ${p.phone}';
    return '${p.name}$phone';
  }

  Iterable<Party> _filter(String q) {
    final qq = q.trim().toLowerCase();
    if (qq.isEmpty) return const Iterable<Party>.empty();
    bool match(String? s) => (s ?? '').toLowerCase().contains(qq);
    return widget.customers.where((p) =>
    match(p.name) || match(p.phone) || match(p.farmName) || match(p.gstin)
    ).take(12);
  }

  InputDecoration _box(BuildContext ctx, String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: Colors.grey.shade100,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );

  void _mirrorSearchIntoFields() {
    if (_selected != null) return;

    final raw = _search.text.trim();
    if (raw.isEmpty) return;

    final gstMatch = RegExp(
      r'\b[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]\b',
      caseSensitive: false,
    ).firstMatch(raw);
    var working = raw;

    if (gstMatch != null) {
      final gst = gstMatch.group(0)!.toUpperCase();
      if (_gstin.text.isEmpty) _gstin.text = gst;
      working = working.replaceFirst(gstMatch.group(0)!, '').trim();
    }

    final isNumericLike = RegExp(r'^[\d\+\-\s\(\)]+$').hasMatch(working);
    if (isNumericLike) {
      final digits = working.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        final last10 = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
        if (_phone.text != last10) _phone.text = last10;
        _emit();
      }
      return;
    }

    final digits = working.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) {
      final last10 = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
      if (_phone.text.isEmpty) _phone.text = last10;
      working = working.replaceAll(RegExp(r'\d'), ' ').trim();
    }

    working = working
        .replaceAll(RegExp(r'[-|,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (working.isNotEmpty) {
      final title = working
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');
      if (_name.text.isEmpty || _name.text != title) {
        _name.text = title;
      }
    }

    _emit();
  }

  void _clearAll() {
    setState(() { _selected = null; });
    _search.clear();
    _name.clear();
    _phone.clear();
    _gstin.clear();
    _email.clear();
    _farm.clear();
    _addr.clear();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RawAutocomplete<Party>(
          textEditingController: _search,
          focusNode: _searchFocus,
          optionsBuilder: (t) => _filter(t.text),
          displayStringForOption: _displayParty,
          onSelected: (p) {
            setState(() { _selected = p; });
            _fillFromParty(p);
            widget.onPick(p);
            _emit();
          },
          fieldViewBuilder: (_, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: _box(context, 'Search name / phone / GSTIN'),
            );
          },
          optionsViewBuilder: (_, onSelected, options) {
            final list = options.toList();
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final subtitleBits = <String>[
                      if ((p.phone ?? '').isNotEmpty) p.phone!,
                      if ((p.farmName ?? '').isNotEmpty) 'Farm: ${p.farmName}',
                      if ((p.gstin ?? '').isNotEmpty) 'GST: ${p.gstin}',
                    ];
                    return ListTile(
                      dense: true,
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: subtitleBits.isEmpty
                          ? null
                          : Text(subtitleBits.join('  •  '), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onSelected(p),
                    );
                  },
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        isMobile
            ? Column(children: _fields(context))
            : Row(
                children: [
                  Expanded(child: Column(children: _fieldsLeft(context))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(children: _fieldsRight(context))),
                ],
              ),

        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(onPressed: _clearAll, child: const Text('Clear')),
        ),

        if (_selected != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 18),
              const SizedBox(width: 6),
              Text('Selected: ${_selected!.name}'),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _fields(BuildContext ctx) => [
    TextField(controller: _name,  decoration: _box(ctx, 'Name *')),
    const SizedBox(height: 8),
    TextField(controller: _phone, decoration: _box(ctx, 'Phone (optional)'), keyboardType: TextInputType.phone),
    const SizedBox(height: 8),
    TextField(controller: _gstin, decoration: _box(ctx, 'GSTIN (optional)')),
    const SizedBox(height: 8),
    TextField(controller: _email, decoration: _box(ctx, 'Email (optional)')),
    const SizedBox(height: 8),
    TextField(controller: _farm,  decoration: _box(ctx, 'Farm name (optional)')),
    const SizedBox(height: 8),
    TextField(controller: _addr,  decoration: _box(ctx, 'Address (optional)'), maxLines: 2),
  ];

  List<Widget> _fieldsLeft(BuildContext ctx) => [
    TextField(controller: _name,  decoration: _box(ctx, 'Name *')),
    const SizedBox(height: 8),
    TextField(controller: _phone, decoration: _box(ctx, 'Phone (optional)'), keyboardType: TextInputType.phone),
    const SizedBox(height: 8),
    TextField(controller: _gstin, decoration: _box(ctx, 'GSTIN (optional)')),
  ];

  List<Widget> _fieldsRight(BuildContext ctx) => [
    TextField(controller: _email, decoration: _box(ctx, 'Email (optional)')),
    const SizedBox(height: 8),
    TextField(controller: _farm,  decoration: _box(ctx, 'Farm name (optional)')),
    const SizedBox(height: 8),
    TextField(controller: _addr,  decoration: _box(ctx, 'Address (optional)'), maxLines: 2),
  ];
}

/* ================= Helper: showAccountantPicker =================
   This function should exist in your codebase already (you earlier added it).
   Ensure it's imported/visible here. If not, paste your showAccountantPicker
   implementation (the recommended one uses your CreditPaymentsController.watchAccountants).
*/

