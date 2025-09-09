// lib/features/sales/widgets/add_customer_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

import 'package:bhago/app/data/local_database.dart';
import 'package:bhago/features/dashboard/controller/settings_controller.dart';

class AddCustomerButton extends StatelessWidget {
  const AddCustomerButton({super.key, this.onAdded});
  final void Function(Parties newParty)? onAdded;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Add Customer'),
      onPressed: () => _openDialog(context),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    final payload = await showDialog<_NewCustomer>(
      context: context,
      builder: (ctx) => const _AddCustomerDialog(),
    );
    if (payload == null) return;

    final db = context.read<AppDatabase>();
    final settings = context.read<SettingsProvider>();

    // resolve orgId (prefer provider, else first org)
    int? orgId;
    try { orgId = (settings as dynamic).orgId as int?; } catch (_) {}
    orgId ??= await _firstOrgId(db);

    final id = await db.into(db.parties).insert(
      PartiesCompanion.insert(
        orgId: orgId!,
        name: payload.name,
        phone: drift.Value(payload.phone.isEmpty ? null : payload.phone),
        email: const drift.Value(null),
        gstin: const drift.Value(null),
        address: drift.Value(payload.address.isEmpty ? null : payload.address),
        farmName: drift.Value(payload.farmName.isEmpty ? null : payload.farmName),
        partyType: PartyType.customer,
        createdAt: drift.Value(DateTime.now()),
      ),
    );

    final saved =
        await (db.select(db.parties)..where((t) => t.id.equals(id))).getSingle();

    onAdded?.call(saved as Parties);

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Customer added')));
    }
  }

  Future<int> _firstOrgId(AppDatabase db) async {
    final org = await (db.select(db.organizations)..limit(1)).getSingle();
    return org.id;
  }
}

class _AddCustomerDialog extends StatefulWidget {
  const _AddCustomerDialog();
  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _farm = TextEditingController();
  final _addr = TextEditingController();

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _farm.dispose(); _addr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Text('Add Customer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                decoration: deco('Customer name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                decoration: deco('Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _farm,
                decoration: deco('Farm name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addr,
                decoration: deco('Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      Navigator.pop(
                        context,
                        _NewCustomer(
                          name: _name.text.trim(),
                          phone: _phone.text.trim(),
                          farmName: _farm.text.trim(),
                          address: _addr.text.trim(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NewCustomer {
  final String name;
  final String phone;
  final String farmName;
  final String address;
  _NewCustomer({required this.name, required this.phone, required this.farmName, required this.address});
}
