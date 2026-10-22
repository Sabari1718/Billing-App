part of 'Supplier Products.dart';

mixin AddSupplierProductLogic on State<AddSupplierProductScreen> {
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
  String? selectedStockStatus;

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
        "Authorization": "Bearer \${widget.token}",
        "Accept": "application/json"
      });
      console.log("VARIANT API => \${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data is Map && data['data'] != null) ? data['data'] as List : (data is List ? data : []);
        setState(() {
          variants = list.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      console.error("VARIANT FETCH ERR => \$e");
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

    String url = "https://billing.srivagroups.in/api/products?search=\$query";
    
    if (role == "supplier" || role == "partner") {
      url += "&business_id=$bId&user_main_id=$uId";
    } else if (role != "propagator" && role != "propagater" && role != "admin") {
      url += "&business_id=$bId";
    }
    final headers = {"Authorization": "Bearer \${widget.token}", "Accept": "application/json"};

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
      print("SEARCH ERR => \$e");
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
      "Authorization": "Bearer \${widget.token}",
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
      print("PRODUCT ID => \${first['product_id']}");
      print("VARIANT ID => \${first['variant_id']}");
    }
    print("PAYLOAD => \${jsonEncode(body)}");
    print("==================================================");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print("RESPONSE => \${response.body}");
      print("STATUS => \${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved successfully")));
        Navigator.pop(context);
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: \${err['message'] ?? response.statusCode}")));
      }
    } catch (e) {
      print("SAVE ERR => \$e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("An error occurred")));
    } finally {
      setState(() => isSaving = false);
    }
  }
}
