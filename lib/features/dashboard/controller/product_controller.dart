// lib/features/products/product_controller.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

import 'package:bhago/app/data/local_database.dart';

class ProductVM {
  final int id;
  final int orgId;
  final String code;
  final String name;
  final String? unit;
  final int? gstPercent;
  final int? costMinor;
  final int? mrpMinor;
  final int? priceMinor;
  final int? minStockQty;
  final int? isActive;

  const ProductVM({
    required this.id,
    required this.orgId,
    required this.code,
    required this.name,
    required this.unit,
    required this.gstPercent,
    required this.costMinor,
    required this.mrpMinor,
    required this.priceMinor,
    required this.minStockQty,
    required this.isActive,
  });

  bool get active => (isActive ?? 1) != 0;
  String inr(int? minor) => _formatInr(minor);
  static String _formatInr(int? minor) {
    if (minor == null) return '—';
    final rupees = minor / 100.0;
    // Simple grouping (12,345). Replace with a proper Indian grouping if needed.
    return '₹${rupees.toStringAsFixed(2)}';
  }
}

class ProductController {
  /// Live list of products filtered by [q].
  static Stream<List<ProductVM>> watchProducts(AppDatabase db, int orgId, String q) {
    final like = '%${q.toLowerCase()}%';
    final sql = '''
      SELECT id, org_id, code, name, unit, gst_percent, cost_minor, mrp_minor, price_minor, min_stock_qty, is_active
      FROM products
      WHERE org_id = ? AND (
            ? = '' OR
            LOWER(code) LIKE ? OR
            LOWER(name) LIKE ?
      )
      ORDER BY name COLLATE NOCASE ASC, id DESC
    ''';

    return db
        .customSelect(
          sql,
          variables: [
            drift.Variable<int>(orgId),
            drift.Variable<String>(q),
            drift.Variable<String>(like),
            drift.Variable<String>(like),
          ],
          readsFrom: {db.products},
        )
        .watch()
        .map((rows) => rows
            .map((r) => ProductVM(
                  id: r.read<int>('id'),
                  orgId: r.read<int>('org_id'),
                  code: r.read<String>('code'),
                  name: r.read<String>('name'),
                  unit: r.readNullable<String>('unit'),
                  gstPercent: r.readNullable<int>('gst_percent'),
                  costMinor: r.readNullable<int>('cost_minor'),
                  mrpMinor: r.readNullable<int>('mrp_minor'),
                  priceMinor: r.readNullable<int>('price_minor'),
                  minStockQty: r.readNullable<int>('min_stock_qty'),
                  isActive: r.readNullable<int>('is_active'),
                ))
            .toList());
  }

