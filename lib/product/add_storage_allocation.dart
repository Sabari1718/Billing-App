import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  // Toggle: With Variant vs Without Variant (Photo 2)
  bool isWithVariant = true;

  // Selected Stock Component values
  String selectedStockName = "6A4 DIODE 6 AMP";
  String selectedVariant = "Imported (5)";
  String selectedStockDist = "Select Location";

  final List<String> stockNameOptions = [
    "6A4 DIODE 6 AMP",
    "SIM 900A GSM MODULE",
    "A4988 STEPPER MOTOR DRIVER",
    "ULN2003 STEPPER DRIVER",
    "BIG BUZZER 12V",
    "RED LASER DIODE 5MW",
    "DRV8825 STEPPER DRIVER",
  ];

  final List<String> variantOptions = [
    "Imported (5)",
    "Standard (2)",
    "Red Board (4)",
    "Standard (8)",
    "12V Active (17)",
    "5V Dot (7)",
    "Purple (1)",
  ];

  final List<String> stockDistOptions = [
    "Select Location",
    "Shop In Sales",
    "Main Warehouse",
    "Display Counter",
  ];

  // Previous configuration banner (Photo 2)
  bool showPreviousConfig = true;
  List<String> previousConfigParts = [
    "CP Building",
    "Floor 1",
    "Electronics Rack 1",
    "Shelf 5",
    "Diode1",
    "6A4 Diode",
  ];

  // Define Location Path selections
  String selectedBuilding = "CP Building";
  String selectedFloor = "Floor 1";
  String selectedRack = "Electronics Rack 1";
  String selectedShelf = "Shelf 5";
  String selectedBox = "Diode1";
  String selectedContainer = "6A4 Diode";

  final List<String> buildingOptions = ["CP Building", "Warehouse A", "Main Facility"];
  final List<String> floorOptions = ["Floor 1", "Floor 2", "Ground Floor"];
  final List<String> rackOptions = ["Electronics Rack 1", "Hardware Rack 2", "Parts Rack 3"];
  final List<String> shelfOptions = ["Shelf 4", "Shelf 5", "Shelf 6"];
  final List<String> boxOptions = ["Diode1", "GSM", "PCB Stepper Motor Driver", "Big Buzzer", "Light Layer"];
  final List<String> containerOptions = ["6A4 Diode", "GPS", "A4988", "ULN2003", "Laser Diode", "DRV8825"];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      if (data['stockName'] != null) selectedStockName = data['stockName'];
      if (data['variant'] != null) selectedVariant = data['variant'];
      if (data['typeDist'] != null) selectedStockDist = data['typeDist'];

      if (data['hierarchy'] != null && data['hierarchy'] is Map) {
        final h = data['hierarchy'] as Map;
        if (h['Building'] != null) selectedBuilding = h['Building'];
        if (h['Floor'] != null) selectedFloor = h['Floor'];
        if (h['Rack'] != null) selectedRack = h['Rack'];
        if (h['Shelf'] != null) selectedShelf = h['Shelf'];
        if (h['Box'] != null) selectedBox = h['Box'];
        if (h['Container'] != null) selectedContainer = h['Container'];
      }
    }
  }

  void _saveAllocation() {
    final updatedItem = {
      if (widget.initialData != null) "id": widget.initialData!['id'],
      if (widget.initialData != null) "sNo": widget.initialData!['sNo'],
      "locationPath": "${widget.storageTypeName} > $selectedBuilding > $selectedFloor > $selectedRack > $selectedShelf > $selectedBox > $selectedContainer",
      "product": widget.initialData != null ? widget.initialData!['product'] : "Product #${DateTime.now().millisecondsSinceEpoch % 10000}",
      "stockName": selectedStockName,
      "variant": selectedVariant,
      "typeDist": selectedStockDist == "Select Location" ? "Shop In Sales" : selectedStockDist,
      "allocatedQty": widget.initialData != null ? widget.initialData!['allocatedQty'] : 5,
      "code": "QR/Barcode",
      "hierarchy": {
        "Building": selectedBuilding,
        "Floor": selectedFloor,
        "Rack": selectedRack,
        "Shelf": selectedShelf,
        "Box": selectedBox,
        "Container": selectedContainer,
      },
    };

    Navigator.pop(context, updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                "Back to storages",
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
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            // CARD 1: SELECT STOCK COMPONENT (Photo 2)
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
                  // Title and With/Without Variant Toggles
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers_outlined, size: 16, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Text(
                            "Select Stock Component",
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isWithVariant = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isWithVariant ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "With Variant",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isWithVariant ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => isWithVariant = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !isWithVariant ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Without Variant",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
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
                  const SizedBox(height: 12),

                  Text(
                    "CHOOSE PRODUCT / STOCK ENTRY",
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 14),

                  // 3 Dropdown Fields: Stock Name, Variant, Stock Dist (Photo 2)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;

                      final stockField = _buildDropdownField(
                        label: "STOCK NAME",
                        value: selectedStockName,
                        items: stockNameOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => selectedStockName = val);
                        },
                      );

                      final variantField = _buildDropdownField(
                        label: "VARIANT",
                        value: selectedVariant,
                        items: variantOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => selectedVariant = val);
                        },
                      );

                      final distField = _buildDropdownField(
                        label: "STOCK DIST",
                        value: selectedStockDist,
                        items: stockDistOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => selectedStockDist = val);
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
                          Expanded(child: stockField),
                          const SizedBox(width: 12),
                          Expanded(child: variantField),
                          const SizedBox(width: 12),
                          Expanded(child: distField),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CARD 2: CHOOSE STORAGE TYPE (Photo 2)
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
                  // Section Header
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(
                        "Choose Storage Type",
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Yellow Previous Configuration Banner (Photo 2)
                  if (showPreviousConfig)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 6),
                              Text(
                                "PREVIOUS CONFIGURATION:",
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: previousConfigParts.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final part = entry.value;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFCD34D)),
                                    ),
                                    child: Text(part, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                                  ),
                                  if (idx < previousConfigParts.length - 1)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.chevron_right, size: 12, color: Color(0xFFD97706)),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                          InkWell(
                            onTap: () => setState(() => showPreviousConfig = false),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.close, size: 12, color: Color(0xFF92400E)),
                                  const SizedBox(width: 2),
                                  Text("Clear", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Text(
                    "1. Choose Storage Type",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),

                  // Selected Storage Type Card (Photo 2)
                  Container(
                    width: 130,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.dns_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.storageTypeName,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CARD 3: DEFINE LOCATION PATH (Photo 2)
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
                      const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(
                        "Define Location Path",
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2-Column Responsive Grid for Hierarchy Levels
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 550;

                      final buildingField = _buildDropdownField(
                        label: "Building",
                        value: selectedBuilding,
                        items: buildingOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => selectedBuilding = val);
                        },
                      );

                      final floorField = _buildDropdownField(
                        label: "Floor",
                        value: selectedFloor,
                        items: floorOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => selectedFloor = val);
                        },
                      );

                      final rackField = _buildDropdownField(
                        label: "Rack",
                        value: selectedRack,
                        items: rackOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => selectedRack = val);
                        },
                      );

                      final shelfField = _buildDropdownField(
                        label: "Shelf",
                        value: selectedShelf,
                        items: shelfOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => selectedShelf = val);
                        },
                      );

                      final boxField = _buildDropdownField(
                        label: "Box",
                        value: selectedBox,
                        items: boxOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => selectedBox = val);
                        },
                      );

                      final containerField = _buildDropdownField(
                        label: "Container",
                        value: selectedContainer,
                        items: containerOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => selectedContainer = val);
                        },
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            buildingField,
                            const SizedBox(height: 12),
                            floorField,
                            const SizedBox(height: 12),
                            rackField,
                            const SizedBox(height: 12),
                            shelfField,
                            const SizedBox(height: 12),
                            boxField,
                            const SizedBox(height: 12),
                            containerField,
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: buildingField),
                              const SizedBox(width: 14),
                              Expanded(child: floorField),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: rackField),
                              const SizedBox(width: 14),
                              Expanded(child: shelfField),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: boxField),
                              const SizedBox(width: 14),
                              Expanded(child: containerField),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Bottom Notice (Photo 2)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Assigning drawers from SA12-DiodeBox",
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E40AF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cancel & Save Allocation Buttons (Photo 2)
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        onPressed: _saveAllocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text("Save Allocation", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
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
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
              items: effectiveItems.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
