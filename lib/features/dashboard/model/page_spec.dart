// lib/features/dashboard/model/page_spec.dart
import 'package:flutter/material.dart';

class PageSpec {
  final String id;           // stable id
  final String label;        // UI label
  final IconData icon;       // icon
  final String route;        // '/sales', '/products', ...
  final WidgetBuilder builder; // lazy page builder

  const PageSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.builder,
  });
}
