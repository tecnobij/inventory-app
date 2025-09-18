// lib/features/payments/accountant_picker_page.dart
import 'package:bhago/features/dashboard/presentation/pages/sections/credit_payment_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/controller/credit_payments_controller.dart';


class AccountantPickerPage extends StatefulWidget {
  const AccountantPickerPage({super.key});
  @override
  State<AccountantPickerPage> createState() => _AccountantPickerPageState();
}

class _AccountantPickerPageState extends State<AccountantPickerPage> {
  late final CreditPaymentsController _ctrl;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl = CreditPaymentsController(context.read<AppDatabase>());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    if (!s.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!s.onboarded || s.orgId == null) {
      return const Scaffold(body: Center(child: Text('Finish onboarding.')));
    }
    final orgId = s.orgId!;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
       
      
        body: StreamBuilder<List<Party>>(
          stream: _ctrl.watchAccountants(orgId),
          builder: (context, snap) {
            final list = snap.data ?? const <Party>[];
            if (snap.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator(minHeight: 2);
            }
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No accountants yet.'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => _openAddAccountant(orgId),
                      child: const Text('Add Accountant'),
                    ),
                  ],
                ),
              );
            }
      
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
           itemBuilder: (_, i) {
  final p = list[i];

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

  Widget _amtPill(String label, int amount, {required bool isIn}) {
    final bg = isIn ? const Color(0xFFE9F7F0) : const Color(0xFFFDECEE);
    final fg = isIn ? const Color(0xFF12B76A) : const Color(0xFFF04438);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(.35)),
      ),
      child: Text(
        '$label ₹${_comma(amount)}',
        style: TextStyle(fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  return StreamBuilder<AccountantTotalsVM>(

stream: _ctrl.watchRecordedTotalsForAccountant(orgId, p.id),

    builder: (context, sumSnap) {
      final totals = sumSnap.data ?? const AccountantTotalsVM(partyId: -1, inSum: 0, outSum: 0);

      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreditPaymentsPage(accountant: p)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + name + chevron
              Row(
                children: [
                  CircleAvatar(
                    child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if ((p.phone ?? '').isNotEmpty)
                          Text(p.phone!, style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),

              // Totals row: IN / OUT (and you can add NET if you want)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _amtPill('IN', totals.inSum, isIn: true),
                  _amtPill('OUT', totals.outSum, isIn: false),
                  // Uncomment if you'd like to show NET too:
                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  //   decoration: BoxDecoration(
                  //     color: Colors.black.withOpacity(.05),
                  //     borderRadius: BorderRadius.circular(999),
                  //     border: Border.all(color: scheme.outlineVariant),
                  //   ),
                  //   child: Text('NET ₹${_comma(totals.net)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  // ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
},

            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddAccountant(orgId),
          icon: const Icon(Icons.add),
          label: const Text('Add Accountant'),
        ),
      ),
    );
  }

  Future<void> _openAddAccountant(int orgId) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Accountant'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: req),
            const SizedBox(height: 10),
            TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Phone (optional)'), keyboardType: TextInputType.phone),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _ctrl.createAccountant(orgId: orgId, name: name.text.trim(), phone: phone.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accountant added')));
      }
    }
  }
}
