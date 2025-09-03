import 'package:bhago/features/dashboard/presentation/widgets/tab_componant.dart';
import 'package:flutter/material.dart';

class PartyManagePage extends StatefulWidget {
  const PartyManagePage({super.key});

  @override
  State<PartyManagePage> createState() => _PartyManagePageState();
}

class _PartyManagePageState extends State<PartyManagePage> {
  int selectedTab = 0; // 0 = List, 1 = Create Quote

  @override
  Widget build(BuildContext context) {

 return Scaffold(

      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
              SegmentedTabs(
                
                tabs:  [
                  (Icons.dashboard_customize_rounded, 'Customers'),
                  (Icons.person, 'Suppliers'),
               
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
                            // if (row["canConvert"] == true)
                            //   OutlinedButton.icon(
                            //     onPressed: () {},
                            //     icon: const Icon(Icons.description, size: 16),
                            //     label: const Text("Convert to SO"),
                            //     style: OutlinedButton.styleFrom(
                            //       padding: const EdgeInsets.symmetric(
                            //           horizontal: 8, vertical: 4),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(8),
                            //       ),
                            //     ),
                            //   ),
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
  return LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final isCompact = w < 520;   // phones
      final isMedium  = w < 900;   // small tablets / narrow windows

      // Reusable pieces
      final searchField = TextField(
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: "Search Customer...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );

      final filterBtn = OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.filter_list),
        label: const Text("Filters"),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48), // consistent tap target
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      final addBtn = FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // ====== Phones (stacked) ======
      if (isCompact) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search full-width
              searchField,
              const SizedBox(height: 12),
              // Buttons share the row space equally
              Row(
                children: [
                  Expanded(child: filterBtn),
                  const SizedBox(width: 8),
                  Expanded(child: addBtn),
                ],
              ),
            ],
          ),
        );
      }

      // ====== Small tablets / narrow windows (single row, no spacer) ======
      if (isMedium) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              // Keep buttons inline; Flexible prevents overflow on tighter widths
              Flexible(fit: FlexFit.loose, child: filterBtn),
              const SizedBox(width: 8),
              Flexible(fit: FlexFit.loose, child: addBtn),
            ],
          ),
        );
      }

      // ====== Desktop / wide screens (search + filter on left, add on right) ======
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(flex: 2, child: searchField),
            const SizedBox(width: 12),
            filterBtn,
            const Spacer(),
            addBtn,
          ],
        ),
      );
    },
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
