import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

/// ------------ View Models ------------
// ---------- Add near the top (outside the class) ----------
enum LedgerKind { sale, paymentIn }

class LedgerVM {
  final DateTime? dt;
  final LedgerKind kind;
  final int? soId;
  final int? paymentId;
  final String party;
  final int amountMinor;
  final String? method;
  final String? note;

  LedgerVM({
    required this.dt,
    required this.kind,
    required this.soId,
    required this.paymentId,
    required this.party,
    required this.amountMinor,
    this.method,
    this.note,
  });
}

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
class LedgerRowVM {
  final DateTime? dt;
  final String kind;        // 'SO', 'PAYIN', 'PAYOUT'
  final int refId;
  final int debitMinor;     // increases due
  final int creditMinor;    // decreases due
  final String? note;
  LedgerRowVM({
    required this.dt,
    required this.kind,
    required this.refId,
    required this.debitMinor,
    required this.creditMinor,
    this.note,
  });

  String get refNo => kind == 'SO'
      ? 'SO-${refId.toString().padLeft(6, '0')}'
      : 'PMT-${refId.toString().padLeft(6, '0')}';
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

/// Totals for P&L / summaries
class SummaryTotals {
  final int txCount;
  final int amountMinor;
  final int uniqueParties;
  const SummaryTotals({required this.txCount, required this.amountMinor, required this.uniqueParties});
}

/// Party-wise total used in lists
class PartyTotal {
  final String partyName;
  final int txCount;
  final int amountMinor;
  const PartyTotal({required this.partyName, required this.txCount, required this.amountMinor});
}

/// Simple P&L structure
class PlTotals {
  final int revenueIn;
  final int cogsOut;
  const PlTotals({required this.revenueIn, required this.cogsOut});
  int get gross => revenueIn - cogsOut;
}

/// Stats shown in payment dialog
class PartyStats {
  final int lifetimeSales; // sum of SO totals
  final int paidIn;        // sum of incoming payments
  final int due;           // lifetimeSales - paidIn
  const PartyStats({required this.lifetimeSales, required this.paidIn, required this.due});
}

/// Sales order item VM (joined with product)
class SoLineVM {
  final String productName;
  final int qty;
  final int unitPriceMinor;
  final int gstPercent;
  final int lineTotalMinor;
  SoLineVM({
    required this.productName,
    required this.qty,
    required this.unitPriceMinor,
    required this.gstPercent,
    required this.lineTotalMinor,
  });
}

/// A payment row tied to this SO
class SoPaymentVM {
  final int id;
  final DateTime? paidAt;
  final String method;
  final int amountMinor;
  final String? note;
  SoPaymentVM({
    required this.id,
    required this.paidAt,
    required this.method,
    required this.amountMinor,
    required this.note,
  });
}

/// Header for details page
class SoHeaderVM {
  final int id;
  final DateTime? soDate;
  final SoStatus? status;
  final int subtotalMinor;
  final int taxMinor;
  final int totalMinor;

  final int partyId;
  final String partyName;
  final String? phone;
  final String? gstin;
  final String? address;
  final String? farmName;

  SoHeaderVM({
    required this.id,
    required this.soDate,
    required this.status,
    required this.subtotalMinor,
    required this.taxMinor,
    required this.totalMinor,
    required this.partyId,
    required this.partyName,
    required this.phone,
    required this.gstin,
    required this.address,
    required this.farmName,
  });
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

  bool get ready => settings.loaded && settings.onboarded && settings.orgId != null;
  int get orgId => settings.orgId!;

