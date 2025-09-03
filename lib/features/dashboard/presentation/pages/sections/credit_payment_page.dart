import 'dart:async';
import 'package:flutter/material.dart';

class CreditPaymentsPage extends StatefulWidget {
  const CreditPaymentsPage({super.key});

  @override
  State<CreditPaymentsPage> createState() => _CreditPaymentsPageState();
}

class _CreditPaymentsPageState extends State<CreditPaymentsPage> {
  // ---- Search state ----
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _q = '';

  // ---- Demo data ----
  final List<_Tx> _tx = [
    _Tx(
      date: DateTime(2024, 12, 19),
      party: 'ABC Technologies',
      type: _TxType.inward,
      method: 'Bank',
      reference: 'TXN123456',
      amount: 28500,
      notes: 'Payment for Invoice INV-001',
    ),
    _Tx(
      date: DateTime(2024, 12, 18),
      party: 'Tech Supplies Ltd',
      type: _TxType.outward,
      method: 'UPI',
      reference: 'UPI789012',
      amount: 45750,
      notes: 'Payment for PO-123',
    ),
  ];

  // Payment method balances (top 3 cards)
  final Map<String, int> _methodBalances = {
    'Cash': 25000,
    'Bank': 150000,
    'UPI': 75000,
  };

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 180), () {
        setState(() => _q = _searchCtrl.text.trim().toLowerCase());
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ---- Computed totals (from transactions) ----
  int get _totalIn => _tx.where((t) => t.type == _TxType.inward).fold(0, (s, t) => s + t.amount);
  int get _totalOut => _tx.where((t) => t.type == _TxType.outward).fold(0, (s, t) => s + t.amount);
  int get _net => _totalIn - _totalOut;

  // ---- Filters ----
  Iterable<_Tx> get _filteredTx {
    if (_q.isEmpty) return _tx;
    return _tx.where((t) {
      final hay = [
        _fmtDate(t.date),
        t.party,
        t.method,
        t.reference,
        t.notes,
        (t.type == _TxType.inward ? 'in' : 'out'),
      ].join(' ').toLowerCase();
      return hay.contains(_q);
    });
  }

  // ---- Responsive helpers ----
  bool get _isWide => MediaQuery.of(context).size.width >= 1000;
  bool get _useTable => MediaQuery.sizeOf(context).width >= 820; // table on ≥820px
  int _methodCols(double w) {
    if (w >= 1100) return 3;
    if (w >= 700) return 3;
    if (w >= 520) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
    
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ---------------- Payment Methods (Cash, Bank, UPI) ----------------
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
                    amount: _methodBalances['Cash']!,
                    icon: Icons.payments_rounded,
                    iconBg: const Color(0xFFDFF7E6),
                  ),
                  _PaymentMethodCard(
                    label: 'Bank',
                    amount: _methodBalances['Bank']!,
                    icon: Icons.credit_card_rounded,
                    iconBg: const Color(0xFFDDE7FF),
                  ),
                  _PaymentMethodCard(
                    label: 'UPI',
                    amount: _methodBalances['UPI']!,
                    icon: Icons.phone_iphone_rounded,
                    iconBg: const Color(0xFFEFE3FF),
                  ),
                ],
              );
            }),

            const SizedBox(height: 16),

            // ---------------- Summary pills + Record button ----------------
            _isWide
                ? Row(
                    children: [
                      Expanded(child: _SummaryPill(label: 'Total In', value: _inr(_totalIn), color: const Color(0xFF12B76A))),
                      const SizedBox(width: 16),
                      Expanded(child: _SummaryPill(label: 'Total Out', value: _inr(_totalOut), color: const Color(0xFFF04438))),
                      const SizedBox(width: 16),
                      Expanded(child: _SummaryPill(label: 'Net Amount', value: _inr(_net), color: const Color(0xFFFB8C00))),
                      const SizedBox(width: 16),
                      _RecordPaymentButton(onPressed: _onRecordPayment),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryPill(label: 'Total In', value: _inr(_totalIn), color: const Color(0xFF12B76A)),
                      const SizedBox(height: 12),
                      _SummaryPill(label: 'Total Out', value: _inr(_totalOut), color: const Color(0xFFF04438)),
                      const SizedBox(height: 12),
                      _SummaryPill(label: 'Net Amount', value: _inr(_net), color: const Color(0xFFFB8C00)),
                      const SizedBox(height: 12),
                      _RecordPaymentButton(onPressed: _onRecordPayment),
                    ],
                  ),

            const SizedBox(height: 20),

            // ---------------- Recent Transactions (responsive) ----------------
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
                    for (final t in _filteredTx) ...[
                      _TableRowWidget(tx: t),
                      Divider(height: 1, color: scheme.outlineVariant),
                    ],
                    const SizedBox(height: 8),
                  ] else ...[
                    // Mobile: card list
                    const SizedBox(height: 4),
                    for (final t in _filteredTx) ...[
                      _TxCard(tx: t),
                      const Divider(height: 1),
                    ],
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---------------- Reconciliation Tip ----------------
            _InfoCallout(
              icon: Icons.info_outline_rounded,
              color: const Color(0xFF1976D2),
              text:
                  'Reconciliation Tip: Regularly reconcile your payment methods with bank statements to ensure accuracy.',
            ),
          ],
        ),
      ),
    );
  }

  void _onRecordPayment() => _snack('Record Payment clicked');
  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ---- Helpers ----
  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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

