import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

class StockEntryPage extends StatefulWidget {
  const StockEntryPage({super.key});

  @override
  _StockEntryPageState createState() => _StockEntryPageState();
}

class _StockEntryPageState extends State<StockEntryPage> {
  List suppliers = [];
  List products = [];

  String? selectedSupplier;
  String? selectedProduct;

  int? currentMin;
  int? currentMax;
  bool isOneTimeOrder = false;

  // 🔥 Controllers moved to State level (Requirement 1, 2)
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController variantQtyController = TextEditingController();
  final TextEditingController buyingController = TextEditingController();
  final TextEditingController profitController = TextEditingController();
  final TextEditingController sellingController = TextEditingController();
  final TextEditingController distQtyController = TextEditingController();
  
  // 🔥 Notifiers for localized UI updates
  final ValueNotifier<String> sellingPriceNotifier = ValueNotifier<String>("0.00");

  String token = "";
  bool isSaving = false;

  Map<String, String> get headers =>
      {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      };

  List<Map<String, dynamic>> variants = [];
  bool isLoadingVariants = false;

  Future<void> fetchVariants() async {
    if (!mounted) return;
    setState(() => isLoadingVariants = true);
    try {
      final url = "https://billing.srivagroups.in/api/variant-master";
      AppLogger.info("FETCHING VARIANTS FROM: $url");
      final res = await http.get(Uri.parse(url), headers: headers);

      AppLogger.info("VARIANT API RESPONSE CODE: ${res.statusCode}");
      AppLogger.info("VARIANT API RESPONSE BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        dynamic data = decoded['data'];

        // Handle nested data formats
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['data'] is List) {
          list = data['data'];
        }

        if (mounted) {
          setState(() {
            variants = list.map((e) => e as Map<String, dynamic>).toList();
            variantTabData.clear();
            stockTabData.clear();
            for (var v in variants) {
              int id = int.tryParse(v['id'].toString()) ?? 0;
              variantTabData[id] =
              {'qty': '', 'buying': '', 'profit': '', 'selling': ''};
              stockTabData[id] = [];
            }
          });
        }
        AppLogger.info("PARSED VARIANTS: $variants");
      }
    } catch (e) {
      AppLogger.error("Error fetching variants", e);
    } finally {
      if (mounted) setState(() => isLoadingVariants = false);
    }
  }

  List<Map<String, dynamic>> stockTypes = [];
  bool isLoadingStockTypes = false;
  String? currentBusinessId;

  Future<void> fetchStockTypes() async {
    if (stockTypes.isNotEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    currentBusinessId = prefs.get("business_id")?.toString();

    AppLogger.info("STOCK TYPES FETCH START (Business ID: $currentBusinessId)");
    if (mounted) setState(() => isLoadingStockTypes = true);
    try {
      final url = "https://billing.srivagroups.in/api/stockTypes";
      final res = await http.get(Uri.parse(url), headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        AppLogger.info("RAW STOCK TYPES RESPONSE: $decoded");

        dynamic data = decoded['data'];

        List<dynamic> list = [];
        if (data is List)
          list = data;
        else if (data is Map) {
          if (data['data'] is List)
            list = data['data'];
          else if (data['stockTypes'] is List)
            list = data['stockTypes'];
          else
            list = [data];
        } else if (decoded['stockTypes'] is List) {
          list = decoded['stockTypes'];
        }

        final uniqueNames = <String>{};
        if (mounted) {
          setState(() {
            stockTypes = list.where((e) {
              final bId = e['business_id']?.toString();
              
              // 1. Deleted check (Requirement 1)
              if (e['deleted_at'] != null) return false;

              // 2. Business Isolation check
              if (currentBusinessId != null && bId != null && bId != "0" && bId != "" && bId != currentBusinessId) {
                return false;
              }

              final name = (e['name'] ?? '')
                  .toString()
                  .replaceAll('\r', '')
                  .replaceAll('\n', '')
                  .trim();
              if (uniqueNames.contains(name)) return false;
              uniqueNames.add(name);
              return true;
            }).map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              map['name'] = (map['name'] ?? '')
                  .toString()
                  .replaceAll('\r', '')
                  .replaceAll('\n', '')
                  .trim();
              return map;
            }).toList();

            AppLogger.info("FILTERED STOCK TYPES: ${stockTypes.map((e) => "${e['id']}:${e['name']} (BID:${e['business_id']})").toList()}");
          });
        }
        AppLogger.info("STOCK TYPES FETCH SUCCESS: ${stockTypes.length} items");
      }
    } catch (e) {
      AppLogger.error("Error fetching stock types", e);
    } finally {
      if (mounted) setState(() => isLoadingStockTypes = false);
    }
  }

  @override
  void dispose() {
    qtyController.dispose();
    variantQtyController.dispose();
    buyingController.dispose();
    profitController.dispose();
    sellingController.dispose();
    distQtyController.dispose();
    sellingPriceNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initToken();
  }

  Future<void> _initToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ FIX: Safe SharedPreferences fetch (handles any runtime type mismatches gracefully)
      final rawToken1 = prefs.get("token");
      final rawToken2 = prefs.get("auth_token");

      final String safeToken = (rawToken1?.toString()) ??
          (rawToken2?.toString()) ?? "";


      if (mounted) {
        setState(() {
          token = safeToken;
        });
      }

      await loadData();
      await fetchVariants();
      await fetchStockTypes();
    } catch (e) {
      AppLogger.error("Token initialization error", e);
    }
  }

  Future<void> saveStock() async {
    // Helper for safe integer parsing (Requirement 8)
    int parseQty(dynamic value) {
      if (value == null) return 0;
      final s = value.toString().trim();
      if (s.isEmpty) return 0;
      return int.tryParse(s) ?? 0;
    }

    // Clear previous state (Requirement 6, 10)
    ScaffoldMessenger.of(context).clearSnackBars();

    AppLogger.info("------------------------------------------");
    AppLogger.info("VALIDATION STARTED");

    // 1. Basic Field Validation
    if (selectedSupplier == null || selectedProduct == null ||
        qtyController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please complete all selections first")));
      AppLogger.error("VALIDATION FAILED: Missing basic selections");
      return;
    }

    int totalQty = parseQty(qtyController.text);
    if (totalQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Quantity must be greater than 0")));
      AppLogger.error("VALIDATION FAILED: Qty <= 0");
      return;
    }

    // 2. Total Variant Qty Validation
    int variantTotalSum = 0;
    variantTabData.forEach((key, value) {
      variantTotalSum += parseQty(value['qty']);
    });

    if (variantTotalSum != totalQty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Variant total ($variantTotalSum) does not match main quantity ($totalQty)"),
        backgroundColor: Colors.orange,
      ));
      AppLogger.error(
          "VALIDATION FAILED: Variant total mismatch ($variantTotalSum != $totalQty)");
      return;
    }

    // 3. Stock Distribution Validation with Structured Debugging
    bool distributionPassed = true;
    for (var variant in variants) {
      int id = int.tryParse(variant['id'].toString()) ?? 0;
      int vQty = parseQty(variantTabData[id]?['qty']);

      if (vQty > 0) {
        List<Map<String, dynamic>> distList = stockTabData[id] ?? [];
        int distributedTotal = distList.fold(
            0, (sum, item) => sum + parseQty(item['qty']));

        String variantName = variant['name'] ?? "Variant $id";

        AppLogger.info("Variant ID $id ($variantName) Check:");
        AppLogger.info("  Variant Qty       = $vQty");
        AppLogger.info("  Total Distributed = $distributedTotal");

        if (distributedTotal != vQty) {
          AppLogger.error(
              "Variant ID $id mismatch: Expected = $vQty, Received Distribution Total = $distributedTotal");

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "$variantName stock distribution total ($distributedTotal) must be $vQty"),
              backgroundColor: Colors.redAccent,
            ));
          }
          distributionPassed = false;
          break;
        }
      }
    }

    if (!distributionPassed) {
      AppLogger.error("VALIDATION FAILED: Distribution mismatch");
      return;
    }

    // 4. Stock Type ID Integrity Validation (Requirement 3, 5, 6, 8)
    bool stockTypeValid = true;
    final availableTypeIds = stockTypes.map((e) => int.tryParse(e['id'].toString()) ?? -1).toSet();

    AppLogger.info("AVAILABLE STOCK TYPE IDs: $availableTypeIds");

    for (var entry in stockTabData.entries) {
      int vId = entry.key;
      List<Map<String, dynamic>> dists = entry.value;

      // Only validate if this variant has quantity
      int vQty = parseQty(variantTabData[vId]?['qty']);
      if (vQty <= 0) continue;

      for (var d in dists) {
        int sTypeId = int.tryParse(d['stock_type_id'].toString()) ?? -1;
        AppLogger.info("CHECKING ID: $sTypeId for Variant $vId");

        if (!availableTypeIds.contains(sTypeId)) {
          stockTypeValid = false;
          AppLogger.error("INVALID STOCK TYPE ID: $sTypeId (Not in available list)");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Invalid or stale stock type selected ($sTypeId). Please re-select."),
              backgroundColor: Colors.red,
            ));
          }
          break;
        }
      }
      if (!stockTypeValid) break;
    }

    if (!stockTypeValid) {
      AppLogger.error("VALIDATION FAILED: Invalid stock_type_id detected");
      return;
    }

    // 5. Min/Max Validation
    if (currentMin != null && totalQty < currentMin!) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Minimum allowed quantity is $currentMin")));
      AppLogger.error("VALIDATION FAILED: Below Min ($totalQty < $currentMin)");
      return;
    }
    if (!isOneTimeOrder && currentMax != null && totalQty > currentMax!) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Maximum allowed quantity is $currentMax")));
      AppLogger.error("VALIDATION FAILED: Above Max ($totalQty > $currentMax)");
      return;
    }

    AppLogger.success("VALIDATION PASSED");
    AppLogger.info("MAIN QTY: $totalQty");
    AppLogger.info("VARIANT TOTAL: $variantTotalSum");
    AppLogger.info("------------------------------------------");

    if (mounted) setState(() => isSaving = true);

    try {
      final url = "https://billing.srivagroups.in/api/stocks";


      // 🔥 Specific debug logs (Requirement: "Also before API payload add")
      print("QTY = '${qtyController.text}'");
      if (variantTabData.isNotEmpty) {
        final firstV = variantTabData.values.first;
        print("BUYING = '${firstV['buying']}'");
        print("SELLING = '${firstV['selling']}'");
        print("MARGIN = '${firstV['profit']}'");
      }

      final payload = {
        "supplier_id": int.tryParse(selectedSupplier.toString()) ?? 0,
        "product_id": int.tryParse(selectedProduct.toString()) ?? 0,
        "qty": int.tryParse(qtyController.text.trim()) ?? 0,
        "is_self_produced": 0,
        "is_one_time_order": isOneTimeOrder,
        "variants": variantTabData.entries.map((entry) {
          int vId = entry.key;
          var data = entry.value;
          int vQty = int.tryParse(data['qty'].toString().trim()) ?? 0;

          List<Map<String, dynamic>> distList = stockTabData[vId] ?? [];

          // ✨ Filter only valid distributions (Requirement 4)
          final distributions = distList
              .where((e) => (int.tryParse(e['qty'].toString().trim()) ?? 0) > 0)
              .map((e) {
            return {
              "stock_type_id": int.tryParse(e["stock_type_id"].toString()) ?? 0,
              "qty": int.tryParse(e["qty"].toString().trim()) ?? 0,
            };
          }).toList();

          // ⚠️ Strict Internal Validation (Requirement 3)
          final totalDistributed = distributions.fold(0, (sum, item) => sum + (item["qty"] as int));

          if (totalDistributed != vQty) {
            AppLogger.error("INTERNAL MISMATCH for variant $vId: $totalDistributed != $vQty");
          }

          double buyingD = double.tryParse(data['buying']?.toString().trim() ?? '0') ?? 0.0;
          double profitD = double.tryParse(data['profit']?.toString().trim() ?? '0') ?? 0.0;
          double sellingD = double.tryParse(data['selling']?.toString().trim() ?? '0') ?? 0.0;

          return {
            "variant_id": vId,
            "qty": vQty,
            "buying_price": buyingD == buyingD.toInt() ? buyingD.toInt() : buyingD,
            "profit_margin": profitD == profitD.toInt() ? profitD.toInt() : profitD,
            "selling_price": sellingD == sellingD.toInt() ? sellingD.toInt() : sellingD,
            "stock_types": distributions,
          };
        }).where((v) => (v['qty'] as int) > 0).toList(),
      };

      // 🔥 Added debug logs (Requirement 6)
      print("SELECTED STOCK TYPE ID: ${distQtyController.text}"); // Tracking current input
      print("FINAL PAYLOAD: ${jsonEncode(payload)}");

      AppLogger.info("FINAL API PAYLOAD: $payload");

      // ✨ API REQUEST LOGGING
      AppLogger.info("================ API REQUEST START ================");
      AppLogger.info("URL: $url");
      AppLogger.info("HEADERS: $headers");
      AppLogger.info("PAYLOAD: ${jsonEncode(payload)}");
      AppLogger.info("================ API REQUEST END ==================");

      final res = await http.post(
        Uri.parse(url),
        headers: {
          ...headers,
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      // ✨ API RESPONSE LOGGING
      AppLogger.info("================ API RESPONSE START ================");
      AppLogger.info("STATUS CODE: ${res.statusCode}");
      AppLogger.info("RESPONSE BODY: ${res.body}");
      AppLogger.info("================ API RESPONSE END ==================");

      final decoded = jsonDecode(res.body);

      // ✨ STRUCTURED DECODED LOGGING (Requirement 2)
      if (decoded is Map) {
        AppLogger.info("Decoded Success: ${decoded['success']}");
        AppLogger.info("Decoded Message: ${decoded['message']}");
        if (decoded['data'] != null) {
          AppLogger.info("Decoded Data: ${decoded['data']}");
          if (decoded['data']['stock_id'] != null) {
            AppLogger.success(
                "Stock ID Created: ${decoded['data']['stock_id']}");
          }
        }
      }

      if (res.statusCode == 200 || res.statusCode == 201 ||
          (decoded is Map && decoded['success'] == true)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Stock saved successfully"),
            backgroundColor: Colors.green
        ));

        setState(() {
          selectedSupplier = null;
          selectedProduct = null;
          qtyController.clear();
          currentMin = null;
          currentMax = null;
          isOneTimeOrder = false;
          variantTabData.clear();
          stockTabData.clear();
          for (var v in variants) {
            int id = int.tryParse(v['id'].toString()) ?? 0;
            variantTabData[id] =
            {'qty': '', 'buying': '', 'profit': '', 'selling': ''};
            stockTabData[id] = [];
          }
        });
      } else {
        if (!mounted) return;
        String errorMsg = decoded['message']?.toString() ??
            "Failed to save stock";
        AppLogger.error("API SAVE FAILED: $errorMsg");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMsg = "Failed to save stock";
      
      if (e is SocketException) {
        errorMsg = "No Internet Connection";
        AppLogger.error("NETWORK ERROR: SocketException - Likely no internet or invalid host", e);
      } else if (e is TimeoutException) {
        errorMsg = "Request Timeout. Please try again.";
        AppLogger.error("NETWORK ERROR: TimeoutException", e);
      } else if (e is http.ClientException) {
        errorMsg = "Network Error. Please check your connection.";
        AppLogger.error("NETWORK ERROR: ClientException", e);
      } else {
        errorMsg = "An unexpected error occurred. Please try again.";
        AppLogger.error("API EXCEPTION", e);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future loadData() async {
    if (token.isEmpty) {
      return;
    }
    await getSuppliers();
    await getProducts();
  }

  Future<void> getSuppliers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bId = prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";
      final r = prefs.getString("role")?.toLowerCase() ?? "";

      String url = "https://billing.srivagroups.in/api/suppliers";
      
      if (r == "supplier" || r == "partner") {
        url += "?business_id=$bId&user_main_id=$uId";
      } else if (r == "propagator" || r == "propagater" || r == "admin") {
        // No filter
      } else if (bId.isNotEmpty) {
        url += "?business_id=$bId";
      }

      final res = await http.get(Uri.parse(url), headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        var data = decoded['data'];

        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          // Handle deeply nested structure from logs: data['data']['data']
          if (data['data'] is Map && data['data']['data'] is List) {
            list = data['data']['data'];
          } else {
            list = data['suppliers'] ?? data['list'] ?? [data];
          }
        }

        if (mounted) {
          setState(() {
            suppliers = list;
          });
        }
      } else {
        AppLogger.api("GET", url, res.statusCode, isError: true);
      }
    } catch (e) {
      AppLogger.error("Failed to fetch suppliers", e);
    }
  }

  static List<Map<String, dynamic>> _parseProductsTask(dynamic rawData) {
    List<Map<String, dynamic>> flattened = [];
    if (rawData is List) {
      for (var group in rawData) {
        if (group is Map && group['Categories'] != null) {
          final cats = group['Categories'];
          
          void processProductList(List productsList) {
            for (var product in productsList) {
              flattened.add({
                'id': product['id'],
                'product_name': product['name'] ?? product['product_name'] ?? "Unknown",
                'min': int.tryParse(product['Qty']?['min']?.toString() ?? '') ?? 1,
                'max': int.tryParse(product['Qty']?['max']?.toString() ?? '') ?? 100,
                'supplier_id': product['supplier_id'],
              });
            }
          }

          // Process Primary
          for (var cat in (cats['primary'] ?? [])) {
            for (var brand in (cat['Brand'] ?? [])) {
              processProductList(brand['Products'] ?? []);
            }
          }
          // Process Secondary
          for (var cat in (cats['secondary'] ?? [])) {
            for (var brand in (cat['Brand'] ?? [])) {
              processProductList(brand['Products'] ?? []);
            }
          }
        } else if (group is Map) {
          final item = Map<String, dynamic>.from(group);
          // Ensure min/max exist even for flat items
          item['min'] = int.tryParse(group['Qty']?['min']?.toString() ?? '') ?? 
                        int.tryParse(group['min']?.toString() ?? '') ?? 1;
          item['max'] = int.tryParse(group['Qty']?['max']?.toString() ?? '') ?? 
                        int.tryParse(group['max']?.toString() ?? '') ?? 100;
          flattened.add(item);
        }
      }
    }
    return flattened;
  }

  Future<void> getProducts() async {
    try {
      AppLogger.info("PRODUCTS FETCH START");
      final prefs = await SharedPreferences.getInstance();
      final bId = prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";
      final r = prefs.getString("role")?.toLowerCase() ?? "";

      String url = "https://billing.srivagroups.in/api/productAllocation";
      
      if (r == "supplier" || r == "partner") {
        url += "?business_id=$bId&user_main_id=$uId";
      } else if (r == "propagator" || r == "propagater" || r == "admin") {
        // No filter
      } else if (bId.isNotEmpty) {
        url += "?business_id=$bId";
      }

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final rawData = decoded['data'];

        final flattened = await compute(_parseProductsTask, rawData);

        if (mounted) {
          setState(() {
            products = flattened;
          });
          AppLogger.info("PRODUCTS FETCH SUCCESS: ${products.length} items");
        }
      }
    } catch (e) {
      AppLogger.error("Failed to fetch products", e);
    }
  }


  // Data storage for variants per tab (Key: Dynamic Variant ID)
  Map<int, Map<String, String>> variantTabData = {};
  Map<int, List<Map<String, dynamic>>> stockTabData = {};

  // 🔥 REFACTORED VARIANT POPUP
  void openVariantPopup() {
    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No variants available. Please wait for loading.")));
      return;
    }

    int activeVariantId = int.tryParse(variants.first['id'].toString()) ?? 0;

    void calculateSellingPrice() {
      double buying = double.tryParse(buyingController.text) ?? 0.0;
      double margin = double.tryParse(profitController.text) ?? 0.0;
      String calculated = (buying + margin).toStringAsFixed(2);
      if (sellingPriceNotifier.value != calculated) {
        sellingPriceNotifier.value = calculated;
        sellingController.text = calculated;
      }
    }

    buyingController.removeListener(calculateSellingPrice);
    profitController.removeListener(calculateSellingPrice);
    buyingController.addListener(calculateSellingPrice);
    profitController.addListener(calculateSellingPrice);

    int getUsedExcluding(int excludedId) {
      int sum = 0;
      variantTabData.forEach((id, value) {
        if (id != excludedId) {
          sum += int.tryParse(value['qty']?.toString() ?? '0') ?? 0;
        }
      });
      return sum;
    }

    void loadTab(int id) {
      final data = variantTabData[id] ??
          {'qty': '', 'buying': '', 'profit': '', 'selling': ''};
      variantQtyController.text = data['qty'] ?? '';
      buyingController.text = data['buying'] ?? '';
      profitController.text = data['profit'] ?? '';
      calculateSellingPrice();
    }

    void saveCurrentTab(int id) {
      if (mounted) {
        setState(() {
          variantTabData[id] = {
            'qty': variantQtyController.text.trim(),
            'buying': buyingController.text.trim(),
            'profit': profitController.text.trim(),
            'selling': sellingPriceNotifier.value,
          };
        });
      }
    }

    loadTab(activeVariantId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              final int totalAllocated = int.tryParse(qtyController.text) ?? 0;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery
                      .of(context)
                      .viewInsets
                      .bottom,
                  left: 20, right: 20, top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 20),
                      const Text("Variant Distribution", style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                      const SizedBox(height: 20),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: variants.map((v) {
                            int id = int.tryParse(v['id'].toString()) ?? 0;
                            bool isSelected = activeVariantId == id;
                            return GestureDetector(
                              onTap: () {
                                saveCurrentTab(activeVariantId);
                                setModalState(() {
                                  activeVariantId = id;
                                  loadTab(id);
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(v['name'] ?? "Variant $id",
                                    style: TextStyle(color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                        fontWeight: FontWeight.bold)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoBox("Total Qty", "$totalAllocated"),
                          StatefulBuilder(builder: (c, s) {
                            int usedOthers = getUsedExcluding(activeVariantId);
                            int currentQty = int.tryParse(variantQtyController.text) ?? 0;
                            int remaining = totalAllocated -
                                (usedOthers + currentQty);
                            return _infoBox("Balance Qty", "$remaining",
                                color: remaining < 0 ? Colors.red : Colors
                                    .green);
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: variantQtyController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          int usedOthers = getUsedExcluding(activeVariantId);
                          int input = int.tryParse(val) ?? 0;
                          if (input + usedOthers > totalAllocated) {
                            int allowed = totalAllocated - usedOthers;
                            variantQtyController.text = allowed.toString();
                            variantQtyController.selection = TextSelection.fromPosition(
                                TextPosition(offset: variantQtyController.text.length));
                          }
                          // Local rebuild for the balance info box only
                          (context as Element).markNeedsBuild();
                        },
                        decoration: InputDecoration(
                          labelText: "Quantity",
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius
                              .circular(12), borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: buyingController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Buying Price",
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius
                              .circular(12), borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: profitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Profit Margin",
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius
                              .circular(12), borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: sellingController,
                        readOnly: true,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB)),
                        decoration: InputDecoration(
                          labelText: "Selling Price (Auto)",
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            int usedOthers = getUsedExcluding(activeVariantId);
                            int currentQty = int.tryParse(variantQtyController.text) ?? 0;
                            if (totalAllocated - (usedOthers + currentQty) <
                                0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text(
                                      "Total quantity exceeded!")));
                              return;
                            }
                            saveCurrentTab(activeVariantId);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("Confirm & Save", style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  Widget _infoBox(String title, String value, {Color? color}) {
    return Column(
      children: [
        Text(
            title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      ],
    );
  }

  // 🔥 STOCK POPUP (Requirement 1, 4, 10)
  void openStockPopup() {
    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No variants available. Please wait for loading.")));
      return;
    }

    // Fetch fresh stock types on modal open to ensure dynamic data
    fetchStockTypes();

    int activeVariantId = int.tryParse(variants.first['id'].toString()) ?? 0;
    int? selectedStockTypeId;
    int? editingIndex;
    
    // Reset controller
    distQtyController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<Map<String,
                dynamic>> currentList = stockTabData[activeVariantId] ?? [];
            final int variantQty = int.tryParse(
                variantTabData[activeVariantId]?['qty'] ?? '0') ?? 0;
            final int distributedQty = currentList.fold(0, (sum, item) =>
            sum + (int.tryParse(item['qty'].toString()) ?? 0));
            final int remainingQty = variantQty - distributedQty;

            bool isExceeded = distributedQty > variantQty;

            return Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.9,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // --- HEADER ---
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius
                            .circular(24)),
                      ),
                      child: Column(
                        children: [
                          Container(width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Stock Distribution", style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B))),
                              IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Dynamic Horizontal Scrollable Tabs
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: variants.map((v) {
                                int id = int.tryParse(v['id'].toString()) ?? 0;
                                bool isSelected = activeVariantId == id;
                                return GestureDetector(
                                  onTap: () =>
                                      setModalState(() {
                                        activeVariantId = id;
                                        editingIndex = null;
                                        selectedStockTypeId = null;
                                        distQtyController.clear();
                                      }),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(
                                          0xFF2563EB) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      v['name'] ?? "Variant $id",
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Remaining Qty Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isExceeded
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isExceeded
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFDBEAFE)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      const Text("VARIANT QTY",
                                          style: TextStyle(fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF64748B))),
                                      Text("$variantQty",
                                          style: const TextStyle(fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B))),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          isExceeded ? "EXCEEDED" : "REMAINING",
                                          style: TextStyle(fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isExceeded
                                                  ? Colors.red
                                                  : const Color(0xFF64748B))),
                                      Text("${remainingQty.abs()}",
                                          style: TextStyle(fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isExceeded
                                                  ? Colors.red
                                                  : const Color(0xFF2563EB))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isExceeded)
                              const Padding(padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                      "⚠️ Total distribution exceeds variant quantity",
                                      style: TextStyle(color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600))),

                            const SizedBox(height: 24),

                            // --- ADD NEW FORM ---
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10)
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(editingIndex == null
                                      ? "ADD NEW DISTRIBUTION"
                                      : "EDIT DISTRIBUTION",
                                      style: const TextStyle(fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B))),
                                  const SizedBox(height: 16),
                                  // Stock Type Dropdown
                                  DropdownButtonFormField<int>(
                                    value: selectedStockTypeId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: "Stock Type Name",
                                      hintText: isLoadingStockTypes
                                          ? "Fetching types..."
                                          : (stockTypes.isEmpty
                                              ? "No stock types found"
                                              : "Select Stock Type"),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      prefixIcon: isLoadingStockTypes
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2)),
                                            )
                                          : const Icon(Icons.inventory_2_outlined),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    items: stockTypes.map((st) {
                                      int id = int.tryParse(st['id'].toString()) ?? 0;
                                      return DropdownMenuItem<int>(
                                          value: id, child: Text(st['name'] ?? 'N/A'));
                                    }).toList(),
                                    onChanged: isLoadingStockTypes
                                        ? null
                                        : (val) {
                                            AppLogger.info("SELECTED STOCK TYPE ID: $val");
                                            setModalState(() => selectedStockTypeId = val);
                                          },
                                  ),
                                  const SizedBox(height: 12),
                                  // Qty Field
                                  TextField(
                                    controller: distQtyController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: "Quantity",
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              12),
                                          borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0))),
                                      contentPadding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 16, vertical: 14),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (selectedStockTypeId == null) {
                                          ScaffoldMessenger
                                              .of(context)
                                              .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Please select a stock type")));
                                          return;
                                        }

                                        final selectedStock = stockTypes
                                            .firstWhere(
                                              (e) =>
                                          (int.tryParse(e['id'].toString()) ??
                                              0) == selectedStockTypeId,
                                          orElse: () => {},
                                        );

                                        if (selectedStock.isEmpty) {
                                          ScaffoldMessenger
                                              .of(context)
                                              .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Invalid stock type selected")));
                                          return;
                                        }

                                        if (distQtyController.text.isEmpty) {
                                          ScaffoldMessenger
                                              .of(context)
                                              .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Please enter quantity")));
                                          return;
                                        }
                                        int val = int.tryParse(distQtyController.text) ??
                                            0;
                                        if (val <= 0) {
                                          ScaffoldMessenger
                                              .of(context)
                                              .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Quantity must be greater than 0")));
                                          return;
                                        }

                                        setModalState(() {
                                          if (editingIndex != null) {
                                            currentList[editingIndex!] = {
                                              'stock_type_id': selectedStock['id'],
                                              'stock_type_name': selectedStock['name'],
                                              'qty': val,
                                            };
                                            editingIndex = null;
                                          } else {
                                            // Duplicate check
                                            if (currentList.any((e) =>
                                            e['stock_type_id'] ==
                                                selectedStock['id'])) {
                                              ScaffoldMessenger
                                                  .of(context)
                                                  .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      "This stock type is already added for this variant")));
                                              return;
                                            }
                                            currentList.add({
                                              'stock_type_id': selectedStock['id'],
                                              'stock_type_name': selectedStock['name'],
                                              'qty': val,
                                            });
                                          }
                                          selectedStockTypeId = null;
                                          distQtyController.clear();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                            0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                12)),
                                      ),
                                      child: Text(editingIndex == null
                                          ? "ADD VALUE"
                                          : "UPDATE VALUE",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            const Text("CURRENT DISTRIBUTION", style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B))),
                            const SizedBox(height: 12),
                            if (currentList.isEmpty)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 48,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text("No distributions added yet",
                                          style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: currentList.length,
                                itemBuilder: (ctx, index) {
                                  final item = currentList[index];
                                  return Container(
                                    key: ValueKey(
                                        "dist_${item['stock_type_id']}"),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius
                                                  .circular(12)),
                                          child: const Icon(
                                              Icons.location_on_outlined,
                                              color: Color(0xFF64748B),
                                              size: 20),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment
                                                .start,
                                            children: [
                                              Text(item['stock_type_name'],
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold,
                                                      color: Color(
                                                          0xFF1E293B))),
                                              Text("Value: ${item['qty']}",
                                                  style: TextStyle(
                                                      color: Colors.grey
                                                          .shade500,
                                                      fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setModalState(() {
                                              editingIndex = index;
                                              selectedStockTypeId =
                                                  int.tryParse(
                                                      item['stock_type_id']
                                                          .toString());
                                              distQtyController.text =
                                                  item['qty'].toString();
                                            });
                                          },
                                          icon: const Icon(Icons.edit_outlined,
                                              color: Color(0xFF2563EB)),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              setModalState(() =>
                                                  currentList.removeAt(index)),
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    // --- STICKY BOTTOM BUTTON ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4))
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (remainingQty != 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Total distribution ($distributedQty) must be exactly $variantQty"),
                                    backgroundColor: Colors.orange,
                                  ));
                              return;
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text("Save Details", style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPopupTab(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stock Entry")),
      body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
                children: [
                  // 🔥 SUPPLIER DROPDOWN
                  if (suppliers.isEmpty)
                    const Center(child: Text("No suppliers available"))
                  else
                    DropdownButtonFormField<String>(
                      hint: const Text("Select Supplier"),
                      isExpanded: true,
                      value: (suppliers.any((e) =>
                      e['id'].toString() == selectedSupplier))
                          ? selectedSupplier
                          : null,
                      items: suppliers.map<DropdownMenuItem<String>>((e) {
                        // ✅ FIX: Enhanced supplier name parsing (handles registered & unregistered)
                        String supplierName = e['supplier_name']?.toString() ??
                            e['company_name']?.toString() ??
                            e['business_name']?.toString() ??
                            e['name']?.toString() ??
                            (e['supplier'] is Map ? e['supplier']['name']
                                ?.toString() : null) ??
                            "No Name";

                        return DropdownMenuItem(
                          value: e['id'].toString(),
                          child: Text(supplierName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSupplier = val;
                        });
                      },
                    ),

                  const SizedBox(height: 20),

                  // 🔥 PRODUCT DROPDOWN (INDEPENDENT)
                  DropdownButtonFormField<String>(
                    hint: const Text("Select Product"),
                    isExpanded: true,
                    value: (products.any((e) =>
                    e['id'].toString() == selectedProduct))
                        ? selectedProduct
                        : null,
                    items: products.map<DropdownMenuItem<String>>((e) {
                      return DropdownMenuItem(
                        value: e['id'].toString(),
                        child: Text(e['product_name']?.toString() ?? e['name']
                            ?.toString() ?? "Unnamed Product"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedProduct = val;

                        final matchedProducts = products.where(
                          (p) => p['id'].toString() == val,
                        ).toList();

                        if (matchedProducts.isNotEmpty) {
                          final prod = matchedProducts.first;

                          currentMin = int.tryParse(
                            prod['min']?.toString() ?? '1',
                          ) ?? 1;

                          currentMax = int.tryParse(
                            prod['max']?.toString() ?? '100',
                          ) ?? 100;

                          AppLogger.info(
                            "SELECTED PRODUCT => ${prod['product_name']} | MIN=$currentMin | MAX=$currentMax",
                          );
                        } else {
                          currentMin = null;
                          currentMax = null;
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 🔥 QUANTITY SECTION
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && currentMax != null && !isOneTimeOrder) {
                            int? val = int.tryParse(value);
                            if (val != null && val > currentMax!) {
                              qtyController.text = currentMax.toString();
                              qtyController.selection = TextSelection.fromPosition(
                                TextPosition(offset: qtyController.text.length),
                              );
                            }
                          }
                          setState(() {}); // Refresh for validation messages
                        },
                        decoration: InputDecoration(
                          labelText: "Quantity",
                          hintText: selectedProduct == null 
                              ? "Select product first" 
                              : "Enter quantity",
                          prefixIcon: const Icon(Icons.shopping_cart_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          errorText: (qtyController.text.isNotEmpty &&
                              currentMin != null &&
                              (int.tryParse(qtyController.text) ?? 0) < currentMin!)
                              ? "Minimum required: $currentMin"
                              : (!isOneTimeOrder &&
                                 qtyController.text.isNotEmpty &&
                                 currentMax != null &&
                                 (int.tryParse(qtyController.text) ?? 0) > currentMax!)
                              ? "Maximum allowed: $currentMax"
                              : null,
                        ),
                      ),
                      
                      const SizedBox(height: 10),

                      // 🔥 MIN/MAX QTY DISPLAY
                      if (currentMin != null && currentMax != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            "Min: $currentMin | Max: $currentMax",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),

                      // 🔥 ONE TIME ORDER CHECKBOX
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: isOneTimeOrder,
                              activeColor: Colors.blue,
                              onChanged: (val) {
                                setState(() {
                                  isOneTimeOrder = val ?? false;
                                  // Trigger validation check
                                  if (!isOneTimeOrder && qtyController.text.isNotEmpty && currentMax != null) {
                                     int val = int.tryParse(qtyController.text) ?? 0;
                                     if (val > currentMax!) {
                                       qtyController.text = currentMax.toString();
                                     }
                                  }
                                });
                              },
                            ),
                          ),
                          const Text(
                            "ONE TIME ORDER",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // 🔥 VARIANT BUTTON
                  ElevatedButton(
                    onPressed: openVariantPopup,
                    child: Text("Specify Variant Details"),
                  ),

                  SizedBox(height: 20),

                  // 🔥 STOCK BUTTON
                  ElevatedButton(
                    onPressed: openStockPopup,
                    child: Text("Specify Stock Details"),
                  ),

                  SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving ? null : saveStock,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12)),
                          child: isSaving
                              ? const SizedBox(width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Text("Save Stock", style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12)),
                          child: const Text("Cancel", style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ]
            ),
          )
      ),
    );
  }
}