  /// Create product (modal form). Returns inserted id or null if cancelled.
  static Future<int?> createProductDialog(BuildContext context, {required int orgId}) async {
    final db = context.read<AppDatabase>();

    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final gstCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final mrpCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final minStockCtrl = TextEditingController();
    bool active = true;

    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

    int? _parseInt(String s) => int.tryParse(s.trim());
    int? _rupeesToMinor(String s) {
      if (s.trim().isEmpty) return null;
      final v = double.tryParse(s.trim());
      return (v == null) ? null : (v * 100).round();
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Product'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (unique)'), validator: req),
                const SizedBox(height: 8),
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: req),
                const SizedBox(height: 8),
                TextFormField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g., PCS)')),
                const SizedBox(height: 8),
                TextFormField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GST % (e.g., 18)'),
                  keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextFormField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Cost (₹)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                TextFormField(controller: mrpCtrl, decoration: const InputDecoration(labelText: 'MRP (₹)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                TextFormField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Selling Price (₹)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                TextFormField(controller: minStockCtrl, decoration: const InputDecoration(labelText: 'Min Stock Qty'),
                  keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: (v) => active = v,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final id = await db.into(db.products).insert(
                      ProductsCompanion.insert(
                        orgId: orgId,
                        code: codeCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        unit: drift.Value(unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim()),
                        gstPercent: drift.Value(_parseInt(gstCtrl.text) ?? 0),
                        costMinor: drift.Value(_rupeesToMinor(costCtrl.text)),
                        mrpMinor: drift.Value(_rupeesToMinor(mrpCtrl.text)),
                        priceMinor: drift.Value(_rupeesToMinor(priceCtrl.text)),
                        minStockQty: drift.Value(_parseInt(minStockCtrl.text)),
                        isActive: drift.Value(active ? 1 : 0),
                        createdAt: drift.Value(DateTime.now()),
                      ),
                    );
                // Pop with success
                // ignore: use_build_context_synchronously
                Navigator.pop(context, true);
              
              } catch (e) {
                // Unique code constraint, etc.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return (ok == true) ? 1 : null; // caller doesn’t need the id right now
  }

  /// Edit product by id. Returns true if saved.
  static Future<bool?> editProductDialog(BuildContext context, {required int productId}) async {
    final db = context.read<AppDatabase>();
    final row = await (db.select(db.products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (row == null) return null;

    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: row.code);
    final nameCtrl = TextEditingController(text: row.name);
    final unitCtrl = TextEditingController(text: row.unit ?? '');
    final gstCtrl = TextEditingController(text: (row.gstPercent ?? 0).toString());
    final costCtrl = TextEditingController(text: _minorToRupeesStr(row.costMinor));
    final mrpCtrl = TextEditingController(text: _minorToRupeesStr(row.mrpMinor));
    final priceCtrl = TextEditingController(text: _minorToRupeesStr(row.priceMinor));
    final minStockCtrl = TextEditingController(text: (row.minStockQty ?? 0).toString());
    bool active = (row.isActive ?? 1) != 0;

    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
    int? _parseInt(String s) => int.tryParse(s.trim());
    int? _rupeesToMinor(String s) {
      if (s.trim().isEmpty) return null;
      final v = double.tryParse(s.trim());
      return (v == null) ? null : (v * 100).round();
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Product'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (unique)'), validator: req),
                const SizedBox(height: 8),
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: req),
                const SizedBox(height: 8),
                TextFormField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit')),
                const SizedBox(height: 8),
                TextFormField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GST %'),
                  keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextFormField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Cost (₹)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                TextFormField(controller: mrpCtrl, decoration: const InputDecoration(labelText: 'MRP (₹)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                TextFormField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Selling Price (₹)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                TextFormField(controller: minStockCtrl, decoration: const InputDecoration(labelText: 'Min Stock Qty'),
                  keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: (v) => active = v,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await (db.update(db.products)..where((t) => t.id.equals(productId))).write(
                  ProductsCompanion(
                    code: drift.Value(codeCtrl.text.trim()),
                    name: drift.Value(nameCtrl.text.trim()),
                    unit: drift.Value(unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim()),
                    gstPercent: drift.Value(_parseInt(gstCtrl.text) ?? 0),
                    costMinor: drift.Value(_rupeesToMinor(costCtrl.text)),
                    mrpMinor: drift.Value(_rupeesToMinor(mrpCtrl.text)),
                    priceMinor: drift.Value(_rupeesToMinor(priceCtrl.text)),
                    minStockQty: drift.Value(_parseInt(minStockCtrl.text)),
                    isActive: drift.Value(active ? 1 : 0),
                    updatedAt: drift.Value(DateTime.now()),
                  ),
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return ok == true;
  }

  /// Delete with confirmation.
  static Future<bool?> deleteProduct(BuildContext context, {required int productId}) async {
    final db = context.read<AppDatabase>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          )
        ],
      ),
    );
    if (ok == true) {
      try {
        await (db.delete(db.products)..where((t) => t.id.equals(productId))).go();
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot delete (in use?): $e')),
        );
      }
    }
    return false;
  }

  static String _minorToRupeesStr(int? minor) {
  if (minor == null) return '';
  final rupees = minor / 100.0;
  // if no decimal part → drop ".00"
  if (rupees == rupees.truncateToDouble()) {
    return rupees.toInt().toString();
  }
  return rupees.toStringAsFixed(2);
}
}
