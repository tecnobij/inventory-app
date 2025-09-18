import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import 'package:bhago/app/data/local_database.dart';

int _asInt(Object? v, [int def = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

String _asString(Object? v) => (v == null) ? '' : v.toString();

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) {
    // Heuristic: seconds / ms / µs
    if (v > 10000000000000) return DateTime.fromMicrosecondsSinceEpoch(v);
    if (v > 10000000000)    return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.fromMillisecondsSinceEpoch(v * 1000);
  }
  return null;
}

/// Aggregated balance per payment method (Cash/Bank/UPI)
class MethodBalanceVM {
  final int id;
  final String name;
  final int inSum;
  final int outSum;

  const MethodBalanceVM({
    required this.id,
    required this.name,
    required this.inSum,
    required this.outSum,
  });

  int get net => inSum - outSum;

  factory MethodBalanceVM.fromRow(Map<String, Object?> row) {
    return MethodBalanceVM(
      id: _asInt(row['id']),
      name: _asString(row['name']),
      inSum: _asInt(row['in_sum']),
      outSum: _asInt(row['out_sum']),
    );
  }
}
class PaymentInput {
  final int orgId;
  final int partyId;        // customer
  final int methodId;
  final PayDir direction;
  final int amountMinor;
  final String? reference;
  final String? note;
  final DateTime paidAt;

  // ✅ NEW: who recorded it (the accountant’s party id)
  final int? accountantPartyId;

  PaymentInput({
    required this.orgId,
    required this.partyId,
    required this.methodId,
    required this.direction,
    required this.amountMinor,
    required this.paidAt,
    this.reference,
    this.note,
    this.accountantPartyId, // ✅ expose named param
  });
}


/// Payment row with joined party/method names
class PaymentVM {
  final int id;
  final int orgId;
  final int partyId;
  final int methodId;
  final PayDir direction;
  final int amountMinor;
  final String reference; // from ref_no
  final String notes;     // from note
  final DateTime? paidAt;
  final String partyName;
  final String methodName;

  const PaymentVM({
    required this.id,
    required this.orgId,
    required this.partyId,
    required this.methodId,
    required this.direction,
    required this.amountMinor,
    required this.reference,
    required this.notes,
    required this.paidAt,
    required this.partyName,
    required this.methodName,
  });

  factory PaymentVM.fromRow(Map<String, Object?> row) {
    final dirIdx = _asInt(row['direction']);
    return PaymentVM(
      id: _asInt(row['id']),
      orgId: _asInt(row['org_id']),
      partyId: _asInt(row['party_id']),
      methodId: _asInt(row['method_id']),
      direction: PayDir.values[dirIdx.clamp(0, PayDir.values.length - 1)],
      amountMinor: _asInt(row['amount_minor']),
      reference: _asString(row['ref_no']),
      notes: _asString(row['note']),
      paidAt: _asDate(row['paid_at']),
      partyName: _asString(row['party_name']),
      methodName: _asString(row['method_name']),
    );
  }
}

/// Lightweight list items for dropdowns
class MethodLite {
  final int id;
  final String name;
  MethodLite({required this.id, required this.name});
}

class PartyLite {
  final int id;
  final String name;
  PartyLite({required this.id, required this.name});
}

class AccountantTotalsVM {
  final int partyId;
  final int inSum;
  final int outSum;
  const AccountantTotalsVM({
    required this.partyId,
    required this.inSum,
    required this.outSum,
  });
  int get net => inSum - outSum;

  factory AccountantTotalsVM.fromRow(int partyId, Map<String, Object?> r) {
    return AccountantTotalsVM(
      partyId: partyId,
      inSum: (r['in_sum'] as int?) ?? 0,
      outSum: (r['out_sum'] as int?) ?? 0,
    );
  }
}


