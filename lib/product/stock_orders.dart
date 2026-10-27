import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// =========================================================================
// API & SCOPE HELPERS (BUSINESS: 52, STORE: 38, PLATFORM: 1)
// =========================================================================
Future<Map<String, String>> _getStockHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('billing_auth_token') ??
      prefs.getString('auth_token') ??
      prefs.getString('token') ??
      '';
  final businessId = prefs.getString('selected_business_id') ??
      prefs.get('business_id')?.toString() ??
      '52';
  final storeId = prefs.getString('selected_store_id') ??
      prefs.get('store_id')?.toString() ??
      '38';

  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token.isNotEmpty) 'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
    'x-business-id': businessId,
    'x-store-id': storeId,
    'x-platform-id': '1',
  };
}

Future<Map<String, String>> _getStockScope() async {
  final prefs = await SharedPreferences.getInstance();
  final businessId = prefs.getString('selected_business_id') ??
      prefs.get('business_id')?.toString() ??
      '52';
  final storeId = prefs.getString('selected_store_id') ??
      prefs.get('store_id')?.toString() ??
      '38';
  return {
    'business_id': businessId,
    'store_id': storeId,
    'platform_id': '1',
  };
}

// =========================================================================
// 1. STOCK ORDERS LIST PAGE (PHOTO 1 MATCHING)
// =========================================================================
class StockOrdersPage extends StatefulWidget {
  const StockOrdersPage({super.key});

  @override
  State<StockOrdersPage> createState() => _StockOrdersPageState();
}

class _StockOrdersPageState extends State<StockOrdersPage> {
  List<Map<String, dynamic>> stockOrders = [];
  bool isLoading = true;
  String searchQuery = "";
  bool isTableView = true;

  @override
  void initState() {
    super.initState();
    _loadStockOrders();
  }

  Future<void> _loadStockOrders() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final headers = await _getStockHeaders();
      final scope = await _getStockScope();
      final bId = scope['business_id']!;
      final sId = scope['store_id']!;

      // 1. GET /api/stock-orders
      final stockOrderUrl = "https://billing.srivagroups.in/api/stock-orders?business_id=$bId&store_id=$sId&platform_id=1";
      final res = await http.get(Uri.parse(stockOrderUrl), headers: headers);
      debugPrint("StockOrders GET status: ${res.statusCode}");

      // Also trigger /api/products and /api/new-product as web does
      http.get(
        Uri.parse("https://billing.srivagroups.in/api/products?business_id=$bId&store_id=$sId&platform_id=1"),
        headers: headers,
      ).catchError((_) => http.Response('{}', 500));

