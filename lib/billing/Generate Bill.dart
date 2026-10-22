import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:billingapp/billing/checkout_screen.dart';
import 'package:billingapp/utils/app_logger.dart';

part 'generate_bill_logic.dart';
part 'generate_bill_widgets.dart';
part 'generate_bill_dialogs.dart';
part 'generate_bill_views.dart';
part 'generate_bill_views_billing.dart';

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
          onNavigationRequest: (NavigationRequest request) {
            if (_shouldPop(request.url)) {
              _safePop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null && _shouldPop(change.url!)) {
              _safePop(true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Registration"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _safePop(false),
        ),
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
  String selectedMainTab = "User"; // navigation tab
  String productSearchBy = "Name"; // dropdown option
  bool _isLaunchingRegistration = false;
  
  // Product state
  List<ProductStock> productResults = [];
  ProductStock? selectedProduct;
  List<ProductStock> selectedBillItems = [];
  bool productLoading = false;
  String? productErrorMessage;
  bool _showProductDropdown = false;
  final TextEditingController _productSearchController = TextEditingController();
  final LayerLink _productLayerLink = LayerLink();
  Timer? _debounce;
  bool _showDropdown = false;
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  // Advanced filters
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

  // Billing Totals Controllers
  final TextEditingController taxController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController chargesController = TextEditingController();
  double itemTotal = 0.0;
  double payableTotal = 0.0;

  // Global Billing State
  String globalTaxType = "%";
  String globalDiscountType = "₹";
  double totalItemAmount = 0.0;
  double totalTaxAmount = 0.0;
  double totalDiscountAmount = 0.0;
  double totalAdditionalCharges = 0.0;
  double finalPayableAmount = 0.0;

  // Additional Charges
  bool showAdditionalChargesDetails = false;
  int activeChargesTab = 0;
  bool loadingCharges = false;
  List<dynamic> fetchedPrices = [];
  List<dynamic> fetchedCombos = [];
  List<dynamic> fetchedCoupons = [];
  List<dynamic> fetchedDiscounts = [];

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _debounce?.cancel();
    _searchFocusNode.dispose();
    
    filterProductNameController.dispose();
    filterHSNController.dispose();
    filterPriceMinController.dispose();
    filterPriceMaxController.dispose();
    filterStockMinController.dispose();
    filterStockMaxController.dispose();
    
    taxController.dispose();
    discountController.dispose();
    chargesController.dispose();
    super.dispose();
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
    String name = (json['customer_name'] ?? 
                   json['business_name'] ?? 
                   json['name'] ?? 
                   json['full_name'] ?? 
                   json['display_name'] ?? 
                   '').toString();

    String mob = (json['customer_phone'] ?? 
                  json['mobile_no'] ?? 
                  json['mobile'] ?? 
                  json['phone'] ?? 
                  json['contact'] ?? 
                  json['contact_no'] ?? 
                  '').toString();

    String type = (json['customer_type'] ?? 
                   json['business_type'] ?? 
                   json['type'] ?? 
                   '').toString();

    String gst = (json['gst_no'] ?? 
                  json['gst'] ?? 
                  json['gstin'] ?? 
                  json['business_gst'] ??
                  json['tax_id'] ??
                  '').toString();

    String pan = (json['pan_no'] ?? 
                  json['pan'] ?? 
                  '').toString();

    var meta = json['customer_meta'] ?? json['meta'] ?? json['business_meta'] ?? json['meta_data'];
    String address = (json['address'] ?? json['location'] ?? json['addr'] ?? '').toString();
    String email = (json['email'] ?? json['email_id'] ?? json['mail'] ?? '').toString();

    if (meta is Map) {
      if (address.isEmpty || address == "null") {
        address = (meta['address'] ?? meta['location'] ?? meta['customer_address'] ?? '').toString();
      }
      if (email.isEmpty || email == "null") {
        email = (meta['email'] ?? meta['email_id'] ?? '').toString();
      }
    }

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
  final String variantId;      
  final String variantTypeId;  
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
