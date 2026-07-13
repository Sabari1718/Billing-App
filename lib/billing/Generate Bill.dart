import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomerRegisterWebView extends StatefulWidget {
  final String url;
  const CustomerRegisterWebView({super.key, required this.url});

  @override
  State<CustomerRegisterWebView> createState() => _CustomerRegisterWebViewState();
}

class _CustomerRegisterWebViewState extends State<CustomerRegisterWebView> {
  late final WebViewController _controller;
  bool _isPopped = false;

  void _safePop(bool result) {
    if (!mounted) return;
    if (!_isPopped) {
      _isPopped = true;
      Navigator.pop(context, result);
    }
  }

  bool _shouldPop(String url) {
    final cleanUrl = url.toLowerCase();
    if (cleanUrl == "https://user.jobes24x7.com/" || 
        cleanUrl == "https://user.jobes24x7.com" || 
        cleanUrl.startsWith("https://user.jobes24x7.com/home") ||
        cleanUrl.contains("dashboard") ||
        cleanUrl.contains("login") ||
        (!cleanUrl.contains("key=bill") && !cleanUrl.contains("otp") && !cleanUrl.contains("register") && !cleanUrl.contains("signup"))) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            final url = change.url;
            if (url != null) {
              print("WebView url changed: $url");
              if (_shouldPop(url)) {
                _safePop(true);
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            print("WebView navigating request: $url");
            if (_shouldPop(url)) {
              _safePop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Registration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _safePop(false),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class CustomerScreen extends StatefulWidget { 
  const CustomerScreen({super.key});

  @override
  _CustomerScreenState createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> with WidgetsBindingObserver {
  bool isUser = true;
  String verifyBy = "Mobile No";
  final TextEditingController _searchController = TextEditingController();
  List<Customer> results = [];
  Customer? selectedCustomer;
  bool loading = false;
  String? errorMessage;
  String selectedMainTab = "User"; // ✨ Added for top-level navigation
  String productSearchBy = "Name"; // ✨ For product search dropdown

  bool _isLaunchingRegistration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLaunchingRegistration) {
      _isLaunchingRegistration = false;
      checkRegistrationAfterReturn();
    }
  }

  Future<void> checkRegistrationAfterReturn() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      loading = true;
      errorMessage = null;
      _showDropdown = true;
    });

    try {
      final data = await fetchCustomers(query);
      if (!mounted) return;

      setState(() {
        results = data;
        loading = false;
        _showDropdown = true;

        if (data.isEmpty) {
          errorMessage = "No customer found with '$query'. Registration may not be completed.";
        } else {
          if (data.length == 1) {
            selectedCustomer = data.first;
            _showDropdown = false;
            if (verifyBy == "GST No") {
              _searchController.text = selectedCustomer!.gst;
            } else if (verifyBy == "PAN No") {
              _searchController.text = selectedCustomer!.pan;
            } else {
              _searchController.text = selectedCustomer!.mobile;
            }
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        results = [];
        errorMessage = "Failed to load customer. Error: $e";
        _showDropdown = true;
      });
    }
  }

  void _launchCustomerRegistration() async {
    final query = _searchController.text.trim();
    String urlStr = "https://user.jobes24x7.com/?key=bill";
    if (query.isNotEmpty) {
      if (verifyBy == "Mobile No") {
        urlStr += "&mobile=$query";
      } else if (verifyBy == "GST No") {
        urlStr += "&gst=$query";
      } else if (verifyBy == "PAN No") {
        urlStr += "&pan=$query";
      }
    }

    setState(() {
      _isLaunchingRegistration = true;
      errorMessage = null;
    });

    try {
      final bool? registered = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerRegisterWebView(url: urlStr),
        ),
      );
      if (registered == true) {
        checkRegistrationAfterReturn();
      } else {
        checkRegistrationAfterReturn();
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error launching page: $e";
      });
    } finally {
      setState(() {
        _isLaunchingRegistration = false;
      });
    }
  }

  Widget _buildAddNewCustomerButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [const Color(0xFF2563EB).withOpacity(0.05), const Color(0xFF1D4ED8).withOpacity(0.05)],
        ),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _launchCustomerRegistration,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Text(
                  "Add New Customer",
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // ✨ Product State
  List<ProductStock> productResults = [];
  ProductStock? selectedProduct;
  List<ProductStock> selectedBillItems = []; // ✨ To store multiple selected products
  bool productLoading = false;
  String? productErrorMessage;
  bool _showProductDropdown = false;
  final TextEditingController _productSearchController = TextEditingController();
  final LayerLink _productLayerLink = LayerLink();
  Timer? _debounce;
  bool _showDropdown = false;
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  // 🔍 Advanced Filter States
  String? filterCategoryGroup;
  String? filterCategory;
  String? filterBrand;
  String? filterGST;
  
  final TextEditingController filterProductNameController = TextEditingController();
  final TextEditingController filterHSNController = TextEditingController();
  final TextEditingController filterPriceMinController = TextEditingController();
  final TextEditingController filterPriceMaxController = TextEditingController();
  final TextEditingController filterStockMinController = TextEditingController();
  final TextEditingController filterStockMaxController = TextEditingController();

  // 💰 Billing Totals Controllers
  final TextEditingController taxController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController chargesController = TextEditingController();

  double itemTotal = 0.0;
  double payableTotal = 0.0;

  // ✨ Global Billing State
  String globalTaxType = "%";
  String globalDiscountType = "₹";
  double totalItemAmount = 0.0;
  double totalTaxAmount = 0.0;
  double totalDiscountAmount = 0.0;
  double totalAdditionalCharges = 0.0;
  double finalPayableAmount = 0.0;

  // ⚡ Additional Charges Integration State
  bool showAdditionalChargesDetails = false;
  int activeChargesTab = 0; // 0 = Price, 1 = Combo, 2 = Coupon, 3 = Discount
  bool loadingCharges = false;
  List<dynamic> fetchedPrices = [];
  List<dynamic> fetchedCombos = [];
  List<dynamic> fetchedCoupons = [];
  List<dynamic> fetchedDiscounts = [];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _debounce?.cancel();
    _searchFocusNode.dispose();
    
    // Dispose Filter Controllers
    filterProductNameController.dispose();
    filterHSNController.dispose();
    filterPriceMinController.dispose();
    filterPriceMaxController.dispose();
    filterStockMinController.dispose();
    filterStockMaxController.dispose();
    
    // Dispose Billing Controllers
    taxController.dispose();
    discountController.dispose();
    chargesController.dispose();
    
    super.dispose();
  }

// ✅ REPLACE YOUR ENTIRE searchCustomer() METHOD WITH THIS

  void searchCustomer(String value) {
    final query = value.trim();

    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    // ✅ SHOW FROM 1 CHARACTER
    if (query.isEmpty) {
      setState(() {
        results = [];
        loading = false;
        errorMessage = null;
        _showDropdown = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        loading = true;
        errorMessage = null;
        _showDropdown = true;
      });

      try {
        final data = await fetchCustomers(query);

        if (!mounted) return;

        setState(() {
          results = data;
          loading = false;
          _showDropdown = true;

          if (data.isEmpty) {
            errorMessage = "No customers found";
          } else {
            errorMessage = null;
          }
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          loading = false;
          results = [];
          errorMessage = "Failed to load customers";
          _showDropdown = true;
        });
      }
    });
  }

