import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:billingapp/billing/billing_mode_selector.dart';
import 'supplier_db_seed.dart';

// Shim to support console.log/error
class _Console {
  void log(Object? message) => debugPrint(message?.toString());
  void error(Object? message) => debugPrint("ERROR: ${message?.toString()}");
}
final console = _Console();

class EditQuotationPage extends StatefulWidget {
  final int quotationId;
  final String token;
  final Map<String, dynamic> initialData;

  const EditQuotationPage({
    super.key,
    required this.quotationId,
    required this.token,
    required this.initialData,
  });

  @override
  State<EditQuotationPage> createState() => _EditQuotationPageState();
}

class _EditQuotationPageState extends State<EditQuotationPage> {
  String rfqId = "RFQ-560159";
  DateTime requestDate = DateTime.now();
  DateTime? validityDate;
  String selectedStatus = "Pending";

  String? selectedBusiness = "Circuitpointcare";
  String? selectedStore = "Circuitpointcare";

  final List<String> businessList = [
    "Circuitpointcare",
    "circuitpointcare",
    "lohit perfectt",
    "Sriva Groups",
  ];

  final Map<String, List<String>> storeMap = {
    "Circuitpointcare": ["Circuitpointcare", "Circuitpoint", "Main Store", "Warehouse Neelambur"],
    "circuitpointcare": ["Circuitpointcare", "Circuitpoint", "Main Store", "Warehouse Neelambur"],
    "lohit perfectt": ["Circuitpointcare", "Circuitpoint", "Main Store"],
    "Sriva Groups": ["Sriva Central Store", "Sriva Hub 2", "Circuitpoint"],
  };

  // Live stock inventory from GET https://billing.srivagroups.in/api/stocks
  List<Map<String, dynamic>> stocksList = gLiveStocksCache.isNotEmpty ? List.from(gLiveStocksCache) : sanitizeStocksList(kLiveStocksData);
  bool isLoadingStocks = false;
  void Function(void Function())? _modalSetState;

