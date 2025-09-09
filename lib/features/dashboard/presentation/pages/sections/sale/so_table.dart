// lib/features/sales/widgets/so_table.dart
import 'package:bhago/features/dashboard/controller/sales_dispatch_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// assumes you already have this controller


class SalesOrderVM {
  final String soNo;
  final String customer;
  final DateTime? date;
  final int itemsCount;
  final int totalMinor;
  SalesOrderVM({
    required this.soNo,
    required this.customer,
    required this.date,
    required this.itemsCount,
    required this.totalMinor,
  });
}

class SoTable extends StatelessWidget {
  final List<SalesOrderVM> items;
  const SoTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ctrl = context.read<SalesDispatchController>();

    Widget th(String t, {int flex = 1}) => Expanded(
          flex: flex,
          child: Text(t, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        );

    Widget td(String t, {int flex = 1, bool bold = false}) => Expanded(
          flex: flex,
          child: Text(t, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                th('SO No', flex: 2),
                th('Customer', flex: 3),
                th('Date', flex: 2),
                th('Items', flex: 1),
                th('Amount', flex: 2),
                const SizedBox(width: 56, child: Text('')),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final s in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  td(s.soNo, flex: 2, bold: true),
                  td(s.customer, flex: 3),
                  td(_fmtDate(s.date), flex: 2),
                  td('${s.itemsCount}', flex: 1),
                  td(ctrl.inr(s.totalMinor), flex: 2, bold: true),
                  const SizedBox(width: 56, child: Icon(Icons.visibility_outlined, size: 20)),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '-' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
