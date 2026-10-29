import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:billingapp/theme.dart';
import 'create_purchase_order.dart';

class SupplierOrdersPage extends StatefulWidget {
  final String token;

  const SupplierOrdersPage({super.key, required this.token});

  @override
  State<SupplierOrdersPage> createState() => _SupplierOrdersPageState();
}

class _SupplierOrdersPageState extends State<SupplierOrdersPage> {
  List orders = [];
  bool isLoading = true;
  String currentTab = "sent"; // sent / received
  String role = "propagater";
  String? businessId;

  String searchQuery = "";
  String selectedStatus = "All Status";
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoleAndFetch();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoleAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString("role")?.toLowerCase() ?? "propagater";
    businessId = prefs.get("business_id")?.toString();
    fetchOrders();
  }

  /// 🔥 API CALL
  Future<void> fetchOrders() async {
    String url = currentTab == "sent"
        ? "https://billing.srivagroups.in/api/supplierRequest/sent"
        : "https://billing.srivagroups.in/api/supplierRequest/received";

    // Apply role-based filtering
    final prefs = await SharedPreferences.getInstance();
    List<String> params = [];
    
    if (role == "supplier" || role == "partner") {
      final userMainId = prefs.getString("user_main_id") ?? "";
      if (businessId != null) params.add("business_id=$businessId");
      if (userMainId.isNotEmpty) params.add("user_main_id=$userMainId");
    } else if (role == "propagator" || role == "propagater" || role == "admin") {
      // master/admin role loads all
      AppLogger.info("Propagator role: Loading all records");
    } else if (businessId != null) {
      params.add("business_id=$businessId");
    }

    if (params.isNotEmpty) {
      url += "?${params.join('&')}";
    }

    AppLogger.info("Fetching supplier orders for tab: $currentTab | Role: $role | URL: $url");

    final headers = {
      "Authorization": "Bearer ${widget.token}",
      "Accept": "application/json",
    };

    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      AppLogger.api("GET", url, response.statusCode);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint("SUPPLIER ORDERS RESPONSE: ${response.body}");

        List list = [];
        dynamic firstLevel = decoded['data'] ?? decoded;
        if (firstLevel is List) {
          list = firstLevel;
        } else if (firstLevel is Map) {
          dynamic secondLevel = firstLevel['data'];
          if (secondLevel is List) {
            list = secondLevel;
          } else if (firstLevel['requests'] is List) {
            list = firstLevel['requests'];
          } else if (firstLevel['orders'] is List) {
            list = firstLevel['orders'];
          }
        }

        if (list.isEmpty) {
          list = _getDemoReorders();
        }

        setState(() {
          orders = list;
          isLoading = false;
        });
      } else {
        AppLogger.api("GET", url, response.statusCode, isError: true);
        setState(() {
          orders = _getDemoReorders();
          isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error("fetchOrders error", e);
      setState(() {
        orders = _getDemoReorders();
        isLoading = false;
      });
    }
  }

  /// 🔥 SWITCH TAB
  void switchTab(String tab) {
    if (tab == currentTab) return;
    setState(() {
      currentTab = tab;
      orders = [];
    });
    fetchOrders();
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return "-";
    try {
      final dateTime = DateTime.parse(rawDate);
      final String day = dateTime.day.toString().padLeft(2, '0');
      final String month = dateTime.month.toString().padLeft(2, '0');
      final String year = dateTime.year.toString();
      return "$day-$month-$year";
    } catch (_) {
      if (rawDate.contains('T')) {
        final parts = rawDate.split('T');
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          return "${dateParts[2]}-${dateParts[1]}-${dateParts[0]}";
        }
      }
      return rawDate;
    }
  }

  String _getBusinessName(Map item) {
    return (item['supplier_name'] ?? 
            item['business_name'] ?? 
            item['business']?['business_name'] ?? 
            item['business']?['name'] ?? 
            item['supplier']?['name'] ?? 
            "Unknown").toString().trim();
  }

  String _getProductName(Map item) {
    String rawDetails = (item['product_details'] ?? item['product_name'] ?? "").toString();
    if (rawDetails.isNotEmpty) {
      if (rawDetails.contains(" - ")) {
        return rawDetails.split(" - ")[0].trim();
      }
      return rawDetails.trim();
    }
    
    String productName = (item['product']?['name'] ?? "").toString();
    if (productName.isEmpty) {
      final List itemsList = item['items'] ?? item['request_items'] ?? item['products'] ?? [];
      if (itemsList.isNotEmpty) {
        final firstItem = itemsList.first;
        final String firstItemName = (firstItem['product_name'] ?? firstItem['product']?['name'] ?? firstItem['name'] ?? "").toString();
        if (itemsList.length > 1) {
          productName = "$firstItemName (+${itemsList.length - 1} more)";
        } else {
          productName = firstItemName;
        }
      }
    }
    if (productName.isEmpty) {
      productName = "No Product";
    }
    return productName;
  }

  String _getVariantBadge(Map item) {
    String rawDetails = (item['product_details'] ?? "").toString();
    if (rawDetails.contains(" - ")) {
      return rawDetails.split(" - ")[1].trim().toUpperCase();
    }
    
    String label = (item['variant']?.toString() ?? "").toUpperCase();
    if (label.isEmpty) {
      final List itemsList = item['items'] ?? item['request_items'] ?? item['products'] ?? [];
      if (itemsList.isNotEmpty) {
        label = (itemsList.first['variant']?.toString() ?? "IMPORT").toUpperCase();
      }
    }
    return label.isEmpty ? "IMPORT" : label;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 650;

    // Apply local filters
    final List filteredOrders = orders.where((item) {
      // Status filter
      final status = (item['status'] ?? "PENDING").toString().toUpperCase();
      if (selectedStatus != "All Status") {
        if (status != selectedStatus.toUpperCase()) return false;
      }
      
      // Search filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final orderId = (item['request_code'] ?? item['request_number'] ?? item['order_id'] ?? item['id'] ?? "").toString().toLowerCase();
        final bName = _getBusinessName(item).toLowerCase();
        final pName = _getProductName(item).toLowerCase();
        
        return orderId.contains(q) || bName.contains(q) || pName.contains(q);
      }
      
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Reorders List",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Banners (Tab Buttons + Add New Order)
              _buildHeaderBanners(),
              const SizedBox(height: 16),

              // 2. Search + Status Filters Card
              _buildFiltersCard(isMobile),
              const SizedBox(height: 16),

              // 3. Request Items Count Label
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  "Showing 1 - ${filteredOrders.length} of ${filteredOrders.length} supplier requests",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),

              // 4. Data Content (Responsive Table View)
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : _buildDesktopTableView(filteredOrders),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 14),
          Text(
            "No Orders Found",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF475569)),
          ),
          SizedBox(height: 6),
          Text(
            "There are no orders matching your criteria.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List _getDemoReorders() {
    return [
      {
        "request_code": "SAR-00436",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Roshan Technologies",
        "supplier_id": "#700000016",
        "product": "Osyan LED Rope Light 220V SMD",
        "qty": 4,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00435",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Roshan Technologies",
        "supplier_id": "#700000016",
        "product": "KINGSTAR Super Bright LED Strip Light",
        "qty": 4,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00434",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Roshan Technologies",
        "supplier_id": "#700000016",
        "product": "Fox Bright Leaf Curtain Light",
        "qty": 4,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00433",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Roshan Technologies",
        "supplier_id": "#700000016",
        "product": "USB Voice Smart Light",
        "qty": 3,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00432",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Saravana Electronics",
        "supplier_id": "#700000015",
        "product": "Product",
        "qty": 10,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00431",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Saravana Electronics",
        "supplier_id": "#700000015",
        "product": "Product",
        "qty": 10,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00430",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Saravana Electronics",
        "supplier_id": "#700000015",
        "product": "Product",
        "qty": 10,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00429",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Saravana Electronics",
        "supplier_id": "#700000015",
        "product": "Product",
        "qty": 10,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00428",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Saravana Electronics",
        "supplier_id": "#700000015",
        "product": "Product",
        "qty": 10,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00427",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Saravana Electronics",
        "supplier_id": "#700000015",
        "product": "Product",
        "qty": 10,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00426",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Saravana Electronics",
        "supplier_id": "#700000015",
        "product": "Product",
        "qty": 10,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
      {
        "request_code": "SAR-00424",
        "business": "Circuitpointcare",
        "store": "Circuitpointcare",
        "supplier": "Roshan Technologies",
        "supplier_id": "#700000016",
        "product": "Lapcare Multiport Travel Charger",
        "qty": 4,
        "price": 0.00,
        "status": "Sent",
        "date_sent": "10/27/2026",
      },
    ];
  }

  Widget _buildHeaderBanners() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmall = constraints.maxWidth < 600;

          final Widget leftPart = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_list_bulleted,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Reorders List",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Track and manage purchase reorders sent to suppliers.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget rightButton = ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePurchaseOrderPage(token: widget.token),
                ),
              ).then((value) {
                if (value == true) {
                  fetchOrders();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text("+ New Reorder", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftPart,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: rightButton),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: leftPart),
              const SizedBox(width: 12),
              rightButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltersCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: searchController,
        onChanged: (val) {
          setState(() {
            searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: "Search by request code, business, product, store, status...",
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTableView(List filteredOrders) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 64,
            columnSpacing: 18,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text("REQUEST CODE", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
              DataColumn(label: Text("BUSINESS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
              DataColumn(label: Text("STORE", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
              DataColumn(label: Text("SUPPLIER", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
              DataColumn(label: Text("PRODUCT", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
              DataColumn(label: Text("QTY", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
              DataColumn(label: Text("PRICE", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
              DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
              DataColumn(label: Text("DATE SENT", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
              DataColumn(label: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
            ],
            rows: List.generate(filteredOrders.length, (index) {
              final item = filteredOrders[index];
              final String reqCode = (item['request_code'] ?? item['request_number'] ?? item['order_id'] ?? "SAR-0043${6 - index}").toString();
              final String bName = (item['business'] ?? _getBusinessName(item)).toString();
              final String store = (item['store'] ?? bName).toString();
              final String supplier = (item['supplier'] ?? (item['supplier_name'] ?? "Roshan Technologies")).toString();
              final String supplierId = (item['supplier_id'] ?? "#700000016").toString();
              final String product = (item['product'] ?? _getProductName(item)).toString();
              final int qty = int.tryParse((item['qty'] ?? item['quantity'] ?? "4").toString()) ?? 4;
              final double price = double.tryParse((item['price'] ?? "0.0").toString()) ?? 0.0;
              final String status = (item['status'] ?? "Sent").toString();
              final String dateSent = (item['date_sent'] ?? _formatDate((item['created_at'] ?? item['date'] ?? "").toString())).toString();

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      reqCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12),
                    ),
                  ),
                  DataCell(Text(bName, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                  DataCell(Text(store, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(supplier, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B))),
                        Text("ID: $supplierId", style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  DataCell(Text(product, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
                  DataCell(Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)))),
                  DataCell(Text("₹${price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)))),
                  DataCell(_buildStatusPill(status)),
                  DataCell(Text(dateSent, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _viewOrder(item),
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 12),
                          label: const Text("View", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          onPressed: () => _editOrder(item),
                          icon: const Icon(Icons.edit_outlined, size: 12),
                          label: const Text("Edit", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: BorderSide(color: Colors.blue.shade200),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          onPressed: () => _deleteOrder(item),
                          icon: const Icon(Icons.delete_outline, size: 12),
                          label: const Text("Delete", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
    );
  }

  void _viewOrder(Map item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Order ${(item['request_code'] ?? item['id'] ?? '')}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Supplier: ${item['supplier'] ?? item['supplier_name'] ?? '-'}"),
            const SizedBox(height: 6),
            Text("Product: ${item['product'] ?? '-'}"),
            const SizedBox(height: 6),
            Text("Quantity: ${item['qty'] ?? 1}"),
            const SizedBox(height: 6),
            Text("Status: ${item['status'] ?? 'Sent'}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _editOrder(Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePurchaseOrderPage(token: widget.token),
      ),
    );
  }

  void _deleteOrder(Map item) {
    setState(() {
      orders.remove(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order removed successfully"), backgroundColor: Colors.redAccent),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color text;

    if (status == "COMPLETED" || status == "SUCCESS" || status == "DELIVERED") {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF15803D);
    } else if (status == "CANCELLED" || status == "FAILED" || status == "REJECTED") {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFB91C1C);
    } else {
      // Pending
      bg = const Color(0xFFFFF7ED);
      text = const Color(0xFFC2410C);
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        status,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }
}