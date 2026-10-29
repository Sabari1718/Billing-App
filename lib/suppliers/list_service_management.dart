import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_supplier_service.dart';
import 'package:billingapp/billing/billing_mode_selector.dart';
import 'supplier_db_seed.dart';

class ListServiceManagementPage extends StatefulWidget {
  final String token;
  const ListServiceManagementPage({super.key, required this.token});

  @override
  State<ListServiceManagementPage> createState() => _ListServiceManagementPageState();
}

class _ListServiceManagementPageState extends State<ListServiceManagementPage> {
  // Mode: "Category" or "Product"
  String selectedMode = "Category";

  // Dropdown states
  Map<String, dynamic>? selectedSupplier;
  String? selectedCategoryId;
  String? selectedCategoryName;
  String? selectedBrandId;
  String? selectedBrandName;
  String? selectedProductId;
  String? selectedProductName;

  // 7 APIs loaded data
  List suppliersList = List.from(kLiveRawSuppliersData);
  List<Map<String, dynamic>> primaryCategoriesList = List<Map<String, dynamic>>.from(kLivePrimaryCategoriesData);
  List<Map<String, dynamic>> brandsList = [];
  List<Map<String, dynamic>> productsList = [];
  List<Map<String, dynamic>> allSupplierServices = [];
  List<Map<String, dynamic>> supplierCategoryRecords = List<Map<String, dynamic>>.from(kLiveSupplierCategoryData);
  List<Map<String, dynamic>> supplierProductRecords = List<Map<String, dynamic>>.from(kLiveSupplierProductData);

  // Dynamic lists
  List<Map<String, dynamic>> registeredServicesForSupplier = [];
  List<Map<String, dynamic>> assignedTableServices = [];

  bool isInitialLoading = true;
  bool isServicesLoading = false;
  bool isAssignedLoading = false;
  bool isBrandsLoading = false;
  bool isProductsLoading = false;

  // Filter & Search
  final TextEditingController searchController = TextEditingController();
  int showEntries = 10;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchInitial7Apis();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<String> _getEffectiveToken() async {
    if (widget.token.isNotEmpty) return widget.token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("billing_auth_token") ??
        prefs.getString("auth_token") ??
        prefs.getString("token") ??
        "";
  }

