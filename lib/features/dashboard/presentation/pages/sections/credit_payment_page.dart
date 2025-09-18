import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/controller/credit_payments_controller.dart';


class CreditPaymentsPage extends StatefulWidget {
  const CreditPaymentsPage({super.key, required this.accountant});
  final Party accountant; // The selected accountant

  @override
  State<CreditPaymentsPage> createState() => _CreditPaymentsPageState();
}

class _CreditPaymentsPageState extends State<CreditPaymentsPage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _q = '';
 int? _lastCustomerId;
  CreditPaymentsController? _ctrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() => _q = _searchCtrl.text.trim().toLowerCase());
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl ??= CreditPaymentsController(context.read<AppDatabase>());

    final s = context.watch<SettingsProvider>();
    if (s.loaded && s.onboarded && s.orgId != null) {
      _ctrl!.ensureDefaultPaymentMethods(s.orgId!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _isWide => MediaQuery.of(context).size.width >= 1000;
  bool get _useTable => MediaQuery.sizeOf(context).width >= 820;
  int _methodCols(double w) {
    if (w >= 1100) return 3;
    if (w >= 700) return 3;
    if (w >= 520) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;

    if (!s.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!s.onboarded || s.orgId == null) {
      return const Scaffold(body: Center(child: Text('Finish onboarding your organization to use Credit & Payments.')));
    }

    final orgId = s.orgId!;

    // Fetching transactions and payment method balances only for the selected accountant
final txStream = _ctrl!.watchPayments(
  orgId,
  _q,
  accountantPartyId: widget.accountant.id, // ✅ filter by recorder
);

final pmStream = _ctrl!.watchMethodBalancesByAccountant(
  orgId,
  accountantPartyId: widget.accountant.id,
);

    // final pmStream = _ctrl!.watchMethodBalances(
    //   orgId,
    //   partyId: widget.accountant.id, // Only show the accountant's balance
    // );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<PaymentVM>>(
          stream: txStream,
          builder: (context, txSnap) {
        final tx = txSnap.data ?? const <PaymentVM>[];
    final totalIn  = tx.where((t) => t.direction == PayDir.in_).fold<int>(0, (s0, t) => s0 + t.amountMinor);
    final totalOut = tx.where((t) => t.direction == PayDir.out_).fold<int>(0, (s0, t) => s0 + t.amountMinor);
    final net      = totalIn - totalOut;

            return StreamBuilder<List<MethodBalanceVM>>(
              stream: pmStream,
              builder: (context, pmSnap) {
                final balances = pmSnap.data ?? const <MethodBalanceVM>[];
                int balanceFor(String label) =>
                    balances.firstWhere(
                      (m) => m.name.toLowerCase() == label.toLowerCase(),
                      orElse: () => MethodBalanceVM(id: -1, name: label, inSum: 0, outSum: 0),
                    ).net;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    // Header row: accountant details + quick actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${widget.accountant.name}${(widget.accountant.phone ?? '').isNotEmpty ? ' • ${widget.accountant.phone}' : ''}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          // Expense quick action (OUT) - locked to accountant
                          OutlinedButton.icon(
                            onPressed: () => _openRecordPayment(
                              orgId,
                              presetDir: PayDir.out_,
                              presetPartyId: widget.accountant.id,
                              requireNote: true,
                            ),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Expense'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                     
                       
                          // Add party
                          FilledButton.icon(
                            onPressed: () => _openAddParty(orgId),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Add Party'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Method cards
                    LayoutBuilder(builder: (context, c) {
                      final cols = _methodCols(c.maxWidth);
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                        children: [
                          _PaymentMethodCard(
                            label: 'Cash',
                            amount: balanceFor('Cash'),
                            icon: Icons.payments_rounded,
                            iconBg: const Color(0xFFDFF7E6),
                          ),
                          _PaymentMethodCard(
                            label: 'Bank',
                            amount: balanceFor('Bank'),
                            icon: Icons.credit_card_rounded,
                            iconBg: const Color(0xFFDDE7FF),
                          ),
                          _PaymentMethodCard(
                            label: 'UPI',
                            amount: balanceFor('UPI'),
                            icon: Icons.phone_iphone_rounded,
                            iconBg: const Color(0xFFEFE3FF),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 16),

                    // Summary + Record
                    _isWide
                        ? Row(
                            children: [
                              Expanded(child: _SummaryPill(label: 'Total In',  value: _inr(totalIn),  color: const Color(0xFF12B76A))),
                              const SizedBox(width: 16),
                              Expanded(child: _SummaryPill(label: 'Total Out', value: _inr(totalOut), color: const Color(0xFFF04438))),
                              const SizedBox(width: 16),
                              Expanded(child: _SummaryPill(label: 'Net Amount', value: _inr(net),      color: const Color(0xFFFB8C00))),
                               
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SummaryPill(label: 'Total In',  value: _inr(totalIn),  color: const Color(0xFF12B76A)),
                              const SizedBox(height: 12),
                              _SummaryPill(label: 'Total Out', value: _inr(totalOut), color: const Color(0xFFF04438)),
                              const SizedBox(height: 12),
                              _SummaryPill(label: 'Net Amount', value: _inr(net),     color: const Color(0xFFFB8C00)),
                              
                            ],
                          ),

                    const SizedBox(height: 12),
  _RecordPaymentButton(onPressed: () => _openRecordPayment(orgId)),
        const SizedBox(height: 12),
                    // Recent transactions
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                            child: _RecentHeader(
                              searchCtrl: _searchCtrl,
                              onFilter: () => _snack('Filters coming soon'),
                            ),
                          ),
                          const Divider(height: 1),

                          if (_useTable) ...[
                            _TableHeader(
                              cols: const ['Date', 'Party', 'Type', 'Method', 'Reference', 'Amount', 'Notes'],
                              flexes: const [2, 3, 2, 2, 2, 2, 3],
                            ),
                            const Divider(height: 1),
                            if (txSnap.connectionState == ConnectionState.waiting)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            for (final t in tx) ...[
                              _TableRowWidget(tx: t),
                              Divider(height: 1, color: scheme.outlineVariant),
                            ],
                            const SizedBox(height: 8),
                          ] else ...[
                            const SizedBox(height: 4),
                            if (txSnap.connectionState == ConnectionState.waiting)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            for (final t in tx) ...[
                              _TxCard(tx: t),
                              const Divider(height: 1),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const _InfoCallout(
                      icon: Icons.info_outline_rounded,
                      color: Color(0xFF1976D2),
                      text: 'Reconciliation Tip: Regularly reconcile your payment methods with bank statements to ensure accuracy.',
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ---------------- Dialogs (UI) ----------------

  Future<void> _openAddParty(int orgId) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Party'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: req),
              const SizedBox(height: 10),
              TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (optional)'), keyboardType: TextInputType.phone),
            ],
          ),
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
      await _ctrl!.createParty(orgId: orgId, name: nameCtrl.text, phone: phoneCtrl.text);
      if (mounted) _snack('Party added');
    }
  }

  // Function to open payment recording for a specific accountant
  Future<void> _openRecordPayment(
    int orgId, {
    PayDir? presetDir,
    int? presetPartyId,
    bool requireNote = false,
  }) async {
    // Get methods and parties (exclude accountants for IN flow for cleaner picking)
    final methods = await _ctrl!.listMethods(orgId);
    final allParties = await _ctrl!.listParties(orgId,
        excludeAccountants: presetDir == null ? true : (presetDir == PayDir.in_));

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    PayDir dir = presetDir ?? PayDir.in_;
    int? methodId = methods.isNotEmpty ? methods.first.id : null;

    int? partyId = presetPartyId
        ?? (_lastCustomerId != null && allParties.any((p) => p.id == _lastCustomerId)
            ? _lastCustomerId
            : (allParties.isNotEmpty ? allParties.first.id : null));

    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime paidAt = DateTime.now();

    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
    String? reqInt(String? v) {
      if (req(v) != null) return 'Required';
      final i = int.tryParse(v!.trim());
      return (i == null || i <= 0) ? 'Enter a positive amount' : null;
    }
    String? reqNote(String? v) => requireNote ? req(v) : null;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        InputDecoration _soft(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(.45),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant, width: 1.0)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant, width: .6)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outline, width: 1.6)),
        );

        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 16),
              child: StatefulBuilder(builder: (context, setState) {
                return Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text('Record Payment', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (presetDir == null)
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('IN'),
                                selected: dir == PayDir.in_,
                                onSelected: (_) => setState(() => dir = PayDir.in_),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('OUT'),
                                selected: dir == PayDir.out_,
                                onSelected: (_) => setState(() => dir = PayDir.out_),
                              ),
                            ],
                          ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                icon: const SizedBox.shrink(),
                                value: methodId,
                                items: methods.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                                onChanged: (v) => setState(() => methodId = v ?? methodId),
                                validator: (v) => (v == null) ? 'Select method' : null,
                                decoration: _soft('Method'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                icon: const SizedBox.shrink(),
                                value: (presetPartyId != null) ? presetPartyId : partyId,
                                hint: Text(allParties.isNotEmpty ? 'Party' : 'Please Add Party'),
                                items: allParties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                                onChanged: (presetPartyId != null) ? null : (v) => setState(() => partyId = v),
                                validator: (v) => (v == null) ? 'Select party' : null,
                                decoration: _soft('Party'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        TextFormField(controller: amountCtrl, decoration: _soft('Amount (minor units)'), keyboardType: TextInputType.number, validator: reqInt),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: refCtrl,  decoration: _soft('Reference (optional)'))),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: noteCtrl, decoration: _soft(requireNote ? 'Notes (required)' : 'Notes (optional)'), validator: reqNote)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: InputDatePickerFormField(
                                initialDate: paidAt,
                                firstDate: DateTime(2020, 1, 1),
                                lastDate: DateTime(2100, 12, 31),
                                onDateSubmitted: (d) => paidAt = d,
                                onDateSaved: (d) => paidAt = d,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Format: YYYY-MM-DD', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final amt = int.parse(amountCtrl.text.trim());

                                 await _ctrl!.savePayment(
  PaymentInput(
    orgId: orgId,
    partyId: (presetPartyId ?? partyId)!,
    methodId: methodId!,
    direction: dir,
    amountMinor: amt,
    paidAt: paidAt,
    reference: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
    note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    accountantPartyId: widget.accountant.id, // ✅ who recorded this payment
  ),
);


                                  // Remember last picked customer for quick IN entries
                                  if (presetPartyId == null && dir == PayDir.in_) {
                                    setState(() => _lastCustomerId = partyId);
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                    _snack('Payment saved');
                                  }
                                },
                                child: const Text('Save Payment'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }



  // ---------------- Utils ----------------
  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  String _inr(int v) => '₹${_comma(v)}';
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
}

/* ======================= Stateless UI bits ======================= */

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconBg,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('₹${_comma(amount)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

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
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _RecordPaymentButton extends StatelessWidget {
  const _RecordPaymentButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, minHeight: 44),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader({required this.searchCtrl, required this.onFilter});
  final TextEditingController searchCtrl;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 520;

    final searchField = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 420),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.search, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(hintText: 'Search transactions…', border: InputBorder.none, isCollapsed: true),
              ),
            ),
          ],
        ),
      ),
    );

    final filterBtn = OutlinedButton.icon(
      onPressed: onFilter,
      icon: const Icon(Icons.tune, size: 18),
      label: const Text('Filter'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          searchField,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: filterBtn),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        searchField,
        const SizedBox(width: 10),
        filterBtn,
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.cols, required this.flexes});
  final List<String> cols;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (int i = 0; i < cols.length; i++)
            Expanded(
              flex: flexes[i],
              child: Text(
                cols[i],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableRowWidget extends StatelessWidget {
  const _TableRowWidget({required this.tx});
  final PaymentVM tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = const Color(0xFF12B76A);
    final red = const Color(0xFFF04438);

    final sign = tx.direction == PayDir.in_ ? '+' : '-';
    final amtText = '$sign${_inr(tx.amountMinor)}';
    final amtColor = tx.direction == PayDir.in_ ? green : red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _cell(_fmtDate(tx.paidAt), flex: 2),
          _cell(tx.partyName, flex: 3, bold: true),
          Expanded(flex: 2, child: _TypeChip(dir: tx.direction)),
          _cell(tx.methodName, flex: 2),
          _cell(tx.reference, flex: 2),
          Expanded(flex: 2, child: Text(amtText, style: TextStyle(fontWeight: FontWeight.w700, color: amtColor))),
          _cell(tx.notes, flex: 3),
        ],
      ),
    );
  }

  Widget _cell(String text, {int flex = 1, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
      ),
    );
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '--' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _inr(int v) => '₹${_comma(v)}';
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
}

