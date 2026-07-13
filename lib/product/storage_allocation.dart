import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_storage_allocation.dart';

class StorageAllocationPage extends StatefulWidget {
  const StorageAllocationPage({super.key});

  @override
  State<StorageAllocationPage> createState() => _StorageAllocationPageState();
}

class _StorageAllocationPageState extends State<StorageAllocationPage> {
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
    print("$print debug: API call started to https://billing.srivagroups.in/api/storage/types");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/storage/types"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      print("--------------------------------------------------");
      print("\$print debug: Storage Types Status Code: ${response.statusCode}");
      try {
        final decoded = jsonDecode(response.body);
        final prettyResponse = const JsonEncoder.withIndent('  ').convert(decoded);
        print("\$print debug: Storage Types Response:\n$prettyResponse");
      } catch (e) {
        print("\$print debug: Storage Types Response (Raw): ${response.body}");
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
      print("\$print debug: Storage Types API Call Failed: $e");
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
        if (token.isNotEmpty) "Authorization": "Bearer $token",
      };

      print("--------------------------------------------------");
      print("\$print debug: API call started to fetch storage configurations and allocated review");

      // 1. Fetch storage types
      final storageTypesUri = Uri.parse("https://billing.srivagroups.in/api/storage/types");
      final storageTypesRes = await http.get(storageTypesUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Storage Types Status Code: ${storageTypesRes.statusCode}");
      
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
            final locUri = Uri.parse("https://billing.srivagroups.in/api/storage/locations/$stId");
            final locRes = await http.get(locUri, headers: headers).timeout(const Duration(seconds: 15));
            print("\$print debug: Storage Locations for Type $stId Status Code: ${locRes.statusCode}");
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
            print("\$print debug: Error fetching locations for storage type $stId: $e");
          }
        }
      }

      // 3. Fetch allocated locations list
      final locationsUri = Uri.parse("https://billing.srivagroups.in/api/stocks/all/locations");
      final locationsRes = await http.get(locationsUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Stocks Locations Status Code: ${locationsRes.statusCode}");
      try {
        final decoded = jsonDecode(locationsRes.body);
        print("\$print debug: Stocks Locations Response:\n${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (_) {
        print("\$print debug: Stocks Locations Response (Raw): ${locationsRes.body}");
      }

      // 4. Fetch stocks
      final stocksUri = Uri.parse("https://billing.srivagroups.in/api/stocks");
      final stocksRes = await http.get(stocksUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Stocks Status Code: ${stocksRes.statusCode}");
      try {
        final decoded = jsonDecode(stocksRes.body);
        print("\$print debug: Stocks Response:\n${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (_) {
        print("\$print debug: Stocks Response (Raw): ${stocksRes.body}");
      }

      // 5. Fetch variant-master
      final variantsUri = Uri.parse("https://billing.srivagroups.in/api/variant-master");
      final variantsRes = await http.get(variantsUri, headers: headers).timeout(const Duration(seconds: 15));
      print("\$print debug: Variant Master Status Code: ${variantsRes.statusCode}");
      try {
        final decoded = jsonDecode(variantsRes.body);
        print("\$print debug: Variant Master Response:\n${const JsonEncoder.withIndent('  ').convert(decoded)}");
      } catch (_) {
        print("\$print debug: Variant Master Response (Raw): ${variantsRes.body}");
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
            'product_name': productName + (variantName.isNotEmpty ? ' ($variantName)' : ''),
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
            _allocatedError = 'Failed to load allocations (Status: ${locationsRes.statusCode})';
            _isLoadingAllocated = false;
          });
        }
      }
    } catch (e) {
      print("\$print debug: Error fetching Allocated Stock Review: $e");
      if (mounted) {
        setState(() {
          _allocatedError = 'Error fetching stock allocations: $e';
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
      final url = "https://billing.srivagroups.in/api/stocks/all/locations/$id";

      print("--------------------------------------------------");
      print("\$print debug: DELETE request to $url");

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      print("\$print debug: DELETE Status Code: ${response.statusCode}");
      print("\$print debug: DELETE Response: ${response.body}");
      print("--------------------------------------------------");

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Successfully deleted stock location: $path"),
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
              content: Text("Failed to delete. Status code: ${response.statusCode}"),
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
            content: Text("Error: $e"),
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
        content: Text("Are you sure you want to delete allocation for path '$path'? This action cannot be undone."),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Storage Setup",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            _loadStorageTypes();
            await _fetchAllocatedStockReview();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. STORAGE ALLOCATION HEADER BANNER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      "Storage Allocation",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),

                // 2. STORAGE TYPES GRID
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _storageFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text("Failed to load storage", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadStorageTypes,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data ?? [];

                    if (data.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text("No storage allocations found", style: GoogleFonts.inter(color: Colors.grey)),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final id = item['id'] ?? item['storage_id'] ?? 0;
                        final name = (item['name'] ?? item['storage_name'] ?? "Storage").toString();

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Edit Icon
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Edit '$name' functionality coming soon"),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0).withOpacity(0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Card Content
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2563EB).withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.dns_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Manage storage, levels and items",
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 34,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2563EB),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddStorageAllocationPage(
                                                storageTypeId: id,
                                                storageTypeName: name,
                                              ),
                                            ),
                                          ).then((value) {
                                            _fetchAllocatedStockReview();
                                          });
                                        },
                                        child: Text(
                                          "Select",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 3. ALLOCATED STOCK REVIEW BANNER CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Allocated Stock Review",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _fetchAllocatedStockReview,
                          icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF2563EB)),
                          label: Text(
                            "Refresh Data",
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 4. ALLOCATED STOCKS DATA TABLE
                _buildAllocatedStockTable(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocatedStockTable() {
    if (_isLoadingAllocated) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (_allocatedError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            children: [
              Text(
                _allocatedError,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchAllocatedStockReview,
                child: const Text("Retry Load"),
              )
            ],
          ),
        ),
      );
    }

    if (_allocatedStocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                "No allocated stocks found.",
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 68,
              headingRowHeight: 52,
              horizontalMargin: 20,
              columnSpacing: 28,
              columns: [
                DataColumn(
                  label: Text(
                    "LOCATION PATH",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "PRODUCT",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "TYPE / DIST",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "ALLOCATED QTY",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "ACTION",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              rows: _allocatedStocks.map((item) {
                final id = item['id'] as int;
                final path = item['location_path'].toString();
                final productName = item['product_name'].toString();
                final typeDist = item['type_dist'].toString();
                final qty = item['qty'].toString();

                return DataRow(
                  cells: [
                    // 1. LOCATION PATH
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          path,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                    // 2. PRODUCT
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          productName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    // 3. TYPE/DIST
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Text(
                          typeDist,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                    // 4. ALLOCATED QTY
                    DataCell(
                      Text(
                        qty,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    // 5. ACTION
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF7C3AED)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Edit allocation for '$path' coming soon"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE11D48)),
                            onPressed: () => _confirmDeleteAllocation(id, path),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