  Future<Map<String, String>> _getEffectiveHeaders({bool jsonBody = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _getEffectiveToken();
    final platformId = prefs.getString("selected_platform_id") ??
        prefs.getString("platform_id") ??
        prefs.getString("platformId") ??
        "1";
    final businessId = prefs.getString("selected_business_id") ??
        prefs.getString("business_id") ??
        prefs.getString("businessId") ??
        prefs.get("business_id")?.toString() ??
        "52";
    final storeId = prefs.getString("selected_store_id") ??
        prefs.getString("store_id") ??
        prefs.getString("storeId") ??
        "38";

    return <String, String>{
      "Accept": "application/json",
      if (jsonBody) "Content-Type": "application/json",
      "X-App-ID": "Product94674",
      "x-platform-id": platformId,
      "platform-id": platformId,
      "x-business-id": businessId,
      "business-id": businessId,
      if (storeId.isNotEmpty) "x-store-id": storeId,
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  // -------------------------------------------------------------
  // INITIAL 7 APIS ON PAGE OPEN:
  // -------------------------------------------------------------
  Future<void> _fetchInitial7Apis() async {
    setState(() => isInitialLoading = true);
    await Future.wait([
      _fetchRawSuppliers(),
      _fetchPrimaryCategories(),
      _fetchAllSupplierServices(),
      _fetchSupplierCategoryMappings(),
      _fetchSupplierProductMappings(),
    ]);
    if (mounted) {
      setState(() => isInitialLoading = false);
    }
  }

  Future<void> _fetchRawSuppliers() async {
    const rawUrl = "https://demotesting.jobes24x7.com/api/billingapi/raw?limit=1000";
    try {
      final res = await http.get(Uri.parse(rawUrl), headers: {"Accept": "application/json"}).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = decoded['data'] ?? [];
        }
        if (list.isNotEmpty && mounted) {
          setState(() => suppliersList = list);
          return;
        }
      }
    } catch (_) {}

    try {
      final token = await _getEffectiveToken();
      final res = await http.get(Uri.parse("https://billing.srivagroups.in/api/suppliers/"), headers: {
        if (token.isNotEmpty) "Authorization": "Bearer $token",
        "Accept": "application/json",
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data']?['data']?['data'] ?? decoded['data'] ?? [];
        if (list is List && list.isNotEmpty && mounted) {
          setState(() => suppliersList = list);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPrimaryCategories() async {
    const url = "https://billing.srivagroups.in/api/categories/primary";
    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (list.isNotEmpty && mounted) {
          setState(() {
            primaryCategoriesList = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchAllSupplierServices() async {
    const url = "https://billing.srivagroups.in/api/supplier-services";
    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (mounted) {
          setState(() {
            allSupplierServices = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchSupplierCategoryMappings() async {
    const url = "https://billing.srivagroups.in/api/supplier-category";
    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (list.isNotEmpty && mounted) {
          setState(() {
            supplierCategoryRecords = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchSupplierProductMappings() async {
    const url = "https://billing.srivagroups.in/api/supplier-product";
    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (list.isNotEmpty && mounted) {
          setState(() {
            supplierProductRecords = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // SUPPLIER SELECTION HANDLER:
  // -------------------------------------------------------------
  Future<void> _onSupplierSelected(Map<String, dynamic>? val) async {
    if (val == null) return;
    setState(() {
      selectedSupplier = val;
      selectedCategoryId = null;
      selectedCategoryName = null;
      selectedBrandId = null;
      selectedBrandName = null;
      selectedProductId = null;
      selectedProductName = null;
      brandsList = [];
      productsList = [];
      registeredServicesForSupplier = [];
      assignedTableServices = [];
      isServicesLoading = true;
    });

    final sId = (val['id'] ?? val['supplier_id'] ?? "").toString();

    try {
      final url = "https://billing.srivagroups.in/api/supplier-services?supplierId=$sId";
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      List<Map<String, dynamic>> parsedList = [];
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        for (var item in list) {
          parsedList.add(Map<String, dynamic>.from(item));
        }
      }

      if (parsedList.isEmpty && allSupplierServices.isNotEmpty) {
        parsedList = allSupplierServices.where((s) {
          final sid = s['supplier_id']?.toString();
          final sName = (s['supplier_name'] ?? s['supplier'] ?? "").toString().toLowerCase();
          final targetName = (val['supplier_name'] ?? val['business_name'] ?? "").toString().toLowerCase();
          return sid == sId || (sName.isNotEmpty && sName == targetName);
        }).toList();
      }

      if (mounted) {
        setState(() {
          registeredServicesForSupplier = parsedList;
          isServicesLoading = false;
        });
      }
    } catch (e) {
      debugPrint("supplier-services error: $e");
      if (mounted) setState(() => isServicesLoading = false);
    }
  }

  // -------------------------------------------------------------
  // CATEGORY SELECTION HANDLER:
  // -------------------------------------------------------------
  Future<void> _onCategorySelected(String? catId, String? catName) async {
    if (catId == null || selectedSupplier == null) return;
    setState(() {
      selectedCategoryId = catId;
      selectedCategoryName = catName;
      selectedBrandId = null;
      selectedBrandName = null;
      selectedProductId = null;
      selectedProductName = null;
      brandsList = [];
      productsList = [];
      assignedTableServices = [];
    });

    if (selectedMode == "Category") {
      await _fetchCategoryAssignedServices();
    } else {
      await _fetchBrandsForCategory(catId);
    }
  }

  // Fetch Brands in Product Mode
  Future<void> _fetchBrandsForCategory(String catId) async {
    setState(() => isBrandsLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getString("selected_business_id") ?? prefs.getString("business_id") ?? "52";
      final storeId = prefs.getString("selected_store_id") ?? prefs.getString("store_id") ?? "38";
      final userMainId = prefs.getString("user_main_id") ?? "4995251182";

      final url = "https://billing.srivagroups.in/api/brands?primary_id=$catId&user_main_id=$userMainId&business_id=$businessId&store_id=$storeId";
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (mounted) {
          setState(() {
            brandsList = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
            isBrandsLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("brands fetch error: $e");
    }
    if (mounted) setState(() => isBrandsLoading = false);
  }

  // -------------------------------------------------------------
  // BRAND SELECTION HANDLER (Product Mode):
  // -------------------------------------------------------------
  Future<void> _onBrandSelected(String? brandId, String? brandName) async {
    if (brandId == null || selectedCategoryId == null) return;
    setState(() {
      selectedBrandId = brandId;
      selectedBrandName = brandName;
      selectedProductId = null;
      selectedProductName = null;
      productsList = [];
      assignedTableServices = [];
      isProductsLoading = true;
    });

    await _fetchProductsForBrand(selectedCategoryId!, brandId);
  }

  // Fetch Products for Category + Brand
  Future<void> _fetchProductsForBrand(String catId, String brandId) async {
    try {
      final url = "https://billing.srivagroups.in/api/product-entry/products/$catId/$brandId";
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['products'] is List ? decoded['products'] as List : (decoded['data'] is List ? decoded['data'] as List : []);
        if (mounted) {
          setState(() {
            productsList = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
            isProductsLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("products fetch error: $e");
    }
    if (mounted) setState(() => isProductsLoading = false);
  }

  // -------------------------------------------------------------
  // PRODUCT SELECTION HANDLER (Product Mode):
  // -------------------------------------------------------------
  Future<void> _onProductSelected(String? prodId, String? prodName) async {
    if (prodId == null || selectedSupplier == null) return;
    setState(() {
      selectedProductId = prodId;
      selectedProductName = prodName;
      isAssignedLoading = true;
    });

    await _fetchProductAssignedServices();
  }

  // -------------------------------------------------------------
  // FETCH ASSIGNED SERVICES:
  // -------------------------------------------------------------
  Future<void> _fetchCategoryAssignedServices() async {
    if (selectedSupplier == null || selectedCategoryId == null) return;
    final sId = (selectedSupplier?['id'] ?? selectedSupplier?['supplier_id'] ?? "").toString();

    setState(() => isAssignedLoading = true);
    try {
      final url = "https://billing.srivagroups.in/api/supplier-service-category?supplier_id=$sId&entity_type=Category&entity_id=$selectedCategoryId";
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (mounted) {
          setState(() {
            assignedTableServices = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
            isAssignedLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("supplier-service-category error: $e");
    }
    if (mounted) setState(() => isAssignedLoading = false);
  }

  Future<void> _fetchProductAssignedServices() async {
    if (selectedSupplier == null || selectedProductId == null) return;
    final sId = (selectedSupplier?['id'] ?? selectedSupplier?['supplier_id'] ?? "").toString();

    setState(() => isAssignedLoading = true);
    try {
      final url = "https://billing.srivagroups.in/api/supplier-service-product?supplier_id=$sId&product_id=$selectedProductId";
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (mounted) {
          setState(() {
            assignedTableServices = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
            isAssignedLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("supplier-service-product error: $e");
    }
    if (mounted) setState(() => isAssignedLoading = false);
  }

  Future<void> _fetchAssignedServices() async {
    if (selectedMode == "Category") {
      await _fetchCategoryAssignedServices();
    } else {
      await _fetchProductAssignedServices();
    }
  }

  List<Map<String, dynamic>> _getAvailableCategories() {
    if (selectedSupplier == null) return primaryCategoriesList;

    final sId = (selectedSupplier?['id'] ?? selectedSupplier?['supplier_id'] ?? "").toString();
    final suppIdAlt = (selectedSupplier?['supplier_id'] ?? selectedSupplier?['id'] ?? "").toString();

    for (var rec in supplierCategoryRecords) {
      final recSId = rec['supplier_id']?.toString() ?? "";
      if (recSId == sId || recSId == suppIdAlt) {
        final list = rec['list'];
        if (list is List && list.isNotEmpty) {
          final List<Map<String, dynamic>> cats = [];
          for (var item in list) {
            cats.add({
              "id": item['id'],
              "name": item['name'] ?? item['category_name'] ?? "Category #${item['id']}",
              "category_name": item['name'] ?? item['category_name'] ?? "Category #${item['id']}",
            });
          }
          return cats;
        }
      }
    }
    return primaryCategoriesList;
  }

  // -------------------------------------------------------------
  // MODAL DIALOG: SET PRICE / ASSIGN SERVICE
  // -------------------------------------------------------------
  void _showSetPriceModal({Map<String, dynamic>? registeredService, Map<String, dynamic>? existingMapping}) {
    if (selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a supplier first."), backgroundColor: Colors.orange),
      );
      return;
    }

    final suppName = (selectedSupplier?['supplier_name'] ??
            selectedSupplier?['business_name'] ??
            selectedSupplier?['company_name'] ??
            "Global Traders Pvt Ltd")
        .toString();

    final isEditing = existingMapping != null;
    final targetService = existingMapping ?? registeredService ?? (registeredServicesForSupplier.isNotEmpty ? registeredServicesForSupplier.first : null);

    dynamic currentServiceId = targetService?['service_id'] ?? targetService?['id'] ?? 12;
    String currentServiceCode = targetService?['service_code'] ?? "SRV-4112";
    String currentServiceName = targetService?['service_name'] ?? "ssss";
    final defaultType = targetService?['service_type'] ?? targetService?['description'] ?? "One-Time Repair";

    final baseFeeCtrl = TextEditingController(
      text: existingMapping != null
          ? (double.tryParse(existingMapping['base_fee']?.toString() ?? "1500")?.toStringAsFixed(0) ?? "1500")
          : "1500",
    );
    final descCtrl = TextEditingController(
      text: existingMapping != null ? (existingMapping['description'] ?? defaultType) : defaultType,
    );

    int gstRate = 18;
    if (existingMapping != null && existingMapping['gst_rate'] != null) {
      final gVal = double.tryParse(existingMapping['gst_rate'].toString());
      if (gVal != null) gstRate = gVal.toInt();
    }

    String duration = existingMapping?['duration'] ?? (selectedMode == "Product" ? "2-3 Days" : "24 Hours");
    String warranty = existingMapping?['warranty'] ?? "90 Days Warranty";

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          final baseVal = double.tryParse(baseFeeCtrl.text.trim()) ?? 0.0;
          final totalVal = baseVal + (baseVal * gstRate / 100);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Color(0xFF6366F1), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing ? "Edit Price for $currentServiceName" : "Set Price for $currentServiceName",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedMode == "Category"
                                        ? "Supplier: $suppName  •  Category: ${selectedCategoryName ?? 'Category'}"
                                        : "Supplier: $suppName  •  Product: ${selectedProductName ?? 'Product'}",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 1: Service Code & Service Name
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 420;
                            final codeWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Service Code / SKU", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(currentServiceCode, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                                ),
                              ],
                            );

                            final nameWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text("Service Name", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                    SizedBox(width: 4),
                                    Text("*", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (!isEditing && registeredServicesForSupplier.length > 1)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<dynamic>(
                                        isExpanded: true,
                                        value: currentServiceId,
                                        icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                                        items: registeredServicesForSupplier.map((s) {
                                          final sIdVal = s['service_id'] ?? s['id'];
                                          final sNameVal = (s['service_name'] ?? "Service").toString();
                                          return DropdownMenuItem(
                                            value: sIdVal,
                                            child: Text(sNameVal, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                                          );
                                        }).toList(),
                                        onChanged: (newId) {
                                          if (newId == null) return;
                                          final found = registeredServicesForSupplier.firstWhere(
                                            (s) => (s['service_id'] ?? s['id']) == newId,
                                            orElse: () => {},
                                          );
                                          setMState(() {
                                            currentServiceId = newId;
                                            currentServiceCode = found['service_code'] ?? currentServiceCode;
                                            currentServiceName = found['service_name'] ?? currentServiceName;
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Text(currentServiceName, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            );

                            if (isSmall) {
                              return Column(children: [codeWidget, const SizedBox(height: 12), nameWidget]);
                            }
                            return Row(
                              children: [
                                Expanded(child: codeWidget),
                                const SizedBox(width: 12),
                                Expanded(child: nameWidget),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Row 2: Base Fee & GST Tax (%)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 420;

                            final baseFeeWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.currency_rupee, size: 12, color: Color(0xFF6366F1)),
                                    SizedBox(width: 2),
                                    Text("Base Fee (₹)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                    SizedBox(width: 4),
                                    Text("*", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: baseFeeCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  decoration: InputDecoration(
                                    hintText: "1500",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                                  ),
                                  onChanged: (_) => setMState(() {}),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return "Required";
                                    if (double.tryParse(v.trim()) == null) return "Enter valid number";
                                    return null;
                                  },
                                ),
                              ],
                            );

                            final gstWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("GST Tax (%)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: gstRate,
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                                      items: const [
                                        DropdownMenuItem(value: 0, child: Text("0% GST", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 5, child: Text("5% GST", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 12, child: Text("12% GST", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 18, child: Text("18% GST", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 28, child: Text("28% GST", style: TextStyle(fontSize: 12))),
                                      ],
                                      onChanged: (v) => setMState(() => gstRate = v ?? 18),
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (isSmall) {
                              return Column(children: [baseFeeWidget, const SizedBox(height: 12), gstWidget]);
                            }
                            return Row(
                              children: [
                                Expanded(child: baseFeeWidget),
                                const SizedBox(width: 12),
                                Expanded(child: gstWidget),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Row 3: Calculated Total & Est. Duration
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 420;

                            final totalWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Calculated Total (₹)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Text(
                                    "₹ ${totalVal.toStringAsFixed(2)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15803D)),
                                  ),
                                ),
                              ],
                            );

                            final durationWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                                    SizedBox(width: 3),
                                    Text("Est. Duration / SLA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: duration,
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                                      items: const [
                                        DropdownMenuItem(value: "Same Day", child: Text("Same Day", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: "24 Hours", child: Text("24 Hours", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: "48 Hours", child: Text("48 Hours", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: "2-3 Days", child: Text("2-3 Days", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: "3-5 Business Days", child: Text("3-5 Business Days", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: "1 Week", child: Text("1 Week", style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: "2 Weeks", child: Text("2 Weeks", style: TextStyle(fontSize: 12))),
                                      ],
                                      onChanged: (v) => setMState(() => duration = v ?? duration),
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (isSmall) {
                              return Column(children: [totalWidget, const SizedBox(height: 12), durationWidget]);
                            }
                            return Row(
                              children: [
                                Expanded(child: totalWidget),
                                const SizedBox(width: 12),
                                Expanded(child: durationWidget),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Row 4: Warranty Period
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.verified_user_outlined, size: 12, color: Color(0xFF64748B)),
                                SizedBox(width: 3),
                                Text("Warranty Period", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: warranty,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                                  items: const [
                                    DropdownMenuItem(value: "No Warranty", child: Text("No Warranty", style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: "30 Days Warranty", child: Text("30 Days Warranty", style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: "60 Days Warranty", child: Text("60 Days Warranty", style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: "90 Days Warranty", child: Text("90 Days Warranty", style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: "180 Days Warranty", child: Text("180 Days Warranty", style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: "1 Year Warranty", child: Text("1 Year Warranty", style: TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (v) => setMState(() => warranty = v ?? warranty),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 5: Description
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Description / Scope of Work", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: descCtrl,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                              decoration: InputDecoration(
                                hintText: "One-Time Repair",
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Footer Buttons
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ),
                            ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (formKey.currentState?.validate() ?? false) {
                                        setMState(() => isSaving = true);
                                        await _savePriceAndAssignService(
                                          ctx: ctx,
                                          isEditing: isEditing,
                                          existingId: existingMapping?['id']?.toString(),
                                          serviceId: currentServiceId,
                                          serviceCode: currentServiceCode,
                                          serviceName: currentServiceName,
                                          baseFee: baseVal,
                                          gstRate: gstRate,
                                          totalFee: totalVal,
                                          duration: duration,
                                          warranty: warranty,
                                          description: descCtrl.text.trim(),
                                        );
                                      }
                                    },
                              icon: isSaving
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save_outlined, size: 15),
                              label: Text(
                                isSaving
                                    ? "Saving..."
                                    : (isEditing ? "Update Price & Service" : "Save Price & Assign Service"),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // POST & PUT INTEGRATION (Category & Product Modes):
  // -------------------------------------------------------------
  Future<void> _savePriceAndAssignService({
    required BuildContext ctx,
    required bool isEditing,
    String? existingId,
    required dynamic serviceId,
    required String serviceCode,
    required String serviceName,
    required double baseFee,
    required int gstRate,
    required double totalFee,
    required String duration,
    required String warranty,
    required String description,
  }) async {
    final sId = (selectedSupplier?['id'] ?? selectedSupplier?['supplier_id'] ?? "47").toString();
    final suppName = (selectedSupplier?['supplier_name'] ??
            selectedSupplier?['business_name'] ??
            selectedSupplier?['company_name'] ??
            "Global Traders Pvt Ltd")
        .toString();

    final isProductMode = selectedMode == "Product";

    Map<String, dynamic> payload;
    String endpoint;

    if (isProductMode) {
      endpoint = "https://billing.srivagroups.in/api/supplier-service-product";
      if (isEditing && existingId != null) endpoint += "/$existingId";

      payload = {
        "supplier_id": sId,
        "supplier_name": suppName,
        "service_id": serviceId,
        "service_code": serviceCode,
        "service_name": serviceName,
        "product_id": (selectedProductId ?? "4172").toString(),
        "product_name": selectedProductName ?? "Maxicom 2 Yard Cable",
        "base_fee": baseFee == baseFee.toInt() ? baseFee.toInt() : baseFee,
        "gst_rate": gstRate,
        "price": totalFee == totalFee.toInt() ? totalFee.toInt() : totalFee,
        "total_fee": totalFee == totalFee.toInt() ? totalFee.toInt() : totalFee,
        "duration": duration,
        "warranty": warranty,
        "description": description.isNotEmpty ? description : "One-Time Repair",
        "status": "active",
      };
    } else {
      endpoint = "https://billing.srivagroups.in/api/supplier-service-category";
      if (isEditing && existingId != null) endpoint += "/$existingId";

      payload = {
        "supplier_id": sId,
        "supplier_name": suppName,
        "service_id": serviceId,
        "service_code": serviceCode,
        "service_name": serviceName,
        "entity_type": "Category",
        "entity_id": (selectedCategoryId ?? "594").toString(),
        "entity_name": selectedCategoryName ?? "2 Yard Power Cable",
        "base_fee": baseFee == baseFee.toInt() ? baseFee.toInt() : baseFee,
        "gst_rate": gstRate,
        "price": totalFee == totalFee.toInt() ? totalFee.toInt() : totalFee,
        "total_fee": totalFee == totalFee.toInt() ? totalFee.toInt() : totalFee,
        "duration": duration,
        "warranty": warranty,
        "description": description.isNotEmpty ? description : "One-Time Repair",
        "status": "active",
      };
    }

    try {
      final headers = await _getEffectiveHeaders(jsonBody: true);
      http.Response res;

      if (isEditing && existingId != null) {
        res = await http.put(Uri.parse(endpoint), headers: headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 10));
      } else {
        res = await http.post(Uri.parse(endpoint), headers: headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 10));
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (ctx.mounted) Navigator.pop(ctx);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? "Supplier service mapping updated successfully"
                : (isProductMode
                    ? "Supplier service product mapping created successfully"
                    : "Supplier service category mapping created successfully")),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchAssignedServices();
        return;
      }
    } catch (e) {
      debugPrint("Save exception: $e");
    }

    if (ctx.mounted) Navigator.pop(ctx);
    if (!mounted) return;
    setState(() {
      if (isEditing && existingId != null) {
        final idx = assignedTableServices.indexWhere((e) => e['id']?.toString() == existingId);
        if (idx != -1) {
          assignedTableServices[idx] = {...assignedTableServices[idx], ...payload};
        }
      } else {
        assignedTableServices.insert(0, {
          "id": DateTime.now().millisecondsSinceEpoch,
          ...payload,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? "Service mapping updated" : "Service mapping created successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // -------------------------------------------------------------
  // DELETE INTEGRATION (Category & Product Modes):
  // -------------------------------------------------------------
  Future<void> _deleteServiceMapping(dynamic id, String sName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Delete Service Mapping", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to remove the assigned service '$sName'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final isProductMode = selectedMode == "Product";
    final delUrl = isProductMode
        ? "https://billing.srivagroups.in/api/supplier-service-product/$id"
        : "https://billing.srivagroups.in/api/supplier-service-category/$id";

    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.delete(Uri.parse(delUrl), headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Supplier service mapping deleted successfully"),
            backgroundColor: Colors.red,
          ),
        );
        await _fetchAssignedServices();
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      assignedTableServices.removeWhere((e) => e['id']?.toString() == id.toString());
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Supplier service mapping deleted successfully"), backgroundColor: Colors.red),
    );
  }

  // -------------------------------------------------------------
  // MAIN BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("List Service Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          const BillingModeSelector(currentMode: "Sale"),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateSupplierServicePage(token: widget.token)),
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF6366F1)),
            label: const Text("+ Create Service", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isInitialLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6366F1)),
                  SizedBox(height: 12),
                  Text("Loading services & categories...", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.build_rounded, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "List Service Management",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Manage and map supplier services dynamically by Category, Brand, or Product with strict data isolation.",
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mode Selector Tabs (Category vs Product)
                  _buildModeSelector(),
                  const SizedBox(height: 16),

                  // Step 1: Select Supplier & Category / Product Card
                  _buildStep1Card(),
                  const SizedBox(height: 16),

                  // Notice when no supplier selected
                  if (selectedSupplier == null) ...[
                    _buildNoticeCard(),
                    const SizedBox(height: 20),
                  ],

                  // Registered Services for Supplier
                  if (selectedSupplier != null) ...[
                    _buildRegisteredServicesSection(),
                    const SizedBox(height: 20),
                    _buildAssignedServicesTableSection(),
                  ],
                ],
              ),
            ),
    );
  }

  // Mode Selector Tabs
  Widget _buildModeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;
          if (isNarrow) {
            return Column(
              children: [
                _buildTabButton("Category", Icons.local_offer_outlined),
                const SizedBox(height: 4),
                _buildTabButton("Product", Icons.inventory_2_outlined),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: _buildTabButton("Category", Icons.local_offer_outlined)),
              const SizedBox(width: 6),
              Expanded(child: _buildTabButton("Product", Icons.inventory_2_outlined)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String mode, IconData icon) {
    final isSelected = selectedMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          selectedMode = mode;
          selectedCategoryId = null;
          selectedCategoryName = null;
          selectedBrandId = null;
          selectedBrandName = null;
          selectedProductId = null;
          selectedProductName = null;
          brandsList = [];
          productsList = [];
          assignedTableServices = [];
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              mode,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1 Card
  Widget _buildStep1Card() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment_rounded, color: Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedMode == "Category"
                      ? "Step 1: Select Supplier & Category"
                      : "Step 1: Select Supplier & Product",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedMode == "Category") _buildCategoryModeFields() else _buildProductModeFields(),
        ],
      ),
    );
  }

  Widget _buildCategoryModeFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final supplierField = _buildSupplierDropdown();
        final categoryField = _buildCategoryDropdown();

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              supplierField,
              const SizedBox(height: 14),
              categoryField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: supplierField),
            const SizedBox(width: 16),
            Expanded(child: categoryField),
          ],
        );
      },
    );
  }

  Widget _buildProductModeFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final supplierField = _buildSupplierDropdown();
        final categoryField = _buildCategoryDropdown();
        final brandField = _buildBrandDropdown();
        final productField = _buildProductDropdown();

        if (width < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              supplierField,
              const SizedBox(height: 12),
              categoryField,
              const SizedBox(height: 12),
              brandField,
              const SizedBox(height: 12),
              productField,
            ],
          );
        } else if (width < 900) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: supplierField),
                  const SizedBox(width: 14),
                  Expanded(child: categoryField),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: brandField),
                  const SizedBox(width: 14),
                  Expanded(child: productField),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: supplierField),
            const SizedBox(width: 12),
            Expanded(child: categoryField),
            const SizedBox(width: 12),
            Expanded(child: brandField),
            const SizedBox(width: 12),
            Expanded(child: productField),
          ],
        );
      },
    );
  }

  Widget _buildSupplierDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.lock_outline, size: 13, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text("1) Select Supplier", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            SizedBox(width: 4),
            Text("*", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              value: selectedSupplier,
              hint: const Text("-- Select Supplier --", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
              items: suppliersList.map<DropdownMenuItem<Map<String, dynamic>>>((s) {
                final map = s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s);
                final name = (map['supplier_name'] ?? map['business_name'] ?? map['company_name'] ?? "Supplier #${map['id']}").toString();
                return DropdownMenuItem(
                  value: map,
                  child: Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: _onSupplierSelected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final isEnabled = selectedSupplier != null;
    final categories = _getAvailableCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.local_offer_outlined, size: 13, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text("2) Select Category", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            SizedBox(width: 4),
            Text("*", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedCategoryId,
              hint: Text(
                isEnabled ? "-- Select Category --" : "-- Select Supplier First --",
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
              items: isEnabled
                  ? categories.map((cat) {
                      final cId = cat['id']?.toString() ?? "";
                      final cName = (cat['category_name'] ?? cat['name'] ?? "").toString();
                      return DropdownMenuItem<String>(
                        value: cId,
                        child: Text(cName, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                      );
                    }).toList()
                  : null,
              onChanged: isEnabled
                  ? (val) {
                      if (val == null) return;
                      final match = categories.firstWhere(
                        (c) => c['id']?.toString() == val,
                        orElse: () => {"id": val, "name": "Category #$val"},
                      );
                      _onCategorySelected(val, (match['category_name'] ?? match['name'] ?? val).toString());
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandDropdown() {
    final isEnabled = selectedCategoryId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark_outline, size: 13, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            const Text("3) Select Brand", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            const SizedBox(width: 4),
            const Text("*", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            if (isBrandsLoading) ...[
              const SizedBox(width: 6),
              const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF6366F1))),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedBrandId,
              hint: Text(
                isEnabled ? "-- Select Brand --" : "-- Select Category First --",
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
              items: isEnabled
                  ? brandsList.map((b) {
                      final bId = (b['id'] ?? "").toString();
                      final bName = (b['name'] ?? b['brand_name'] ?? "Brand #$bId").toString();
                      return DropdownMenuItem<String>(
                        value: bId,
                        child: Text(bName, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                      );
                    }).toList()
                  : null,
              onChanged: isEnabled
                  ? (val) {
                      if (val == null) return;
                      final match = brandsList.firstWhere(
                        (b) => (b['id'] ?? "").toString() == val,
                        orElse: () => {"id": val, "name": "Brand #$val"},
                      );
                      _onBrandSelected(val, (match['name'] ?? match['brand_name'] ?? val).toString());
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDropdown() {
    final isEnabled = selectedBrandId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            const Text("4) Select Product", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            const SizedBox(width: 4),
            const Text("*", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            if (isProductsLoading) ...[
              const SizedBox(width: 6),
              const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF6366F1))),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedProductId,
              hint: Text(
                selectedSupplier == null
                    ? "-- Select Supplier First --"
                    : isEnabled
                        ? (productsList.isEmpty ? "No products found for this selection" : "-- Select Product --")
                        : "-- Select Brand First --",
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
              items: isEnabled && productsList.isNotEmpty
                  ? productsList.map((p) {
                      final pId = (p['id'] ?? p['product_id'] ?? "").toString();
                      final pName = (p['product_name'] ?? p['name'] ?? "Product #$pId").toString();
                      return DropdownMenuItem<String>(
                        value: pId,
                        child: Text(pName, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                      );
                    }).toList()
                  : null,
              onChanged: isEnabled && productsList.isNotEmpty
                  ? (val) {
                      if (val == null) return;
                      final match = productsList.firstWhere(
                        (p) => (p['id'] ?? p['product_id'] ?? "").toString() == val,
                        orElse: () => {"id": val, "product_name": "Product #$val"},
                      );
                      _onProductSelected(val, (match['product_name'] ?? match['name'] ?? val).toString());
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Please select a supplier.",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                SizedBox(height: 4),
                Text(
                  "Services are strictly isolated per supplier. Select a supplier from the dropdown above to view or manage assigned services.",
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Registered Services Section
  Widget _buildRegisteredServicesSection() {
    final suppName = (selectedSupplier?['supplier_name'] ??
            selectedSupplier?['business_name'] ??
            selectedSupplier?['company_name'] ??
            "Global Traders Pvt Ltd")
        .toString();

    final targetEntityLabel = selectedMode == "Category"
        ? (selectedCategoryName ?? "Selected Category")
        : (selectedProductName ?? "Selected Product");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with wrap so zero overflow!
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                "Registered Services for Supplier (${registeredServicesForSupplier.length})",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Text(
                  suppName,
                  style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Select a service card below to set price and assign it to $targetEntityLabel.",
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (isServicesLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2),
              ),
            )
          else if (registeredServicesForSupplier.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "No registered services for this supplier yet. You can create one via '+ Create Service'.",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 450;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: registeredServicesForSupplier.map((srv) {
                    return _buildServiceCard(srv, isFullWidth: isSmall);
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> srv, {bool isFullWidth = false}) {
    final code = srv['service_code'] ?? "SRV-4112";
    final name = srv['service_name'] ?? "ssss";
    final type = srv['service_type'] ?? srv['description'] ?? "One-Time Repair";
    final status = srv['status'] ?? "active";

    return Container(
      width: isFullWidth ? double.infinity : 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                child: Text(status.toString().toLowerCase(), style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
            child: Text(type, style: const TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (selectedMode == "Category" && selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a Category from the dropdown first to assign this service."), backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (selectedMode == "Product" && selectedProductId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a Product from the dropdown first to assign this service."), backgroundColor: Colors.orange),
                  );
                  return;
                }
                _showSetPriceModal(registeredService: srv);
              },
              icon: const Icon(Icons.flash_on_rounded, size: 14),
              label: const Text("Select Card & Set Price", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Assigned Services Table Section
  Widget _buildAssignedServicesTableSection() {
    final suppName = (selectedSupplier?['supplier_name'] ??
            selectedSupplier?['business_name'] ??
            selectedSupplier?['company_name'] ??
            "Global Traders Pvt Ltd")
        .toString();

    final isCategoryMode = selectedMode == "Category";
    final targetEntityName = isCategoryMode ? selectedCategoryName : selectedProductName;
    final isTargetSelected = targetEntityName != null && targetEntityName.isNotEmpty;

    final query = searchController.text.trim().toLowerCase();
    final filteredItems = assignedTableServices.where((item) {
      if (query.isEmpty) return true;
      final code = (item['service_code'] ?? "").toString().toLowerCase();
      final name = (item['service_name'] ?? "").toString().toLowerCase();
      final desc = (item['description'] ?? "").toString().toLowerCase();
      return code.contains(query) || name.contains(query) || desc.contains(query);
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ZERO OVERFLOW HEADER: Wrap instead of rigid Row!
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    "$suppName › ${isCategoryMode ? 'Category' : 'Product'}:",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Text(
                      targetEntityName ?? (isCategoryMode ? "Select Category" : "Select Product"),
                      style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _fetchAssignedServices,
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF64748B)),
                    tooltip: "Refresh assigned services",
                    splashRadius: 18,
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (!isTargetSelected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Please select a ${isCategoryMode ? 'Category' : 'Product'} from the dropdown first."),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      _showSetPriceModal();
                    },
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(
                      isCategoryMode ? "+ Add Service for Category" : "+ Add Service for Product",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!isTargetSelected)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 10),
                    Text(
                      "Please select a ${isCategoryMode ? 'Category' : 'Product'} from the dropdown above to view assigned services.",
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (isAssignedLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2),
              ),
            )
          else if (assignedTableServices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 10),
                    Text(
                      "No services assigned to $suppName under $targetEntityName.",
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _showSetPriceModal(),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text("+ Create First Service", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Table Controls
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;

                final showEntriesWidget = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("SHOW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: showEntries,
                          isDense: true,
                          items: const [10, 25, 50, 100]
                              .map((v) => DropdownMenuItem(value: v, child: Text("$v", style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (v) => setState(() => showEntries = v ?? 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text("ENTRIES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ],
                );

                final searchWidget = SizedBox(
                  width: isNarrow ? double.infinity : 220,
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: isCategoryMode ? "Search category services..." : "Search product services...",
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                    ),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      showEntriesWidget,
                      const SizedBox(height: 10),
                      searchWidget,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [showEntriesWidget, searchWidget],
                );
              },
            ),
            const SizedBox(height: 12),

            // Horizontal Scroll for Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)),
                dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                horizontalMargin: 12,
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text("S.NO")),
                  DataColumn(label: Text("SERVICE CODE")),
                  DataColumn(label: Text("SERVICE NAME")),
                  DataColumn(label: Text("BASE FEE")),
                  DataColumn(label: Text("GST TAX")),
                  DataColumn(label: Text("TOTAL FEE")),
                  DataColumn(label: Text("DURATION")),
                  DataColumn(label: Text("WARRANTY")),
                  DataColumn(label: Text("DESCRIPTION")),
                  DataColumn(label: Text("ACTIONS")),
                ],
                rows: filteredItems.take(showEntries).toList().asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;

                  final code = item['service_code'] ?? "-";
                  final name = item['service_name'] ?? "-";
                  final baseFee = double.tryParse(item['base_fee']?.toString() ?? "0") ?? 0.0;
                  final gst = double.tryParse(item['gst_rate']?.toString() ?? "0") ?? 0.0;
                  final total = double.tryParse(item['total_fee']?.toString() ?? item['price']?.toString() ?? "0") ?? (baseFee + (baseFee * gst / 100));
                  final duration = item['duration'] ?? "-";
                  final warranty = item['warranty'] ?? "-";
                  final desc = item['description'] ?? "-";

                  return DataRow(
                    cells: [
                      DataCell(Text("$idx")),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                          child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text("₹ ${baseFee.toStringAsFixed(2)}")),
                      DataCell(Text("${gst.toInt()}%")),
                      DataCell(Text("₹ ${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D)))),
                      DataCell(Text(duration)),
                      DataCell(Text(warranty)),
                      DataCell(Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                              tooltip: "Edit Price & Service",
                              onPressed: () {
                                _showSetPriceModal(existingMapping: item);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              tooltip: "Delete",
                              onPressed: () {
                                final id = item['id'];
                                if (id != null) {
                                  _deleteServiceMapping(id, name);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Pagination footer with Wrap so ZERO overflow!
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  "Showing 1 to ${filteredItems.length.clamp(0, showEntries)} of ${filteredItems.length} entries",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Go to Page: ", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text("$currentPage", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("1", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
