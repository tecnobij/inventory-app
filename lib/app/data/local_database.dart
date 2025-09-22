import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

/// =========================
/// Enums (stored as integers)
/// =========================
enum PartyType { customer, vendor, both }
enum QuoteStatus { open, accepted, rejected, expired }
enum SoStatus { draft, confirmed, dispatched, cancelled }
enum InvoiceStatus { draft, unpaid, paid, cancelled }
// `in` / `out` are reserved; use in_ / out_ in Dart:
enum MoveType { in_, out_, adjust }
enum PayDir { in_, out_ }
enum PayMethodType { cash, bank, upi, other }

/// Generic enum<->int converter
class EnumIndexConverter<T extends Enum> extends TypeConverter<T, int> {
  final List<T> values;
  const EnumIndexConverter(this.values);
  @override
  T fromSql(int fromDb) => values[fromDb];
  @override
  int toSql(T value) => value.index;
}

/// ====================================
/// Tables - names and columns match spec
/// ====================================
// lib/app/data/local_database.dart (tables file)

class SoPartySnapshots extends Table {
  IntColumn get soId => integer().references(SalesOrders, #id)();

  TextColumn get name     => text().nullable()();
  TextColumn get phone    => text().nullable()();
  TextColumn get email    => text().nullable()();
  TextColumn get gstin    => text().nullable()();
  TextColumn get address  => text().nullable()();
  TextColumn get farmName => text().nullable()();

  @override
  Set<Column> get primaryKey => {soId};
}

class Organizations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120).named('name')();
  TextColumn get email => text().nullable().named('email')();
  TextColumn get phone => text().nullable().named('phone')();
  TextColumn get gstin => text().nullable().named('gstin')();
  TextColumn get address => text().nullable().named('address')();
  TextColumn get ownerName => text().nullable().named('owner_name')();
  TextColumn get logoPath => text().nullable().named('logo_path')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

class Warehouses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint(
        'REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  TextColumn get name => text().withLength(min: 1, max: 120).named('name')();
  TextColumn get address => text().nullable().named('address')();
  IntColumn get isActive => integer().nullable().named('is_active')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

// lib/app/data/local_database.dart
// ...
class Parties extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint('REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT')();
  TextColumn get name => text().withLength(min: 1, max: 120).named('name')();
  TextColumn get phone => text().nullable().named('phone')();
  TextColumn get email => text().nullable().named('email')();
  TextColumn get gstin => text().nullable().named('gstin')();

  // ✅ new fields
  TextColumn get address => text().nullable().named('address')();
  TextColumn get farmName => text().nullable().named('farm_name')();

  IntColumn get partyType => integer()
      .map(const EnumIndexConverter<PartyType>(PartyType.values))
      .named('party_type')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}



