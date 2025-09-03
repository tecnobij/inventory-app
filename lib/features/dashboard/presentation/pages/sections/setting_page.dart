import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/presentation/dashboard_view.dart';
import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We assume SettingsProvider is provided at app root (as in your main()).
    // If not, wrap this with a ChangeNotifierProvider<SettingsProvider>()..load()
    return const _SettingsPageInner();
  }
}

class _SettingsPageInner extends StatefulWidget {
  const _SettingsPageInner();

  @override
  State<_SettingsPageInner> createState() => _SettingsPageInnerState();
}

class _SettingsPageInnerState extends State<_SettingsPageInner> {
  // ---------- Common controllers (also used by onboarding) ----------
  final _formKey = GlobalKey<FormState>();
  final _orgCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController(); // used only in full settings
  final _logoCtrl = TextEditingController(text: 'No file chosen');
// Application Settings state
String _currency = 'INR (₹)';
String _dateFmt  = 'DD/MM/YYYY';
String _gstPct   = '18%';
final TextEditingController _lowStockCtrl = TextEditingController(text: '10');
bool _notif = true;

final _currencyOpts = const ['INR (₹)', 'USD ()', 'EUR (€)'];
final _dateFmtOpts  = const ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];
final _gstOpts      = const ['0%', '5%', '12%', '18%', '28%'];



  bool _seeded = false;
  bool _dirty = false;