/* ======================= Models ======================= */
enum _TxType { inward, outward }

class _Tx {
  final DateTime date;
  final String party;
  final _TxType type;
  final String method;
  final String reference;
  final int amount; // positive int; sign/color handled by type
  final String notes;

  _Tx({
    required this.date,
    required this.party,
    required this.type,
    required this.method,
    required this.reference,
    required this.amount,
    required this.notes,
  });
}

/* ======================= Widgets ======================= */

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
                  Text('₹${_comma(amount)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
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
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
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
      constraints: const BoxConstraints(minWidth: 220, minHeight: 56),
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
                decoration: const InputDecoration(
                  hintText: 'Search transactions…',
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
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
          Text('Recent Transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          searchField,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: filterBtn),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text('Recent Transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
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
  final _Tx tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = const Color(0xFF12B76A);
    final red = const Color(0xFFF04438);

    String amtText = '${tx.type == _TxType.inward ? '+' : '-'}${_inr(tx.amount)}';
    final amtColor = tx.type == _TxType.inward ? green : red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _cell(_fmtDate(tx.date), flex: 2),
          _cell(tx.party, flex: 3, bold: true),
          Expanded(flex: 2, child: _TypeChip(type: tx.type)),
          _cell(tx.method, flex: 2),
          _cell(tx.reference, flex: 2),
          Expanded(
            flex: 2,
            child: Text(amtText, style: TextStyle(fontWeight: FontWeight.w700, color: amtColor)),
          ),
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

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
  final _Tx tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = const Color(0xFF12B76A);
    final red = const Color(0xFFF04438);
    final amt = '${tx.type == _TxType.inward ? '+' : '-'}${_inr(tx.amount)}';
    final amtColor = tx.type == _TxType.inward ? green : red;

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
            // First row: date + amount
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fmtDate(tx.date),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                Text(amt, style: TextStyle(fontWeight: FontWeight.w800, color: amtColor)),
              ],
            ),
            const SizedBox(height: 6),
            // Party (bold)
            Text(tx.party, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            // Chips row: IN/OUT + Method + Reference
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _TypeChip(type: tx.type),
                _Chip(label: tx.method),
                _Chip(label: tx.reference, mono: true),
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

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
  const _TypeChip({required this.type});
  final _TxType type;

  @override
  Widget build(BuildContext context) {
    final isIn = type == _TxType.inward;
    final bg = isIn ? const Color(0xFF0B0B14) : const Color(0xFFF2F4F7);
    final fg = isIn ? Colors.white : const Color(0xFF101828);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Text(isIn ? 'IN' : 'OUT',
            style: TextStyle(color: fg, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