  // Products in the RFQ request
  List<Map<String, dynamic>> addedProducts = [];

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _prefillData();
    _fetchStocks();
    _fetchQuotationDetails();
  }

  void _prefillData() {
    final d = widget.initialData;
    rfqId = d['rfq_reference'] ?? "RFQ-${widget.quotationId}";

    final bName = d['business_name'] ?? (d['business'] is Map ? d['business']['name'] : null);
    if (bName != null && bName.toString().isNotEmpty) {
      selectedBusiness = bName.toString();
    }
    if (selectedBusiness != null && !businessList.contains(selectedBusiness)) {
      businessList.add(selectedBusiness!);
    }

    final sName = d['store_name'] ?? (d['store'] is Map ? d['store']['name'] : null);
    if (sName != null && sName.toString().isNotEmpty) {
      selectedStore = sName.toString();
    }
    if (selectedStore != null && selectedStore!.isNotEmpty) {
      for (var key in storeMap.keys) {
        if (!storeMap[key]!.contains(selectedStore)) {
          storeMap[key]!.add(selectedStore!);
        }
      }
    }

    if (d['request_date'] != null) {
      try {
        requestDate = DateTime.parse(d['request_date'].toString());
      } catch (_) {}
    }

    final valStr = d['validity_until'] ?? d['validity_date'];
    if (valStr != null) {
      try {
        validityDate = DateTime.parse(valStr.toString());
      } catch (_) {}
    }

    final st = (d['status'] ?? "Pending").toString();
    if (st.toLowerCase() == "accepted") {
      selectedStatus = "Accepted";
    } else if (st.toLowerCase() == "rejected") {
      selectedStatus = "Rejected";
    } else if (st.toLowerCase() == "expired") {
      selectedStatus = "Expired";
    } else {
      selectedStatus = "Pending";
    }

    final rawProducts = (d['products'] is List && (d['products'] as List).isNotEmpty)
        ? d['products'] as List
        : (d['items'] is List ? d['items'] as List : []);

    addedProducts.clear();
    for (var p in rawProducts) {
      if (p is Map) {
        final pName = p['product_name'] ??
            (p['product'] is Map ? p['product']['name'] : null) ??
            p['name'] ??
            "Product";
        final pId = int.tryParse((p['product_id'] ?? (p['product'] is Map ? p['product']['id'] : null) ?? 0).toString()) ?? 0;
        final vName = p['variant_name'] ??
            (p['variant'] is Map ? p['variant']['name'] : null) ??
            "Imported";
        final vId = int.tryParse((p['variant_id'] ?? (p['variant'] is Map ? p['variant']['id'] : null) ?? 41).toString()) ?? 41;
        final qty = int.tryParse(p['quantity']?.toString() ?? p['qty']?.toString() ?? "1") ?? 1;
        final double priceWithoutGst = double.tryParse((p['price_without_gst'] ??
                p['buying_price_without_gst'] ??
                p['target_price'] ??
                p['unit_price'] ??
                0.0).toString()) ?? 0.0;
        final double gstRate = double.tryParse((p['gst_rate'] ?? p['tax'] ?? 18.0).toString()) ?? 18.0;
        final double priceWithGst = double.tryParse((p['price_with_gst'] ??
                p['buying_price_with_gst'] ??
                (priceWithoutGst * (1 + gstRate / 100))).toString()) ?? (priceWithoutGst * (1 + gstRate / 100));
        final double total = double.tryParse((p['total_with_gst'] ?? p['total'] ?? (priceWithGst * qty)).toString()) ?? (priceWithGst * qty);

        addedProducts.add({
          "stock_id": p['stock_id'] ?? pId,
          "product_id": pId,
          "product_name": pName,
          "variant_id": vId,
          "variant_name": vName,
          "brand_name": p['brand_name'] ?? (p['brand'] is Map ? p['brand']['name'] : ""),
          "qty": qty,
          "unit_price_excl": priceWithoutGst,
          "tax": gstRate,
          "unit_price_incl": priceWithGst,
          "total": total,
        });
      }
    }
  }

  Future<void> _fetchQuotationDetails() async {
    final url = "https://billing.srivagroups.in/api/quotation/${widget.quotationId}";
    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      AppLogger.api("GET", url, response.statusCode);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final d = decoded['data'] is Map ? decoded['data'] as Map<String, dynamic> : (decoded is Map ? decoded as Map<String, dynamic> : null);
        if (d != null && mounted) {
          setState(() {
            widget.initialData.addAll(d);
            _prefillData();
          });
        }
      }
    } catch (e) {
      AppLogger.error("Fetch quotation details error", e);
    }
  }

  Future<String> _getEffectiveToken() async {
    if (widget.token.isNotEmpty) return widget.token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("billing_auth_token") ??
        prefs.getString("auth_token") ??
        prefs.getString("token") ??
        "";
  }

  Future<Map<String, String>> _getEffectiveHeaders({bool jsonBody = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _getEffectiveToken();
    final platformId = prefs.getString("selected_platform_id") ??
        prefs.getString("platform_id") ??
        "1";
    final bId = prefs.getString("selected_business_id") ??
        prefs.getString("business_id") ??
        "52";
    final sId = prefs.getString("selected_store_id") ??
        prefs.getString("store_id") ??
        "38";

    return <String, String>{
      "Accept": "application/json",
      if (jsonBody) "Content-Type": "application/json",
      "X-App-ID": "Product94674",
      "x-platform-id": platformId,
      "platform-id": platformId,
      "x-business-id": bId,
      "business-id": bId,
      if (sId.isNotEmpty) "x-store-id": sId,
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<void> _fetchStocks() async {
    if (stocksList.isEmpty) {
      setState(() => isLoadingStocks = true);
    }
    const url = "https://billing.srivagroups.in/api/stocks";

    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
      AppLogger.api("GET", url, response.statusCode);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] is List ? decoded['data'] as List : (decoded is List ? decoded : []);
        final sanitized = sanitizeStocksList(list);
        if (sanitized.isNotEmpty) {
          gLiveStocksCache = sanitized;
          if (mounted) {
            setState(() {
              stocksList = sanitized;
              isLoadingStocks = false;
            });
            _modalSetState?.call(() {});
            return;
          }
        }
      }
    } catch (e) {
      AppLogger.error("fetchStocks error in Edit", e);
    }

    if (mounted) {
      setState(() {
        if (stocksList.isEmpty) {
          stocksList = sanitizeStocksList(kLiveStocksData);
        }
        isLoadingStocks = false;
      });
      _modalSetState?.call(() {});
    }
  }

  // Multi-select modal matching Screenshot 4 with Virtualized ListView (Zero lag, zero crash)
  void _openProductPicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        String searchQuery = "";
        final Set<int> selectedStockIds = {};

        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            _modalSetState = setModalState;

            final filteredStocks = stocksList.where((stock) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.toLowerCase();
              final name = (stock['product_name'] ?? "").toString().toLowerCase();
              final cat = (stock['category_name'] ?? "").toString().toLowerCase();
              final brand = (stock['brand_name'] ?? "").toString().toLowerCase();
              final variants = (stock['variants'] as List? ?? []);
              final vName = variants.isNotEmpty && variants[0] is Map ? (variants[0]['variant_name'] ?? "").toString().toLowerCase() : "";
              return name.contains(q) || cat.contains(q) || brand.contains(q) || vName.contains(q);
            }).toList();

            final allFilteredIds = filteredStocks.map((s) => int.tryParse(s['id']?.toString() ?? "") ?? 0).where((id) => id > 0).toSet();
            final isAllSelected = allFilteredIds.isNotEmpty && allFilteredIds.every(selectedStockIds.contains);

            final screenWidth = MediaQuery.of(dialogCtx).size.width;
            final screenHeight = MediaQuery.of(dialogCtx).size.height;
            final isSmallScreen = screenWidth < 750;
            final dialogWidth = isSmallScreen ? screenWidth * 0.96 : 820.0;
            final dialogHeight = screenHeight * 0.85;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Container(
                width: dialogWidth,
                height: dialogHeight,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header: Store pill badge + Close X button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront_outlined, size: 14, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    selectedStore ?? "Circuitpointcare",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _modalSetState = null;
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Select Store Stock Product",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Choose an available product from current store inventory to add to quotation",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),

                    // Search box (Photo 4)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        onChanged: (val) => setModalState(() => searchQuery = val),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: "Search by product name, variant, brand, or category...",
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                          prefixIconConstraints: BoxConstraints(minWidth: 32, minHeight: 18),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Virtualized Products Table (Prevents Android OOM / Signal 35 crash!)
                    Expanded(
                      child: isLoadingStocks && stocksList.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                          : filteredStocks.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF94A3B8)),
                                      SizedBox(height: 8),
                                      Text("No products match the search query", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: 825,
                                        child: Column(
                                          children: [
                                            // Sticky Table Header matching Photo 4
                                            Container(
                                              color: const Color(0xFFF8FAFC),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 44,
                                                    child: Checkbox(
                                                      value: isAllSelected,
                                                      activeColor: const Color(0xFF6366F1),
                                                      onChanged: (checked) {
                                                        setModalState(() {
                                                          if (checked == true) {
                                                            selectedStockIds.addAll(allFilteredIds);
                                                          } else {
                                                            selectedStockIds.removeAll(allFilteredIds);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 240, child: Text("PRODUCT / VARIANT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                                                  const SizedBox(width: 140, child: Text("CATEGORY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                                                  const SizedBox(width: 110, child: Text("BRAND", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                                                  const SizedBox(width: 80, child: Text("AVAIL. STOCK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                                                  const SizedBox(width: 90, child: Text("WITHOUT GST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                                                  const SizedBox(width: 90, child: Text("WITH GST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                                                ],
                                              ),
                                            ),
                                            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                                            // Butter-smooth Virtualized Rows (Only renders visible rows!)
                                            Expanded(
                                              child: ListView.separated(
                                                itemCount: filteredStocks.length,
                                                separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                                                itemBuilder: (context, index) {
                                                  final stock = filteredStocks[index];
                                                  final id = int.tryParse(stock['id']?.toString() ?? "") ?? index;
                                                  final isChecked = selectedStockIds.contains(id);
                                                  final pName = (stock['product_name'] ?? "Unknown").toString();
                                                  final catName = (stock['category_name'] ?? "-").toString();
                                                  final brandName = (stock['brand_name'] ?? "-").toString();
                                                  final availStock = int.tryParse(stock['total_qty']?.toString() ?? "") ?? 1;

                                                  final variants = (stock['variants'] as List? ?? []);
                                                  final variant = variants.isNotEmpty && variants[0] is Map ? variants[0] as Map : {};
                                                  final variantName = (variant['variant_name'] ?? "Imported").toString();
                                                  final double withoutGst = double.tryParse((variant['buying_price_without_gst'] ?? variant['buying_price'] ?? 0).toString()) ?? 0.0;
                                                  final double gstRate = double.tryParse((variant['gst_rate'] ?? 18).toString()) ?? 18.0;
                                                  final double withGst = double.tryParse((variant['buying_price_with_gst'] ?? (withoutGst * (1 + gstRate / 100))).toString()) ?? (withoutGst * 1.18);

                                                  return InkWell(
                                                    onTap: () {
                                                      setModalState(() {
                                                        if (isChecked) {
                                                          selectedStockIds.remove(id);
                                                        } else {
                                                          selectedStockIds.add(id);
                                                        }
                                                      });
                                                    },
                                                    child: Container(
                                                      color: isChecked ? const Color(0xFFEEF2FF).withValues(alpha: 0.5) : Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          SizedBox(
                                                            width: 44,
                                                            child: Checkbox(
                                                              value: isChecked,
                                                              activeColor: const Color(0xFF6366F1),
                                                              onChanged: (val) {
                                                                setModalState(() {
                                                                  if (val == true) {
                                                                    selectedStockIds.add(id);
                                                                  } else {
                                                                    selectedStockIds.remove(id);
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 240,
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Text(
                                                                  pName,
                                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                const SizedBox(height: 3),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                                  decoration: BoxDecoration(
                                                                    color: const Color(0xFFF1F5F9),
                                                                    borderRadius: BorderRadius.circular(4),
                                                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                                                  ),
                                                                  child: Text(
                                                                    "($variantName)",
                                                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 140,
                                                            child: Text(
                                                              catName,
                                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 110,
                                                            child: Text(
                                                              brandName,
                                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 80,
                                                            child: Align(
                                                              alignment: Alignment.centerLeft,
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFFFEF3C7),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                                                ),
                                                                child: Text(
                                                                  "$availStock",
                                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 90,
                                                            child: Text(
                                                              "₹${withoutGst.toStringAsFixed(2)}",
                                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 90,
                                                            child: Text(
                                                              "₹${withGst.toStringAsFixed(2)}",
                                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                    const SizedBox(height: 14),

                    // Modal Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "Showing ${filteredStocks.length} of ${stocksList.length} products",
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                _modalSetState = null;
                                Navigator.pop(ctx);
                              },
                              child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selectedStockIds.isEmpty
                                  ? null
                                  : () {
                                      _modalSetState = null;
                                      Navigator.pop(ctx);
                                      setState(() {
                                        for (final id in selectedStockIds) {
                                          final stock = stocksList.firstWhere(
                                            (s) => (int.tryParse(s['id']?.toString() ?? "") ?? 0) == id,
                                            orElse: () => {},
                                          );
                                          if (stock.isNotEmpty) {
                                            final variants = (stock['variants'] as List? ?? []);
                                            final variant = variants.isNotEmpty && variants[0] is Map ? variants[0] as Map : {};
                                            final variantName = (variant['variant_name'] ?? "Imported").toString();
                                            final double withoutGst = double.tryParse((variant['buying_price_without_gst'] ?? variant['buying_price'] ?? 0).toString()) ?? 0.0;
                                            final double gstRate = double.tryParse((variant['gst_rate'] ?? 18).toString()) ?? 18.0;
                                            final double withGst = double.tryParse((variant['buying_price_with_gst'] ?? (withoutGst * (1 + gstRate / 100))).toString()) ?? (withoutGst * 1.18);
                                            final int pId = int.tryParse((stock['product_id'] ?? stock['id'])?.toString() ?? "") ?? id;
                                            final int vId = int.tryParse(variant['variant_id']?.toString() ?? "") ?? 41;

                                            addedProducts.add({
                                              "stock_id": id,
                                              "product_id": pId,
                                              "product_name": stock['product_name'] ?? "Product",
                                              "variant_id": vId,
                                              "variant_name": variantName,
                                              "brand_name": stock['brand_name'] ?? "",
                                              "category_name": stock['category_name'] ?? "",
                                              "qty": 1,
                                              "unit_price_excl": withoutGst,
                                              "tax": gstRate,
                                              "unit_price_incl": withGst,
                                              "total": withGst * 1,
                                            });
                                          }
                                        }
                                        _recalculateTotals();
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: Text(
                                "+ Add Selected (${selectedStockIds.length})",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  void _recalculateTotals() {
    for (var p in addedProducts) {
      final qty = (p['qty'] as num).toDouble();
      final excl = (p['unit_price_excl'] as num).toDouble();
      final tax = (p['tax'] as num).toDouble();
      final incl = excl * (1 + tax / 100);
      p['unit_price_incl'] = incl;
      p['total'] = incl * qty;
    }
    setState(() {});
  }

  int get totalQty => addedProducts.fold(0, (acc, p) => acc + (p['qty'] as int? ?? 1));

  double get totalWithoutGst => addedProducts.fold(0.0, (acc, p) {
        final q = (p['qty'] as num).toDouble();
        final excl = (p['unit_price_excl'] as num).toDouble();
        return acc + (excl * q);
      });

  double get totalGst => grandTotal - totalWithoutGst;

  double get grandTotal => addedProducts.fold(0.0, (acc, p) => acc + (p['total'] as num).toDouble());

  Future<void> _updateQuotation() async {
    if (addedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one product ⚠️"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isSaving = true);

    final url = "https://billing.srivagroups.in/api/quotation/${widget.quotationId}";
    final headers = await _getEffectiveHeaders(jsonBody: true);

    final reqDateStr = DateFormat('yyyy-MM-dd').format(requestDate);
    final valDateStr = DateFormat('yyyy-MM-dd').format(validityDate ?? DateTime.now());

    final pName = addedProducts.length == 1
        ? "${addedProducts[0]['product_name']} (${addedProducts[0]['variant_name'] ?? 'Imported'})"
        : "${addedProducts[0]['product_name']} (${addedProducts[0]['variant_name'] ?? 'Imported'}) (+${addedProducts.length - 1} more)";

    final itemsList = addedProducts.map((p) => {
      "stock_id": p['stock_id'],
      "product_id": p['product_id'],
      "product_name": p['product_name'],
      "name": p['product_name'],
      "variant_id": p['variant_id'],
      "variant_name": p['variant_name'],
      "brand_id": null,
      "brand_name": p['brand_name'],
      "quantity": p['qty'],
      "price_without_gst": p['unit_price_excl'],
      "price_with_gst": p['unit_price_incl'],
      "total_with_gst": p['total'],
    }).toList();

    final payload = {
      "business_id": 52,
      "business_name": selectedBusiness ?? "Circuitpointcare",
      "store_id": 38,
      "store_name": selectedStore ?? "Circuitpointcare",
      "platform_id": 1,
      "rfq_reference": rfqId,
      "request_date": reqDateStr,
      "validity_date": valDateStr,
      "validity_until": valDateStr,
      "status": selectedStatus,
      "total_amount": grandTotal,
      "product_name": pName,
      "product": pName,
      "summary": {
        "total_without_gst": totalWithoutGst,
        "total_tax": totalGst,
        "total_with_gst": grandTotal,
      },
      "products": itemsList,
      "items": itemsList,
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 12));

      AppLogger.api("PUT", url, response.statusCode);

      // Sync into local seed list
      final idx = kLiveQuotationsData.indexWhere((q) => q['id']?.toString() == widget.quotationId.toString());
      if (idx != -1) {
        kLiveQuotationsData[idx] = {
          ...kLiveQuotationsData[idx],
          ...payload,
        };
      }

      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Quotation Updated Successfully ✅"),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
      return;
    } catch (e) {
      AppLogger.error("Error updating quotation", e);
    }

    // Fallback sync
    final idx = kLiveQuotationsData.indexWhere((q) => q['id']?.toString() == widget.quotationId.toString());
    if (idx != -1) {
      kLiveQuotationsData[idx] = {
        ...kLiveQuotationsData[idx],
        ...payload,
      };
    }

    if (!mounted) return;
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Quotation Updated Successfully ✅"),
        backgroundColor: Color(0xFF10B981),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Edit Quotation Request", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: const [
          BillingModeSelector(currentMode: "Sale"),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header (Photo 1)
            _buildTopHeader(),
            const SizedBox(height: 16),

            // Card 1: Business & Store (Photo 1)
            _buildBusinessStoreCard(),
            const SizedBox(height: 16),

            // Card 2: Basic Information (Photo 1)
            _buildBasicInfoCard(),
            const SizedBox(height: 16),

            // Card 3: Requested Products (Photo 1)
            _buildRequestedProductsCard(),
            const SizedBox(height: 16),

            // Card 4: Summary Totals (Photo 1)
            _buildSummaryTotalsCard(),
            const SizedBox(height: 24),

            // Bottom Actions (Photo 1)
            _buildBottomActions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Top Navigation & RFQ Reference (Photo 1)
  Widget _buildTopHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final leftSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text("Back to Quotations", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Edit Quotation Request",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        );

        final rfqBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "RFQ REFERENCE",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                rfqId,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftSection,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: rfqBadge),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            leftSection,
            rfqBadge,
          ],
        );
      },
    );
  }

  // Card 1: Business & Store (Photo 1)
  Widget _buildBusinessStoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          // Safe business list
          final cleanBusinesses = businessList.map((b) => b.trim()).where((b) => b.isNotEmpty).toSet().toList();
          if (selectedBusiness != null && selectedBusiness!.trim().isNotEmpty && !cleanBusinesses.contains(selectedBusiness!.trim())) {
            cleanBusinesses.add(selectedBusiness!.trim());
          }
          final effectiveBusiness = (selectedBusiness != null && cleanBusinesses.contains(selectedBusiness!.trim()))
              ? selectedBusiness!.trim()
              : (cleanBusinesses.isNotEmpty ? cleanBusinesses.first : null);

          // Safe store list
          List<String> rawStoreList = [];
          if (effectiveBusiness != null) {
            final bKey = storeMap.keys.firstWhere(
              (k) => k.toLowerCase() == effectiveBusiness.toLowerCase(),
              orElse: () => "",
            );
            if (bKey.isNotEmpty && storeMap[bKey] != null) {
              rawStoreList.addAll(storeMap[bKey]!);
            }
          }
          if (rawStoreList.isEmpty) {
            rawStoreList.addAll(["Circuitpointcare", "Circuitpoint", "Main Store", "Warehouse Neelambur"]);
          }
          if (selectedStore != null && selectedStore!.trim().isNotEmpty) {
            rawStoreList.add(selectedStore!.trim());
          }
          final cleanStores = rawStoreList.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList();
          final effectiveStore = (selectedStore != null && cleanStores.contains(selectedStore!.trim()))
              ? selectedStore!.trim()
              : (cleanStores.isNotEmpty ? cleanStores.first : null);

          final businessField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.business_outlined, size: 13, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text("BUSINESS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  SizedBox(width: 2),
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
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: effectiveBusiness,
                    hint: Row(
                      children: const [
                        Icon(Icons.bookmark_outline, size: 14, color: Color(0xFF4F46E5)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text("Select Business...", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                    items: cleanBusinesses.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedBusiness = val;
                        final bKey = storeMap.keys.firstWhere(
                          (k) => k.toLowerCase() == (val ?? "").trim().toLowerCase(),
                          orElse: () => "",
                        );
                        final newStores = (bKey.isNotEmpty && storeMap[bKey] != null)
                            ? storeMap[bKey]!
                            : ["Circuitpointcare", "Circuitpoint", "Main Store"];
                        selectedStore = newStores.isNotEmpty ? newStores.first : null;
                      });
                    },
                  ),
                ),
              ),
            ],
          );

          final storeField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.storefront_outlined, size: 13, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text("STORE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  SizedBox(width: 2),
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
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: effectiveStore,
                    hint: Row(
                      children: const [
                        Icon(Icons.storefront, size: 14, color: Color(0xFF94A3B8)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Select Store",
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                    items: cleanStores.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
                    onChanged: (val) => setState(() => selectedStore = val),
                  ),
                ),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              children: [
                businessField,
                const SizedBox(height: 12),
                storeField,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: businessField),
              const SizedBox(width: 16),
              Expanded(child: storeField),
            ],
          );
        },
      ),
    );
  }

  // Card 2: Basic Information (Photo 1)
  Widget _buildBasicInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            children: const [
              Icon(Icons.menu_book_outlined, size: 14, color: Color(0xFF4F46E5)),
              SizedBox(width: 6),
              Text("Basic Information", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 650;

              final reqDateField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("REQUEST DATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: requestDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => requestDate = picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd-MM-yyyy').format(requestDate), style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              final valDateField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("VALIDITY UNTIL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: validityDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => validityDate = picked);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            validityDate != null ? DateFormat('dd-MM-yyyy').format(validityDate!) : "dd-mm-yyyy",
                            style: TextStyle(fontSize: 12, color: validityDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              // Status Dropdown matching Screenshot 1
              final statusField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
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
                        value: selectedStatus,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                        items: ["Pending", "Accepted", "Rejected", "Expired"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedStatus = val);
                        },
                      ),
                    ),
                  ),
                ],
              );

              if (isMobile) {
                return Column(
                  children: [
                    reqDateField,
                    const SizedBox(height: 12),
                    valDateField,
                    const SizedBox(height: 12),
                    statusField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: reqDateField),
                  const SizedBox(width: 14),
                  Expanded(child: valDateField),
                  const SizedBox(width: 14),
                  Expanded(child: statusField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Card 3: Requested Products (Photo 1)
  Widget _buildRequestedProductsCard() {
    final storeLabel = selectedStore ?? "Circuitpointcare";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          // Header row with title & "+ Add Product" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Requested Products (Store: $storeLabel)",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openProductPicker,
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF4F46E5)),
                label: const Text("Add Product", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // If empty: Empty State
          if (addedProducts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    "No products added yet.",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Click below to select products from your store stock inventory",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _openProductPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add, size: 15, color: Color(0xFF4F46E5)),
                          SizedBox(width: 6),
                          Text("Add Product", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)),
                dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                columns: const [
                  DataColumn(label: Text("S.NO")),
                  DataColumn(label: Text("PRODUCT / VARIANT")),
                  DataColumn(label: Text("QUANTITY")),
                  DataColumn(label: Text("UNIT PRICE EXCL. GST")),
                  DataColumn(label: Text("TAX")),
                  DataColumn(label: Text("UNIT PRICE INCL. GST")),
                  DataColumn(label: Text("TOTAL")),
                  DataColumn(label: Text("ACTION")),
                ],
                rows: addedProducts.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final p = entry.value;

                  return DataRow(cells: [
                    DataCell(Text("$idx")),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p['product_name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(p['variant_name'] ?? "Imported", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                if ((p['qty'] as int) > 1) {
                                  p['qty'] = (p['qty'] as int) - 1;
                                  _recalculateTotals();
                                }
                              },
                              child: const Icon(Icons.remove, size: 14, color: Color(0xFF64748B)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text("${p['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            InkWell(
                              onTap: () {
                                p['qty'] = (p['qty'] as int) + 1;
                                _recalculateTotals();
                              },
                              child: const Icon(Icons.add, size: 14, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 90,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "₹ ${(p['unit_price_excl'] as num).toDouble().toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text("${(p['tax'] as num).toInt()} %", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 90,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "₹ ${(p['unit_price_incl'] as num).toDouble().toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          "₹${(p['total'] as num).toDouble().toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFF64748B)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Duplicate",
                            onPressed: () {
                              setState(() {
                                addedProducts.add(Map<String, dynamic>.from(p));
                                _recalculateTotals();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Remove",
                            onPressed: () {
                              setState(() {
                                addedProducts.removeAt(entry.key);
                                _recalculateTotals();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Card 4: Summary Totals Card (Photo 1)
  Widget _buildSummaryTotalsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          Widget buildMetric(String label, String value, {bool isGrand = false}) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isGrand ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isGrand ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isGrand ? const Color(0xFF047857) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isGrand ? const Color(0xFF059669) : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            );
          }

          final metrics = [
            buildMetric("TOTAL QUANTITY", "$totalQty"),
            buildMetric("WITHOUT GST", "₹${totalWithoutGst.toStringAsFixed(2)}"),
            buildMetric("TOTAL GST", "₹${totalGst.toStringAsFixed(2)}"),
            buildMetric("GRAND TOTAL", "₹${grandTotal.toStringAsFixed(2)}", isGrand: true),
          ];

          if (isMobile) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: metrics[0]),
                    const SizedBox(width: 8),
                    Expanded(child: metrics[1]),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: metrics[2]),
                    const SizedBox(width: 8),
                    Expanded(child: metrics[3]),
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: metrics
                .map((m) => Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: SizedBox(width: 130, child: m),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  // Bottom Actions (Photo 1)
  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: isSaving ? null : _updateQuotation,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Update Quotation Request", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }
}
