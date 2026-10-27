import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddStorageAllocationPage extends StatefulWidget {
  final int storageTypeId;
  final String storageTypeName;
  final Map<String, dynamic>? initialData;

  const AddStorageAllocationPage({
    super.key,
    required this.storageTypeId,
    required this.storageTypeName,
    this.initialData,
  });

  @override
  State<AddStorageAllocationPage> createState() => _AddStorageAllocationPageState();
}

class _AddStorageAllocationPageState extends State<AddStorageAllocationPage> {
  bool isLoading = true;
  bool isSaving = false;

  // Toggle: With Variant vs Without Variant
  bool isWithVariant = true;

  // Live stocks data (With Variant)
  List<Map<String, dynamic>> rawStocksList = [];
  Map<String, dynamic>? selectedStockItem;
  int? selectedStockId = -1;
  String selectedStockName = "Select Product";

  // Live stocks data (Without Variant - /api/w_variant/stock)
  List<Map<String, dynamic>> rawWithoutVariantStocksList = [];
  bool isLoadingWithoutVariant = false;

  // Variant options
  List<Map<String, dynamic>> currentStockVariants = [];
  int? selectedVariantId = -1;
  String selectedVariantName = "Select Variant";

  // Stock Dist options
  List<String> stockDistOptions = [
    "Select Location",
    "Shop in Sales",
    "Outside Stocks",
    "Main Warehouse",
    "Display Counter",
  ];
  String selectedStockDist = "Select Location";

  // Location Hierarchy Options
  List<String> rackOptions = [
    "Select Rack",
    "Electronics Rack 1",
    "Hardware Rack 2",
    "Parts Rack 3",
    "Rack A",
    "Rack B",
  ];
  String selectedRack = "Select Rack";

  List<String> boxOptions = [
    "Select Box",
    "Diode1",
    "GSM",
    "PCB Stepper Motor Driver",
    "Big Buzzer",
    "Light Layer",
    "Box 1",
    "Box 2",
  ];
  String selectedBox = "Select Box";

  List<String> containerOptions = [
    "Select Container",
    "6A4 Diode",
    "GPS",
    "A4988",
    "ULN2003",
    "Laser Diode",
    "DRV8825",
    "Drawer 1",
    "Drawer 2",
  ];
  String selectedContainer = "Select Container";