extension AccountantRecordedTotals on CreditPaymentsController {
  /// Totals (IN/OUT) for entries recorded by this accountant across customers,
  /// and include self rows only when they are OUT (expense).
  Stream<AccountantTotalsVM> watchRecordedTotalsForAccountant(int orgId, int accountantPartyId) {
    final sql = '''
      SELECT
        COALESCE(SUM(CASE WHEN p.direction = ${PayDir.in_.index}  THEN p.amount_minor ELSE 0 END), 0) AS in_sum,
        COALESCE(SUM(CASE WHEN p.direction = ${PayDir.out_.index} THEN p.amount_minor ELSE 0 END), 0) AS out_sum
      FROM payments p
      WHERE p.org_id = ?
        AND p.accountant_party_id = ?
        AND (p.party_id <> ? OR p.direction = ${PayDir.out_.index})
    ''';

    return db
        .customSelect(
          sql,
          variables: [
            drift.Variable.withInt(orgId),
            drift.Variable.withInt(accountantPartyId),
            drift.Variable.withInt(accountantPartyId),
          ],
          readsFrom: {db.payments},
        )
        .watch()
        .map((rows) => AccountantTotalsVM.fromRow(
              accountantPartyId,
              rows.isNotEmpty ? rows.first.data : const {},
            ));
  }
}





  /// Totals (IN/OUT) for a single accountant (party)

class CreditPaymentsController extends ChangeNotifier {
  final AppDatabase db;
  bool _seededPM = false;
  int? _seededForOrg;

  CreditPaymentsController(this.db);

  /// All parties tagged as 'Accountant'
  Stream<List<Party>> watchAccountants(int orgId) {
    final q = (db.select(db.parties)
      ..where((t) => t.orgId.equals(orgId) & t.farmName.equals('Accountant'))
      ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]));
    return q.watch();
  }

  /// Seed default payment methods for an org (Cash/Bank/UPI) once.
  Future<void> ensureDefaultPaymentMethods(int orgId) async {
    if (_seededPM && _seededForOrg == orgId) return;
    _seededPM = true;
    _seededForOrg = orgId;

    final existing = await (db.select(db.paymentMethods)
          ..where((t) => t.orgId.equals(orgId)))
        .get();
    if (existing.isNotEmpty) return;

    await db.batch((b) {
      b.insert(
        db.paymentMethods,
        PaymentMethodsCompanion.insert(
          orgId: orgId,
          name: 'Cash',
          type: const drift.Value(PayMethodType.cash),
          isActive: const drift.Value(1),
        ),
      );
      b.insert(
        db.paymentMethods,
        PaymentMethodsCompanion.insert(
          orgId: orgId,
          name: 'Bank',
          type: const drift.Value(PayMethodType.bank),
          isActive: const drift.Value(1),
        ),
      );
      b.insert(
        db.paymentMethods,
        PaymentMethodsCompanion.insert(
          orgId: orgId,
          name: 'UPI',
          type: const drift.Value(PayMethodType.upi),
          isActive: const drift.Value(1),
        ),
      );
    });
  }



