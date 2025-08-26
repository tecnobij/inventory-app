import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart';
import 'package:flutter/material.dart';

class QuotationsPage extends StatefulWidget {
  const QuotationsPage({super.key});

  @override
  State<QuotationsPage> createState() => _QuotationsPageState();
}

class _QuotationsPageState extends State<QuotationsPage> {
  final _searchCtrl = TextEditingController();

  final _rows = <_QuoteRow>[
    _QuoteRow(
      no: 'QU0–001',
      customer: 'ABC Technologies',
      date: DateTime(2024, 12, 18),
      validTill: DateTime(2025, 1, 18),
      status: _QuoteStatus.open,
      amount: 28500,
    ),
    _QuoteRow(
      no: 'QU0–002',
      customer: 'XYZ Solutions',
      date: DateTime(2024, 12, 15),
      validTill: DateTime(2025, 1, 15),
      status: _QuoteStatus.accepted,
      amount: 45750,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      // appBar: AppBar(
      //   title: Align(
      //     alignment: Alignment.bottomLeft,
      //     child: Text(
      //       'Quotations',
      //       style: Theme.of(context)
      //           .textTheme
      //           .titleLarge
      //           ?.copyWith(fontWeight: FontWeight.w200),
      //     ),
      //   ),
      // ),

      // ✅ Provide a TabController for both TabBar (inside SegmentedTabs)
      // and TabBarView below.
      body: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

              // Segmented header (uses DefaultTabController above)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedTabs(
                  tabs: const [
                    (Icons.widgets_outlined, 'List'),
                    (Icons.notifications_none_outlined, 'Create Quote'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ✅ TabBarView must be constrained; keep it in Expanded
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // ---- List tab ----
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        // Search + Filters row
                        Wrap(
                          runSpacing: 8,
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _searchField(
                              context,
                              controller: _searchCtrl,
                              hint: 'Search Quote Number…',
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Filters coming soon')),
                                );
                              },
                              icon: const Icon(Icons.tune),
                              label: const Text('Filters'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Table/Card container
                        Container(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: wide
                              ? _TableWide(rows: _rows)
                              : _CardsNarrow(rows: _rows),
                        ),
                      ],
                    ),

                    // ---- Create Quote tab (placeholder) ----
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined,
                              size: 56, color: scheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('Create Quote',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            'Quote builder UI goes here.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Search (pill)
  Widget _searchField(BuildContext context,
      {required TextEditingController controller, required String hint}) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 440),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: hint,
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(.45),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/* ============================ Wide table ============================ */

class _TableWide extends StatelessWidget {
  const _TableWide({required this.rows});
  final List<_QuoteRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget headCell(String t,
            {int flex = 1, TextAlign align = TextAlign.left}) =>
        Expanded(
          flex: flex,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(t,
                textAlign: align,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        );

    Widget divider() =>
        Divider(height: 1, thickness: 1, color: scheme.outlineVariant);

    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              headCell('Quote No', flex: 2),
              headCell('Customer', flex: 3),
              headCell('Date', flex: 2),
              headCell('Valid Till', flex: 2),
              headCell('Status', flex: 2),
              headCell('Amount', flex: 2),
              headCell('Actions', flex: 2),
            ],
          ),
        ),
        divider(),
        // Data rows
        for (final r in rows) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                _cell(context, r.no, flex: 2),
                _cell(context, r.customer, flex: 3),
                _cell(context, _fmtDate(r.date), flex: 2),
                _cell(context, _fmtDate(r.validTill), flex: 2),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _StatusPill(status: r.status)),
                _cell(context, '₹${_comma(r.amount)}', flex: 2),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'View',
                        onPressed: () => _toast(context, 'Viewing ${r.no}'),
                        icon: const Icon(Icons.remove_red_eye_outlined),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          divider(),
        ],
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _cell(BuildContext context, String t, {int flex = 1}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );
}

/* ============================ Narrow cards ============================ */

class _CardsNarrow extends StatelessWidget {
  const _CardsNarrow({required this.rows});
  final List<_QuoteRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final r in rows) ...[
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top line: quote no + amount
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.no,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium),
                      ),
                      Text('₹${_comma(r.amount)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(r.customer),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _meta('Date', _fmtDate(r.date)),
                      _meta('Valid Till', _fmtDate(r.validTill)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Status  '),
                          _StatusPill(status: r.status)
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'View',
                        onPressed: () => _toast(context, 'Viewing ${r.no}'),
                        icon: const Icon(Icons.remove_red_eye_outlined),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: () => _toast(context, 'Convert ${r.no} → SO'),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Convert to SO'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _meta(String k, String v) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(v),
        ],
      );
}

/* ============================ Status pill ============================ */

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final _QuoteStatus status;

  @override
  Widget build(BuildContext context) {
    final dark = status == _QuoteStatus.open;
    final bg = dark ? const Color(0xFF0B0B14) : const Color(0xFFF2F4F7);
    final fg = dark ? Colors.white : const Color(0xFF344054);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          status == _QuoteStatus.open ? 'Open' : 'Accepted',
          style: TextStyle(color: fg, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/* ============================ Model & helpers ============================ */

enum _QuoteStatus { open, accepted }

class _QuoteRow {
  final String no;
  final String customer;
  final DateTime date;
  final DateTime validTill;
  final _QuoteStatus status;
  final int amount;
  _QuoteRow({
    required this.no,
    required this.customer,
    required this.date,
    required this.validTill,
    required this.status,
    required this.amount,
  });
}

String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _comma(num v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final fromRight = s.length - i - 1;
    buf.write(s[i]);
    if (fromRight > 0 && fromRight % 3 == 0) buf.write(',');
  }
  return buf.toString();
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
