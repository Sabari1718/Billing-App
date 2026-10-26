import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // -----------------------------------------------------------------------
  // STEP 1 STATE: Storage List
  // -----------------------------------------------------------------------
  List<Map<String, dynamic>> storages = [
    {
      "id": 1,
      "name": "CircuitPoint Store",
      "desc": "Manage storage, levels and items",
    },
  ];

  // -----------------------------------------------------------------------
  // STEP 2 STATE: Address Setup
  // -----------------------------------------------------------------------
  final TextEditingController newFieldCtrl = TextEditingController();
  String insertAfterSelection = "At the end";

  List<String> addressFields = ["Address", "Pincode", "dd", "gb", "dd"];
  final Map<String, TextEditingController> addressFieldControllers = {};

  int? editingAddressIndex;

  List<Map<String, String>> savedAddresses = [
    {
      "Address": "1/143 Near Avinashi Road, Kathir College Rd, Neelambur",
      "Pincode": "641062",
      "dd": "",
      "gb": "",
    },
  ];

  // -----------------------------------------------------------------------
  // STEP 3 STATE: Structure Design
  // -----------------------------------------------------------------------
  final TextEditingController newLevelCtrl = TextEditingController();
  bool supportGridPartitioning = false;
  int? editingLevelIndex; // For Photo 2 & 3: editing a level in Add Structure Level

  List<Map<String, dynamic>> structureLevels = [
    {"level": 1, "name": "Building"},
    {"level": 2, "name": "Floor"},
    {"level": 3, "name": "Rack"},
    {"level": 4, "name": "Shelf"},
    {"level": 5, "name": "Box"},
    {"level": 6, "name": "Container"},
  ];

  // -----------------------------------------------------------------------
  // STEP 4 STATE: Location Builder Hierarchy Tree (Photos 4 & 5)
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
  }

  void _initAddressControllers() {
    for (var f in addressFields) {
      if (!addressFieldControllers.containsKey(f)) {
        addressFieldControllers[f] = TextEditingController();
      }
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
  // STEP 1 ACTIONS: Edit & Add Storage (Photo 1)
  // =========================================================================
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
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  storage['name'] = newName;
                  if (activeStorage != null && activeStorage!['id'] == storage['id']) {
                    activeStorage!['name'] = newName;
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Storage updated successfully"), backgroundColor: Colors.green),
                );
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
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  storages.add({
                    "id": DateTime.now().millisecondsSinceEpoch,
                    "name": name,
                    "desc": "Manage storage, levels and items",
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Storage created successfully"), backgroundColor: Colors.green),
                );
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
            onPressed: () {
              setState(() {
                storages.removeWhere((e) => e['id'] == item['id']);
                if (activeStorage != null && activeStorage!['id'] == item['id']) {
                  activeStorage = null;
                  currentStep = 1;
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Storage deleted"), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2 ACTIONS: Address Setup Edit & Delete
  // =========================================================================
  void _addAddressField() {
    final field = newFieldCtrl.text.trim();
    if (field.isEmpty) return;

    setState(() {
      addressFields.add(field);
      addressFieldControllers[field] = TextEditingController();
      newFieldCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Address field '$field' added"), backgroundColor: Colors.green),
    );
  }

  void _editSavedAddress(int index) {
    final addr = savedAddresses[index];
    setState(() {
      editingAddressIndex = index;
      for (var f in addressFields) {
        if (addressFieldControllers.containsKey(f)) {
          addressFieldControllers[f]!.text = addr[f] ?? "";
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Address loaded into inputs for editing")),
    );
  }

  void _saveOrUpdateAddress() {
    Map<String, String> entry = {};
    for (var f in addressFields) {
      entry[f] = addressFieldControllers[f]?.text.trim() ?? "";
    }

    if ((entry["Address"] ?? "").isNotEmpty || (entry["Pincode"] ?? "").isNotEmpty) {
      setState(() {
        if (editingAddressIndex != null) {
          savedAddresses[editingAddressIndex!] = entry;
          editingAddressIndex = null;
        } else {
          savedAddresses.add(entry);
        }
        for (var ctrl in addressFieldControllers.values) {
          ctrl.clear();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Address saved successfully"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least Address or Pincode")),
      );
    }
  }

  void _confirmDeleteSavedAddress(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Address", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() => savedAddresses.removeAt(index));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Address deleted"), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 3 ACTIONS: Structure Design Edit & Delete (Photos 2 & 3)
  // =========================================================================
  void _startEditingLevel(int index) {
    setState(() {
      editingLevelIndex = index;
      newLevelCtrl.text = structureLevels[index]['name'];
    });
  }

  void _saveOrUpdateLevel() {
    final lvlName = newLevelCtrl.text.trim();
    if (lvlName.isEmpty) return;

    setState(() {
      if (editingLevelIndex != null) {
        structureLevels[editingLevelIndex!]['name'] = lvlName;
        editingLevelIndex = null;
      } else {
        structureLevels.add({
          "level": structureLevels.length + 1,
          "name": lvlName,
        });
      }
      newLevelCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Level '$lvlName' saved successfully"), backgroundColor: Colors.green),
    );
  }

  void _cancelEditingLevel() {
    setState(() {
      editingLevelIndex = null;
      newLevelCtrl.clear();
    });
  }

  // Exact match to Photo 3 dialog
  void _confirmDeleteLevel(int index) {
    final lvl = structureLevels[index];
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                structureLevels.removeAt(index);
                // Re-index remaining levels
                for (int i = 0; i < structureLevels.length; i++) {
                  structureLevels[i]['level'] = i + 1;
                }
                if (editingLevelIndex == index) {
                  editingLevelIndex = null;
                  newLevelCtrl.clear();
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Structure level '${lvl['name']}' deleted"), backgroundColor: Colors.green),
              );
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

    // Dynamically find next structure level name from hierarchy
    String childLevelName = "Sub-location";
    final parentLevel = parentItem['levelName']?.toString().toLowerCase();
    for (int i = 0; i < structureLevels.length; i++) {
      if (structureLevels[i]['name'].toString().toLowerCase() == parentLevel && i + 1 < structureLevels.length) {
        childLevelName = structureLevels[i + 1]['name'];
        break;
      }
    }
    if (childLevelName == "Sub-location") {
      childLevelName = (parentItem['levelName'] == "Building") ? "Floor" : "Rack";
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
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final newItem = {
                  "id": DateTime.now().millisecondsSinceEpoch,
                  "name": name,
                  "code": "C${(parentItem['children'] as List).length + 1}",
                  "levelName": childLevelName,
                  "isExpanded": true,
                  "racks": <Map<String, dynamic>>[],
                  "children": <Map<String, dynamic>>[],
                };

                setState(() {
                  (parentItem['children'] as List).add(newItem);
                  parentItem['isExpanded'] = true;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$childLevelName added successfully"), backgroundColor: Colors.green),
                );
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
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  locationsTree.add({
                    "id": DateTime.now().millisecondsSinceEpoch,
                    "name": name,
                    "code": "B${locationsTree.length + 1}",
                    "levelName": "Building",
                    "isExpanded": true,
                    "children": <Map<String, dynamic>>[],
                  });
                });
                Navigator.pop(ctx);
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
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  if (floorItem['racks'] == null) {
                    floorItem['racks'] = <Map<String, dynamic>>[];
                  }
                  (floorItem['racks'] as List).add({
                    "id": DateTime.now().millisecondsSinceEpoch,
                    "name": name,
                  });
                  floorItem['isExpanded'] = true;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Rack '$name' added"), backgroundColor: Colors.green),
                );
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
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  rack['name'] = name;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Rack '$name' updated"), backgroundColor: Colors.green),
                );
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
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() => item['name'] = newName);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Location updated"), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text("Update Location"),
          ),
        ],
      ),
    );
  }

  void _deleteLocationRecursive(List<Map<String, dynamic>> list, int targetId) {
    list.removeWhere((item) {
      if (item['id'] == targetId) return true;
      if (item['children'] != null) {
        _deleteLocationRecursive((item['children'] as List).cast<Map<String, dynamic>>(), targetId);
      }
      return false;
    });
  }

  void _confirmDeleteLocation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Location", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete ${item['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _deleteLocationRecursive(locationsTree, item['id']);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Location deleted"), backgroundColor: Colors.green),
              );
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
                        onPressed: () {
                          setState(() {
                            activeStorage = item;
                            currentStep = 2; // Advance to Step 2!
                          });
                        },
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
                        ...addressFields.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12)))),
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
                    children: addressFields.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final name = entry.value;

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
                                      "ORDER: ${idx + 1}",
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
                          if (idx < addressFields.length - 1)
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

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 550;

              return Column(
                children: [
                  for (int i = 0; i < addressFields.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: isNarrow
                          ? Column(
                              children: [
                                _buildAddressValueInput(addressFields[i]),
                                if (i + 1 < addressFields.length) ...[
                                  const SizedBox(height: 12),
                                  _buildAddressValueInput(addressFields[i + 1]),
                                ],
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _buildAddressValueInput(addressFields[i])),
                                const SizedBox(width: 14),
                                if (i + 1 < addressFields.length)
                                  Expanded(child: _buildAddressValueInput(addressFields[i + 1]))
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
            child: Column(
              children: savedAddresses.asMap().entries.map((entry) {
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
                            Text("Address: ${addr['Address']}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            if ((addr['Pincode'] ?? '').isNotEmpty)
                              Text("Pincode: ${addr['Pincode']}", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                            onPressed: () => _editSavedAddress(idx),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            onPressed: () => _confirmDeleteSavedAddress(idx),
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
                onPressed: () => setState(() => currentStep = 3),
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

  Widget _buildAddressValueInput(String fieldName) {
    if (!addressFieldControllers.containsKey(fieldName)) {
      addressFieldControllers[fieldName] = TextEditingController();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fieldName.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: addressFieldControllers[fieldName],
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
                onPressed: () => setState(() => currentStep = 4),
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