import 'package:flutter/material.dart';
import '../../../controller/dashboard_controller.dart';

class MorePage extends StatelessWidget {
  final DashboardController controller;
  // startFrom = first index that should go into "More" (here, 4)
  final int startFrom;

  const MorePage({super.key, required this.controller, this.startFrom = 4});

  @override
  Widget build(BuildContext context) {
    final extras = controller.items.asMap().entries
        .where((e) => e.key >= startFrom)
        .map((e) => (index: e.key, item: e.value))
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: extras.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final idx = extras[i].index;
        final nav = extras[i].item;
        return ListTile(
          leading: Icon(nav.icon),
          title: Text(nav.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => controller.setIndex(idx),
        );
      },
    );
  }
}
