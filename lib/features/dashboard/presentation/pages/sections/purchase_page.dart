import 'package:flutter/material.dart';

class PurchasePage extends StatelessWidget {
  const PurchasePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Purchase', style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
