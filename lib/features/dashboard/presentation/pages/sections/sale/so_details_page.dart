import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/sales_dispatch_controller.dart';

class SalesOrderDetailsPage extends StatelessWidget {
  final int soId;
  const SalesOrderDetailsPage({super.key, required this.soId});

  bool _isWalkInName(String? name) {
    if (name == null) return false;
    final norm = name.trim().toLowerCase().replaceAll(RegExp(r'[-\s]+'), ' ');
    // Covers: "Walk-in Customer", "Walk in Customer", "Walk-in..."
    return norm == 'walk in customer' || norm.startsWith('walk in');
  }

  SoHeaderVM _applyDraft(SoHeaderVM base, Party? d) {
    if (d == null) return base;
    return SoHeaderVM(
      id: base.id,
      soDate: base.soDate,
      status: base.status,
      subtotalMinor: base.subtotalMinor,
      taxMinor: base.taxMinor,
      totalMinor: base.totalMinor,
      partyId: base.partyId,
      partyName: d.name,
      phone: d.phone,
      gstin: d.gstin,
      address: d.address,
      farmName: d.farmName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Order #${soId.toString().padLeft(6,'0')}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<SoHeaderVM>(
        future: ctrl.loadSoHeader(soId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Apply SO-scoped draft (from "Use for this order only") on top of DB header
          final soDraft = ctrl.soDraftFor(soId);
          final headerForUi = _applyDraft(snap.data!, soDraft);
          final isWalkIn = _isWalkInName(headerForUi.partyName);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _HeaderCard(header: headerForUi),
                const SizedBox(height: 16),

                // Items
                FutureBuilder<List<SoLineVM>>(
                  future: ctrl.loadSoItems(soId),
                  builder: (context, itemsSnap) {
                    final items = itemsSnap.data ?? const <SoLineVM>[];
                    return _ItemsCard(items: items);
                  },
                ),
                const SizedBox(height: 16),

                // Party balance summary (HIDDEN for Walk-in)
                if (!isWalkIn)
                  FutureBuilder<PartyStats>(
                    future: ctrl.getPartyStats(headerForUi.partyId),
                    builder: (context, stSnap) {
                      if (!stSnap.hasData) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        );
                      }
                      final s = stSnap.data!;
                      return _PartyBalanceCard(
                        partyName: headerForUi.partyName,
                        currentDue: s.due,
                        thisOrder: headerForUi.totalMinor,
                      );
                    },
                  ),

                if (!isWalkIn) const SizedBox(height: 16),

                // Payments for THIS order (still useful for Walk-in)
                _PaymentsCard(soId: soId),
                const SizedBox(height: 16),

                // FULL PARTY LEDGER (HIDDEN for Walk-in)
                if (!isWalkIn) _LedgerCard(partyId: headerForUi.partyId),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ---------------------- Existing cards (unchanged) ---------------------- */

class _LedgerCard extends StatelessWidget {
  final int partyId;
  const _LedgerCard({required this.partyId});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
    final theme = Theme.of(context);

    String _inr(int n) {
      final s = n.toString();
      if (s.length <= 3) return '₹$s';
      final head = s.substring(0, s.length - 3);
      final tail = s.substring(s.length - 3);
      final headWithCommas = head.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '₹$headWithCommas,$tail';
    }

    Widget header() => Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade50,
      child: Row(children: const [
        Expanded(flex: 3, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text('Ref',  style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text('Debit',style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text('Credit',style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text('Balance',style: TextStyle(fontWeight: FontWeight.bold))),
      ]),
    );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Text('All Transactions (Party Ledger)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),

          header(),

          StreamBuilder<List<LedgerRowVM>>(
            stream: ctrl.watchPartyLedger(partyId),
            builder: (context, snap) {
              final list = snap.data ?? const <LedgerRowVM>[];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No transactions yet for this party.'),
                );
              }

              int running = 0; // running due (debit - credit)
              return Column(
                children: [
                  for (final row in list)
                    _ledgerRow(
                      date: row.dt == null
                          ? '-'
                          : "${row.dt!.year}-${row.dt!.month.toString().padLeft(2,'0')}-${row.dt!.day.toString().padLeft(2,'0')}",
                      kind: row.kind,
                      ref: row.refNo,
                      debit: row.debitMinor,
                      credit: row.creditMinor,
                      note: row.note,
                      runningAfter: (() {
                        running += row.debitMinor - row.creditMinor;
                        return running;
                      })(),
                      inr: _inr,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _ledgerRow({
    required String date,
    required String kind,
    required String ref,
    required int debit,
    required int credit,
    required int runningAfter,
    required String? note,
    required String Function(int) inr,
  }) {
    final muted = TextStyle(color: Colors.grey.shade600, fontSize: 12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: Text(date)),
              Expanded(flex: 2, child: Text(kind)),
              Expanded(flex: 3, child: Text(ref)),
              Expanded(flex: 3, child: Text(debit == 0 ? '-' : inr(debit))),
              Expanded(flex: 3, child: Text(credit == 0 ? '-' : inr(credit))),
              Expanded(flex: 3, child: Text(inr(runningAfter))),
            ],
          ),
          if (note != null && note.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(note, style: muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final SoHeaderVM header;
  const _HeaderCard({required this.header});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String k, String v) => Row(
      children: [
        SizedBox(width: 120, child: Text(k, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        Expanded(child: Text(v)),
      ],
    );
    String _inr(int n) {
      final s = n.toString();
      if (s.length <= 3) return '₹$s';
      final head = s.substring(0, s.length - 3);
      final tail = s.substring(s.length - 3);
      final headWithCommas = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
      return '₹$headWithCommas,$tail';
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          row('Order No', 'SO-${header.id.toString().padLeft(6, '0')}'),
          row('Date', header.soDate == null
              ? '-'
              : "${header.soDate!.year}-${header.soDate!.month.toString().padLeft(2,'0')}-${header.soDate!.day.toString().padLeft(2,'0')}"),
          row('Status', header.status?.name.toUpperCase() ?? '-'),
          const SizedBox(height: 8),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Text('Customer', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          row('Name', header.partyName),
          if ((header.phone ?? '').isNotEmpty) row('Phone', header.phone!),
          if ((header.gstin ?? '').isNotEmpty) row('GSTIN', header.gstin!),
          if ((header.farmName ?? '').isNotEmpty) row('Farm', header.farmName!),
          if ((header.address ?? '').isNotEmpty) row('Address', header.address!),
          const SizedBox(height: 8),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Row(
            children: [
              _pill('Subtotal', _inr(header.subtotalMinor)),
              const SizedBox(width: 8),
              _pill('Tax', _inr(header.taxMinor)),
              const SizedBox(width: 8),
              _pill('Total', _inr(header.totalMinor)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final List<SoLineVM> items;
  const _ItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(SoLineVM r) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(children: [
        Expanded(flex: 4, child: Text(r.productName)),
        Expanded(flex: 2, child: Text('${r.qty}')),
        Expanded(flex: 3, child: Text(_inr(r.unitPriceMinor))),
        Expanded(flex: 2, child: Text('${r.gstPercent}%')),
        Expanded(flex: 3, child: Text(_inr(r.lineTotalMinor))),
      ]),
    );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: Row(children: const [
              Expanded(flex: 4, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('GST %', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('Line Total', style: TextStyle(fontWeight: FontWeight.bold))),
            ]),
          ),
          for (final r in items) row(r),
        ],
      ),
    );
  }

  String _inr(int n) {
    final s = n.toString();
    if (s.length <= 3) return '₹$s';
    final head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final headWithCommas = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
    return '₹$headWithCommas,$tail';
  }
}

class _PartyBalanceCard extends StatelessWidget {
  final String partyName;
  final int currentDue;
  final int thisOrder;
  const _PartyBalanceCard({required this.partyName, required this.currentDue, required this.thisOrder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String _inr(int n) {
      final s = n.toString();
      if (s.length <= 3) return '₹$s';
      final head = s.substring(0, s.length - 3);
      final tail = s.substring(s.length - 3);
      final headWithCommas = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
      return '₹$headWithCommas,$tail';
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Party Balance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _pill('Party', partyName),
            _pill('This Order', _inr(thisOrder)),
            _pill('Current Due', _inr(currentDue)),
          ]),
        ]),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  final int soId;
  const _PaymentsCard({required this.soId});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text('Payments (This Order)', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          StreamBuilder<List<SoPaymentVM>>(
            stream: ctrl.watchSoPayments(soId),
            builder: (context, snap) {
              final rows = snap.data ?? const <SoPaymentVM>[];
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No payments recorded for this order yet.'),
                );
              }
              return Column(
                children: [
                  for (final p in rows) _payRow(p),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _payRow(SoPaymentVM p) {
    String _inr(int n) {
      final s = n.toString();
      if (s.length <= 3) return '₹$s';
      final head = s.substring(0, s.length - 3);
      final tail = s.substring(s.length - 3);
      final headWithCommas = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
      return '₹$headWithCommas,$tail';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(child: Text(p.paidAt?.toString().split('.').first ?? '-')),
          Expanded(child: Text(p.method)),
          Expanded(child: Text(_inr(p.amountMinor))),
          Expanded(child: Text(p.note ?? '-')),
        ],
      ),
    );
  }
}
