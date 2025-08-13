import 'package:flutter/material.dart';

class QuotationsPage extends StatelessWidget {
  const QuotationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Quotations', style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
