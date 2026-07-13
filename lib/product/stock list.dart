import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  // API State
  List stocks = [];
  List suppliers = [];
  List products = [];
  bool isLoading = true;

  // Pagination & Filtering State
  int currentPage = 1;
  int currentLimit = 10;
  String searchQuery = "";
  String? selectedSupplierFilter;
  String? selectedProductFilter;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  String role = "business";
  String userName = "";

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString("role")?.toLowerCase() ?? "propagater";
    userName = prefs.getString("user_name") ?? "";

    if (prefs.getString("role") == null) {
      final userJson = prefs.getString("user");
      if (userJson != null) {
        try {
          final Map<String, dynamic> user = json.decode(userJson);
          String rawRole = user['role']?.toString().toLowerCase() ?? "business";
          role = (rawRole == "business") ? "propagater" : rawRole;
          userName = user['name']?.toString() ?? "";
        } catch (e) {
          debugPrint("Error parsing user json in stock list: $e");
        }
      }
    }
    await fetchStocks();
  }

// 🔥 API: GET STOCKS
  Future<void> fetchStocks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // FIX: Use 'token' to match other working screens
      final token = prefs.getString("token") ?? "";
      final businessId = prefs.get("business_id")?.toString() ?? "";

      String url = "https://billing.srivagroups.in/api/productAllocation";
      
      if (role == "supplier" || role == "partner") {
        final userMainId = prefs.getString("user_main_id") ?? "";
        url += "?business_id=$businessId&user_main_id=$userMainId";
      } else if (role == "propagator" || role == "propagater" || role == "admin") {
        // Master role: no filtering
        AppLogger.info("Propagator role: Loading all stocks");
      } else {
        url += "?business_id=$businessId";
      }

      AppLogger.info("Fetching stocks with URL: $url");

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );

      AppLogger.api("GET", url, res.statusCode);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> listData = [];

        if (decoded['data'] is List) {
          for (var group in decoded['data']) {
            final id = group['id'];
            final supplierName = group['supplier_name'] ?? group['supplier']?['name'] ?? "Unknown Supplier";
            
            // API already filtered data by user_main_id for non-propagators

            final categories = group['Categories'];
            
            if (categories == null) continue;

            for (var type in ['primary', 'secondary']) {
              final catList = categories[type] ?? [];

              for (var cat in catList) {
                for (var brand in cat['Brand'] ?? []) {
                  for (var product in brand['Products'] ?? []) {
                    listData.add({
                      "id": id,
                      "product_name": product['name'] ?? "Unnamed Product",
                      "supplier_name": supplierName,
                      "min_qty": product['Qty']?['min'] ?? 0,
                      "max_qty": product['Qty']?['max'] ?? 0,
                    });
                  }
                }
              }
            }
          }
        }

        AppLogger.success("Found ${listData.length} stock allocations");

        if (mounted) {
          setState(() {
            stocks = listData;
            isLoading = false;
          });
        }
      } else {
        AppLogger.api("GET", url, res.statusCode, isError: true);
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      AppLogger.error("fetchStocks error", e);
      if (mounted) setState(() => isLoading = false);
    }
  }




// 🔥 GET PRODUCTS
  Future<void> fetchProductsForSupplier(String supplierId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawToken = prefs.get("auth_token");
      final token = rawToken?.toString() ?? "";

      final url =
          "https://billing.srivagroups.in/api/products?supplier_id=$supplierId";

      AppLogger.info("Fetching products for supplier: $supplierId");

      final res = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      AppLogger.api("GET", url, res.statusCode);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        var data = decoded['data'];
        List parsedProducts = [];
        if (data is List) {
          parsedProducts = data;
        } else if (data is Map && data['data'] is List) {
          parsedProducts = data['data'];
        }

        if (mounted) {
          setState(() {
            products = parsedProducts;
          });
        }
      } else {
        AppLogger.api("GET", url, res.statusCode, isError: true);
      }
    } catch (e, stack) {
      AppLogger.error("fetchProductsForSupplier error", e, stack);
    }
  }

// 🔥 DELETE
  Future<void> deleteStock(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.get("auth_token")?.toString() ?? "";

      // ✅ FIX: Use correct endpoint for deletion
      final url = "https://billing.srivagroups.in/api/productAllocation/$id";

      final res = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      AppLogger.api("DELETE", url, res.statusCode);

      if (res.statusCode == 200 || res.statusCode == 204) {
        // optional refresh (background)
        fetchStocks();
      } else {
        AppLogger.api("DELETE", url, res.statusCode, body: res.body, isError: true);
      }
    } catch (e, stack) {
      AppLogger.error("deleteStock error", e, stack);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock List"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchStocks,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildStockList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
      child: Column(
        children: [
          TextField(
            onChanged: (val) { searchQuery = val; fetchStocks(); },
            decoration: InputDecoration(
              hintText: "Search stock...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedSupplierFilter,
                  hint: const Text("Select Supplier"),
                  decoration: const InputDecoration(labelText: "Supplier", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text("All Suppliers")),
                    ...suppliers.map((s) => DropdownMenuItem(
                      value: s['id'].toString(),
                      child: Text(s['supplier_name'] ?? s['name'] ?? "No Name", overflow: TextOverflow.ellipsis)
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedSupplierFilter = val;
                      selectedProductFilter = null;
                    });
                    fetchStocks();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<int>(
                  value: currentLimit,
                  decoration: const InputDecoration(labelText: "Limit", border: OutlineInputBorder()),
                  items: [10, 20, 30, 40, 50].map((l) => DropdownMenuItem(value: l, child: Text("$l"))).toList(),
                  onChanged: (val) { setState(() => currentLimit = val!); fetchStocks(); },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    if (stocks.isEmpty) {
      return Center(
        child: Text(
          selectedSupplierFilter != null
            ? "No products for selected supplier"
            : "No products available",
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        final stock = stocks[index];
        final supplierName = stock['supplier_name'] ?? "Unknown Supplier";
        final minQty = stock['min_qty'] ?? 0;
        final maxQty = stock['max_qty'] ?? 0;

        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              title: Text(
                stock['product_name'] ?? "Unnamed Product",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplierName,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Min: $minQty | Max: $maxQty",
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(stock),
              ),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
          ],
        );
      },
    );
  }


  void _confirmDelete(dynamic stock) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Stock?"),
        content: Text("Are you sure you want to delete stock for ${stock['product_name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); deleteStock(stock['id']); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete")),
        ],
      ),
    );
  }
}

