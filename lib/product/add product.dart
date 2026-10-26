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
  final Map<String, dynamic>? editItem;
  const ProductEntryPage({super.key, this.editItem});

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

  String? _autofilledText;
  bool isLoading = true;

  // SCAN SETUP
  bool _isScanMode = false;
  bool _isBarcodeMode = false; // default to QR Code matching Photo 2

  // EDIT MODE
  int? editAllocationId;
  int? editCategoryGroupId;
  int? editCategoryId;
  int? editBrandId;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      editAllocationId = widget.editItem!['id'];
      editCategoryGroupId = widget.editItem!['category_group_id'];
      editCategoryId = widget.editItem!['category_id'];
      editBrandId = widget.editItem!['brand_id'];
      selectedProductId = widget.editItem!['product_id'];
      selectedProductName = widget.editItem!['name'];
      minQtyController.text = widget.editItem!['min']?.toString() ?? "";
      maxQtyController.text = widget.editItem!['max']?.toString() ?? "";
    }
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
      backgroundColor: const Color(0xFFF1F5F9), // Light background like web
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "Product Entry",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: () {
                _showAdvanceSearchDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
              ),
              child: Text(
                "Advance Search",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row with Icon & Title
                      Row(
                        children: [
                          const Icon(Icons.folder_shared_outlined, color: Color(0xFF3B82F6), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? "Edit Product Entry" : "Product Entry",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Center Mode Toggle (Manual Entry / Scanner)
                      if (!isEditing) ...[
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildModeButton("Manual Entry", !_isScanMode, Icons.search_rounded),
                                _buildModeButton("Scanner", _isScanMode, Icons.qr_code_scanner_rounded),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Product Scan Setup Card (When Scanner is chosen, Photos 2 & 3)
                      if (_isScanMode && !isEditing) ...[
                        _buildScanSetupArea(),
                        const SizedBox(height: 24),
                      ],

                      // Form Fields (CATEGORY, BRAND, PRODUCT, MIN QTY, MAX QTY)
                      _buildDropdownsFormArea(),
                      const SizedBox(height: 32),

                      // Centered Action Buttons (Save [Blue] & Cancel [Red])
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: saveOrUpdate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF60A5FA), // Soft blue like web button
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  isEditing ? "Update" : "Save",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 140,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (widget.editItem != null) {
                                    Navigator.pop(context);
                                  } else {
                                    cancelEdit();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444), // Red button like web
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
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
            ),
    );
  }

  void _showAdvanceSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Advance Search", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          "Enter keywords, category or barcode to search product catalog.",
          style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13),
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
          )
        ],
      ),
    );
  }
}