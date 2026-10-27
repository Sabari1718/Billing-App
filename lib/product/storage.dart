import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kStorageBaseUrl = "https://billing.srivagroups.in/api";

Future<Map<String, String>> _getStorageApiHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("billing_auth_token") ??
      prefs.getString("auth_token") ??
      prefs.getString("token") ??
      prefs.getString("access_token") ??
      "";
  final cleanToken = token.startsWith("Bearer ") ? token.substring(7).trim() : token.trim();
  final businessId = prefs.getString("selected_business_id") ??
      prefs.get("business_id")?.toString() ??
      "52";
  final storeId = prefs.getString("selected_store_id") ??
      prefs.get("store_id")?.toString() ??
      "38";

  return {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "X-App-ID": "Product94674",
    if (cleanToken.isNotEmpty) "Authorization": "Bearer $cleanToken",
    "x-business-id": businessId,
    "x-store-id": (storeId == '1' || storeId.isEmpty) ? '38' : storeId,
    "x-platform-id": "1",
  };
}

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  // Wizard current step: 1 (Storage), 2 (Address Setup), 3 (Structure Design), 4 (Location Builder)
  int currentStep = 1;

  // Selected Active Storage (Photos 1 -> 2 transition)
  Map<String, dynamic>? activeStorage;

  // Loading indicators
  bool isLoadingStorage = false;
  bool isLoadingAddress = false;
  bool isLoadingStructure = false;
  bool isLoadingLocation = false;

  // -----------------------------------------------------------------------
  // STEP 1 STATE: Storage List (GET /api/storage/types)
  // -----------------------------------------------------------------------
  List<Map<String, dynamic>> storages = [
    {
      "id": 20,
      "business_id": 52,
      "platform_id": 1,
      "store_id": 38,
      "name": "CircuitPoint Store",
      "desc": "Manage storage, levels and items",
    },
  ];

  // -----------------------------------------------------------------------
  // STEP 2 STATE: Address Setup (GET /address-fields/:id & /address-values/:id)
  // -----------------------------------------------------------------------
  final TextEditingController newFieldCtrl = TextEditingController();
  String insertAfterSelection = "At the end";

  List<Map<String, dynamic>> rawAddressFields = [
    {"id": 63, "storage_type_id": 20, "field_name": "Address", "field_order": 1},
    {"id": 64, "storage_type_id": 20, "field_name": "Pincode", "field_order": 2},
    {"id": 71, "storage_type_id": 20, "field_name": "dd", "field_order": 3},
    {"id": 72, "storage_type_id": 20, "field_name": "gb", "field_order": 4},
    {"id": 73, "storage_type_id": 20, "field_name": "dd", "field_order": 5},
  ];

  final Map<int, TextEditingController> addressFieldControllers = {};

  int? editingAddressIndex;
  dynamic editingGroupId;
  Map<int, int> editingAddressRecordIds = {};

  List<Map<String, dynamic>> savedAddressGroups = [
    {
      "group_id": 1786083223756,
      "first_id": 224,
      "Address": "1/143 Near Avinashi Road, Kathir College Rd,Neelambur",
      "Pincode": "641062",
      "values": {
        63: "1/143 Near Avinashi Road, Kathir College Rd,Neelambur",
        64: "641062",
      },
      "record_ids": {
        63: 224,
        64: 225,
      },
    },
  ];

  // -----------------------------------------------------------------------
  // STEP 3 STATE: Structure Design (GET & PUT /api/storage/structure/:id)
  // -----------------------------------------------------------------------
  final TextEditingController newLevelCtrl = TextEditingController();
  bool supportGridPartitioning = false;
  int? editingLevelIndex;

  List<Map<String, dynamic>> structureLevels = [
    {"id": 135, "level": 1, "name": "Building", "is_partitionable": false},
    {"id": 136, "level": 2, "name": "Floor", "is_partitionable": false},
    {"id": 137, "level": 3, "name": "Rack", "is_partitionable": false},
    {"id": 138, "level": 4, "name": "Shelf", "is_partitionable": false},
    {"id": 141, "level": 5, "name": "Box", "is_partitionable": false},
    {"id": 139, "level": 6, "name": "Container", "is_partitionable": false},
  ];

  // -----------------------------------------------------------------------
  // STEP 4 STATE: Location Builder Hierarchy Tree (GET /locations/:id)
  // -----------------------------------------------------------------------
  List<Map<String, dynamic>> locationsTree = [
    {
      "id": 1,
      "name": "CP Building",
      "code": "B1",
      "levelName": "Building",
      "isExpanded": true,
      "children": [
        {
          "id": 2,
          "name": "Floor 1",
          "code": "F1",
          "levelName": "Floor",
          "isExpanded": false,
          "racks": <Map<String, dynamic>>[],
          "children": <Map<String, dynamic>>[],
        },
        {
          "id": 3,
          "name": "ddd",
          "code": "F2",
          "levelName": "Floor",
          "isExpanded": true,
          "racks": <Map<String, dynamic>>[],
          "children": <Map<String, dynamic>>[],
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAddressControllers();
    activeStorage = storages.first;
    _fetchStorageTypes().then((_) {
      final sId = activeStorage?['id'] as int? ?? 20;
      _fetchAddressFieldsAndValues(sId);
      _fetchStructureLevels(sId);
    });
  }

  TextEditingController _getControllerForField(int fieldId) {
    if (!addressFieldControllers.containsKey(fieldId)) {
      addressFieldControllers[fieldId] = TextEditingController();
    }
    return addressFieldControllers[fieldId]!;
  }

  void _initAddressControllers() {
    for (var f in rawAddressFields) {
      final fId = f['id'] as int;
      _getControllerForField(fId);
    }
  }

  @override
  void dispose() {
    newFieldCtrl.dispose();
    newLevelCtrl.dispose();
    for (var ctrl in addressFieldControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // =========================================================================
  // LIVE API: 1. Storage Types (GET https://billing.srivagroups.in/api/storage/types)
  // =========================================================================
  Future<void> _fetchStorageTypes() async {
    setState(() => isLoadingStorage = true);
    try {
      final headers = await _getStorageApiHeaders();
      final url = "$_kStorageBaseUrl/storage/types";
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final data = (decoded is Map ? decoded['data'] : decoded) as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final list = List<Map<String, dynamic>>.from(data).map((item) {
            return {
              "id": item['id'],
              "name": item['name'] ?? "CircuitPoint Store",
              "desc": "Manage storage, levels and items",
              "business_id": item['business_id'],
              "store_id": item['store_id'],
              "platform_id": item['platform_id'],
            };
          }).toList();
          setState(() {
            storages = list;
            activeStorage = storages.firstWhere(
              (s) => s['id'] == 20,
              orElse: () => storages.first,
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Storage types fetch error: $e");
    } finally {
      if (mounted) setState(() => isLoadingStorage = false);
    }
  }

  // =========================================================================
  // LIVE API: 2. Address Fields & Address Values
  // GET /api/storage/address-fields/{id}
  // GET /api/storage/address-values/{id}
  // =========================================================================
  Future<void> _fetchAddressFieldsAndValues(int sId) async {
    setState(() => isLoadingAddress = true);
    try {
      final headers = await _getStorageApiHeaders();

      // 1. Fetch Fields
      final fieldsUrl = "$_kStorageBaseUrl/storage/address-fields/$sId";
      final fieldsRes = await http.get(Uri.parse(fieldsUrl), headers: headers).timeout(const Duration(seconds: 10));
      if (fieldsRes.statusCode >= 200 && fieldsRes.statusCode < 300) {
        final decoded = jsonDecode(fieldsRes.body);
        final data = (decoded is Map ? decoded['data'] : decoded) as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final fieldsList = List<Map<String, dynamic>>.from(data);
          fieldsList.sort((a, b) => (a['field_order'] ?? 0).compareTo(b['field_order'] ?? 0));
          setState(() {
            rawAddressFields = fieldsList;
            for (var f in rawAddressFields) {
              final fId = f['id'] as int;
              _getControllerForField(fId);
            }
          });
        }
      }

      // 2. Fetch Values
      final valuesUrl = "$_kStorageBaseUrl/storage/address-values/$sId";
      final valuesRes = await http.get(Uri.parse(valuesUrl), headers: headers).timeout(const Duration(seconds: 10));
      if (valuesRes.statusCode >= 200 && valuesRes.statusCode < 300) {
        final decoded = jsonDecode(valuesRes.body);
        final data = (decoded is Map ? decoded['data'] : decoded) as List<dynamic>?;
        if (data != null) {
          final valuesList = List<Map<String, dynamic>>.from(data);

          // Group by address_group_id
          Map<dynamic, Map<String, dynamic>> groups = {};
          for (var item in valuesList) {
            final gId = item['address_group_id'];
            if (!groups.containsKey(gId)) {
              groups[gId] = {
                "group_id": gId,
                "first_id": item['id'],
                "Address": "",
                "Pincode": "",
                "values": <int, String>{},
                "record_ids": <int, int>{},
              };
            }
            final fieldId = item['field_id'] as int;
            final fieldVal = (item['field_value'] ?? "").toString();
            (groups[gId]!['values'] as Map<int, String>)[fieldId] = fieldVal;
            (groups[gId]!['record_ids'] as Map<int, int>)[fieldId] = item['id'];

            final fieldName = (item['field_name'] ?? "").toString().toLowerCase();
            if (fieldName.contains("address")) {
              groups[gId]!['Address'] = fieldVal;
            } else if (fieldName.contains("pincode")) {
              groups[gId]!['Pincode'] = fieldVal;
            }
          }

          setState(() {
            savedAddressGroups = groups.values.toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Address fields/values fetch error: $e");
    } finally {
      if (mounted) setState(() => isLoadingAddress = false);
    }
  }

  // =========================================================================
  // LIVE API: 3. Structure Levels (GET /api/storage/structure/{id})
  // =========================================================================
  Future<void> _fetchStructureLevels(int sId) async {
    setState(() => isLoadingStructure = true);
    try {
      final headers = await _getStorageApiHeaders();
      final url = "$_kStorageBaseUrl/storage/structure/$sId";
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final data = (decoded is Map ? decoded['data'] : decoded) as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final list = List<Map<String, dynamic>>.from(data);
          list.sort((a, b) => (a['level_order'] ?? 0).compareTo(b['level_order'] ?? 0));
          setState(() {
            structureLevels = list.map((item) {
              return {
                "id": item['id'],
                "level": item['level_order'] ?? 1,
                "name": item['name'] ?? "",
                "is_partitionable": item['is_partitionable'] == 1 || item['is_partitionable'] == true,
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Structure levels fetch error: $e");
    } finally {
      if (mounted) setState(() => isLoadingStructure = false);
    }
  }

  // =========================================================================
  // LIVE API: 4. Location Builder Data (GET /api/storage/locations/{id})
  // =========================================================================
  Future<void> _fetchLocations(int sId) async {
    setState(() => isLoadingLocation = true);
    try {
      final headers = await _getStorageApiHeaders();
      final url = "$_kStorageBaseUrl/storage/locations/$sId";
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        List<dynamic> fetchedData = [];
        if (decoded is List) {
          fetchedData = decoded;
        } else if (decoded is Map) {
          final candidate = decoded['data'] ?? decoded['locations'] ?? decoded['hierarchy'];
          if (candidate is List) {
            fetchedData = candidate;
          }
        }
        if (fetchedData.isNotEmpty) {
          bool isNested = fetchedData.any((item) => item is Map && item['children'] != null && (item['children'] as List).isNotEmpty);
          List<Map<String, dynamic>> parsedTree;
          if (isNested) {
            parsedTree = _normalizeLocationTree(fetchedData);
          } else {
            parsedTree = _buildTreeFromFlatLocations(fetchedData);
          }
          if (mounted) {
            setState(() {
              locationsTree = parsedTree;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Locations fetch error: $e");
    } finally {
      if (mounted) setState(() => isLoadingLocation = false);
    }
  }

  List<Map<String, dynamic>> _normalizeLocationTree(List<dynamic> list, {int depth = 0}) {
    final List<Map<String, dynamic>> result = [];
    for (var item in list) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final rawChildren = (m['children'] as List<dynamic>?) ?? [];
      final rawRacks = (m['racks'] as List<dynamic>?) ?? [];
      final lvlName = m['level_name'] ?? m['levelName'] ?? (depth == 0 ? "Building" : (depth == 1 ? "Floor" : "Rack"));

      result.add({
        "id": m['id'],
        "name": (m['name'] ?? m['location_name'] ?? "Location #${m['id']}").toString(),
        "code": (m['code'] ?? m['short_code'] ?? "L${m['id']}").toString(),
        "parent_id": m['parent_id'],
        "level_id": m['level_id'],
        "levelName": lvlName.toString(),
        "isExpanded": true,
        "children": _normalizeLocationTree(rawChildren, depth: depth + 1),
        "racks": rawRacks.map((r) => Map<String, dynamic>.from(r as Map)).toList(),
      });
    }
    return result;
  }

  List<Map<String, dynamic>> _buildTreeFromFlatLocations(List<dynamic> flatList) {
    final Map<dynamic, Map<String, dynamic>> nodeMap = {};
    for (var item in flatList) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = m['id'];
      if (id == null) continue;

      String lvlName = (m['level_name'] ?? m['level'] ?? '').toString();
      if (lvlName.isEmpty && m['level_id'] != null) {
        final matchedLvl = structureLevels.firstWhere(
          (sl) => sl['id'] == m['level_id'],
          orElse: () => {},
        );
        if (matchedLvl.isNotEmpty) {
          lvlName = (matchedLvl['name'] ?? '').toString();
        }
      }
      if (lvlName.isEmpty) {
        lvlName = m['parent_id'] == null ? "Building" : "Floor";
      }

      nodeMap[id] = {
        "id": id,
        "name": (m['name'] ?? m['location_name'] ?? "Location #$id").toString(),
        "code": (m['code'] ?? m['short_code'] ?? "L$id").toString(),
        "parent_id": m['parent_id'],
        "level_id": m['level_id'],
        "levelName": lvlName,
        "isExpanded": true,
        "children": <Map<String, dynamic>>[],
        "racks": <Map<String, dynamic>>[],
      };
    }

    final List<Map<String, dynamic>> roots = [];
    for (var node in nodeMap.values) {
      final pid = node['parent_id'];
      if (pid != null && nodeMap.containsKey(pid)) {
        (nodeMap[pid]!['children'] as List<Map<String, dynamic>>).add(node);
      } else {
        roots.add(node);
      }
    }
    return roots;
  }

  // =========================================================================
  // STEP 1 ACTIONS: Edit & Add Storage (Photo 1)
  // =========================================================================
  void _onSelectStorage(Map<String, dynamic> item) {
    setState(() {
      activeStorage = item;
      currentStep = 2; // Advance to Step 2
    });
    final sId = item['id'] as int? ?? 20;
    _fetchAddressFieldsAndValues(sId);
    _fetchStructureLevels(sId);
    _fetchLocations(sId);
  }

  void _showEditStorageDialog(Map<String, dynamic> storage) {
    final nameCtrl = TextEditingController(text: storage['name']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
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
                setState(() => isLoadingStorage = true);
                try {
                  final headers = await _getStorageApiHeaders();
                  final id = storage['id'];
                  http.Response res = await http.put(
                    Uri.parse("$_kStorageBaseUrl/storage/types/$id"),
                    headers: headers,
                    body: jsonEncode({"name": newName}),
                  );
                  if (res.statusCode < 200 || res.statusCode >= 300) {
                    res = await http.put(
                      Uri.parse("$_kStorageBaseUrl/storage/type/$id"),
                      headers: headers,
                      body: jsonEncode({"name": newName}),
                    );
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Storage updated successfully"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint("Update storage error: $e");
                } finally {
                  await _fetchStorageTypes();
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

  void _showAddStorageDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text("New Storage", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("STORAGE NAME", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: "e.g. Main Warehouse",
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => isLoadingStorage = true);
                try {
                  final headers = await _getStorageApiHeaders();
                  final prefs = await SharedPreferences.getInstance();
                  final storeId = prefs.getString("selected_store_id") ?? prefs.get("store_id")?.toString() ?? "38";
                  final businessId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "52";
                  http.Response res = await http.post(
                    Uri.parse("$_kStorageBaseUrl/storage/types"),
                    headers: headers,
                    body: jsonEncode({
                      "name": name,
                      "store_id": int.tryParse(storeId) ?? 38,
                      "business_id": int.tryParse(businessId) ?? 52,
                    }),
                  );
                  if (res.statusCode < 200 || res.statusCode >= 300) {
                    res = await http.post(
                      Uri.parse("$_kStorageBaseUrl/storage/type"),
                      headers: headers,
                      body: jsonEncode({
                        "name": name,
                        "store_id": int.tryParse(storeId) ?? 38,
                        "business_id": int.tryParse(businessId) ?? 52,
                      }),
                    );
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Storage created successfully"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint("Create storage error: $e");
                } finally {
                  await _fetchStorageTypes();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStorage(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Storage", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete ${item['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => isLoadingStorage = true);
              try {
                final headers = await _getStorageApiHeaders();
                final id = item['id'];
                http.Response res = await http.delete(
                  Uri.parse("$_kStorageBaseUrl/storage/types/$id"),
                  headers: headers,
                );
                if (res.statusCode < 200 || res.statusCode >= 300) {
                  res = await http.delete(
                    Uri.parse("$_kStorageBaseUrl/storage/type/$id"),
                    headers: headers,
                  );
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Storage deleted successfully"), backgroundColor: Colors.green),
                );
              } catch (e) {
                debugPrint("Delete storage error: $e");
              } finally {
                await _fetchStorageTypes();
                if (activeStorage != null && activeStorage!['id'] == item['id']) {
                  setState(() {
                    activeStorage = storages.isNotEmpty ? storages.first : null;
                    if (activeStorage == null) currentStep = 1;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2 ACTIONS: Address Setup Save, Edit (PUT), Delete (DELETE)
  // =========================================================================
  Future<void> _addAddressField() async {
    final fieldName = newFieldCtrl.text.trim();
    if (fieldName.isEmpty) return;
    final sId = activeStorage?['id'] as int? ?? 20;

    setState(() => isLoadingAddress = true);
    try {
      final headers = await _getStorageApiHeaders();
      http.Response res = await http.post(
        Uri.parse("$_kStorageBaseUrl/storage/address-field"),
        headers: headers,
        body: jsonEncode({
          "storage_type_id": sId,
          "field_name": fieldName,
          "field_order": rawAddressFields.length + 1,
        }),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        res = await http.post(
          Uri.parse("$_kStorageBaseUrl/storage/address-fields"),
          headers: headers,
          body: jsonEncode({
            "storage_type_id": sId,
            "field_name": fieldName,
            "field_order": rawAddressFields.length + 1,
          }),
        );
      }
      newFieldCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Address field '$fieldName' added successfully"), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint("Add address field err: $e");
    } finally {
      await _fetchAddressFieldsAndValues(sId);
    }
  }

  void _editSavedAddressGroup(int index) {
    final group = savedAddressGroups[index];
    setState(() {
      editingAddressIndex = index;
      editingGroupId = group['group_id'];
      editingAddressRecordIds = Map<int, int>.from(group['record_ids'] ?? {});

      final vals = (group['values'] as Map?) ?? {};
      for (var f in rawAddressFields) {
        final fId = f['id'] as int;
        _getControllerForField(fId).text = vals[fId]?.toString() ?? "";
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Address loaded into inputs for editing")),
    );
  }

  Future<void> _saveOrUpdateAddress() async {
    final sId = activeStorage?['id'] as int? ?? 20;

    if (editingGroupId != null) {
      // 1. UPDATE EXISTING ADDRESS: PUT /api/storage/address-value/:id
      setState(() => isLoadingAddress = true);
      try {
        final headers = await _getStorageApiHeaders();
        for (var f in rawAddressFields) {
          final fId = f['id'] as int;
          final val = _getControllerForField(fId).text.trim();
          final recordId = editingAddressRecordIds[fId];
          if (recordId != null) {
            final url = "$_kStorageBaseUrl/storage/address-value/$recordId";
            await http.put(
              Uri.parse(url),
              headers: headers,
              body: jsonEncode({"value": val}),
            );
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Address updated successfully"), backgroundColor: Colors.green),
        );
      } catch (e) {
        debugPrint("Error updating address: $e");
      } finally {
        setState(() {
          editingAddressIndex = null;
          editingGroupId = null;
          editingAddressRecordIds.clear();
          for (var ctrl in addressFieldControllers.values) {
            ctrl.clear();
          }
        });
        await _fetchAddressFieldsAndValues(sId);
      }
    } else {
      // 2. CREATE NEW ADDRESS: POST /api/storage/address-value
      List<Map<String, dynamic>> fieldsPayload = [];
      for (var f in rawAddressFields) {
        final fId = f['id'] as int;
        final val = _getControllerForField(fId).text.trim();
        fieldsPayload.add({"field_id": fId, "value": val});
      }

      setState(() => isLoadingAddress = true);
      try {
        final headers = await _getStorageApiHeaders();
        final url = "$_kStorageBaseUrl/storage/address-value";
        final res = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            "storage_type_id": sId,
            "fields": fieldsPayload,
          }),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Address values saved successfully"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        debugPrint("Error saving address: $e");
      } finally {
        setState(() {
          for (var ctrl in addressFieldControllers.values) {
            ctrl.clear();
          }
        });
        await _fetchAddressFieldsAndValues(sId);
      }
    }
  }

  void _confirmDeleteSavedAddressGroup(int index) {
    final group = savedAddressGroups[index];
    final firstId = group['first_id'];
    final sId = activeStorage?['id'] as int? ?? 20;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Address", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (firstId != null) {
                setState(() => isLoadingAddress = true);
                try {
                  final headers = await _getStorageApiHeaders();
                  final url = "$_kStorageBaseUrl/storage/address-value/$firstId";
                  await http.delete(Uri.parse(url), headers: headers);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Address deleted successfully"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint("Delete address error: $e");
                } finally {
                  await _fetchAddressFieldsAndValues(sId);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 3 ACTIONS: Structure Design Edit (PUT) & Delete (DELETE)
  // =========================================================================
  void _startEditingLevel(int index) {
    setState(() {
      editingLevelIndex = index;
      newLevelCtrl.text = structureLevels[index]['name'];
      supportGridPartitioning = structureLevels[index]['is_partitionable'] == true;
    });
  }

  Future<void> _saveOrUpdateLevel() async {
    final lvlName = newLevelCtrl.text.trim();
    if (lvlName.isEmpty) return;
    final sId = activeStorage?['id'] as int? ?? 20;

    if (editingLevelIndex != null) {
      // PUT /api/storage/structure/:id
      final lvl = structureLevels[editingLevelIndex!];
      final id = lvl['id'];
      setState(() => isLoadingStructure = true);
      try {
        final headers = await _getStorageApiHeaders();
        final url = "$_kStorageBaseUrl/storage/structure/$id";
        await http.put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            "name": lvlName,
            "is_partitionable": supportGridPartitioning ? 1 : 0,
          }),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Structure level '$lvlName' updated successfully"), backgroundColor: Colors.green),
        );
      } catch (e) {
        debugPrint("Update structure error: $e");
      } finally {
        setState(() {
          editingLevelIndex = null;
          newLevelCtrl.clear();
        });
        await _fetchStructureLevels(sId);
      }
    } else {
      // POST /api/storage/structure
      setState(() => isLoadingStructure = true);
      try {
        final headers = await _getStorageApiHeaders();
        final url = "$_kStorageBaseUrl/storage/structure";
        await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            "storage_type_id": sId,
            "name": lvlName,
            "is_partitionable": supportGridPartitioning ? 1 : 0,
            "level_order": structureLevels.length + 1,
          }),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Structure level '$lvlName' added successfully"), backgroundColor: Colors.green),
        );
      } catch (e) {
        debugPrint("Add structure error: $e");
      } finally {
        setState(() => newLevelCtrl.clear());
        await _fetchStructureLevels(sId);
      }
    }
  }

  void _cancelEditingLevel() {
    setState(() {
      editingLevelIndex = null;
      newLevelCtrl.clear();
    });
  }

  // Exact match to Photo 3 dialog: DELETE /api/storage/structure/:id
  void _confirmDeleteLevel(int index) {
    final lvl = structureLevels[index];
    final id = lvl['id'];
    final sId = activeStorage?['id'] as int? ?? 20;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "billing.srivagroups.in says",
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
        ),
        content: Text(
          "This will fully delete this structure level AND all associated locations permanently. Are you absolutely sure?",
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (id != null) {
                setState(() => isLoadingStructure = true);
                try {
                  final headers = await _getStorageApiHeaders();
                  final url = "$_kStorageBaseUrl/storage/structure/$id";
                  await http.delete(Uri.parse(url), headers: headers);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Structure level '${lvl['name']}' deleted"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint("Delete structure error: $e");
                } finally {
                  await _fetchStructureLevels(sId);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5E3A), // Dark Green OK button from Photo 3
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            child: Text("OK", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E5E3A),
              side: const BorderSide(color: Color(0xFFA7F3D0)),
              backgroundColor: const Color(0xFFDCFCE7), // Light green cancel from Photo 3
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 4 ACTIONS: Location Builder Add, Edit, Delete (Photos 4 & 5)
  // =========================================================================
  void _showAddChildLocationDialog(Map<String, dynamic> parentItem) {
    final nameCtrl = TextEditingController();
    final sId = activeStorage?['id'] as int? ?? 20;

    // Dynamically find next structure level name from hierarchy
    String childLevelName = "Sub-location";
    int? childLevelId;
    final parentLevel = parentItem['levelName']?.toString().toLowerCase();
    for (int i = 0; i < structureLevels.length; i++) {
      if (structureLevels[i]['name'].toString().toLowerCase() == parentLevel && i + 1 < structureLevels.length) {
        childLevelName = structureLevels[i + 1]['name'];
        childLevelId = structureLevels[i + 1]['id'];
        break;
      }
    }
    if (childLevelName == "Sub-location") {
      childLevelName = (parentItem['levelName'] == "Building") ? "Floor" : "Rack";
      if (structureLevels.length > 1) {
        childLevelId = structureLevels[1]['id'];
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          children: [
            Text("Add $childLevelName", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text("Inside: ${parentItem['name']}", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LOCATION NAME", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: "e.g. $childLevelName 1",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
              ),
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
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => isLoadingLocation = true);
                try {
                  final headers = await _getStorageApiHeaders();
                  final body = {
                    "storage_type_id": sId,
                    "parent_id": parentItem['id'],
                    "name": name,
                    "level_id": childLevelId,
                  };
                  final res = await http.post(
                    Uri.parse("$_kStorageBaseUrl/storage/location"),
                    headers: headers,
                    body: jsonEncode(body),
                  );
                  debugPrint("Add Child Location res [${res.statusCode}]: ${res.body}");
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$childLevelName added successfully"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint("Add Child Location error: $e");
                } finally {
                  await _fetchLocations(sId);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Build Location"),
          ),
        ],
      ),
    );
  }

  void _showAddBuildingDialog() {
    final nameCtrl = TextEditingController();
    final sId = activeStorage?['id'] as int? ?? 20;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text("Add Building", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LOCATION NAME", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: "e.g. Building A",
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => isLoadingLocation = true);
                try {
                  final headers = await _getStorageApiHeaders();
                  final int? lvlId = structureLevels.isNotEmpty ? structureLevels.first['id'] : null;
                  final body = {
                    "storage_type_id": sId,
                    "parent_id": null,
                    "name": name,
                    "level_id": lvlId,
                  };
                  final res = await http.post(
                    Uri.parse("$_kStorageBaseUrl/storage/location"),
                    headers: headers,
                    body: jsonEncode(body),
                  );
                  debugPrint("Add Building res [${res.statusCode}]: ${res.body}");
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Building '$name' added successfully"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint("Add Building error: $e");
                } finally {
                  await _fetchLocations(sId);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text("Build Location"),
          ),
        ],
      ),
    );
  }

  void _showAddRackDialog(Map<String, dynamic> floorItem) {
    final nameCtrl = TextEditingController();
    final sId = activeStorage?['id'] as int? ?? 20;

    int? rackLevelId;
    for (var lvl in structureLevels) {
      if (lvl['name'].toString().toLowerCase().contains("rack")) {
        rackLevelId = lvl['id'];
        break;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          children: [
            Text("Add Rack", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text("Inside: ${floorItem['name']}", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("RACK NAME", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: "e.g. Rack 1",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
              ),
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
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => isLoadingLocation = true);
                try {
                  final headers = await _getStorageApiHeaders();
                  final body = {
                    "storage_type_id": sId,
                    "parent_id": floorItem['id'],
                    "name": name,
                    "level_id": rackLevelId,
                  };
                  final res = await http.post(
                    Uri.parse("$_kStorageBaseUrl/storage/location"),
                    headers: headers,
                    body: jsonEncode(body),
                  );
                  debugPrint("Add Rack res [${res.statusCode}]: ${res.body}");
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Rack '$name' added successfully"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint("Add Rack error: $e");
                } finally {
                  await _fetchLocations(sId);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Build Location"),
          ),
        ],
      ),
    );
  }

  void _showEditRackDialog(Map<String, dynamic> floorItem, int rackIdx) {
    final rack = (floorItem['racks'] as List)[rackIdx];
    final nameCtrl = TextEditingController(text: rack['name']);
    final sId = activeStorage?['id'] as int? ?? 20;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text("Edit Rack", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Under floor: ${floorItem['name']}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            Text("RACK NAME", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
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
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => isLoadingLocation = true);
                try {
                  final headers = await _getStorageApiHeaders();
                  final id = rack['id'];
                  if (id != null) {
                    await http.put(
                      Uri.parse("$_kStorageBaseUrl/storage/location/$id"),
                      headers: headers,
                      body: jsonEncode({"name": name}),
                    );
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Rack '$name' updated"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint("Update rack error: $e");
                } finally {
                  await _fetchLocations(sId);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text("Update Rack"),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(Map<String, dynamic> item) {
    final nameCtrl = TextEditingController(text: item['name']);
    final sId = activeStorage?['id'] as int? ?? 20;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text("Edit ${item['levelName'] ?? 'Location'}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LOCATION NAME", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => isLoadingLocation = true);
                try {
                  final headers = await _getStorageApiHeaders();
                  final id = item['id'];
                  final res = await http.put(
                    Uri.parse("$_kStorageBaseUrl/storage/location/$id"),
                    headers: headers,
                    body: jsonEncode({"name": newName}),
                  );
                  debugPrint("Update location res [${res.statusCode}]: ${res.body}");
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Location updated successfully"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint("Update location error: $e");
                } finally {
                  await _fetchLocations(sId);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text("Update Location"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLocation(Map<String, dynamic> item) {
    final sId = activeStorage?['id'] as int? ?? 20;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Location", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete ${item['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => isLoadingLocation = true);
              try {
                final headers = await _getStorageApiHeaders();
                final id = item['id'];
                final res = await http.delete(
                  Uri.parse("$_kStorageBaseUrl/storage/location/$id"),
                  headers: headers,
                );
                debugPrint("Delete location res [${res.statusCode}]: ${res.body}");
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Location deleted successfully"), backgroundColor: Colors.green),
                );
              } catch (e) {
                debugPrint("Delete location error: $e");
              } finally {
                await _fetchLocations(sId);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text("Delete"),
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
          "Storage Management",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (currentStep > 1) {
              setState(() => currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header: Title, Description, Active Storage Badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Storage Management",
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Configure and build your storage hierarchy",
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                if (activeStorage != null && currentStep > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Text(
                          "Active: ${activeStorage!['name']}",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Stepper Navigation Bar (Horizontal Scrollable for Zero Overflow)
            _buildStepperHeader(),
            const SizedBox(height: 20),

            // Main Content Area based on currentStep
            if (currentStep == 1)
              _buildStep1Storage()
            else if (currentStep == 2)
              _buildStep2AddressSetup()
            else if (currentStep == 3)
              _buildStep3StructureDesign()
            else if (currentStep == 4)
              _buildStep4LocationBuilder(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // STEPPER HEADER WIDGET (Photos 1, 2, 4, 5)
  // =========================================================================
  Widget _buildStepperHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStepTab(1, "Storage", Icons.storage_rounded, currentStep == 1),
            const SizedBox(width: 8),
            _buildStepTab(2, "Address Setup", Icons.location_on_outlined, currentStep == 2),
            const SizedBox(width: 8),
            _buildStepTab(3, "Structure Design", Icons.layers_outlined, currentStep == 3),
            const SizedBox(width: 8),
            _buildStepTab(4, "Location Builder", Icons.near_me_outlined, currentStep == 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTab(int stepNumber, String title, IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (stepNumber == 1 || activeStorage != null) {
          setState(() => currentStep = stepNumber);
          if (activeStorage != null) {
            final sId = activeStorage!['id'] as int? ?? 20;
            if (stepNumber == 2) {
              _fetchAddressFieldsAndValues(sId);
            } else if (stepNumber == 3) {
              _fetchStructureLevels(sId);
            } else if (stepNumber == 4) {
              _fetchLocations(sId);
              _fetchStructureLevels(sId);
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$stepNumber",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 14, color: isActive ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: isActive ? Colors.white70 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 1: SELECT STORAGE (PHOTO 1)
  // =========================================================================
  Widget _buildStep1Storage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Select ",
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    TextSpan(
                      text: "Storage",
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddStorageDialog,
                icon: const Icon(Icons.add, size: 15, color: Colors.white),
                label: Text("New Storage", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (isLoadingStorage)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: storages.map((item) {
                return Container(
                  width: 270,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Edit & Delete icons on top right (Photo 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFF59E0B)),
                            onPressed: () => _showEditStorageDialog(item),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            onPressed: () => _confirmDeleteStorage(item),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.dns_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        item['name'],
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      Text(
                        item['desc'],
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _onSelectStorage(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: Text("Select", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2: ADDRESS SETUP (PHOTOS 2 & 3)
  // =========================================================================
  Widget _buildStep2AddressSetup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "1. Setup ",
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                TextSpan(
                  text: "Address Fields",
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 550;

              final nameField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("FIELD NAME", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: newFieldCtrl,
                      style: GoogleFonts.inter(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "e.g. Row, Drawer, Bin",
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                  ),
                ],
              );

              final insertAfterField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("INSERT AFTER", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: DropdownButtonFormField<String>(
                      initialValue: insertAfterSelection,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                      items: [
                        const DropdownMenuItem(value: "At the end", child: Text("At the end", style: TextStyle(fontSize: 12))),
                        ...rawAddressFields.map((f) => DropdownMenuItem(
                              value: f['field_name']?.toString() ?? "",
                              child: Text(f['field_name']?.toString() ?? "", style: const TextStyle(fontSize: 12)),
                            )),
                      ],
                      onChanged: (val) => setState(() => insertAfterSelection = val ?? "At the end"),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    nameField,
                    const SizedBox(height: 12),
                    insertAfterField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: nameField),
                  const SizedBox(width: 14),
                  Expanded(child: insertAfterField),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          Center(
            child: ElevatedButton.icon(
              onPressed: _addAddressField,
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: Text("Add Address Field", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // FORMAT PREVIEW
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("FORMAT PREVIEW", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: rawAddressFields.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final f = entry.value;
                      final name = (f['field_name'] ?? "").toString();
                      final order = f['field_order'] ?? (idx + 1);

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                    const SizedBox(width: 4),
                                    Text(
                                      "ORDER: $order",
                                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                          if (idx < rawAddressFields.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text("—", style: TextStyle(color: Colors.grey.shade400)),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: 2. Setup Address Values
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "2. Setup ",
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                TextSpan(
                  text: "Address Values",
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (isLoadingAddress)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 550;

                return Column(
                  children: [
                    for (int i = 0; i < rawAddressFields.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: isNarrow
                            ? Column(
                                children: [
                                  _buildAddressValueInput(rawAddressFields[i]),
                                  if (i + 1 < rawAddressFields.length) ...[
                                    const SizedBox(height: 12),
                                    _buildAddressValueInput(rawAddressFields[i + 1]),
                                  ],
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _buildAddressValueInput(rawAddressFields[i])),
                                  const SizedBox(width: 14),
                                  if (i + 1 < rawAddressFields.length)
                                    Expanded(child: _buildAddressValueInput(rawAddressFields[i + 1]))
                                  else
                                    const Expanded(child: SizedBox()),
                                ],
                              ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Saved Addresses Box with Edit & Delete actions
            Text("Saved Addresses", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: savedAddressGroups.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text("No saved addresses yet.", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                      ),
                    )
                  : Column(
                      children: savedAddressGroups.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final addr = entry.value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Address: ${addr['Address'] ?? ''}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                    if ((addr['Pincode'] ?? '').toString().isNotEmpty)
                                      Text("Pincode: ${addr['Pincode']}", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                                    onPressed: () => _editSavedAddressGroup(idx),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                    onPressed: () => _confirmDeleteSavedAddressGroup(idx),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveOrUpdateAddress,
                  icon: const Icon(Icons.save_outlined, size: 14, color: Colors.white),
                  label: Text(
                    editingAddressIndex != null ? "Update Address" : "Save Address",
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                if (editingAddressIndex != null)
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        editingAddressIndex = null;
                        editingGroupId = null;
                        editingAddressRecordIds.clear();
                        for (var ctrl in addressFieldControllers.values) {
                          ctrl.clear();
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text("Cancel Edit"),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 28),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => currentStep = 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
                child: Text("Previous Step", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => currentStep = 3);
                  if (activeStorage != null) {
                    _fetchStructureLevels(activeStorage!['id'] as int? ?? 20);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                ),
                child: Text("Next Step: Structure Design →", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressValueInput(Map<String, dynamic> field) {
    final fId = field['id'] as int;
    final fieldName = (field['field_name'] ?? "").toString();
    final ctrl = _getControllerForField(fId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fieldName.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: ctrl,
            style: GoogleFonts.inter(fontSize: 12),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 3: STRUCTURE DESIGN (PHOTOS 2 & 3)
  // =========================================================================
  Widget _buildStep3StructureDesign() {
    final isEditing = editingLevelIndex != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "3. Structure ",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                TextSpan(
                  text: "Design",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ADD STRUCTURE LEVEL Section (Photo 2)
          Text("ADD STRUCTURE LEVEL", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 550;

              final inputField = SizedBox(
                height: 40,
                child: TextField(
                  controller: newLevelCtrl,
                  style: GoogleFonts.inter(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: "e.g. Block, Building, Floor, Rack",
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
              );

              final actionBtns = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing) ...[
                    OutlinedButton.icon(
                      onPressed: _cancelEditingLevel,
                      icon: const Icon(Icons.close, size: 14, color: Color(0xFF475569)),
                      label: Text("Cancel", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: _saveOrUpdateLevel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      isEditing ? "Update Level" : "+ Add Level",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    inputField,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: actionBtns),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: inputField),
                  const SizedBox(width: 12),
                  actionBtns,
                ],
              );
            },
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: supportGridPartitioning,
                  onChanged: (val) => setState(() => supportGridPartitioning = val),
                  activeThumbColor: const Color(0xFF2563EB),
                ),
              ),
              Text(
                "Support Grid Partitioning (Rows/Cols)",
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // VISUAL MODEL (DRAG TO REORDER) - Flow Chain (Photos 2 & 3)
          Text("VISUAL MODEL (DRAG TO REORDER)", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: structureLevels.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final lvl = entry.value;
                  final isCardEditing = editingLevelIndex == idx;

                  return Row(
                    children: [
                      Container(
                        width: 120, // Clean width to fit actions with zero overflow
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCardEditing ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                            width: isCardEditing ? 2.0 : 1.0,
                          ),
                          boxShadow: isCardEditing
                              ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
                                Text(
                                  "LEVEL: ${lvl['level']}",
                                  style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              lvl['name'],
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            // Safe action buttons with zero RenderFlex overflow!
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () => _startEditingLevel(idx),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.edit_outlined, size: 15, color: Color(0xFF2563EB)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _confirmDeleteLevel(idx),
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (idx < structureLevels.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => currentStep = 2),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
                child: Text("Previous Step", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => currentStep = 4);
                  if (activeStorage != null) {
                    final sId = activeStorage!['id'] as int? ?? 20;
                    _fetchLocations(sId);
                    _fetchStructureLevels(sId);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                ),
                child: Text("Next Step: Location Builder →", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 4: LOCATION BUILDER (PHOTOS 4 & 5)
  // =========================================================================
  Widget _buildStep4LocationBuilder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "4. Location ",
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    TextSpan(
                      text: "Builder",
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddBuildingDialog,
                icon: const Icon(Icons.add, size: 15, color: Colors.white),
                label: Text("Add Building", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hierarchy Tree View
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: locationsTree.map((root) => _buildTreeNode(root, 0)).toList(),
            ),
          ),
          const SizedBox(height: 28),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => currentStep = 3),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
                child: Text("Previous Step", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Storage hierarchy configuration completed!"), backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, size: 15, color: Colors.white),
                label: Text("Finish Setup", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recursive Tree Node Renderer matching Photo 4 & 5
  Widget _buildTreeNode(Map<String, dynamic> item, int depth) {
    final children = (item['children'] as List<dynamic>?) ?? [];
    final hasChildren = children.isNotEmpty;
    final isExpanded = item['isExpanded'] == true;
    final isFloor = item['levelName'] == "Floor";
    final racks = (item['racks'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    item['isExpanded'] = !isExpanded;
                  });
                },
                child: Icon(
                  (hasChildren || isFloor)
                      ? (isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right)
                      : Icons.chevron_right,
                  size: 18,
                  color: (hasChildren || isFloor) ? const Color(0xFF2563EB) : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              if (isFloor)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.layers_outlined, size: 16, color: Color(0xFF2563EB)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    Text(
                      "${item['code'] ?? ''} • ${item['levelName']}",
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF2563EB)),
                    onPressed: () => _showEditLocationDialog(item),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      if (isFloor) {
                        _showAddRackDialog(item);
                      } else {
                        _showAddChildLocationDialog(item);
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add, size: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                    onPressed: () => _confirmDeleteLocation(item),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Photo 5: When floor is expanded, show Racks / Places in {floor} container
        if (isFloor && isExpanded)
          Container(
            margin: EdgeInsets.only(left: (depth + 1) * 20.0, bottom: 10, right: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grid_view_outlined, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "Racks in ${item['name']}",
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRackDialog(item),
                      icon: const Icon(Icons.add, size: 12, color: Colors.white),
                      label: Text("Add Rack", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (racks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Text(
                            "No Rack created under this floor yet.",
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => _showAddRackDialog(item),
                            icon: const Icon(Icons.add, size: 13, color: Colors.white),
                            label: Text("Add First Rack", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: racks.asMap().entries.map((rEntry) {
                      final rIdx = rEntry.key;
                      final rack = rEntry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rack['name'],
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF2563EB)),
                              onPressed: () => _showEditRackDialog(item, rIdx),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                              onPressed: () {
                                setState(() => (item['racks'] as List).removeAt(rIdx));
                              },
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

        if (hasChildren && isExpanded)
          ...children.map((child) => _buildTreeNode(child as Map<String, dynamic>, depth + 1)),
      ],
    );
  }
}