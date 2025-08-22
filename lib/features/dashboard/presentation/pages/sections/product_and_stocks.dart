import 'package:flutter/material.dart';

/// Entry widget you can push or place inside your dashboard body.
class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page title row (kept simple so it embeds anywhere)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  'Products & Stock',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),

              // Segmented tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SegmentedTabs(
                  tabs: const [
                    (Icons.widgets_outlined, 'Products'),
                    (Icons.notifications_none_outlined, 'Alerts'),
                    (Icons.swap_horiz_outlined, 'Stock Movements'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tabs content
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _ProductsTab(),
                    _AlertsTab(),
                    _StockMovementsTab(),
                  ],
                ),
              ),

              // Bottom hint (optional; remove if not needed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  'Ctrl+K for quick search • Alt+N for new item',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                   TABS                                      */
/* -------------------------------------------------------------------------- */

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final _searchCtrl = TextEditingController();

  // Demo data
  final List<_Product> _data = [
    _Product(
      name: 'Wireless Headphones',
      sku: 'SKU–001',
      unit: 'PCS',
      cost: '₹2,500',
      mrp: '₹3,500',
      gst: '18%',
      minStock: 10,
      inStock: 45,
      active: true,
    ),
    _Product(
      name: 'USB Cable Type-C',
      sku: 'SKU–045',
      unit: 'PCS',
      cost: '₹200',
      mrp: '₹350',
      gst: '18%',
      minStock: 50,
      inStock: 8,
      active: true,
    ),
    _Product(
      name: 'Laptop Stand Adjustable',
      sku: 'SKU–012',
      unit: 'PCS',
      cost: '₹1,200',
      mrp: '₹1,800',
      gst: '18%',
      minStock: 5,
      inStock: 25,
      active: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1024;

    // filter by search (name or SKU)
    final q = _searchCtrl.text.trim().toLowerCase();
    final items = _data
        .where((p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q))
        .toList();

    // any low stock?
    final lowCount =
        items.where((p) => p.inStock < p.minStock).toList().length;

    InputDecoration soft(String hint, {IconData? leading}) => InputDecoration(
          hintText: hint,
          prefixIcon: leading != null ? Icon(leading) : null,
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(.5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top row: search + filters + alerts chip + add product
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 460),
              child: TextField(
                controller: _searchCtrl,
                decoration: soft('Search SKU or Name...', leading: Icons.search),
                onChanged: (_) => setState(() {}),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.tune),
              label: const Text('Filters'),
              style: _outlinedGrey(context),
            ),
            if (lowCount > 0)
              FilledButton.tonalIcon(
                onPressed: () => DefaultTabController.of(context).index = 1,
                icon: const Icon(Icons.warning_amber_rounded),
                label: Text('Low-stock alerts: $lowCount'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE4E2),
                  foregroundColor: const Color(0xFFB42318),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table/card container
        _SectionCard(
          child: isWide
              ? _ProductsTableWide(items: items)
              : _ProductsListNarrow(items: items),
        ),
      ],
    );
  }

  ButtonStyle _outlinedGrey(BuildContext context) => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

class _ProductsTableWide extends StatelessWidget {
  const _ProductsTableWide({required this.items});
  final List<_Product> items;

  @override
  Widget build(BuildContext context) {
    final grey = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget head(String t, {int flex = 1}) =>
        Expanded(flex: flex, child: Text(t, style: TextStyle(color: grey)));

    Widget row(_Product p) {
      final low = p.inStock < p.minStock;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Product cell with tiny thumbnail
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
                Expanded(flex: 2, child: Text(p.sku)),
                Expanded(flex: 2, child: Text(p.unit)),
                Expanded(flex: 2, child: Text(p.cost)),
                Expanded(flex: 2, child: Text(p.mrp)),
                Expanded(flex: 2, child: Text(p.gst)),
                Expanded(flex: 2, child: Text('${p.minStock}')),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _countPill(
                      p.inStock,
                      color: low ? const Color(0xFFEF4444) : Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _statusPill(p.active),
                  ),
                ),
                // actions
                SizedBox(
                  width: 96,
                  child: Row(
                    children: [
                      IconButton(
                          tooltip: 'Edit',
                          onPressed: () {},
                          icon: const Icon(Icons.edit_outlined)),
                      IconButton(
                          tooltip: 'Delete',
                          onPressed: () {},
                          icon: const Icon(Icons.delete_outline)),
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
        // header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              head('Product', flex: 4),
              head('SKU', flex: 2),
              head('Unit', flex: 2),
              head('Cost', flex: 2),
              head('MRP', flex: 2),
              head('GST%', flex: 2),
              head('Min Stock', flex: 2),
              head('In Stock', flex: 2),
              head('Status', flex: 2),
              const SizedBox(width: 96, child: Text('Actions')),
            ],
          ),
        ),
        const Divider(height: 1),
        // rows
        for (final p in items) row(p),
      ],
    );
  }
}

