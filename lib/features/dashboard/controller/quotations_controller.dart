// lib/features/quotations/controller/quotations_controller.dart
import 'dart:async';
import 'package:bhago/features/dashboard/presentation/pages/quotation/quotation_detail_page.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

// ----- Public input DTO so UI can pass items -----
class CreateItem {
  final int productId;
  final int qty;
  final int? gstPct;         // optional override; falls back to product or settings
  final num unitPriceRupees; // UI sends rupees; controller converts to paise

  CreateItem({
    required this.productId,
    required this.qty,
    required this.unitPriceRupees,
    this.gstPct,
  });
}

class QuoteVM {
  final int id;
  final String docNo;       // QU-00001
  final String partyName;
  final DateTime? quoteDate;
  final DateTime? validTill;
  final QuoteStatus status;
  final int totalMinor;

  QuoteVM({
    required this.id,
    required this.docNo,
    required this.partyName,
    required this.quoteDate,
    required this.validTill,
    required this.status,
    required this.totalMinor,
  });
}

class ProductLite {
  final int id;
  final String name;
  final int? gstPct;
  final int? defaultPriceMinor;
  ProductLite({
    required this.id,
    required this.name,
    this.gstPct,
    this.defaultPriceMinor,
  });
}

class PartyLite {
  final int id;
  final String name;
  PartyLite({required this.id, required this.name});
}

class QuotationsController extends ChangeNotifier {
  final AppDatabase db;
  final SettingsProvider settings;

  QuotationsController({required this.db, required this.settings});

  String _q = '';
  String get q => _q;
  void setQuery(String v) {
    _q = v.trim().toLowerCase();
    notifyListeners();
  }

  // ---------- Streams ----------
  Stream<List<QuoteVM>> watchQuotes() {
    final orgId = settings.orgId;
    if (orgId == null) return const Stream.empty();

    final like = '%$_q%';
    final sql = '''
      SELECT q.id,
             q.quote_date,
             q.valid_till,
             COALESCE(q.status, 0) AS status,
             COALESCE(q.total_minor, 0) AS total_minor,
             COALESCE(p.name, '') AS party_name
      FROM quotations q
      JOIN parties p ON p.id = q.party_id
      WHERE q.org_id = ?
        AND (? = '' OR
             LOWER(p.name) LIKE ? OR
             CAST(q.id AS TEXT) LIKE ?)
      ORDER BY q.id DESC
    ''';

    return db
        .customSelect(
          sql,
          variables: [
            drift.Variable<int>(orgId),
            drift.Variable<String>(_q),
            drift.Variable<String>(like),
            drift.Variable<String>(like),
          ],
          readsFrom: {db.quotations, db.parties},
        )
        .watch()
        .map((rows) {
          return rows.map((r) {
            final id = r.read<int>('id');
            final statusIdx = r.read<int>('status');
            return QuoteVM(
              id: id,
              docNo: _formatDoc('QU', id),
              partyName: r.read<String>('party_name'),
              quoteDate: r.readNullable<DateTime>('quote_date'),
              validTill: r.readNullable<DateTime>('valid_till'),
              status: QuoteStatus.values[statusIdx],
              totalMinor: r.read<int>('total_minor'),
            );
          }).toList();
        });
  }
Future<QuoteDetailVM> fetchQuoteDetails(int quoteId) async {
  // Implement based on your database structure
  // Sample implementation:

final query = db.select(db.quotations);
query.where((q) => q.id.equals(quoteId));
final quote = await query.getSingle();



  final party = await (db.select(db.parties)
    ..where((p) => p.id.equals(quote.partyId)))
    .getSingle();
    
  final items = await (db.select(db.quotationItems).join([
    drift.innerJoin(db.products, db.products.id.equalsExp(db.quotationItems.productId))
  ])..where(db.quotationItems.quotationId.equals(quoteId)))
    .map((row) {
      final item = row.readTable(db.quotationItems);
      final product = row.readTable(db.products);
      return QuoteItemVM(
        id: item.id,
        productName: product.name,
        qty: item.qty,
        unitPriceMinor: item.unitPriceMinor,
      //  gstPct: item,
      );
    }).get();
    
  return QuoteDetailVM(
    id: quote.id,
    docNo: 'QT${quote.id.toString().padLeft(5, '0')}',
    partyName: party.name,
    partyAddress: party.address,
    quoteDate: quote.quoteDate!,
    validTill: quote.validTill!,
    createdAt: quote.createdAt!,
    status: quote.status!,
    subtotalMinor: quote.subtotalMinor!,
    taxMinor: quote.taxMinor!,
    totalMinor: quote.totalMinor!,
    items: items,
  );
}

Future<int> convertQuoteToSalesOrder(int quoteId) async {
  // Implementation depends on your sales order structure
  // Return the new sales order ID
  return 0; // Placeholder
}

Future<void> updateQuoteStatus(int quoteId, QuoteStatus status) async {
  await (db.update(db.quotations)
    ..where((q) => q.id.equals(quoteId)))
    .write(QuotationsCompanion(
      status: drift.Value(status),
      updatedAt: drift.Value(DateTime.now()),
    ));
}