  // local search state (independent for SO & Invoices)
  String _soQuery = '';
  String _invQuery = '';
final Map<int, Party> _partyDrafts = {};
// in SalesDispatchController

SoStatus? _statusFromDb(int? raw) {
  if (raw == null) return null;
  if (raw < 0 || raw >= SoStatus.values.length) return null;
  return SoStatus.values[raw];
}

Future<SoHeaderVM> loadSoHeader(int soId) async {
  final row = await db.customSelect(
    '''
    SELECT
      so.id, so.so_date, so.status, so.subtotal_minor, so.tax_minor, so.total_minor,
      p.id AS party_id, p.name AS party_name, p.phone, p.gstin, p.address, p.farm_name
    FROM sales_orders so
    JOIN parties p ON p.id = so.party_id
    WHERE so.org_id = ? AND so.id = ?
    LIMIT 1
    ''',
    variables: [drift.Variable<int>(orgId), drift.Variable<int>(soId)],
    readsFrom: {db.salesOrders, db.parties},
  ).getSingleOrNull();

  if (row == null) {
    throw StateError('Sales Order $soId not found for org $orgId');
  }

  // Pick DB values first
  final partyId   = row.read<int>('party_id');
  String  name    = row.read<String>('party_name');
  String? phone   = row.readNullable<String>('phone');
  String? gstin   = row.readNullable<String>('gstin');
  String? address = row.readNullable<String>('address');
  String? farm    = row.readNullable<String>('farm_name');

  // Overlay with local draft (if any)
  final draft = partyDraftFor(partyId);
  String? _pick(String? draftVal, String? dbVal) =>
      (draftVal != null && draftVal.isNotEmpty) ? draftVal : dbVal;

  if (draft != null) {
    name    = _pick(draft.name, name) ?? name; // name is required in our model, keep DB if draft empty
    phone   = _pick(draft.phone,   phone);
    gstin   = _pick(draft.gstin,   gstin);
    address = _pick(draft.address, address);
    farm    = _pick(draft.farmName, farm);
  }

  return SoHeaderVM(
    id: row.read<int>('id'),
    soDate: row.readNullable<DateTime>('so_date'),
    status: _statusFromDb(row.readNullable<int>('status')),
    subtotalMinor: row.read<int>('subtotal_minor'),
    taxMinor: row.read<int>('tax_minor'),
    totalMinor: row.read<int>('total_minor'),
    partyId: partyId,
    partyName: name,
    phone: phone,
    gstin: gstin,
    address: address,
    farmName: farm,
  );
}


void setPartyDraft(Party draft) {
  _partyDrafts[draft.id] = draft;
  notifyListeners();
}

void clearPartyDraft(int partyId) {
  _partyDrafts.remove(partyId);
  notifyListeners();
}

Party? partyDraftFor(int partyId) => _partyDrafts[partyId];
  void setSoQuery(String q) {
    _soQuery = q.trim().toLowerCase();
    notifyListeners();
  }

  void setInvQuery(String q) {
    _invQuery = q.trim().toLowerCase();
    notifyListeners();
  }

  int? _defaultWarehouseIdCache;
  int? get defaultWarehouseId => _defaultWarehouseIdCache;

  /// Resolve and cache a default warehouse (first active one).
  Future<int?> ensureDefaultWarehouse() async {
    if (_defaultWarehouseIdCache != null) return _defaultWarehouseIdCache;
    final row = await (db.select(db.warehouses)
          ..where((t) => t.orgId.equals(orgId) &
              ((t.isActive.isNull()) | t.isActive.equals(1)))
          ..limit(1))
        .getSingleOrNull();
    _defaultWarehouseIdCache = row?.id;
    return _defaultWarehouseIdCache;
  }
Stream<List<LedgerRowVM>> watchPartyLedger(int partyId) {
  final sql = '''
    SELECT so.so_date AS dt,
           'SO'       AS kind,
           so.id      AS ref_id,
           so.total_minor AS debit,
           0          AS credit,
           NULL       AS note
    FROM sales_orders so
    WHERE so.org_id = ? AND so.party_id = ?
    UNION ALL
    SELECT pay.paid_at AS dt,
           CASE WHEN pay.direction = 0 THEN 'PAYIN' ELSE 'PAYOUT' END AS kind,
           pay.id      AS ref_id,
           CASE WHEN pay.direction = 1 THEN pay.amount_minor ELSE 0 END AS debit,
           CASE WHEN pay.direction = 0 THEN pay.amount_minor ELSE 0 END AS credit,
           pay.note    AS note
    FROM payments pay
    WHERE pay.org_id = ? AND pay.party_id = ?
    ORDER BY dt ASC, ref_id ASC
  ''';

  return db
      .customSelect(
        sql,
        variables: [
          drift.Variable<int>(orgId),
          drift.Variable<int>(partyId),
          drift.Variable<int>(orgId),
          drift.Variable<int>(partyId),
        ],
        readsFrom: {db.salesOrders, db.payments},
      )
      .watch()
      .map((rows) => rows
          .map((r) => LedgerRowVM(
                dt: r.readNullable<DateTime>('dt'),
                kind: r.read<String>('kind'),
                refId: r.read<int>('ref_id'),
                debitMinor: r.read<int>('debit'),
                creditMinor: r.read<int>('credit'),
                note: r.readNullable<String>('note'),
              ))
          .toList());
}



