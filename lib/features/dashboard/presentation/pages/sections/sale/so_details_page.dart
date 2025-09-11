import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart'; // for VM types
import 'package:bhago/features/dashboard/controller/sales_dispatch_controller.dart';

class SalesOrderDetailsPage extends StatelessWidget {
  final int soId;
  const SalesOrderDetailsPage({super.key, required this.soId});

  bool _isWalkInName(String? name) {
    if (name == null) return false;
    final norm = name.trim().toLowerCase().replaceAll(RegExp(r'[-\s]+'), ' ');
    return norm == 'walk in customer' || norm.startsWith('walk in');
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Order #${soId.toString().padLeft(6, '0')}'),
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

          // ✅ Use ONLY DB data (no draft overlay)
          final header = snap.data!;
          final isWalkIn = _isWalkInName(header.partyName);

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: ListView(
                children: [
                  _HeaderCard(header: header),
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
                      future: ctrl.getPartyStats(header.partyId),
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
                          partyName: header.partyName,
                          currentDue: s.due,
                          thisOrder: header.totalMinor,
                        );
                      },
                    ),

                  if (!isWalkIn) const SizedBox(height: 16),

                  // Payments for THIS order
                  _PaymentsCard(soId: soId),
                  const SizedBox(height: 16),

                  // FULL PARTY LEDGER (HIDDEN for Walk-in)
                  if (!isWalkIn) _LedgerCard(partyId: header.partyId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ---------------------- Ledger (responsive) ---------------------- */

class _LedgerCard extends StatelessWidget {
  final int partyId;
  const _LedgerCard({required this.partyId});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

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

    Widget headerDesktop() => Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade50,
          child: Row(children: const [
            Expanded(flex: 3, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text('Ref', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
          ]),
        );

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('All Transactions (Party Ledger)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),

            if (!isMobile) headerDesktop(),

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

                if (isMobile) {
                  // Mobile: tile list (outer list scrolls)
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200, height: 1),
                    itemBuilder: (_, i) {
                      final r = list[i];
                      final dt = r.dt == null
                          ? '-'
                          : "${r.dt!.year}-${r.dt!.month.toString().padLeft(2, '0')}-${r.dt!.day.toString().padLeft(2, '0')}";
                      final debit = r.debitMinor;
                      final credit = r.creditMinor;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(r.kind, style: const TextStyle(fontSize: 11)),
                              ),
                              const Spacer(),
                              Text(_inr(debit != 0 ? debit : credit != 0 ? credit : 0),
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 6),
                            Text('Date: $dt', style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 2),
                            Text('Ref: ${r.refNo}', style: TextStyle(color: Colors.grey.shade700)),
                            if ((r.note ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(r.note!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                }

                // Desktop: table rows (outer list scrolls)
                int running = 0;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final row = list[i];
                    final date = row.dt == null
                        ? '-'
                        : "${row.dt!.year}-${row.dt!.month.toString().padLeft(2, '0')}-${row.dt!.day.toString().padLeft(2, '0')}";
                    running += row.debitMinor - row.creditMinor;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(date)),
                          Expanded(flex: 2, child: Text(row.kind)),
                          Expanded(flex: 3, child: Text(row.refNo)),
                          Expanded(flex: 3, child: Text(row.debitMinor == 0 ? '-' : _inr(row.debitMinor))),
                          Expanded(flex: 3, child: Text(row.creditMinor == 0 ? '-' : _inr(row.creditMinor))),
                          Expanded(flex: 3, child: Text(_inr(running))),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------------- Header (responsive) ---------------------- */

class _HeaderCard extends StatelessWidget {
  final SoHeaderVM header;
  const _HeaderCard({required this.header});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    String _inr(int n) {
      final s = n.toString();
      if (s.length <= 3) return '₹$s';
      final head = s.substring(0, s.length - 3);
      final tail = s.substring(s.length - 3);
      final headWithCommas =
          head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
      return '₹$headWithCommas,$tail';
    }

    Widget kv(String k, String v) {
      if (isMobile) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(v, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }
      return Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(v)),
        ],
      );
    }

    final dateStr = header.soDate == null
        ? '-'
        : "${header.soDate!.year}-${header.soDate!.month.toString().padLeft(2, '0')}-${header.soDate!.day.toString().padLeft(2, '0')}";

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
          kv('Order No', 'SO-${header.id.toString().padLeft(6, '0')}'),
          kv('Date', dateStr),
          kv('Status', header.status?.name.toUpperCase() ?? '-'),
          const SizedBox(height: 8),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Text('Customer', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          kv('Name', header.partyName),
          if ((header.phone ?? '').isNotEmpty) kv('Phone', header.phone!),
          if ((header.gstin ?? '').isNotEmpty) kv('GSTIN', header.gstin!),
          if ((header.farmName ?? '').isNotEmpty) kv('Farm', header.farmName!),
          if ((header.address ?? '').isNotEmpty) kv('Address', header.address!),
          const SizedBox(height: 8),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),

          // Totals — horizontally scrollable on tight screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _pill('Subtotal', _inr(header.subtotalMinor)),
                const SizedBox(width: 8),
                _pill('Tax', _inr(header.taxMinor)),
                const SizedBox(width: 8),
                _pill('Total', _inr(header.totalMinor)),
              ],
            ),
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

/* ---------------------- Items (responsive) ---------------------- */

class _ItemsCard extends StatelessWidget {
  final List<SoLineVM> items;
  const _ItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    String _inr(int n) {
      final s = n.toString();
      if (s.length <= 3) return '₹$s';
      final head = s.substring(0, s.length - 3);
      final tail = s.substring(s.length - 3);
      final headWithCommas =
          head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
      return '₹$headWithCommas,$tail';
    }

    if (isMobile) {
      // Mobile: tile list
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
              ),
              child: Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200, height: 1),
              itemBuilder: (_, i) {
                final r = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: Text('Qty: ${r.qty}')),
                          Expanded(child: Text('Unit: ${_inr(r.unitPriceMinor)}')),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(child: Text('GST: ${r.gstPercent}%')),
                          Expanded(child: Text('Line: ${_inr(r.lineTotalMinor)}')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // Desktop: table layout
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
}

/* ---------------------- Party balance ---------------------- */

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
      final headWithCommas =
          head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
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

/* ---------------------- Payments (responsive) ---------------------- */

class _PaymentsCard extends StatelessWidget {
  final int soId;
  const _PaymentsCard({required this.soId});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SalesDispatchController>();
    final isMobile = MediaQuery.of(context).size.width < 700;

    String _inr(int n) {
      final s = n.toString();
      if (s.length <= 3) return '₹$s';
      final head = s.substring(0, s.length - 3);
      final tail = s.substring(s.length - 3);
      final headWithCommas =
          head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
      return '₹$headWithCommas,$tail';
    }

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
            child: const Text('Payments (This Order)', style: TextStyle(fontWeight: FontWeight.w700)),
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

              if (isMobile) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200, height: 1),
                  itemBuilder: (_, i) {
                    final p = rows[i];
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(_inr(p.amountMinor), style: const TextStyle(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text(p.method),
                          ]),
                          const SizedBox(height: 6),
                          Text(p.paidAt?.toString().split('.').first ?? '-',
                              style: TextStyle(color: Colors.grey.shade700)),
                          if ((p.note ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(p.note!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ],
                      ),
                    );
                  },
                );
              }

              // Desktop row style
              return Column(
                children: [
                  for (final p in rows)
                    Container(
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
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
