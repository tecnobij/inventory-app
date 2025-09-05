// lib/features/products/product_page.dart
import 'package:bhago/features/dashboard/controller/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart';
import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';



class ProductPage extends StatefulWidget {
  const ProductPage({super.key});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    if (!s.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!s.onboarded || s.orgId == null) {
      return const Scaffold(
        body: Center(child: Text('Finish onboarding to manage products.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const SegmentedTabs(
                tabs: [
                  (Icons.widgets_outlined, 'Products'),
                  (Icons.notifications_none_outlined, 'Alerts'),
                  (Icons.swap_horiz_outlined, 'Stock Movements'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ProductsTab(orgId: s.orgId!),
                    const _AlertsTab(), // placeholder until stock ledger is wired
                    const _StockMovementsTab(), // placeholder
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

/* ------------------------------- PRODUCTS TAB ------------------------------ */

class _ProductsTab extends StatefulWidget {
  const _ProductsTab({required this.orgId});
  final int orgId;

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1024;
    final q = _searchCtrl.text.trim().toLowerCase();

    InputDecoration soft(String hint, {IconData? leading}) => InputDecoration(
          hintText: hint,
          prefixIcon: leading != null ? Icon(leading) : null,
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        );

    return StreamBuilder<List<ProductVM>>(
      stream: ProductController.watchProducts(db, widget.orgId, q),
      builder: (context, snap) {
        final items = snap.data ?? const <ProductVM>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Controls row: search + filters + add
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 260, maxWidth: 460),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: soft('Search Code or Name...', leading: Icons.search),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune),
                  label: const Text('Filters'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () async {
                    final id = await ProductController.createProductDialog(context, orgId: widget.orgId);
                    if (id != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added')));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _SectionCard(
              child: snap.connectionState == ConnectionState.waiting
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : (isWide
                      ? _ProductsTableWide(items: items)
                      : _ProductsListNarrow(items: items)),
            ),
          ],
        );
      },
    );
  }
}

class _ProductsTableWide extends StatelessWidget {
  const _ProductsTableWide({required this.items});
  final List<ProductVM> items;

  @override
  Widget build(BuildContext context) {
    final grey = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget head(String t, {int flex = 1}) =>
        Expanded(flex: flex, child: Text(t, style: TextStyle(color: grey)));

    Widget row(ProductVM p) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.image_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(p.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(p.code)),
                Expanded(flex: 2, child: Text(p.unit ?? '—')),
                Expanded(flex: 2, child: Text(p.inr(p.costMinor))),
                Expanded(flex: 2, child: Text(p.inr(p.mrpMinor))),
                Expanded(flex: 2, child: Text(p.gstPercent?.toString() ?? '—')),
                Expanded(flex: 2, child: Text('${p.minStockQty ?? 0}')),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _statusPill(p.active),
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () async {
                          final ok = await ProductController.editProductDialog(context, productId: p.id);
                          if (ok == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => ProductController.deleteProduct(context, productId: p.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              head('Product', flex: 4),
              head('Code', flex: 2),
              head('Unit', flex: 2),
              head('Cost', flex: 2),
              head('MRP', flex: 2),
              head('GST%', flex: 2),
              head('Min Stock', flex: 2),
              head('Status', flex: 2),
              const SizedBox(width: 96, child: Text('Actions')),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final p in items) row(p),
      ],
    );
  }
}

class _ProductsListNarrow extends StatelessWidget {
  const _ProductsListNarrow({required this.items});
  final List<ProductVM> items;

  @override
  Widget build(BuildContext context) {
    final ov = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      children: [
        for (final p in items) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(p.code, style: TextStyle(color: ov)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _chip(p.unit ?? '—'),
                            _chip('GST ${p.gstPercent ?? 0}%'),
                            _chip('Min ${p.minStockQty ?? 0}'),
                            _chip('MRP ${p.inr(p.mrpMinor)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () async {
                          final ok = await ProductController.editProductDialog(context, productId: p.id);
                          if (ok == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => ProductController.deleteProduct(context, productId: p.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/* ---------------------------------- ALERTS --------------------------------- */

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    // Placeholder until stock ledger is connected
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionCard(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Low stock alerts will appear here once stock balances are connected.'),
          ),
        ),
      ],
    );
  }
}

/* ---------------------------- STOCK MOVEMENTS TAB --------------------------- */

class _StockMovementsTab extends StatelessWidget {
  const _StockMovementsTab();

  @override
  Widget build(BuildContext context) {
    // Placeholder
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionCard(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Stock movements will appear here once the ledger is wired.'),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------- WIDGETS ---------------------------------- */

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

Widget _statusPill(bool active) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );

Widget _chip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
