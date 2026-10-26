import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stock entry.dart';

class StockStatusPage extends StatefulWidget {
  const StockStatusPage({super.key});

  @override
  State<StockStatusPage> createState() => _StockStatusPageState();
}

class _StockStatusPageState extends State<StockStatusPage> {
  // Stat counts matching Photo 1
  int totalItems = 574;
  int totalQty = 13860;
  int lowStockCount = 243;
  int outOfStockCount = 12;

  // Filter State
  String searchQuery = "";
  String? selectedSupplier;
  String selectedStatusFilter = "All Status";
  int currentLimit = 10;
  final List<int> limitOptions = [10, 25, 50, 100, 250, 500, 1000];

  // Stock Items matching Photo 1
  List<Map<String, dynamic>> stockItems = [
    {
      "id": 1,
      "s_no": 1,
      "product": "3.7V 600mAh Li-ion Rechargeable Battery",
      "variant": "Imported",
      "supplier": "Saravana Electronics",
      "qty": 83,
      "is_low": false,
      "is_out": false,
    },
    {
      "id": 2,
      "s_no": 2,
      "product": "3.7V 6000mAh Li-ion Battery",
      "variant": "Imported",
      "supplier": "Saravana Electronics",
      "qty": 5,
      "is_low": true,
      "is_out": false,
    },
    {
      "id": 3,
      "s_no": 3,
      "product": "3.7V 1200mAh Li-ion Battery",
      "variant": "Imported",
      "supplier": "Saravana Electronics",
      "qty": 10,
      "is_low": false,
      "is_out": false,
    },
    {
      "id": 4,
      "s_no": 4,
      "product": "3.6V 2000 mAh battery",
      "variant": "Imported",
      "supplier": "Saravana Electronics",
      "qty": 5,
      "is_low": true,
      "is_out": false,
    },
    {
      "id": 5,
      "s_no": 5,
      "product": "3000mAh battery",
      "variant": "Imported",
      "supplier": "Saravana Electronics",
      "qty": 59,
      "is_low": false,
      "is_out": false,
    },
    {
      "id": 6,
      "s_no": 6,
      "product": "BNC Female to Female Connector Pin",
      "variant": "Imported",
      "supplier": "Saravana Electronics",
      "qty": 3,
      "is_low": true,
      "is_out": false,
    },
    {
      "id": 7,
      "s_no": 7,
      "product": "Mq-2 Gas Sensor Module",
      "variant": "Original",
      "supplier": "Circuitpointcare",
      "qty": 0,
      "is_low": false,
      "is_out": true,
    },
  ];

  final List<String> suppliersList = [
    "All Suppliers",
    "Saravana Electronics",
    "Circuitpointcare",
    "Sai TV Smart LED Pvt.Ltd",
    "Supplier #73",
  ];

