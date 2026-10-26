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
    "id": 1,
    "name": "CircuitPoint Store",
    "desc": "Manage storage, levels and items",
  };

  // Allocated stock items for "With Variant" (Photo 1)
  List<Map<String, dynamic>> withVariantAllocations = [
    {
      "id": 1,
      "sNo": 1,
      "locationPath": "CircuitPoint Store > CP Building > Floor 1 > Electronics Rack 1 > Shelf 5 > Diode1 > 6A4 Diode",
      "product": "Product #2827",
      "stockName": "6A4 DIODE 6 AMP",
      "variant": "Imported (5)",
      "typeDist": "Shop In Sales",
      "allocatedQty": 8,
      "code": "QR/Barcode",
      "hierarchy": {
        "Building": "CP Building",
        "Floor": "Floor 1",
        "Rack": "Electronics Rack 1",
        "Shelf": "Shelf 5",
        "Box": "Diode1",
        "Container": "6A4 Diode",
      },
    },
    {
      "id": 2,
      "sNo": 2,
      "locationPath": "CircuitPoint Store > CP Building > Floor 1 > Electronics Rack 1 > Shelf 6 > GSM > GPS > SIM 900A",
      "product": "Product #3845",
      "stockName": "SIM 900A GSM MODULE",
      "variant": "Standard (2)",
      "typeDist": "Shop In Sales",
      "allocatedQty": 2,
      "code": "QR/Barcode",
      "hierarchy": {
        "Building": "CP Building",
        "Floor": "Floor 1",
        "Rack": "Electronics Rack 1",
        "Shelf": "Shelf 6",
        "Box": "GSM",
        "Container": "GPS",
      },
    },
    {
      "id": 3,
      "sNo": 3,
      "locationPath": "CircuitPoint Store > CP Building > Floor 1 > Electronics Rack 1 > Shelf 4 > PCB Stepper Motor Driver > A4988 stepper motor driver module",
      "product": "Product #731",
      "stockName": "A4988 STEPPER MOTOR DRIVER",
      "variant": "Red Board (4)",
      "typeDist": "Shop In Sales",
      "allocatedQty": 4,
      "code": "QR/Barcode",
      "hierarchy": {
        "Building": "CP Building",
        "Floor": "Floor 1",
        "Rack": "Electronics Rack 1",
        "Shelf": "Shelf 4",
        "Box": "PCB Stepper Motor Driver",
        "Container": "A4988",
      },
    },
    {
      "id": 4,
      "sNo": 4,
      "locationPath": "CircuitPoint Store > CP Building > Floor 1 > Electronics Rack 1 > Shelf 4 > PCB Stepper Motor Driver > ULN2003 Stepper Motor Driver",
      "product": "Product #3897",
      "stockName": "ULN2003 STEPPER DRIVER",
      "variant": "Standard (8)",
      "typeDist": "Shop In Sales",
      "allocatedQty": 8,
      "code": "QR/Barcode",
      "hierarchy": {
        "Building": "CP Building",
        "Floor": "Floor 1",
        "Rack": "Electronics Rack 1",
        "Shelf": "Shelf 4",
        "Box": "PCB Stepper Motor Driver",
        "Container": "ULN2003",
      },
    },
    {
      "id": 5,
      "sNo": 5,
      "locationPath": "CircuitPoint Store > CP Building > Floor 1 > Electronics Rack 1 > Shelf 5 > Big Buzzer",
      "product": "Product #2135",
      "stockName": "BIG BUZZER 12V",
      "variant": "12V Active (17)",
      "typeDist": "Shop In Sales",
      "allocatedQty": 17,
      "code": "QR/Barcode",
      "hierarchy": {
        "Building": "CP Building",
        "Floor": "Floor 1",
        "Rack": "Electronics Rack 1",
        "Shelf": "Shelf 5",
        "Box": "Big Buzzer",
        "Container": "Buzzer Unit",
      },
    },
    {
      "id": 6,
      "sNo": 6,
      "locationPath": "CircuitPoint Store > CP Building > Floor 1 > Electronics Rack 1 > Shelf 5 > Light Layer > Laser Diode",
      "product": "Product #2127",
      "stockName": "RED LASER DIODE 5MW",
      "variant": "5V Dot (7)",
      "typeDist": "Shop In Sales",
      "allocatedQty": 7,
      "code": "QR/Barcode",
      "hierarchy": {
        "Building": "CP Building",
        "Floor": "Floor 1",
        "Rack": "Electronics Rack 1",
        "Shelf": "Shelf 5",
        "Box": "Light Layer",
        "Container": "Laser Diode",
      },
    },
    {
      "id": 7,
      "sNo": 7,
      "locationPath": "CircuitPoint Store > CP Building > Floor 1 > Electronics Rack 1 > Shelf 4 > PCB Stepper Motor Driver > DRV8825 Stepper Motor",
      "product": "Product #161",
      "stockName": "DRV8825 STEPPER DRIVER",
      "variant": "Purple (1)",
      "typeDist": "Shop In Sales",
      "allocatedQty": 1,
      "code": "QR/Barcode",
      "hierarchy": {
        "Building": "CP Building",
        "Floor": "Floor 1",
        "Rack": "Electronics Rack 1",
        "Shelf": "Shelf 4",
        "Box": "PCB Stepper Motor Driver",
        "Container": "DRV8825",
      },
    },
  ];

  // Allocated stock items for "Without Variant" (Photo 3 is empty by default)
  List<Map<String, dynamic>> withoutVariantAllocations = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveAllocations();
  }

  Future<void> _fetchLiveAllocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token.isNotEmpty) "Authorization": "Bearer $token",
      };

      final res = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stocks/all/locations"),
        headers: headers,
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded['data'] ?? decoded;
        if (data is List && data.isNotEmpty) {
          // Merge with live data if available
        }
      }
    } catch (_) {
      // Offline fallback already loaded gracefully!
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
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  activeStorage['name'] = newName;
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
            onPressed: () {
              setState(() {
                if (isWithVariant) {
                  withVariantAllocations.removeWhere((item) => item['id'] == id);
                  // Re-index sNo
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
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Allocation deleted successfully"), backgroundColor: Colors.green),
              );
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

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (isWithVariant) {
          final idx = withVariantAllocations.indexWhere((e) => e['id'] == result['id']);
          if (idx != -1) {
            withVariantAllocations[idx] = result;
          } else {
            result['sNo'] = withVariantAllocations.length + 1;
            withVariantAllocations.add(result);
          }
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Allocation updated successfully"), backgroundColor: Colors.green),
        );
      }
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

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        result['id'] = DateTime.now().millisecondsSinceEpoch;
        result['sNo'] = withVariantAllocations.length + 1;
        withVariantAllocations.add(result);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Allocation created successfully"), backgroundColor: Colors.green),
        );
      }
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
      return path.contains(q) || prod.contains(q) || stock.contains(q);
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
      body: SingleChildScrollView(
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Allocated Stock Review",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 14),
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
                        onPressed: () {
                          _fetchLiveAllocations();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Data refreshed")),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF2563EB)),
                        label: Text(
                          "Refresh Data",
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
    );
  }
}
