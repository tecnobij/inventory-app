import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:collection/collection.dart';

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

/// ------------ View Models ------------
class SalesOrderVM {
  final int id;
  final DateTime? date;
  final SoStatus? status;
  final String customer;
  final String warehouse;
  final int itemsCount;
  final int totalMinor;

  SalesOrderVM({
    required this.id,
    required this.date,
    required this.status,
    required this.customer,
    required this.warehouse,
    required this.itemsCount,
    required this.totalMinor,
  });

  String get soNo => 'SO-${id.toString().padLeft(6, '0')}';
}

class InvoiceVM {
  final int id;
  final DateTime? date;
  final InvoiceStatus? status;
  final int? soId;
  final String customer;
  final int totalMinor;

  InvoiceVM({
    required this.id,
    required this.date,
    required this.status,
    required this.soId,
    required this.customer,
    required this.totalMinor,
  });

  String get invNo => 'INV-${id.toString().padLeft(6, '0')}';
  String get soNo  => soId == null ? '-' : 'SO-${soId!.toString().padLeft(6, '0')}';
}

/// ------------ Create SO input ------------
class SoItemInput {
  final int productId;
  final int qty;
  final int unitPriceMinor;
  const SoItemInput({
    required this.productId,
    required this.qty,
    required this.unitPriceMinor,
  });
}

/// ------------ Controller ------------
class SalesDispatchController extends ChangeNotifier {
  final AppDatabase db;
  final SettingsProvider settings;

  SalesDispatchController({
    required this.db,
    required this.settings,
  });

  // local search state (independent for SO & Invoices)
  String _soQuery = '';
  String _invQuery = '';

  void setSoQuery(String q) {
    _soQuery = q.trim().toLowerCase();
    notifyListeners();
  }

  void setInvQuery(String q) {
    _invQuery = q.trim().toLowerCase();
    notifyListeners();
  }

  bool get ready => settings.loaded && settings.onboarded && settings.orgId != null;
  int get orgId => settings.orgId!;