Stream<List<PaymentVM>> watchPayments(int orgId, String q, {int? accountantPartyId}) {
  final like = '%${q.replaceAll('%', r'\%')}%';
  final where = StringBuffer('WHERE p.org_id = ?');
  final vars = <drift.Variable>[drift.Variable.withInt(orgId)];

  if (accountantPartyId != null) {
  // Was: p.accountant_party_id = ? AND p.party_id <> ?
  // Now: include self only for EXPENSE (OUT)
  where.write(
    ' AND p.accountant_party_id = ?'
    ' AND (p.party_id <> ? OR p.direction = ${PayDir.out_.index})'
  );
  vars.addAll([
    drift.Variable.withInt(accountantPartyId),
    drift.Variable.withInt(accountantPartyId),
  ]);
}


  if (q.isNotEmpty) {
    where.write(
      ' AND (pa.name LIKE ? OR IFNULL(pa.phone,"") LIKE ? OR IFNULL(p.ref_no,"") LIKE ? OR IFNULL(p.note,"") LIKE ?)'
    );
    vars.addAll([
      drift.Variable.withString(like),
      drift.Variable.withString(like),
      drift.Variable.withString(like),
      drift.Variable.withString(like),
    ]);
  }

  final sql = '''
    SELECT p.id, p.org_id, p.party_id, p.method_id, p.direction, p.amount_minor,
           IFNULL(p.ref_no,'') AS ref_no, IFNULL(p.note,'') AS note, p.paid_at,
           pa.name  AS party_name,
           IFNULL(pm.name,'') AS method_name
    FROM payments p
    JOIN parties pa ON pa.id = p.party_id
    LEFT JOIN payment_methods pm ON pm.id = p.method_id
    $where
    ORDER BY p.paid_at DESC, p.id DESC
  ''';

  return db
      .customSelect(sql, variables: vars, readsFrom: {db.payments, db.parties, db.paymentMethods})
      .watch()
      .map((rows) => rows.map((r) => PaymentVM.fromRow(r.data)).toList());
}

  /// Dropdown sources
  Future<List<MethodLite>> listMethods(int orgId) async {
    final rows = await (db.select(db.paymentMethods)
          ..where((t) => t.orgId.equals(orgId) & ((t.isActive.isNull()) | t.isActive.equals(1)))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();
    return rows.map((m) => MethodLite(id: m.id, name: m.name)).toList();
  }

  Future<List<PartyLite>> listParties(int orgId, {bool excludeAccountants = false}) async {
    final rows = await (db.select(db.parties)
          ..where((t) => t.orgId.equals(orgId))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();

    final filtered = excludeAccountants
        ? rows.where((p) => (p.farmName ?? '').toLowerCase() != 'accountant').toList()
        : rows;

    return filtered.map((p) => PartyLite(id: p.id, name: p.name)).toList();
  }

  /// Create party (used by UI dialog)
  Future<int> createParty({
    required int orgId,
    required String name,
    String? phone,
  }) async {
    final id = await db.into(db.parties).insert(
          PartiesCompanion.insert(
            orgId: orgId,
            name: name.trim(),
            phone: (phone == null || phone.trim().isEmpty)
                ? const drift.Value.absent()
                : drift.Value(phone.trim()),
            partyType: PartyType.both,
            createdAt: drift.Value(DateTime.now()),
          ),
        );
    return id;
  }

  /// Make an accountant party (tagged)
  Future<int> createAccountant({
    required int orgId,
    required String name,
    String? phone,
  }) async {
    return db.into(db.parties).insert(PartiesCompanion.insert(
      orgId: orgId,
      name: name,
      phone: drift.Value((phone ?? '').trim().isEmpty ? null : phone!.trim()),
      partyType: PartyType.vendor,
      farmName: const drift.Value('Accountant'),
      createdAt: drift.Value(DateTime.now()),
    ));
  }
// ✅ NEW: balances for entries recorded by this accountant
Stream<List<MethodBalanceVM>> watchMethodBalancesByAccountant(
  int orgId, {
  required int accountantPartyId,
}) {
  final sql = '''
    SELECT
      pm.id,
      pm.name,
      COALESCE(SUM(CASE WHEN p.direction = ${PayDir.in_.index}  THEN p.amount_minor ELSE 0 END), 0) AS in_sum,
      COALESCE(SUM(CASE WHEN p.direction = ${PayDir.out_.index} THEN p.amount_minor ELSE 0 END), 0) AS out_sum
    FROM payment_methods pm
    LEFT JOIN payments p
      ON p.method_id = pm.id
     AND p.org_id = pm.org_id
     AND p.accountant_party_id = ?
     -- include customer rows + self EXPENSE rows
     AND (p.party_id <> ? OR p.direction = ${PayDir.out_.index})
    WHERE pm.org_id = ?
    GROUP BY pm.id, pm.name
    ORDER BY pm.name
  ''';

  return db
      .customSelect(
        sql,
        variables: [
          drift.Variable.withInt(accountantPartyId),
          drift.Variable.withInt(accountantPartyId),
          drift.Variable.withInt(orgId),
        ],
        readsFrom: {db.paymentMethods, db.payments},
      )
      .watch()
      .map((rows) => rows.map((r) => MethodBalanceVM.fromRow(r.data)).toList());
}

  /// Save payment
Future<int> savePayment(PaymentInput input) async {
  return db.into(db.payments).insert(
    PaymentsCompanion.insert(
      orgId: input.orgId,
      partyId: input.partyId,
      invoiceId: const drift.Value.absent(),
      methodId: input.methodId,
      direction: input.direction,
      amountMinor: input.amountMinor,
      refNo: (input.reference == null || input.reference!.trim().isEmpty)
          ? const drift.Value.absent()
          : drift.Value(input.reference!.trim()),
      note: (input.note == null || input.note!.trim().isEmpty)
          ? const drift.Value.absent()
          : drift.Value(input.note!.trim()),
      paidAt: drift.Value(input.paidAt),
      createdAt: drift.Value(DateTime.now()),
      // ✅ NEW: attribute to the accountant who added it
      accountantPartyId: (input.accountantPartyId == null)
          ? const drift.Value.absent()
          : drift.Value(input.accountantPartyId!),
    ),
  );
}

}

/// Payload for saving a payment

