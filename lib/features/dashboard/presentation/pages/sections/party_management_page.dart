import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/parties_controller.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PartyManagePage extends StatefulWidget {
  const PartyManagePage({super.key});

  @override
  State<PartyManagePage> createState() => _PartyManagePageState();
}

class _PartyManagePageState extends State<PartyManagePage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    if (!s.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!s.onboarded || s.orgId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Finish onboarding your organization to manage parties.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => PartiesController(
        db: context.read<AppDatabase>(),
        settings: s,
      ),
      child: Scaffold(
        body: SafeArea(
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                SegmentedTabs(
                  tabs: const [
                    (Icons.dashboard_customize_rounded, 'Customers'),
                    (Icons.person, 'Suppliers'),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _PartyListTab(type: PartyType.customer),
                      _PartyListTab(type: PartyType.vendor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartyListTab extends StatefulWidget {
  const _PartyListTab({required this.type});
  final PartyType type;

  @override
  State<_PartyListTab> createState() => _PartyListTabState();
}

class _PartyListTabState extends State<_PartyListTab> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Update controller query on each text change
    _searchCtrl.addListener(() {
      context.read<PartiesController>().setQuery(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PartiesController>();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _searchFilterBar(
          context,
          controller: _searchCtrl,
          onAdd: () => _openPartyDialog(context, type: widget.type),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 750;
              return StreamBuilder<List<PartyVM>>(
                stream: ctrl.watchParties(widget.type),
                builder: (context, snap) {
                  final items = snap.data ?? const <PartyVM>[];
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No ${widget.type == PartyType.customer ? 'customers' : 'suppliers'} found.',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    );
                  }

                  return wide
                      ? _PartyTableWide(
                          items: items,
                          onEdit: (p) => _openPartyDialog(context, existing: p),
                          onDelete: (p) => _deleteParty(context, p.id),
                        )
                      : _PartyCardsNarrow(
                          items: items,
                          onEdit: (p) => _openPartyDialog(context, existing: p),
                          onDelete: (p) => _deleteParty(context, p.id),
                        );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Search + Filter + Add
  Widget _searchFilterBar(
    BuildContext context, {
    required TextEditingController controller,
    required VoidCallback onAdd,
  }) {
    final isCompact = MediaQuery.of(context).size.width < 520;

    final searchField = TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: "Search name / phone / email / GSTIN...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );

    final addBtn = FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add),
      label: Text('Add ${widget.type == PartyType.customer ? 'Customer' : 'Supplier'}'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 8),
            addBtn,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: searchField),
          const SizedBox(width: 12),
          addBtn,
        ],
      ),
    );
  }

  Future<void> _openPartyDialog(BuildContext context, {PartyVM? existing, PartyType? type}) async {
    final ctrl = context.read<PartiesController>();
    final name = TextEditingController(text: existing?.name ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final gstin = TextEditingController(text: existing?.gstin ?? '');
    PartyType pType = existing?.type ?? type ?? PartyType.customer;
    final formKey = GlobalKey<FormState>();

    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existing == null ? 'Add ${pType == PartyType.customer ? 'Customer' : 'Supplier'}' : 'Edit Party'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<PartyType>(
                  value: pType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: PartyType.customer, child: Text('Customer')),
                    DropdownMenuItem(value: PartyType.vendor, child: Text('Supplier')),
                    DropdownMenuItem(value: PartyType.both, child: Text('Both')),
                  ],
                  onChanged: (v) => pType = v ?? pType,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: req,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: gstin,
                  decoration: const InputDecoration(labelText: 'GSTIN'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                if (existing == null) {
                  await ctrl.createParty(
                    type: pType,
                    name: name.text,
                    phone: phone.text,
                    email: email.text,
                    gstin: gstin.text,
                  );
                } else {
                  await ctrl.updateParty(
                    id: existing.id,
                    type: pType,
                    name: name.text,
                    phone: phone.text,
                    email: email.text,
                    gstin: gstin.text,
                  );
                }
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? 'Party created' : 'Party updated')),
      );
    }
  }

  Future<void> _deleteParty(BuildContext context, int id) async {
    final ctrl = context.read<PartiesController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete party?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ctrl.deleteParty(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party deleted')));
      }
    } catch (e) {
      // Likely FK constraint (party used in quotes/invoices/payments)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete: party is used in documents.')),
        );
      }
    }
  }
}

/* ========================= Wide table ========================= */

class _PartyTableWide extends StatelessWidget {
  const _PartyTableWide({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PartyVM> items;
  final void Function(PartyVM) onEdit;
  final void Function(PartyVM) onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget head(String t, {int flex = 1}) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(t,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    )),
          ),
        );

    Widget row(PartyVM p) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(p.name, overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 2, child: Text(p.phone ?? '—')),
                  Expanded(flex: 2, child: Text(p.email ?? '—')),
                  Expanded(flex: 2, child: Text(p.gstin ?? '—')),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _typePill(p.type),
                    ),
                  ),
                  SizedBox(
                    width: 112,
                    child: Row(
                      children: [
                        IconButton(onPressed: () => onEdit(p), icon: const Icon(Icons.edit_outlined)),
                        IconButton(onPressed: () => onDelete(p), icon: const Icon(Icons.delete_outline)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
          ],
        );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              head('Name', flex: 3),
              head('Phone', flex: 2),
              head('Email', flex: 2),
              head('GSTIN', flex: 2),
              head('Type', flex: 2),
              const SizedBox(width: 112, child: Text('Actions')),
            ],
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          for (final p in items) row(p),
        ],
      ),
    );
  }

  Widget _typePill(PartyType t) {
    final isDark = t == PartyType.customer;
    final bg = isDark ? const Color(0xFF0B0B14) : const Color(0xFFF2F4F7);
    final fg = isDark ? Colors.white : const Color(0xFF101828);
    final label = switch (t) {
      PartyType.customer => 'Customer',
      PartyType.vendor => 'Supplier',
      PartyType.both => 'Both',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

/* ========================= Narrow cards ========================= */

class _PartyCardsNarrow extends StatelessWidget {
  const _PartyCardsNarrow({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PartyVM> items;
  final void Function(PartyVM) onEdit;
  final void Function(PartyVM) onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name + actions
                Row(
                  children: [
                    Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                    IconButton(onPressed: () => onEdit(p), icon: const Icon(Icons.edit_outlined)),
                    IconButton(onPressed: () => onDelete(p), icon: const Icon(Icons.delete_outline)),
                  ],
                ),
                const SizedBox(height: 6),
                if ((p.phone ?? '').isNotEmpty) Text('📞 ${p.phone}'),
                if ((p.email ?? '').isNotEmpty) Text('✉️ ${p.email}'),
                if ((p.gstin ?? '').isNotEmpty) Text('GSTIN: ${p.gstin}'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.surfaceVariant.withOpacity(.45),
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(_typeLabel(p.type), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _typeLabel(PartyType t) => switch (t) {
        PartyType.customer => 'Customer',
        PartyType.vendor => 'Supplier',
        PartyType.both => 'Both',
      };
}
