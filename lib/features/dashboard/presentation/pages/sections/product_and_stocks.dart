// lib/features/products/product_page.dart
import 'package:bhago/features/dashboard/controller/product_controller.dart';
import 'package:drift/drift.dart' as drift;
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
                   _AlertsTab(orgId: s.orgId!),
_StockMovementsTab(orgId: s.orgId!),

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

/* ---------------------------------- ALERTS (LOW STOCK) --------------------------------- */

class AlertVM {
  final int productId;
  final String name;
  final int onHand;
  final int minStock;
  AlertVM({
    required this.productId,
    required this.name,
    required this.onHand,
    required this.minStock,
  });
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({required this.orgId});
  final int orgId;

  Stream<List<AlertVM>> _watchLowStock(AppDatabase db, int orgId) {
    final sql = '''
      SELECT 
        p.id AS product_id,
        p.name AS name,
        COALESCE(p.min_stock_qty, 0) AS min_stock,
        COALESCE(SUM(ps.qty), 0) AS onhand
      FROM products p
      LEFT JOIN product_stocks ps ON ps.product_id = p.id
      WHERE p.org_id = ?
        AND COALESCE(p.min_stock_qty, 0) > 0
      GROUP BY p.id
      HAVING COALESCE(SUM(ps.qty), 0) < COALESCE(p.min_stock_qty, 0)
      ORDER BY (COALESCE(p.min_stock_qty,0) - COALESCE(SUM(ps.qty),0)) DESC
    ''';

    return db
        .customSelect(
          sql,
          variables: [drift.Variable<int>(orgId)],
          readsFrom: {db.products, db.productStocks},
        )
        .watch()
        .map((rows) => rows
            .map((r) => AlertVM(
                  productId: r.read<int>('product_id'),
                  name: r.read<String>('name'),
                  onHand: r.read<int>('onhand'),
                  minStock: r.read<int>('min_stock'),
                ))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    return StreamBuilder<List<AlertVM>>(
      stream: _watchLowStock(db, orgId),
      builder: (context, snap) {
        final list = snap.data ?? const <AlertVM>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (snap.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (list.isEmpty && snap.connectionState != ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No low-stock items.'),
                    ),
                  if (list.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.grey.shade50,
                          child: Row(children: const [
                            Expanded(flex: 5, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('On Hand', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Min Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                          ]),
                        ),
                        for (final a in list)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(children: [
                              Expanded(flex: 5, child: Text(a.name)),
                              Expanded(flex: 2, child: Text('${a.onHand}')),
                              Expanded(flex: 2, child: Text('${a.minStock}')),
                            ]),
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
}


class _LowStockVM {
  final int productId;
  final String name;
  final String code;
  final int minStockQty;
  final int stockQty;

  const _LowStockVM({
    required this.productId,
    required this.name,
    required this.code,
    required this.minStockQty,
    required this.stockQty,
  });

  int get deficit => (minStockQty - stockQty).clamp(0, 1 << 31);
}

class _LowStockTile extends StatefulWidget {
  const _LowStockTile({required this.vm, required this.orgId});
  final _LowStockVM vm;
  final int orgId;

  @override
  State<_LowStockTile> createState() => _LowStockTileState();
}

class _LowStockTileState extends State<_LowStockTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final deficit = widget.vm.deficit;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // product + code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.vm.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(widget.vm.code, style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _pill('Stock ${widget.vm.stockQty}'),
                      _pill('Min ${widget.vm.minStockQty}'),
                      _pill('Short by $deficit'),
                    ]),
                  ],
                ),
              ),
              IconButton(
                tooltip: _expanded ? 'Hide per-warehouse' : 'Show per-warehouse',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            _PerWarehouseBreakdown(productId: widget.vm.productId, orgId: widget.orgId),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}

class _PerWarehouseBreakdown extends StatelessWidget {
  const _PerWarehouseBreakdown({required this.productId, required this.orgId});
  final int productId;
  final int orgId;

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    return FutureBuilder<List<_WhQty>>(
      future: _load(db, orgId, productId),
      builder: (context, snap) {
        final rows = snap.data ?? const <_WhQty>[];
        if (rows.isEmpty) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text('No stock recorded per-warehouse.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }
        return Column(
          children: [
            for (final w in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(w.warehouse)),
                    Text('${w.qty}'),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<List<_WhQty>> _load(AppDatabase db, int orgId, int productId) async {
    final sql = '''
      SELECT w.name AS wname, IFNULL(ps.qty, 0) AS qty
      FROM warehouses w
      LEFT JOIN product_stocks ps 
        ON ps.warehouse_id = w.id AND ps.product_id = ?
      WHERE w.org_id = ?
      ORDER BY w.name ASC
    ''';
    final rows = await db.customSelect(
      sql,
      variables: [drift.Variable<int>(productId), drift.Variable<int>(orgId)],
      readsFrom: {db.warehouses, db.productStocks},
    ).get();

    return rows
        .map((r) => _WhQty(warehouse: r.read<String>('wname'), qty: r.read<int>('qty')))
        .toList();
  }
}

class _WhQty {
  final String warehouse;
  final int qty;
  const _WhQty({required this.warehouse, required this.qty});
}

/* ---------------------------- STOCK MOVEMENTS TAB --------------------------- */

class MoveVM {
  final int id;
  final String product;
  final String warehouse;
  final int qty;
  final MoveType moveType;
  final DateTime? createdAt;
  MoveVM({
    required this.id,
    required this.product,
    required this.warehouse,
    required this.qty,
    required this.moveType,
    required this.createdAt,
  });
}

class _StockMovementsTab extends StatelessWidget {
  const _StockMovementsTab({required this.orgId});
  final int orgId;

  Stream<List<MoveVM>> _watchMoves(AppDatabase db, int orgId) {
    final sql = '''
      SELECT 
        im.id AS id,
        p.name AS product,
        w.name AS warehouse,
        im.qty AS qty,
        im.move_type AS move_type,
        im.created_at AS created_at
      FROM inventory_moves im
      JOIN products p   ON p.id = im.product_id
      JOIN warehouses w ON w.id = im.warehouse_id
      WHERE p.org_id = ?
      ORDER BY im.created_at DESC, im.id DESC
      LIMIT 500
    ''';

    return db
        .customSelect(
          sql,
          variables: [drift.Variable<int>(orgId)],
          readsFrom: {db.inventoryMoves, db.products, db.warehouses},
        )
        .watch()
        .map((rows) => rows.map((r) {
              final mtIndex = r.read<int>('move_type'); // stored via EnumIndexConverter
              return MoveVM(
                id: r.read<int>('id'),
                product: r.read<String>('product'),
                warehouse: r.read<String>('warehouse'),
                qty: r.read<int>('qty'),
                moveType: MoveType.values[mtIndex],
                createdAt: r.readNullable<DateTime>('created_at'),
              );
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final ov = Theme.of(context).colorScheme.onSurfaceVariant;

    String _label(MoveType t) {
      switch (t) {
        case MoveType.in_:
          return 'IN';
        case MoveType.out_:
          return 'OUT';
        case MoveType.adjust:
          return 'ADJUST';
      }
    }

    return StreamBuilder<List<MoveVM>>(
      stream: _watchMoves(db, orgId),
      builder: (context, snap) {
        final list = snap.data ?? const <MoveVM>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (snap.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (list.isEmpty && snap.connectionState != ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No movements yet.'),
                    ),
                  if (list.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.grey.shade50,
                          child: Row(children: const [
                            Expanded(flex: 3, child: Text('Date/Time', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text('Warehouse', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 5, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                          ]),
                        ),
                        for (final m in list)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(children: [
                              Expanded(
                                flex: 3,
                                child: Text(m.createdAt?.toString().split('.').first ?? '-',
                                    style: TextStyle(color: ov)),
                              ),
                              Expanded(flex: 3, child: Text(m.warehouse)),
                              Expanded(flex: 5, child: Text(m.product)),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: Text(
                                    _label(m.moveType),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Expanded(flex: 2, child: Text('${m.qty}')),
                            ]),
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
}




/* ---------------------------- STOCK MOVEMENTS TAB --------------------------- */


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
