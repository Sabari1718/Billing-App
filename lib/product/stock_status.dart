import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'stock entry.dart';
import 'storage_allocation.dart';

class StockStatusPage extends StatefulWidget {
  const StockStatusPage({super.key});

  @override
  State<StockStatusPage> createState() => _StockStatusPageState();
}

class _StockStatusPageState extends State<StockStatusPage> {
  // All raw stock items from API
  List<Map<String, dynamic>> allStocks = [];
  bool isLoading = true;
  String? errorMessage;

  // Stat counts matching Photo 1
  int totalItems = 0;
  int totalQty = 0;
  int lowStockCount = 0;
  int outOfStockCount = 0;

  // Filter State
  String searchQuery = "";
  String selectedSupplier = "All Suppliers";
  String selectedStatusFilter = "All Status";
  int currentLimit = 10;
  int currentPage = 1;
  final List<int> limitOptions = [10, 25, 50, 100];

  List<String> suppliersList = ["All Suppliers"];
  final List<String> statusFilterOptions = [
    "All Status",
    "In Stock",
    "Low Stock",
    "Out of Stock",
  ];

  @override
  void initState() {
    super.initState();
    _fetchStockStatus();
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('billing_auth_token') ??
        prefs.getString('auth_token') ??
        prefs.getString('token') ??
        '';
    final businessId = prefs.getString('selected_business_id') ??
        prefs.get('business_id')?.toString() ??
        '52';
    String storeId = prefs.getString('selected_store_id') ??
        prefs.get('store_id')?.toString() ??
        '38';
    if (storeId == '1' || storeId.isEmpty) {
      storeId = '38';
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      'x-business-id': businessId,
      'x-store-id': storeId,
      'x-platform-id': '1',
    };
  }

