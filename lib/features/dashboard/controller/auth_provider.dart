// lib/core/auth/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const _kAuth = 'auth_ok';
  static const _kName = 'auth_name';
  static const _kEmail = 'auth_email';
  static const _kAvatar = 'auth_avatar';

  bool _loggedIn = false;
  String _name = '';
  String _email = '';
  String _avatar = '';

  bool get loggedIn => _loggedIn;
  String get name => _name;
  String get email => _email;
  String get avatar => _avatar;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _loggedIn = sp.getBool(_kAuth) ?? false;
    _name = sp.getString(_kName) ?? '';
    _email = sp.getString(_kEmail) ?? '';
    _avatar = sp.getString(_kAvatar) ?? '';
    notifyListeners();
  }

  /// Replace this with real Google / email auth later
  Future<void> signInWithGoogleStub() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAuth, true);
    await sp.setString(_kName, 'Tecnobij');
    await sp.setString(_kEmail, 'admin@tecnobij.com');
    await sp.setString(_kAvatar, '');
    _loggedIn = true;
    _name = 'Tecnobij';
    _email = 'admin@tecnobij.com';
    _avatar = '';
    notifyListeners();
  }

  Future<void> signOut() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAuth);
    await sp.remove(_kName);
    await sp.remove(_kEmail);
    await sp.remove(_kAvatar);
    _loggedIn = false;
    _name = '';
    _email = '';
    _avatar = '';
    notifyListeners();
  }
}
