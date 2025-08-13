import 'package:flutter/material.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Finance', style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
