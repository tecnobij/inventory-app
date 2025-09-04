// lib/features/dashboard/controller/settings_controller.dart
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:bhago/app/data/local_database.dart';

class LocationInput {
  final String name, address, city, state, pincode;
  final bool isActive;
  const LocationInput({
    required this.name,
    required this.address,
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.isActive = true,
  });
}

class WarehouseVM {
  final int id;
  final String name;
  final String address;
  final bool isActive;
  const WarehouseVM({
    required this.id,
    required this.name,
    required this.address,
    required this.isActive,
  });
}

class NumberingVM {
  String po, so, inv, quo;
  NumberingVM({required this.po, required this.so, required this.inv, required this.quo});
}

class AppSettingsVM {
  String currency;
  String dateFormat;
  int? defaultGstPct;
  int? lowStockWarn;
  bool notifications;
  AppSettingsVM({
    required this.currency,
    required this.dateFormat,
    this.defaultGstPct,
    this.lowStockWarn,
    required this.notifications,
  });
}

class SettingsProvider extends ChangeNotifier {
  final AppDatabase db;
  SettingsProvider(this.db) {
    app = AppSettingsVM(
      currency: 'INR (₹)',
      dateFormat: 'DD/MM/YYYY',
      defaultGstPct: 18,
      lowStockWarn: 10,
      notifications: true,
    );
    numbering = NumberingVM(
      po: 'FY/PO/######',
      so: 'FY/SO/######',
      inv: 'FY/INV/######',
      quo: 'FY/QUO/######',
    );
  }

  bool loaded = false;
  bool onboarded = false;

  // org
  int? orgId;
  String orgName = '';
  String ownerName = '';
  String email = '';
  String phone = '';
  String gst = '';
  String address = '';
  String? logoPath;

  // app & numbering
  late AppSettingsVM app;
  late NumberingVM numbering;

  List<WarehouseVM> warehouses = [];

