import 'package:flutter/material.dart';
import '../model/dashboard_model.dart';
import '../presentation/pages/pages.dart';

class DashboardController extends ChangeNotifier {
  int _index = 0;
  ThemeMode _themeMode = ThemeMode.system;

  int get index => _index;
  ThemeMode get themeMode => _themeMode;

  // Order matters: first 4 will show in bottom bar + a "More" tab in portrait.
  final List<NavItem> items = const [
    NavItem(label: 'Home', icon: Icons.dashboard_outlined, page: HomePage()),
    NavItem(
      label: 'Sales',
      icon: Icons.point_of_sale_outlined,
      page: ProductPage(),
    ),
    NavItem(
      label: 'Purchase',
      icon: Icons.shopping_cart_outlined,
      page: SalesDispatchPage(),
    ),
    NavItem(
      label: 'Products',
      icon: Icons.inventory_2_outlined,
      page: ProductPage(),
    ),
    // Everything beyond index 3 appears inside "More" on portrait
    NavItem(
      label: 'Quotations',
      icon: Icons.request_quote_outlined,
      page: QuotationsPage(),
    ),
    NavItem(
      label: 'Reports',
      icon: Icons.receipt_long_outlined,
      page: CreditPaymentsPage(),
    ),
    NavItem(
      label: 'Finance',
      icon: Icons.account_balance_wallet_outlined,
      page: ReportPage(),
    ),
    NavItem(
      label: 'Customers',
      icon: Icons.people_outline,
      page: SalesDispatchPage(),
    ),
    NavItem(
      label: 'Vendors',
      icon: Icons.store_mall_directory_outlined,
      page: VendorsPage(),
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      page: SettingPage(),
    ),
  ];

  void setIndex(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }

  void toggleThemeMode() {
    _themeMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
  }
}