  final List<String> statusFilterOptions = [
    "All Status",
    "In Stock",
    "Low Stock",
    "Out of Stock",
  ];

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          "billing.srivagroups.in says",
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
        ),
        content: Text(
          "Are you sure you want to delete ${item['product']}?",
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                stockItems.removeWhere((e) => e['id'] == item['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Stock item removed successfully"), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5E3A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            child: const Text("OK"),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E5E3A),
              side: const BorderSide(color: Color(0xFFA7F3D0)),
              backgroundColor: const Color(0xFFDCFCE7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter items
    final filtered = stockItems.where((item) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final p = item['product'].toString().toLowerCase();
        final s = item['supplier'].toString().toLowerCase();
        if (!p.contains(q) && !s.contains(q)) return false;
      }
      if (selectedSupplier != null && selectedSupplier != "All Suppliers") {
        if (item['supplier'] != selectedSupplier) return false;
      }
      if (selectedStatusFilter == "In Stock" && (item['is_low'] == true || item['is_out'] == true)) {
        return false;
      }
      if (selectedStatusFilter == "Low Stock" && item['is_low'] != true) {
        return false;
      }
      if (selectedStatusFilter == "Out of Stock" && item['is_out'] != true) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Stock Status",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Icon, Title & 4 Stat Badges (Photo 1)
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Title Block
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Icon(Icons.inventory_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Stock Status",
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              "Real-time inventory stock levels & supplier breakdown",
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 4 Stat Cards Row/Wrap (Photo 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatCard("TOTAL ITEMS", "$totalItems", const Color(0xFFF1F5F9), const Color(0xFF0F172A), const Color(0xFFCBD5E1)),
                        _buildStatCard("TOTAL QTY", "$totalQty", const Color(0xFFDCFCE7), const Color(0xFF16A34A), const Color(0xFF86EFAC)),
                        _buildStatCard("LOW STOCK", "$lowStockCount", const Color(0xFFFEF3C7), const Color(0xFFD97706), const Color(0xFFFDE68A)),
                        _buildStatCard("OUT OF STOCK", "$outOfStockCount", const Color(0xFFFEE2E2), const Color(0xFFDC2626), const Color(0xFFFECACA)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Filter Bar (Photo 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;

                  final searchField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PRODUCT SEARCH", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: TextField(
                          onChanged: (val) => setState(() => searchQuery = val),
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Search by product name or model...",
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                          ),
                        ),
                      ),
                    ],
                  );

                  final supplierField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SUPPLIER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          value: selectedSupplier ?? "All Suppliers",
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          items: suppliersList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                          onChanged: (val) => setState(() => selectedSupplier = val),
                        ),
                      ),
                    ],
                  );

                  final statusField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("STOCK STATUS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          value: selectedStatusFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          items: statusFilterOptions.map((st) => DropdownMenuItem(value: st, child: Text(st, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                          onChanged: (val) => setState(() => selectedStatusFilter = val ?? "All Status"),
                        ),
                      ),
                    ],
                  );

                  final showField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SHOW", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<int>(
                          value: currentLimit,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          items: limitOptions.map((l) => DropdownMenuItem(value: l, child: Text("$l", style: GoogleFonts.inter(fontSize: 12)))).toList(),
                          onChanged: (val) => setState(() => currentLimit = val ?? 10),
                        ),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        searchField,
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: supplierField),
                            const SizedBox(width: 8),
                            Expanded(child: statusField),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(width: 100, child: showField),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 4, child: searchField),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: supplierField),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: statusField),
                      const SizedBox(width: 12),
                      SizedBox(width: 85, child: showField),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Table View (Photo 1)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Text("No stock status records match your filter", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 68,
                        columnSpacing: 24,
                        horizontalMargin: 20,
                        columns: [
                          DataColumn(label: Text("S.NO", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                          DataColumn(label: Text("PRODUCT NAME", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                          DataColumn(label: Text("SUPPLIER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                          DataColumn(label: Text("QTY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                          DataColumn(label: Text("ACTION", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                        ],
                        rows: filtered.map((item) {
                          final isOut = item['is_out'] == true;
                          final isLow = item['is_low'] == true;

                          Color qtyBg = const Color(0xFFECFDF5);
                          Color qtyText = const Color(0xFF059669);
                          IconData qtyIcon = Icons.check_circle_outline_rounded;

                          if (isOut) {
                            qtyBg = const Color(0xFFFEF2F2);
                            qtyText = const Color(0xFFDC2626);
                            qtyIcon = Icons.cancel_outlined;
                          } else if (isLow) {
                            qtyBg = const Color(0xFFFFFBEB);
                            qtyText = const Color(0xFFD97706);
                            qtyIcon = Icons.warning_amber_rounded;
                          }

                          return DataRow(
                            cells: [
                              DataCell(Text(item['s_no'].toString(), style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)))),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 240),
                                      child: Text(
                                        item['product'].toString(),
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text(
                                        item['variant'].toString(),
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(item['supplier'].toString(), style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: qtyBg,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(qtyIcon, size: 14, color: qtyText),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['qty'].toString(),
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: qtyText),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Storage icon
                                    IconButton(
                                      icon: const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF2563EB)),
                                      onPressed: () {},
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                    // Edit icon -> Navigates to StockEntryPage
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFF59E0B)),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const StockEntryPage()),
                                        );
                                      },
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                    // Delete icon -> Confirms and deletes
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                      onPressed: () => _confirmDelete(item),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bg, Color textColor, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }
}
