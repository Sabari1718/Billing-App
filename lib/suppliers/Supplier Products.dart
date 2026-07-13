import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

// Shim to support console.log/error
class _Console {
  void log(Object? message) => debugPrint(message?.toString());
  void error(Object? message) => debugPrint("ERROR: ${message?.toString()}");
}
final console = _Console();

class SupplierProductsPage extends StatefulWidget {
  final String token;

  const SupplierProductsPage({super.key, required this.token});

  @override
  State<SupplierProductsPage> createState() => _SupplierProductsPageState();
}

class _SupplierProductsPageState extends State<SupplierProductsPage> {
  List products = [];
  List allProducts = [];
  bool isLoading = true;
  String selectedTab = "ALL"; // ALL or PERSONAL
  String selectedStock = "All Stock Levels";
  
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchSupplierProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------
  // API CALLS
  // ---------------------------------------------------

  Future<void> fetchSupplierProducts() async {
    setState(() => isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final bId = prefs.get("business_id")?.toString() ?? "";
    final uId = prefs.getString("user_main_id") ?? "";
    final role = prefs.getString("role")?.toLowerCase() ?? "";

    String baseUrl = "https://billing.srivagroups.in/api/supplierProduct";
    String url = selectedTab == "ALL" ? baseUrl : "$baseUrl/my-products";
    
    // 🔥 Apply role-based filtering
    if (role == "supplier" || role == "partner") {
      url += (url.contains("?") ? "&" : "?") + "business_id=$bId&user_main_id=$uId";
    } else if (role == "propagator" || role == "propagater" || role == "admin") {
      // Propagator sees everything
      AppLogger.info("Propagator role: Loading all supplier products");
    } else if (bId.isNotEmpty) {
      url += (url.contains("?") ? "&" : "?") + "business_id=$bId";
    }

    AppLogger.info("Fetching supplier products with URL: $url");
    
    final headers = {
      "Authorization": "Bearer ${widget.token}",
      "Accept": "application/json",
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print("STATUS => ${response.statusCode}");
      print("BODY => ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = (data is Map && data.containsKey('data')) ? data['data'] : data;

        setState(() {
          allProducts = list;
          products = list;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("ERROR => $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> searchBusinessCentral(String query) async {
    if (query.isEmpty) {
      fetchSupplierProducts();
      return;
    }

    setState(() => isSearching = true);
    final prefs = await SharedPreferences.getInstance();
    final bId = prefs.get("business_id")?.toString() ?? "";
    final uId = prefs.getString("user_main_id") ?? "";
    final role = prefs.getString("role")?.toLowerCase() ?? "";

    String url = "https://billing.srivagroups.in/api/customer/businesscentral?search=$query";
    
    if (role == "supplier" || role == "partner") {
      url += "&business_id=$bId&user_main_id=$uId";
    } else if (role != "propagator" && role != "propagater" && role != "admin") {
      url += "&business_id=$bId";
    }
    
    print("==================================================");
    print("[SEARCH BUSINESS CENTRAL]");
    print("API => $url");
    print("QUERY => $query");
    print("==================================================");

    final headers = {
      "Authorization": "Bearer ${widget.token}",
      "Accept": "application/json",
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      print("STATUS => ${response.statusCode}");
      print("BODY => ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = (data is Map && data.containsKey('data')) ? data['data'] : (data is List ? data : []);
        setState(() {
          products = list;
          isSearching = false;
        });
      } else {
        setState(() => isSearching = false);
      }
    } catch (e) {
      print("SEARCH ERROR => $e");
      setState(() => isSearching = false);
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchBusinessCentral(query);
    });
  }

  // ---------------------------------------------------
  // FILTERS
  // ---------------------------------------------------

  void filterByStock(String value) {
    print("FILTER STOCK STATUS => $value");
    setState(() {
      selectedStock = value;
      if (value == "All Stock Levels") {
        products = allProducts;
      } else {
        products = allProducts.where((item) {
          if (value == "Order Based") return item['stock_status'] == "order_based";
          
          int stock = item['stock'] ?? 0;
          if (value == "In Stock") return stock > 10;
          if (value == "Low Stock") return stock > 0 && stock <= 10;
          if (value == "Out of Stock") return stock == 0;
          return true;
        }).toList();
      }
    });
    print("FILTER => $value | COUNT => ${products.length}");
  }

  // ---------------------------------------------------
  // UI WIDGETS
  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Supplier Products",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            "Manage and map products to your suppliers efficiently.",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildTabButton("ALL"),
              const SizedBox(width: 8),
              _buildTabButton("PERSONAL"),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddSupplierProductScreen(token: widget.token))),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("ADD NEW PRODUCT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab) {
    bool isSelected = selectedTab == tab;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => selectedTab = tab);
          fetchSupplierProducts();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300),
        ),
        child: Text(
          tab,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search products...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: isSearching ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))) : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown("All Categories", ["All Categories"]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStockDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String value, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (val) {},
      ),
    );
  }

  Widget _buildStockDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: selectedStock,
        isExpanded: true,
        underline: const SizedBox(),
        items: ["All Stock Levels", "In Stock", "Low Stock", "Out of Stock", "Order Based"]
            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
            .toList(),
        onChanged: (val) {
          if (val != null) filterByStock(val);
        },
      ),
    );
  }

  Widget _buildProductList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No products found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 800) {
        return _buildDesktopTable();
      } else {
        return _buildMobileList();
      }
    });
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item['product_name']?.toString() ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _buildStatusBadge(item['status']?.toString() ?? 'Pending'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['supplier_name']?.toString() ?? 'Unknown Supplier', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("UNIT PRICE", style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("₹${item['unit_price']?.toString() ?? '0'}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("DAYS", style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("${item['days'] ?? '0'} Days", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text("PRODUCT NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("SUPPLIER", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("UNIT PRICE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("STATUS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("DAYS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("ACTIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
          rows: products.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['product_name']?.toString() ?? 'N/A')),
              DataCell(Text(item['supplier_name']?.toString() ?? 'N/A')),
              DataCell(Text("₹${item['unit_price']?.toString() ?? '0'}")),
              DataCell(_buildStatusBadge(item['status']?.toString() ?? 'Pending')),
              DataCell(Text("${item['days'] ?? '0'} Days")),
              DataCell(Row(children: [IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}), IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () {})])),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String s = status.toLowerCase();
    Color color = Colors.orange; // Default Pending
    
    if (s == "verified" || s == "in_stock" || s == "in stock") {
      color = Colors.green;
    } else if (s == "out_of_stock" || s == "out of stock") {
      color = Colors.red;
    } else if (s == "order_based" || s == "order based") {
      color = Colors.indigo;
    } else if (s == "discontinued") {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ---------------------------------------------------
// ADD NEW PRODUCT SCREEN
// ---------------------------------------------------

class AddSupplierProductScreen extends StatefulWidget {
  final String token;
  const AddSupplierProductScreen({super.key, required this.token});

  @override
  State<AddSupplierProductScreen> createState() => _AddSupplierProductScreenState();
}

class _AddSupplierProductScreenState extends State<AddSupplierProductScreen> {
  String mappingType = "PRODUCT"; // PRODUCT or CATEGORY
  final TextEditingController supplierProductCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();
  final TextEditingController costPriceCtrl = TextEditingController();
  
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> addedItems = [];
  List<Map<String, dynamic>> variants = [];
  Map<String, dynamic>? selectedVariant;
  bool isSearching = false;
  bool _isLoadingVariants = false;
  bool isSaving = false;
  Map<String, dynamic>? selectedItem;

  // Lead Time State
  bool isSameDay = false;
  final TextEditingController leadDaysCtrl = TextEditingController(text: "1");
  String selectedLeadType = "Day";

  Timer? _debounce;

  @override
  void dispose() {
    supplierProductCtrl.dispose();
    searchCtrl.dispose();
    costPriceCtrl.dispose();
    leadDaysCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchVariants();
  }

  Future<void> fetchVariants() async {
    setState(() => _isLoadingVariants = true);
    const url = "https://billing.srivagroups.in/api/variant-master";
    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json"
      });
      console.log("VARIANT API => ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is Map && data['data'] != null) ? data['data'] as List : (data is List ? data : []);
        setState(() {
          variants = list.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      console.error("VARIANT FETCH ERR => $e");
    } finally {
      if (mounted) setState(() => _isLoadingVariants = false);
    }
  }

  void onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchProducts(val);
    });
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) return;
    setState(() => isSearching = true);
    
    final prefs = await SharedPreferences.getInstance();
    final bId = prefs.get("business_id")?.toString() ?? "";
    final uId = prefs.getString("user_main_id") ?? "";
    final role = prefs.getString("role")?.toLowerCase() ?? "";

    String url = "https://billing.srivagroups.in/api/products?search=$query";
    
    if (role == "supplier" || role == "partner") {
      url += "&business_id=$bId&user_main_id=$uId";
    } else if (role != "propagator" && role != "propagater" && role != "admin") {
      url += "&business_id=$bId";
    }
    final headers = {"Authorization": "Bearer ${widget.token}", "Accept": "application/json"};

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = (data is Map && data.containsKey('data')) ? data['data'] : (data is List ? data : []);
        setState(() {
          searchResults = List<Map<String, dynamic>>.from(list);
          isSearching = false;
        });
      } else {
        setState(() => isSearching = false);
      }
    } catch (e) {
      print("SEARCH ERR => $e");
      setState(() => isSearching = false);
    }
  }

  void addItem() {
    if (selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a product first"), backgroundColor: Colors.red));
      return;
    }
    if (supplierProductCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Supplier Product is required"), backgroundColor: Colors.red));
      return;
    }
    if (selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select variant"), backgroundColor: Colors.red));
      return;
    }
    if (costPriceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cost Price is required"), backgroundColor: Colors.red));
      return;
    }
    if (selectedStockStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select stock status"), backgroundColor: Colors.red));
      return;
    }

    // Duplicate Check
    bool exists = addedItems.any((it) => it['product_id'] == selectedItem!['id'] && it['variant_id'] == selectedVariant!['id']);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("This product and variant is already added"), backgroundColor: Colors.orange));
      return;
    }
    
    setState(() {
      String leadDays = isSameDay ? "0" : leadDaysCtrl.text;
      
      addedItems.add({
        "product_id": selectedItem!["id"],
        "variant_id": selectedVariant!["id"],
        "variant_name": selectedVariant!["name"],
        "supplier_product": supplierProductCtrl.text.trim(),
        "name": selectedItem!["name"] ?? selectedItem!["product_name"] ?? "Unknown",
        "cost_price": costPriceCtrl.text,
        "stock_status": selectedStockStatus,
        "lead_days": leadDays,
        "raw_item": selectedItem, 
      });

      // Clear fields
      selectedItem = null;
      selectedVariant = null;
      selectedStockStatus = null;
      isSameDay = false;
      leadDaysCtrl.text = "1";
      selectedLeadType = "Day";
      searchCtrl.clear();
      costPriceCtrl.clear();
      supplierProductCtrl.clear();
      searchResults = [];
    });
  }

  void removeItem(int index) {
    setState(() => addedItems.removeAt(index));
  }

  Future<void> saveSupplierProducts() async {
    if (addedItems.isEmpty) return;

    setState(() => isSaving = true);
    final url = "https://billing.srivagroups.in/api/supplierProduct";
    final headers = {
      "Authorization": "Bearer ${widget.token}",
      "Accept": "application/json",
      "Content-Type": "application/json"
    };

    final body = {
      "data": addedItems.map((item) {
        String uiStatus = item["stock_status"] ?? "In Stock";
        String apiStatus = uiStatus;
        if (uiStatus == "In Stock") apiStatus = "in_stock";
        else if (uiStatus == "Out of Stock") apiStatus = "out_of_stock";
        else if (uiStatus == "Discontinued") apiStatus = "discontinued";
        else if (uiStatus == "Order Based") apiStatus = "order_based";

        return {
          "product_id": item["product_id"],
          "variant_id": item["variant_id"],
          "supplier_product": item["supplier_product"],
          "cost_price": double.tryParse(item["cost_price"].toString()) ?? 0,
          "stock_status": apiStatus,
          "lead_days": item["lead_days"],
        };
      }).toList()
    };

    print("==================================================");
    print("SUPPLIER FIELD REMOVED");
    if (addedItems.isNotEmpty) {
      final first = addedItems[0];
      print("PRODUCT ID => ${first['product_id']}");
      print("VARIANT ID => ${first['variant_id']}");
    }
    print("PAYLOAD => ${jsonEncode(body)}");
    print("==================================================");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print("RESPONSE => ${response.body}");
      print("STATUS => ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved successfully")));
        Navigator.pop(context);
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: ${err['message'] ?? response.statusCode}")));
      }
    } catch (e) {
      print("SAVE ERR => $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("An error occurred")));
    } finally {
      setState(() => isSaving = false);
    }
  }

  String? selectedStockStatus;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Supplier-Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (isSaving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: saveSupplierProducts,
              child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMappingSection(),
            const SizedBox(height: 24),
            const Text("ADDED ITEMS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            _buildAddedItemsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PRODUCT MAPPING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildToggleBtn("PRODUCT"),
              const SizedBox(width: 12),
              _buildToggleBtn("CATEGORY"),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 20),
          _buildVariantDropdown(),
          const SizedBox(height: 20),
          _buildInputRow("Supplier Product", supplierProductCtrl, hint: "Enter supplier's product name/code"),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            bool isSmall = constraints.maxWidth < 500;
            return Column(
              children: [
                if (isSmall) ...[
                  _buildInputRow("Cost Price", costPriceCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildDropdownRow("Stock Status", selectedStockStatus, ["In Stock", "Out of Stock", "Discontinued", "Order Based"], (val) => setState(() => selectedStockStatus = val)),
                ] else Row(
                  children: [
                    Expanded(child: _buildInputRow("Cost Price", costPriceCtrl, keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdownRow("Stock Status", selectedStockStatus, ["In Stock", "Out of Stock", "Discontinued", "Order Based"], (val) => setState(() => selectedStockStatus = val))),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildLeadTimeSection(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("ADD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LEAD TIME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Row(
          children: [
            // Same Day Button
            GestureDetector(
              onTap: () {
                setState(() {
                  isSameDay = !isSameDay;
                  if (isSameDay) {
                    leadDaysCtrl.text = "0";
                    selectedLeadType = "Day";
                  } else {
                    leadDaysCtrl.text = "1";
                  }
                });
                print("LEAD TIME TYPE => $selectedLeadType");
                print("LEAD DAYS => ${leadDaysCtrl.text}");
                print("SAME DAY => $isSameDay");
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSameDay ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSameDay ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  "Same Day",
                  style: TextStyle(
                    color: isSameDay ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Number Input
            Expanded(
              flex: 2,
              child: TextField(
                controller: leadDaysCtrl,
                keyboardType: TextInputType.number,
                enabled: !isSameDay,
                onChanged: (val) {
                  print("LEAD TIME TYPE => $selectedLeadType");
                  print("LEAD DAYS => $val");
                  print("SAME DAY => $isSameDay");
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isSameDay ? const Color(0xFFF1F5F9).withOpacity(0.5) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Dropdown
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedLeadType,
                    isExpanded: true,
                    items: ["Day", "Week", "Month", "Year"].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: isSameDay ? null : (val) {
                      if (val != null) {
                        setState(() => selectedLeadType = val);
                        print("LEAD TIME TYPE => $selectedLeadType");
                        print("LEAD DAYS => ${leadDaysCtrl.text}");
                        print("SAME DAY => $isSameDay");
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownRow(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String type) {
    bool isSelected = mappingType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => mappingType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("VARIANT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              hint: Text(_isLoadingVariants ? "Loading variants..." : "Select Variant"),
              value: selectedVariant,
              items: variants.map((v) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: v,
                  child: Text(v['name'] ?? 'N/A'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedVariant = val);
                console.log("SELECTED VARIANT => ${val?['id']} - ${val?['name']}");
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Search $mappingType", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextField(
          controller: searchCtrl,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: "Enter name...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: selectedItem != null ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0))),
          ),
        ),
        if (isSearching) const LinearProgressIndicator(),
        if (searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, idx) {
                final item = searchResults[idx];
                return ListTile(
                  title: Text(item['name'] ?? item['product_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item['code'] ?? item['sku'] ?? ''),
                  onTap: () {
                    setState(() {
                      selectedItem = item;
                      searchCtrl.text = item['name'] ?? item['product_name'] ?? 'Unknown';
                      searchResults = [];
                    });
                  },
                );
              },
            ),
          )
        else if (searchCtrl.text.isNotEmpty && !isSearching && searchResults.isEmpty && selectedItem == null)
          const Padding(padding: EdgeInsets.all(12), child: Text("No products found", style: TextStyle(color: Colors.grey))),
      ],
    );
  }

  Widget _buildInputRow(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAddedItemsList() {
    if (addedItems.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.add_shopping_cart_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text("No products mapped yet", style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: addedItems.length,
      itemBuilder: (context, index) {
        final item = addedItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F46E5), size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("Variant: ${item['variant_name']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text("Supplier Ref: ${item['supplier_product']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => removeItem(index), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _itemSummaryItem("COST PRICE", "₹${item['cost_price']}"),
                    _itemSummaryItem("STOCK", item['stock_status']),
                    _itemSummaryItem("LEAD TIME", "${item['lead_days']} Days"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
      ],
    );
  }
}