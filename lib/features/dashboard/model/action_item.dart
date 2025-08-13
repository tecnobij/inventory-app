import 'package:flutter/material.dart';

class ActionItem {
  final String id;
  final String label;
  final IconData icon;
  final Widget page;
  final Color color; // 🎨 new field for icon color

  const ActionItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.page,
    required this.color,
  });
}
