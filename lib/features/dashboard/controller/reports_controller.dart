import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

// simple range holder
class DateTimeRangeX {
  final DateTime start;
  final DateTime end;
  const DateTimeRangeX(this.start, this.end);
}

class PartyTotal {
  final int? partyId;
  final String partyName;
  final int txCount;
  final int amountMinor; // summed
  PartyTotal({
    required this.partyId,
    required this.partyName,
    required this.txCount,
    required this.amountMinor,
  });
}

class SummaryTotals {
  final int txCount;
  final int amountMinor;
  final int uniqueParties;
  const SummaryTotals({
    required this.txCount,
    required this.amountMinor,
    required this.uniqueParties,
  });
}

class PlTotals {
  final int revenueIn;  // sum(direction = in_)
  final int cogsOut;    // sum(direction = out_)
  int get gross => revenueIn - cogsOut;
  const PlTotals({required this.revenueIn, required this.cogsOut});
}

class ReportsController extends ChangeNotifier {
  final AppDatabase db;
  final SettingsProvider settings;

  late DateTimeRangeX _range;
  DateTimeRangeX get range => _range;

  int? get _orgId => settings.orgId;

  ReportsController({
    required this.db,
    required this.settings,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
    _range = DateTimeRangeX(start, end);
  }

  void setRange(DateTimeRangeX r) {
    _range = r;
    notifyListeners();
  }

  // ---------- PURCHASES (direction = out_) ----------
  Stream<List<PartyTotal>> watchPurchaseBySupplier() {
    if (_orgId == null) return const Stream.empty();
    final outIdx = PayDir.out_.index;
    final sql = '''
      SELECT pt.id AS party_id,
             COALESCE(pt.name, '(No Party)') AS party_name,
             COUNT(p.id) AS tx_count,
             COALESCE(SUM(p.amount_minor), 0) AS amount_sum
      FROM payments p
      LEFT JOIN parties pt ON pt.id = p.party_id
      WHERE p.org_id = ?
        AND p.direction = $outIdx
        AND p.paid_at >= ? AND p.paid_at <= ?
      GROUP BY pt.id, pt.name
      ORDER BY amount_sum DESC
    ''';
    return db.customSelect(
      sql,
      variables: [
        drift.Variable<int>(_orgId!),
        drift.Variable<DateTime>(_range.start),
        drift.Variable<DateTime>(_range.end),
      ],
      readsFrom: {db.payments, db.parties},
    ).watch().map((rows) => rows.map((r) => PartyTotal(
          partyId: r.readNullable<int>('party_id'),
          partyName: r.read<String>('party_name'),
          txCount: r.read<int>('tx_count'),
          amountMinor: r.read<int>('amount_sum'),
        )).toList());
  }

  Stream<SummaryTotals> watchPurchaseSummary() {
    if (_orgId == null) return const Stream.empty();
    final outIdx = PayDir.out_.index;
    final sql = '''
      SELECT COUNT(p.id) AS tx_count,
             COALESCE(SUM(p.amount_minor), 0) AS amount_sum,
             COUNT(DISTINCT p.party_id) AS uniq_parties
      FROM payments p
      WHERE p.org_id = ?
        AND p.direction = $outIdx
        AND p.paid_at >= ? AND p.paid_at <= ?
    ''';
    return db.customSelect(
      sql,
      variables: [
        drift.Variable<int>(_orgId!),
        drift.Variable<DateTime>(_range.start),
        drift.Variable<DateTime>(_range.end),
      ],
      readsFrom: {db.payments},
    ).watch().map((rows) {
      final r = rows.first;
      return SummaryTotals(
        txCount: r.read<int>('tx_count'),
        amountMinor: r.read<int>('amount_sum'),
        uniqueParties: r.read<int>('uniq_parties'),
      );
    });
  }

  // ---------- SALES (direction = in_) ----------
  Stream<List<PartyTotal>> watchSalesByCustomer() {
    if (_orgId == null) return const Stream.empty();
    final inIdx = PayDir.in_.index;
    final sql = '''
      SELECT pt.id AS party_id,
             COALESCE(pt.name, '(No Party)') AS party_name,
             COUNT(p.id) AS tx_count,
             COALESCE(SUM(p.amount_minor), 0) AS amount_sum
      FROM payments p
      LEFT JOIN parties pt ON pt.id = p.party_id
      WHERE p.org_id = ?
        AND p.direction = $inIdx
        AND p.paid_at >= ? AND p.paid_at <= ?
      GROUP BY pt.id, pt.name
      ORDER BY amount_sum DESC
    ''';
    return db.customSelect(
      sql,
      variables: [
        drift.Variable<int>(_orgId!),
        drift.Variable<DateTime>(_range.start),
        drift.Variable<DateTime>(_range.end),
      ],
      readsFrom: {db.payments, db.parties},
    ).watch().map((rows) => rows.map((r) => PartyTotal(
          partyId: r.readNullable<int>('party_id'),
          partyName: r.read<String>('party_name'),
          txCount: r.read<int>('tx_count'),
          amountMinor: r.read<int>('amount_sum'),
        )).toList());
  }

  Stream<SummaryTotals> watchSalesSummary() {
    if (_orgId == null) return const Stream.empty();
    final inIdx = PayDir.in_.index;
    final sql = '''
      SELECT COUNT(p.id) AS tx_count,
             COALESCE(SUM(p.amount_minor), 0) AS amount_sum,
             COUNT(DISTINCT p.party_id) AS uniq_parties
      FROM payments p
      WHERE p.org_id = ?
        AND p.direction = $inIdx
        AND p.paid_at >= ? AND p.paid_at <= ?
    ''';
    return db.customSelect(
      sql,
      variables: [
        drift.Variable<int>(_orgId!),
        drift.Variable<DateTime>(_range.start),
        drift.Variable<DateTime>(_range.end),
      ],
      readsFrom: {db.payments},
    ).watch().map((rows) {
      final r = rows.first;
      return SummaryTotals(
        txCount: r.read<int>('tx_count'),
        amountMinor: r.read<int>('amount_sum'),
        uniqueParties: r.read<int>('uniq_parties'),
      );
    });
  }

  // ---------- P&L (from payments only) ----------
  Stream<PlTotals> watchPl() {
    if (_orgId == null) return const Stream.empty();
    final inIdx = PayDir.in_.index;
    final outIdx = PayDir.out_.index;
    final sql = '''
      SELECT
        COALESCE(SUM(CASE WHEN p.direction = $inIdx  THEN p.amount_minor END), 0) AS rev_in,
        COALESCE(SUM(CASE WHEN p.direction = $outIdx THEN p.amount_minor END), 0) AS cogs_out
      FROM payments p
      WHERE p.org_id = ?
        AND p.paid_at >= ? AND p.paid_at <= ?
    ''';
    return db.customSelect(
      sql,
      variables: [
        drift.Variable<int>(_orgId!),
        drift.Variable<DateTime>(_range.start),
        drift.Variable<DateTime>(_range.end),
      ],
      readsFrom: {db.payments},
    ).watch().map((rows) {
      final r = rows.first;
      return PlTotals(
        revenueIn: r.read<int>('rev_in'),
        cogsOut: r.read<int>('cogs_out'),
      );
    });
  }

  // ---------- GST (needs invoice items; return null for now) ----------
  Stream<void> watchGstSummary() {
    // When you add invoice & line tables, compute GST here.
    return const Stream.empty();
  }
}
