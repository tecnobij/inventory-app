// lib/features/quotations/presentation/quotations_page.dart
import 'dart:async';
import 'package:bhago/features/dashboard/controller/quotations_controller.dart';
import 'package:bhago/features/dashboard/presentation/pages/quotation/quotation_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart';

class QuotationsPage extends StatelessWidget {
  const QuotationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the controller (scoped just to this page)
    return ChangeNotifierProvider(
      create: (_) => QuotationsController(
        db: context.read<AppDatabase>(),
        settings: context.read<SettingsProvider>(),
      ),
      child: const _QuotationsScaffold(),
    );
  }
}

class _QuotationsScaffold extends StatelessWidget {
  const _QuotationsScaffold();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (!settings.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!settings.onboarded || settings.orgId == null) {
      return const Scaffold(
        body: Center(child: Text('Please complete onboarding to use Quotations.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedTabs(
                  tabs: [
                    (Icons.widgets_outlined, 'List'),
                    (Icons.description_outlined, 'Create Quote'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Expanded(child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _QuotesListTab(),
                  _CreateQuoteTab(),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- List Tab ----------------------------- */
class _QuotesListTab extends StatefulWidget {
  const _QuotesListTab();

  @override
  State<_QuotesListTab> createState() => _QuotesListTabState();
}

class _QuotesListTabState extends State<_QuotesListTab> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        context.read<QuotationsController>().setQuery(_searchCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<QuotationsController>();
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.of(context).size.width >= 900;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 460),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search customer or quote id…',
                  filled: true,
                  fillColor: scheme.surfaceVariant.withOpacity(.45),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: StreamBuilder<List<QuoteVM>>(
            stream: ctrl.watchQuotes(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }
              final rows = snap.data ?? const <QuoteVM>[];

              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text('No quotations yet.',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                );
              }

              return wide ? _TableWide(rows: rows) : _CardsNarrow(rows: rows);
            },
          ),
        ),
      ],
    );
  }
}

class _TableWide extends StatelessWidget {
  const _TableWide({required this.rows});
  final List<QuoteVM> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget head(String t, {int flex = 1}) => Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(t, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        )),
      ),
    );

    Widget cell(String t, {int flex = 1, TextAlign align = TextAlign.left}) => Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: align),
      ),
    );

    Divider div() => Divider(height: 1, color: scheme.outlineVariant);

    return Column(
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            head('Quote No', flex: 2),
            head('Customer', flex: 3),
            head('Date', flex: 2),
            head('Valid Till', flex: 2),
            head('Status', flex: 2),
            head('Amount', flex: 2),
            head('Actions', flex: 2),
          ],
        ),
        div(),
        for (final r in rows) ...[
          Row(
            children: [
              cell(r.docNo, flex: 2),
              cell(r.partyName, flex: 3),
              cell(_d(r.quoteDate), flex: 2),
              cell(_d(r.validTill), flex: 2),
              Expanded(flex: 2, child: _StatusPill(status: r.status)),
              cell('₹${_comma((r.totalMinor/100).toInt())}', flex: 2),
              Expanded(
                flex: 2,
                child: Row(children: [
                 IconButton(
  tooltip: 'View',
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => QuotationDetailsPage(quoteId: r.id),
    ),
  ),
  icon: const Icon(Icons.remove_red_eye_outlined),
),

                ]),
              ),
            ],
          ),
          div(),
        ],
        const SizedBox(height: 6),
      ],
    );
  }
}

