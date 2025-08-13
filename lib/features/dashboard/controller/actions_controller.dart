import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/action_item.dart';
import '../presentation/pages/pages.dart';

class ActionsController extends ChangeNotifier {
  // Master list of all pages in the app
  final List<ActionItem> _all = const [
    ActionItem(id: 'home',       label: 'Home',       icon: Icons.dashboard_outlined,          page: HomePage()),
    ActionItem(id: 'sales',      label: 'Sales',      icon: Icons.point_of_sale_outlined,      page: SalesPage()),
    ActionItem(id: 'purchase',   label: 'Purchase',   icon: Icons.shopping_cart_outlined,      page: PurchasePage()),
    ActionItem(id: 'products',   label: 'Products',   icon: Icons.inventory_2_outlined,        page: ProductPage()),
    ActionItem(id: 'quotes',     label: 'Quotations', icon: Icons.request_quote_outlined,      page: QuotationsPage()),
    ActionItem(id: 'reports',    label: 'Reports',    icon: Icons.receipt_long_outlined,       page: ReportPage()),
    ActionItem(id: 'finance',    label: 'Finance',    icon: Icons.account_balance_wallet_outlined, page: FinancePage()),
    ActionItem(id: 'customers',  label: 'Customers',  icon: Icons.people_outline,              page: CustomersPage()),
    ActionItem(id: 'vendors',    label: 'Vendors',    icon: Icons.store_mall_directory_outlined, page: VendorsPage()),
    ActionItem(id: 'settings',   label: 'Settings',   icon: Icons.settings_outlined,           page: SettingPage()),
  ];

  // Favorites (ids) and selected index within favorites
  List<String> _favoriteIds = ['home', 'sales', 'purchase', 'products'];
  int _selectedIndex = 0;

  // ===== Getters expected by your UI =====
  List<ActionItem> get allActions => List.unmodifiable(_all);
  List<ActionItem> get favorites =>
      _favoriteIds.map((id) => _all.firstWhere((a) => a.id == id)).toList();
  int get selectedFavoriteIndex => _selectedIndex;
  ActionItem get selectedAction =>
      favorites[_selectedIndex.clamp(0, favorites.length - 1)];

  // ===== Persistence =====
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _favoriteIds = sp.getStringList('fav_ids') ?? _favoriteIds;
    _selectedIndex = sp.getInt('fav_sel') ?? 0;
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
}
