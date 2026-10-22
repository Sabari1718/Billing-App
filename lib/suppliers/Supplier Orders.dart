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

        setState(() {
          orders = list;
          isLoading = false;
        });
      } else {
        AppLogger.api("GET", url, response.statusCode, isError: true);
        setState(() => isLoading = false);
      }
    } catch (e) {
      AppLogger.error("fetchOrders error", e);
      setState(() => isLoading = false);
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
          "Supplier Orders",
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

              // 4. Data Content (Responsive Table or Card List)
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : isMobile
                            ? _buildMobileCardList(filteredOrders)
                            : _buildDesktopTableView(filteredOrders),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanners() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final bool sideBySide = w > 550;

        final Widget tabSelector = Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tabItem("Sent", "sent"),
              _tabItem("Received", "received"),
            ],
          ),
        );

        final Widget addOrderButton = ElevatedButton.icon(
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
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 0,
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add New Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        );

        if (sideBySide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTab == "sent" ? "Sent Purchase Orders" : "Received Purchase Orders",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  tabSelector,
                  const SizedBox(width: 12),
                  addOrderButton,
                ],
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: tabSelector),
              const SizedBox(height: 12),
              addOrderButton,
            ],
          );
        }
      },
    );
  }

  Widget _tabItem(String text, String value) {
    final bool isActive = currentTab == value;
    return GestureDetector(
      onTap: () => switchTab(value),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? AppColors.primary : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final bool sideBySide = w > 500;

          final Widget textField = TextField(
            controller: searchController,
            onChanged: (val) {
              setState(() {
                searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: "Search by Order ID or Supplier...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          );

          final Widget statusDropdown = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedStatus,
                icon: Icon(Icons.filter_list, color: Colors.grey.shade600, size: 18),
                items: ["All Status", "Pending", "Completed", "Cancelled"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStatus = newValue;
                    });
                  }
                },
              ),
            ),
          );

          if (sideBySide) {
            return Row(
              children: [
                Expanded(child: textField),
                const SizedBox(width: 12),
                statusDropdown,
              ],
            );
          } else {
            return Column(
              children: [
                textField,
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: statusDropdown),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No Orders Found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Text(
            "There are no orders matching your criteria.",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCardList(List filteredOrders) {
    return ListView.builder(
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final item = filteredOrders[index];
        final String orderId = (item['request_code'] ?? item['request_number'] ?? item['order_id'] ?? item['id'] ?? "-").toString();
        final String date = _formatDate((item['delivery_datetime'] ?? item['created_at'] ?? item['date'] ?? "").toString());
        final String bName = _getBusinessName(item);
        final String pName = _getProductName(item);
        final String variant = _getVariantBadge(item);
        final double amount = double.tryParse((item['total_amount'] ?? item['amount'] ?? item['total'] ?? "0").toString()) ?? 0.0;
        final String status = (item['status'] ?? "PENDING").toString().toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: Order ID & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      orderId,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  _buildStatusPill(status),
                ],
              ),
              const Divider(height: 20),
              
              // Body Details
              _buildMobileDetailRow(Icons.calendar_today_outlined, "Date", date),
              const SizedBox(height: 8),
              _buildMobileDetailRow(Icons.business_outlined, "Business", bName),
              const SizedBox(height: 8),
              _buildMobileProductRow(Icons.inventory_2_outlined, "Product", pName, variant),
              
              const Divider(height: 20),
              
              // Footer: Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(
                    "₹${amount.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _buildMobileProductRow(IconData icon, String label, String value, String badge) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.indigo, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        )
      ],
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
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          dataRowHeight: 68,
          columns: const [
            DataColumn(label: Text("S.NO", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
            DataColumn(label: Text("ORDER ID", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
            DataColumn(label: Text("DATE", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
            DataColumn(label: Text("BUSINESS NAME", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
            DataColumn(label: Text("PRODUCT NAME", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
            DataColumn(label: Text("AMOUNT", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
            DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
          ],
          rows: List.generate(filteredOrders.length, (index) {
            final item = filteredOrders[index];
            final String orderId = (item['request_code'] ?? item['request_number'] ?? item['order_id'] ?? item['id'] ?? "-").toString();
            final String date = _formatDate((item['delivery_datetime'] ?? item['created_at'] ?? item['date'] ?? "").toString());
            final String bName = _getBusinessName(item);
            final String pName = _getProductName(item);
            final String variant = _getVariantBadge(item);
            final double amount = double.tryParse((item['total_amount'] ?? item['amount'] ?? item['total'] ?? "0").toString()) ?? 0.0;
            final String status = (item['status'] ?? "PENDING").toString().toUpperCase();

            return DataRow(
              cells: [
                // S.NO
                DataCell(Text("${index + 1}", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold))),
                
                // ORDER ID (Badge)
                DataCell(
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      orderId,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                
                // DATE
                DataCell(Text(date, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF475569)))),
                
                // BUSINESS NAME (Icon + Name)
                DataCell(
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // PRODUCT NAME (Bold + Blue variant badge)
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          variant,
                          style: const TextStyle(color: Colors.indigo, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
                
                // AMOUNT
                DataCell(
                  Text(
                    "₹${amount.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
                
                // STATUS (Color Pill)
                DataCell(_buildStatusPill(status)),
              ],
            );
          }),
        ),
      ),
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