import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
  
      body: DefaultTabController(
        length: 4,
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
            SegmentedTabs(
              tabs: [
                (Icons.shopping_cart_outlined, 'Purchase Report'),
                (Icons.sell_outlined, 'Sales Report'),
                (Icons.trending_up, 'P&L'),
                (Icons.receipt_long, 'GST Summary'),
              ],
            
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPurchaseReport(isMobile),
                  _buildSalesReport(isMobile),
                  _buildPLReport(isMobile),
                  _buildGSTSummary(isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseReport(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters and export buttons - Responsive
          _buildResponsiveHeader(isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          
          // Summary cards - Responsive
          _buildResponsiveSummaryCards(isMobile, [
            ('Total Orders', '15', Icons.inventory_2_outlined),
            ('Total Amount', '₹3,70,000', Icons.currency_rupee),
            ('Suppliers', '3', Icons.people_outline),
          ]),
          SizedBox(height: isMobile ? 24 : 32),
          
          // Purchase by Supplier section
          Text(
            'Purchase by Supplier',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18, 
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          
          // Responsive Table
          _buildResponsiveTable(
            isMobile,
            headers: ['Supplier', 'Orders', 'Amount', '% of Total'],
            rows: [
              ['Tech Supplies Ltd', '5', '₹125,000', '33.8%'],
              ['Electronics Hub', '3', '₹89,000', '24.1%'],
              ['Office Mart', '7', '₹156,000', '42.2%'],
            ],
            flexValues: [3, 2, 2, 2],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          
          // Purchase Trend Chart placeholder
          Container(
            height: isMobile ? 150 : 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: isMobile ? 32 : 40, color: Colors.grey),
                  SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    'Purchase Trend Chart', 
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
        ],
      ),
    );
  }

  Widget _buildSalesReport(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters and export buttons - Responsive
          _buildResponsiveHeader(isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          
          Text(
            'Sales by Customer',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18, 
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          
          // Responsive Table
          _buildResponsiveTable(
            isMobile,
            headers: ['Customer', 'Orders', 'Amount', '% of Total'],
            rows: [
              ['ABC Technologies', '4', '₹95,000', '32.1%'],
              ['XYZ Solutions', '2', '₹67,000', '22.6%'],
              ['PQR Industries', '6', '₹134,000', '45.3%'],
            ],
            flexValues: [3, 2, 2, 2],
          ),
        ],
      ),
    );
  }

  Widget _buildPLReport(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // P&L Summary cards - Responsive
          _buildResponsivePLCards(isMobile),
          SizedBox(height: isMobile ? 24 : 32),
          
          // P&L Summary by Period
          Text(
            'P&L Summary by Period',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18, 
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          
          // Responsive Table
          _buildResponsiveTable(
            isMobile,
            headers: ['Period', 'Revenue', 'COGS', 'Gross Profit', 'Margin %'],
            rows: [
              ['Q4 2024', '₹296,000', '₹210,000', '₹86,000', '29.1%'],
              ['Q3 2024', '₹245,000', '₹175,000', '₹70,000', '28.6%'],
              ['Q2 2024', '₹198,000', '₹142,000', '₹56,000', '28.3%'],
            ],
            flexValues: [1, 1, 1, 1, 1],
          ),
        ],
      ),
    );
  }

  Widget _buildGSTSummary(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: isMobile 
        ? Column(
            children: [
              _buildGSTCard(
                'Outward Supply (Sales)',
                [
                  ('Taxable Value:', '₹250,000'),
                  ('CGST:', '₹22,500'),
                  ('SGST:', '₹22,500'),
                  ('Total Tax:', '₹45,000'),
                ],
                isMobile,
              ),
              const SizedBox(height: 16),
              _buildGSTCard(
                'Inward Supply (Purchases)',
                [
                  ('Taxable Value:', '₹180,000'),
                  ('CGST:', '₹16,200'),
                  ('SGST:', '₹16,200'),
                  ('Total Tax:', '₹32,400'),
                ],
                isMobile,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildGSTCard(
                  'Outward Supply (Sales)',
                  [
                    ('Taxable Value:', '₹250,000'),
                    ('CGST:', '₹22,500'),
                    ('SGST:', '₹22,500'),
                    ('Total Tax:', '₹45,000'),
                  ],
                  isMobile,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGSTCard(
                  'Inward Supply (Purchases)',
                  [
                    ('Taxable Value:', '₹180,000'),
                    ('CGST:', '₹16,200'),
                    ('SGST:', '₹16,200'),
                    ('Total Tax:', '₹32,400'),
                  ],
                  isMobile,
                ),
              ),
            ],
          ),
    );
  }

  // Responsive Helper Widgets

  Widget _buildResponsiveHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters row
          Row(
            children: [
              Expanded(child: _buildFilterChip('This Month', Icons.calendar_today)),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterChip('Main Warehouse', null)),
            ],
          ),
          const SizedBox(height: 12),
          // Export buttons row
          Row(
            children: [
              Expanded(
                child: _buildExportButton('Export CSV', Icons.download, isMobile),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildExportButton('Export PDF', Icons.picture_as_pdf, isMobile),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildFilterChip('This Month', Icons.calendar_today),
        const SizedBox(width: 16),
        _buildFilterChip('Main Warehouse', null),
        const Spacer(),
        _buildExportButton('Export CSV', Icons.download, isMobile),
        const SizedBox(width: 8),
        _buildExportButton('Export PDF', Icons.picture_as_pdf, isMobile),
      ],
    );
  }

  Widget _buildFilterChip(String text, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildExportButton(String text, IconData icon, bool isMobile) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(
        text, 
        style: TextStyle(fontSize: isMobile ? 12 : 14),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildResponsiveSummaryCards(bool isMobile, List<(String, String, IconData)> cardData) {
    if (isMobile) {
      return Column(
        children: cardData.map((data) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSummaryCard(data.$1, data.$2, data.$3, isMobile),
          )
        ).toList(),
      );
    }

    return Row(
      children: cardData.map((data) => 
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: cardData.indexOf(data) < cardData.length - 1 ? 16 : 0
            ),
            child: _buildSummaryCard(data.$1, data.$2, data.$3, isMobile),
          ),
        )
      ).toList(),
    );
  }

  Widget _buildResponsivePLCards(bool isMobile) {
    final cardData = [
      ('Revenue', '₹2,96,000', Colors.green),
      ('COGS', '₹2,10,000', Colors.red),
      ('Gross Profit', '₹86,000', Colors.blue),
    ];

    if (isMobile) {
      return Column(
        children: cardData.map((data) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPLCard(data.$1, data.$2, data.$3, isMobile),
          )
        ).toList(),
      );
    }

    return Row(
      children: cardData.map((data) => 
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: cardData.indexOf(data) < cardData.length - 1 ? 16 : 0
            ),
            child: _buildPLCard(data.$1, data.$2, data.$3, isMobile),
          ),
        )
      ).toList(),
    );
  }

  Widget _buildResponsiveTable(
    bool isMobile, {
    required List<String> headers,
    required List<List<String>> rows,
    required List<int> flexValues,
  }) {
    if (isMobile) {
      return Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 24,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTableHeader(headers, flexValues, isMobile),
            ...rows.map((row) => _buildTableRow(row, flexValues, isMobile)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTableHeader(headers, flexValues, isMobile),
          ...rows.map((row) => _buildTableRow(row, flexValues, isMobile)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<String> headers, List<int> flexValues, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: headers.asMap().entries.map((entry) {
          int index = entry.key;
          String header = entry.value;
          return Expanded(
            flex: flexValues[index],
            child: Text(
              header,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableRow(List<String> rowData, List<int> flexValues, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: rowData.asMap().entries.map((entry) {
          int index = entry.key;
          String data = entry.value;
          return Expanded(
            flex: flexValues[index],
            child: Text(
              data,
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGSTCard(
    String title, 
    List<(String, String)> items, 
    bool isMobile
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18, 
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          
          // Regular items
          ...items.take(items.length - 1).map((item) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGSTRow(item.$1, item.$2, false, isMobile),
            ),
          ),
          
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          
          // Total item
          _buildGSTRow(items.last.$1, items.last.$2, true, isMobile),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title, 
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isMobile ? 12 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: Colors.grey.shade400, size: isMobile ? 20 : 24),
            ],
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPLCard(String title, String value, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title, 
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24, 
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGSTRow(String label, String value, bool isTotal, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? (isMobile ? 14 : 16) : (isMobile ? 12 : 14),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? (isMobile ? 14 : 16) : (isMobile ? 12 : 14),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.tabs, required this.isMobile});
  final List<(IconData, String)> tabs;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18),
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurface,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: [
            for (final t in tabs)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10),
                child: Tab(
                  height: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$1, size: isMobile ? 16 : 18),
                      SizedBox(width: isMobile ? 6 : 10),
                      Text(
                        t.$2, 
                        style: TextStyle(
                          fontWeight: FontWeight.w700, 
                          fontSize: isMobile ? 12 : 16
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}