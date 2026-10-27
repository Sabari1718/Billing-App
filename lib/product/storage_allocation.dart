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
  // Toggle: "With Variant" vs "Without Variant" (Photo 1 vs Photo 3)
  bool isWithVariant = true;

  // Search query & entries filter
  String searchQuery = "";
  int entriesPerPage = 10;
  final TextEditingController searchCtrl = TextEditingController();

  // Storage Type data (Photo 1)
  Map<String, dynamic> activeStorage = {
    "id": 20,
    "name": "CircuitPoint Stores",
    "desc": "Manage storage, levels and items",
  };
  List<Map<String, dynamic>> allStorageTypes = [];

  // Allocated stock items for "With Variant" and "Without Variant"
  List<Map<String, dynamic>> withVariantAllocations = [];
  List<Map<String, dynamic>> withoutVariantAllocations = [];

  // Live API Caches
  List<dynamic> _categoriesList = [];
  List<dynamic> _stocksList = [];
  List<dynamic> _variantsList = [];
  final Map<int, List<dynamic>> _storageLocationsMap = {};

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStorageAllocationData();
  }

  Future<Map<String, String>> _getStorageApiHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("billing_auth_token") ??
        prefs.getString("auth_token") ??
        prefs.getString("token") ??
        prefs.getString("access_token") ??
        "";
    if (token.startsWith("Bearer ")) {
      token = token.substring(7).trim();
    }
    final businessId = prefs.getString('selected_business_id') ??
        prefs.get('business_id')?.toString() ??
        '52';
    final storeId = prefs.getString('selected_store_id') ??
        prefs.get('store_id')?.toString() ??
        '38';
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

  List<Map<String, dynamic>> _flattenLocations(List<dynamic> treeList) {
    final List<Map<String, dynamic>> flat = [];

    void traverse(dynamic node, int? parentId) {
      if (node is! Map) return;
      final mapNode = Map<String, dynamic>.from(node);
      final int? id = int.tryParse(mapNode['id']?.toString() ?? '') ??
          int.tryParse(mapNode['location_id']?.toString() ?? '');
      if (id == null) return;

      final resolvedParentId =
          int.tryParse(mapNode['parent_id']?.toString() ?? '') ?? parentId;

      flat.add({
        'id': id,
        'name': (mapNode['name'] ?? mapNode['location_name'] ?? '').toString(),
        'parent_id': resolvedParentId,
      });

      final children = mapNode['children'] ?? mapNode['child'];
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

  Future<void> _fetchStorageAllocationData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final headers = await _getStorageApiHeaders();
      debugPrint("🚀 [Storage Allocation] Fetching all 6 live APIs...");

      // API 1: Category List (GET https://srivagroups.in/api/category/list)
      final catFuture = http.get(
        Uri.parse("https://srivagroups.in/api/category/list"),
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 15));

      // API 2: Storage Types (GET https://billing.srivagroups.in/api/storage/types)
      final typesFuture = http.get(
        Uri.parse("https://billing.srivagroups.in/api/storage/types"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // API 3: Stocks (GET https://billing.srivagroups.in/api/stocks)
      final stocksFuture = http.get(
        Uri.parse("https://billing.srivagroups.in/api/stocks"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // API 4: Variant Master (GET https://billing.srivagroups.in/api/variant-master)
      final variantsFuture = http.get(
        Uri.parse("https://billing.srivagroups.in/api/variant-master"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      // API 5: Stocks All Locations (GET https://billing.srivagroups.in/api/stocks/all/locations)
      final allocatedFuture = http.get(
        Uri.parse("https://billing.srivagroups.in/api/stocks/all/locations"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      final responses = await Future.wait([
        catFuture.catchError((e) {
          debugPrint("❌ Category list error: $e");
          return http.Response('{"data":[]}', 500);
        }),
        typesFuture.catchError((e) {
          debugPrint("❌ Storage types error: $e");
          return http.Response('{"data":[]}', 500);
        }),
        stocksFuture.catchError((e) {
          debugPrint("❌ Stocks error: $e");
          return http.Response('{"data":[]}', 500);
        }),
        variantsFuture.catchError((e) {
          debugPrint("❌ Variant master error: $e");
          return http.Response('{"data":[]}', 500);
        }),
        allocatedFuture.catchError((e) {
          debugPrint("❌ Stocks all locations error: $e");
          return http.Response('{"data":[]}', 500);
        }),
      ]);

      final catRes = responses[0];
      final typesRes = responses[1];
      final stocksRes = responses[2];
      final variantsRes = responses[3];
      final allocatedRes = responses[4];

      // 1. Process Categories
      if (catRes.statusCode >= 200 && catRes.statusCode < 300) {
        final decoded = jsonDecode(catRes.body);
        final data = decoded['data'] ?? decoded;
        if (data is List) {
          _categoriesList = data;
        }
      }

      // 2. Process Storage Types
      List rawStorageTypes = [];
      if (typesRes.statusCode >= 200 && typesRes.statusCode < 300) {
        final decoded = jsonDecode(typesRes.body);
        final data = decoded['data'] ?? decoded;
        if (data is List) {
          rawStorageTypes = data;
        } else if (data is Map && data['data'] is List) {
          rawStorageTypes = data['data'];
        }
        if (rawStorageTypes.isNotEmpty) {
          allStorageTypes = List<Map<String, dynamic>>.from(
            rawStorageTypes.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          );
          final first = rawStorageTypes[0];
          activeStorage = {
            "id": first['id'] ?? activeStorage['id'] ?? 1,
            "name": first['name'] ?? first['storage_name'] ?? "CircuitPoint Stores",
            "desc": first['description'] ?? first['desc'] ?? "Manage storage, levels and items",
          };
        }
      }

      // 3. Process Stocks
      if (stocksRes.statusCode >= 200 && stocksRes.statusCode < 300) {
        final decoded = jsonDecode(stocksRes.body);
        final data = decoded['data'] ?? decoded;
        if (data is List) {
          _stocksList = data;
        } else if (data is Map && data['data'] is List) {
          _stocksList = data['data'];
        }
      }

      // 4. Process Variants
      if (variantsRes.statusCode >= 200 && variantsRes.statusCode < 300) {
        final decoded = jsonDecode(variantsRes.body);
        final data = decoded['data'] ?? decoded;
        if (data is List) {
          _variantsList = data;
        } else if (data is Map && data['data'] is List) {
          _variantsList = data['data'];
        }
      }

      // API 6: Storage Locations Hierarchy (GET https://billing.srivagroups.in/api/storage/locations/{activeStorage['id']})
      final activeTypeId = activeStorage['id'] ?? 1;
      try {
        final locRes = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/storage/locations/$activeTypeId"),
          headers: headers,
        ).timeout(const Duration(seconds: 10));

        if (locRes.statusCode >= 200 && locRes.statusCode < 300) {
          final decoded = jsonDecode(locRes.body);
          final data = decoded['data'] ?? decoded['locations'] ?? decoded['hierarchy'] ?? decoded;
          if (data is List) {
            _storageLocationsMap[activeTypeId as int] = data;
          } else if (data is Map && data['data'] is List) {
            _storageLocationsMap[activeTypeId as int] = data['data'];
          }
        }
      } catch (e) {
        debugPrint("❌ Storage locations fetch error: $e");
      }

      // 5. Process Stocks All Locations
      if (allocatedRes.statusCode >= 200 && allocatedRes.statusCode < 300) {
        final decoded = jsonDecode(allocatedRes.body);
        final data = decoded['data'] ?? decoded;

        List rawAllocations = [];
        if (data is List) {
          rawAllocations = data;
        } else if (data is Map && data['data'] is List) {
          rawAllocations = data['data'];
        }

        final List<Map<String, dynamic>> newWithVariant = [];
        final List<Map<String, dynamic>> newWithoutVariant = [];

        for (var item in rawAllocations) {
          if (item is! Map) continue;
          final mapLoc = Map<String, dynamic>.from(item);

          final int id = int.tryParse(mapLoc['id']?.toString() ?? '') ?? 0;
          final stockId = int.tryParse(mapLoc['stock_id']?.toString() ?? '') ??
              int.tryParse(mapLoc['product_id']?.toString() ?? '') ??
              0;
          final variantId = int.tryParse(mapLoc['variant_id']?.toString() ?? '') ??
              int.tryParse(mapLoc['product_variant_id']?.toString() ?? '');
          final String variantRaw =
              (mapLoc['variant'] ?? mapLoc['variant_name'] ?? '').toString();

          // Resolve Product Details
          String productName = (mapLoc['product'] ??
                  mapLoc['product_name'] ??
                  mapLoc['stockName'] ??
                  '')
              .toString();
          String productCode =
              (mapLoc['code'] ?? mapLoc['barcode'] ?? mapLoc['sku'] ?? 'QR/Barcode')
                  .toString();

          String categoryName = '';
          if (stockId > 0 && _stocksList.isNotEmpty) {
            final matchedStock = _stocksList.firstWhere(
              (s) => s['id'] == stockId || s['product_id'] == stockId,
              orElse: () => {},
            );
            if (matchedStock.isNotEmpty) {
              final name = matchedStock['product_name'] ??
                  matchedStock['name'] ??
                  matchedStock['product']?['name'];
              if (name != null && name.toString().isNotEmpty) {
                productName = name.toString();
              }
              final code = matchedStock['sku'] ??
                  matchedStock['product_code'] ??
                  matchedStock['code'];
              if (code != null && code.toString().isNotEmpty) {
                productCode = code.toString();
              }
              final catId = matchedStock['category_id'] ??
                  matchedStock['category'] ??
                  matchedStock['category_name_id'];
              if (catId != null && _categoriesList.isNotEmpty) {
                final matchedCat = _categoriesList.firstWhere(
                  (c) => c['id'].toString() == catId.toString(),
                  orElse: () => {},
                );
                if (matchedCat.isNotEmpty) {
                  categoryName = (matchedCat['name'] ??
                          matchedCat['category_name'] ??
                          '')
                      .toString();
                }
              }
            }
          }
          if (productName.isEmpty) {
            productName = stockId > 0 ? "Product #$stockId" : "Stock Item";
          }

          // Resolve Variant Name
          String variantName = variantRaw;
          if ((variantId != null && variantId > 0) && _variantsList.isNotEmpty) {
            final matchedV = _variantsList.firstWhere(
              (v) => v['id'] == variantId,
              orElse: () => {},
            );
            if (matchedV.isNotEmpty) {
              variantName =
                  (matchedV['name'] ?? matchedV['variant_name'] ?? '').toString();
            }
          }

          // Format Location Path
          String locationPath =
              (mapLoc['location_path'] ?? mapLoc['path'] ?? '').toString();
          if (locationPath.isEmpty) {
            final stId = int.tryParse(mapLoc['storage_type_id']?.toString() ?? '') ??
                activeStorage['id'] ??
                1;
            final leafId =
                int.tryParse(mapLoc['storage_location_id']?.toString() ?? '') ??
                    int.tryParse(mapLoc['location_id']?.toString() ?? '');
            locationPath = _buildLocationPath(
              storageTypeId: stId,
              leafLocationId: leafId,
              storageTypeName:
                  activeStorage['name'] ?? "CircuitPoint Stores",
              storageLocationsMap: _storageLocationsMap,
            );
          }

          final String typeDist =
              (mapLoc['type'] ?? mapLoc['dist_type'] ?? mapLoc['type_dist'] ?? 'Shop In Sales')
                  .toString();
          final int qty = int.tryParse(mapLoc['qty']?.toString() ?? '') ??
              int.tryParse(mapLoc['allocated_qty']?.toString() ?? '') ??
              0;

          final record = {
            "id": id,
            "sNo": 0,
            "locationPath": locationPath,
            "product": productName,
            "stockName": productName,
            "variant": variantName,
            "category": categoryName,
            "typeDist": typeDist,
            "allocatedQty": qty,
            "code": productCode,
            "hierarchy": mapLoc['hierarchy'] ?? {},
            "raw": mapLoc,
          };

          final bool hasVariant =
              (variantId != null && variantId > 0) || variantName.isNotEmpty;
          if (hasVariant) {
            newWithVariant.add(record);
          } else {
            newWithoutVariant.add(record);
          }
        }

        for (int i = 0; i < newWithVariant.length; i++) {
          newWithVariant[i]['sNo'] = i + 1;
        }
        for (int i = 0; i < newWithoutVariant.length; i++) {
          newWithoutVariant[i]['sNo'] = i + 1;
        }

        if (mounted) {
          setState(() {
            withVariantAllocations = newWithVariant;
            withoutVariantAllocations = newWithoutVariant;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching storage allocation data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showEditStorageDialog() {
    final nameCtrl = TextEditingController(text: activeStorage['name']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "Edit Storage",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("STORAGE NAME", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Give your storage unit a clear, descriptive name.",
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                final stId = activeStorage['id'] ?? 20;
                try {
                  final headers = await _getStorageApiHeaders();
                  final res = await http.put(
                    Uri.parse("https://billing.srivagroups.in/api/storage/type/$stId"),
                    headers: headers,
                    body: jsonEncode({
                      "name": newName,
                    }),
                  ).timeout(const Duration(seconds: 15));

                  String msg = "Storage type updated";
                  if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                      final decoded = jsonDecode(res.body);
                      if (decoded['message'] != null) {
                        msg = decoded['message'].toString();
                      }
                    } catch (_) {}
                  }

                  setState(() {
                    activeStorage['name'] = newName;
                    for (var st in allStorageTypes) {
                      if (st['id'] == stId) {
                        st['name'] = newName;
                      }
                    }
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  debugPrint("❌ Storage update error: $e");
                  setState(() {
                    activeStorage['name'] = newName;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Storage updated successfully"), backgroundColor: Colors.green),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Update Storage"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllocation(int id, String locationPath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "Delete Allocation",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        content: Text(
          "Are you sure you want to delete allocation for:\n$locationPath?",
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final headers = await _getStorageApiHeaders();
                await http.delete(
                  Uri.parse("https://billing.srivagroups.in/api/stocks/all/locations/$id"),
                  headers: headers,
                ).timeout(const Duration(seconds: 15));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Allocation deleted successfully"), backgroundColor: Colors.green),
                  );
                }
                _fetchStorageAllocationData();
              } catch (e) {
                debugPrint("Delete error: $e");
                setState(() {
                  if (isWithVariant) {
                    withVariantAllocations.removeWhere((item) => item['id'] == id);
                    for (int i = 0; i < withVariantAllocations.length; i++) {
                      withVariantAllocations[i]['sNo'] = i + 1;
                    }
                  } else {
                    withoutVariantAllocations.removeWhere((item) => item['id'] == id);
                    for (int i = 0; i < withoutVariantAllocations.length; i++) {
                      withoutVariantAllocations[i]['sNo'] = i + 1;
                    }
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showQrBarcodeModal(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "QR / Barcode Info",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 100, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 12),
            Text(
              item['product'] ?? '',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              item['locationPath'] ?? '',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _navigateToEditAllocation(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStorageAllocationPage(
          storageTypeId: activeStorage['id'] ?? 1,
          storageTypeName: activeStorage['name'] ?? "CircuitPoint Store",
          initialData: item,
        ),
      ),
    );

    if (result != null) {
      _fetchStorageAllocationData();
    }
  }

  void _navigateToAddAllocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStorageAllocationPage(
          storageTypeId: activeStorage['id'] ?? 1,
          storageTypeName: activeStorage['name'] ?? "CircuitPoint Store",
        ),
      ),
    );

    if (result != null) {
      _fetchStorageAllocationData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = isWithVariant ? withVariantAllocations : withoutVariantAllocations;
    final filteredList = currentList.where((item) {
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase();
      final path = (item['locationPath'] ?? '').toString().toLowerCase();
      final prod = (item['product'] ?? '').toString().toLowerCase();
      final stock = (item['stockName'] ?? '').toString().toLowerCase();
      final cat = (item['category'] ?? '').toString().toLowerCase();
      return path.contains(q) || prod.contains(q) || stock.contains(q) || cat.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Storage Allocation",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          if (isLoading)
            const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Color(0xFFEFF6FF),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // TOP HEADER: Storage Allocation with 2D View & 3D View (Photo 1)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Text(
                  "Storage Allocation",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("2D View activated")),
                        );
                      },
                      icon: const Icon(Icons.grid_on_outlined, size: 14, color: Color(0xFF2563EB)),
                      label: Text("2D View", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        backgroundColor: const Color(0xFFEFF6FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("3D View activated")),
                        );
                      },
                      icon: const Icon(Icons.view_in_ar_outlined, size: 14, color: Color(0xFF64748B)),
                      label: Text("3D View", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // STORAGE CARD: CircuitPoint Store (Photo 1)
            Container(
              width: 250,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                      onPressed: _showEditStorageDialog,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.dns_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activeStorage['name'] ?? "CircuitPoint Store",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeStorage['desc'] ?? "Manage storage, levels and items",
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToAddAllocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        "Select",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ALLOCATED STOCK REVIEW SECTION (Photos 1 & 3)
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
                  // Title, With/Without Variant Toggles, and Refresh Data
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Allocated Stock Review",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          // TOGGLES: With Variant / Without Variant (Photos 1 & 3)
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
                                  onTap: () {
                                    setState(() => isWithVariant = true);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isWithVariant ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: isWithVariant
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                                          : null,
                                    ),
                                    child: Text(
                                      "With Variant",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isWithVariant ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => isWithVariant = false);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: !isWithVariant ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: !isWithVariant
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                                          : null,
                                    ),
                                    child: Text(
                                      "Without Variant",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: !isWithVariant ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _fetchStorageAllocationData,
                        icon: isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                              )
                            : const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF2563EB)),
                        label: Text(
                          isLoading ? "Loading..." : "Refresh Data",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Row: SHOW [ 10 ⌄ ] ENTRIES & SEARCH BOX (Photo 1)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("SHOW", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: entriesPerPage,
                                items: [10, 25, 50, 100].map((count) {
                                  return DropdownMenuItem<int>(
                                    value: count,
                                    child: Text("$count", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => entriesPerPage = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text("ENTRIES", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(
                        width: 220,
                        height: 36,
                        child: TextField(
                          controller: searchCtrl,
                          style: GoogleFonts.inter(fontSize: 12),
                          onChanged: (val) => setState(() => searchQuery = val),
                          decoration: InputDecoration(
                            hintText: "Search allocations...",
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // TABLE OR EMPTY STATE (Photos 1 & 3)
                  if (filteredList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Text(
                        "No allocations found. Create a new one above.",
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          headingRowHeight: 46,
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 64,
                          horizontalMargin: 16,
                          columnSpacing: 22,
                          columns: [
                            DataColumn(label: Text("S.NO", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)))),
                            DataColumn(label: Text("LOCATION PATH", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)))),
                            DataColumn(label: Text("PRODUCT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)))),
                            DataColumn(label: Text("TYPE / DIST", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)))),
                            DataColumn(label: Text("ALLOCATED QTY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)))),
                            DataColumn(label: Text("CODE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)))),
                            DataColumn(label: Text("ACTION", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)))),
                          ],
                          rows: filteredList.take(entriesPerPage).map((item) {
                            return DataRow(
                              cells: [
                                // S.NO
                                DataCell(Text("${item['sNo']}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),

                                // LOCATION PATH
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 320),
                                    child: Text(
                                      item['locationPath'] ?? '',
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),

                                // PRODUCT
                                DataCell(
                                  Text(
                                    item['product'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                  ),
                                ),

                                // TYPE / DIST
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['typeDist'] ?? 'Shop In Sales',
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                                    ),
                                  ),
                                ),

                                // ALLOCATED QTY
                                DataCell(
                                  Center(
                                    child: Text(
                                      "${item['allocatedQty']}",
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                    ),
                                  ),
                                ),

                                // CODE: QR / Barcode button (Photo 1)
                                DataCell(
                                  OutlinedButton.icon(
                                    onPressed: () => _showQrBarcodeModal(item),
                                    icon: const Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF2563EB)),
                                    label: Text("QR / Barcode", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                                      backgroundColor: const Color(0xFFEFF6FF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ),

                                // ACTION: Edit & Delete (Photo 1)
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _navigateToEditAllocation(item),
                                        borderRadius: BorderRadius.circular(4),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _confirmDeleteAllocation(item['id'], item['locationPath'] ?? ''),
                                        borderRadius: BorderRadius.circular(4),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                        ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
);
  }
}
