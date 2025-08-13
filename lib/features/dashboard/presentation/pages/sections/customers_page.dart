import 'package:flutter/material.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Customers', style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