  // ---------- Streams ----------
  Stream<List<SalesOrderVM>> watchSalesOrders() {
    final q = _soQuery;
    final like = '%$q%';
    final sql = '''
      SELECT so.id,
             so.so_date,
             so.status,
             so.total_minor,
             p.name   AS party_name,
             w.name   AS wh_name,
             (SELECT COUNT(*) FROM sales_order_items si WHERE si.sales_order_id = so.id) AS items_count
      FROM sales_orders so
      JOIN parties   p ON p.id = so.party_id
      JOIN warehouses w ON w.id = so.warehouse_id
      WHERE so.org_id = ?
        AND (? = '' OR
             LOWER(p.name) LIKE ? OR
             CAST(so.id AS TEXT) LIKE ?)
      ORDER BY so.so_date DESC NULLS LAST, so.id DESC
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
          readsFrom: {db.salesOrders, db.parties, db.warehouses, db.salesOrderItems},
        )
        .watch()
        .map((rows) {
          return rows.map((r) {
            return SalesOrderVM(
              id: r.read<int>('id'),
              date: r.readNullable<DateTime>('so_date'),
              status: r.readNullable<int>('status') == null
                  ? null
                  : SoStatus.values[r.read<int>('status')],
              totalMinor: r.readNullable<int>('total_minor') ?? 0,
              customer: r.read<String>('party_name'),
              warehouse: r.read<String>('wh_name'),
              itemsCount: r.read<int>('items_count'),
            );
          }).toList();
        });
  }

  Stream<List<InvoiceVM>> watchInvoices() {
    final q = _invQuery;
    final like = '%$q%';
    final sql = '''
      SELECT inv.id,
             inv.invoice_date,
             inv.status,
             inv.sales_order_id,
             inv.total_minor,
             p.name AS party_name
      FROM invoices inv
      JOIN parties p ON p.id = inv.party_id
      WHERE inv.org_id = ?
        AND (? = '' OR
             LOWER(p.name) LIKE ? OR
             CAST(inv.id AS TEXT) LIKE ? OR
             CAST(inv.sales_order_id AS TEXT) LIKE ?)
      ORDER BY inv.invoice_date DESC NULLS LAST, inv.id DESC
    ''';

    return db
        .customSelect(
          sql,
          variables: [
            drift.Variable<int>(orgId),
            drift.Variable<String>(q),
            drift.Variable<String>(like),
            drift.Variable<String>(like),
            drift.Variable<String>(like),
          ],
          readsFrom: {db.invoices, db.parties},
        )
        .watch()
        .map((rows) {
          return rows.map((r) {
            return InvoiceVM(
              id: r.read<int>('id'),
              date: r.readNullable<DateTime>('invoice_date'),
              status: r.readNullable<int>('status') == null
                  ? null
                  : InvoiceStatus.values[r.read<int>('status')],
              soId: r.readNullable<int>('sales_order_id'),
              totalMinor: r.readNullable<int>('total_minor') ?? 0,
              customer: r.read<String>('party_name'),
            );
          }).toList();
        });
  }

  // ---------- Dropdown data ----------
  Future<List<Party>> fetchCustomers() async {
    final q = db.select(db.parties)
      ..where((t) => t.orgId.equals(orgId));
    // If you want only customers & both:
    // ..where((t) => t.orgId.equals(orgId) & (t.partyType.equals(PartyType.customer) | t.partyType.equals(PartyType.both)));
    return q.get();
  }

  Future<List<Warehouse>> fetchWarehouses() async {
    final q = db.select(db.warehouses)..where((t) => t.orgId.equals(orgId));
    return q.get();
  }

  Future<List<Product>> fetchProducts() async {
    final q = db.select(db.products)..where((t) => t.orgId.equals(orgId) & ((t.isActive.isNull()) | t.isActive.equals(1)));
    return q.get();
  }

  Future<int?> defaultGstPct() async {
    final row = await (db.select(db.appSettings)..where((t) => t.orgId.equals(orgId))).getSingleOrNull();
    return row?.defaultGstPct;
  }

  // ---------- Create Sales Order ----------
  Future<int> createSalesOrder({
    required int partyId,
    required int warehouseId,
    required DateTime soDate,
    required List<SoItemInput> items,
  }) async {
    assert(items.isNotEmpty, 'At least one item required');

    // Map productId -> Product (for gst, etc.)
    final ids = items.map((e) => e.productId).toSet().toList();
    final prods = await (db.select(db.products)..where((t) => t.id.isIn(ids))).get();
    final prodMap = {for (final p in prods) p.id: p};

    final defGst = await defaultGstPct() ?? 0;

    int subtotal = 0;
    int tax = 0;

    for (final it in items) {
      final line = it.qty * it.unitPriceMinor;
      subtotal += line;
      final gst = (prodMap[it.productId]?.gstPercent ?? defGst);
      tax += (line * gst ~/ 100);
    }

    final total = subtotal + tax;

    return await db.transaction(() async {
      final soId = await db.into(db.salesOrders).insert(
            SalesOrdersCompanion.insert(
              orgId: orgId,
              partyId: partyId,
              warehouseId: warehouseId,
              soDate: drift.Value(soDate),
              status: const drift.Value(SoStatus.confirmed),
              subtotalMinor: drift.Value(subtotal),
              taxMinor: drift.Value(tax),
              totalMinor: drift.Value(total),
              createdAt: drift.Value(DateTime.now()),
            ),
          );

      // Items
      for (final it in items) {
        final line = it.qty * it.unitPriceMinor;
        await db.into(db.salesOrderItems).insert(
              SalesOrderItemsCompanion.insert(
                salesOrderId: soId,
                productId: it.productId,
                qty: it.qty,
                unitPriceMinor: it.unitPriceMinor,
                lineTotalMinor: line,
                createdAt: drift.Value(DateTime.now()),
              ),
            );
      }

      return soId;
    });
  }

  // Helpers
  String inr(int minor) => '₹${_comma(minor)}';
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
}
