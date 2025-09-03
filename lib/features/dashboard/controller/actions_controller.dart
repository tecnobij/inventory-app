// actions_controller.dart
import 'package:bhago/features/dashboard/presentation/pages/manage_actions_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/action_item.dart';
import '../presentation/pages/pages.dart';

class ActionsController extends ChangeNotifier {
  // 🔒 Pinned (non-removable) favorites
  static const Set<String> _pinnedFavIds = {'home', 'actions'};

  // Master list of all pages
  final List<ActionItem> all = const [
    ActionItem(id: 'home',     label: 'Home',              icon: Icons.dashboard_outlined, page: HomePage()),
    ActionItem(id: 'products', label: 'Products & Stocks', icon: Icons.inventory_2_outlined, page: ProductPage()),
    ActionItem(id: 'sales',    label: 'Sales/Dispatch',    icon: Icons.local_shipping_outlined, page: SalesDispatchPage()),
    ActionItem(id: 'quotations', label: 'Quotations',      icon: Icons.description_outlined, page: QuotationsPage()),
    ActionItem(id: 'party',    label: 'Party Management',  icon: Icons.groups_2_outlined, page: PartyManagePage()),
    ActionItem(id: 'payments', label: 'Credit/Payments',   icon: Icons.credit_card, page: CreditPaymentsPage()),
    ActionItem(id: 'reports',  label: 'Reports',           icon: Icons.bar_chart_outlined, page: ReportPage()),
    ActionItem(id: 'settings', label: 'Settings',          icon: Icons.settings_outlined, page: SettingPage()),
    ActionItem(id: 'actions',  label: 'Actions',           icon: Icons.favorite, page: ManageActionsPage()),
  ];

  // Favorites and selection
  List<String> _favoriteIds = ['home', 'products', 'sales', 'actions'];
  int _selectedIndex = 0;

  // Getters
  List<ActionItem> get allActions => List.unmodifiable(all);
  List<ActionItem> get favorites =>
      _favoriteIds.map((id) => all.firstWhere((a) => a.id == id)).toList();
  int get selectedFavoriteIndex => _selectedIndex;

  ActionItem get selectedAction {
    if (favorites.isEmpty) return all.first;
    return favorites[_selectedIndex.clamp(0, favorites.length - 1)];
  }

  // ===== Persistence =====
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _favoriteIds = sp.getStringList('fav_ids') ?? _favoriteIds;
    _selectedIndex = sp.getInt('fav_sel') ?? 0;

    // ✅ Ensure pinned favorites are always present
    for (final id in _pinnedFavIds) {
      if (!_favoriteIds.contains(id)) {
        _favoriteIds.insert(0, id); // keep pinned near the front
      }
    }

    if (_favoriteIds.isEmpty) {
      _favoriteIds = ['home', 'sales'];
      _selectedIndex = 0;
    }
    if (_selectedIndex >= _favoriteIds.length) {
      _selectedIndex = 0;
    }

    notifyListeners();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList('fav_ids', _favoriteIds);
    await sp.setInt('fav_sel', _selectedIndex);
  }

  // ===== Mutations =====
  void setSelectedFavorite(int index) {
    if (index < 0 || index >= favorites.length) return;
    _selectedIndex = index;
    _persist();
    notifyListeners();
  }

  void reorderFavorites(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = _favoriteIds.removeAt(oldIndex);
    _favoriteIds.insert(newIndex, moved);

    if (_selectedIndex == oldIndex) {
      _selectedIndex = newIndex;
    } else if (oldIndex < _selectedIndex && newIndex >= _selectedIndex) {
      _selectedIndex -= 1;
    } else if (oldIndex > _selectedIndex && newIndex <= _selectedIndex) {
      _selectedIndex += 1;
    }
    _persist();
    notifyListeners();
  }

  void addFavorite(String id) {
    if (!_favoriteIds.contains(id)) {
      _favoriteIds.add(id);
      _persist();
      notifyListeners();
    }
  }

  void removeFavorite(String id) {
    // 🔒 Block removal of pinned favorites
    if (_pinnedFavIds.contains(id)) return;

    final idx = _favoriteIds.indexOf(id);
    if (idx != -1) {
      _favoriteIds.removeAt(idx);
      if (_selectedIndex >= _favoriteIds.length) {
        _selectedIndex = (_favoriteIds.isEmpty) ? 0 : _favoriteIds.length - 1;
      }
      _persist();
      notifyListeners();
    }
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);
  bool isPinned(String id) => _pinnedFavIds.contains(id);
}
