import 'dart:async';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --------- Search state ----------
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';

  // Demo data (replace with your real search source)
  final List<_SearchItem> _allItems = const [
    _SearchItem(type: 'Product', label: 'Apple iPhone 15 Pro'),
    _SearchItem(type: 'Product', label: 'Dell Latitude 7400'),
    _SearchItem(type: 'Customer', label: 'Acme Traders'),
    _SearchItem(type: 'Customer', label: 'Bright Retails'),
    _SearchItem(type: 'Invoice', label: 'INV-10023'),
    _SearchItem(type: 'Invoice', label: 'INV-10024'),
    _SearchItem(type: 'Vendor', label: 'Global Supplies Co'),
  ];

  List<_SearchItem> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _allItems
        .where((e) => e.label.toLowerCase().contains(q) || e.type.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      // Debounce to avoid rebuilding too often
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 180), () {
        setState(() => _query = _searchCtrl.text);
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

  // ---------- Responsive helpers ----------
  int _cardColumns(BoxConstraints c) {
    final w = c.maxWidth;
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    if (w >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ======= Search + helper chips =======
        _SearchBar(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          hintText: 'Search products, customers, invoices…',
          onClear: () => setState(() {
            _searchCtrl.clear();
            _query = '';
            _searchFocus.unfocus();
          }),
          trailing: [
            Tooltip(
              message: 'Filters',
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_alt_outlined),
              ),
            ),
          ],
        ),

        // Live results dropdown (inline card)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _results.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: scheme.secondaryContainer,
                            child: Icon(_iconForType(r.type), color: scheme.onSecondaryContainer, size: 18),
                          ),
                          title: Text(r.label, overflow: TextOverflow.ellipsis),
                          subtitle: Text(r.type),
                          onTap: () {
                            // TODO: Navigate to detail page based on r.type/label
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Open ${r.type}: ${r.label}')),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 16),

        // ======= Quick chips (shortcuts) =======
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickChip(icon: Icons.add_shopping_cart_outlined, label: 'New Sale', color: Colors.teal, onTap: () {}),
            _QuickChip(icon: Icons.person_add_alt_1_outlined, label: 'Add Customer', color: Colors.deepPurple, onTap: () {}),
           // _QuickChip(icon: Icons.inventory_2_outlined, label: 'Add Product', color: Colors.orange, onTap: () {}),
           // _QuickChip(icon: Icons.document_scanner_outlined, label: 'New Invoice', color: Colors.blue, onTap: () {}),
          ],
        ),

        const SizedBox(height: 20),

        // ======= Stat cards (responsive grid) =======
        LayoutBuilder(
          builder: (context, c) {
            final cols = _cardColumns(c);
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.3,
              ),
              children: const [
                _StatCardDecorated(
                  title: 'Today Sales',
                  value: '₹ 0',
                  delta: '+0%',
                  icon: Icons.point_of_sale_outlined,
                  gradient: [Color(0xFF00C853), Color(0xFFB9F6CA)],
                ),
                _StatCardDecorated(
                  title: 'Pending Invoices',
                  value: '0',
                  delta: '0',
                  icon: Icons.receipt_long_outlined,
                  gradient: [Color(0xFF2979FF), Color(0xFF82B1FF)],
                ),
                _StatCardDecorated(
                  title: 'Low Stock Items',
                  value: '0',
                  delta: '',
                  icon: Icons.warning_amber_outlined,
                  gradient: [Color(0xFFFF6D00), Color(0xFFFFD180)],
                ),
                _StatCardDecorated(
                  title: 'Cash Balance',
                  value: '₹ 0',
                  delta: '',
                  icon: Icons.account_balance_wallet_outlined,
                  gradient: [Color(0xFFAA00FF), Color(0xFFE1BEE7)],
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // ======= Welcome / tips =======
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.tertiaryContainer,
                  child: Icon(Icons.lightbulb_outline, color: scheme.onTertiaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome to BhaGo! Get started by adding products and customers.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return Icons.inventory_2_outlined;
      case 'customer':
        return Icons.people_outline;
      case 'invoice':
        return Icons.receipt_long_outlined;
      case 'vendor':
        return Icons.store_mall_directory_outlined;
      default:
        return Icons.search;
    }
  }
}

// ------------------------------------------------------------
// Pretty search bar (Material 3-ish)
// ------------------------------------------------------------
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.trailing,
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final List<Widget>? trailing;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Icon(Icons.search, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          if ((controller.text).isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
            ),
          ...?trailing,
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Quick action chip
// ------------------------------------------------------------
class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Decorated stat card with gradient, icon & small delta tag
// ------------------------------------------------------------
class _StatCardDecorated extends StatelessWidget {
  const _StatCardDecorated({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.delta,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = gradient.first;
    final end = gradient.last;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [end.withOpacity(0.06), start.withOpacity(0.10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: start.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // ✅ Vertically center everything
          children: [
            // Left circle icon
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [start, end]),
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),

            // Middle text block
            Expanded(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ✅ Prevent extra vertical space
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        if (delta != null && delta!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              delta!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Right icon
            Icon(icon, color: start.withOpacity(0.9), size: 26),
          ],
        ),
      ),
    );
  }
}

// Simple model for demo search
class _SearchItem {
  final String type;
  final String label;
  const _SearchItem({required this.type, required this.label});
}
