import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _kFollowSystemKey = 'theme_follow_system';
  static const _kThemeModeKey    = 'theme_mode'; // 'system' | 'light' | 'dark'

  bool _followSystem = true;
  ThemeMode _themeMode = ThemeMode.system;

  bool get followSystem => _followSystem;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _followSystem = sp.getBool(_kFollowSystemKey) ?? true;
    final raw = sp.getString(_kThemeModeKey) ?? 'system';
    _themeMode = _fromString(raw);
    notifyListeners();
  }

  Future<void> setFollowSystem(bool v) async {
    _followSystem = v;
    if (v) _themeMode = ThemeMode.system;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kFollowSystemKey, v);
    await sp.setString(_kThemeModeKey, _toString(_themeMode));
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _followSystem = (mode == ThemeMode.system);
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kFollowSystemKey, _followSystem);
    await sp.setString(_kThemeModeKey, _toString(mode));
    notifyListeners();
  }

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark:  return 'dark';
      case ThemeMode.system:
      default:              return 'system';
    }
  }

  ThemeMode _fromString(String v) {
    switch (v) {
      case 'light': return ThemeMode.light;
      case 'dark':  return ThemeMode.dark;
      default:      return ThemeMode.system;
    }
  }
}
