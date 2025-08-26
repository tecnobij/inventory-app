import 'package:flutter/material.dart';
import 'page_spec.dart';
import '../presentation/pages/pages.dart';

class PageRegistry {
  static final List<PageSpec> all = [
    PageSpec(id:'home', label:'Home', icon:Icons.dashboard_outlined, route:'/home', builder: (_) => const HomePage()),
    PageSpec(id:'sales', label:'Sales', icon:Icons.point_of_sale_outlined, route:'/sales', builder: (_) => const ProductPage()),
    PageSpec(id:'purchase', label:'Purchase', icon:Icons.shopping_cart_outlined, route:'/purchase', builder: (_) => const PartyManagePage()),
    PageSpec(id:'products', label:'Products', icon:Icons.inventory_2_outlined, route:'/products', builder: (_) => const ProductPage()),
    PageSpec(id:'quotes', label:'Quotations', icon:Icons.request_quote_outlined, route:'/quotes', builder: (_) => const QuotationsPage()),
    PageSpec(id:'reports', label:'Reports', icon:Icons.receipt_long_outlined, route:'/reports', builder: (_) => const CreditPaymentsPage()),
    PageSpec(id:'finance', label:'Finance', icon:Icons.account_balance_wallet_outlined, route:'/finance', builder: (_) => const ReportPage()),
    PageSpec(id:'customers', label:'Customers', icon:Icons.people_outline, route:'/customers', builder: (_) => const SalesDispatchPage()),
    PageSpec(id:'vendors', label:'Vendors', icon:Icons.store_mall_directory_outlined, route:'/vendors', builder: (_) => const VendorsPage()),
    PageSpec(id:'settings', label:'Settings', icon:Icons.settings_outlined, route:'/settings', builder: (_) => const SettingPage()),
  ];

  static PageSpec byId(String id) => all.firstWhere((p) => p.id == id);
  static PageSpec byRoute(String route) => all.firstWhere((p) => p.route == route);
}
