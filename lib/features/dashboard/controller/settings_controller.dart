import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Stored values
  String orgName = '';
  String ownerName = '';
  String email = '';
  String phone = '';
  String gst = '';
  String address = '';
  String city = '';
  String stateName = '';
  String pincode = '';

  bool loaded = false;
  bool onboarded = false;

  // Keys
  static const _kOrgName   = 'org_name';
  static const _kOwnerName = 'owner_name';
  static const _kEmail     = 'email';
  static const _kPhone     = 'phone';
  static const _kGst       = 'gst';
  static const _kAddress   = 'address';
  static const _kCity      = 'city';
  static const _kState     = 'state';
  static const _kPincode   = 'pincode';
  static const _kOnboarded = 'settings_onboarded';

  // Decide if info is “complete enough”
  bool get isComplete =>
      orgName.isNotEmpty &&
      ownerName.isNotEmpty &&
      email.isNotEmpty &&
      phone.isNotEmpty &&
      gst.length == 15 &&
      address.isNotEmpty &&
      city.isNotEmpty &&
      stateName.isNotEmpty &&
      pincode.length == 6;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    orgName   = sp.getString(_kOrgName)   ?? '';
    ownerName = sp.getString(_kOwnerName) ?? '';
    email     = sp.getString(_kEmail)     ?? '';
    phone     = sp.getString(_kPhone)     ?? '';
    gst       = sp.getString(_kGst)       ?? '';
    address   = sp.getString(_kAddress)   ?? '';
    city      = sp.getString(_kCity)      ?? '';
    stateName = sp.getString(_kState)     ?? '';
    pincode   = sp.getString(_kPincode)   ?? '';
    onboarded = sp.getBool(_kOnboarded)   ?? false;
    loaded = true;
    notifyListeners();
  }

  Future<void> saveFrom({
    required String orgName,
    required String ownerName,
    required String email,
    required String phone,
    required String gst,
    required String address,
    required String city,
    required String stateName,
    required String pincode,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kOrgName, orgName);
    await sp.setString(_kOwnerName, ownerName);
    await sp.setString(_kEmail, email);
    await sp.setString(_kPhone, phone);
    await sp.setString(_kGst, gst);
    await sp.setString(_kAddress, address);
    await sp.setString(_kCity, city);
    await sp.setString(_kState, stateName);
    await sp.setString(_kPincode, pincode);

    // update in-memory
    this.orgName = orgName;
    this.ownerName = ownerName;
    this.email = email;
    this.phone = phone;
    this.gst = gst;
    this.address = address;
    this.city = city;
    this.stateName = stateName;
    this.pincode = pincode;

    // Auto-mark onboarded once details are complete
    if (isComplete) {
      onboarded = true;
      await sp.setBool(_kOnboarded, true);
    }
    notifyListeners();
  }

  /// Explicitly set onboarding flag (used by "Create Organization" in the first-run screen).
  Future<void> setOnboarded(bool value) async {
    final sp = await SharedPreferences.getInstance();
    onboarded = value;
    await sp.setBool(_kOnboarded, value);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kOnboarded, false);
    onboarded = false;
    notifyListeners();
  }

  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kOrgName);
    await sp.remove(_kOwnerName);
    await sp.remove(_kEmail);
    await sp.remove(_kPhone);
    await sp.remove(_kGst);
    await sp.remove(_kAddress);
    await sp.remove(_kCity);
    await sp.remove(_kState);
    await sp.remove(_kPincode);
    await sp.setBool(_kOnboarded, false);

    orgName = ownerName = email = phone = gst =
      address = city = stateName = pincode = '';
    onboarded = false;
    notifyListeners();
  }
}
