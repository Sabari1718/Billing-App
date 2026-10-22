part of 'storage_allocation.dart';

mixin StorageAllocationLogic on State<StorageAllocationPage> {
  late Future<List<Map<String, dynamic>>> _storageFuture;
  
  // Allocated Stock Review States
  List<Map<String, dynamic>> _allocatedStocks = [];
  bool _isLoadingAllocated = false;
  String _allocatedError = '';

  @override
  void initState() {
    super.initState();
    _loadStorageTypes();
    _fetchAllocatedStockReview();
  }

  void _loadStorageTypes() {
    setState(() {
      _storageFuture = _fetchStorageTypes();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchStorageTypes() async {
    print("\$print debug: API call started to https://billing.srivagroups.in/api/storage/types");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/storage/types"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer \$token",
        },
      ).timeout(const Duration(seconds: 15));

      print("--------------------------------------------------");
      print("\$print debug: Storage Types Status Code: \${response.statusCode}");
      try {
        final decoded = jsonDecode(response.body);
        final prettyResponse = const JsonEncoder.withIndent('  ').convert(decoded);
        print("\$print debug: Storage Types Response:\n\$prettyResponse");
      } catch (e) {
        print("\$print debug: Storage Types Response (Raw): \${response.body}");
      }
      print("--------------------------------------------------");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print("--------------------------------------------------");
      print("\$print debug: Storage Types API Call Failed: \$e");
      print("--------------------------------------------------");
      rethrow;
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

  // Recursively reconstruct path from leaf to root using flattened nodes list
  String _buildLocationPath({
    required int storageTypeId,
    required int? leafLocationId,
    required String storageTypeName,
    required Map<int, List<dynamic>> storageLocationsMap,
  }) {
    final rawTree = storageLocationsMap[storageTypeId] ?? [];
    if (leafLocationId == null || rawTree.isEmpty) {
      return storageTypeName;
    }

    // Flatten the hierarchical locations to allow easy search and lookup
    final locations = _flattenLocations(rawTree);
    if (locations.isEmpty) {
      return storageTypeName;
    }

    final pathParts = <String>[];
    int? currentId = leafLocationId;
    final visited = <int>{};

    while (currentId != null && !visited.contains(currentId)) {
      visited.add(currentId);
      final match = locations.firstWhere(
        (loc) => loc['id'] == currentId,
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        final name = match['name'].toString();
        if (name.isNotEmpty) {
          pathParts.insert(0, name);
        }
        currentId = match['parent_id'] as int?;
      } else {
        break;
      }
    }

    if (storageTypeName.isNotEmpty) {
      pathParts.insert(0, storageTypeName);
    }

    return pathParts.join(' > ');
  }

  Future<void> _fetchAllocatedStockReview() async {
    setState(() {
      _isLoadingAllocated = true;
      _allocatedError = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token.isNotEmpty) "Authorization": "Bearer \$token",
      };

      print("--------------------------------------------------");
      print("\$print debug: API call started to fetch storage configurations and allocated review");

      // 1. Fetch storage types
      final storageTypesUri = Uri.parse("https://billing.srivagroups.in/api/storage/types");
      final storageTypesRes = await http.get(storageTypesUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Storage Types Status Code: \${storageTypesRes.statusCode}");
      
      List rawStorageTypes = [];
      if (storageTypesRes.statusCode == 200) {
        final decoded = jsonDecode(storageTypesRes.body);
        final stData = decoded['data'] ?? decoded;
        if (stData is List) {
          rawStorageTypes = stData;
        } else if (stData is Map && stData['data'] is List) {
          rawStorageTypes = stData['data'];
        }
      }

      // 2. Fetch nested hierarchy locations for each storage type
      final Map<int, List<dynamic>> storageLocationsMap = {};
      for (var st in rawStorageTypes) {
        if (st is! Map) continue;
        final stId = st['id'] ?? st['storage_id'];
        if (stId != null) {
          try {
            final locUri = Uri.parse("https://billing.srivagroups.in/api/storage/locations/\$stId");
            final locRes = await http.get(locUri, headers: headers).timeout(const Duration(seconds: 15));
            print("\$print debug: Storage Locations for Type \$stId Status Code: \${locRes.statusCode}");
            if (locRes.statusCode == 200) {
              final decoded = jsonDecode(locRes.body);
              final locData = decoded['data'] ?? decoded['locations'] ?? decoded['hierarchy'] ?? decoded;
              if (locData is List) {
                storageLocationsMap[stId as int] = locData;
              } else if (locData is Map && locData['data'] is List) {
                storageLocationsMap[stId as int] = locData['data'];
              }
            }
          } catch (e) {
            print("\$print debug: Error fetching locations for storage type \$stId: \$e");
          }
        }
      }

      // 3. Fetch allocated locations list
      final locationsUri = Uri.parse("https://billing.srivagroups.in/api/stocks/all/locations");
      final locationsRes = await http.get(locationsUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Stocks Locations Status Code: \${locationsRes.statusCode}");
      try {
        final decoded = jsonDecode(locationsRes.body);
        print("\$print debug: Stocks Locations Response:\n\${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (_) {
        print("\$print debug: Stocks Locations Response (Raw): \${locationsRes.body}");
      }

      // 4. Fetch stocks
      final stocksUri = Uri.parse("https://billing.srivagroups.in/api/stocks");
      final stocksRes = await http.get(stocksUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Stocks Status Code: \${stocksRes.statusCode}");
      try {
        final decoded = jsonDecode(stocksRes.body);
        print("\$print debug: Stocks Response:\n\${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (_) {
        print("\$print debug: Stocks Response (Raw): \${stocksRes.body}");
      }

      // 5. Fetch variant-master
      final variantsUri = Uri.parse("https://billing.srivagroups.in/api/variant-master");
      final variantsRes = await http.get(variantsUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Variant Master Status Code: \${variantsRes.statusCode}");
      try {
        final decoded = jsonDecode(variantsRes.body);
        print("\$print debug: Variant Master Response:\n\${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (_) {
        print("\$print debug: Variant Master Response (Raw): \${variantsRes.body}");
      }
      print("--------------------------------------------------");

      if (locationsRes.statusCode == 200) {
        final locationsDecoded = jsonDecode(locationsRes.body);
        final locationsData = locationsDecoded['data'] ?? locationsDecoded;

        List rawLocations = [];
        if (locationsData is List) {
          rawLocations = locationsData;
        } else if (locationsData is Map && locationsData['data'] is List) {
          rawLocations = locationsData['data'];
        }

        // Parse Stocks
        List rawStocks = [];
        if (stocksRes.statusCode == 200) {
          final decoded = jsonDecode(stocksRes.body);
          final sData = decoded['data'] ?? decoded;
          if (sData is List) {
            rawStocks = sData;
          } else if (sData is Map && sData['data'] is List) {
            rawStocks = sData['data'];
          }
        }

        // Parse Variants
        List rawVariants = [];
        if (variantsRes.statusCode == 200) {
          final decoded = jsonDecode(variantsRes.body);
          final vData = decoded['data'] ?? decoded;
          if (vData is List) {
            rawVariants = vData;
          } else if (vData is Map && vData['data'] is List) {
            rawVariants = vData['data'];
          }
        }

        // Map data together
        final List<Map<String, dynamic>> mappedList = [];

        for (var loc in rawLocations) {
          if (loc is! Map) continue;
          final mapLoc = Map<String, dynamic>.from(loc);

          final stockId = mapLoc['stock_id'] ?? mapLoc['product_id'] ?? 0;
          final variantId = mapLoc['variant_id'] ?? mapLoc['product_variant_id'] ?? 0;
          final storageTypeId = mapLoc['storage_type_id'] ?? mapLoc['storage_id'] ?? 0;

          // Robust dynamic leaf location ID matching
          int? leafLocationId;
          for (var key in mapLoc.keys) {
            if (key.toString().toLowerCase().contains('location_id')) {
              leafLocationId = int.tryParse(mapLoc[key].toString());
              if (leafLocationId != null) break;
            }
          }
          leafLocationId ??= int.tryParse(mapLoc['storage_location_id']?.toString() ?? '') ??
                             int.tryParse(mapLoc['location_id']?.toString() ?? '') ??
                             int.tryParse(mapLoc['location']?['id']?.toString() ?? '') ??
                             int.tryParse(mapLoc['storage_location']?['id']?.toString() ?? '');

          // Find product details
          var productName = 'Unknown Product';
          final matchedStock = rawStocks.firstWhere(
            (s) => s['id'] == stockId || s['product_id'] == stockId,
            orElse: () => null,
          );
          if (matchedStock != null) {
            productName = matchedStock['product_name'] ?? matchedStock['product']?['name'] ?? matchedStock['name'] ?? 'Unknown Product';
          }

          // Find variant details
          var variantName = '';
          final matchedVariant = rawVariants.firstWhere(
            (v) => v['id'] == variantId,
            orElse: () => null,
          );
          if (matchedVariant != null) {
            variantName = matchedVariant['name'] ?? matchedVariant['variant_name'] ?? '';
          }

          // Find storage type details
          var storageTypeName = '';
          final matchedStorage = rawStorageTypes.firstWhere(
            (st) => st['id'] == storageTypeId || st['storage_id'] == storageTypeId,
            orElse: () => null,
          );
          if (matchedStorage != null) {
            storageTypeName = matchedStorage['name'] ?? matchedStorage['storage_name'] ?? '';
          }

          // Format Location Path
          String locationPath = (mapLoc['location_path'] ?? mapLoc['path'] ?? '').toString();
          if (locationPath.isEmpty) {
            locationPath = _buildLocationPath(
              storageTypeId: storageTypeId as int,
              leafLocationId: leafLocationId,
              storageTypeName: storageTypeName,
              storageLocationsMap: storageLocationsMap,
            );
          }

          mappedList.add({
            'id': mapLoc['id'] ?? 0,
            'location_path': locationPath.isNotEmpty ? locationPath : 'Unknown Location',
            'product_name': productName + (variantName.isNotEmpty ? ' (\$variantName)' : ''),
            'type_dist': mapLoc['type'] ?? mapLoc['dist_type'] ?? mapLoc['type_dist'] ?? 'Display',
            'qty': mapLoc['qty'] ?? mapLoc['allocated_qty'] ?? 0,
          });
        }

        if (mounted) {
          setState(() {
            _allocatedStocks = mappedList;
            _isLoadingAllocated = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _allocatedError = 'Failed to load allocations (Status: \${locationsRes.statusCode})';
            _isLoadingAllocated = false;
          });
        }
      }
    } catch (e) {
      print("\$print debug: Error fetching Allocated Stock Review: \$e");
      if (mounted) {
        setState(() {
          _allocatedError = 'Error fetching stock allocations: \$e';
          _isLoadingAllocated = false;
        });
      }
    }
  }

  Future<void> _deleteAllocatedLocation(int id, String path) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48))),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final url = "https://billing.srivagroups.in/api/stocks/all/locations/\$id";

      print("--------------------------------------------------");
      print("\$print debug: DELETE request to \$url");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer \$token",
        },
      ).timeout(const Duration(seconds: 15));

      print("\$print debug: DELETE Status Code: \${response.statusCode}");
      print("\$print debug: DELETE Response: \${response.body}");
      print("--------------------------------------------------");

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Successfully deleted stock location: \$path"),
              backgroundColor: const Color(0xFFE11D48),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _fetchAllocatedStockReview();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to delete. Status code: \${response.statusCode}"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: \$e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeleteAllocation(int id, String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48)),
            SizedBox(width: 8),
            Text("Delete Allocation?"),
          ],
        ),
        content: Text("Are you sure you want to delete allocation for path '\$path'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAllocatedLocation(id, path);
            },
            child: Text("Delete", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