class _CardsNarrow extends StatelessWidget {
  const _CardsNarrow({required this.rows});
  final List<QuoteVM> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: rows.map((r) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(r.docNo, style: Theme.of(context).textTheme.titleMedium)),
                  Text('₹${_comma((r.totalMinor/100).toInt())}'),
                ]),
                const SizedBox(height: 6),
                Text(r.partyName),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _meta('Date', _d(r.quoteDate)),
                    _meta('Valid Till', _d(r.validTill)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Status '),
                      _StatusPill(status: r.status),
                    ]),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
  tooltip: 'View',
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => QuotationDetailsPage(quoteId: r.id),
    ),
  ),
  icon: const Icon(Icons.remove_red_eye_outlined),
),

                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _meta(String k, String v) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w700)),
      Text(v),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final QuoteStatus status;

  @override
  Widget build(BuildContext context) {
    final dark = status == QuoteStatus.open;
    final bg = dark ? const Color(0xFF0B0B14) : const Color(0xFFF2F4F7);
    final fg = dark ? Colors.white : const Color(0xFF344054);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          _label(status),
          style: TextStyle(color: fg, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _label(QuoteStatus s) {
    switch (s) {
      case QuoteStatus.open: return 'Open';
      case QuoteStatus.accepted: return 'Accepted';
      case QuoteStatus.rejected: return 'Rejected';
      case QuoteStatus.expired: return 'Expired';
    }
  }
}

/* ---------------------------- Create Tab ---------------------------- */
class _CreateQuoteTab extends StatefulWidget {
  const _CreateQuoteTab();

  @override
  State<_CreateQuoteTab> createState() => _CreateQuoteTabState();
}

class _CreateQuoteTabState extends State<_CreateQuoteTab> {
  final _formKey = GlobalKey<FormState>();
  int? _partyId;
  DateTime _quoteDate = DateTime.now();
  DateTime _validTill = DateTime.now().add(const Duration(days: 30));

  // dynamic lines
  final List<LineModel> _lines = [ LineModel() ];

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<QuotationsController>();
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder(
      future: Future.wait([ctrl.fetchParties(), ctrl.fetchProducts()]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final parties = (snap.data?[0] as List<PartyLite>? ?? []);
        final products = (snap.data?[1] as List<ProductLite>? ?? []);
        final narrow = MediaQuery.of(context).size.width < 720;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Create Quote', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header fields
                  narrow
                      ? Column(
                          children: [
                            _partyField(parties, scheme),
                            const SizedBox(height: 12),
                            _dateField('Quote Date', _quoteDate, (d) => setState(() => _quoteDate = d)),
                            const SizedBox(height: 12),
                            _dateField('Valid Till', _validTill, (d) => setState(() => _validTill = d)),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _partyField(parties, scheme)),
                            const SizedBox(width: 12),
                            Expanded(child: _dateField('Quote Date', _quoteDate, (d) => setState(() => _quoteDate = d))),
                            const SizedBox(width: 12),
                            Expanded(child: _dateField('Valid Till', _validTill, (d) => setState(() => _validTill = d))),
                          ],
                        ),

                  const SizedBox(height: 16),

                  // Lines table
                  _LinesEditor(
                    lines: _lines,
                    products: products,
                    onChanged: () => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Totals
                  TotalsBox(lines: _lines,),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save Quote'),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (_lines.where((l) => l.isValid).isEmpty) {
                              _snack(context, 'Add at least one valid line');
                              return;
                            }

                            final items = _lines
                                .where((l) => l.isValid)
                                .map((l) => CreateItem(
                                      productId: l.productId!,
                                      qty: l.qty!,
                                      unitPriceRupees: l.unitPriceRupees!,
                                      gstPct: l.gstPct,
                                    ))
                                .toList();

                            final id = await ctrl.createQuote(
                              partyId: _partyId!,
                              quoteDate: _quoteDate,
                              validTill: _validTill,
                              items: items,
                            );

                            if (!mounted) return;
                            _snack(context, 'Quotation ${id.toString().padLeft(5, '0')} saved');
                            DefaultTabController.of(context).index = 0;
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _partyField(List<PartyLite> parties, ColorScheme scheme) {
    return DropdownButtonFormField<int>(
      value: _partyId,
      items: parties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
      onChanged: (v) => setState(() => _partyId = v),
      validator: (v) => v == null ? 'Select customer' : null,
      decoration: InputDecoration(
        labelText: 'Customer *',
        filled: true,
        fillColor: scheme.surfaceVariant.withOpacity(.45),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onPick) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Text(_d(value)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2100, 12, 31),
                initialDate: value,
              );
              if (picked != null) onPick(picked);
            },
          ),
        ],
      ),
    );
  }
}

/* -------------------- lines editor (Create form) -------------------- */
class _LinesEditor extends StatelessWidget {
  const _LinesEditor({required this.lines, required this.products, required this.onChanged});
  final List<LineModel> lines;
  final List<ProductLite> products;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          // header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text('Product')),
                Expanded(flex: 2, child: Text('Qty')),
                Expanded(flex: 3, child: Text('Unit Price (₹)')),
                Expanded(flex: 2, child: Text('GST%')),
                Expanded(flex: 2, child: Text('Line Total (₹)')),
                SizedBox(width: 44),
              ],
            ),
          ),
          const Divider(height: 1),

          // rows
        //  for (int i = 0; i < lines.length; i++) _row(context, i, products),
for (int i = 0; i < lines.length; i++)
  ChangeNotifierProvider.value(
    value: lines[i],
    child: _Row(products: products, onRemove: () {
      lines.removeAt(i);
      onChanged();
    }),
  ),

          // add
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                lines.add(LineModel());
                onChanged();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Line'),
            ),
          )
        ],
      ),
    );
  }
}

