part of 'Supplier Products.dart';

mixin SupplierProductsLogic on State<SupplierProductsPage> {
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
      "Authorization": "Bearer \${widget.token}",
      "Accept": "application/json",
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print("STATUS => \${response.statusCode}");
      print("BODY => \${response.body}");

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
      print("ERROR => \$e");
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

    String url = "https://billing.srivagroups.in/api/customer/businesscentral?search=\$query";
    
    if (role == "supplier" || role == "partner") {
      url += "&business_id=$bId&user_main_id=$uId";
    } else if (role != "propagator" && role != "propagater" && role != "admin") {
      url += "&business_id=$bId";
    }
    
    print("==================================================");
    print("[SEARCH BUSINESS CENTRAL]");
    print("API => \$url");
    print("QUERY => \$query");
    print("==================================================");

    final headers = {
      "Authorization": "Bearer \${widget.token}",
      "Accept": "application/json",
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      print("STATUS => \${response.statusCode}");
      print("BODY => \${response.body}");

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
      print("SEARCH ERROR => \$e");
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
    print("FILTER STOCK STATUS => \$value");
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
    print("FILTER => \$value | COUNT => \${products.length}");
  }
}
