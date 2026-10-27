import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'stock list.dart';

part 'stock_entry_dialogs.dart';
part 'stock_entry_logic.dart';

class StockEntryPage extends StatefulWidget {
  final Map<String, dynamic>? editStockItem;
  const StockEntryPage({super.key, this.editStockItem});

  @override
  _StockEntryPageState createState() => _StockEntryPageState();
}

class _StockEntryPageState extends State<StockEntryPage> {
  bool get isEditing => widget.editStockItem != null;
  List suppliers = [];
  List products = [];

  String? selectedSupplier;
  String? selectedProduct;

  int? currentMin;
  int? currentMax;
  bool isOneTimeOrder = false; // Bound to the "Default: Disabled" Switch
  bool withVariantMode = true; // Switch tab mode selector
  bool isManufactureMode = false; // Manufacture mode toggle (Photos 1, 2, 3)

  // Controllers
  final TextEditingController qtyController = TextEditingController(text: "0");
  final TextEditingController variantQtyController = TextEditingController();
  final TextEditingController buyingController = TextEditingController(text: "0.00");
  final TextEditingController profitController = TextEditingController(text: "0.00");
  final TextEditingController sellingController = TextEditingController(text: "0.00");
  final TextEditingController distQtyController = TextEditingController();

  final Map<int, TextEditingController> qtyCtrls = {};
  final Map<int, TextEditingController> priceCtrls = {};
  final Map<int, TextEditingController> profitCtrls = {};
  final Map<int, TextEditingController> purchaseValueCtrls = {};
  final Map<int, TextEditingController> sellingPerQtyCtrls = {};
  final Map<int, TextEditingController> totalSellingValCtrls = {};

  final ValueNotifier<String> sellingPriceNotifier = ValueNotifier<String>("0.00");

  String token = "";
  bool isSaving = false;

  Map<String, String> get headers => {
        if (token.isNotEmpty) "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-App-ID": "Product94674",
      };

  List<Map<String, dynamic>> variants = [];
  bool isLoadingVariants = false;

  List<Map<String, dynamic>> stockTypes = [];
  bool isLoadingStockTypes = false;
  String? currentBusinessId;
  String? currentStoreId;
  String productGstRate = "18% GST";

  Map<int, Map<String, dynamic>> variantTabData = {};
  Map<int, List<Map<String, dynamic>>> stockTabData = {};

  @override
  void dispose() {
    qtyController.dispose();
    variantQtyController.dispose();
    buyingController.dispose();
    profitController.dispose();
    sellingController.dispose();
    distQtyController.dispose();
    sellingPriceNotifier.dispose();
    qtyCtrls.values.forEach((c) => c.dispose());
    priceCtrls.values.forEach((c) => c.dispose());
    profitCtrls.values.forEach((c) => c.dispose());
    purchaseValueCtrls.values.forEach((c) => c.dispose());
    sellingPerQtyCtrls.values.forEach((c) => c.dispose());
    totalSellingValCtrls.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initToken();
  }

  Widget _buildStockEntryHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colorful gears icon matching web
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              isEditing ? "Edit Stock Entry" : "Stock Entry",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockListPage()),
                );
              },
              icon: const Icon(Icons.list_alt_rounded, size: 15, color: Color(0xFF2563EB)),
              label: Text(
                "Stock List",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                side: const BorderSide(color: Color(0xFF93C5FD)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            // Manufacture Button (Matching Photos 1, 2, 3)
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  isManufactureMode = !isManufactureMode;
                });
              },
              icon: Icon(
                Icons.factory_outlined,
                size: 15,
                color: isManufactureMode ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
              label: Text(
                isManufactureMode ? "Manufacture ✓" : "Manufacture",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isManufactureMode ? const Color(0xFF2563EB) : const Color(0xFF475569),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: isManufactureMode ? const Color(0xFFEFF6FF) : Colors.white,
                side: BorderSide(
                  color: isManufactureMode ? const Color(0xFF93C5FD) : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // With Variant Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => withVariantMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: withVariantMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: withVariantMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: withVariantMode ? const Color(0xFF2563EB) : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "With Variant",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: withVariantMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Without Variant Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => withVariantMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: !withVariantMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: !withVariantMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: !withVariantMode ? const Color(0xFF2563EB) : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Without Variant",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !withVariantMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          isEditing ? "Edit Stock Entry" : "Stock Entry",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Icon & Manufacture button
                    _buildStockEntryHeader(),
                    const SizedBox(height: 20),

                    // With Variant / Without Variant Mode Pill
                    _buildModeToggle(),
                    const SizedBox(height: 24),

                    // Section 1: Supplier / Manufacturer Field
                    if (!isManufactureMode) ...[
                      // SUPPLIER FIELD (Photos 1 & 2)
                      Row(
                        children: [
                          Text("SUPPLIER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                          Text(" *", style: GoogleFonts.inter(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(
                            isOneTimeOrder ? "Default: Enabled" : "Default: Disabled",
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: isOneTimeOrder,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (val) => setState(() => isOneTimeOrder = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        hint: Text("Select Supplier", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                        isExpanded: true,
                        value: (suppliers.any((e) => e['id'].toString() == selectedSupplier)) ? selectedSupplier : null,
                        items: suppliers.map<DropdownMenuItem<String>>((e) {
                          String name = e['supplier_name']?.toString() ?? e['company_name']?.toString() ?? e['name']?.toString() ?? "No Name";
                          return DropdownMenuItem(value: e['id'].toString(), child: Text(name, style: GoogleFonts.inter(fontSize: 13)));
                        }).toList(),
                        onChanged: (val) => setState(() => selectedSupplier = val),
                        decoration: _inputDecoration(),
                      ),
                    ] else ...[
                      // MANUFACTURER FIELD (Photo 3)
                      Row(
                        children: [
                          Text("MANUFACTURER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                          Text(" *", style: GoogleFonts.inter(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront_outlined, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(
                                  "In-House Store",
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Circuitpointcare",
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Branch: Neelambur, Sulur Taluk, Coimbatore, Tamil Nadu",
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check, size: 13, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            "Default Store: Circuitpointcare",
                            style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Section 2: Product Field
                    Row(
                      children: [
                        Text("PRODUCT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                        Text(" *", style: GoogleFonts.inter(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      hint: Text("Select Product", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                      isExpanded: true,
                      value: (products.any((e) => e['id'].toString() == selectedProduct)) ? selectedProduct : null,
                      items: products.map<DropdownMenuItem<String>>((e) {
                        String name = e['product_name']?.toString() ?? e['name']?.toString() ?? "Unnamed Product";
                        return DropdownMenuItem(value: e['id'].toString(), child: Text(name, style: GoogleFonts.inter(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedProduct = val;
                          onProductSelected(val);
                        });
                      },
                      decoration: _inputDecoration(),
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Variant / Price Details Action Button
                    if (withVariantMode) ...[
                      Text("VARIANT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: openVariantPopup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: Text("Specify Variant Details", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ] else ...[
                      Text("PRICE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: openPriceDetailsPopup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: Text("Price Details", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Section 4: Stock Dist Action Button
                    Text("STOCK DIST", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: openStockPopup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Text("Specify Stock Details", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Section 5: Save & Cancel Buttons (Matching Web)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : saveStock,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(isEditing ? "Update" : "Save", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Text("Cancel", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
