import 'package:flutter/material.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const _CenterLabel('Sales');
  }
}

class _CenterLabel extends StatelessWidget {
  final String text;
  const _CenterLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