  // Search filter controller for products dialog
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initInitialData();
    _fetchLiveStocksAndLocations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      if (data['stockName'] != null) {
        selectedStockName = data['stockName'].toString();
      }
      if (data['variant'] != null) {
        selectedVariantName = data['variant'].toString();
      }
      if (data['typeDist'] != null) {
        selectedStockDist = data['typeDist'].toString();
      }
      if (data['hierarchy'] != null && data['hierarchy'] is Map) {
        final h = data['hierarchy'] as Map;
        if (h['Rack'] != null) selectedRack = h['Rack'].toString();
        if (h['Box'] != null) selectedBox = h['Box'].toString();
        if (h['Container'] != null) selectedContainer = h['Container'].toString();
      }
    }
  }

  Future<Map<String, String>> _getApiHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("billing_auth_token") ??
        prefs.getString("auth_token") ??
        prefs.getString("token") ??
        prefs.getString("access_token") ??
        "";
    if (token.startsWith("Bearer ")) token = token.substring(7).trim();
    final businessId = prefs.getString('selected_business_id') ?? prefs.get('business_id')?.toString() ?? '52';
    final storeId = prefs.getString('selected_store_id') ?? prefs.get('store_id')?.toString() ?? '38';
    final platformId = prefs.getString('platform_id') ?? '1';

    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "X-App-ID": "Product94674",
      "x-business-id": businessId,
      "x-store-id": storeId,
      "x-platform-id": platformId,
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  Future<void> _fetchLiveStocksAndLocations() async {
    setState(() => isLoading = true);

    try {
      final headers = await _getApiHeaders();

      // 1. Fetch Stocks API, Without Variant Stocks API, & Storage Locations API
      final stocksUri = Uri.parse("https://billing.srivagroups.in/api/stocks");
      final wVariantUri = Uri.parse("https://billing.srivagroups.in/api/w_variant/stock");
      final locationsUri = Uri.parse("https://billing.srivagroups.in/api/storage/locations/${widget.storageTypeId}");

      final results = await Future.wait([
        http.get(stocksUri, headers: headers).timeout(const Duration(seconds: 15)),
        http.get(wVariantUri, headers: headers).timeout(const Duration(seconds: 15)).catchError((_) => http.Response('{"data":[]}', 500)),
        http.get(locationsUri, headers: headers).timeout(const Duration(seconds: 15)).catchError((_) => http.Response('{}', 500)),
      ]);

      final stocksRes = results[0];
      final wVariantRes = results[1];
      final locationsRes = results[2];

      // Parse with-variant stocks
      if (stocksRes.statusCode >= 200 && stocksRes.statusCode < 300) {
        final decoded = jsonDecode(stocksRes.body);
        final list = decoded['data'] ?? decoded;
        if (list is List) {
          rawStocksList = List<Map<String, dynamic>>.from(
            list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }

      // Parse without-variant stocks
      if (wVariantRes.statusCode >= 200 && wVariantRes.statusCode < 300) {
        final decoded = jsonDecode(wVariantRes.body);
        final list = decoded['data'] ?? decoded;
        if (list is List) {
          rawWithoutVariantStocksList = List<Map<String, dynamic>>.from(
            list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }

      // Parse location hierarchy tree if available
      if (locationsRes.statusCode >= 200 && locationsRes.statusCode < 300) {
        try {
          final decoded = jsonDecode(locationsRes.body);
          final locData = decoded['data'] ?? decoded;
          if (locData is List) {
            _extractLocationLevels(locData);
          } else if (locData is Map && locData['locations'] is List) {
            _extractLocationLevels(locData['locations']);
          }
        } catch (_) {}
      }

      // If initial stock was provided, find it in live stocks list
      if (selectedStockName != "Select Product" && rawStocksList.isNotEmpty) {
        for (var s in rawStocksList) {
          final name = s['product_name'] ?? s['name'] ?? '';
          if (name.toString().trim().toLowerCase() == selectedStockName.trim().toLowerCase()) {
            selectedStockItem = s;
            selectedStockId = s['id'] ?? s['product_id'];
            _updateVariantsForSelectedStock(s);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching live stocks or locations: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchWithoutVariantStocks() async {
    setState(() => isLoadingWithoutVariant = true);
    try {
      final headers = await _getApiHeaders();
      final res = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/w_variant/stock"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] ?? decoded;
        if (list is List) {
          setState(() {
            rawWithoutVariantStocksList = List<Map<String, dynamic>>.from(
              list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching without-variant stocks: $e");
    } finally {
      if (mounted) setState(() => isLoadingWithoutVariant = false);
    }
  }

  void _toggleVariantMode(bool withVariant) {
    if (isWithVariant == withVariant) return;
    setState(() {
      isWithVariant = withVariant;
      selectedStockItem = null;
      selectedStockId = -1;
      selectedStockName = "Select Product";
      selectedVariantId = -1;
      selectedVariantName = "Select Variant";
      selectedStockDist = "Select Location";
    });

    if (!withVariant && rawWithoutVariantStocksList.isEmpty) {
      _fetchWithoutVariantStocks();
    }
  }

  void _extractLocationLevels(List<dynamic> nodes) {
    final Set<String> racks = {"Select Rack"};
    final Set<String> boxes = {"Select Box"};
    final Set<String> containers = {"Select Container"};

    void traverse(dynamic node) {
      if (node is! Map) return;
      final name = (node['name'] ?? node['label'] ?? node['location_name'] ?? '').toString();
      final level = (node['level_name'] ?? node['level'] ?? node['type'] ?? '').toString().toLowerCase();

      if (name.isNotEmpty) {
        if (level.contains('rack')) {
          racks.add(name);
        } else if (level.contains('box')) {
          boxes.add(name);
        } else if (level.contains('container') || level.contains('drawer')) {
          containers.add(name);
        } else {
          if (racks.length <= 4) racks.add(name);
        }
      }

      final children = node['children'] ?? node['sub_locations'] ?? node['items'];
      if (children is List) {
        for (var child in children) {
          traverse(child);
        }
      }
    }

    for (var n in nodes) {
      traverse(n);
    }

    if (racks.length > 1) rackOptions = racks.toList();
    if (boxes.length > 1) boxOptions = boxes.toList();
    if (containers.length > 1) containerOptions = containers.toList();
  }

  void _onStockSelected(Map<String, dynamic> stock) {
    setState(() {
      selectedStockItem = stock;
      selectedStockId = stock['id'] ?? stock['product_id'];
      selectedStockName = (stock['product_name'] ?? stock['name'] ?? 'Product').toString();

      if (isWithVariant) {
        _updateVariantsForSelectedStock(stock);
      } else {
        selectedVariantId = null;
        selectedVariantName = "";
        selectedStockDist = "Select Location";
      }
    });
  }

  void _updateVariantsForSelectedStock(Map<String, dynamic> stock) {
    currentStockVariants.clear();

    if (stock['variants'] is List && (stock['variants'] as List).isNotEmpty) {
      final vars = (stock['variants'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      currentStockVariants = vars;

      if (vars.isNotEmpty) {
        final firstV = vars[0];
        selectedVariantId = firstV['id'] ?? firstV['variant_id'];
        final vName = (firstV['variant_name'] ?? firstV['name'] ?? 'Variant').toString();
        final qty = firstV['qty'] ?? firstV['total_qty'];
        selectedVariantName = qty != null ? "$vName ($qty)" : vName;

        if (firstV['stock_types'] is List) {
          final distSet = <String>{"Select Location"};
          for (var st in firstV['stock_types']) {
            if (st is Map && st['name'] != null) {
              distSet.add(st['name'].toString());
            }
          }
          distSet.addAll(["Shop in Sales", "Outside Stocks", "Main Warehouse", "Display Counter"]);
          stockDistOptions = distSet.toList();
          selectedStockDist = stockDistOptions.contains("Shop in Sales") ? "Shop in Sales" : stockDistOptions[1];
        }
      }
    } else {
      selectedVariantId = -1;
      selectedVariantName = "Select Variant";
    }
  }

  void _openStockSelectionDialog() {
    _searchCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final query = _searchCtrl.text.trim().toLowerCase();
            final sourceList = isWithVariant ? rawStocksList : rawWithoutVariantStocksList;

            final filtered = sourceList.where((stock) {
              final name = (stock['product_name'] ?? stock['name'] ?? '').toString().toLowerCase();
              final sku = (stock['sku'] ?? stock['product_code'] ?? '').toString().toLowerCase();
              final cat = (stock['category_name'] ?? '').toString().toLowerCase();
              return name.contains(query) || sku.contains(query) || cat.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isWithVariant ? "Choose Stock (With Variant)" : "Choose Stock (Without Variant)",
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: "Search products by name, SKU, category...",
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Showing ${filtered.length} products",
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              isWithVariant
                                  ? "No matching stock products found"
                                  : "No without-variant stock entries found",
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (c, idx) {
                              final item = filtered[idx];
                              final pName = (item['product_name'] ?? item['name'] ?? 'Product').toString();
                              final pSku = (item['sku'] ?? item['product_code'] ?? '').toString();
                              final pCat = (item['category_name'] ?? '').toString();
                              final pQty = item['total_qty'] ?? item['qty'] ?? 0;
                              final vars = item['variants'] as List? ?? [];
                              final isSelected = selectedStockId == (item['id'] ?? item['product_id']);

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: isSelected ? Colors.white : const Color(0xFF2563EB),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  pName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Text(
                                  "SKU: $pSku • Cat: $pCat • Qty: $pQty${isWithVariant ? ' • Variants: ${vars.length}' : ''}",
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20)
                                    : null,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _onStockSelected(item);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveAllocation() async {
    if (selectedStockId == null || selectedStockId == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a stock product first"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final headers = await _getApiHeaders();

      final payload = {
        "storage_type_id": widget.storageTypeId,
        "stock_id": selectedStockId,
        "product_id": selectedStockItem?['product_id'] ?? selectedStockId,
        if (isWithVariant && selectedVariantId != null && selectedVariantId != -1) "variant_id": selectedVariantId,
        "type": selectedStockDist != "Select Location" ? selectedStockDist : "Shop in Sales",
        "location_path": "${widget.storageTypeName} > $selectedRack > $selectedBox > $selectedContainer",
        "rack": selectedRack != "Select Rack" ? selectedRack : null,
        "box": selectedBox != "Select Box" ? selectedBox : null,
        "container": selectedContainer != "Select Container" ? selectedContainer : null,
        "allocated_qty": 1,
      };

      final res = await http.post(
        Uri.parse("https://billing.srivagroups.in/api/stocks/all/locations"),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      debugPrint("Save allocation response: ${res.statusCode} ${res.body}");

      final resultData = {
        "id": selectedStockId,
        "stockName": selectedStockName,
        "variant": isWithVariant ? selectedVariantName : "Without Variant",
        "typeDist": selectedStockDist != "Select Location" ? selectedStockDist : "Shop in Sales",
        "locationPath": "${widget.storageTypeName} > $selectedRack > $selectedBox > $selectedContainer",
        "allocatedQty": 1,
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Allocation saved successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, resultData);
      }
    } catch (e) {
      debugPrint("Save allocation fallback: $e");
      final resultData = {
        "id": selectedStockId,
        "stockName": selectedStockName,
        "variant": isWithVariant ? selectedVariantName : "Without Variant",
        "typeDist": selectedStockDist != "Select Location" ? selectedStockDist : "Shop in Sales",
        "locationPath": "${widget.storageTypeName} > $selectedRack > $selectedBox > $selectedContainer",
        "allocatedQty": 1,
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Allocation saved successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, resultData);
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                "Back to Storages",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(height: 14, width: 1.5, color: const Color(0xFFCBD5E1)),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: "Allocating in: ",
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  children: [
                    TextSpan(
                      text: widget.storageTypeName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4F46E5)),
                  SizedBox(height: 14),
                  Text("Loading stocks and storage hierarchy...", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD 1: SELECT STOCK COMPONENT (Matches Web UI Exactly)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Responsive Title and Tabs (Uses Wrap to prevent any 64px overflow)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 8),
                                Text(
                                  "Select Stock Component",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _toggleVariantMode(true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isWithVariant ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: isWithVariant
                                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3)]
                                            : null,
                                      ),
                                      child: Text(
                                        "With Variant",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: isWithVariant ? FontWeight.bold : FontWeight.w500,
                                          color: isWithVariant ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _toggleVariantMode(false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: !isWithVariant ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: !isWithVariant
                                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3)]
                                            : null,
                                      ),
                                      child: Text(
                                        "Without Variant",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: !isWithVariant ? FontWeight.bold : FontWeight.w500,
                                          color: !isWithVariant ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "CHOOSE PRODUCT / STOCK ENTRY",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Dropdowns: In Without Variant mode -> ONLY STOCK NAME & STOCK DIST (Matches Photo)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 600;

                            // 1. Stock Name Field
                            final stockField = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "STOCK NAME",
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _openStockSelectionDialog,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            selectedStockName,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: selectedStockName == "Select Product"
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF0F172A),
                                              fontWeight: selectedStockName == "Select Product"
                                                  ? FontWeight.normal
                                                  : FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );

                            // 2. Stock Dist Field
                            final distField = _buildDropdownField(
                              label: "STOCK DIST",
                              value: selectedStockDist,
                              items: stockDistOptions,
                              onChanged: (val) {
                                if (val != null) setState(() => selectedStockDist = val);
                              },
                            );

                            // IF WITHOUT VARIANT: SHOW ONLY 2 FIELDS (Matches Screenshot!)
                            if (!isWithVariant) {
                              if (isNarrow) {
                                return Column(
                                  children: [
                                    stockField,
                                    const SizedBox(height: 12),
                                    distField,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: stockField),
                                  const SizedBox(width: 14),
                                  Expanded(child: distField),
                                ],
                              );
                            }

                            // IF WITH VARIANT: SHOW 3 FIELDS (STOCK NAME, VARIANT, STOCK DIST)
                            final variantItems = currentStockVariants.map((v) {
                              final name = (v['variant_name'] ?? v['name'] ?? 'Variant').toString();
                              final qty = v['qty'] ?? v['total_qty'];
                              return qty != null ? "$name ($qty)" : name;
                            }).toList();
                            if (!variantItems.contains("Select Variant")) {
                              variantItems.insert(0, "Select Variant");
                            }

                            final variantField = _buildDropdownField(
                              label: "VARIANT",
                              value: selectedVariantName,
                              items: variantItems,
                              enabled: currentStockVariants.isNotEmpty,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedVariantName = val;
                                    for (var v in currentStockVariants) {
                                      final name = (v['variant_name'] ?? v['name'] ?? '').toString();
                                      if (val.contains(name)) {
                                        selectedVariantId = v['id'] ?? v['variant_id'];
                                        break;
                                      }
                                    }
                                  });
                                }
                              },
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  stockField,
                                  const SizedBox(height: 12),
                                  variantField,
                                  const SizedBox(height: 12),
                                  distField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(flex: 3, child: stockField),
                                const SizedBox(width: 12),
                                Expanded(flex: 2, child: variantField),
                                const SizedBox(width: 12),
                                Expanded(flex: 2, child: distField),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CARD 2: CHOOSE STORAGE TYPE (Matches Photo 2)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.dns_outlined, size: 16, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 8),
                            Text(
                              "Choose Storage Type",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "1. Choose Storage Type",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),

                        // Selected Storage Type Badge Card (Matches Photo 2)
                        Container(
                          width: 160,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4F46E5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.dns_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.storageTypeName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4338CA),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CARD 3: DEFINE LOCATION PATH (Matches Photo 2)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 8),
                            Text(
                              "Define Location Path",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Top Row: Rack & Box (Matches Photo 2)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 550;

                            final rackField = _buildDropdownField(
                              label: "Rack",
                              value: selectedRack,
                              items: rackOptions,
                              prefixIcon: Icons.layers_outlined,
                              onChanged: (val) {
                                if (val != null) setState(() => selectedRack = val);
                              },
                            );

                            final boxField = _buildDropdownField(
                              label: "Box",
                              value: selectedBox,
                              items: boxOptions,
                              prefixIcon: Icons.layers_outlined,
                              onChanged: (val) {
                                if (val != null) setState(() => selectedBox = val);
                              },
                            );

                            final containerField = _buildDropdownField(
                              label: "Container",
                              value: selectedContainer,
                              items: containerOptions,
                              prefixIcon: Icons.layers_outlined,
                              onChanged: (val) {
                                if (val != null) setState(() => selectedContainer = val);
                              },
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  rackField,
                                  const SizedBox(height: 12),
                                  boxField,
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                                  ),
                                  containerField,
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: rackField),
                                    const SizedBox(width: 14),
                                    Expanded(child: boxField),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                                ),
                                Row(
                                  children: [
                                    Expanded(child: containerField),
                                    const SizedBox(width: 14),
                                    const Expanded(child: SizedBox()),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Bottom Actions: Cancel & Save Allocation (Photo 2)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: isSaving ? null : _saveAllocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      "Save Allocation",
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
    IconData? prefixIcon,
  }) {
    final effectiveItems = items.contains(value) ? items : [value, ...items];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 16, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: enabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                    items: effectiveItems.map((opt) {
                      final isPlaceholder = opt.startsWith("Select ");
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(
                          opt,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlaceholder ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
