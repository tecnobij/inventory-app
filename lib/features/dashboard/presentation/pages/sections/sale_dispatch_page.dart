import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart';
import 'package:flutter/material.dart';

class SalesDispatchPage extends StatefulWidget {
  const SalesDispatchPage({super.key});

  @override
  State<SalesDispatchPage> createState() => _SalesDispatchPageState();
}

class _SalesDispatchPageState extends State<SalesDispatchPage> {
@override
Widget build(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 768;

  return Scaffold(

    body: SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SegmentedTabs(
              tabs: [
                (Icons.receipt_long, 'Sales Orders'),
                (Icons.description, 'Invoices'),
                (Icons.add, 'Create SO'),
              ],
             
            ),
            const SizedBox(height: 16),
      
            // Main content area with fixed height and scrollable children
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildConstrainedScrollableContent((_) => _buildSalesOrdersTab(isMobile)),
                  _buildConstrainedScrollableContent((_) => _buildInvoicesTab(isMobile)),
                  _buildConstrainedScrollableContent((_) => _buildCreateSOTab(isMobile)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Wraps content to provide max height and scrolling
Widget _buildConstrainedScrollableContent(WidgetBuilder builder) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: builder(context),
      );
    },
  );
}


// Wraps tab content with scrolling and proper constraints to prevent overflow



  Widget _buildSalesOrdersTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchField('Search SO Number...'),
                    const SizedBox(height: 12),
                    _buildFilterButton(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSearchField('Search SO Number...')),
                    const SizedBox(width: 16),
                    _buildFilterButton(),
                  ],
                ),
          const SizedBox(height: 20),
          isMobile ? _buildSalesOrderCards() : _buildSalesOrdersTable(),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchField('Search Invoice...'),
                    const SizedBox(height: 12),
                    _buildEInvoiceButton(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSearchField('Search Invoice...')),
                    const SizedBox(width: 16),
                    _buildEInvoiceButton(),
                  ],
                ),
          const SizedBox(height: 20),
          isMobile ? _buildInvoiceCards() : _buildInvoicesTable(),
        ],
      ),
    );
  }

  Widget _buildCreateSOTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Sales Order',
            style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          isMobile ? _buildCreateSOFormMobile() : _buildCreateSOFormDesktop(),
          SizedBox(height: isMobile ? 24 : 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Line Items', style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Item'),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isMobile ? _buildLineItemsListMobile() : _buildLineItemsTableDesktop(),
          SizedBox(height: isMobile ? 24 : 32),
          _buildTotalsSection(),
          SizedBox(height: isMobile ? 24 : 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm Sales Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
        ],
      ),
    );
  }

  // Reusable UI components:

  Widget _buildSearchField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.search, color: Colors.grey),
        const SizedBox(width: 8),
        Text(hint, style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list, size: 20),
          SizedBox(width: 8),
          Text('Filters'),
        ],
      ),
    );
  }

  Widget _buildEInvoiceButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description, size: 20),
          SizedBox(width: 8),
          Text('e-invoice (future)'),
        ],
      ),
    );
  }

  Widget _buildSalesOrdersTable() {
    return Container(
      constraints: const BoxConstraints(minWidth: 1000),
      decoration: BoxDecoration(
       // color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
             // color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('SO No', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Items', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          _buildSalesOrderRow('FY24-25/SO/000089', 'ABC Technologies', '2024-12-18', 'Confirmed', '3 items', '₹28,500'),
          _buildSalesOrderRow('FY24-25/SO/000090', 'XYZ Solutions', '2024-12-19', 'Dispatched', '5 items', '₹45,750'),
        ],
      ),
    );
  }

  Widget _buildSalesOrderRow(String soNo, String customer, String date, String status, String items, String amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(soNo, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(customer)),
          Expanded(flex: 1, child: Text(date)),
          SizedBox(width: 90, child: Padding(padding: const EdgeInsets.only(right: 25), child: _buildStatusChip(status))),
          Expanded(flex: 1, child: Text(items)),
          Expanded(flex: 1, child: Text(amount, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesOrderCards() {
    final orders = [
      {'soNo': 'FY24-25/SO/000089', 'customer': 'ABC Technologies', 'date': '2024-12-18', 'status': 'Confirmed', 'items': '3 items', 'amount': '₹28,500'},
      {'soNo': 'FY24-25/SO/000090', 'customer': 'XYZ Solutions', 'date': '2024-12-19', 'status': 'Dispatched', 'items': '5 items', 'amount': '₹45,750'},
    ];

    return Column(
      children: orders
          .map(
            (order) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(order['soNo']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    _buildStatusChip(order['status']!),
                  ]),
                  const SizedBox(height: 8),
                  Text('Customer: ${order['customer']}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: Text('Date: ${order['date']}', style: const TextStyle(fontSize: 14, color: Colors.grey))),
                    Text('Items: ${order['items']}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(order['amount']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.visibility_outlined, size: 20)),
                  ])
                ]),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Confirmed':
        bgColor = Colors.black;
        textColor = Colors.white;
        break;
      case 'Dispatched':
        bgColor = Colors.grey.shade200;
        textColor = Colors.black;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInvoicesTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        constraints: const BoxConstraints(minWidth: 1200),
        decoration: BoxDecoration(
        //  color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
             //   color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 1, child: Text('Invoice No', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('SO No', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            _buildInvoiceRow('INV-001', 'FY24-25/SO/000089', 'ABC Technologies', '2024-12-18', '₹28,500', 'Unpaid'),
            _buildInvoiceRow('INV-002', 'FY24-25/SO/000090', 'XYZ Solutions', '2024-12-19', '₹45,750', 'Paid'),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String invoiceNo, String soNo, String customer, String date, String amount, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(invoiceNo, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(soNo)),
          Expanded(flex: 2, child: Text(customer)),
          Expanded(flex: 1, child: Text(date)),
          Expanded(flex: 1, child: Text(amount, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(flex: 1, child: _buildInvoiceStatusChip(status)),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                if (status == 'Unpaid') ...[
                  
                  const SizedBox(width: 8),
                ],
                IconButton(onPressed: () {}, icon: const Icon(Icons.download_outlined, size: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCards() {
    final invoices = [
      {'invoiceNo': 'INV-001', 'soNo': 'FY24-25/SO/000089', 'customer': 'ABC Technologies', 'date': '2024-12-18', 'amount': '₹28,500', 'status': 'Unpaid'},
      {'invoiceNo': 'INV-002', 'soNo': 'FY24-25/SO/000090', 'customer': 'XYZ Solutions', 'date': '2024-12-19', 'amount': '₹45,750', 'status': 'Paid'},
    ];

    return Column(
      children: invoices
          .map(
            (invoice) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(invoice['invoiceNo']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    _buildInvoiceStatusChip(invoice['status']!),
                  ]),
                  const SizedBox(height: 8),
                  Text('SO: ${invoice['soNo']}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('Customer: ${invoice['customer']}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Date: ${invoice['date']}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(invoice['amount']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(children: [
                      if (invoice['status'] == 'Unpaid') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.credit_card, size: 14),
                            SizedBox(width: 4),
                            Text('Payment', style: TextStyle(fontSize: 12)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(onPressed: () {}, icon: const Icon(Icons.download_outlined, size: 20)),
                    ]),
                  ])
                ]),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInvoiceStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Unpaid':
        bgColor = Colors.red;
        textColor = Colors.white;
        break;
      case 'Paid':
        bgColor = Colors.black;
        textColor = Colors.white;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Text(status, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCreateSOFormMobile() {
    return Column(
      children: [
        _buildFormField('Customer *', 'Select customer'),
        const SizedBox(height: 16),
        _buildFormField('SO Date *', 'dd/mm/yyyy'),
        const SizedBox(height: 16),
        _buildFormField('Warehouse *', 'Select warehouse'),
        const SizedBox(height: 16),
        _buildFormField('Payment Terms', 'Select terms'),
      ],
    );
  }

  Widget _buildCreateSOFormDesktop() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFormField('Customer *', 'Select customer')),
            const SizedBox(width: 24),
            Expanded(child: _buildFormField('SO Date *', 'dd/mm/yyyy')),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildFormField('Warehouse *', 'Select warehouse')),
            const SizedBox(width: 24),
            Expanded(child: _buildFormField('Payment Terms', 'Select terms')),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField(String label, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(child: Text(placeholder, style: const TextStyle(color: Colors.grey))),
              if (placeholder.contains('Select')) const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineItemsTableDesktop() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                child: const Row(
                  children: [
                    SizedBox(width: 240, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 100, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 140, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 100, child: Text('Tax', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 120, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: const Row(
                          children: [
                            Expanded(child: Text('Select product', style: TextStyle(color: Colors.grey))),
                            Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Quantity', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 132,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Unit Price', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: const Row(
                          children: [
                            Expanded(child: Text('18%', style: TextStyle(color: Colors.grey))),
                            Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SizedBox(width: 120, child: Text('₹0.00', style: TextStyle(fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineItemsListMobile() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
            child: const Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMobileFormField('Product', 'Select product'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMobileFormField('Quantity', 'Quantity')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMobileFormField('Unit Price', 'Unit Price')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMobileFormField('Tax', '18%')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 8),
                          Text('₹0.00', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFormField(String label, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
          child: Row(
            children: [
              Expanded(child: Text(placeholder, style: const TextStyle(color: Colors.grey))),
              if (placeholder.contains('Select') || placeholder.contains('%'))
                const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: const Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Subtotal:', style: TextStyle(fontSize: 16)),
            Text('₹0.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ]),
          SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('GST:', style: TextStyle(fontSize: 16)),
            Text('₹0.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ]),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('₹0.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }
}