  Future<List<PartyLite>> fetchParties() async {
    final orgId = settings.orgId;
    if (orgId == null) return [];
    final list =
        await (db.select(db.parties)..where((t) => t.orgId.equals(orgId))).get();
    return list.map((p) => PartyLite(id: p.id, name: p.name)).toList();
  }

  Future<List<ProductLite>> fetchProducts() async {
    final orgId = settings.orgId;
    if (orgId == null) return [];
    final list =
        await (db.select(db.products)..where((t) => t.orgId.equals(orgId))).get();

    return list.map((p) {
      final defPrice = p.priceMinor ?? p.mrpMinor ?? p.costMinor;
      return ProductLite(
        id: p.id,
        name: p.name,
        gstPct: p.gstPercent,
        defaultPriceMinor: defPrice,
      );
    }).toList();
  }

  // ---------- Create Quote ----------
  Future<int> createQuote({
    required int partyId,
    required DateTime quoteDate,
    required DateTime validTill,
    required List<CreateItem> items, // ✅ give the param a name
  }) async {
    final orgId = settings.orgId!;
    return await db.transaction(() async {
      int subtotal = 0;
      int tax = 0;

      // ✅ iterate over the variable, not the type
      for (final it in items) {
        final unitMinor = _toMinor(it.unitPriceRupees);
        final line = unitMinor * it.qty;
        subtotal += line;

        // prefer per-item gst, then product default, then app setting
        final gstPct = it.gstPct ??0;
        tax += ((line * gstPct) / 100).round();
      }
      final total = subtotal + tax;

      final qId = await db.into(db.quotations).insert(
        QuotationsCompanion.insert(
          orgId: orgId,
          partyId: partyId,
          quoteDate: drift.Value(quoteDate),
          validTill: drift.Value(validTill),
          status: drift.Value(QuoteStatus.open),
          subtotalMinor: drift.Value(subtotal),
          taxMinor: drift.Value(tax),
          totalMinor: drift.Value(total),
          createdAt: drift.Value(DateTime.now()),
        ),
      );

      // items
      for (final it in items) {
        final unitMinor = _toMinor(it.unitPriceRupees);
        final line = unitMinor * it.qty;
        await db.into(db.quotationItems).insert(
          QuotationItemsCompanion.insert(
            quotationId: qId,
            productId: it.productId,
            qty: it.qty,
            unitPriceMinor: unitMinor,
            lineTotalMinor: line,
            createdAt: drift.Value(DateTime.now()),
          ),
        );
      }

      return qId;
    });
  }

  // Helpers
  int _toMinor(num rupees) => (rupees * 100).round();
  String _formatDoc(String prefix, int id) =>
      '$prefix-${id.toString().padLeft(5, '0')}';
}
