import 'package:bhago/features/dashboard/controller/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {

    return const _SettingsPageInner();
  }
}
class _SettingsPageInner extends StatefulWidget {
  const _SettingsPageInner();

  @override
  State<_SettingsPageInner> createState() => _SettingsPageInnerState();
}

class _SettingsPageInnerState extends State<_SettingsPageInner> {
  final _formKey = GlobalKey<FormState>();
  final _orgCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  bool _seeded = false;
  bool _dirty = false;

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
      _cityCtrl.text = p.city;
      _stateCtrl.text = p.stateName;
      _pincodeCtrl.text = p.pincode;
      _seeded = true;
    }
  }

  @override
  void dispose() {
    _orgCtrl.dispose();
    _ownerCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _gstCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.watch<SettingsProvider>();

    final gradient = const LinearGradient(
      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
     
      bottomNavigationBar: _actionBar(theme, p),
      body: p.loaded
          ? LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 900;

                final form = _decorCard(
                  child: Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _chipTitle(icon: Icons.apartment, label: 'Organization Details'),
                              const SizedBox(height: 18),
                              _grid(
                                wide,
                                children: [
                                  _field(_orgCtrl, 'Organization Name', Icons.business, _req),
                                  _field(_ownerCtrl, 'Owner / Shopkeeper Name', Icons.person, _req),
                                  _field(_emailCtrl, 'Email', Icons.email, _email,
                                      keyboardType: TextInputType.emailAddress,
                                      helper: 'Used on invoice & contact'),
                                  _field(_phoneCtrl, 'Phone', Icons.call, _phone,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(13),
                                      ]),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _chipTitle(icon: Icons.receipt_long, label: 'Tax & Address'),
                              const SizedBox(height:18),
                              _grid(
                                wide,
                                children: [
                                  _field(_gstCtrl, 'GST Number', Icons.verified, _gst,
                                      textCap: TextCapitalization.characters,
                                      helper: '15-char GSTIN, auto uppercased'),
                                  _field(_addressCtrl, 'Address', Icons.location_on, _req, maxLines: 2),
                                  _field(_cityCtrl, 'City', Icons.location_city, _req),
                                  _field(_stateCtrl, 'State', Icons.map, _req),
                                  _field(_pincodeCtrl, 'Pincode', Icons.numbers, _pin,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(6),
                                      ]),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _tipBanner(
                                icon: Icons.info_outline,
                                text:
                                    'These details will appear on invoices, headers, and exports. Keep them accurate.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );

                final preview = _decorCard(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Padding(
                      key: ValueKey('${p.orgName}_${p.gst}_${p.email}_${p.phone}_${p.pincode}'),
                      padding: const EdgeInsets.all(16),
                      child: _savedPreview(theme, p, gradient),
                    ),
                  ),
                );

                return Container(
                  decoration: const BoxDecoration(
                  
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: form),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: preview),
                            ],
                          )
                        : ListView(
                            children: [
                              form,
                              const SizedBox(height: 16),
                              preview,
                              const SizedBox(height: 72), // space for bottom bar
                            ],
                          ),
                  ),
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  // ---------- Action bar (sticky bottom) ----------
  Widget _actionBar(ThemeData theme, SettingsProvider p) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        color: theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10 + 10), // +10 for safe area-ish
      child: Row(
        children: [
          _dirty
              ? Row(children: [
                  const _Dot(color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Unsaved changes', style: theme.textTheme.bodyMedium),
                ])
              : Row(children: [
                  const _Dot(color: Colors.green),
                  const SizedBox(width: 8),
                  Text('All changes saved', style: theme.textTheme.bodyMedium),
                ]),
          const Spacer(),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Form'),
            onPressed: () {
              _resetControllers();
              setState(() => _dirty = true);
            },
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              await context.read<SettingsProvider>().saveFrom(
                    orgName: _orgCtrl.text.trim(),
                    ownerName: _ownerCtrl.text.trim(),
                    email: _emailCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                    gst: _gstCtrl.text.trim().toUpperCase(),
                    address: _addressCtrl.text.trim(),
                    city: _cityCtrl.text.trim(),
                    stateName: _stateCtrl.text.trim(),
                    pincode: _pincodeCtrl.text.trim(),
                  );
              if (!mounted) return;
              setState(() => _dirty = false);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Settings saved')));
            },
          ),
        ],
      ),
    );
  }

  // ---------- UI helpers ----------
  Widget _decorCard({required Widget child}) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.white,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: child,
      ),
    );
  }

  Widget _chipTitle({required IconData icon, required String label}) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color.fromARGB(255, 148, 142, 176), Color.fromARGB(255, 51, 66, 117)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    );
  }

  Widget _grid(bool wide, {required List<Widget> children}) {
    final colCount = wide ? 2 : 1;
    return GridView.count(
      crossAxisCount: colCount,
      childAspectRatio: wide ? 4.6 : 3.8,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon,
    String? Function(String?) validator, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? helper,
    TextCapitalization textCap = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      textCapitalization: textCap,
      validator: validator,
      keyboardType: keyboardType ?? _keyboardTypeFor(label),
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() => _dirty = true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        helperText: helper,
        prefixIcon: Icon(icon),
        suffixIcon: c.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close),
                onPressed: () {
                  c.clear();
                  setState(() => _dirty = true);
                },
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  TextInputType _keyboardTypeFor(String label) {
    if (label.contains('Email')) return TextInputType.emailAddress;
    if (label.contains('Phone') || label.contains('Pincode')) return TextInputType.number;
    return TextInputType.text;
  }

  // ---------- Validators ----------
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _email(String? v) {
    if (_req(v) != null) return 'Required';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(v!.trim()) ? null : 'Invalid email';
  }

  String? _phone(String? v) {
    if (_req(v) != null) return 'Required';
    final s = v!.replaceAll(RegExp(r'[^0-9]'), '');
    return (s.length >= 7 && s.length <= 13) ? null : 'Invalid phone';
  }

  // Full GSTIN format check
  String? _gst(String? v) {
    if (_req(v) != null) return 'Required';
    final s = v!.trim().toUpperCase();
    final re = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return re.hasMatch(s) ? null : 'Invalid GSTIN format';
  }

  String? _pin(String? v) {
    if (_req(v) != null) return 'Required';
    final s = v!.trim();
    return RegExp(r'^\d{6}$').hasMatch(s) ? null : 'Invalid pincode';
  }

  // ---------- Preview ----------
  Widget _savedPreview(ThemeData theme, SettingsProvider p, Gradient badgeGradient) {
    final initials = _initials(p.orgName);
    final rows = <_KV>[
      _KV('Organization', p.orgName),
      _KV('Owner', p.ownerName),
      _KV('Email', p.email),
      _KV('Phone', p.phone),
      _KV('GST', p.gst),
      _KV('Address', p.address),
      _KV('City', p.city),
      _KV('State', p.stateName),
      _KV('Pincode', p.pincode),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.orgName.isEmpty ? '—' : p.orgName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(p.email.isEmpty ? 'No email' : p.email,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: badgeGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    p.gst.isEmpty ? 'GST —' : 'GST OK',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),
        ...rows.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(e.k, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.v.isEmpty ? '—' : e.v)),
                ],
              ),
            )),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('Load Saved'),
                onPressed: () {
                  final sp = context.read<SettingsProvider>();
                  _orgCtrl.text = sp.orgName;
                  _ownerCtrl.text = sp.ownerName;
                  _emailCtrl.text = sp.email;
                  _phoneCtrl.text = sp.phone;
                  _gstCtrl.text = sp.gst;
                  _addressCtrl.text = sp.address;
                  _cityCtrl.text = sp.city;
                  _stateCtrl.text = sp.stateName;
                  _pincodeCtrl.text = sp.pincode;
                  setState(() => _dirty = false);
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy JSON'),
                onPressed: () {
                  final jsonText =
                      '{'
                      '"orgName":"${p.orgName}","ownerName":"${p.ownerName}","email":"${p.email}",'
                      '"phone":"${p.phone}","gst":"${p.gst}","address":"${p.address}",'
                      '"city":"${p.city}","state":"${p.stateName}","pincode":"${p.pincode}"'
                      '}';
                  Clipboard.setData(ClipboardData(text: jsonText));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _resetControllers() {
    _orgCtrl.clear();
    _ownerCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _gstCtrl.clear();
    _addressCtrl.clear();
    _cityCtrl.clear();
    _stateCtrl.clear();
    _pincodeCtrl.clear();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'WM';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  Widget _tipBanner({required IconData icon, required String text}) {
  final theme = Theme.of(context);
  return Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.primaryContainer.withOpacity(0.18),
      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}

}

class _KV {
  final String k;
  final String v;
  _KV(this.k, this.v);
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({super.key, required this.color});
  @override
  Widget build(BuildContext context) =>
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
