import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

class PartyVM {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? gstin;
  final PartyType type;

  PartyVM({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.email,
    this.gstin,
  });
}

class PartiesController extends ChangeNotifier {
  final AppDatabase db;
  final SettingsProvider settings;

  PartiesController({required this.db, required this.settings});

  String _q = '';
  String get q => _q;
  void setQuery(String v) {
    _q = v.trim().toLowerCase();
    notifyListeners();
  }

  /// Stream parties of a given type (customer/supplier) filtered by search query.
  Stream<List<PartyVM>> watchParties(PartyType type) {
    final orgId = settings.orgId;
    if (orgId == null) return const Stream.empty();

    final like = '%$_q%';
    final sql = '''
      SELECT id, name, phone, email, gstin, party_type
      FROM parties
      WHERE org_id = ?
        AND party_type = ?
        AND (? = '' OR
             LOWER(COALESCE(name,''))  LIKE ? OR
             LOWER(COALESCE(phone,'')) LIKE ? OR
             LOWER(COALESCE(email,'')) LIKE ? OR
             LOWER(COALESCE(gstin,'')) LIKE ?)
      ORDER BY name COLLATE NOCASE
    ''';

    return db
        .customSelect(
          sql,
          variables: [
            drift.Variable<int>(orgId),
            drift.Variable<int>(type.index),
            drift.Variable<String>(_q),
            drift.Variable<String>(like),
            drift.Variable<String>(like),
            drift.Variable<String>(like),
            drift.Variable<String>(like),
          ],
          readsFrom: {db.parties},
        )
        .watch()
        .map((rows) {
          return rows.map((r) {
            return PartyVM(
              id: r.read<int>('id'),
              name: r.read<String>('name'),
              phone: r.readNullable<String>('phone'),
              email: r.readNullable<String>('email'),
              gstin: r.readNullable<String>('gstin'),
              type: PartyType.values[r.read<int>('party_type')],
            );
          }).toList();
        });
  }

  Future<int> createParty({
    required PartyType type,
    required String name,
    String? phone,
    String? email,
    String? gstin,
  }) async {
    final orgId = settings.orgId!;
    final id = await db.into(db.parties).insert(
          PartiesCompanion.insert(
            orgId: orgId,
            name: name.trim(),
            phone: drift.Value(_nullIfEmpty(phone)),
            email: drift.Value(_nullIfEmpty(email)),
            gstin: drift.Value(_nullIfEmpty(gstin)),
            partyType: type,
            createdAt: drift.Value(DateTime.now()),
          ),
        );
    return id;
  }

  Future<void> updateParty({
    required int id,
    required PartyType type,
    required String name,
    String? phone,
    String? email,
    String? gstin,
  }) async {
    await (db.update(db.parties)..where((t) => t.id.equals(id))).write(
      PartiesCompanion(
        name: drift.Value(name.trim()),
        phone: drift.Value(_nullIfEmpty(phone)),
        email: drift.Value(_nullIfEmpty(email)),
        gstin: drift.Value(_nullIfEmpty(gstin)),
        partyType: drift.Value(type),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteParty(int id) async {
    // Will throw if referenced due to FK RESTRICT. Catch it in UI and show a friendly message.
    await (db.delete(db.parties)..where((t) => t.id.equals(id))).go();
  }

  String? _nullIfEmpty(String? s) {
    if (s == null) return null;
    final v = s.trim();
    return v.isEmpty ? null : v;
  }
}