  // ---------- Streams (lists) ----------
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
    final list = await (db.select(db.parties)
          ..where((t) => t.orgId.equals(orgId)))
        .get();

    return list
        .where((p) =>
            p.partyType == PartyType.customer ||
            p.partyType == PartyType.both)
        .toList();
  }
  Future<List<Product>> fetchProducts() {
    final q = db.select(db.products)
      ..where((t) =>
          t.orgId.equals(orgId) &
          ((t.isActive.isNull()) | t.isActive.equals(1)));
    return q.get();
  }

  Future<Party?> fetchPartyById(int id) async {
    return (db.select(db.parties)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int?> defaultGstPct() async {
    final row = await (db.select(db.appSettings)
          ..where((t) => t.orgId.equals(orgId)))
        .getSingleOrNull();
    return row?.defaultGstPct;
  }

  /// Add customer: phone required; others optional (GSTIN optional).
  Future<Party> addCustomer({
    required String phone,
    String? name,
    String? farmName,
    String? address,
    String? email,
    String? gstin,
  }) async {
    final id = await db.into(db.parties).insert(
          PartiesCompanion.insert(
            orgId: orgId,
            name: name ?? phone, // fallback if name omitted
            partyType: PartyType.customer, // pass enum directly
            phone: drift.Value(phone),
            email: drift.Value(email),
            gstin: drift.Value(gstin),
            address: drift.Value(address),
            farmName: drift.Value(farmName),
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
    return (await (db.select(db.parties)..where((t) => t.id.equals(id))).getSingle());
  }

  /// Update customer (only changed fields are sent).
  Future<Party> updateCustomer({
    required int id,
    String? name,
    String? phone,
    String? email,
    String? gstin,
    String? address,
    String? farmName,
  }) async {
    await (db.update(db.parties)..where((t) => t.id.equals(id))).write(
      PartiesCompanion(
        name: name == null ? const drift.Value.absent() : drift.Value(name),
        phone: phone == null ? const drift.Value.absent() : drift.Value(phone),
        email: email == null ? const drift.Value.absent() : drift.Value(email),
        gstin: gstin == null ? const drift.Value.absent() : drift.Value(gstin),
        address: address == null ? const drift.Value.absent() : drift.Value(address),
        farmName: farmName == null ? const drift.Value.absent() : drift.Value(farmName),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
    return (await (db.select(db.parties)..where((t) => t.id.equals(id))).getSingle());
  }

  // ---------- Payments helpers ----------
  Future<int> ensureCashMethod() async {
    final exist = await (db.select(db.paymentMethods)
          ..where((t) =>
              t.orgId.equals(orgId) &
              t.name.equals('Cash')))
        .getSingleOrNull();
    if (exist != null) return exist.id;
    return db.into(db.paymentMethods).insert(
          PaymentMethodsCompanion.insert(
            orgId: orgId,
            name: 'Cash',
            type: drift.Value(PayMethodType.cash),
            isActive: const drift.Value(1),
          ),
        );
  }

  /// Insert an incoming payment tied to a Sales Order via ref_no = 'SO-<id>'
  Future<int> addPaymentForSalesOrder({
    required int partyId,
    required int salesOrderId,
    required int methodId,
    required int amountMinor,
    String? note,
  }) {
    return db.into(db.payments).insert(
          PaymentsCompanion.insert(
            orgId: orgId,
            partyId: partyId,
            invoiceId: const drift.Value.absent(), // not via invoice
            methodId: methodId,
            direction: PayDir.in_,                 // incoming
            amountMinor: amountMinor,
            refNo: drift.Value('SO-$salesOrderId'),
            note: drift.Value(note ?? 'Payment at SO $salesOrderId'),
            paidAt: drift.Value(DateTime.now()),
            createdAt: drift.Value(DateTime.now()),
          ),
        );
  }


// -------------------- 1) CREATE SO (no snapshots) --------------------
Future<int> createSalesOrder({
  required int partyId,
  required int warehouseId,
  required DateTime soDate,
  required List<SoItemInput> items,
}) async {
  assert(items.isNotEmpty, 'At least one item required');

  // Build totals from items
  int subtotal = 0;
  for (final it in items) {
    subtotal += (it.qty * it.unitPriceMinor);
  }
  final defGst = await defaultGstPct() ?? 0;

  // Pull product GSTs (only for tax preview / totals)
  final ids = items.map((e) => e.productId).toSet().toList();
  final prods = await (db.select(db.products)..where((t) => t.id.isIn(ids))).get();
  final prodMap = {for (final p in prods) p.id: p};

  int tax = 0;
  for (final it in items) {
    final line = it.qty * it.unitPriceMinor;
    final gst  = (prodMap[it.productId]?.gstPercent ?? defGst);
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
        status: drift.Value(SoStatus.confirmed),   // enum directly (not index)
        subtotalMinor: drift.Value(subtotal),
        taxMinor: drift.Value(tax),
        totalMinor: drift.Value(total),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    for (final it in items) {
      final net = it.qty * it.unitPriceMinor;
      await db.into(db.salesOrderItems).insert(
        SalesOrderItemsCompanion.insert(
          salesOrderId: soId,
          productId: it.productId,
          qty: it.qty,
          unitPriceMinor: it.unitPriceMinor,
          lineTotalMinor: net,
          createdAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }

    // ✅ No snapshot write here (removed)

    return soId;
  });
}

// -------------------- 2) HEADER (join parties, no snapshots) --------------------



// -------------------- 4) PAYMENTS (for this SO) --------------------


// -------------------- 5) PARTY STATS (used in dialogs/cards) --------------------
Future<PartyStats> getPartyStats(int partyId) async {
  final row = await db.customSelect(
    '''
    SELECT
      (SELECT COALESCE(SUM(total_minor), 0) 
         FROM sales_orders 
        WHERE org_id = ? AND party_id = ?) AS so_total,
      (SELECT COALESCE(SUM(amount_minor), 0) 
         FROM payments 
        WHERE org_id = ? AND party_id = ? AND direction = 0) AS paid_in
    ''',
    variables: [
      drift.Variable<int>(orgId), drift.Variable<int>(partyId),
      drift.Variable<int>(orgId), drift.Variable<int>(partyId),
    ],
    readsFrom: {db.salesOrders, db.payments},
  ).getSingle();

  final sales = row.read<int>('so_total');
  final paid  = row.read<int>('paid_in');
  return PartyStats(lifetimeSales: sales, paidIn: paid, due: sales - paid);
}

// -------------------- 6) LEDGER (null-safe variables; no NULL binds) --------------------
Stream<List<LedgerVM>> watchLedger({
  int? partyId,
  DateTime? from,   // inclusive (optional)
  DateTime? to,     // exclusive (optional)
  String query = '',
}) {
  final likeQ = query.trim().toLowerCase();
  final vars = <drift.Variable<Object>>[];

  // ---- SO WHERE ----
  final soWhere = StringBuffer('so.org_id = ?');
  vars.add(drift.Variable<int>(orgId));
  if (partyId != null) {
    soWhere.write(' AND so.party_id = ?');
    vars.add(drift.Variable<int>(partyId));
  }
  if (likeQ.isNotEmpty) {
    final like = '%$likeQ%';
    soWhere.write(
      ' AND (LOWER(COALESCE(p.name, "")) LIKE ? OR CAST(so.id AS TEXT) LIKE ?)'
    );
    vars.addAll([drift.Variable<String>(like), drift.Variable<String>(like)]);
  }

  // ---- PAY WHERE (incoming only) ----
  final payWhere = StringBuffer('pay.org_id = ? AND pay.direction = 0');
  vars.add(drift.Variable<int>(orgId));
  if (partyId != null) {
    payWhere.write(' AND pay.party_id = ?');
    vars.add(drift.Variable<int>(partyId));
  }
  if (likeQ.isNotEmpty) {
    final like = '%$likeQ%';
    // allow searching party or ref_no (e.g., "SO-123")
    payWhere.write(
      ' AND (LOWER(COALESCE(p.name, "")) LIKE ? OR LOWER(COALESCE(pay.ref_no, "")) LIKE ?)'
    );
    vars.addAll([drift.Variable<String>(like), drift.Variable<String>(like)]);
  }

  // optional time filter (applied after UNION)
  final fromMs = from?.millisecondsSinceEpoch;
  final toMs   = to?.millisecondsSinceEpoch;
  final timeFilter = StringBuffer(' WHERE 1=1');
  if (fromMs != null) {
    timeFilter.write(' AND dt_ms >= ?');
    vars.add(drift.Variable<int>(fromMs));
  }
  if (toMs != null) {
    timeFilter.write(' AND dt_ms < ?');
    vars.add(drift.Variable<int>(toMs));
  }

  // NOTE: we normalize dates that might be stored as INTEGER(ms or sec) or TEXT(ISO, YYYYMMDDHHMMSS, etc.)
  // We also handle ISO with 'T' by REPLACE(ts,'T',' ').
  const soTs = 'COALESCE(so.so_date, so.created_at)';
  const payTs = 'COALESCE(pay.paid_at, pay.created_at)';

  final sql = '''
    WITH so_ledger AS (
      SELECT
        CASE
          WHEN typeof($soTs) = 'integer' THEN
            CASE
              WHEN $soTs >= 20000000000 THEN $soTs                 -- already ms
              WHEN $soTs >  1000000000  THEN $soTs * 1000          -- seconds -> ms
              ELSE $soTs                                           -- tiny ints; keep as-is
            END
          WHEN typeof($soTs) = 'text' THEN
            CASE
              WHEN strftime('%s', REPLACE($soTs,'T',' ')) IS NOT NULL
                THEN CAST(strftime('%s', REPLACE($soTs,'T',' ')) AS INTEGER) * 1000
              WHEN length($soTs) IN (8,14) THEN
                CAST(strftime('%s',
                  substr($soTs,1,4) || '-' || substr($soTs,5,2) || '-' || substr($soTs,7,2) ||
                  CASE WHEN length($soTs) = 14
                       THEN ' ' || substr($soTs,9,2) || ':' || substr($soTs,11,2) || ':' || substr($soTs,13,2)
                       ELSE ''
                  END
                ) AS INTEGER) * 1000
              ELSE NULL
            END
          ELSE NULL
        END AS dt_ms,
        'SO' AS kind,
        so.id AS so_id,
        NULL AS payment_id,
        COALESCE(p.name, '') AS party_name,
        COALESCE(so.total_minor, 0) AS amount_minor,
        NULL AS method,
        NULL AS note
      FROM sales_orders so
      LEFT JOIN parties p ON p.id = so.party_id
      WHERE ${soWhere.toString()}
    ),
    pay_ledger AS (
      SELECT
        CASE
          WHEN typeof($payTs) = 'integer' THEN
            CASE
              WHEN $payTs >= 20000000000 THEN $payTs
              WHEN $payTs >  1000000000  THEN $payTs * 1000
              ELSE $payTs
            END
          WHEN typeof($payTs) = 'text' THEN
            CASE
              WHEN strftime('%s', REPLACE($payTs,'T',' ')) IS NOT NULL
                THEN CAST(strftime('%s', REPLACE($payTs,'T',' ')) AS INTEGER) * 1000
              WHEN length($payTs) IN (8,14) THEN
                CAST(strftime('%s',
                  substr($payTs,1,4) || '-' || substr($payTs,5,2) || '-' || substr($payTs,7,2) ||
                  CASE WHEN length($payTs) = 14
                       THEN ' ' || substr($payTs,9,2) || ':' || substr($payTs,11,2) || ':' || substr($payTs,13,2)
                       ELSE ''
                  END
                ) AS INTEGER) * 1000
              ELSE NULL
            END
          ELSE NULL
        END AS dt_ms,
        'PAYMENT_IN' AS kind,
        CASE
          WHEN COALESCE(pay.ref_no,'') LIKE 'SO-%'
            THEN CAST(substr(pay.ref_no, 4) AS INTEGER)
          ELSE NULL
        END AS so_id,
        pay.id AS payment_id,
        COALESCE(p.name, '') AS party_name,
        COALESCE(pay.amount_minor, 0) AS amount_minor,
        COALESCE(pm.name, '') AS method,
        pay.note AS note
      FROM payments pay
      LEFT JOIN parties p ON p.id = pay.party_id
      LEFT JOIN payment_methods pm ON pm.id = pay.method_id
      WHERE ${payWhere.toString()}
    )
    SELECT * FROM (
      SELECT * FROM so_ledger
      UNION ALL
      SELECT * FROM pay_ledger
    )
    ${timeFilter.toString()}
    ORDER BY (dt_ms IS NULL), dt_ms DESC, kind DESC, so_id DESC, payment_id DESC;
  ''';

  return db
      .customSelect(
        sql,
        variables: vars,
        readsFrom: {db.salesOrders, db.payments, db.parties, db.paymentMethods},
      )
      .watch()
      .map((rows) => rows.map((r) {
            final k = r.read<String>('kind');
            final dtMs = r.readNullable<int>('dt_ms'); // may be null for old rows
            return LedgerVM(
              dt: dtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(dtMs),
              kind: (k == 'SO') ? LedgerKind.sale : LedgerKind.paymentIn,
              soId: r.readNullable<int>('so_id'),
              paymentId: r.readNullable<int>('payment_id'),
              party: r.read<String>('party_name'),
              amountMinor: r.read<int>('amount_minor'),
              method: r.readNullable<String>('method'),
              note: r.readNullable<String>('note'),
            );
          }).toList());
}

  Future<List<SoLineVM>> loadSoItems(int soId) async {
    final sql = '''
      SELECT si.qty, si.unit_price_minor, si.line_total_minor,
             p.name AS product_name,
             COALESCE(p.gst_percent, 0) AS gst_percent
      FROM sales_order_items si
      JOIN products p ON p.id = si.product_id
      WHERE si.sales_order_id = ?
      ORDER BY si.id ASC
    ''';
    final rows = await db.customSelect(
      sql,
      variables: [drift.Variable<int>(soId)],
      readsFrom: {db.salesOrderItems, db.products},
    ).get();

    return rows.map((r) => SoLineVM(
      productName: r.read<String>('product_name'),
      qty: r.read<int>('qty'),
      unitPriceMinor: r.read<int>('unit_price_minor'),
      gstPercent: r.read<int>('gst_percent'),
      lineTotalMinor: r.read<int>('line_total_minor'),
    )).toList();
  }

  /// This SO's payments (we tag them using `ref_no = 'SO-<id>'`)
  Stream<List<SoPaymentVM>> watchSoPayments(int soId) {
    final sql = '''
      SELECT pay.id, pay.paid_at, pay.amount_minor, pay.note,
             m.name AS method_name
      FROM payments pay
      JOIN payment_methods m ON m.id = pay.method_id
      WHERE pay.org_id = ? AND pay.ref_no = ?
      ORDER BY pay.paid_at DESC NULLS LAST, pay.id DESC
    ''';
    return db
        .customSelect(
          sql,
          variables: [
            drift.Variable<int>(orgId),
            drift.Variable<String>('SO-$soId'),
          ],
          readsFrom: {db.payments, db.paymentMethods},
        )
        .watch()
        .map((rows) => rows.map((r) => SoPaymentVM(
          id: r.read<int>('id'),
          paidAt: r.readNullable<DateTime>('paid_at'),
          method: r.read<String>('method_name'),
          amountMinor: r.read<int>('amount_minor'),
          note: r.readNullable<String>('note'),
        )).toList());
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
