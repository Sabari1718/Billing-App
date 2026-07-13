import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRoleAndFetch();
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

    // 🔥 Apply role-based filtering
    final prefs = await SharedPreferences.getInstance();
    if (role == "supplier" || role == "partner") {
      final userMainId = prefs.getString("user_main_id") ?? "";
      url += "?business_id=$businessId&user_main_id=$userMainId";
    } else if (role == "propagator" || role == "propagater" || role == "admin") {
      // Propagator role: Master/Admin, loads everything
      AppLogger.info("Propagator role: Loading all records");
    } else if (businessId != null) {
      url += "?business_id=$businessId";
    }

    AppLogger.info("Fetching supplier orders for tab: $currentTab | Role: $role");

    final headers = {
      "Authorization": "Bearer ${widget.token}",
      "Accept": "application/json",
    };

    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      AppLogger.api("GET", url, response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List list;

        if (data is Map && data.containsKey('data')) {
          list = data['data'];
        } else {
          list = data;
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
    setState(() {
      currentTab = tab;
    });
    fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Supplier Orders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            /// 🔥 SENT / RECEIVED BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _tabButton("Sent", "sent"),
                const SizedBox(width: 10),
                _tabButton("Received", "received"),
              ],
            ),

            const SizedBox(height: 12),

            /// 🔍 SEARCH + FILTER
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search by Order ID or Supplier...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: _statusDropdown(),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 📋 LIST
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                  ? const Center(child: Text("No orders found"))
                  : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final item = orders[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        item['product_name']?.toString() ??
                            'No Product',
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text("Order ID: ${item['order_id'] ?? '-'}"),
                          Text("Business: ${item['business_name'] ?? '-'}"),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Text(
                            "₹${item['amount'] ?? '0'}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item['status'] ?? '',
                            style:
                            const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  /// 🔘 TAB BUTTON
  Widget _tabButton(String text, String value) {
    final isActive = currentTab == value;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
        isActive ? Colors.deepPurple : Colors.grey.shade300,
      ),
      onPressed: () => switchTab(value),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  /// 🔽 STATUS DROPDOWN
  Widget _statusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: "All Status",
        underline: const SizedBox(),
        items: ["All Status", "Pending", "Completed", "Cancelled"]
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (val) {},
      ),
    );
  }
}