// lib/features/dashboard/controller/dashboard_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

class DashboardMetrics {
  final int products;
  final int suppliers;       // Parties with type vendor or both
  final int stockInToday;    // Qty summed from InventoryMoves (IN) today
  final int stockOutToday;   // Qty summed from InventoryMoves (OUT) today
  final int lowStockAlerts;  // Products where onhand < min_stock_qty

  const DashboardMetrics({
    required this.products,
    required this.suppliers,
    required this.stockInToday,
    required this.stockOutToday,
    required this.lowStockAlerts,
  });
}

class RecentMoveVM {
  final String kind;         // "IN" | "OUT" | "ADJ"
  final String productName;
  final String sku;          // products.code
  final int qty;
  final DateTime? at;
  const RecentMoveVM({
    required this.kind,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.at,
  });
}

class DashboardController extends ChangeNotifier {
  final AppDatabase db;
  final SettingsProvider settings;

  DashboardController({required this.db, required this.settings});

  /// Stream a single row with all metrics (reacts to changes in products/parties/moves/stocks).
  Stream<DashboardMetrics> watchMetrics() {
    final orgId = settings.orgId;
    if (orgId == null) return const Stream.empty();

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // One SQL returning 5 numbers; watches the 4 tables we care about.
    final sql = '''
      SELECT
        (SELECT COUNT(*) FROM products pr WHERE pr.org_id = ?) AS products_count,
        (SELECT COUNT(*) FROM parties pa
          WHERE pa.org_id = ?
            AND pa.party_type IN (${PartyType.vendor.index}, ${PartyType.both.index})
        ) AS suppliers_count,

        (SELECT COALESCE(SUM(m.qty), 0)
           FROM inventory_moves m
           JOIN products p ON p.id = m.product_id
          WHERE p.org_id = ?
            AND m.created_at >= ?
            AND m.created_at <  ?
            AND m.move_type = ${MoveType.in_.index}
        ) AS stock_in_today,

        (SELECT COALESCE(SUM(m.qty), 0)
           FROM inventory_moves m
           JOIN products p ON p.id = m.product_id
          WHERE p.org_id = ?
            AND m.created_at >= ?
            AND m.created_at <  ?
            AND m.move_type = ${MoveType.out_.index}
        ) AS stock_out_today,

        (SELECT COUNT(*) FROM (
            SELECT pr.id, pr.min_stock_qty, COALESCE(SUM(ps.qty), 0) AS onhand
              FROM products pr
              LEFT JOIN product_stocks ps ON ps.product_id = pr.id
             WHERE pr.org_id = ?
             GROUP BY pr.id
        ) t
         WHERE t.min_stock_qty IS NOT NULL AND t.onhand < t.min_stock_qty
        ) AS low_stock_count
      ;
    ''';

    final vars = [
      // products_count
      drift.Variable<int>(orgId),
      // suppliers_count
      drift.Variable<int>(orgId),
      // stock_in_today
      drift.Variable<int>(orgId),
      drift.Variable<DateTime>(dayStart),
      drift.Variable<DateTime>(dayEnd),
      // stock_out_today
      drift.Variable<int>(orgId),
      drift.Variable<DateTime>(dayStart),
      drift.Variable<DateTime>(dayEnd),
      // low_stock_count
      drift.Variable<int>(orgId),
    ];

    return db
        .customSelect(
          sql,
          variables: vars,
          readsFrom: {
            db.products,
            db.parties,
            db.inventoryMoves,
            db.productStocks,
          },
        )
        .watchSingle()
        .map((row) => DashboardMetrics(
              products: row.read<int>('products_count'),
              suppliers: row.read<int>('suppliers_count'),
              stockInToday: row.read<int>('stock_in_today'),
              stockOutToday: row.read<int>('stock_out_today'),
              lowStockAlerts: row.read<int>('low_stock_count'),
            ));
  }

  /// Recent inventory movements, newest first.
  Stream<List<RecentMoveVM>> watchRecentMoves({int limit = 6}) {
    final orgId = settings.orgId;
    if (orgId == null) return const Stream.empty();

    final sql = '''
      SELECT m.move_type, m.qty, m.created_at,
             p.name AS product_name, p.code AS code
        FROM inventory_moves m
        JOIN products p ON p.id = m.product_id
       WHERE p.org_id = ?
       ORDER BY m.created_at DESC NULLS LAST, m.id DESC
       LIMIT ?
    ''';

    return db
        .customSelect(
          sql,
          variables: [
            drift.Variable<int>(orgId),
            drift.Variable<int>(limit),
          ],
          readsFrom: {db.inventoryMoves, db.products},
        )
        .watch()
        .map((rows) {
          return rows.map((r) {
            final mt = r.read<int>('move_type');
            final kind = (mt == MoveType.in_.index)
                ? 'IN'
                : (mt == MoveType.out_.index)
                    ? 'OUT'
                    : 'ADJ';
            return RecentMoveVM(
              kind: kind,
              productName: r.read<String>('product_name'),
              sku: r.read<String>('code'),
              qty: r.read<int>('qty'),
              at: r.readNullable<DateTime>('created_at'),
            );
          }).toList();
        });
  }
}
