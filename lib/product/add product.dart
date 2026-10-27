import 'package:flutter/material.dart';
import 'package:billingapp/Auth/api service.dart';
import 'package:billingapp/models/category%20grou0p.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/Auth/billing%20dashboardc.dart';
import 'package:billingapp/product/viewpage.dart';

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
  String? selectedProductMrp;
  String? selectedProductCode;

  final minQtyController = TextEditingController();
  final maxQtyController = TextEditingController();
  final barcodeController = TextEditingController();

  String? _autofilledText;
  bool isLoading = true;

  void clearCategory() {
    setState(() {
      selectedCategoryId = null;
      selectedSecondaryCategoryId = null;
      selectedBrandId = null;
      selectedProductId = null;
      selectedProductName = null;
      selectedProductMrp = null;
      selectedProductCode = null;
      secondaryCategories = [];
      brands = [];
      products = [];
    });
  }

  void incrementMinQty() {
    final cur = int.tryParse(minQtyController.text) ?? 0;
    minQtyController.text = (cur + 1).toString();
    setState(() {});
  }

  void decrementMinQty() {
    final cur = int.tryParse(minQtyController.text) ?? 0;
    if (cur > 1) {
      minQtyController.text = (cur - 1).toString();
    } else {
      minQtyController.text = "";
    }
    setState(() {});
  }

  void incrementMaxQty() {
    final cur = int.tryParse(maxQtyController.text) ?? 0;
    maxQtyController.text = (cur + 1).toString();
    setState(() {});
  }

  void decrementMaxQty() {
    final cur = int.tryParse(maxQtyController.text) ?? 0;
    if (cur > 1) {
      maxQtyController.text = (cur - 1).toString();
    } else {
      maxQtyController.text = "";
    }
    setState(() {});
  }


  // SCAN SETUP
  bool _isScanMode = false;
  bool _isBarcodeMode = false; // default to QR Code matching Photo 2

  // EDIT MODE
  int? editAllocationId;
  int? editCategoryGroupId;
  int? editCategoryId;
  int? editBrandId;

  // STORE SETUP HIERARCHY (From GET /api/product-entry/store-setup)
  String hierarchyMode = "primary_secondary_brand";
  bool hasSecondaryCategories = true;
  List<Map<String, dynamic>> storeSetupPrimaryCategories = [];

  // CONNECTED APIS: STORE, NOTIFICATIONS, PERMISSIONS
  List<Map<String, dynamic>> stores = [];
  Map<String, dynamic>? currentStore;
  int unreadNotificationsCount = 0;
  bool isOwner = true;
  bool canCreateProduct = true;
  bool canReadProduct = true;
  bool canManageProduct = true;
  Map<String, dynamic>? userPermissions;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Product Entry",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (currentStore != null)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "${currentStore!['store_name'] ?? 'Store'} • #${currentStore!['store_id'] ?? ''}",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          // Notification Bell with Unread Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, size: 22),
                tooltip: "Notifications",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
              ),
              if (unreadNotificationsCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      "$unreadNotificationsCount",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10, bottom: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: saveOrUpdate,
                                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                    label: Text(
                                      isEditing ? "Update" : "Save",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (widget.editItem != null) {
                                        Navigator.pop(context);
                                      } else {
                                        cancelEdit();
                                      }
                                    },
                                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                    label: Text(
                                      "Cancel",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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