class TotalsBox extends StatelessWidget {
  const TotalsBox({required this.lines, super.key});
  final List<LineModel> lines;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(lines), // listens to all LineModels
      builder: (_, __) {
        num subtotal = 0, tax = 0;
        for (final l in lines.where((e) => e.isValid)) {
          final sub = (l.unitPriceRupees ?? 0) * (l.qty ?? 0);
          final t = sub * ((l.gstPct ?? 0) / 100.0);
          subtotal += sub;
          tax += t;
        }
        final total = subtotal + tax;

        return _TotalsBoxUI(
          subtotal: subtotal,
          tax: tax,
          total: total,
        );
      },
    );
  }
}


class _TotalsBoxUI extends StatelessWidget {
  const _TotalsBoxUI({
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  final num subtotal, tax, total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _row('Subtotal:', '₹${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _row('GST:', '₹${tax.toStringAsFixed(2)}'),
          const Divider(height: 18),
          _rowBold('Total:', '₹${total.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k), Text(v)],
      );

  Widget _rowBold(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
}

Future<ProductLite?> _showProductSearch(
  BuildContext context,
  List<ProductLite> products,
) async {
  TextEditingController searchCtrl = TextEditingController();
  return showDialog<ProductLite>(
    context: context,
    builder: (context) {
      List<ProductLite> filtered = List.from(products);

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: TextField(
              controller: searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Search product...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) {
                setState(() {
                  filtered = products
                      .where((p) =>
                          p.name.toLowerCase().contains(q.toLowerCase()))
                      .toList();
                });
              },
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final p = filtered[i];
                  return ListTile(
                    title: Text(p.name),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}
class ProductSearchField extends StatefulWidget {
  final List<ProductLite> products;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const ProductSearchField({
    required this.products,
    required this.selectedId,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  late OverlayEntry _overlayEntry;
  List<ProductLite> suggestionList = [];
  bool showAll = false;

  @override
  void initState() {
    super.initState();
    controller.text = widget.products
        .firstWhere((p) => p.id == widget.selectedId, orElse: () => ProductLite(id: -1, name: '', gstPct: 0))
        .name;
    suggestionList = widget.products;
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          showAll = true;
          suggestionList = widget.products;
        });
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context)!.insert(_overlayEntry);
  }

  void _removeOverlay() {
    _overlayEntry.remove();
  }

  OverlayEntry _buildOverlay() {
    RenderBox box = context.findRenderObject() as RenderBox;
    var offset = box.localToGlobal(Offset.zero);
    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + box.size.height,
        width: box.size.width,
        child: Material(
          elevation: 2,
          child: SizedBox(
            height: 200,
            child: ListView(
              padding: EdgeInsets.zero,
              children: suggestionList.map((product) => ListTile(
                title: Text(product.name),
                onTap: () {
                  widget.onChanged(product.id);
                  controller.text = product.name;
                  focusNode.unfocus();
                },
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: 'Product',
        suffixIcon: IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            focusNode.requestFocus();
            setState(() {
              showAll = true;
              suggestionList = widget.products;
            });
          },
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onChanged: (val) {
        setState(() {
          showAll = false;
          suggestionList = widget.products.where(
            (p) => p.name.toLowerCase().contains(val.toLowerCase())
          ).toList();
          _removeOverlay();
          _showOverlay();
        });
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }
}

class _Row extends StatelessWidget {
  final List<ProductLite> products;
  final VoidCallback onRemove;

  const _Row({required this.products, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final line = context.watch<LineModel>();
    final scheme = Theme.of(context).colorScheme;

    int? productGst(int pid) => products.firstWhere((p) => p.id == pid).gstPct;
    num? productDefaultPriceR(int pid) {
      final p = products.firstWhere((e) => e.id == pid);
      final m = p.defaultPriceMinor;
      return m == null ? null : m / 100.0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;

        if (mobile) {
          // 📱 MOBILE: stacked card layout
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // product
                  DropdownButtonFormField<int>(
                    value: line.productId,
                    items: products
                        .map((p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) {
                      line.productId = v;
                      line.gstPct ??= v == null ? null : productGst(v);
                      line.unitPriceRupees ??=
                          v == null ? null : productDefaultPriceR(v);
                      line.notifyListeners();
                    },
                    decoration: InputDecoration(
                      labelText: 'Product',
                      filled: true,
                      fillColor: scheme.surfaceVariant.withOpacity(.45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // qty + unit price
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: line.qty?.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => line.setQty(int.tryParse(v)),
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            filled: true,
                            fillColor: scheme.surfaceVariant.withOpacity(.45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer<LineModel>(
                          builder: (_, line, __) => TextFormField(
                            key: ValueKey("unitPrice-${line.productId}"),
                            initialValue: line.unitPriceRupees?.toString(),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (v) =>
                                line.setUnitPrice(num.tryParse(v)),
                            decoration: InputDecoration(
                              labelText: 'Unit Price (₹)',
                              filled: true,
                              fillColor: scheme.surfaceVariant.withOpacity(.45),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // gst + total
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<LineModel>(
                          builder: (_, line, __) => TextFormField(
                            key: ValueKey("gst-${line.productId}"),
                            initialValue: line.gstPct?.toString(),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (v) =>
                                line.setGst(int.tryParse(v)),
                            decoration: InputDecoration(
                              labelText: 'GST %',
                              filled: true,
                              fillColor: scheme.surfaceVariant.withOpacity(.45),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer<LineModel>(
                          builder: (_, l, __) {
                            if (!l.isValid) return const Text('₹0.00');
                            final sub =
                                (l.unitPriceRupees! * l.qty!).toDouble();
                            final tax =
                                sub * ((l.gstPct ?? 0) / 100.0);
                            final total = sub + tax;
                            return Text(
                              'Total: ₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // remove button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Remove',
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 💻 DESKTOP/TABLET: same as your wide row
        return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // product
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<int>(
              value: line.productId,
              items: products
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (v) {
                line.productId = v;
                line.gstPct ??= v == null ? null : productGst(v);
                line.unitPriceRupees ??= v == null ? null : productDefaultPriceR(v);
                line.notifyListeners();
              },
              decoration: InputDecoration(
                hintText: 'product',
                filled: true,
                fillColor: scheme.surfaceVariant.withOpacity(.45),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // qty
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: line.qty?.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => line.setQty(int.tryParse(v)),
              decoration: InputDecoration(
                hintText: 'Qty',
                filled: true,
                fillColor: scheme.surfaceVariant.withOpacity(.45),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // unit price
   Expanded(
  flex: 3,
  child: Consumer<LineModel>(
    builder: (_, line, __) => TextFormField(
      key: ValueKey("unitPrice-${line.productId}"), // forces rebuild on product change
      initialValue: line.unitPriceRupees?.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => line.setUnitPrice(num.tryParse(v)),
      decoration: InputDecoration(
        hintText: '0.00',
        filled: true,
        fillColor: scheme.surfaceVariant.withOpacity(.45),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  ),
),


          const SizedBox(width: 8),

          // gst
        Expanded(
  flex: 2,
  child: Consumer<LineModel>(
    builder: (_, line, __) => TextFormField(
      key: ValueKey("gst-${line.productId}"), // force reset when product changes
      initialValue: line.gstPct?.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => line.setGst(int.tryParse(v)),
      decoration: InputDecoration(
        hintText: 'GST%',
        filled: true,
        fillColor: scheme.surfaceVariant.withOpacity(.45),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  ),
)
,

          const SizedBox(width: 8),

          // line total (⚡️ only this widget rebuilds!)
          Expanded(
            flex: 2,
            child: Consumer<LineModel>(
              builder: (_, l, __) {
                if (!l.isValid) return const Text('₹0.00');
                final sub = (l.unitPriceRupees! * l.qty!).toDouble();
                final tax = sub * ((l.gstPct ?? 0) / 100.0);
                final total = sub + tax;
                return Text(
                  '₹${total.toStringAsFixed(2)}',
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                );
              },
            ),
          ),

          // remove
          SizedBox(
            width: 44,
            child: IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
    );
      }
    );
  }
}

class LineModel extends ChangeNotifier {
  int? productId;
  int? qty;
  num? unitPriceRupees;
  int? gstPct;

  bool get isValid => productId != null && qty != null && unitPriceRupees != null;

  void setQty(int? value) {
    qty = value;
    notifyListeners();
  }

  void setUnitPrice(num? value) {
    unitPriceRupees = value;
    notifyListeners();
  }

  void setGst(int? value) {
    gstPct = value;
    notifyListeners();
  }
}

/* ----------------------------- helpers ----------------------------- */
void _snack(BuildContext ctx, String m) =>
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(m)));

String _d(DateTime? d) =>
    d == null ? '--' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _comma(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final fromRight = s.length - i - 1;
    buf.write(s[i]);
    if (fromRight > 0 && fromRight % 3 == 0) buf.write(',');
  }
  return buf.toString();
}
