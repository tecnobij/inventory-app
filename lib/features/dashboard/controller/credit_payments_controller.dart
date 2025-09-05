import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import 'package:bhago/app/data/local_database.dart';

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

/// View models used by the UI
class PaymentVM {
  final int id;
  final DateTime? paidAt;
  final PayDir direction;
  final String methodName;
  final String partyName;
  final String reference;
  final int amountMinor;
  final String notes;

  PaymentVM({
    required this.id,
    required this.paidAt,
    required this.direction,
    required this.methodName,
    required this.partyName,
    required this.reference,
    required this.amountMinor,
    required this.notes,
  });
}

class MethodBalanceVM {
  final int id;
  final String name;
  final int inSum;
  final int outSum;
  int get net => inSum - outSum;

  MethodBalanceVM({
    required this.id,
    required this.name,
    required this.inSum,
    required this.outSum,
  });
}

/// Payload for saving a payment
class PaymentInput {
  final int orgId;
  final int partyId;
  final int methodId;
  final PayDir direction;
  final int amountMinor;
  final String? reference;
  final String? note;
  final DateTime paidAt;

  PaymentInput({
    required this.orgId,
    required this.partyId,
    required this.methodId,
    required this.direction,
    required this.amountMinor,
    required this.paidAt,
    this.reference,
    this.note,
  });
}

/// Controller: owns DB logic only (no UI)
class CreditPaymentsController extends ChangeNotifier {
  final AppDatabase db;
  bool _seededPM = false;
  int? _seededForOrg;

  CreditPaymentsController(this.db);

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

  /// Dropdown sources
  Future<List<MethodLite>> listMethods(int orgId) async {
    final rows = await (db.select(db.paymentMethods)
          ..where((t) => t.orgId.equals(orgId) & ((t.isActive.isNull()) | t.isActive.equals(1)))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();
    return rows.map((m) => MethodLite(id: m.id, name: m.name)).toList();
  }

  Future<List<PartyLite>> listParties(int orgId) async {
    final rows = await (db.select(db.parties)
          ..where((t) => t.orgId.equals(orgId))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();
    return rows.map((p) => PartyLite(id: p.id, name: p.name)).toList();
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
          ),
        );
  }

  /// Streams
  Stream<List<PaymentVM>> watchPayments(int orgId, String q) {
    final like = '%$q%';
    final sql = '''
      SELECT p.id, p.paid_at, p.direction, p.amount_minor, p.ref_no, p.note,
             COALESCE(pm.name, '') AS method_name,
             COALESCE(pt.name, '') AS party_name
      FROM payments p
      JOIN payment_methods pm ON pm.id = p.method_id
      LEFT JOIN parties pt ON pt.id = p.party_id
      WHERE p.org_id = ?
        AND (? = '' OR
             LOWER(COALESCE(pt.name,'')) LIKE ? OR
             LOWER(COALESCE(pm.name,'')) LIKE ? OR
             LOWER(COALESCE(p.ref_no,'')) LIKE ? OR
             LOWER(COALESCE(p.note,'')) LIKE ?)
      ORDER BY p.paid_at DESC NULLS LAST, p.id DESC
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
            drift.Variable<String>(like),
          ],
          readsFrom: {db.payments, db.paymentMethods, db.parties},
        )
        .watch()
        .map((rows) {
          return rows.map((r) {
            final dirIdx = r.read<int>('direction');
            final dir = PayDir.values[dirIdx];
            return PaymentVM(
              id: r.read<int>('id'),
              paidAt: r.readNullable<DateTime>('paid_at'),
              direction: dir,
              amountMinor: r.read<int>('amount_minor'),
              reference: r.readNullable<String>('ref_no') ?? '',
              notes: r.readNullable<String>('note') ?? '',
              methodName: r.read<String>('method_name'),
              partyName: r.read<String>('party_name'),
            );
          }).toList();
        });
  }

  Stream<List<MethodBalanceVM>> watchMethodBalances(int orgId) {
    final inIdx = PayDir.in_.index;
    final outIdx = PayDir.out_.index;
    final sql = '''
      SELECT pm.id,
             pm.name,
             COALESCE(SUM(CASE WHEN p.direction = $inIdx  THEN p.amount_minor END), 0) AS in_sum,
             COALESCE(SUM(CASE WHEN p.direction = $outIdx THEN p.amount_minor END), 0) AS out_sum
      FROM payment_methods pm
      LEFT JOIN payments p ON p.method_id = pm.id AND p.org_id = ?
      WHERE pm.org_id = ?
      GROUP BY pm.id, pm.name
      ORDER BY pm.name
    ''';
    return db
        .customSelect(
          sql,
          variables: [
            drift.Variable<int>(orgId),
            drift.Variable<int>(orgId),
          ],
          readsFrom: {db.paymentMethods, db.payments},
        )
        .watch()
        .map((rows) {
          return rows
              .map((r) => MethodBalanceVM(
                    id: r.read<int>('id'),
                    name: r.read<String>('name'),
                    inSum: r.read<int>('in_sum'),
                    outSum: r.read<int>('out_sum'),
                  ))
              .toList();
        });
  }
}
