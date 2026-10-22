import 'package:flutter/material.dart';
import 'package:billingapp/Auth/api service.dart';
import 'package:billingapp/models/category%20grou0p.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

part 'add_product_logic.dart';
part 'add_product_widgets.dart';
part 'add_product_scanner.dart';

class ProductEntryPage extends StatefulWidget {
  const ProductEntryPage({super.key});

  @override
  State<ProductEntryPage> createState() => _ProductEntryPageState();
}

class _ProductEntryPageState extends State<ProductEntryPage> {
  // FORM DATA
  List<CategoryGroup> categoryGroups = [];
  List<Map<String, dynamic>> categoryItems = [];
  List<Map<String, dynamic>> secondaryCategories = [];
  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> products = [];
  List<dynamic> rawCategoryBrandData = [];

  int? selectedCategoryGroupId;
  int? selectedCategoryId;
  int? selectedSecondaryCategoryId;
  int? selectedBrandId;
  int? selectedProductId;
  String? selectedProductName;

  final minQtyController = TextEditingController();
  final maxQtyController = TextEditingController();
  final barcodeController = TextEditingController();

  bool isLoading = true;

  // SCAN SETUP
  bool _isScanMode = false;
  bool _isBarcodeMode = true;
  String? _autofilledText;

  // EDIT MODE
  int? editAllocationId;
  int? editCategoryGroupId;
  int? editCategoryId;
  int? editBrandId;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    minQtyController.dispose();
    maxQtyController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = editAllocationId != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Product Entry"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                "Advance Search",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? "Edit Allocation Details" : "Allocation Details",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                const SizedBox(height: 24),

                                // Mode Toggle Button
                                if (!isEditing) ...[
                                  Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildModeButton("Manual Entry", !_isScanMode, Icons.edit_note),
                                          _buildModeButton("Scan Code", _isScanMode, Icons.qr_code_scanner),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Scan Setup Area
                                if (_isScanMode && !isEditing) ...[
                                  _buildScanSetupArea(),
                                  const SizedBox(height: 24),
                                ],

                                // Dropdowns Form Section
                                if (!isEditing) ...[
                                  _buildDropdownsFormArea(),
                                ],

                                if (isEditing) ...[
                                  buildField(
                                    "PRODUCT NAME",
                                    TextFormField(
                                      initialValue: selectedProductName ?? "",
                                      enabled: false,
                                      decoration: _inputDecoration("Product Name"),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildResponsiveRow(
                                    buildField(
                                      "MIN QTY",
                                      TextFormField(
                                        controller: minQtyController,
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration("Enter Minimum Quantity"),
                                      ),
                                    ),
                                    buildField(
                                      "MAX QTY",
                                      TextFormField(
                                        controller: maxQtyController,
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration("Enter Maximum Quantity"),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: _buildResponsiveButtons(
                      ElevatedButton(
                        onPressed: isEditing ? cancelEdit : () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isEditing ? "CANCEL EDIT" : "CANCEL",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: saveOrUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isEditing ? "UPDATE" : "SAVE",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}