class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint(
        'REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  TextColumn get code =>
      text().withLength(min: 1, max: 40).named('code').unique()();
  TextColumn get name => text().withLength(min: 1, max: 120).named('name')();
  TextColumn get unit => text().nullable().named('unit')();
  IntColumn get gstPercent => integer().nullable().named('gst_percent')();
  IntColumn get costMinor => integer().nullable().named('cost_minor')();
  IntColumn get mrpMinor => integer().nullable().named('mrp_minor')();
  IntColumn get priceMinor => integer().nullable().named('price_minor')();
  IntColumn get minStockQty => integer().nullable().named('min_stock_qty')();
  IntColumn get isActive => integer().nullable().named('is_active')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

class ProductStocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer()
      .named('product_id')
      .customConstraint(
        'REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get warehouseId => integer()
      .named('warehouse_id')
      .customConstraint(
        'REFERENCES warehouses(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get qty => integer().nullable().named('qty')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();

  /// Composite unique: (product_id, warehouse_id)
  @override
  List<String> get customConstraints => [
        'UNIQUE(product_id, warehouse_id)',
      ];
}

class InventoryMoves extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer()
      .named('product_id')
      .customConstraint(
        'REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get warehouseId => integer()
      .named('warehouse_id')
      .customConstraint(
        'REFERENCES warehouses(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get moveType => integer()
      .map(const EnumIndexConverter<MoveType>(MoveType.values))
      .named('move_type')();
  IntColumn get qty => integer().named('qty')();
  TextColumn get refTable => text().nullable().named('ref_table')();
  IntColumn get refId => integer().nullable().named('ref_id')();
  TextColumn get note => text().nullable().named('note')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
}

class Quotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint(
        'REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get partyId => integer()
      .named('party_id')
      .customConstraint(
        'REFERENCES parties(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  DateTimeColumn get quoteDate => dateTime().nullable().named('quote_date')();
  DateTimeColumn get validTill => dateTime().nullable().named('valid_till')();
  IntColumn get status => integer()
      .map(const EnumIndexConverter<QuoteStatus>(QuoteStatus.values))
      .nullable()
      .named('status')();
  IntColumn get subtotalMinor => integer().nullable().named('subtotal_minor')();
  IntColumn get taxMinor => integer().nullable().named('tax_minor')();
  IntColumn get totalMinor => integer().nullable().named('total_minor')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

class QuotationItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get quotationId => integer()
      .named('quotation_id')
      .customConstraint(
        'REFERENCES quotations(id) ON UPDATE CASCADE ON DELETE CASCADE',
      )();
  IntColumn get productId => integer()
      .named('product_id')
      .customConstraint(
        'REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get qty => integer().named('qty')();
  IntColumn get unitPriceMinor => integer().named('unit_price_minor')();
  IntColumn get lineTotalMinor => integer().named('line_total_minor')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

class SalesOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint(
        'REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get partyId => integer()
      .named('party_id')
      .customConstraint(
        'REFERENCES parties(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();

  DateTimeColumn get soDate => dateTime().nullable().named('so_date')();
  IntColumn get status => integer()
      .map(const EnumIndexConverter<SoStatus>(SoStatus.values))
      .nullable()
      .named('status')();
  IntColumn get subtotalMinor => integer().nullable().named('subtotal_minor')();
  IntColumn get taxMinor => integer().nullable().named('tax_minor')();
  IntColumn get totalMinor => integer().nullable().named('total_minor')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

class SalesOrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get salesOrderId => integer()
      .named('sales_order_id')
      .customConstraint(
        'REFERENCES sales_orders(id) ON UPDATE CASCADE ON DELETE CASCADE',
      )();
  IntColumn get productId => integer()
      .named('product_id')
      .customConstraint(
        'REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get qty => integer().named('qty')();
  IntColumn get unitPriceMinor => integer().named('unit_price_minor')();
  IntColumn get lineTotalMinor => integer().named('line_total_minor')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint(
        'REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get salesOrderId => integer()
      .nullable()
      .named('sales_order_id')
      .customConstraint(
        'REFERENCES sales_orders(id) ON UPDATE CASCADE ON DELETE SET NULL',
      )();
  IntColumn get partyId => integer()
      .named('party_id')
      .customConstraint(
        'REFERENCES parties(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  DateTimeColumn get invoiceDate =>
      dateTime().nullable().named('invoice_date')();
  IntColumn get status => integer()
      .map(const EnumIndexConverter<InvoiceStatus>(InvoiceStatus.values))
      .nullable()
      .named('status')();
  IntColumn get subtotalMinor => integer().nullable().named('subtotal_minor')();
  IntColumn get taxMinor => integer().nullable().named('tax_minor')();
  IntColumn get totalMinor => integer().nullable().named('total_minor')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer()
      .named('invoice_id')
      .customConstraint(
        'REFERENCES invoices(id) ON UPDATE CASCADE ON DELETE CASCADE',
      )();
  IntColumn get productId => integer()
      .named('product_id')
      .customConstraint(
        'REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  IntColumn get qty => integer().named('qty')();
  IntColumn get unitPriceMinor => integer().named('unit_price_minor')();
  IntColumn get lineTotalMinor => integer().named('line_total_minor')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

class PaymentMethods extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint(
        'REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  TextColumn get name => text().withLength(min: 1, max: 40).named('name')();
  IntColumn get type => integer()
      .map(const EnumIndexConverter<PayMethodType>(PayMethodType.values))
      .nullable()
      .named('type')();
  IntColumn get isActive => integer().nullable().named('is_active')();
}

   
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint('REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT')();

  IntColumn get partyId => integer()
      .named('party_id')
      .customConstraint('REFERENCES parties(id) ON UPDATE CASCADE ON DELETE RESTRICT')();

  IntColumn get invoiceId => integer()
      .nullable()
      .named('invoice_id')
      .customConstraint('REFERENCES invoices(id) ON UPDATE CASCADE ON DELETE SET NULL')();

  IntColumn get methodId => integer()
      .named('method_id')
      .customConstraint('REFERENCES payment_methods(id) ON UPDATE CASCADE ON DELETE RESTRICT')();

  IntColumn get direction => integer()
      .map(const EnumIndexConverter<PayDir>(PayDir.values))
      .named('direction')();

  IntColumn get amountMinor => integer().named('amount_minor')();

  TextColumn get refNo => text().nullable().named('ref_no')();

  TextColumn get note => text().nullable().named('note')();

  DateTimeColumn get paidAt => dateTime().nullable().named('paid_at')();

  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();

  // ✅ NEW: who recorded this payment (the accountant’s party id)
// In class Payments extends Table
IntColumn get accountantPartyId => integer()
    .nullable()
    .named('accountant_party_id')
    .customConstraint('REFERENCES parties(id) ON UPDATE CASCADE ON DELETE SET NULL')();

}







class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint(
        'REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  TextColumn get currency => text().nullable().named('currency')();
  TextColumn get dateFormat => text().nullable().named('date_format')();
  IntColumn get defaultGstPct => integer().nullable().named('default_gst_pct')();
  IntColumn get lowStockWarn => integer().nullable().named('low_stock_warn')();
  IntColumn get notifications => integer().nullable().named('notifications')();
}

class NumberingPatterns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orgId => integer()
      .named('org_id')
      .customConstraint(
        'REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE RESTRICT',
      )();
  TextColumn get docType =>
      text().withLength(min: 1, max: 20).named('doc_type')();
  TextColumn get pattern =>
      text().withLength(min: 1, max: 60).named('pattern')();
  IntColumn get counter => integer().nullable().named('counter')();

  // If you want to enforce unique(doc_type) within org, uncomment:
  // @override
  // List<String> get customConstraints => [
  //   'UNIQUE(org_id, doc_type)'
  // ];
}

class Actions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code =>
      text().withLength(min: 1, max: 40).named('code').unique()();
  TextColumn get label =>
      text().withLength(min: 1, max: 120).named('label')();
  TextColumn get icon => text().nullable().named('icon')();
  IntColumn get isPinned => integer().nullable().named('is_pinned')();
}

class FavoriteActions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get actionId => integer()
      .named('action_id')
      .customConstraint(
        'REFERENCES actions(id) ON UPDATE CASCADE ON DELETE CASCADE',
      )();
  IntColumn get position => integer().named('position')();
}














/// ======================
/// Database + migrations
/// ======================
@DriftDatabase(
  tables: [
    Organizations,
    Warehouses,
    Parties,
    Products,
    ProductStocks,
    InventoryMoves,
    Quotations,
    QuotationItems,
    SalesOrders,
    SalesOrderItems,
    Invoices,
    InvoiceItems,
    PaymentMethods,
    Payments,
    AppSettings,
    NumberingPatterns,
    Actions,
    FavoriteActions,

  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // ⬆️ was 2

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.alterTable(TableMigration(
          parties,
          newColumns: [parties.address, parties.farmName],
        ));
      }
      if (from < 3) {
        // ✅ add accountant_party_id to payments
        if (from < 3) {
      // ✅ Use addColumn to avoid the IntColumn vs GeneratedColumn mismatch
      await m.addColumn(payments, payments.accountantPartyId );
    }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}



LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'bhago.sqlite'));
    // Run SQLite in a background isolate to avoid jank
    return NativeDatabase.createInBackground(
      file,
      logStatements: kDebugMode, // logs SQL only in debug
    );
  });
}

// =====================
// Maintenance helpers
// =====================
extension DbMaintenance on AppDatabase {
  /// Deletes only transactional data (keeps master data like products, parties, warehouses, etc.)
Future<void> wipeTransactionsOnly() async {
  await transaction(() async {
    // detail tables first
    await delete(invoiceItems).go();
    await delete(salesOrderItems).go();
    await delete(quotationItems).go();

    // snapshots before deleting sales orders (FK restrict)
    // await delete(soPartySnapshots).go(); // ❌ remove or guard, table not present

    // ledger-ish / balances
    await delete(inventoryMoves).go();
    await delete(productStocks).go();

    // headers
    await delete(invoices).go();
    await delete(quotations).go();
    await delete(payments).go();
    await delete(salesOrders).go();

    // reset autoincrement counters for only the tables that exist
    await customStatement('DELETE FROM sqlite_sequence WHERE name IN ('
        "'invoice_items','sales_order_items','quotation_items',"
        // "'so_party_snapshots',"  // ❌ remove
        "'inventory_moves','product_stocks',"
        "'invoices','quotations','payments','sales_orders'"
        ')');
  });
}


  /// Factory reset everything. By default keeps the Organizations row so onboarding stays intact.
  Future<void> factoryReset({bool keepOrg = true}) async {
    await transaction(() async {
      // 1) everything transactional
      await wipeTransactionsOnly();

      // 2) app/master data – mind FK order
      await delete(favoriteActions).go(); // must be before actions
      await delete(actions).go();

      await delete(numberingPatterns).go();
      await delete(appSettings).go();

      await delete(paymentMethods).go();

      // masters that inventory referenced
      await delete(products).go();
      await delete(warehouses).go();
      await delete(parties).go();

      if (!keepOrg) {
        await delete(organizations).go();
      }

      // reset all counters
      await customStatement('DELETE FROM sqlite_sequence');
    });
  }
}
