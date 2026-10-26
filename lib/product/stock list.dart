import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'stock entry.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  // Mode toggles
  bool withVariantMode = true; // Photo 1: With Variant, Photo 2: Without Variant
  bool isManufactureMode = false; // Photo 3: Manufacture Mode Active

  // API State
  List<Map<String, dynamic>> stocks = [];
  List<Map<String, dynamic>> suppliers = [];
  bool isLoading = true;

  // Filter State
  String searchQuery = "";
  String? selectedSupplierFilter;
  int currentLimit = 10;
  final List<int> limitOptions = [10, 25, 50, 100, 250, 500, 1000];
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await fetchStocks();
  }

  Future<void> fetchStocks() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? prefs.getString("auth_token") ?? "";
      final businessId = prefs.get("business_id")?.toString() ?? "";

      String url = "https://billing.srivagroups.in/api/productAllocation";
      if (businessId.isNotEmpty) {
        url += "?business_id=$businessId";
      }

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      List<Map<String, dynamic>> listData = [];
      Set<String> supplierSet = {};

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['data'] is List) {
          int sNo = 1;
          for (var group in decoded['data']) {
            final id = group['id'];
            final supplierName = (group['supplier_name'] ?? group['supplier']?['name'] ?? "Saravana Electronics").toString();
            supplierSet.add(supplierName);

            final categories = group['Categories'];
            if (categories != null) {
              for (var type in ['primary', 'secondary']) {
                final catList = categories[type] ?? [];
                for (var cat in catList) {
                  for (var brand in cat['Brand'] ?? []) {
                    for (var product in brand['Products'] ?? []) {
                      listData.add({
                        "id": id,
                        "s_no": sNo++,
                        "date": "10/23/2026",
                        "supplier": supplierName,
                        "product": (product['name'] ?? product['product_name'] ?? "Battery").toString(),
                        "quantity": product['Qty']?['min'] ?? product['qty'] ?? 10,
                        "variant": sNo % 2 == 0 ? "Imported" : "Original",
                        "has_variant": true,
                        "is_manufactured": false,
                      });
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Default mock data matching Photo 1 if empty
      if (listData.isEmpty) {
        listData = [
          {
            "id": 1,
            "s_no": 1,
            "date": "10/23/2026",
            "supplier": "Saravana Electronics",
            "product": "3.7V 600mAh Li-ion Rechargeable Battery",
            "quantity": 83,
            "variant": "Imported",
            "has_variant": true,
            "is_manufactured": false,
          },
          {
            "id": 2,
            "s_no": 2,
            "date": "10/23/2026",
            "supplier": "Saravana Electronics",
            "product": "3.7V 6000mAh Li-ion Battery",
            "quantity": 5,
            "variant": "Imported",
            "has_variant": true,
            "is_manufactured": false,
          },
          {
            "id": 3,
            "s_no": 3,
            "date": "10/23/2026",
            "supplier": "Saravana Electronics",
            "product": "3.7V 1200mAh Li-ion Battery",
            "quantity": 10,
            "variant": "Imported",
            "has_variant": true,
            "is_manufactured": false,
          },
          {
            "id": 4,
            "s_no": 4,
            "date": "10/23/2026",
            "supplier": "Saravana Electronics",
            "product": "3.6V 2000 mAh battery",
            "quantity": 5,
            "variant": "Imported",
            "has_variant": true,
            "is_manufactured": false,
          },
          {
            "id": 5,
            "s_no": 5,
            "date": "10/23/2026",
            "supplier": "Saravana Electronics",
            "product": "3000mAh battery",
            "quantity": 59,
            "variant": "Imported",
            "has_variant": true,
            "is_manufactured": false,
          },
          {
            "id": 6,
            "s_no": 6,
            "date": "10/23/2026",
            "supplier": "Saravana Electronics",
            "product": "BNC Female to Female Connector Pin",
            "quantity": 3,
            "variant": "Imported",
            "has_variant": true,
            "is_manufactured": false,
          },
        ];
        supplierSet.add("Saravana Electronics");
        supplierSet.add("Circuitpointcare");
      }

      if (mounted) {
        setState(() {
          stocks = listData;
          suppliers = supplierSet.map((name) => {'name': name}).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error("fetchStocks error", e);
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "billing.srivagroups.in says",
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
        ),
        content: Text(
          "Are you sure you want to delete stock for ${item['product']}?",
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                stocks.removeWhere((e) => e['id'] == item['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Stock deleted successfully"), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5E3A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text("OK", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E5E3A),
              side: const BorderSide(color: Color(0xFFA7F3D0)),
              backgroundColor: const Color(0xFFDCFCE7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter stocks based on mode and query
    List<Map<String, dynamic>> displayedStocks = stocks.where((item) {
      if (isManufactureMode) {
        return item['is_manufactured'] == true;
      }
      if (withVariantMode) {
        if (item['has_variant'] != true) return false;
      } else {
        if (item['has_variant'] == true) return false;
      }

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final p = item['product'].toString().toLowerCase();
        final s = item['supplier'].toString().toLowerCase();
        if (!p.contains(q) && !s.contains(q)) return false;
      }

      if (selectedSupplierFilter != null) {
        if (item['supplier'] != selectedSupplierFilter) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Stock List",
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
            // Top Section: Title & Controls (Photos 1, 2, 3)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.precision_manufacturing_rounded, size: 20, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Stock List",
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    if (isManufactureMode) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.factory_outlined, size: 12, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              "Manufacturing Mode Active",
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // With Variant / Without Variant Toggle (Photos 1 & 2)
                    if (!isManufactureMode)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => withVariantMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: withVariantMode ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: withVariantMode
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: withVariantMode ? const Color(0xFF2563EB) : Colors.grey.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "With Variant",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: withVariantMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => withVariantMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: !withVariantMode ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: !withVariantMode
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: !withVariantMode ? const Color(0xFF2563EB) : Colors.grey.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Without Variant",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: !withVariantMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Manufacture Button (Photo 3)
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          isManufactureMode = !isManufactureMode;
                        });
                      },
                      icon: Icon(
                        Icons.factory_outlined,
                        size: 14,
                        color: isManufactureMode ? const Color(0xFF2563EB) : const Color(0xFF475569),
                      ),
                      label: Text(
                        isManufactureMode ? "Manufacture ✓" : "Manufacture",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isManufactureMode ? const Color(0xFF2563EB) : const Color(0xFF475569),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isManufactureMode ? const Color(0xFFEFF6FF) : Colors.white,
                        side: BorderSide(color: isManufactureMode ? const Color(0xFF93C5FD) : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Bar Container (Photos 1, 2, 3)
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
                            hintText: "Type product name or model...",
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                      Text(isManufactureMode ? "MANUFACTURER" : "SUPPLIER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          value: selectedSupplierFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          items: [
                            DropdownMenuItem(value: null, child: Text(isManufactureMode ? "All Manufacturers" : "All Suppliers", style: GoogleFonts.inter(fontSize: 12))),
                            ...suppliers.map((s) => DropdownMenuItem(value: s['name'].toString(), child: Text(s['name'].toString(), style: GoogleFonts.inter(fontSize: 12)))),
                          ],
                          onChanged: (val) => setState(() => selectedSupplierFilter = val),
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
                            Expanded(flex: 7, child: supplierField),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: showField),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 5, child: searchField),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: supplierField),
                      const SizedBox(width: 16),
                      SizedBox(width: 90, child: showField),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Content Table or Empty View (Photos 1, 2, 3)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: isLoading
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))))
                  : displayedStocks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                            child: Column(
                              children: [
                                const Icon(Icons.add, size: 40, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                Text(
                                  isManufactureMode
                                      ? "No manufacturing product stock entries found."
                                      : "No stock entries found matching your search.",
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // Zero-overflow horizontal scrolling table (Photo 1)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 56,
                                columnSpacing: 24,
                                horizontalMargin: 20,
                                columns: [
                                  DataColumn(label: Text("S.NO", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("DATE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text(isManufactureMode ? "MANUFACTURER" : "SUPPLIER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("PRODUCT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("QUANTITY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("VARIANT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("ACTIONS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                ],
                                rows: displayedStocks.map((item) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(item['s_no'].toString(), style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)))),
                                      DataCell(Text(item['date'].toString(), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))),
                                      DataCell(Text(item['supplier'].toString(), style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500))),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 240),
                                          child: Text(item['product'].toString(), style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                          child: Text(item['quantity'].toString(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                                          child: Text(item['variant'].toString(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
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
                                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF3B82F6)),
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
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
