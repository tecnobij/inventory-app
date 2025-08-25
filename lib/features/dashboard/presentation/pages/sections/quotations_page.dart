import 'package:flutter/material.dart';

class QuotationsPage extends StatefulWidget {
  const QuotationsPage({super.key});

  @override
  State<QuotationsPage> createState() => _QuotationsPageState();
}

class _QuotationsPageState extends State<QuotationsPage> {
  int selectedTab = 0; // 0 = List, 1 = Create Quote

  @override
  Widget build(BuildContext context) {

 return Scaffold(
  
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Header row with "Settings" and a session-only Skip (won’t show normally)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Quotations',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  // (optional) quick exit if you ever reuse this screen as start
                
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SegmentedTabs(
              
              tabs:  [
                (Icons.apartment_outlined, 'List'),
                (Icons.tag_outlined, 'Create Quote'),
             
              ],
            ),

            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(

                physics: const NeverScrollableScrollPhysics(),
                children: [
                _buildQuotationList(context)  ,   // Organization tab (your existing form)
               _buildEmptyState()
                
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  /// ---------------- Quotation List ----------------
  Widget _buildQuotationList(BuildContext context) {
    final rows = [
      {
        "quoteNo": "QU0-001",
        "customer": "ABC Technologies",
        "date": "2024-12-18",
        "validTill": "2025-01-18",
        "status": "Open",
        "amount": "₹28,500",
        "canConvert": false,
      },
      {
        "quoteNo": "QU0-002",
        "customer": "XYZ Solutions",
        "date": "2024-12-15",
        "validTill": "2025-01-15",
        "status": "Accepted",
        "amount": "₹45,750",
        "canConvert": true,
      }
    ];

    return Column(
      children: [
        _buildSearchFilter(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 750) {
                // ---------- Desktop / Web ----------
                return SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.white),
                    dividerThickness: 0.5,
                    columns: const [
                      DataColumn(
                          label: Text("Quote No",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Customer",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Date",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Valid Till",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Status",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Amount",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Actions",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: rows.map((row) {
                      return DataRow(cells: [
                        DataCell(Text(row["quoteNo"].toString())),
                        DataCell(Text(row["customer"].toString())),
                        DataCell(Text(row["date"].toString())),
                        DataCell(Text(row["validTill"].toString())),
                        DataCell(_buildStatus(row["status"].toString())),
                        DataCell(Text(row["amount"].toString())),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, size: 20),
                              onPressed: () {},
                            ),
                            if (row["canConvert"] == true)
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.description, size: 16),
                                label: const Text("Convert to SO"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              } else {
                // ---------- Mobile ----------
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row["quoteNo"].toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 6),
                            Text("Customer: ${row["customer"]}"),
                            Text("Date: ${row["date"]}"),
                            Text("Valid Till: ${row["validTill"]}"),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatus(row["status"].toString()),
                                Text(row["amount"].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye,
                                      size: 20),
                                  onPressed: () {},
                                ),
                                if (row["canConvert"] == true)
                                  OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.description,
                                        size: 16),
                                    label: const Text("Convert"),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFilter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Quote Number...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
            label: const Text("Filters"),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(String status) {
    if (status == "Open") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("Open",
            style: TextStyle(color: Colors.white, fontSize: 12)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("Accepted",
            style: TextStyle(color: Colors.black, fontSize: 12)),
      );
    }
  }

  /// ---------------- Empty State ----------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            "Create New Quotation",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Similar to Create SO form with Quote-specific fields",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Start Creating Quote"),
          ),
        ],
      ),
    );
  }
}
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.tabs});
  final List<(IconData, String)> tabs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start, // ← LEFT ALIGN TABS
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
          labelPadding: const EdgeInsets.symmetric(horizontal: 18),
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurface,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          tabs: [
            for (final t in tabs)
              Padding(
                padding:  EdgeInsets.symmetric(horizontal:10),
                child: Tab(
                  height: 40,
                  
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$1, size: 18),
                      const SizedBox(width: 10),
                      Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
