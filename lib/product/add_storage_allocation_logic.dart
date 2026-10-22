part of 'add_storage_allocation.dart';

mixin AddStorageAllocationLogic on State<AddStorageAllocationPage> {
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
      print("\$print debug: GET \$stocksUri");
      final stocksRes = await http.get(stocksUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Stocks Status Code: \${stocksRes.statusCode}");
      try {
        final decoded = jsonDecode(stocksRes.body);
        _stocksList = decoded['data'] ?? decoded ?? [];
        print("\$print debug: Stocks Response:\n\${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (e) {
        print("\$print debug: Stocks Response (Raw): \${stocksRes.body}");
      }

      // 2. Fetch Variants
      final variantsUri = Uri.parse("https://billing.srivagroups.in/api/variant-master");
      print("\$print debug: GET \$variantsUri");
      final variantsRes = await http.get(variantsUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Variant Master Status Code: \${variantsRes.statusCode}");
      try {
        final decoded = jsonDecode(variantsRes.body);
        _allVariantsList = decoded['data'] ?? decoded ?? [];
        print("\$print debug: Variant Master Response:\n\${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (e) {
        print("\$print debug: Variant Master Response (Raw): \${variantsRes.body}");
      }

      // 3. Fetch Structure of selected Storage Type
      final structureUri = Uri.parse("https://billing.srivagroups.in/api/storage/structure/\${widget.storageTypeId}");
      print("\$print debug: GET \$structureUri");
      final structureRes = await http.get(structureUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Storage Structure Status Code: \${structureRes.statusCode}");
      try {
        final decoded = jsonDecode(structureRes.body);
        final List list = decoded['data'] ?? decoded ?? [];
        list.sort((a, b) => (a['level_order'] ?? 0).compareTo(b['level_order'] ?? 0));
        _structureLevels = list;
        print("\$print debug: Storage Structure Response:\n\${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (e) {
        print("\$print debug: Storage Structure Response (Raw): \${structureRes.body}");
      }

      // 4. Fetch Locations of selected Storage Type
      final locationsUri = Uri.parse("https://billing.srivagroups.in/api/storage/locations/\${widget.storageTypeId}");
      print("\$print debug: GET \$locationsUri");
      final locationsRes = await http.get(locationsUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Storage Locations Status Code: \${locationsRes.statusCode}");
      try {
        final decoded = jsonDecode(locationsRes.body);
        _rawLocationsList = decoded['data'] ?? decoded['locations'] ?? decoded['hierarchy'] ?? decoded ?? [];
        print("\$print debug: Storage Locations Response:\n\${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (e) {
        print("\$print debug: Storage Locations Response (Raw): \${locationsRes.body}");
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
      print("\$print debug: Error fetching allocation data: \$e");
      setState(() {
        _errorMessage = 'Error loading page configurations: \$e';
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
      {"name": "Display", "label": "Display (\$displayQty)"},
      {"name": "Shop", "label": "Shop (\$shopQty)"},
      {"name": "Outside", "label": "Outside (\$outsideQty)"},
    ];
  }

  // Generate partition labels based on row and column counts
  List<String> _generatePartitions(int rows, int cols) {
    final List<String> list = [];
    if (rows > 0 && cols > 0) {
      for (int r = 0; r < rows; r++) {
        final String letter = String.fromCharCode(65 + r); // A, B, C...
        for (int c = 1; c <= cols; c++) {
          list.add("\$letter\$c");
        }
      }
    } else if (rows > 0) {
      for (int r = 0; r < rows; r++) {
        list.add(String.fromCharCode(65 + r));
      }
    } else if (cols > 0) {
      for (int c = 1; c <= cols; c++) {
        list.add("\$c");
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
      print("\$print debug: POST request started to \$url");
      print("\$print debug: Request Payload:\n\${const JsonEncoder.withIndent('  ').convert(payload)}");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer \$token",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      print("\$print debug: POST Response Status Code: \${response.statusCode}");
      print("\$print debug: POST Response Body: \${response.body}");
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
              content: Text("Failed to save allocation. Status: \${response.statusCode}"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      print("\$print debug: Error posting allocation: \$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving allocation: \$e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