bool _resetCounters = false; // for the "Reset Numbering Counters" switch

  // Warehouses (Settings tab)
  final List<_WhRow> _warehouses = [
    _WhRow('Main Warehouse', '123 Industrial Area, Mumbai', true),
    _WhRow('Secondary Warehouse', '456 Storage Complex, Delhi', false),
  ];

  // Onboarding locations
  final List<_LocationCtrls> _locations = [ _LocationCtrls() ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.watch<SettingsProvider>();
    if (p.loaded && !_seeded) {
      _orgCtrl.text = p.orgName;
      _ownerCtrl.text = p.ownerName;
      _emailCtrl.text = p.email;
      _phoneCtrl.text = p.phone;
      _gstCtrl.text = p.gst;
      _addressCtrl.text = p.address;
      _seeded = true;
    }
  }

  @override
  void dispose() {
     _lowStockCtrl.dispose();
    _orgCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _gstCtrl.dispose();
    _addressCtrl.dispose();
    _ownerCtrl.dispose();
    _logoCtrl.dispose();
    for (final l in _locations) { l.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SettingsProvider>();

    if (!p.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ---------- FIRST RUN: Onboarding card ----------
    if (!p.onboarded) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _onboardingCard(context, p),
            ],
          ),
        ),
      );
    }

    // ---------- RETURNING USER: Tabbed Settings ----------
    return Scaffold(
      
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
         
           
            const SizedBox(height: 8),
            Padding(
  padding: const EdgeInsets.symmetric(horizontal: 9),
  child: SegmentedTabs(
    tabs: const [
      (Icons.apartment_outlined, 'Organization'),
      (Icons.tag_outlined, 'Numbering'),
      (Icons.notifications_none_outlined, 'App Settings'),
      (Icons.group_outlined, 'Users'),
    ],
  ),
),

            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _orgTab(context),      // Organization tab (your existing form)
                  _numberingTab(),
                  _appSettingsTab(),
                  _usersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // ONBOARDING (first screenshot)
  // ===================================================================

  Widget _onboardingCard(BuildContext context, SettingsProvider p) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.of(context).size.width >= 900;

    // local validator for email/org
    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
    String? email(String? v) {
      if (req(v) != null) return 'Required';
      final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      return re.hasMatch(v!.trim()) ? null : 'Invalid email';
    }
String? phone(String? v) {
  if (req(v) != null) return 'Required';
  final digits = v!.replaceAll(RegExp(r'\D'), '');
  return (digits.length >= 7 && digits.length <= 13)
      ? null
      : 'Enter a valid phone number';
}

String? gstin(String? v) {
  if (req(v) != null) return 'Required';
  final s = v!.trim().toUpperCase();
  final re = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
  return re.hasMatch(s) ? null : 'Invalid GSTIN';
}
    InputDecoration _soft(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        );

    Widget _title(String s, {bool req = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(s, style: TextStyle(fontWeight: FontWeight.bold)),
            if (req) const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    Widget _twoCol(Widget a, Widget b) {
      if (!wide) return Column(children: [a, const SizedBox(height: 12), b]);
      return Row(children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Set up your organization',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can manage multiple organizations later from the header.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Org + Email
              _twoCol(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Organization Name', req: true),
                    TextFormField(
                      controller: _orgCtrl,
                      validator: req,
                      decoration: _soft('Enter organization name'),
                      onChanged: (_) => setState(() => _dirty = true),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Business Email', req: true),
                    TextFormField(
                      controller: _emailCtrl,
                      validator: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _soft('admin@company.com'),
                      onChanged: (_) => setState(() => _dirty = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Phone + GSTIN
              _twoCol(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Phone'),
                    TextFormField(
                      controller: _phoneCtrl,
                       validator: phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                      decoration: _soft('+91 98765 43210'),
                      onChanged: (_) => setState(() => _dirty = true),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('GSTIN'),
                    TextFormField(
                      controller: _gstCtrl,
                       validator: gstin,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _soft('22AAAAA0000A1Z5'),
                      onChanged: (_) => setState(() => _dirty = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Address full width
              _title('Address'),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: _soft('Enter complete address'),
                onChanged: (_) => setState(() => _dirty = true),
              ),
              const SizedBox(height: 18),

              // Locations header + Add
              Row(
                children: [
                  Text('Warehouse Locations',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                 OutlinedButton.icon(
  icon: const Icon(Icons.add,),
  label: const Text('Add Location',style: TextStyle(fontWeight: FontWeight.bold,),),
  onPressed: () => setState(() => _locations.add(_LocationCtrls())),
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // <- radius
    ),
    side: BorderSide(
      color: Colors.grey.shade400,             // <- grey border
      width: 1.2,
    ),
    foregroundColor: Theme.of(context).colorScheme.onSurface,
  ),
)
                ],
              ),
              const SizedBox(height: 10),

              // Location cards
              for (int idx = 0; idx < _locations.length; idx++) ...[
                _locationCard(idx, scheme, wide),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),

              // Logo upload
              Text('Logo Upload', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
             Row(
  children: [
    OutlinedButton.icon(
      onPressed: () {
        setState(() => _logoCtrl.text = 'company_logo.png');
      },
      icon: const Icon(Icons.upload_file_outlined),
      label: const Text('Choose file'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // ↓ reduced radius
        ),
        side: BorderSide(
          color: Colors.transparent,           // ← grey border
          width: 1.2,
        ),
        //foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    const SizedBox(width: 10),
    Expanded(child: _readOnlyChip(_logoCtrl.text)),
  ],
),

              const SizedBox(height: 18),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        await context.read<SettingsProvider>().saveFrom(
                          orgName: _orgCtrl.text.trim(),
                          ownerName: _ownerCtrl.text.trim(),
                          email: _emailCtrl.text.trim(),
                          phone: _phoneCtrl.text.trim(),
                          gst: _gstCtrl.text.trim().toUpperCase(),
                          address: _addressCtrl.text.trim(),
                          city: _locations.first.city.text.trim(),
                          stateName: _locations.first.state.text.trim(),
                          pincode: _locations.first.pincode.text.trim(),
                        );
                        // mark onboarded so next time we show the tabs screen
                        // implement setOnboarded in your provider if missing
                        await context.read<SettingsProvider>().setOnboarded(true);
                        if (!mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const DashboardView()),
                        );
                      },
                      child: const Text('Create Organization'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                           side: BorderSide(
          color: Colors.grey.shade400,           // ← grey border
          width: 0.4
        ),
                      ),
                      onPressed: () {
                        // Session-only skip: do NOT set onboarded
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const DashboardView()),
                        );
                      },
                      child: const Text('Skip for now',style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationCard(int index, ColorScheme scheme, bool wide) {
    final l = _locations[index];

    InputDecoration _soft(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
         border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        );

    Widget twoCol(Widget a, Widget b) {
      if (!wide) return Column(children: [a, const SizedBox(height: 12), b]);
      return Row(children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location ${index + 1}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          twoCol(
            TextFormField(controller: l.name, decoration: _soft('Warehouse Name'),
            
            ),
            TextFormField(controller: l.address, decoration: _soft('Address')),
          ),
          const SizedBox(height: 12),
          twoCol(
            TextFormField(controller: l.city, decoration: _soft('City')),
            TextFormField(controller: l.state, decoration: _soft('State')),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: wide ? 320 : double.infinity,
            child: TextFormField(
              controller: l.pincode,
              decoration: _soft('Pincode'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // EXISTING SETTINGS TABS (second screenshot)
  // ===================================================================

  Widget _orgTab(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.of(context).size.width >= 900;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Organization Profile
        _SectionCard(
          header: const _CardHeader(title: 'Organization Profile'),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _grid(
                  wide,
                  children: [
                    _labeledField(
                      label: 'Organization Name',
                      controller: _orgCtrl,
                      icon: Icons.business_outlined,
                      validator: _req,
                    ),
                    _labeledField(
                      label: 'GSTIN',
                      controller: _gstCtrl,
                      icon: Icons.verified_outlined,
                      textCap: TextCapitalization.characters,
                      validator: _gst,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _labeledField(
                  label: 'Address',
                  controller: _addressCtrl,
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: _req,
                ),
                const SizedBox(height: 12),
                Text('Organization Logo',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onSurface)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _logoCtrl.text = 'company_logo.png';
                          _dirty = true;
                        });
                      },
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Choose file'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _readOnlyChip(_logoCtrl.text)),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    await context.read<SettingsProvider>().saveFrom(
                      orgName: _orgCtrl.text.trim(),
                      ownerName: _ownerCtrl.text.trim(),
                      email: _emailCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim(),
                      gst: _gstCtrl.text.trim().toUpperCase(),
                      address: _addressCtrl.text.trim(),
                      city: '',
                      stateName: '',
                      pincode: '',
                    );
                    if (!mounted) return;
                    setState(() => _dirty = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Warehouses
        _SectionCard(
          header: _CardHeader(
            title: 'Warehouses',
            trailing: FilledButton.icon(
              onPressed: () => _openWarehouseDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Warehouse'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          child: _WarehousesTable(
            rows: _warehouses,
            onToggle: (i, v) => setState(() => _warehouses[i].enabled = v),
            onDelete: (i) => setState(() => _warehouses.removeAt(i)),
            onEdit: (i) => _editWarehouse(context, i),
          ),
        ),

        const SizedBox(height: 20),

        // Account actions
        _SectionCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Actions',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Manage your account and session',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () {/* logout */},
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE4E2),
                  foregroundColor: const Color(0xFFB42318),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----- tabs stubs you already had -----
Widget _numberingTab() {
  final theme = Theme.of(context);
  final wide  = MediaQuery.of(context).size.width >= 900;

  // Demo controllers (you can bind to real values later)
  final poCtrl   = TextEditingController(text: 'FY/PO/######');
  final soCtrl   = TextEditingController(text: 'FY/SO/######');
  final invCtrl  = TextEditingController(text: 'FY/INV/######');
  final quoCtrl  = TextEditingController(text: 'FY/QUO/######');

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _SectionCard(
        header: const _CardHeader(title: 'Document Numbering Patterns'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1
            _grid(
              wide,
              children: [
                _labeledField(
                  label: 'Purchase Order Pattern',
                  controller: poCtrl,
                  icon: Icons.shopping_cart_checkout_outlined,
                ),
                _labeledField(
                  label: 'Sales Order Pattern',
                  controller: soCtrl,
                  icon: Icons.local_shipping_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2
            _grid(
              wide,
              children: [
                _labeledField(
                  label: 'Invoice Pattern',
                  controller: invCtrl,
                  icon: Icons.receipt_long_outlined,
                ),
                _labeledField(
                  label: 'Quote Pattern',
                  controller: quoCtrl,
                  icon: Icons.description_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // FY / # hint
            _tipBanner(
              icon: Icons.warning_amber_rounded,
              text:
                  'Use FY for financial year, # for auto-incrementing numbers. '
                  'Example: FY/PO/###### becomes FY24-25/PO/00001',
            ),
            const SizedBox(height: 12),

            // Reset counters row with a switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reset Numbering Counters',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Reset all document counters to start from 1',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: .90, // slightly shorter, like the mock
                    child: Switch.adaptive(
                      value: _resetCounters,
                      onChanged: (v) => setState(() => _resetCounters = v),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Save button (black)
            SizedBox(
              width: 200,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Numbering settings saved')),
                  );
                },
                child: const Text('Save Numbering Settings'),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 30),
      const Divider(),

      // Account actions section (matches screenshot)
      const SizedBox(height: 12),
      _SectionCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account Actions',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Manage your account and session',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () { /* TODO: logout */ },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFEE4E2),
                foregroundColor: const Color(0xFFB42318),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 12),
      Center(
        child: Text(
          'Ctrl+K for quick search • Alt+N for new item',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(height: 8),
    ],
  );
}
//app setting

 Widget _appSettingsTab() {
  final theme = Theme.of(context);
  final wide  = MediaQuery.of(context).size.width >= 900;

  InputDecoration _filled([String? hint]) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(.45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // no visible border (like the mock)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s, style: theme.textTheme.labelLarge),
      );

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        DropdownButtonFormField<String>(
          value: value,
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => onChanged(v!),
          decoration: _filled(),
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _filled(),
        ),
      ],
    );
  }

  Widget _notificationsTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Receive notifications for low stock, payments due, etc.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _notif,
            onChanged: (v) => setState(() => _notif = v),
            activeTrackColor: Colors.black,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // grid-like rows (2 columns on wide screens)
  Widget _row(Widget a, Widget b) => wide
      ? Row(children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)])
      : Column(children: [a, const SizedBox(height: 12), b]);

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _SectionCard(
        header: const _CardHeader(
          title: 'Application Settings',
          leadingIcon: Icons.notifications_outlined, // see change in step 3
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(
              _dropdown(
                label: 'Currency',
                value: _currency,
                options: _currencyOpts,
                onChanged: (v) => setState(() => _currency = v),
              ),
              _dropdown(
                label: 'Date Format',
                value: _dateFmt,
                options: _dateFmtOpts,
                onChanged: (v) => setState(() => _dateFmt = v),
              ),
            ),
            const SizedBox(height: 14),
            _row(
              _dropdown(
                label: 'Default GST %',
                value: _gstPct,
                options: _gstOpts,
                onChanged: (v) => setState(() => _gstPct = v),
              ),
              _textField(
                label: 'Low Stock Threshold',
                controller: _lowStockCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 16),
            _notificationsTile(),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // TODO: persist app settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App settings saved')),
                );
              },
              child: const Text('Save App Settings'),
            ),
          ],
        ),
      ),
    ],
  );
}
//userTab
Widget _usersTab() {
  final theme = Theme.of(context);

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _SectionCard(
        // no header — the whole card is the centered empty state
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'User Management',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage users and roles for your organization',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 18),

                // Grey “Coming Soon” pill
                FilledButton.icon(
                  onPressed: null, // disabled
                  icon: const Icon(Icons.add),
                  label: const Text('Add User (Coming Soon)'),
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: const Color(0xFF6B7280), // gray 500
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'User management and role-based access control will be available soon',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  // ===================================================================
  // Shared UI utilities (unchanged)
  // ===================================================================
// Tip / hint banner like the mock
Widget _tipBanner({required IconData icon, required String text}) {
  final theme = Theme.of(context);
  return Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceVariant.withOpacity(.35),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _grid(bool wide, {required List<Widget> children}) {
    if (!wide) return Column(children: _withSpacing(children, 12));
    return Row(children: [Expanded(child: children[0]), const SizedBox(width: 12), Expanded(child: children[1])]);
  }

  List<Widget> _withSpacing(List<Widget> items, double gap) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) out.add(SizedBox(height: gap));
    }
    return out;
  }
Widget _labeledField({
  required String label,
  required TextEditingController controller,
  required IconData icon,
  String? Function(String?)? validator,
  int maxLines = 1,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  TextCapitalization textCap = TextCapitalization.none,
  bool readOnly = false,
}) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        textCapitalization: textCap,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: (_) => setState(() => _dirty = true),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

          // ⬇️ No borders, but keep the rounded corners
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
}


Widget _readOnlyChip(String text) {
  final theme = Theme.of(context);
  return Container(
    height: 46,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceVariant.withOpacity(.5),
      borderRadius: BorderRadius.circular(16),                // ↓ reduced radius
      border:null, // grey
    ),
    child: Text(text, style: theme.textTheme.bodyMedium),
  );
}


  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _gst(String? v) {
    if (_req(v) != null) return 'Required';
    final s = v!.trim().toUpperCase();
    final re = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return re.hasMatch(s) ? null : 'Invalid GSTIN format';
  }

  // ---------- Warehouses helpers ----------
  Future<void> _editWarehouse(BuildContext context, int i) async =>
      _openWarehouseDialog(index: i);

Future<void> _openWarehouseDialog({int? index}) async {
  final isAdd = index == null;
  final nameCtrl = TextEditingController(text: isAdd ? '' : _warehouses[index!].name);
  final addrCtrl = TextEditingController(text: isAdd ? '' : _warehouses[index!].address);
  bool active = isAdd ? true : _warehouses[index!].enabled;

  final row = await showDialog<_WhRow>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final formKey = GlobalKey<FormState>();

      String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

      InputDecoration _soft(String hint) => InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: scheme.surfaceVariant.withOpacity(.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant, width: 0.6),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outline, width: 1.6),
            ),
          );

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title + close
                      Row(
                        children: [
                          Text(
                            isAdd ? 'Add New Warehouse' : 'Edit Warehouse',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), tooltip: 'Close'),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Warehouse Name (required)
                      Text('Warehouse Name', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: _soft('Enter warehouse name'),
                        validator: _req,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // Address (required)
                      Text('Address', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: addrCtrl,
                        decoration: _soft('Enter complete address'),
                        validator: _req,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // Active switch
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.70,
                            alignment: Alignment.centerLeft,
                            child: Switch.adaptive(
                              value: active,
                              onChanged: (v) => setState(() => active = v),
                              activeColor: Colors.white,
                              activeTrackColor: Colors.black,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Active', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                // ✅ Validate required fields
                                if (!formKey.currentState!.validate()) return;
                                final r = _WhRow(
                                  nameCtrl.text.trim(),
                                  addrCtrl.text.trim(),
                                  active,
                                );
                                Navigator.pop(context, r);
                              },
                              child: Text(isAdd ? 'Add Warehouse' : 'Save Changes'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );

  if (row != null) {
    setState(() {
      if (isAdd) {
        _warehouses.add(row);
      } else {
        _warehouses[index] = row;
      }
    });
  }
}

}

// ===== Segmented tabs (unchanged) =================================
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.tabs});
  final List<(IconData, String)> tabs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start, // ← LEFT ALIGN TABS
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: const EdgeInsets.symmetric(horizontal: 18),
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurface,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          tabs: [
            for (final t in tabs)
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$1, size: 18),
                    const SizedBox(width: 10),
                    Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===== Warehouses table (unchanged) ===============================
class _WhRow {
  _WhRow(this.name, this.address, this.enabled);
  String name;
  String address;
  bool enabled;
}

class _WarehousesTable extends StatelessWidget {
  const _WarehousesTable({
    required this.rows,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final List<_WhRow> rows;
  final void Function(int index, bool value) onToggle;
  final void Function(int index) onDelete;
  final void Function(int index) onEdit;

  @override
  Widget build(BuildContext context) {
   
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding:  EdgeInsets.symmetric(
            vertical: 2
          ),
          child: _tableHeader(context),
        ),
          fullBleedDivider(context),
       
        const SizedBox(height: 8),
        for (var i = 0; i < rows.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
           
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(rows[i].name)),
                Expanded(flex: 4, child: Text(rows[i].address)),
                SizedBox(
                  width: 64,
                  child: Switch.adaptive(value: rows[i].enabled, onChanged: (v) => onToggle(i, v)),
                ),
                Row(
                  children: [
                    IconButton(tooltip: 'Edit', onPressed: () => onEdit(i), icon: const Icon(Icons.edit_outlined)),
                    IconButton(tooltip: 'Delete', onPressed: () => onDelete(i), icon: const Icon(Icons.delete_outline)),
                  ],
                ),
              ],
            ),
          ),
          
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 5
          ),
          child: fullBleedDivider(context),
        ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
// Put this helper near the widget (file-level or inside the class)
Widget fullBleedDivider(BuildContext context, {double bleed = 16}) {
  final color = Theme.of(context).dividerColor;
  return SizedBox(
    height: 0.3,
    child: Stack(
      clipBehavior: Clip.none, // allow horizontal overflow
      children: [
        Positioned(
          left: -bleed,  // extend beyond the card’s left padding
          right: -bleed, // extend beyond the card’s right padding
          top: 0,
          bottom: 0,
          child: Container(color: color),
        ),
      ],
    ),
  );
}

  Widget _tableHeader(BuildContext context) {
    final grey = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Name', style: TextStyle(color: grey))),
          Expanded(flex: 4, child: Text('Address', style: TextStyle(color: grey))),
          SizedBox(width: 64, child: Text('Status', style: TextStyle(color: grey))),
          const SizedBox(width: 96, child: Text('Actions')),
        ],
      ),
    );
  }
}

// ===== Common card shell (unchanged) ==============================
class _SectionCard extends StatelessWidget {
  const _SectionCard({this.header, required this.child});
  final _CardHeader? header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.trailing, this.leadingIcon});
  final String title;
  final Widget? trailing;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 22),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}


// ===== Small items (unchanged) ===================================
class _SwitchRow extends StatefulWidget {
  const _SwitchRow(this.label, {super.key});
  final String label;

  @override
  State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
  bool v = true;
  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(widget.label)),
          Switch.adaptive(value: v, onChanged: (x) => setState(() => v = x)),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow(this.name, this.role, {super.key});
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).colorScheme.outlineVariant;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: scheme.surfaceVariant, child: Text(name.isNotEmpty ? name[0] : '?')),
          const SizedBox(width: 10),
          Expanded(child: Text(name)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: scheme.surfaceVariant.withOpacity(.6), borderRadius: BorderRadius.circular(999)),
            child: Text(role, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ===== Helper for onboarding locations ============================
class _LocationCtrls {
  final name = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final pincode = TextEditingController();
  void dispose() {
    name.dispose();
    address.dispose();
    city.dispose();
    state.dispose();
    pincode.dispose();
  }
}