      http.get(
        Uri.parse("https://billing.srivagroups.in/api/new-product?business_id=$bId&store_id=$sId&platform_id=1"),
        headers: headers,
      ).catchError((_) => http.Response('{}', 500));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final dynamic rawData = decoded['data'];
        List<Map<String, dynamic>> loaded = [];
        if (rawData is List) {
          for (var item in rawData) {
            if (item is Map) {
              loaded.add(Map<String, dynamic>.from(item));
            }
          }
        }
        if (mounted) {
          setState(() {
            stockOrders = loaded;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading stock orders: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _navigateToAddStockOrder({Map<String, dynamic>? editOrder}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStockOrderPage(editOrder: editOrder),
      ),
    );
    if (result == true) {
      _loadStockOrders();
    }
  }

  Future<void> _deleteStockOrder(Map<String, dynamic> order) async {
    final orderId = order['id'];
    if (orderId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Stock Order", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to delete this stock order for \"${order['name'] ?? order['product'] ?? 'this product'}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final headers = await _getStockHeaders();
                final scope = await _getStockScope();
                final bId = scope['business_id']!;
                final sId = scope['store_id']!;

                final url = "https://billing.srivagroups.in/api/stock-orders/$orderId?business_id=$bId&store_id=$sId&platform_id=1";
                final res = await http.delete(Uri.parse(url), headers: headers);

                if (res.statusCode >= 200 && res.statusCode < 300) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Stock order deleted successfully"), backgroundColor: Colors.green),
                    );
                    _loadStockOrders();
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: Text("Delete", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = stockOrders.where((order) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final p = (order['product_name'] ?? order['product'] ?? '').toString().toLowerCase();
        final o = (order['name'] ?? order['order_name'] ?? '').toString().toLowerCase();
        return p.contains(q) || o.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Stock Orders",
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
            tooltip: "Refresh",
            onPressed: _loadStockOrders,
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
              onRefresh: _loadStockOrders,
              color: const Color(0xFF2563EB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section Container (Photo 1)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Wrap(
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
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Stock Orders",
                                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Manage and track your stock orders",
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Actions & Search Block
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Search Input
                              SizedBox(
                                width: 200,
                                height: 38,
                                child: TextField(
                                  onChanged: (val) => setState(() => searchQuery = val),
                                  style: GoogleFonts.inter(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: "Search by Product Name...",
                                    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
                                    prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  ),
                                ),
                              ),
                              // View Toggle (Table / Cards)
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => isTableView = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isTableView ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.table_rows_outlined, size: 14, color: isTableView ? const Color(0xFF2563EB) : Colors.grey),
                                            const SizedBox(width: 4),
                                            Text("Table", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isTableView ? const Color(0xFF2563EB) : Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => isTableView = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: !isTableView ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.grid_view_outlined, size: 14, color: !isTableView ? const Color(0xFF2563EB) : Colors.grey),
                                            const SizedBox(width: 4),
                                            Text("Cards", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: !isTableView ? const Color(0xFF2563EB) : Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Refresh Icon Button
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
                                onPressed: _loadStockOrders,
                                tooltip: "Reload orders",
                              ),
                              // Add Stock Order Button (Photo 1)
                              ElevatedButton.icon(
                                onPressed: () => _navigateToAddStockOrder(),
                                icon: const Icon(Icons.add, size: 15, color: Colors.white),
                                label: Text("Add Stock Order", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content Area (Empty state or Orders List)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: filteredOrders.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40.0),
                                child: Column(
                                  children: [
                                    // 3D Box Outline Icon (Photo 1)
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: const Icon(Icons.all_inbox_outlined, size: 44, color: Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      "No Stock Orders Found",
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 380),
                                      child: Text(
                                        "You have not added any stock orders yet. Click below to create your first stock order.",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF64748B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // + Create First Stock Order button (Photo 1)
                                    ElevatedButton.icon(
                                      onPressed: () => _navigateToAddStockOrder(),
                                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                      label: Text(
                                        "Create First Stock Order",
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : isTableView
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                    columns: [
                                      DataColumn(label: Text("PRODUCT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                      DataColumn(label: Text("STOCK ORDER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                      DataColumn(label: Text("MIN STOCK", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                      DataColumn(label: Text("MAX STOCK", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                      DataColumn(label: Text("DAYS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                      DataColumn(label: Text("AMOUNT (₹)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                      DataColumn(label: Text("ACTIONS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                    ],
                                    rows: filteredOrders.map((order) {
                                      final pName = order['product_name'] ?? order['product'] ?? '-';
                                      final oName = order['name'] ?? order['order_name'] ?? '-';
                                      final minS = order['min_stock']?.toString() ?? '0';
                                      final maxS = order['max_stock']?.toString() ?? '10';
                                      final days = order['days']?.toString() ?? '1';
                                      final amount = order['amount']?.toString() ?? '0';

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(pName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                                          DataCell(Text(oName, style: GoogleFonts.inter(fontSize: 13))),
                                          DataCell(Text(minS, style: GoogleFonts.inter(fontSize: 13))),
                                          DataCell(Text(maxS, style: GoogleFonts.inter(fontSize: 13))),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text("$days Days", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                                            ),
                                          ),
                                          DataCell(Text("₹$amount", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)))),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFF59E0B)),
                                                  onPressed: () => _navigateToAddStockOrder(editOrder: order),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                                  onPressed: () => _deleteStockOrder(order),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: filteredOrders.map((order) {
                                        final pName = order['product_name'] ?? order['product'] ?? '-';
                                        final oName = order['name'] ?? order['order_name'] ?? '-';
                                        final minS = order['min_stock']?.toString() ?? '0';
                                        final maxS = order['max_stock']?.toString() ?? '10';
                                        final days = order['days']?.toString() ?? '1';
                                        final amount = order['amount']?.toString() ?? '0';

                                        return Container(
                                          width: constraints.maxWidth > 600 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      pName,
                                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    "₹$amount",
                                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text("Order: $oName", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                                    child: Text("Min: $minS", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                                    child: Text("Max: $maxS", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                                                    child: Text("$days Days", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                                                  ),
                                                  const Spacer(),
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFF59E0B)),
                                                    onPressed: () => _navigateToAddStockOrder(editOrder: order),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                                    onPressed: () => _deleteStockOrder(order),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// =========================================================================
// 2. ADD STOCK ORDER & MASTER MANAGEMENT PAGE (PHOTOS 2, 3, 4, 5)
// =========================================================================
class AddStockOrderPage extends StatefulWidget {
  final Map<String, dynamic>? editOrder;
  final int initialTab;

  const AddStockOrderPage({
    super.key,
    this.editOrder,
    this.initialTab = 0,
  });

  @override
  State<AddStockOrderPage> createState() => _AddStockOrderPageState();
}

class _AddStockOrderPageState extends State<AddStockOrderPage> {
  // Tab index: 0 = Stock Order Configuration (Photo 2), 1 = List (Photos 3, 4, 5)
  late int selectedTab;

  // Master List Sub-Mode: false = Table/Empty list view, true = Form view (Photo 4)
  bool isCreatingMaster = false;
  Map<String, dynamic>? editingMaster;

  // Data lists
  List<Map<String, dynamic>> productsList = [];
  List<Map<String, dynamic>> masterList = [];
  bool isLoadingProducts = true;
  bool isLoadingMasters = true;
  bool isSaving = false;

  // Controllers for Tab 0: Stock Order Configuration (Photo 2)
  String? selectedProductId;
  final orderNameCtrl = TextEditingController();
  final minStockCtrl = TextEditingController(text: "0");
  final maxStockCtrl = TextEditingController(text: "10");
  final daysCtrl = TextEditingController(text: "1");
  final amountCtrl = TextEditingController();

  // Controllers for Tab 1 Form: Create/Edit Stock Order Master (Photo 4)
  final masterNameCtrl = TextEditingController();
  final masterAmountCtrl = TextEditingController();
  final masterDaysCtrl = TextEditingController(text: "1");

  // Search filter in Master List
  String masterSearchQuery = "";

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _loadProducts(),
      _fetchMasters(),
    ]);

    // If edit mode for Stock Order
    if (widget.editOrder != null) {
      final o = widget.editOrder!;
      selectedProductId = (o['product_id'] ?? o['productId'])?.toString();
      orderNameCtrl.text = (o['name'] ?? o['order_name'] ?? '').toString();
      minStockCtrl.text = (o['min_stock'] ?? '0').toString();
      maxStockCtrl.text = (o['max_stock'] ?? '10').toString();
      daysCtrl.text = (o['days'] ?? '1').toString();
      amountCtrl.text = (o['amount'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    orderNameCtrl.dispose();
    minStockCtrl.dispose();
    maxStockCtrl.dispose();
    daysCtrl.dispose();
    amountCtrl.dispose();
    masterNameCtrl.dispose();
    masterAmountCtrl.dispose();
    masterDaysCtrl.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // LOAD PRODUCTS
  // -----------------------------------------------------------------------
  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => isLoadingProducts = true);

    try {
      final headers = await _getStockHeaders();
      final scope = await _getStockScope();
      final bId = scope['business_id']!;
      final sId = scope['store_id']!;

      List<Map<String, dynamic>> prods = [];

      // 1. Try GET /api/products
      try {
        final res = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/products?business_id=$bId&store_id=$sId&platform_id=1"),
          headers: headers,
        );
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final raw = decoded['products'] ?? decoded['data']?['products'] ?? decoded['data'];
          if (raw is List) {
            for (var p in raw) {
              if (p is Map) prods.add(Map<String, dynamic>.from(p));
            }
          }
        }
      } catch (_) {}

      // 2. Try GET /api/new-product
      try {
        final res2 = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/new-product?business_id=$bId&store_id=$sId&platform_id=1"),
          headers: headers,
        );
        if (res2.statusCode == 200) {
          final decoded2 = jsonDecode(res2.body);
          final raw2 = decoded2['data'];
          if (raw2 is List) {
            for (var p in raw2) {
              if (p is Map && !prods.any((e) => e['id']?.toString() == p['id']?.toString())) {
                prods.add(Map<String, dynamic>.from(p));
              }
            }
          }
        }
      } catch (_) {}

      // 3. Fallback to productAllocation if empty
      if (prods.isEmpty) {
        try {
          final res3 = await http.get(
            Uri.parse("https://billing.srivagroups.in/api/productAllocation?business_id=$bId&store_id=$sId"),
            headers: headers,
          );
          if (res3.statusCode == 200) {
            final decoded3 = jsonDecode(res3.body);
            final rawData = decoded3['data'];
            if (rawData is List) {
              for (var cat in rawData) {
                if (cat is Map) {
                  final brands = cat['brands'] ?? cat['Brands'] ?? [];
                  if (brands is List) {
                    for (var b in brands) {
                      if (b is Map) {
                        final plist = b['products'] ?? b['Products'] ?? [];
                        if (plist is List) {
                          for (var p in plist) {
                            if (p is Map) prods.add(Map<String, dynamic>.from(p));
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      // Default mock products as safe fallback if DB returns empty
      if (prods.isEmpty) {
        prods = [
          {'id': '466', 'name': 'Mq-2 Gas Sensor', 'product_name': 'Mq-2 Gas Sensor'},
          {'id': '3417', 'name': '10D20 MOV Thermistor', 'product_name': '10D20 MOV Thermistor'},
          {'id': '3418', 'name': '10D431 MOV Thermister', 'product_name': '10D431 MOV Thermister'},
          {'id': '3419', 'name': '3.7V 600mAh Li-ion Rechargeable Battery', 'product_name': '3.7V 600mAh Li-ion Rechargeable Battery'},
          {'id': '3420', 'name': '3.7V 6000mAh Li-ion Battery', 'product_name': '3.7V 6000mAh Li-ion Battery'},
        ];
      }

      if (mounted) {
        setState(() {
          productsList = prods;
          if (selectedProductId == null && productsList.isNotEmpty) {
            selectedProductId = productsList.first['id']?.toString();
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading products for stock order: $e");
    } finally {
      if (mounted) setState(() => isLoadingProducts = false);
    }
  }

  // -----------------------------------------------------------------------
  // FETCH STOCK ORDER MASTERS (GET /api/stock-orders/masters)
  // -----------------------------------------------------------------------
  Future<void> _fetchMasters() async {
    if (!mounted) return;
    setState(() => isLoadingMasters = true);

    try {
      final headers = await _getStockHeaders();
      final scope = await _getStockScope();
      final bId = scope['business_id']!;
      final sId = scope['store_id']!;

      final url = "https://billing.srivagroups.in/api/stock-orders/masters?business_id=$bId&store_id=$sId&platform_id=1";
      final res = await http.get(Uri.parse(url), headers: headers);
      debugPrint("fetchMasters GET [${res.statusCode}]: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded['data'];
        List<Map<String, dynamic>> list = [];
        if (raw is List) {
          for (var item in raw) {
            if (item is Map) list.add(Map<String, dynamic>.from(item));
          }
        }
        if (mounted) {
          setState(() {
            masterList = list;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching stock order masters: $e");
    } finally {
      if (mounted) setState(() => isLoadingMasters = false);
    }
  }

  // -----------------------------------------------------------------------
  // SAVE STOCK ORDER CONFIGURATION (POST or PUT /api/stock-orders)
  // -----------------------------------------------------------------------
  Future<void> _saveStockOrder() async {
    if (selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product"), backgroundColor: Colors.orange),
      );
      return;
    }

    final name = orderNameCtrl.text.trim().isEmpty ? "Order #1" : orderNameCtrl.text.trim();
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
    final minStock = int.tryParse(minStockCtrl.text.trim()) ?? 0;
    final maxStock = int.tryParse(maxStockCtrl.text.trim()) ?? 10;
    final days = int.tryParse(daysCtrl.text.trim()) ?? 1;

    setState(() => isSaving = true);

    try {
      final headers = await _getStockHeaders();
      final scope = await _getStockScope();
      final bId = scope['business_id']!;
      final sId = scope['store_id']!;

      final payload = {
        "product_id": int.tryParse(selectedProductId!) ?? selectedProductId,
        "name": name,
        "min_stock": minStock,
        "max_stock": maxStock,
        "days": days,
        "amount": amount,
        "business_id": int.tryParse(bId) ?? 52,
        "store_id": int.tryParse(sId) ?? 38,
        "platform_id": 1,
      };

      final bool isEdit = widget.editOrder != null && widget.editOrder!['id'] != null;
      final url = isEdit
          ? "https://billing.srivagroups.in/api/stock-orders/${widget.editOrder!['id']}?business_id=$bId&store_id=$sId&platform_id=1"
          : "https://billing.srivagroups.in/api/stock-orders?business_id=$bId&store_id=$sId&platform_id=1";

      final res = isEdit
          ? await http.put(Uri.parse(url), headers: headers, body: jsonEncode(payload))
          : await http.post(Uri.parse(url), headers: headers, body: jsonEncode(payload));

      debugPrint("saveStockOrder response [${res.statusCode}]: ${res.body}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? "Stock order updated successfully" : "Stock order created successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save stock order [${res.statusCode}]"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // -----------------------------------------------------------------------
  // SAVE STOCK ORDER MASTER (POST or PUT /api/stock-orders/masters)
  // -----------------------------------------------------------------------
  Future<void> _saveMaster() async {
    final name = masterNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Stock Order Name"), backgroundColor: Colors.orange),
      );
      return;
    }

    final amount = double.tryParse(masterAmountCtrl.text.trim());
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount"), backgroundColor: Colors.orange),
      );
      return;
    }

    final days = int.tryParse(masterDaysCtrl.text.trim()) ?? 1;

    setState(() => isSaving = true);

    try {
      final headers = await _getStockHeaders();
      final scope = await _getStockScope();
      final bId = scope['business_id']!;
      final sId = scope['store_id']!;

      final payload = {
        "name": name,
        "amount": amount,
        "days": days,
        "business_id": int.tryParse(bId) ?? 52,
        "store_id": int.tryParse(sId) ?? 38,
        "platform_id": 1,
      };

      final bool isEdit = editingMaster != null && editingMaster!['id'] != null;
      final url = isEdit
          ? "https://billing.srivagroups.in/api/stock-orders/masters/${editingMaster!['id']}?business_id=$bId&store_id=$sId&platform_id=1"
          : "https://billing.srivagroups.in/api/stock-orders/masters?business_id=$bId&store_id=$sId&platform_id=1";

      final res = isEdit
          ? await http.put(Uri.parse(url), headers: headers, body: jsonEncode(payload))
          : await http.post(Uri.parse(url), headers: headers, body: jsonEncode(payload));

      debugPrint("saveMaster response [${res.statusCode}]: ${res.body}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? "Stock order master updated successfully" : "Stock order master created successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Reset master form
        masterNameCtrl.clear();
        masterAmountCtrl.clear();
        masterDaysCtrl.text = "1";
        setState(() {
          isCreatingMaster = false;
          editingMaster = null;
        });

        // Refresh masters list
        _fetchMasters();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save master [${res.statusCode}]"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Master save error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // -----------------------------------------------------------------------
  // DELETE STOCK ORDER MASTER (DELETE /api/stock-orders/masters/{id})
  // -----------------------------------------------------------------------
  Future<void> _deleteMaster(Map<String, dynamic> master) async {
    final masterId = master['id'];
    if (masterId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Stock Order Master", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to delete master \"${master['name'] ?? ''}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final headers = await _getStockHeaders();
                final scope = await _getStockScope();
                final bId = scope['business_id']!;
                final sId = scope['store_id']!;

                final url = "https://billing.srivagroups.in/api/stock-orders/masters/$masterId?business_id=$bId&store_id=$sId&platform_id=1";
                final res = await http.delete(Uri.parse(url), headers: headers);

                if (res.statusCode >= 200 && res.statusCode < 300) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Stock order master deleted successfully"), backgroundColor: Colors.green),
                    );
                    _fetchMasters();
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: Text("Delete", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          selectedTab == 0 ? "Stock Order Configuration" : "Stock Order Masters",
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
          children: [
            // Top Nav Bar (Photos 2 & 3: Back to Stock Orders | Toggle Tabs)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    if (isCreatingMaster) {
                      setState(() {
                        isCreatingMaster = false;
                        editingMaster = null;
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF475569)),
                  label: Text(
                    isCreatingMaster ? "Back to Master List" : "Back to Stock Orders",
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),

                // Toggle Bar [ Stock Order | List (count) ]
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tab 0: Stock Order
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = 0;
                            isCreatingMaster = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: selectedTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: selectedTab == 0
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.layers_outlined,
                                size: 14,
                                color: selectedTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Stock Order",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selectedTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tab 1: List (with badge count matching Photo 5)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = 1;
                            isCreatingMaster = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: selectedTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: selectedTab == 1
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.format_list_bulleted,
                                size: 14,
                                color: selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                masterList.isNotEmpty ? "List ${masterList.length}" : "List",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selectedTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab Content
            selectedTab == 0
                ? _buildStockOrderConfiguration()
                : (isCreatingMaster ? _buildMasterForm() : _buildMasterList()),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // TAB 0: STOCK ORDER CONFIGURATION (PHOTO 2)
  // =======================================================================
  Widget _buildStockOrderConfiguration() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Tune/Sliders Icon
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Stock Order Configuration",
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Configure stock thresholds, order quantities, cycle days and amount per product",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Field 1: Product *
              _buildLabel("Product", true),
              const SizedBox(height: 6),
              isLoadingProducts
                  ? const LinearProgressIndicator(color: Color(0xFF2563EB))
                  : DropdownButtonFormField<String>(
                      value: productsList.any((p) => p['id']?.toString() == selectedProductId)
                          ? selectedProductId
                          : (productsList.isNotEmpty ? productsList.first['id']?.toString() : null),
                      hint: Text("-- Search / Select Product --", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                      isExpanded: true,
                      decoration: _inputDecoration(),
                      items: productsList.map((p) {
                        final idStr = p['id']?.toString() ?? '';
                        final name = p['product_name'] ?? p['name'] ?? "Product #$idStr";
                        return DropdownMenuItem(
                          value: idStr,
                          child: Text(name, style: GoogleFonts.inter(fontSize: 13), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedProductId = val);
                      },
                    ),
              const SizedBox(height: 18),

              // Master templates quick-fill chips if any exist
              if (masterList.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      "Apply Predefined Master Template:",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: masterList.map((m) {
                    return ActionChip(
                      backgroundColor: const Color(0xFFEFF6FF),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      label: Text(
                        "${m['name']} (₹${m['amount'] ?? 0})",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
                      ),
                      onPressed: () {
                        setState(() {
                          orderNameCtrl.text = m['name']?.toString() ?? '';
                          amountCtrl.text = m['amount']?.toString() ?? '';
                          daysCtrl.text = (m['days'] ?? 1).toString();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Template \"${m['name']}\" applied"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
              ],

              // Field 2: Stock Order * & Min Stock *
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 450;

                  final stockOrderField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Stock Order", true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: orderNameCtrl,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: _inputDecoration(hint: "e.g. Weekly Order"),
                      ),
                    ],
                  );

                  final minStockField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Min Stock", true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: minStockCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: _inputDecoration(hint: "0"),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        stockOrderField,
                        const SizedBox(height: 18),
                        minStockField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 6, child: stockOrderField),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: minStockField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              // Field 3: Max Stock * & Days *
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 450;

                  final maxStockField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Max Stock", true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: maxStockCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: _inputDecoration(hint: "10"),
                      ),
                    ],
                  );

                  final daysField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Days", true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: daysCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: _inputDecoration(hint: "1"),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        maxStockField,
                        const SizedBox(height: 18),
                        daysField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: maxStockField),
                      const SizedBox(width: 16),
                      Expanded(child: daysField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              // Field 4: Amount *
              _buildLabel("Amount", true),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(fontSize: 13),
                decoration: _inputDecoration(
                  hint: "Enter Amount (e.g. 5000)",
                  prefixText: "₹   ",
                ),
              ),
              const SizedBox(height: 28),

              // Bottom Buttons (Cancel & Save Stock Order)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isSaving ? null : _saveStockOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            widget.editOrder != null ? "Update Stock Order" : "Save Stock Order",
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =======================================================================
  // TAB 1: STOCK ORDER MASTER LIST (PHOTOS 3 & 5)
  // =======================================================================
  Widget _buildMasterList() {
    final filteredMasters = masterList.where((m) {
      if (masterSearchQuery.isNotEmpty) {
        final q = masterSearchQuery.toLowerCase();
        final name = (m['name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }
      return true;
    }).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Photos 3 & 5)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stock Order Master List",
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Manage predefined stock order configurations and cycle parameters",
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 38,
                      child: TextField(
                        onChanged: (val) => setState(() => masterSearchQuery = val),
                        style: GoogleFonts.inter(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: "Search by Stock Order Name...",
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          editingMaster = null;
                          masterNameCtrl.clear();
                          masterAmountCtrl.clear();
                          masterDaysCtrl.text = "1";
                          isCreatingMaster = true;
                        });
                      },
                      icon: const Icon(Icons.add, size: 15, color: Colors.white),
                      label: Text("Create Stock Order", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body: Empty State or Table
          isLoadingMasters
              ? const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
                )
              : filteredMasters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
                        child: Column(
                          children: [
                            // 3D Box Outline Icon (Photo 3)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.all_inbox_outlined, size: 44, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              "No Stock Orders Found",
                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: Text(
                                "No Stock Order master records found. Click \"+ Create Stock Order\" to add one.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  editingMaster = null;
                                  masterNameCtrl.clear();
                                  masterAmountCtrl.clear();
                                  masterDaysCtrl.text = "1";
                                  isCreatingMaster = true;
                                });
                              },
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              label: Text("Create Stock Order", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Master Table (Photo 5)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 700),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              horizontalMargin: 24,
                              columnSpacing: 32,
                              columns: [
                                DataColumn(label: Text("S.NO", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                DataColumn(label: Text("STOCK ORDER NAME", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                DataColumn(label: Text("AMOUNT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                DataColumn(label: Text("DAYS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                DataColumn(label: Text("ACTION", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                              ],
                              rows: List.generate(filteredMasters.length, (idx) {
                                final item = filteredMasters[idx];
                                final numAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                                final formattedAmount = "₹${numAmount.toStringAsFixed(2)}";
                                final daysStr = item['days']?.toString() ?? '1';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                        child: Text("${idx + 1}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        item['name']?.toString() ?? '-',
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        formattedAmount,
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFFDE68A)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFD97706)),
                                            const SizedBox(width: 4),
                                            Text(
                                              "$daysStr Day${daysStr == '1' ? '' : 's'}",
                                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Edit Action Button (Amber rounded container, Photo 5)
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                editingMaster = item;
                                                masterNameCtrl.text = item['name']?.toString() ?? '';
                                                masterAmountCtrl.text = item['amount']?.toString() ?? '';
                                                masterDaysCtrl.text = (item['days'] ?? 1).toString();
                                                isCreatingMaster = true;
                                              });
                                            },
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFFBEB),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFFCD34D)),
                                              ),
                                              child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFD97706)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Delete Action Button (Red rounded container, Photo 5)
                                          InkWell(
                                            onTap: () => _deleteMaster(item),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF2F2),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFFECACA)),
                                              ),
                                              child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
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
                        ),

                        // Pagination Footer (Photo 5)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              Text(
                                "Show 10 entries",
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Showing 1 to ${filteredMasters.length} of ${filteredMasters.length} entries",
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 14),
                                  Text("Go to Page:", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 36,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text("1", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text("1", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  // =======================================================================
  // TAB 1 FORM: CREATE OR EDIT STOCK ORDER MASTER (PHOTO 4)
  // =======================================================================
  Widget _buildMasterForm() {
    final bool isEdit = editingMaster != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Green Checklist Icon (Photo 4)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEdit ? "Edit Stock Order Master" : "Create Stock Order Master",
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Define reusable stock order parameters (name, amount, days)",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Field 1: Stock Order Name *
              _buildLabel("Stock Order Name", true),
              const SizedBox(height: 6),
              TextField(
                controller: masterNameCtrl,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: _inputDecoration(hint: "Enter Stock Order Name (e.g. Weekly Order)"),
              ),
              const SizedBox(height: 18),

              // Field 2: Amount *
              _buildLabel("Amount", true),
              const SizedBox(height: 6),
              TextField(
                controller: masterAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(fontSize: 13),
                decoration: _inputDecoration(
                  hint: "Enter Amount (e.g. 5000)",
                  prefixText: "₹   ",
                ),
              ),
              const SizedBox(height: 18),

              // Field 3: Days *
              _buildLabel("Days", true),
              const SizedBox(height: 6),
              TextField(
                controller: masterDaysCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: _inputDecoration(hint: "1"),
              ),
              const SizedBox(height: 28),

              // Bottom Buttons (Cancel & Create / Update Stock Order)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        isCreatingMaster = false;
                        editingMaster = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isSaving ? null : _saveMaster,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            isEdit ? "Update Stock Order" : "Create Stock Order",
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // HELPERS
  // -----------------------------------------------------------------------
  Widget _buildLabel(String text, bool isRequired) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
        ),
        if (isRequired)
          Text(
            " *",
            style: GoogleFonts.inter(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