class _TxCard extends StatelessWidget {
  const _TxCard({required this.tx});
  final PaymentVM tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = const Color(0xFF12B76A);
    final red = const Color(0xFFF04438);
    final sign = tx.direction == PayDir.in_ ? '+' : '-';
    final amt = '$sign${_inr(tx.amountMinor)}';
    final amtColor = tx.direction == PayDir.in_ ? green : red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fmtDate(tx.paidAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                Text(amt, style: TextStyle(fontWeight: FontWeight.w800, color: amtColor)),
              ],
            ),
            const SizedBox(height: 6),
            Text(tx.partyName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _TypeChip(dir: tx.direction),
                _Chip(label: tx.methodName),
                if (tx.reference.isNotEmpty) _Chip(label: tx.reference, mono: true),
              ],
            ),
            if (tx.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(tx.notes, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '--' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _inr(int v) => '₹${_comma(v)}';
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
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.mono = false});
  final String label;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.45),
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.dir});
  final PayDir dir;

  @override
  Widget build(BuildContext context) {
    final isIn = dir == PayDir.in_;
    final bg = isIn ? const Color(0xFF0B0B14) : const Color(0xFFF2F4F7);
    final fg = isIn ? Colors.white : const Color(0xFF101828);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Text(isIn ? 'IN' : 'OUT', style: TextStyle(color: fg, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      ),
    );
  }
}

class _InfoCallout extends StatelessWidget {
  const _InfoCallout({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