  Future<void> load() async {
    final org = await (db.select(db.organizations)
          ..orderBy([(t) => drift.OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();

    if (org == null) {
      onboarded = false;
      loaded = true;
      notifyListeners();
      return;
    }

    orgId = org.id;
    orgName = org.name;
    ownerName = org.ownerName ?? '';
    email = org.email ?? '';
    phone = org.phone ?? '';
    gst = org.gstin ?? '';
    address = org.address ?? '';
    logoPath = org.logoPath;

    await _loadAppSettings();
    await _loadNumbering();
    await _loadWarehouses();

    onboarded = true;
    loaded = true;
    notifyListeners();
  }

  Future<void> setOnboarded(bool v) async {
    onboarded = v;
    notifyListeners();
  }

  Future<void> createOrUpdateOrganization({
    required String orgName,
    String ownerName = '',
    String email = '',
    String phone = '',
    String gst = '',
    String address = '',
    String? logoPath,
    List<LocationInput> locations = const [],
  }) async {
    final now = DateTime.now();
    if (orgId == null) {
      final id = await db.into(db.organizations).insert(
            OrganizationsCompanion.insert(
              name: orgName,
              email: drift.Value(email.isEmpty ? null : email),
              phone: drift.Value(phone.isEmpty ? null : phone),
              gstin: drift.Value(gst.isEmpty ? null : gst),
              address: drift.Value(address.isEmpty ? null : address),
              ownerName: drift.Value(ownerName.isEmpty ? null : ownerName),
              logoPath: drift.Value(logoPath),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );
      orgId = id;

      await _ensureAppSettingsSeed();
      await _ensureNumberingSeed();

      for (final l in locations) {
        await db.into(db.warehouses).insert(
              WarehousesCompanion.insert(
                orgId: id,
                name: l.name.isEmpty ? 'Warehouse' : l.name,
                address: drift.Value(l.address.isEmpty ? null : l.address),
                isActive: drift.Value(l.isActive ? 1 : 0),
                createdAt: drift.Value(now),
                updatedAt: drift.Value(now),
              ),
            );
      }
    } else {
      await (db.update(db.organizations)..where((t) => t.id.equals(orgId!))).write(
        OrganizationsCompanion(
          name: drift.Value(orgName),
          email: drift.Value(email.isEmpty ? null : email),
          phone: drift.Value(phone.isEmpty ? null : phone),
          gstin: drift.Value(gst.isEmpty ? null : gst),
          address: drift.Value(address.isEmpty ? null : address),
          ownerName: drift.Value(ownerName.isEmpty ? null : ownerName),
          logoPath: drift.Value(logoPath),
          updatedAt: drift.Value(now),
        ),
      );
    }
    await load();
  }

  // ---------- Warehouses ----------
  Future<void> _loadWarehouses() async {
    if (orgId == null) {
      warehouses = [];
      return;
    }
    final rows = await (db.select(db.warehouses)
          ..where((t) => t.orgId.equals(orgId!))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
        .get();
    warehouses = rows
        .map(
          (w) => WarehouseVM(
            id: w.id,
            name: w.name,
            address: w.address ?? '',
            isActive: (w.isActive ?? 1) != 0,
          ),
        )
        .toList();
  }

  Future<int> addWarehouse({
    required String name,
    String address = '',
    bool isActive = true,
  }) async {
    if (orgId == null) throw StateError('No organization.');
    final now = DateTime.now();
    final id = await db.into(db.warehouses).insert(
          WarehousesCompanion.insert(
            orgId: orgId!,
            name: name,
            address: drift.Value(address.isEmpty ? null : address),
            isActive: drift.Value(isActive ? 1 : 0),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );
    await _loadWarehouses();
    notifyListeners();
    return id;
  }

  Future<void> updateWarehouse({
    required int id,
    required String name,
    String address = '',
    required bool isActive,
  }) async {
    final now = DateTime.now();
    await (db.update(db.warehouses)..where((t) => t.id.equals(id))).write(
      WarehousesCompanion(
        name: drift.Value(name),
        address: drift.Value(address.isEmpty ? null : address),
        isActive: drift.Value(isActive ? 1 : 0),
        updatedAt: drift.Value(now),
      ),
    );
    await _loadWarehouses();
    notifyListeners();
  }

  Future<void> setWarehouseActive(int id, bool v) async {
    await (db.update(db.warehouses)..where((t) => t.id.equals(id))).write(
      WarehousesCompanion(
        isActive: drift.Value(v ? 1 : 0),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
    await _loadWarehouses();
    notifyListeners();
  }

  Future<void> deleteWarehouse(int id) async {
    await (db.delete(db.warehouses)..where((t) => t.id.equals(id))).go();
    await _loadWarehouses();
    notifyListeners();
  }

  // ---------- App settings ----------
  Future<void> _loadAppSettings() async {
    if (orgId == null) return;
    final row = await (db.select(db.appSettings)
          ..where((t) => t.orgId.equals(orgId!))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) {
      await _ensureAppSettingsSeed();
      return _loadAppSettings();
    }
    app = AppSettingsVM(
      currency: row.currency ?? 'INR (₹)',
      dateFormat: row.dateFormat ?? 'DD/MM/YYYY',
      defaultGstPct: row.defaultGstPct,
      lowStockWarn: row.lowStockWarn,
      notifications: (row.notifications ?? 1) != 0,
    );
  }

  Future<void> _ensureAppSettingsSeed() async {
    if (orgId == null) return;
    final exists = await (db.select(db.appSettings)
          ..where((t) => t.orgId.equals(orgId!)))
        .getSingleOrNull();
    if (exists == null) {
      await db.into(db.appSettings).insert(
            AppSettingsCompanion.insert(
              orgId: orgId!,
              currency: drift.Value('INR (₹)'),
              dateFormat: drift.Value('DD/MM/YYYY'),
              defaultGstPct: drift.Value(18),
              lowStockWarn: drift.Value(10),
              notifications: drift.Value(1),
            ),
          );
    }
  }

  Future<void> saveAppSettings({
    required String currency,
    required String dateFormat,
    required int defaultGstPct,
    required int lowStockWarn,
    required bool notifications,
  }) async {
    if (orgId == null) return;
    final row = await (db.select(db.appSettings)
          ..where((t) => t.orgId.equals(orgId!))
          ..limit(1))
        .getSingleOrNull();

    final data = AppSettingsCompanion(
      currency: drift.Value(currency),
      dateFormat: drift.Value(dateFormat),
      defaultGstPct: drift.Value(defaultGstPct),
      lowStockWarn: drift.Value(lowStockWarn),
      notifications: drift.Value(notifications ? 1 : 0),
    );

    if (row == null) {
      await db.into(db.appSettings).insert(
            AppSettingsCompanion.insert(
              orgId: orgId!,
              currency: data.currency,
              dateFormat: data.dateFormat,
              defaultGstPct: data.defaultGstPct,
              lowStockWarn: data.lowStockWarn,
              notifications: data.notifications,
            ),
          );
    } else {
      await (db.update(db.appSettings)..where((t) => t.id.equals(row.id))).write(data);
    }

    await _loadAppSettings();
    notifyListeners();
  }

  // ---------- Numbering ----------
// No explicit Data class usage, no manual Batch object.
// Uses the proper db.batch((batch) { ... }) API.

Future<void> _ensureNumberingSeed() async {
  if (orgId == null) return;

  final rows = await (db.select(db.numberingPatterns)
        ..where((t) => t.orgId.equals(orgId!)))
      .get();

  if (rows.isNotEmpty) return;

  await db.batch((batch) {
    batch.insert(
      db.numberingPatterns,
      NumberingPatternsCompanion.insert(
        orgId: orgId!,
        docType: 'PO',
        pattern: 'FY/PO/######',
        counter: const drift.Value(0),
      ),
    );
    batch.insert(
      db.numberingPatterns,
      NumberingPatternsCompanion.insert(
        orgId: orgId!,
        docType: 'SO',
        pattern: 'FY/SO/######',
        counter: const drift.Value(0),
      ),
    );
    batch.insert(
      db.numberingPatterns,
      NumberingPatternsCompanion.insert(
        orgId: orgId!,
        docType: 'INV',
        pattern: 'FY/INV/######',
        counter: const drift.Value(0),
      ),
    );
    batch.insert(
      db.numberingPatterns,
      NumberingPatternsCompanion.insert(
        orgId: orgId!,
        docType: 'QUO',
        pattern: 'FY/QUO/######',
        counter: const drift.Value(0),
      ),
    );
  });
}

Future<void> _loadNumbering() async {
  if (orgId == null) return;

  final rows = await (db.select(db.numberingPatterns)
        ..where((t) => t.orgId.equals(orgId!)))
      .get();

  String pat(String dt, String def) {
    for (final r in rows) {
      if (r.docType == dt) return r.pattern;
    }
    return def;
  }

  numbering = NumberingVM(
    po:  pat('PO',  'FY/PO/######'),
    so:  pat('SO',  'FY/SO/######'),
    inv: pat('INV', 'FY/INV/######'),
    quo: pat('QUO', 'FY/QUO/######'),
  );
}

Future<void> _upsertNumbering(String docType, String pattern, bool reset) async {
  if (orgId == null) return;

  final existing = await (db.select(db.numberingPatterns)
        ..where((t) => t.orgId.equals(orgId!) & t.docType.equals(docType))
        ..limit(1))
      .getSingleOrNull();

  if (existing == null) {
    await db.into(db.numberingPatterns).insert(
          NumberingPatternsCompanion.insert(
            orgId: orgId!,
            docType: docType,
            pattern: pattern,
            counter: const drift.Value(0),
          ),
        );
  } else {
    await (db.update(db.numberingPatterns)..where((t) => t.id.equals(existing.id)))
        .write(
      NumberingPatternsCompanion(
        pattern: drift.Value(pattern),
        counter: reset ? const drift.Value(0) : const drift.Value.absent(),
      ),
    );
  }
}


 
  Future<void> saveNumbering({
    required String po,
    required String so,
    required String inv,
    required String quo,
    bool resetCounters = false,
  }) async {
    if (orgId == null) return;
    await _upsertNumbering('PO', po, resetCounters);
    await _upsertNumbering('SO', so, resetCounters);
    await _upsertNumbering('INV', inv, resetCounters);
    await _upsertNumbering('QUO', quo, resetCounters);
    await _loadNumbering();
    notifyListeners();
  }

}
