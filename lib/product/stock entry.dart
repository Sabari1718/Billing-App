import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

part 'stock_entry_dialogs.dart';
part 'stock_entry_logic.dart';

class StockEntryPage extends StatefulWidget {
  const StockEntryPage({super.key});

  @override
  _StockEntryPageState createState() => _StockEntryPageState();
}

class _StockEntryPageState extends State<StockEntryPage> {
  List suppliers = [];
  List products = [];

  String? selectedSupplier;
  String? selectedProduct;

  int? currentMin;
  int? currentMax;
  bool isOneTimeOrder = false; // Bound to the "Default: Disabled" Switch
  bool withVariantMode = true; // Switch tab mode selector

  // Controllers
  final TextEditingController qtyController = TextEditingController(); // Stores total qty
  final TextEditingController variantQtyController = TextEditingController();
  final TextEditingController buyingController = TextEditingController();
  final TextEditingController profitController = TextEditingController();
  final TextEditingController sellingController = TextEditingController();
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
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      };

  List<Map<String, dynamic>> variants = [];
  bool isLoadingVariants = false;

  List<Map<String, dynamic>> stockTypes = [];
  bool isLoadingStockTypes = false;
  String? currentBusinessId;

  Map<int, Map<String, String>> variantTabData = {};
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Stock Entry",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode switcher (With Variant | Without Variant)
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // With Variant Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => withVariantMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: withVariantMode ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: withVariantMode
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: withVariantMode ? const Color(0xFF2563EB) : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "With Variant",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: withVariantMode ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Without Variant Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => withVariantMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !withVariantMode ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: !withVariantMode
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: !withVariantMode ? const Color(0xFF2563EB) : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Without Variant",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !withVariantMode ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Inputs stacked vertically for Mobile
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supplier Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text("SUPPLIER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          Text(" *", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        hint: const Text("Select Supplier", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        isExpanded: true,
                        value: (suppliers.any((e) => e['id'].toString() == selectedSupplier)) ? selectedSupplier : null,
                        items: suppliers.map<DropdownMenuItem<String>>((e) {
                          String name = e['supplier_name']?.toString() ?? e['company_name']?.toString() ?? e['name']?.toString() ?? "No Name";
                          return DropdownMenuItem(value: e['id'].toString(), child: Text(name, style: const TextStyle(fontSize: 12)));
                        }).toList(),
                        onChanged: (val) => setState(() => selectedSupplier = val),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Default Switch Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOneTimeOrder ? "Default: Enabled" : "Default: Disabled",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: isOneTimeOrder,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) => setState(() => isOneTimeOrder = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Product Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text("PRODUCT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          Text(" *", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        hint: const Text("Select Product", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        isExpanded: true,
                        value: (products.any((e) => e['id'].toString() == selectedProduct)) ? selectedProduct : null,
                        items: products.map<DropdownMenuItem<String>>((e) {
                          String name = e['product_name']?.toString() ?? e['name']?.toString() ?? "Unnamed Product";
                          return DropdownMenuItem(value: e['id'].toString(), child: Text(name, style: const TextStyle(fontSize: 12)));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedProduct = val;
                            final matched = products.where((p) => p['id'].toString() == val).toList();
                            if (matched.isNotEmpty) {
                              currentMin = int.tryParse(matched.first['min']?.toString() ?? '1') ?? 1;
                              currentMax = int.tryParse(matched.first['max']?.toString() ?? '100') ?? 100;
                            } else {
                              currentMin = null;
                              currentMax = null;
                            }
                          });
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Dynamic fields sections based on selection mode
              if (withVariantMode) ...[
                // VARIANT DETAILS TRIGGER
                const Text("VARIANT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: openVariantPopup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Specify Variant Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 28),

                // STOCK DIST TRIGGER
                const Text("STOCK DIST", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: openStockPopup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Specify Stock Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                // PRICE DETAILS TRIGGER (Without Variant)
                const Text("PRICE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: openPriceDetailsPopup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Price Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 28),

                // STOCK DIST TRIGGER
                const Text("STOCK DIST", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: openStockPopup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Specify Stock Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Bottom Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: isSaving ? null : saveStock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC3545),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
