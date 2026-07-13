import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class AddStorageAllocationPage extends StatefulWidget {
  final int storageTypeId;
  final String storageTypeName;

  const AddStorageAllocationPage({
    super.key,
    required this.storageTypeId,
    required this.storageTypeName,
  });

  @override
  State<AddStorageAllocationPage> createState() => _AddStorageAllocationPageState();
}

class _AddStorageAllocationPageState extends State<AddStorageAllocationPage> {
  bool _isLoading = true;
  String _errorMessage = '';

  // Data Lists from API
  List<dynamic> _stocksList = [];
  List<dynamic> _allVariantsList = [];
  List<dynamic> _structureLevels = [];
  List<dynamic> _rawLocationsList = [];

  // Dropdown Selections
  Map<String, dynamic>? _selectedStock;
  Map<String, dynamic>? _selectedVariant;
  String? _selectedDist;
  
  // Dynamic cascading selections map: levelOrder -> selectedLocationNode Map
  final Map<int, Map<String, dynamic>?> _selectedLocations = {};

  // Selected Partition
  String? _selectedPartition;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token.isNotEmpty) "Authorization": "Bearer $token",
      };

      print("--------------------------------------------------");
      print("\$print debug: STARTING API calls for Add Storage Allocation Screen");

      // 1. Fetch Stocks
      final stocksUri = Uri.parse("https://billing.srivagroups.in/api/stocks");
      print("\$print debug: GET $stocksUri");
      final stocksRes = await http.get(stocksUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Stocks Status Code: ${stocksRes.statusCode}");
      try {
        final decoded = jsonDecode(stocksRes.body);
        _stocksList = decoded['data'] ?? decoded ?? [];
        print("\$print debug: Stocks Response:\n${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (e) {
        print("\$print debug: Stocks Response (Raw): ${stocksRes.body}");
      }

      // 2. Fetch Variants
      final variantsUri = Uri.parse("https://billing.srivagroups.in/api/variant-master");
      print("\$print debug: GET $variantsUri");
      final variantsRes = await http.get(variantsUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Variant Master Status Code: ${variantsRes.statusCode}");
      try {
        final decoded = jsonDecode(variantsRes.body);
        _allVariantsList = decoded['data'] ?? decoded ?? [];
        print("\$print debug: Variant Master Response:\n${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (e) {
        print("\$print debug: Variant Master Response (Raw): ${variantsRes.body}");
      }

      // 3. Fetch Structure of selected Storage Type
      final structureUri = Uri.parse("https://billing.srivagroups.in/api/storage/structure/${widget.storageTypeId}");
      print("\$print debug: GET $structureUri");
      final structureRes = await http.get(structureUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Storage Structure Status Code: ${structureRes.statusCode}");
      try {
        final decoded = jsonDecode(structureRes.body);
        final List list = decoded['data'] ?? decoded ?? [];
        list.sort((a, b) => (a['level_order'] ?? 0).compareTo(b['level_order'] ?? 0));
        _structureLevels = list;
        print("\$print debug: Storage Structure Response:\n${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (e) {
        print("\$print debug: Storage Structure Response (Raw): ${structureRes.body}");
      }

      // 4. Fetch Locations of selected Storage Type
      final locationsUri = Uri.parse("https://billing.srivagroups.in/api/storage/locations/${widget.storageTypeId}");
      print("\$print debug: GET $locationsUri");
      final locationsRes = await http.get(locationsUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Storage Locations Status Code: ${locationsRes.statusCode}");
      try {
        final decoded = jsonDecode(locationsRes.body);
        _rawLocationsList = decoded['data'] ?? decoded['locations'] ?? decoded['hierarchy'] ?? decoded ?? [];
        print("\$print debug: Storage Locations Response:\n${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (e) {
        print("\$print debug: Storage Locations Response (Raw): ${locationsRes.body}");
      }
      print("--------------------------------------------------");

      // Initialize selectedLocations keys
      for (var level in _structureLevels) {
        final int order = level['level_order'] ?? 0;
        _selectedLocations[order] = null;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("\$print debug: Error fetching allocation data: $e");
      setState(() {
        _errorMessage = 'Error loading page configurations: $e';
        _isLoading = false;
      });
    }
  }

  // Flatten nested storage location tree into a single list of maps
  List<Map<String, dynamic>> _flattenLocations(List<dynamic> treeList) {
    final List<Map<String, dynamic>> flat = [];
    
    void traverse(dynamic node, int? parentId) {
      if (node is! Map) return;
      final mapNode = Map<String, dynamic>.from(node);
      final int? id = mapNode['id'] ?? mapNode['location_id'];
      if (id == null) return;
      
      final resolvedParentId = mapNode['parent_id'] ?? parentId;
      
      flat.add({
        'id': id,
        'name': (mapNode['name'] ?? mapNode['location_name'] ?? '').toString(),
        'parent_id': resolvedParentId,
        'partition_rows': mapNode['partition_rows'],
        'partition_columns': mapNode['partition_columns'],
      });
      
      final children = mapNode['children'];
      if (children is List) {
        for (var child in children) {
          traverse(child, id);
        }
      }
    }
    
    for (var root in treeList) {
      traverse(root, null);
    }
    
    return flat;
  }

  // Get options for a cascading location dropdown
  List<Map<String, dynamic>> _getLocationDropdownOptions(int levelOrder, int? levelId) {
    final flatList = _flattenLocations(_rawLocationsList);
    if (flatList.isEmpty) return [];

    // For level order 1 (Building / Root), parent_id is null
    if (levelOrder == 1) {
      return flatList.where((loc) => loc['parent_id'] == null).toList();
    }

    // Otherwise, filter where parent_id is the selected ID of the previous level
    final previousSelected = _selectedLocations[levelOrder - 1];
    if (previousSelected == null) return [];

    final prevId = previousSelected['id'];
    return flatList.where((loc) => loc['parent_id'] == prevId).toList();
  }

  // Helper to get variants list for selected stock
  List<Map<String, dynamic>> _getAvailableVariants() {
    if (_selectedStock == null) return [];
    
    // Check if selected stock contains embedded variants list
    final stockId = _selectedStock!['id'] ?? _selectedStock!['product_id'];
    final embedded = _selectedStock!['variants'];
    if (embedded is List && embedded.isNotEmpty) {
      return List<Map<String, dynamic>>.from(embedded);
    }

    // Fallback: search variant-master list for matching product_id
    return List<Map<String, dynamic>>.from(
      _allVariantsList.where((v) => v is Map && (v['product_id'] == stockId || v['stock_id'] == stockId))
    );
  }

  // Helper to get stock distribution quantities for selected variant
  List<Map<String, String>> _getDistOptions() {
    if (_selectedVariant == null) return [];
    
    int displayQty = 0;
    int shopQty = 0;
    int outsideQty = 0;

    final stockTypes = _selectedVariant!['stock_types'];
    if (stockTypes is List) {
      for (var st in stockTypes) {
        if (st is Map) {
          final String name = (st['name'] ?? '').toString().toLowerCase();
          final int quantity = int.tryParse(st['qty']?.toString() ?? '') ?? 0;
          if (name.contains('display')) {
            displayQty = quantity;
          } else if (name.contains('shop')) {
            shopQty = quantity;
          } else if (name.contains('outside')) {
            outsideQty = quantity;
          }
        }
      }
    } else {
      displayQty = int.tryParse(_selectedVariant!['display_qty']?.toString() ?? '') ?? 
                   int.tryParse(_selectedVariant!['display']?.toString() ?? '') ?? 0;
      shopQty = int.tryParse(_selectedVariant!['shop_qty']?.toString() ?? '') ?? 
                int.tryParse(_selectedVariant!['shop']?.toString() ?? '') ?? 0;
      outsideQty = int.tryParse(_selectedVariant!['outside_qty']?.toString() ?? '') ?? 
                   int.tryParse(_selectedVariant!['outside']?.toString() ?? '') ?? 0;
    }

    return [
      {"name": "Display", "label": "Display ($displayQty)"},
      {"name": "Shop", "label": "Shop ($shopQty)"},
      {"name": "Outside", "label": "Outside ($outsideQty)"},
    ];
  }

  // Generate partition labels based on row and column counts
  List<String> _generatePartitions(int rows, int cols) {
    final List<String> list = [];
    if (rows > 0 && cols > 0) {
      for (int r = 0; r < rows; r++) {
        final String letter = String.fromCharCode(65 + r); // A, B, C...
        for (int c = 1; c <= cols; c++) {
          list.add("$letter$c");
        }
      }
    } else if (rows > 0) {
      for (int r = 0; r < rows; r++) {
        list.add(String.fromCharCode(65 + r));
      }
    } else if (cols > 0) {
      for (int c = 1; c <= cols; c++) {
        list.add("$c");
      }
    }
    return list;
  }

  // Retrieve selected leaf box map from dropdown allocations
  Map<String, dynamic>? _getSelectedLeafBox() {
    if (_structureLevels.isEmpty) return null;
    final lastLevel = _structureLevels.last;
    final int lastOrder = lastLevel['level_order'] ?? _structureLevels.length;
    return _selectedLocations[lastOrder];
  }

  Future<void> _saveAllocation() async {
    if (_selectedStock == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a product")));
      return;
    }
    if (_selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a variant")));
      return;
    }
    if (_selectedDist == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a stock distribution type")));
      return;
    }

    // Get the leaf location ID (last selected level)
    int? leafLocationId;
    for (int i = _structureLevels.length; i >= 1; i--) {
      final levelOrder = _structureLevels[i - 1]['level_order'] ?? i;
      final selectedLocNode = _selectedLocations[levelOrder];
      if (selectedLocNode != null) {
        leafLocationId = selectedLocNode['id'];
        break;
      }
    }

    if (leafLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please define the location path")));
      return;
    }

    // Dynamic qty determination: send the quantity of selected distribution, fallback to 1
    int targetQty = 1;
    final distOptions = _getDistOptions();
    for (var opt in distOptions) {
      if (opt['name'] == _selectedDist) {
        final label = opt['label'] ?? '';
        final match = RegExp(r'\((\d+)\)').firstMatch(label);
        if (match != null) {
          targetQty = int.tryParse(match.group(1) ?? '1') ?? 1;
        }
      }
    }

    // Show loading progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final url = "https://billing.srivagroups.in/api/stocks/all/locations";

      final stockId = _selectedStock!['id'] ?? _selectedStock!['product_id'] ?? 0;
      final variantId = _selectedVariant!['id'] ?? 0;

      // Construct request payload
      final payload = {
        "stock_id": stockId,
        "product_id": stockId,
        "variant_id": variantId,
        "product_variant_id": variantId,
        "storage_type_id": widget.storageTypeId,
        "storage_location_id": leafLocationId,
        "location_id": leafLocationId,
        "type": _selectedDist,
        "qty": targetQty,
        if (_selectedPartition != null) ...{
          "partition": _selectedPartition,
          "partition_name": _selectedPartition,
          "location_partition": _selectedPartition,
        }
      };

      print("--------------------------------------------------");
      print("\$print debug: POST request started to $url");
      print("\$print debug: Request Payload:\n${const JsonEncoder.withIndent('  ').convert(payload)}");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      print("\$print debug: POST Response Status Code: ${response.statusCode}");
      print("\$print debug: POST Response Body: ${response.body}");
      print("--------------------------------------------------");

      // Close progress dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Stock allocation successfully saved!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to save allocation. Status: ${response.statusCode}"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      print("\$print debug: Error posting allocation: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving allocation: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic matching of selected stock ID
    final int? selectedStockId = _selectedStock != null 
        ? (_selectedStock!['id'] ?? _selectedStock!['product_id']) as int?
        : null;

    // Dynamic matching of selected variant ID
    final int? selectedVariantId = _selectedVariant != null 
        ? (_selectedVariant!['id']) as int?
        : null;

    // Retrieve active leaf box and generate partitions
    final leafBox = _getSelectedLeafBox();
    final int rows = leafBox != null ? int.tryParse(leafBox['partition_rows']?.toString() ?? '') ?? 0 : 0;
    final int cols = leafBox != null ? int.tryParse(leafBox['partition_columns']?.toString() ?? '') ?? 0 : 0;
    final hasPartitions = rows > 0 || cols > 0;
    final partitionList = hasPartitions ? _generatePartitions(rows, cols) : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                "Back to Storages",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 16,
              width: 1.5,
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: "Allocating in: ",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                  children: [
                    TextSpan(
                      text: widget.storageTypeName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // CARD 1: SELECT STOCK COMPONENT
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.widgets_outlined, color: Color(0xFF4F46E5), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Select Stock Component",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "CHOOSE PRODUCT / STOCK ENTRY",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // STOCK NAME DROPDOWN
                              Text(
                                "STOCK NAME",
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  color: const Color(0xFFF8FAFC),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedStockId,
                                    hint: Text("Select Product", style: GoogleFonts.inter(fontSize: 14)),
                                    isExpanded: true,
                                    items: () {
                                      final seenIds = <int>{};
                                      final list = <DropdownMenuItem<int>>[];
                                      for (var item in _stocksList) {
                                        if (item is! Map) continue;
                                        final id = item['id'] ?? item['product_id'];
                                        if (id == null || id is! int) continue;
                                        if (seenIds.contains(id)) continue;
                                        seenIds.add(id);
                                        
                                        final name = (item['product_name'] ?? item['name'] ?? 'Unnamed Product').toString();
                                        list.add(DropdownMenuItem<int>(
                                          value: id,
                                          child: Text(name, style: GoogleFonts.inter(fontSize: 14)),
                                        ));
                                      }
                                      return list;
                                    }(),
                                    onChanged: (val) {
                                      setState(() {
                                        Map<String, dynamic>? foundStock;
                                        for (var item in _stocksList) {
                                          if (item is Map && (item['id'] == val || item['product_id'] == val)) {
                                            foundStock = Map<String, dynamic>.from(item);
                                            break;
                                          }
                                        }
                                        _selectedStock = foundStock;
                                        _selectedVariant = null;
                                        _selectedDist = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Row for Variant and Stock Dist
                              Row(
                                children: [
                                  // VARIANT DROPDOWN
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "VARIANT",
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFCBD5E1)),
                                            color: const Color(0xFFF8FAFC),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              value: selectedVariantId,
                                              hint: Text("Select Variant", style: GoogleFonts.inter(fontSize: 14)),
                                              isExpanded: true,
                                              items: () {
                                                final seenIds = <int>{};
                                                final list = <DropdownMenuItem<int>>[];
                                                final variants = _getAvailableVariants();
                                                for (var item in variants) {
                                                  if (item is! Map) continue;
                                                  final id = item['id'] ?? item['variant_id'];
                                                  if (id == null || id is! int) continue;
                                                  if (seenIds.contains(id)) continue;
                                                  seenIds.add(id);
                                                  
                                                  final name = (item['name'] ?? item['variant_name'] ?? 'Unnamed').toString();
                                                  
                                                  // Read total quantity from stock entry variant
                                                  final totalQty = item['qty'] ?? item['quantity'] ?? 0;
                                                  list.add(DropdownMenuItem<int>(
                                                    value: id,
                                                    child: Text("$name ($totalQty)", style: GoogleFonts.inter(fontSize: 14)),
                                                  ));
                                                }
                                                return list;
                                              }(),
                                              onChanged: _selectedStock == null
                                                  ? null
                                                  : (val) {
                                                      setState(() {
                                                        final variants = _getAvailableVariants();
                                                        Map<String, dynamic>? foundVariant;
                                                        for (var item in variants) {
                                                          if (item is Map && (item['id'] == val || item['variant_id'] == val)) {
                                                            foundVariant = Map<String, dynamic>.from(item);
                                                            break;
                                                          }
                                                        }
                                                        _selectedVariant = foundVariant;
                                                        _selectedDist = null;
                                                      });
                                                    },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // STOCK DIST DROPDOWN
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "STOCK DIST",
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFCBD5E1)),
                                            color: const Color(0xFFF8FAFC),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedDist,
                                              hint: Text("Select Location", style: GoogleFonts.inter(fontSize: 14)),
                                              isExpanded: true,
                                              items: _getDistOptions().map((opt) {
                                                return DropdownMenuItem<String>(
                                                  value: opt['name'],
                                                  child: Text(opt['label']!, style: GoogleFonts.inter(fontSize: 14)),
                                                );
                                              }).toList(),
                                              onChanged: _selectedVariant == null
                                                  ? null
                                                  : (val) {
                                                      setState(() {
                                                        _selectedDist = val;
                                                      });
                                                    },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // CARD 2: DEFINE LOCATION PATH
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.account_tree_outlined, color: Color(0xFF7C3AED), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Define Location Path",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              if (_structureLevels.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Center(
                                    child: Text(
                                      "No structures defined for this storage type.",
                                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                                    ),
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 2.1,
                                  ),
                                  itemCount: _structureLevels.length,
                                  itemBuilder: (context, idx) {
                                    final level = _structureLevels[idx];
                                    final String name = (level['name'] ?? 'Level').toString();
                                    final int order = level['level_order'] ?? (idx + 1);
                                    final int? levelId = level['id'];

                                    final selectedVal = _selectedLocations[order];
                                    final options = _getLocationDropdownOptions(order, levelId);

                                    // Capitalize level name
                                    final String formattedLabel = name.isNotEmpty
                                        ? '${name[0].toUpperCase()}${name.substring(1)}'
                                        : 'Level';

                                    // Check if previous dropdown has selection (except for level 1)
                                    final bool isEnabled = order == 1 || _selectedLocations[order - 1] != null;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formattedLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isEnabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isEnabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                                            ),
                                            color: isEnabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              value: selectedVal != null ? selectedVal['id'] as int? : null,
                                              disabledHint: Text("Select $formattedLabel", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                                              hint: Text("Select $formattedLabel", style: GoogleFonts.inter(fontSize: 13)),
                                              isExpanded: true,
                                              items: isEnabled
                                                  ? () {
                                                      final seenIds = <int>{};
                                                      final list = <DropdownMenuItem<int>>[];
                                                      for (var opt in options) {
                                                        final id = opt['id'];
                                                        if (id == null || id is! int) continue;
                                                        if (seenIds.contains(id)) continue;
                                                        seenIds.add(id);
                                                        
                                                        list.add(DropdownMenuItem<int>(
                                                          value: id,
                                                          child: Text(opt['name'].toString(), style: GoogleFonts.inter(fontSize: 13)),
                                                        ));
                                                      }
                                                      return list;
                                                    }()
                                                  : [],
                                              onChanged: isEnabled
                                                  ? (val) {
                                                      setState(() {
                                                        Map<String, dynamic>? foundLoc;
                                                        for (var opt in options) {
                                                          if (opt['id'] == val) {
                                                            foundLoc = opt;
                                                            break;
                                                          }
                                                        }
                                                        _selectedLocations[order] = foundLoc;
                                                        // Clear selected partition when location changes
                                                        _selectedPartition = null;
                                                        // Clear all cascading lower levels
                                                        for (int o = order + 1; o <= _structureLevels.length; o++) {
                                                          _selectedLocations[o] = null;
                                                        }
                                                      });
                                                    }
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // DYNAMIC SELECTED BOX DETAILS (PARTITIONS SECTION)
                        if (hasPartitions && leafBox != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.grid_view_rounded, color: Color(0xFF16A34A), size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Selected Box Details - ${leafBox['name']}",
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: partitionList.map((part) {
                                    final bool isSelected = _selectedPartition == part;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedPartition = part;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                                            width: isSelected ? 2.0 : 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          part,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // CANCEL & SAVE BUTTONS ROW
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                ),
                                onPressed: _saveAllocation,
                                child: Text(
                                  "Save Allocation",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }
}