  Future<Map<String, String>> _getScope() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString('selected_business_id') ??
        prefs.get('business_id')?.toString() ??
        '52';
    String storeId = prefs.getString('selected_store_id') ??
        prefs.get('store_id')?.toString() ??
        '38';
    if (storeId == '1' || storeId.isEmpty) {
      storeId = '38';
    }
    return {
      'business_id': businessId,
      'store_id': storeId,
      'platform_id': '1',
    };
  }

  // -----------------------------------------------------------------------
  // FETCH STOCKS (GET /api/stocks)
  // -----------------------------------------------------------------------
  Future<void> _fetchStockStatus() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final headers = await _getHeaders();
      final scope = await _getScope();
      final bId = scope['business_id']!;
      final sId = scope['store_id']!;

      final url = "https://billing.srivagroups.in/api/stocks?business_id=$bId&store_id=$sId&platform_id=1";
      final res = await http.get(Uri.parse(url), headers: headers);
      debugPrint("StockStatus fetchStocks [${res.statusCode}]: ${res.body.length} chars");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final rawData = decoded['data'];

        List<Map<String, dynamic>> items = [];
        if (rawData is List) {
          for (var item in rawData) {
            if (item is Map) {
              final mapItem = Map<String, dynamic>.from(item);
              final itemStoreId = (mapItem['store_id'] ?? mapItem['store']?['id'])?.toString();
              // If item has a specific store_id, filter to match current active store 38
              if (itemStoreId != null && itemStoreId.isNotEmpty && itemStoreId != '0') {
                if (itemStoreId != sId) {
                  continue;
                }
              }
              items.add(mapItem);
            }
          }
        }

        // Calculate Stats
        int sumQty = 0;
        int lowCount = 0;
        int outCount = 0;
        final Set<String> uniqueSuppliers = {"All Suppliers"};

        for (var item in items) {
          final q = int.tryParse(item['total_qty']?.toString() ?? '0') ?? 0;
          sumQty += q;

          if (q <= 0) {
            outCount++;
          } else if (q < 50) {
            lowCount++;
          }

          // Supplier name
          final supp = item['supplier'];
          if (supp is Map && supp['name'] != null && supp['name'].toString().trim().isNotEmpty) {
            uniqueSuppliers.add(supp['name'].toString().trim());
          }
        }

        if (mounted) {
          setState(() {
            allStocks = items;
            totalItems = items.length;
            totalQty = sumQty;
            lowStockCount = lowCount;
            outOfStockCount = outCount;
            suppliersList = uniqueSuppliers.toList();
            if (!suppliersList.contains(selectedSupplier)) {
              selectedSupplier = "All Suppliers";
            }
            currentPage = 1;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = "Failed to load stocks (status: ${res.statusCode})";
          });
        }
      }
    } catch (e) {
      debugPrint("StockStatus fetch error: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Error loading stocks: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // -----------------------------------------------------------------------
  // DELETE STOCK (DELETE /api/stocks/{id})
  // -----------------------------------------------------------------------
  void _confirmDelete(Map<String, dynamic> item) {
    final pName = item['product_name'] ?? item['product'] ?? "this product";
    final stockId = item['id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          "Delete Stock Entry",
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        content: Text(
          "Are you sure you want to delete stock entry for \"$pName\"?",
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final headers = await _getHeaders();
                final scope = await _getScope();
                final bId = scope['business_id']!;
                final sId = scope['store_id']!;

                final url = "https://billing.srivagroups.in/api/stocks/$stockId?business_id=$bId&store_id=$sId&platform_id=1";
                final res = await http.delete(Uri.parse(url), headers: headers);

                if (res.statusCode >= 200 && res.statusCode < 300) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Stock item deleted successfully"), backgroundColor: Colors.green),
                    );
                    _fetchStockStatus();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Delete failed [${res.statusCode}]"), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Delete error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Delete", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter items
    final filtered = allStocks.where((item) {
      final pName = (item['product_name'] ?? item['product'] ?? '').toString().toLowerCase();
      final pCode = (item['product_code'] ?? '').toString().toLowerCase();
      final supp = (item['supplier'] is Map ? item['supplier']['name'] : item['supplier'])?.toString().toLowerCase() ?? '';

      // Search Query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        if (!pName.contains(q) && !pCode.contains(q) && !supp.contains(q)) {
          return false;
        }
      }

      // Supplier Filter
      if (selectedSupplier != "All Suppliers") {
        final itemSupp = (item['supplier'] is Map ? item['supplier']['name'] : item['supplier'])?.toString().trim() ?? '';
        if (itemSupp.toLowerCase() != selectedSupplier.toLowerCase()) {
          return false;
        }
      }

      // Stock Status Filter
      final q = int.tryParse(item['total_qty']?.toString() ?? '0') ?? 0;
      if (selectedStatusFilter == "In Stock" && q < 50) {
        return false;
      }
      if (selectedStatusFilter == "Low Stock" && (q <= 0 || q >= 50)) {
        return false;
      }
      if (selectedStatusFilter == "Out of Stock" && q > 0) {
        return false;
      }

      return true;
    }).toList();

    // Pagination
    final totalFiltered = filtered.length;
    final totalPages = (totalFiltered / currentLimit).ceil().clamp(1, 99999);
    final safePage = currentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * currentLimit;
    final endIndex = (startIndex + currentLimit).clamp(0, totalFiltered);
    final pagedItems = totalFiltered > 0 ? filtered.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
            tooltip: "Refresh Stock Status",
            onPressed: _fetchStockStatus,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : RefreshIndicator(
              onRefresh: _fetchStockStatus,
              color: const Color(0xFF2563EB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header: Icon, Title & 4 Stat Cards (Photo 1)
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
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: const Icon(Icons.inventory_rounded, color: Color(0xFF2563EB), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Stock Status",
                                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Real-time inventory stock levels & supplier breakdown",
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // 4 Stat Cards (Photo 1)
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
                    const SizedBox(height: 18),

                    // Error Banner if any
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(errorMessage!, style: GoogleFonts.inter(fontSize: 12, color: Colors.red))),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                              onPressed: _fetchStockStatus,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

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
                                  onChanged: (val) {
                                    setState(() {
                                      searchQuery = val;
                                      currentPage = 1;
                                    });
                                  },
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
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: suppliersList.contains(selectedSupplier) ? selectedSupplier : "All Suppliers",
                                    isExpanded: true,
                                    items: suppliersList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedSupplier = val ?? "All Suppliers";
                                        currentPage = 1;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );

                          final statusField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("STOCK STATUS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                              const SizedBox(height: 6),
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedStatusFilter,
                                    isExpanded: true,
                                    items: statusFilterOptions.map((st) => DropdownMenuItem(value: st, child: Text(st, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedStatusFilter = val ?? "All Status";
                                        currentPage = 1;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );

                          final showField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SHOW", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                              const SizedBox(height: 6),
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: currentLimit,
                                    items: limitOptions.map((l) => DropdownMenuItem(value: l, child: Text("$l", style: GoogleFonts.inter(fontSize: 12)))).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        currentLimit = val ?? 10;
                                        currentPage = 1;
                                      });
                                    },
                                  ),
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
                                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                                child: Column(
                                  children: [
                                    const Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text("No stock status records match your filter", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                SingleChildScrollView(
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
                                    rows: List.generate(pagedItems.length, (idx) {
                                      final item = pagedItems[idx];
                                      final sNo = startIndex + idx + 1;
                                      final pName = item['product_name'] ?? item['product'] ?? '-';
                                      final brand = item['brand_name'] ?? (item['variants'] is List && (item['variants'] as List).isNotEmpty ? item['variants'][0]['variant_name'] : null) ?? 'Imported';
                                      final suppName = item['supplier'] is Map ? (item['supplier']['name'] ?? '-') : (item['supplier']?.toString() ?? '-');
                                      final qty = int.tryParse(item['total_qty']?.toString() ?? '0') ?? 0;

                                      final isOut = qty <= 0;
                                      final isLow = qty > 0 && qty < 50;

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
                                          DataCell(Text("$sNo", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)))),
                                          DataCell(
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                ConstrainedBox(
                                                  constraints: const BoxConstraints(maxWidth: 240),
                                                  child: Text(
                                                    pName,
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
                                                    brand,
                                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 180),
                                              child: Text(suppName, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)), overflow: TextOverflow.ellipsis),
                                            ),
                                          ),
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
                                                    "$qty",
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
                                                // Action 1: Manage Storage Allocation (Photos 2 & 3)
                                                Tooltip(
                                                  message: "Manage Storage Allocation",
                                                  child: InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (_) => const StorageAllocationPage()),
                                                      );
                                                    },
                                                    child: Container(
                                                      width: 30,
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEFF6FF),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                                      ),
                                                      child: const Icon(Icons.inventory_2_outlined, size: 15, color: Color(0xFF2563EB)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Action 2: Edit Stock Entry (Photo 4)
                                                Tooltip(
                                                  message: "Edit Stock Entry",
                                                  child: InkWell(
                                                    onTap: () async {
                                                      final res = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => StockEntryPage(editStockItem: item),
                                                        ),
                                                      );
                                                      if (res == true) {
                                                        _fetchStockStatus();
                                                      }
                                                    },
                                                    child: Container(
                                                      width: 30,
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFFBEB),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                                      ),
                                                      child: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFFD97706)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Action 3: Delete / Remove Action
                                                Tooltip(
                                                  message: "Delete Stock Entry",
                                                  child: InkWell(
                                                    onTap: () => _confirmDelete(item),
                                                    child: Container(
                                                      width: 30,
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFEF2F2),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: const Color(0xFFFECACA)),
                                                      ),
                                                      child: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),

                                // Pagination Footer (matching web)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 10,
                                    children: [
                                      Text(
                                        "Showing ${totalFiltered > 0 ? startIndex + 1 : 0} to $endIndex of $totalFiltered entries",
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.chevron_left, size: 18),
                                            onPressed: safePage > 1 ? () => setState(() => currentPage--) : null,
                                          ),
                                          Text(
                                            "Page $safePage of $totalPages",
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.chevron_right, size: 18),
                                            onPressed: safePage < totalPages ? () => setState(() => currentPage++) : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bg, Color textColor, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
