import 'package:flutter/material.dart';

class VendorsPage extends StatelessWidget {
  const VendorsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Vendors', style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
