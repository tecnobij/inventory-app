import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:bhago/features/dashboard/presentation/dashboard_view.dart';
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

  bool _seeded = false;
  bool _dirty = false;

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
            // Header row with "Settings" and a session-only Skip (won’t show normally)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Settings',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  // (optional) quick exit if you ever reuse this screen as start
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Skip for now'),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const DashboardView()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: _SegmentedTabs(
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

    InputDecoration _soft(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary),
          ),
        );

    Widget _title(String s, {bool req = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(s, style: Theme.of(context).textTheme.labelLarge),
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
                    icon: const Icon(Icons.add),
                    label: const Text('Add Location'),
                    onPressed: () => setState(() => _locations.add(_LocationCtrls())),
                  ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Session-only skip: do NOT set onboarded
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const DashboardView()),
                        );
                      },
                      child: const Text('Skip for now'),
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
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary),
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
            TextFormField(controller: l.name, decoration: _soft('Warehouse Name')),
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
  Widget _numberingTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            header: const _CardHeader(title: 'Numbering Rules'),
            child: Column(
              children: [
                _labeledField(
                  label: 'Invoice Prefix',
                  controller: TextEditingController(text: 'INV-'),
                  icon: Icons.confirmation_number_outlined,
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                _labeledField(
                  label: 'Start From',
                  controller: TextEditingController(text: '1001'),
                  icon: Icons.filter_1_outlined,
                  keyboardType: TextInputType.number,
                  readOnly: true,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _appSettingsTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            header: const _CardHeader(title: 'Notifications'),
            child: Column(
              children: const [
                _SwitchRow('Low-stock alerts'),
                _SwitchRow('Daily summary email'),
              ],
            ),
          ),
        ],
      );

  Widget _usersTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            header: _CardHeader(
              title: 'Users',
              trailing: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Invite User'),
              ),
            ),
            child: Column(
              children: const [
                _UserRow('Amit Chopra', 'Owner'),
                _UserRow('Riya Sharma', 'Manager'),
              ],
            ),
          ),
        ],
      );

  // ===================================================================
  // Shared UI utilities (unchanged)
  // ===================================================================

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
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
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
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant.withOpacity(.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _readOnlyChip(String text) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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

        InputDecoration _soft(String hint) => InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: scheme.surfaceVariant.withOpacity(.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant, width: 1.2),
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
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAdd ? 'Add New Warehouse' : 'Edit Warehouse',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Warehouse Name', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(controller: nameCtrl, decoration: _soft('Enter warehouse name')),
                      const SizedBox(height: 16),
                      Text('Address', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(controller: addrCtrl, decoration: _soft('Enter complete address')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Switch.adaptive(
                            activeColor: Colors.black,
                            value: active, onChanged: (v) => setState(() => active = v)),
                          const SizedBox(width: 8),
                          Text('Active', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                final r = _WhRow(nameCtrl.text.trim(), addrCtrl.text.trim(), active);
                                Navigator.pop(context, r);
                              },
                              child: Text(isAdd ? 'Add Warehouse' : 'Save Changes'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
          _warehouses[index!] = row;
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: TabBar(
        isScrollable: true,
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        indicator: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant),
        ),
        dividerColor: Colors.transparent,
        tabs: [
          for (final t in tabs)
            Tab(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$1, size: 18),
                    const SizedBox(width: 8),
                    Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
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
    final border = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tableHeader(context),
        const SizedBox(height: 8),
        for (var i = 0; i < rows.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
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
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _tableHeader(BuildContext context) {
    final grey = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
  const _CardHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