// ✅ REPLACE YOUR ENTIRE fetchCustomers() METHOD WITH THIS

  Future<List<Customer>> fetchCustomers(String search) async {
    try {
      final query = search.trim();

      // ✅ IMPORTANT FIX
      final bool isMobileSearch = verifyBy == "Mobile No";

      final String endpoint =
      (isUser || isMobileSearch)
          ? "usercentral"
          : "businesscentral";

      final prefs = await SharedPreferences.getInstance();
      final bId = prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";
      final r = prefs.getString("role")?.toLowerCase() ?? "";

      String url = "https://billing.srivagroups.in/api/customer/$endpoint?search=$query";
      
      if (r == "supplier" || r == "partner") {
        url += "&business_id=$bId&user_main_id=$uId";
      } else if (r == "propagator" || r == "propagater" || r == "admin") {
        // No filter
      } else if (bId.isNotEmpty) {
        url += "&business_id=$bId";
      }
      
      // ✅ TOKEN FIX
      final token =
          prefs.getString("auth_token") ??
              prefs.getString("token") ??
              "";

      print("==================================================");
      print("[CUSTOMER SEARCH REQUEST]");
      print("URL: $url");
      print("TOKEN: $token");
      print("==================================================");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("==================================================");
      print("[CUSTOMER SEARCH RESPONSE]");
      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");
      print("==================================================");

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = json.decode(response.body);

      List<dynamic> rawList = [];

      // ✅ HANDLE ALL RESPONSE TYPES
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded["data"] is List) {
          rawList = decoded["data"];
        } else if (decoded["data"] is Map<String, dynamic>) {
          final nested = decoded["data"];

          if (nested["data"] is List) {
            rawList = nested["data"];
          } else if (nested["customers"] is List) {
            rawList = nested["customers"];
          } else if (nested["list"] is List) {
            rawList = nested["list"];
          }
        } else if (decoded["customers"] is List) {
          rawList = decoded["customers"];
        } else if (decoded["results"] is List) {
          rawList = decoded["results"];
        } else if (decoded["list"] is List) {
          rawList = decoded["list"];
        }
      }

      // ✅ FINAL MAPPING FIX
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => Customer.fromJson(e))
          .where((customer) => customer.name.trim().isNotEmpty)
          .toList();
    } catch (e) {
      print("FETCH ERROR => $e");
      return [];
    }
  }

  // 🔥 PRODUCT SEARCH LOGIC
  void searchProduct(String value) {
    final query = value.trim();
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        productResults = [];
        _showProductDropdown = false;
        productLoading = false;
        productErrorMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        productLoading = true;
        productErrorMessage = null;
        _showProductDropdown = true;
      });

      try {
        final data = await fetchProductAllocations(query);
        if (!mounted) return;

        setState(() {
          productResults = data;
          productLoading = false;
          if (data.isEmpty) {
            productErrorMessage = "No products found";
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          productLoading = false;
          productErrorMessage = "Search failed";
        });
      }
    });
  }

  Future<List<ProductStock>> fetchProductAllocations(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final businessId = prefs.get("business_id")?.toString() ?? "";

      final r = prefs.getString("role")?.toLowerCase() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      // ✅ USE ONLY /api/stocks endpoint
      String url = "https://billing.srivagroups.in/api/stocks?search=$query";
      
      if (r == "supplier" || r == "partner") {
        url += "&business_id=$businessId&user_main_id=$uId";
      } else if (r == "propagator" || r == "propagater" || r == "admin") {
        // No filter
      } else if (businessId.isNotEmpty) {
        url += "&business_id=$businessId";
      }

      print("==================================================");
      print("[PRODUCT SEARCH REQUEST]");
      print("URL: $url");
      print("TOKEN: $token");
      print("==================================================");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("==================================================");
      print("[PRODUCT SEARCH RESPONSE]");
      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");
      print("==================================================");

      if (response.statusCode != 200) return [];

      final decoded = json.decode(response.body);
      List<ProductStock> list = [];

      dynamic data = decoded['data'] ?? decoded;
      List<dynamic> rawStocks = [];
      if (data is List) {
        rawStocks = data;
      } else if (data is Map && data['data'] is List) {
        rawStocks = data['data'];
      }

      for (final stock in rawStocks) {
        if (stock is! Map) continue;
        final String stockId = (stock['id'] ?? "").toString();
        final String productName = (stock['product_name'] ?? "").toString();
        final String supplierName = (stock['supplier']?['name'] ?? "").toString();
        final String category = (stock['category']?['name'] ?? "").toString();
        final String description = (stock['description'] ?? "").toString();
        
        final variants = stock['variants'] ?? [];
        for (final variant in variants) {
          if (variant is! Map) continue;
          final String recordId = (variant['id'] ?? "").toString();
          final String typeId = (variant['variant_id'] ?? "").toString();
          
          // ✅ Binding variant-specific Qty and Price
          final int vQty = int.tryParse((variant['qty'] ?? "0").toString()) ?? 0;
          final double vPrice = double.tryParse((variant['selling_price'] ?? "0").toString()) ?? 0;

          // ✅ Request Logic: Strictly row-specific based on current variant quantity
          final int totalQty = int.tryParse((variant['total_qty'] ?? variant['qty'] ?? "0").toString()) ?? 0;
          bool isReq = totalQty == 0;

          // ✅ Variant Mapping: 1=Original, 2=Import, 3=Complimentary (with dynamic fallback)
          String label = "";
          if (typeId == "1") {
            label = "Original";
          } else if (typeId == "2") {
            label = "Import";
          } else if (typeId == "3") {
            label = "Complimentary";
          } else if (variant['variant'] != null && variant['variant']['name'] != null) {
            label = variant['variant']['name'].toString();
          } else if (variant['name'] != null) {
            label = variant['name'].toString();
          } else {
            label = "Variant $typeId";
          }

          list.add(ProductStock(
            stockId: stockId,
            productId: (stock['product_id'] ?? "").toString(),
            variantId: recordId, // Use record primary key (e.g., 67)
            variantTypeId: typeId, // Use variant type (e.g., 2)
            productName: productName,
            supplierName: supplierName,
            category: category,
            variant: label,
            qty: vQty, 
            unitPrice: vPrice, 
            total: vQty * vPrice, 
            isRequest: isReq,
            description: description,
            sku: (variant['sku'] ?? "").toString(),
          ));
        }
      }

      // ✅ Search Priority Logic: startsWith FIRST, then contains based on selected productSearchBy
      final searchText = query.trim().toLowerCase();
      if (searchText.isNotEmpty) {
        List<ProductStock> startsWithList = [];
        List<ProductStock> containsList = [];

        for (final item in list) {
          String searchField = "";
          if (productSearchBy == "SKU") {
            searchField = item.sku.toLowerCase();
          } else if (productSearchBy == "Category") {
            searchField = item.category.toLowerCase();
          } else {
            searchField = item.productName.toLowerCase();
          }

          if (searchField.startsWith(searchText)) {
            startsWithList.add(item);
          } else if (searchField.contains(searchText)) {
            containsList.add(item);
          }
        }
        return [...startsWithList, ...containsList];
      }

      return list;
    } catch (e) {
      print("FETCH ERROR => $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchStockDetails(String stockId, String variantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";

      final url = "https://billing.srivagroups.in/api/stockTypes/by-stock?stock_id=$stockId";
      print("==================================================");
      print("[STOCK DETAILS REQUEST]");
      print("URL: $url");
      print("TOKEN: $token");
      print("==================================================");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("==================================================");
      print("[STOCK DETAILS RESPONSE]");
      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");
      print("==================================================");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // ✅ Correct Parsing: Access variants directly from response (or decoded['data'] if wrapped)
        final List variantsList = (decoded['variants'] ?? (decoded['data'] is List ? decoded['data'][0]['variants'] : decoded['data']?['variants']) ?? []);

        // ✅ Match using the unique RECORD ID (e.g., 67)
        final selectedVariant = variantsList.firstWhere(
          (v) => v['id'].toString() == variantId.toString(),
          orElse: () => null,
        );

        if (selectedVariant == null) {
          print("VARIANT ID $variantId NOT FOUND IN RESPONSE");
          return [];
        }

        final List stockTypes = selectedVariant['stock_types'] ?? [];
        return stockTypes;
      }
    } catch (e) {
      print("FETCH STOCK DETAILS ERROR => $e");
    }
    return [];
  }

  Future<void> fetchAdditionalChargesData() async {
    if (selectedBillItems.isEmpty) {
      setState(() {
        fetchedPrices = [];
        fetchedCombos = [];
        fetchedCoupons = [];
        fetchedDiscounts = [];
      });
      return;
    }
    
    setState(() {
      loadingCharges = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      final headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      };

      // Use the first item's productId
      final productId = selectedBillItems.first.productId;

      String buildUrl(String base) {
        List<String> params = [];
        if (productId.isNotEmpty) params.add("product_id=$productId");
        if (bId.isNotEmpty) params.add("business_id=$bId");
        if (uId.isNotEmpty) params.add("user_main_id=$uId");
        return params.isEmpty ? base : "$base?${params.join('&')}";
      }

      final priceUrl = buildUrl("https://billing.srivagroups.in/api/add-price");
      final comboUrl = buildUrl("https://billing.srivagroups.in/api/add-combo-offer");
      final couponUrl = buildUrl("https://billing.srivagroups.in/api/add-coupon-code");
      final discountUrl = buildUrl("https://billing.srivagroups.in/api/add-discount");

      print("==================================================");
      print("[ADDITIONAL CHARGES REQUESTS]");
      print("PRODUCT ID: $productId");
      print("BUSINESS ID: $bId");
      print("URL PRICE: $priceUrl");
      print("URL COMBO: $comboUrl");
      print("URL COUPON: $couponUrl");
      print("URL DISCOUNT: $discountUrl");
      print("==================================================");

      final results = await Future.wait([
        http.get(Uri.parse(priceUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(comboUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(couponUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(discountUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
      ]);

      print("==================================================");
      print("[ADDITIONAL CHARGES RESPONSES]");
      print("Price Status: ${results[0].statusCode}");
      print("Price Body: ${results[0].body}");
      print("Combo Status: ${results[1].statusCode}");
      print("Combo Body: ${results[1].body}");
      print("Coupon Status: ${results[2].statusCode}");
      print("Coupon Body: ${results[2].body}");
      print("Discount Status: ${results[3].statusCode}");
      print("Discount Body: ${results[3].body}");
      print("==================================================");

      List<dynamic> parseResponse(http.Response res) {
        if (res.statusCode == 200) {
          final decoded = json.decode(res.body);
          if (decoded is Map && decoded.containsKey('data')) {
            return decoded['data'] is List ? decoded['data'] : [];
          } else if (decoded is List) {
            return decoded;
          }
        }
        return [];
      }

      setState(() {
        fetchedPrices = parseResponse(results[0]);
        fetchedCombos = parseResponse(results[1]);
        fetchedCoupons = parseResponse(results[2]);
        fetchedDiscounts = parseResponse(results[3]);
        loadingCharges = false;
      });
    } catch (e) {
      print("Error fetching additional charges: $e");
      setState(() {
        loadingCharges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _showDropdown = false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Customer Search", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔘 TOP TABS (User | Products)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTopTabButton("User", selectedMainTab == "User", () {
                      setState(() => selectedMainTab = "User");
                    }),
                    const SizedBox(width: 4),
                    _buildTopTabButton("Products", selectedMainTab == "Products", () {
                      setState(() => selectedMainTab = "Products");
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),


              if (selectedMainTab == "User")
                _buildCustomerSearchSection()
              else
                _buildProductSearchSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Customer Type", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildSubTabButton("User", isUser, () {
                setState(() {
                  isUser = true;
                  selectedCustomer = null;
                  results = [];
                  _showDropdown = false;
                  _searchController.clear();
                });
              }),
              const SizedBox(width: 4),
              _buildSubTabButton("Business", !isUser, () {
                setState(() {
                  isUser = false;
                  selectedCustomer = null;
                  results = [];
                  _showDropdown = false;
                  _searchController.clear();
                });
              }),
            ],
          ),
        ),

        const SizedBox(height: 24),

        /// 🔍 SEARCH SECTION (With Autocomplete Dropdown)
        CompositedTransformTarget(
          link: _layerLink,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: verifyBy,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          items: ["Mobile No", "GST No", "PAN No"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                verifyBy = v;
                                results = [];
                                selectedCustomer = null;
                                _showDropdown = false;
                                _searchController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      keyboardType: verifyBy == "Mobile No" ? TextInputType.phone : TextInputType.text,
                      onChanged: searchCustomer,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Enter $verifyBy",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(verifyBy == "Mobile No" ? Icons.phone_android : Icons.assignment_ind, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: loading 
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    results = [];
                                    selectedCustomer = null;
                                    _showDropdown = false;
                                    loading = false;
                                    errorMessage = null;
                                  });
                                }
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_showDropdown && (results.isNotEmpty || errorMessage != null))
                _buildAutocompleteDropdown(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (selectedCustomer != null) ...[
          _buildSelectedCustomerCompact(selectedCustomer!),
        ] else ...[
          _buildAddNewCustomerButton(),
        ],
      ],
    );
  }

  Widget _buildProductSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Product Search", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            TextButton.icon(
              onPressed: () => _showAdvancedProductSearch(),
              icon: const Icon(Icons.tune, size: 18, color: Color(0xFF2563EB)),
              label: const Text("Advanced Search", style: TextStyle(color: Color(
                  0xFF1F366A), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CompositedTransformTarget(
          link: _productLayerLink,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: productSearchBy,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        items: ["Name", "SKU", "Category"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => productSearchBy = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _productSearchController,
                      onChanged: searchProduct,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Enter $productSearchBy",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: productLoading 
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _buildProductResultsList(),
        const SizedBox(height: 24),
        _buildSelectedItemsList(),
        if (selectedBillItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildAdditionalChargesSection(),
        ],
      ],
    );
  }

  void calculateTotals() {
    setState(() {
      // 1️⃣ ITEM TOTAL: Sum of all selected items (which already include item-level tax/discount)
      final double itemTotalSum = selectedBillItems.fold(0, (sum, item) => sum + item.total);
      
      final double enteredTax = double.tryParse(taxController.text) ?? 0;
      final double enteredDiscount = double.tryParse(discountController.text) ?? 0;
      final double additionalCharges = double.tryParse(chargesController.text) ?? 0;

      // 2️⃣ GST / TAX CALCULATION
      double taxAmount = 0;
      if (globalTaxType == "%") {
        taxAmount = (itemTotalSum * enteredTax) / 100;
      } else {
        taxAmount = enteredTax;
      }

      // 3️⃣ DISCOUNT CALCULATION
      double discountAmount = 0;
      if (globalDiscountType == "%") {
        discountAmount = (itemTotalSum * enteredDiscount) / 100;
      } else {
        discountAmount = enteredDiscount;
      }


      totalItemAmount = itemTotalSum;
      totalTaxAmount = taxAmount;
      totalDiscountAmount = discountAmount;
      totalAdditionalCharges = additionalCharges;
      

      finalPayableAmount = itemTotalSum + taxAmount + additionalCharges - discountAmount;
      
      // Sync legacy variables for safety
      itemTotal = itemTotalSum;
      payableTotal = finalPayableAmount;
    });
  }

  void _updateItemQty(ProductStock item, int newQty) {
    setState(() {
      int idx = selectedBillItems.indexWhere((e) => e.stockId == item.stockId && e.variantId == item.variantId);
      if (idx != -1) {
        double currentItemBaseTotal = newQty * item.unitPrice;
        
        // Recalculate item-level tax/discount automatically
        double taxAmt = item.taxType == "%" ? (currentItemBaseTotal * item.enteredTax) / 100 : item.enteredTax;
        double discountAmt = item.discountType == "%" ? (currentItemBaseTotal * item.enteredDiscount) / 100 : item.enteredDiscount;
        
        double finalPayableItem = currentItemBaseTotal + taxAmt - discountAmt;
        
        selectedBillItems[idx] = item.copyWith(
          qty: newQty,
          total: finalPayableItem,
          taxAmount: taxAmt,
          discountAmount: discountAmt,
        );
      }
      calculateTotals();
    });
  }

  Widget _buildAdditionalChargesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCollapsibleChargesHeader(),
          _buildChargesTabsSection(),
          const SizedBox(height: 24),
          _buildSummaryCard(),
          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Submit logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("Generate Final Bill", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleChargesHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // light blue
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5), // blue border
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              showAdditionalChargesDetails = !showAdditionalChargesDetails;
            });
            if (showAdditionalChargesDetails) {
              fetchAdditionalChargesData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showAdditionalChargesDetails ? Icons.remove_circle : Icons.add_circle,
                  color: const Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "additional_charges".tr,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChargesTabsSection() {
    if (!showAdditionalChargesDetails) return const SizedBox.shrink();

    // Icon & Label mappings
    final List<Map<String, dynamic>> tabs = [
      {"label": "price".tr, "icon": Icons.currency_rupee, "color": const Color(0xFF2563EB)},
      {"label": "combo_offer".tr, "icon": Icons.card_giftcard, "color": const Color(0xFFEF4444)},
      {"label": "coupon_code".tr, "icon": Icons.local_offer, "color": const Color(0xFFF59E0B)},
      {"label": "discount_card".tr, "icon": Icons.credit_card, "color": const Color(0xFF10B981)},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Headers Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (idx) {
                final tab = tabs[idx];
                final isSelected = activeChargesTab == idx;
                return InkWell(
                  onTap: () {
                    setState(() {
                      activeChargesTab = idx;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      color: isSelected ? Colors.white : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab["icon"],
                          size: 16,
                          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tab["label"],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Tab Content Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: loadingCharges
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildActiveTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (activeChargesTab) {
      case 0:
        return _buildPricesList();
      case 1:
        return _buildCombosList();
      case 2:
        return _buildCouponsList();
      case 3:
        return _buildDiscountsList();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPricesList() {
    if (fetchedPrices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "no_price_plans".tr,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: fetchedPrices.map((price) {
        final amount = price['amount']?.toString() ?? '0';
        final name = price['name']?.toString() ?? 'Price Plan';
        final desc = price['description']?.toString() ?? '';
        final status = price['status']?.toString() ?? 'inactive';
        final isPriceActive = status.toLowerCase() == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "₹$amount",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (isPriceActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "active".tr,
                      style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Apply price to the first selected item
              if (selectedBillItems.isNotEmpty) {
                final double newPrice = double.tryParse(amount) ?? 0.0;
                setState(() {
                  final firstItem = selectedBillItems.first;
                  // Override price
                  int idx = selectedBillItems.indexOf(firstItem);
                  if (idx != -1) {
                    selectedBillItems[idx] = firstItem.copyWith(
                      unitPrice: newPrice,
                    );
                  }
                  calculateTotals();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Applied unit price ₹$amount to ${selectedBillItems.first.productName}")),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCombosList() {
    if (fetchedCombos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "no_combos".tr,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: fetchedCombos.map((combo) {
        final name = combo['combo_name'] ?? combo['comboName'] ?? 'Combo Offer';
        final price = combo['combo_price'] ?? combo['comboPrice'] ?? '0';
        final desc = combo['description']?.toString() ?? '';
        final status = combo['status']?.toString() ?? 'inactive';
        final isComboActive = status.toLowerCase() == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "₹$price",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFEF4444),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (isComboActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "active".tr,
                      style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Apply combo price to the first selected item
              if (selectedBillItems.isNotEmpty) {
                final double newPrice = double.tryParse(price.toString()) ?? 0.0;
                setState(() {
                  final firstItem = selectedBillItems.first;
                  int idx = selectedBillItems.indexOf(firstItem);
                  if (idx != -1) {
                    selectedBillItems[idx] = firstItem.copyWith(
                      unitPrice: newPrice,
                    );
                  }
                  calculateTotals();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Applied combo price ₹$price to ${selectedBillItems.first.productName}")),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCouponsList() {
    if (fetchedCoupons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "no_coupons".tr,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: fetchedCoupons.map((coupon) {
        final code = coupon['coupon_code'] ?? coupon['couponCode'] ?? 'COUPON';
        final pct = coupon['discount_pct'] ?? coupon['discountPct'];
        final fixed = coupon['fixed_price'] ?? coupon['fixedPrice'];
        final desc = coupon['description']?.toString() ?? '';
        final status = coupon['status']?.toString() ?? 'inactive';
        final isCouponActive = status.toLowerCase() == 'active';

        String valueText = "";
        if (pct != null && pct > 0) {
          valueText = "$pct%";
        } else if (fixed != null && fixed > 0) {
          valueText = "₹$fixed";
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF59E0B),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (isCouponActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "active".tr,
                      style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            onTap: () {
              setState(() {
                if (pct != null && pct > 0) {
                  globalDiscountType = "%";
                  discountController.text = pct.toString();
                } else if (fixed != null && fixed > 0) {
                  globalDiscountType = "₹";
                  discountController.text = fixed.toString();
                }
                calculateTotals();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Applied coupon $code ($valueText discount)")),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiscountsList() {
    if (fetchedDiscounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "no_discounts".tr,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: fetchedDiscounts.map((disc) {
        final name = disc['discount_name'] ?? disc['discountName'] ?? 'Discount';
        final pct = disc['discount_pct'] ?? disc['discountPct'] ?? 0;
        final desc = disc['description']?.toString() ?? '';
        final status = disc['status']?.toString() ?? 'inactive';
        final isDiscActive = status.toLowerCase() == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$pct%",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (isDiscActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "active".tr,
                      style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            onTap: () {
              setState(() {
                globalDiscountType = "%";
                discountController.text = pct.toString();
                calculateTotals();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Applied discount $name ($pct%)")),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChargeInput({required String label, required TextEditingController controller, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => calculateTotals(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "0",
            hintStyle: TextStyle(color: Colors.grey.shade300),
            prefixIcon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow("item_total".tr, "₹${totalItemAmount.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _summaryRow("gst_tax".tr, "+ ₹${totalTaxAmount.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _summaryRow("additional_charges".tr, "+ ₹${totalAdditionalCharges.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _summaryRow("discount".tr, "- ₹${totalDiscountAmount.toStringAsFixed(2)}", isNegative: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("payable_total".tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text("₹${finalPayableAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.red : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemsList() {
    if (selectedBillItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Bill Items",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${selectedBillItems.length}",
                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 768) {
            return Column(
              children: List.generate(selectedBillItems.length, (index) {
                return _buildSelectedProductMobileCard(selectedBillItems[index], index + 1);
              }),
            );
          } else {
            return _buildSelectedProductDesktopTable();
          }
        }),
      ],
    );
  }

  Widget _buildSelectedProductMobileCard(ProductStock item, int sNo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header: S.No and Product Name
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "$sNo",
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.variant,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _actionBtn(Icons.edit_outlined, const Color(0xFF2563EB), () => _showEditPopup(item)),
                const SizedBox(width: 8),
                _actionBtn(Icons.delete_outline, Colors.red, () {
                  setState(() {
                    selectedBillItems.remove(item);
                    calculateTotals();
                  });
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Body: Qty and Pricing
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Qty Controls
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyBtn(Icons.remove, () {
                            if (item.qty > 1) {
                              _updateItemQty(item, item.qty - 1);
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _qtyBtn(Icons.add, () {
                            _updateItemQty(item, item.qty + 1);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Stock: ${item.qty}", // Dynamically bound stock
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
                
                // Pricing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Unit: ₹${item.unitPrice.toStringAsFixed(2)}",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${item.total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18, 
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: const Color(0xFF1E293B)),
      ),
    );
  }

  void _showEditPopup(ProductStock item) async {
    final selectedProductId = item.productId;
    final selectedStockId = item.stockId;
    final selectedVariantId = item.variantId;

    print("SELECTED PRODUCT => productId: $selectedProductId stockId: $selectedStockId variantId: $selectedVariantId");

    // 🔥 STEP 2: Fetch fresh stock details using CLICKED row's IDs only
    final List stockTypesFromApi = await fetchStockDetails(selectedStockId, selectedVariantId);
    print("FILTERED STOCK TYPES => $stockTypesFromApi");
    
    int tempQty = item.qty;
    // Use a local mutable map for the popup session
    final Map<String, int> distribution = Map<String, int>.from(item.selectedDistribution);
    
    // Local states for Tax and Discount
    String discountType = item.discountType;
    String taxType = item.taxType;
    final TextEditingController discountControllerPopup = TextEditingController(text: item.enteredDiscount == 0 ? "" : item.enteredDiscount.toString());
    final TextEditingController taxControllerPopup = TextEditingController(text: item.enteredTax == 0 ? "" : item.enteredTax.toString());

    // Show dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setPopupState) {
            // ✅ Bind filtered stock types strictly to the UI
            final List itemStockTypes = List<dynamic>.from(stockTypesFromApi);

            void updateLiveItem() {
              int idx = selectedBillItems.indexWhere((e) => e.stockId == item.stockId && e.variantId == item.variantId);
              if (idx != -1) {
                double currentItemBaseTotal = tempQty * item.unitPrice;
                double enteredTaxVal = double.tryParse(taxControllerPopup.text) ?? 0;
                double enteredDiscountVal = double.tryParse(discountControllerPopup.text) ?? 0;
                
                double taxAmt = taxType == "%" ? (currentItemBaseTotal * enteredTaxVal) / 100 : enteredTaxVal;
                double discountAmt = discountType == "%" ? (currentItemBaseTotal * enteredDiscountVal) / 100 : enteredDiscountVal;
                double finalPayableItem = currentItemBaseTotal + taxAmt - discountAmt;

                setState(() {
                  selectedBillItems[idx] = item.copyWith(
                    qty: tempQty,
                    total: finalPayableItem,
                    taxAmount: taxAmt,
                    discountAmount: discountAmt,
                    enteredTax: enteredTaxVal,
                    enteredDiscount: enteredDiscountVal,
                    taxType: taxType,
                    discountType: discountType,
                  );
                  calculateTotals();
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              elevation: 24,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.edit_document, color: Color(0xFF2563EB), size: 20),
                          ),
                          const SizedBox(width: 16),
                          const Text("Update Item", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), padding: const EdgeInsets.all(8)),
                          ),
                        ],  
                      ),
                      const SizedBox(height: 32),
                      
                      // Product Basic Info
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                const SizedBox(height: 6),
                                _variantBadge(item),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Billing Quantity
                      const Text("Billing Quantity", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _qtyBtnLarge(Icons.remove_rounded, () {
                              if (tempQty > 1) {
                                setPopupState(() {
                                  tempQty--;
                                  updateLiveItem();
                                });
                              }
                            }),
                            Text("$tempQty", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            _qtyBtnLarge(Icons.add_rounded, () {
                              setPopupState(() {
                                tempQty++;
                                updateLiveItem();
                              });
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // --- STOCK DISTRIBUTION SECTION (REDESIGNED) ---
                      const Text("Stock Distribution", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 16),
                      
                      // Premium light green summary card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4), // Light green
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
                          boxShadow: [
                             BoxShadow(color: const Color(0xFF166534).withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Distributed Stock", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                const SizedBox(height: 4),
                                Text(
                                  "Pending Dist: ${tempQty - distribution.values.fold(0, (sum, q) => sum + q)}", 
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600)
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("Total Balance", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534), letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(
                                  "${itemStockTypes.fold(0, (sum, st) => sum + (int.tryParse((st['qty'] ?? 0).toString()) ?? 0))}", 
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF15803D))
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Select Source to Add Dropdown
                      _buildStockSourceDropdown(
                        context,
                        itemStockTypes,
                        distribution,
                        (selectedId) {
                          setPopupState(() {
                            if (distribution.containsKey(selectedId)) {
                              return;
                            }

                            final selectedSource = itemStockTypes.firstWhere(
                              (s) => s['stock_type_id'].toString() == selectedId,
                            );

                            final int available = int.tryParse(
                                  (selectedSource['qty'] ?? 0).toString(),
                                ) ??
                                0;

                            // INSERT SELECTED ITEM INTO MAP
                            distribution[selectedId] = 0;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Selected Source Cards
                      Column(
                        children: distribution.keys.map((id) {
                          final source = itemStockTypes.firstWhere((s) => s['stock_type_id'].toString() == id);
                          return _buildSourceSelectionCard(
                            source: source,
                            deducted: distribution[id]!,
                            onQtyChanged: (val) => setPopupState(() => distribution[id] = val),
                            onRemove: () => setPopupState(() => distribution.remove(id)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // --- END STOCK DISTRIBUTION SECTION ---
                      // --- POPUP BOTTOM SECTION (TAX, DISCOUNT, DONE) ---
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildManualInput(
                              label: "Discount", 
                              controller: discountControllerPopup, 
                              icon: Icons.local_offer_outlined,
                              currentType: discountType,
                              onToggle: (type) {
                                setPopupState(() {
                                  discountType = type;
                                  updateLiveItem();
                                });
                              },
                              onChanged: (_) {
                                setPopupState(() {
                                  updateLiveItem();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildManualInput(
                              label: "Tax / GST", 
                              controller: taxControllerPopup, 
                              icon: Icons.receipt_long_outlined,
                              currentType: taxType,
                              onToggle: (type) {
                                setPopupState(() {
                                  taxType = type;
                                  updateLiveItem();
                                });
                              },
                              onChanged: (_) {
                                setPopupState(() {
                                  updateLiveItem();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Done Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                int idx = selectedBillItems.indexWhere((e) => e.stockId == item.stockId);
                                if (idx != -1) {
                                  // Calculate summary stock type name
                                  String summaryStockType = "Direct";
                                  if (distribution.isNotEmpty) {
                                    final firstId = distribution.keys.first;
                                    final firstSource = itemStockTypes.firstWhere((s) => s['stock_type_id'].toString() == firstId, orElse: () => null);
                                    summaryStockType = firstSource != null ? firstSource['name'] : "Direct";
                                    if (distribution.length > 1) summaryStockType += " (+${distribution.length - 1})";
                                  }

                                  final double currentItemBaseTotal = tempQty * item.unitPrice;
                                  final double enteredTaxVal = double.tryParse(taxControllerPopup.text) ?? 0;
                                  final double enteredDiscountVal = double.tryParse(discountControllerPopup.text) ?? 0;

                                  double taxAmt = 0;
                                  double discountAmt = 0;

                                  if (taxType == "%") {
                                    taxAmt = (currentItemBaseTotal * enteredTaxVal) / 100;
                                  } else {
                                    taxAmt = enteredTaxVal;
                                  }

                                  if (discountType == "%") {
                                    discountAmt = (currentItemBaseTotal * enteredDiscountVal) / 100;
                                  } else {
                                    discountAmt = enteredDiscountVal;
                                  }

                                  final double finalPayableItem = currentItemBaseTotal + taxAmt - discountAmt;

                                  selectedBillItems[idx] = item.copyWith(
                                    qty: tempQty,
                                    total: finalPayableItem,
                                    stockType: summaryStockType,
                                    selectedDistribution: Map<String, int>.from(distribution),
                                    taxAmount: taxAmt,
                                    discountAmount: discountAmt,
                                    enteredTax: enteredTaxVal,
                                    enteredDiscount: enteredDiscountVal,
                                    taxType: taxType,
                                    discountType: discountType,
                                  );
                                }
                                calculateTotals();
                              });
                              Navigator.pop(dialogContext);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text("Done", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPER WIDGETS FOR STOCK SOURCE SELECTION ---

  Widget _infoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStockSourceDropdown(BuildContext context, List<dynamic> sources, Map<String, int> distribution, Function(String) onSelect) {
    // Duplicate Prevention: Filter out already selected sources
    final availableSources = sources.where((s) {
      final stockTypeId = (s['stock_type_id'] ?? "").toString();
      return !distribution.keys.contains(stockTypeId);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Source to Add", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 56),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 48, 
              maxWidth: MediaQuery.of(context).size.width - 48
            ),
            onSelected: (selectedId) {
              final selectedSource = sources.firstWhere(
                (s) => s['stock_type_id'].toString() == selectedId,
                orElse: () => null,
              );

              if (selectedSource != null && !distribution.containsKey(selectedId)) {
                onSelect(selectedId);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Stock Source", style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                  Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
                ],
              ),
            ),
            itemBuilder: (context) {
              if (availableSources.isEmpty) {
                return [
                  const PopupMenuItem(
                    enabled: false,
                    child: Text("All sources selected", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                ];
              }
              return availableSources.map((stockType) {
                final id = stockType['stock_type_id'].toString();
                final name = stockType['name'] ?? "Unknown";
                final qty = int.tryParse((stockType['qty'] ?? 0).toString()) ?? 0;
                
                return PopupMenuItem<String>(
                  value: id,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    "$name (Available: $qty)",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSourceSelectionCard({
    required dynamic source,
    required int deducted,
    required Function(int) onQtyChanged,
    required VoidCallback onRemove,
  }) {
    final int available = int.tryParse((source['qty'] ?? 0).toString()) ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LEFT: Name and Deducted Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text("Deducted: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyActionBtn(Icons.remove, () {
                            if (deducted > 0) onQtyChanged(deducted - 1);
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text("$deducted", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          _qtyActionBtn(Icons.add, () {
                            if (deducted < available) onQtyChanged(deducted + 1);
                          }),
                        ],
                      ),
                    ),
                    Text(" / $available", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          
          // RIGHT: Balance and Close
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Balance: ${available - deducted}", 
                  style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 11)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualInput({
    required String label, 
    required TextEditingController controller, 
    required IconData icon,
    required String currentType,
    required Function(String) onToggle,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: onChanged,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    isDense: true,
                    hintText: "0",
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onToggle(currentType == "%" ? "₹" : "%"),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentType,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyActionBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 14, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _qtyBtnLarge(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
        ),
      ),
    );
  }

  void _showStockSourceSheet(BuildContext context, List<dynamic> stockTypes, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Stock Source", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (stockTypes.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No stock sources available", style: TextStyle(color: Colors.grey))))
            else
              ...stockTypes.map((st) {
                final name = (st['name'] ?? 'Unknown').toString();
                final qty = st['qty'] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    onTap: () {
                      onSelect(st['stock_type_id'].toString());
                      Navigator.pop(context);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text("$name (Available: $qty)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB)),
                  ),
                );
              }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedProductDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text("S.No")),
          DataColumn(label: Text("Product")),
          DataColumn(label: Text("Qty")),
          DataColumn(label: Text("Price")),
          DataColumn(label: Text("Total")),
          DataColumn(label: Text("Action")),
        ],
        rows: List.generate(selectedBillItems.length, (index) {
          final item = selectedBillItems[index];
          return DataRow(cells: [
            DataCell(Text("${index + 1}")),
            DataCell(Text(item.productName)),
            DataCell(Text("${item.qty}")),
            DataCell(Text("₹${item.unitPrice}")),
            DataCell(Text("₹${item.total}")),
            DataCell(Row(
              children: [
                _actionBtn(Icons.edit, Colors.blue, () => _showEditPopup(item)),
                const SizedBox(width: 8),
                _actionBtn(Icons.delete, Colors.red, () {
                  setState(() {
                    selectedBillItems.remove(item);
                    calculateTotals();
                  });
                }),
              ],
            )),
          ]);
        }),
      ),
    );
  }

  Widget _buildProductResultsList() {
    if (productResults.isEmpty && productErrorMessage == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text("No products to display. Search to find products.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (productErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: Text(productErrorMessage!, style: TextStyle(color: Colors.red.shade700)),
      );
    }

    // ✅ Render all merged product cards in a single unified list as requested
    return Column(
      children: [
        if (productResults.isNotEmpty) ...[
          _buildGroupHeadline("PRODUCT RESULTS"),
          ...productResults.map((item) => _buildProductCard(item)),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildGroupHeadline(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF2563EB), width: 4)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildProductCard(ProductStock item) {
    bool isSelected = selectedBillItems.any((e) => e.stockId == item.stockId && e.variantId == item.variantId);
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return GestureDetector(
          onTap: () async {
            if (!isSelected) {
              final stockTypes = await fetchStockDetails(item.stockId, item.variantId);
              setState(() {
                selectedBillItems.add(item.copyWith(stockTypes: stockTypes));
                calculateTotals();
              });
            } else {
              setState(() {
                selectedBillItems.removeWhere((e) => e.stockId == item.stockId && e.variantId == item.variantId);
                calculateTotals();
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB).withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0xFF2563EB).withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  isMobile ? _buildMobileCard(item) : _buildDesktopCard(item),
                  if (isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopCard(ProductStock item) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text("${item.supplierName} • ${item.category}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: _variantBadge(item),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Warranty: ${item.warranty}", style: const TextStyle(fontSize: 12)),
              Text("Qty: ${item.qty}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹${item.unitPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14)),
              Text("₹${item.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            ],
          ),
        ),
        const SizedBox(width: 24),
        _buildActionButtons(item),
      ],
    );
  }

  Widget _buildMobileCard(ProductStock item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            _variantBadge(item),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _mobileInfoChip(Icons.verified_user_outlined, item.warranty, Colors.green),
            const SizedBox(width: 12),
            _mobileInfoChip(Icons.inventory_2_outlined, "Qty: ${item.qty}", Colors.orange),
          ],
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Price: ₹${item.unitPrice.toStringAsFixed(2)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text("Total: ₹${item.total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2563EB))),
              ],
            ),
            _buildActionButtons(item),
          ],
        ),
      ],
    );
  }

  Widget _variantBadge(ProductStock item) {
    if (item.variant.contains(" | ")) {
      final labels = item.variant.split(" | ");
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: labels.map((l) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _singleVariantBadge(l),
          );
        }).toList(),
      );
    }
    return _singleVariantBadge(item.variant);
  }

  Widget _singleVariantBadge(String label) {
    Color color;
    if (label == "Original") {
      color = Colors.green;
    } else if (label == "Import") {
      color = Colors.orange;
    } else if (label == "Complimentary" || label == "Compliment") {
      color = Colors.purple;
    } else {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildActionButtons(ProductStock item) {
    bool isSelected = selectedBillItems.any((e) => e.stockId == item.stockId);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Rule: IF total_qty == 0 -> SHOW Request button ONLY
        // ✅ ELSE -> SHOW View and Add buttons
        if (item.isRequest)
          ElevatedButton(
            onPressed: () {
              // Request implementation
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(80, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("Request", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )
        else ...[
          _actionBtn(Icons.visibility_outlined, const Color(0xFF2563EB), () => _showProductDetails(item)),
          const SizedBox(width: 8),
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 16),
                  SizedBox(width: 6),
                  Text("Added", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            )
          else
            _actionBtn(Icons.add_circle_outline, const Color(0xFF2563EB), () async {
              final stockTypes = await fetchStockDetails(item.stockId, item.variantId);
              setState(() {
                selectedBillItems.add(item.copyWith(stockTypes: stockTypes));
                calculateTotals();
              });
            }),
        ],
      ],
    );
  }

  Widget _mobileInfoChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        splashRadius: 22,
      ),
    );
  }

  void _showProductDetails(ProductStock item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔝 TOP HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Product Information",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 24,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 📜 SCROLLABLE CONTENT
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🖼️ PRODUCT IMAGE PLACEHOLDER
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text("Product Image", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 🏷️ PRIMARY INFO
                      _detailRow("Product Name", item.productName, isBold: true),
                      _detailRow("Variant", item.variant, badgeColor: const Color(0xFF2563EB)),
                      _detailRow("Warranty", item.warranty),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),

                      // 📊 STOCK & PRICE INFO
                      Row(
                        children: [
                          Expanded(child: _detailRow("Total Qty", item.qty.toString())),
                          const SizedBox(width: 24),
                          Expanded(child: _detailRow("Stock Type", item.stockType)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _detailRow("Normal Price", "₹${item.normalPrice.toStringAsFixed(2)}"),
                      _detailRow("Tax %", "${item.taxPercent}%"),
                      _detailRow("Tax Price", "₹${item.taxPrice.toStringAsFixed(2)}"),
                      
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.1)),
                        ),
                        child: _detailRow("Final Selling Price", "₹${item.unitPrice.toStringAsFixed(2)}", isHighlight: true, noPadding: true),
                      ),

                      const SizedBox(height: 24),
                      const Text("Description", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔘 FOOTER
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Close Window", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? badgeColor, bool isHighlight = false, bool noPadding = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: noPadding ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: badgeColor != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value, 
                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.normal,
                        fontSize: isHighlight ? 18 : 13,
                        color: isHighlight ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProductAutocompleteDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: productErrorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(productErrorMessage!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: productResults.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade50),
              itemBuilder: (context, index) {
                final item = productResults[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text("${item.supplierName} • ${item.category}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  onTap: () {
                    setState(() {
                      bool isAlreadySelected = selectedBillItems.any((e) => e.stockId == item.stockId);
                      if (!isAlreadySelected) {
                        selectedBillItems.add(item);
                      } else {
                        selectedBillItems.removeWhere((e) => e.stockId == item.stockId);
                      }
                      calculateTotals();
                      // DO NOT clear search results or controller as per user requirement
                      _showProductDropdown = false;
                    });
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
    );
  }

  Widget _buildTopTabButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: errorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(errorMessage!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: results.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade50),
              itemBuilder: (context, index) {
                final item = results[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(item.mobile, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.address.isEmpty ? "No address" : item.address,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      selectedCustomer = item;
                      _showDropdown = false;
                      // Autofill based on active search type
                      if (verifyBy == "GST No") {
                        _searchController.text = item.gst;
                      } else if (verifyBy == "PAN No") {
                        _searchController.text = item.pan;
                      } else {
                        _searchController.text = item.mobile;
                      }
                      results = []; // Clear results to prevent stale data
                    });
                  },
                );
              },
            ),
    );
  }

  Widget _buildSelectedCustomerCompact(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                customer.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text("Verified", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(customer.mobile, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  customer.address.isEmpty ? "No address provided" : customer.address,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdvancedProductSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // 🔝 DRAG HANDLE
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // 🏷️ HEADER
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Advanced Search",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Find products faster using filters",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // 📜 FORM CONTENT
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            child: Column(
                              children: [
                                _buildSearchDropdown(
                                  label: "Category Group",
                                  value: filterCategoryGroup,
                                  hint: "Select Category Group",
                                  items: ["Group A", "Group B", "Group C"], // Placeholder options
                                  onChanged: (val) => setModalState(() => filterCategoryGroup = val),
                                ),
                                const SizedBox(height: 16),
                                _buildSearchDropdown(
                                  label: "Category",
                                  value: filterCategory,
                                  hint: "Select Category",
                                  items: ["Electronics", "Fashion", "Grocery"], // Placeholder options
                                  onChanged: (val) => setModalState(() => filterCategory = val),
                                ),
                                const SizedBox(height: 16),
                                _buildSearchDropdown(
                                  label: "Brand",
                                  value: filterBrand,
                                  hint: "Select Brand",
                                  items: ["Apple", "Samsung", "Sony"], // Placeholder options
                                  onChanged: (val) => setModalState(() => filterBrand = val),
                                ),
                                const SizedBox(height: 16),
                                _buildSearchInputField(
                                  label: "Product Name / ID",
                                  controller: filterProductNameController,
                                  hint: "Search by name or unique ID",
                                  icon: Icons.search_rounded,
                                ),
                                const SizedBox(height: 16),
                                _buildSearchInputField(
                                  label: "HSN Code",
                                  controller: filterHSNController,
                                  hint: "Enter HSN Code",
                                  icon: Icons.qr_code_rounded,
                                ),
                                const SizedBox(height: 16),
                                _buildSearchDropdown(
                                  label: "GST Rate",
                                  value: filterGST,
                                  hint: "Select GST",
                                  items: ["0%", "5%", "12%", "18%", "28%"],
                                  onChanged: (val) => setModalState(() => filterGST = val),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSearchInputField(
                                        label: "Price Min",
                                        controller: filterPriceMinController,
                                        hint: "0.00",
                                        keyboardType: TextInputType.number,
                                        icon: Icons.currency_rupee_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildSearchInputField(
                                        label: "Price Max",
                                        controller: filterPriceMaxController,
                                        hint: "Max",
                                        keyboardType: TextInputType.number,
                                        icon: Icons.currency_rupee_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSearchInputField(
                                        label: "Stock Min",
                                        controller: filterStockMinController,
                                        hint: "0",
                                        keyboardType: TextInputType.number,
                                        icon: Icons.inventory_2_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildSearchInputField(
                                        label: "Stock Max",
                                        controller: filterStockMaxController,
                                        hint: "Max",
                                        keyboardType: TextInputType.number,
                                        icon: Icons.inventory_2_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),

                        // 🔘 BOTTOM ACTIONS
                        _buildBottomActionBar(
                          onClear: () {
                            setModalState(() {
                              filterCategoryGroup = null;
                              filterCategory = null;
                              filterBrand = null;
                              filterGST = null;
                              filterProductNameController.clear();
                              filterHSNController.clear();
                              filterPriceMinController.clear();
                              filterPriceMaxController.clear();
                              filterStockMinController.clear();
                              filterStockMaxController.clear();
                            });
                          },
                          onSearch: () {
                            // Implement filter logic here
                            Navigator.pop(context);
                            // Trigger API search with filters
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF64748B)) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B))),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar({required VoidCallback onClear, required VoidCallback onSearch}) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                "Clear",
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  "Show Results",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Customer {
  final String name;
  final String mobile;
  final String type;
  final String address;
  final String email;
  final String gst;
  final String pan;

  Customer({
    required this.name,
    required this.mobile,
    required this.type,
    required this.address,
    required this.email,
    required this.gst,
    required this.pan,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    // 1️⃣ NAME MAPPING with deep fallbacks
    String name = (json['customer_name'] ?? 
                   json['business_name'] ?? 
                   json['name'] ?? 
                   json['full_name'] ?? 
                   json['display_name'] ?? 
                   '').toString();

    // 2️⃣ MOBILE MAPPING with deep fallbacks
    String mob = (json['customer_phone'] ?? 
                  json['mobile_no'] ?? 
                  json['mobile'] ?? 
                  json['phone'] ?? 
                  json['contact'] ?? 
                  json['contact_no'] ?? 
                  '').toString();

    // 3️⃣ TYPE MAPPING
    String type = (json['customer_type'] ?? 
                   json['business_type'] ?? 
                   json['type'] ?? 
                   '').toString();

    // 4️⃣ GST MAPPING
    String gst = (json['gst_no'] ?? 
                  json['gst'] ?? 
                  json['gstin'] ?? 
                  json['business_gst'] ??
                  json['tax_id'] ??
                  '').toString();

    // 5️⃣ PAN MAPPING
    String pan = (json['pan_no'] ?? 
                  json['pan'] ?? 
                  '').toString();

    // 6️⃣ ADDRESS & EMAIL MAPPING (Handle nested meta)
    var meta = json['customer_meta'] ?? json['meta'] ?? json['business_meta'] ?? json['meta_data'];
    
    String address = (json['address'] ?? 
                      json['location'] ?? 
                      json['addr'] ?? 
                      '').toString();
                      
    String email = (json['email'] ?? 
                    json['email_id'] ?? 
                    json['mail'] ?? 
                    '').toString();

    if (meta is Map) {
      if (address.isEmpty || address == "null") {
        address = (meta['address'] ?? meta['location'] ?? meta['customer_address'] ?? '').toString();
      }
      if (email.isEmpty || email == "null") {
        email = (meta['email'] ?? meta['email_id'] ?? '').toString();
      }
    }

    // Final sanitization
    if (name == "null" || name.isEmpty) name = "";
    if (mob == "null") mob = "";
    if (type == "null") type = "";
    if (address == "null") address = "";
    if (email == "null") email = "";
    if (gst == "null") gst = "";
    if (pan == "null") pan = "";

    return Customer(
      name: name,
      mobile: mob,
      type: type,
      address: address,
      email: email,
      gst: gst,
      pan: pan,
    );
  }
}

class ProductStock {
  final String stockId;
  final String productId;
  final String productName;
  final String supplierName;
  final String category;
  final String sku;
  final String variant;
  final String warranty;
  final int qty;
  final double unitPrice;
  final double total;
  final String stockType;
  final double normalPrice;
  final double taxPercent;
  final double taxPrice;
  final String description;
  final List<dynamic> stockTypes; 
  final Map<String, int> selectedDistribution;
  final String variantId;      // Record ID (e.g., 67)
  final String variantTypeId;  // Type ID (e.g., 1, 2, 3)
  final double taxAmount;
  final double discountAmount;
  final double enteredTax;
  final double enteredDiscount;
  final String taxType;
  final String discountType;
  final bool isRequest;

  ProductStock({
    required this.stockId,
    this.productId = "",
    required this.productName,
    required this.supplierName,
    required this.category,
    this.variantId = "",
    this.variantTypeId = "",
    this.sku = "",
    this.variant = "",
    this.warranty = "",
    this.qty = 0,
    this.unitPrice = 0.0,
    this.total = 0.0,
    this.stockType = "",
    this.normalPrice = 0.0,
    this.taxPercent = 0.0,
    this.taxPrice = 0.0,
    this.description = "",
    this.stockTypes = const [],
    this.selectedDistribution = const {},
    this.isRequest = false,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.enteredTax = 0.0,
    this.enteredDiscount = 0.0,
    this.taxType = "%",
    this.discountType = "₹",
  });

  ProductStock copyWith({
    int? qty,
    double? total,
    String? stockType,
    List<dynamic>? stockTypes,
    Map<String, int>? selectedDistribution,
    String? variantId,
    String? variantTypeId,
    String? variant,
    bool? isRequest,
    double? taxAmount,
    double? discountAmount,
    double? enteredTax,
    double? enteredDiscount,
    String? taxType,
    String? discountType,
    double? unitPrice,
    double? normalPrice,
  }) {
    return ProductStock(
      stockId: stockId,
      productId: productId,
      productName: productName,
      supplierName: supplierName,
      category: category,
      variantId: variantId ?? this.variantId,
      variantTypeId: variantTypeId ?? this.variantTypeId,
      sku: sku,
      variant: variant ?? this.variant,
      warranty: warranty,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      stockType: stockType ?? this.stockType,
      normalPrice: normalPrice ?? this.normalPrice,
      taxPercent: taxPercent,
      taxPrice: taxPrice,
      description: description,
      stockTypes: stockTypes ?? this.stockTypes,
      selectedDistribution: selectedDistribution ?? this.selectedDistribution,
      isRequest: isRequest ?? this.isRequest,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      enteredTax: enteredTax ?? this.enteredTax,
      enteredDiscount: enteredDiscount ?? this.enteredDiscount,
      taxType: taxType ?? this.taxType,
      discountType: discountType ?? this.discountType,
    );
  }
}