class _ProductsListNarrow extends StatelessWidget {
  const _ProductsListNarrow({required this.items});
  final List<_Product> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final p in items) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // thumbnail
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
                  // texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(p.sku,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _countPill(
                              p.inStock,
                              color: (p.inStock < p.minStock)
                                  ? const Color(0xFFEF4444)
                                  : Colors.grey,
                            ),
                            _statusPill(p.active),
                            _chip('GST ${p.gst}'),
                            _chip(p.unit),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // actions
                  Column(
                    children: [
                      IconButton(
                          tooltip: 'Edit',
                          onPressed: () {},
                          icon: const Icon(Icons.edit_outlined)),
                      IconButton(
                          tooltip: 'Delete',
                          onPressed: () {},
                          icon: const Icon(Icons.delete_outline)),
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

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD92D20)),
              const SizedBox(width: 10),
              Text('Low Stock Alerts',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Example alert card
        const _LowStockCard(
          title: 'USB Cable Type-C',
          sku: 'SKU-045',
          stockText: 'Stock: 8 (Min: 50)',
        ),
      ],
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({
    required this.title,
    required this.sku,
    required this.stockText,
  });

  final String title;
  final String sku;
  final String stockText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F6), // soft red bg
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF4C7C3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF4C7C3)),
            ),
            child: const Icon(Icons.image_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sku,
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(stockText,
                    style: const TextStyle(
                        color: Color(0xFFD92D20), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_checkout_outlined),
            label: const Text('Create PO'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockMovementsTab extends StatefulWidget {
  const _StockMovementsTab();

  @override
  State<_StockMovementsTab> createState() => _StockMovementsTabState();
}

class _StockMovementsTabState extends State<_StockMovementsTab> {
  final _searchCtrl = TextEditingController();

  final _rows = const [
    _MvRow(date: '2024-12-19', type: _MvType.inn, ref: 'PO–001', sku: 'SKU–001', qty: 50,  wh: 'Main',      by: 'John Doe'),
    _MvRow(date: '2024-12-19', type: _MvType.out, ref: 'SO–045', sku: 'SKU–045', qty: 25,  wh: 'Main',      by: 'Jane Smith'),
    _MvRow(date: '2024-12-18', type: _MvType.adj, ref: 'ADJ–012',sku: 'SKU–012', qty: -2,  wh: 'Main',      by: 'Admin'),
    _MvRow(date: '2024-12-18', type: _MvType.inn, ref: 'PO–002', sku: 'SKU–089', qty: 100, wh: 'Secondary', by: 'Mike Johnson'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    InputDecoration soft(String hint) => InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(.5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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

    Widget typeChip(_MvType t) {
      final dark = t == _MvType.inn;
      final bg = dark ? const Color(0xFF0B0B12) : const Color(0xFFEAEAEA);
      final fg = dark ? Colors.white : Colors.black87;
      final label = switch (t) { _MvType.inn => 'IN', _MvType.out => 'OUT', _MvType.adj => 'ADJ' };
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Center(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700))),
        ),
      );
    }

    Widget qtyText(int q) => Text(
          (q >= 0 ? '+' : '') + q.toString(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: q >= 0 ? const Color(0xFF12B76A) : const Color(0xFFD92D20),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Controls
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: soft('Search movements...'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filter'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Manual Adjustment'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table
        _SectionCard(
          child: isWide
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          _th(context, 'Date', flex: 2),
                          _th(context, 'Type', flex: 1),
                          _th(context, 'Reference', flex: 2),
                          _th(context, 'SKU', flex: 2),
                          _th(context, 'Quantity', flex: 2),
                          _th(context, 'Warehouse', flex: 2),
                          _th(context, 'Performed By', flex: 3),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    for (final r in _rows) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            _td(r.date, flex: 2),
                            Expanded(flex: 1, child: typeChip(r.type)),
                            _td(r.ref, flex: 2),
                            _td(r.sku, flex: 2),
                            Expanded(flex: 2, child: qtyText(r.qty)),
                            _td(r.wh, flex: 2),
                            _td(r.by, flex: 3),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  ],
                )
              : Column(
                  children: [
                    for (final r in _rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  typeChip(r.type),
                                  const SizedBox(width: 10),
                                  qtyText(r.qty),
                                  const Spacer(),
                                  Text(r.date),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _keyVal('Reference', r.ref, context),
                              _keyVal('SKU', r.sku, context),
                              _keyVal('Warehouse', r.wh, context),
                              _keyVal('Performed By', r.by, context),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
        ),
      ],
    );
  }

  Widget _th(BuildContext context, String t, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          t,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _td(String t, {int flex = 1}) => Expanded(flex: flex, child: Text(t));

  Widget _keyVal(String k, String v, BuildContext ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(k,
                  style: Theme.of(ctx)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(v)),
          ],
        ),
      );
}

/* -------------------------------------------------------------------------- */
/*                               SHARED WIDGETS                                */
/* -------------------------------------------------------------------------- */

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.tabs});
  final List<(IconData, String)> tabs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    // Wider screens get more breathing room between tabs.
    final horizontal = width >= 1100 ? 24.0 : width >= 800 ? 18.0 : 14.0;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(.45),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: TabBar(
            isScrollable: true,
            labelPadding:
                EdgeInsets.symmetric(horizontal: horizontal),
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: scheme.onSurface,
            unselectedLabelColor: scheme.onSurface,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            tabs: [
              for (final t in tabs)
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$1, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        t.$2,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
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

class _Product {
  final String name, sku, unit, cost, mrp, gst;
  final int minStock, inStock;
  final bool active;
  _Product({
    required this.name,
    required this.sku,
    required this.unit,
    required this.cost,
    required this.mrp,
    required this.gst,
    required this.minStock,
    required this.inStock,
    required this.active,
  });
}

Widget _statusPill(bool active) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );

Widget _countPill(int n, {Color color = Colors.grey}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        '$n',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );

Widget _chip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );

class _MvRow {
  final String date, ref, sku, wh, by;
  final _MvType type;
  final int qty;
  const _MvRow({
    required this.date,
    required this.type,
    required this.ref,
    required this.sku,
    required this.qty,
    required this.wh,
    required this.by,
  });
}

enum _MvType { inn, out, adj }
