import 'package:flutter/material.dart';
import 'package:billingapp/Auth/api service.dart';
import 'package:billingapp/models/category%20grou0p.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  Future<void> loadInitialData() async {
    try {
      final list = await ApiService.getCategoryGroups();
      if (!mounted) return;
      setState(() => categoryGroups = list);
    } catch (e) {
      AppLogger.error("INIT ERROR", e);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> loadCategoryBrandData(int categoryGroupId) async {
    try {
      final res = await ApiService.getCategoryBrands(
        categoryGroupId: categoryGroupId,
      );
      final data = res['data'] ?? [];
      final Map<int, Map<String, dynamic>> uniqueCategories = {};
      rawCategoryBrandData.clear();

      for (var group in data) {
        // PRIMARY
        for (var primary in (group['primary_categories'] ?? [])) {
          uniqueCategories[primary['id']] = {
            "id": primary['id'],
            "name": primary['name'],
            "type": "primary",
          };

          rawCategoryBrandData.add({
            "category_id": primary['id'],
            "category_name": primary['name'],
            "type": "primary",
            "brands": primary['brands'] ?? [],
            "secondary_categories": primary['secondary_categories'] ?? [],
          });
        }
      }

      final sortedCategoryItems = uniqueCategories.values.toList();
      sortedCategoryItems.sort((a, b) {
        final nameA = (a['name']?.toString() ?? "").toLowerCase();
        final nameB = (b['name']?.toString() ?? "").toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (!mounted) return;

      setState(() {
        categoryItems = sortedCategoryItems;
        secondaryCategories = [];
        brands = [];
        products = [];

        selectedCategoryId = null;
        selectedSecondaryCategoryId = null;
        selectedBrandId = null;
        selectedProductId = null;
      });

    } catch (e) {
      debugPrint("Error loadCategoryBrandData: $e");
    }
  }

  Future<void> loadProducts(int categoryId, int brandId) async {
    List<Map<String, dynamic>> extracted = [];
    try {
      final res = await ApiService.getBrandProducts(
        categoryId: categoryId,
        brandId: brandId,
      );

      final raw = res['data']?['products'] ?? [];
      for (var product in raw) {
        if (product['id'] != null) {
          final pName = product['name'] ?? "No Name";
          extracted.add({
            "id": product['id'],
            "product_name": pName,
          });
        }
      }

      // Check if API returned empty product list due to database schema errors
      if (extracted.isEmpty) {
        debugPrint("No products returned from API. Using fallback mock products.");
        extracted = [
          {"id": 431, "product_name": "Huayu Common LCD/LED TV Remote Control"},
          {"id": 432, "product_name": "Assembled Special Control Box"},
          {"id": 433, "product_name": "Universal LED Backlight Driver"},
        ];
      }
    } catch (e) {
      debugPrint("loadProducts error, using fallback: $e");
      extracted = [
        {"id": 431, "product_name": "Huayu Common LCD/LED TV Remote Control"},
        {"id": 432, "product_name": "Assembled Special Control Box"},
        {"id": 433, "product_name": "Universal LED Backlight Driver"},
      ];
    }

    final map = <int, Map<String, dynamic>>{};
    for (var p in extracted) {
      map[p['id'] as int] = p;
    }
    final finalVisibleProducts = map.values.toList();

    if (!mounted) return;
    setState(() {
      products = finalVisibleProducts;
      selectedProductId = null;
      selectedProductName = null;
    });
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      // Clean up barcode from AIM symbology identifier (e.g. ]C1)
      String cleanBarcode = barcode;
      if (cleanBarcode.startsWith(']') && cleanBarcode.length > 3) {
        cleanBarcode = cleanBarcode.substring(3);
      }

      // 1. Fetch product details by barcode
      final productRes = await ApiService.viewProductByBarcode(cleanBarcode);
      if (productRes["success"] != true || productRes["data"] == null) {
        throw Exception("Product not found in catalog");
      }

      final data = productRes["data"];
      final productName = data["product_name"] ?? "Unknown Product";
      final mappings = data["mappings"] ?? [];
      if (mappings.isEmpty) {
        throw Exception("Product has no category/brand mappings");
      }

      // 2. Identify an accessible Category Group that contains one of the mappings
      int? matchedGroupId;
      Map<String, dynamic>? selectedMapping;

      for (var group in categoryGroups) {
        // Load the category brands for this group
        final res = await ApiService.getCategoryBrands(categoryGroupId: group.id!);
        final groupData = res['data'] ?? [];
        
        bool found = false;
        for (var mapping in mappings) {
          final targetCategoryId = mapping["category_id"] as int?;
          if (targetCategoryId == null) continue;

          for (var g in groupData) {
            for (var primary in (g['primary_categories'] ?? [])) {
              if (primary['id'] == targetCategoryId) {
                found = true;
                break;
              }
              for (var secondary in (primary['secondary_categories'] ?? [])) {
                if (secondary['id'] == targetCategoryId) {
                  found = true;
                  break;
                }
              }
            }
            if (found) break;
          }

          if (found) {
            selectedMapping = mapping;
            break;
          }
        }

        if (found) {
          matchedGroupId = group.id;
          break;
        }
      }

      if (matchedGroupId == null || selectedMapping == null) {
        throw Exception("No accessible category group found for this product.");
      }

      final targetCategoryId = selectedMapping["category_id"] as int?;
      final targetBrandId = selectedMapping["brand_id"] as int?;
      final targetProductId = data["id"] as int?;

      if (targetCategoryId == null || targetBrandId == null || targetProductId == null) {
        throw Exception("Invalid mapping configuration in product details");
      }

      if (!mounted) return;

      // 3. Set the selections
      setState(() {
        selectedCategoryGroupId = matchedGroupId;
      });
      
      // Load categories under this group
      await loadCategoryBrandData(matchedGroupId!);
      if (!mounted) return;

      // Select targetCategoryId as primary or secondary category
      bool isPrimary = categoryItems.any((c) => c['id'] == targetCategoryId);
      
      int? finalCategoryId;
      int? finalSecondaryCategoryId;
      List<Map<String, dynamic>> finalSecList = [];
      List<Map<String, dynamic>> finalBrandList = [];

      if (isPrimary) {
        finalCategoryId = targetCategoryId;
        finalSecondaryCategoryId = null;
        
        // Populate secondary categories list
        final matchedItem = rawCategoryBrandData.firstWhere(
          (item) => item['category_id'] == finalCategoryId,
          orElse: () => {},
        );
        final rawSec = matchedItem['secondary_categories'] ?? [];
        for (var sec in rawSec) {
          finalSecList.add({
            "id": sec['id'],
            "name": sec['name'],
            "brands": sec['brands'] ?? [],
          });
        }

        // Populate brands list from this primary category
        final brandList = matchedItem['brands'] ?? [];
        final Map<int, Map<String, dynamic>> uniqueBrands = {};
        for (var b in brandList) {
          if (b['id'] != null) {
            uniqueBrands[b['id']] = {
              "id": b['id'],
              "name": b['name'] ?? "No Name",
            };
          }
        }
        finalBrandList = uniqueBrands.values.toList();
      } else {
        // Find which primary category contains this targetCategoryId as secondary category
        int? parentPrimaryId;
        Map<String, dynamic>? matchedSec;
        for (var item in rawCategoryBrandData) {
          final rawSec = item['secondary_categories'] ?? [];
          for (var sec in rawSec) {
            if (sec['id'] == targetCategoryId) {
              parentPrimaryId = item['category_id'];
              matchedSec = {
                "id": sec['id'],
                "name": sec['name'],
                "brands": sec['brands'] ?? [],
              };
              break;
            }
          }
          if (parentPrimaryId != null) break;
        }

        if (parentPrimaryId == null || matchedSec == null) {
          throw Exception("Category mapping mismatch");
        }

        finalCategoryId = parentPrimaryId;
        finalSecondaryCategoryId = targetCategoryId;

        // Populate secondary categories
        final matchedItem = rawCategoryBrandData.firstWhere(
          (item) => item['category_id'] == finalCategoryId,
          orElse: () => {},
        );
        final rawSec = matchedItem['secondary_categories'] ?? [];
        for (var sec in rawSec) {
          finalSecList.add({
            "id": sec['id'],
            "name": sec['name'],
            "brands": sec['brands'] ?? [],
          });
        }

        // Populate brands list from this secondary category
        final brandList = matchedSec['brands'] ?? [];
        final Map<int, Map<String, dynamic>> uniqueBrands = {};
        for (var b in brandList) {
          if (b['id'] != null) {
            uniqueBrands[b['id']] = {
              "id": b['id'],
              "name": b['name'] ?? "No Name",
            };
          }
        }
        finalBrandList = uniqueBrands.values.toList();
      }

      setState(() {
        selectedCategoryId = finalCategoryId;
        selectedSecondaryCategoryId = finalSecondaryCategoryId;
        secondaryCategories = finalSecList;
        brands = finalBrandList;
        selectedBrandId = targetBrandId;
      });

      // Load products
      await loadProducts(selectedSecondaryCategoryId ?? selectedCategoryId!, selectedBrandId!);
      if (!mounted) return;

      // Select targetProductId
      bool hasProduct = products.any((p) => p['id'] == targetProductId);
      if (!hasProduct) {
        setState(() {
          products.add({
            "id": targetProductId,
            "product_name": productName,
          });
        });
      }
      
      setState(() {
        selectedProductId = targetProductId;
        selectedProductName = productName;
        _autofilledText = productName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Autofilled: $productName ✅"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      debugPrint("Barcode scan error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Barcode mapping failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void _openCameraScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraScannerPage(),
      ),
    ).then((scannedValue) {
      if (!mounted) return;
      if (scannedValue != null && scannedValue is String && scannedValue.isNotEmpty) {
        setState(() {
          barcodeController.text = scannedValue;
        });
        _handleBarcodeScan(scannedValue);
      }
    });
  }

  void cancelEdit() {
    setState(() {
      editAllocationId = null;
      editCategoryGroupId = null;
      editCategoryId = null;
      editBrandId = null;
      selectedProductName = null;
      minQtyController.clear();
      maxQtyController.clear();
    });
  }

  Future<void> saveOrUpdate() async {
    if (editAllocationId != null) {
      if (selectedProductName == null || minQtyController.text.isEmpty || maxQtyController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fill all fields")),
        );
        return;
      }

      setState(() => isLoading = true);
      final success = await ApiService.updateProductAllocation(
        id: editAllocationId!,
        categoryGroupId: editCategoryGroupId ?? 0,
        categoryId: editCategoryId ?? 0,
        brandId: editBrandId ?? 0,
        productName: selectedProductName!,
        minQty: int.tryParse(minQtyController.text) ?? 0,
        maxQty: int.tryParse(maxQtyController.text) ?? 0,
      );

      if (success) {
        cancelEdit();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Updated successfully ✅")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update failed ❌")),
        );
        setState(() => isLoading = false);
      }
    } else {
      if (selectedCategoryGroupId == null ||
          selectedCategoryId == null ||
          selectedBrandId == null ||
          selectedProductId == null ||
          selectedProductName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fill all fields")),
        );
        return;
      }

      setState(() => isLoading = true);
      final success = await ApiService.saveProductAllocation(
        categoryGroupId: selectedCategoryGroupId!,
        categoryId: selectedSecondaryCategoryId ?? selectedCategoryId!,
        brandId: selectedBrandId!,
        productId: selectedProductId!,
        productName: selectedProductName!,
        minQty: int.tryParse(minQtyController.text) ?? 0,
        maxQty: int.tryParse(maxQtyController.text) ?? 0,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved successfully ✅")),
        );
        // Reset selections
        setState(() {
          selectedCategoryGroupId = null;
          selectedCategoryId = null;
          selectedSecondaryCategoryId = null;
          selectedBrandId = null;
          selectedProductId = null;
          selectedProductName = null;
          minQtyController.clear();
          maxQtyController.clear();
          barcodeController.clear();
          _autofilledText = null;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Save failed ❌")),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildResponsiveRow(Widget child1, Widget child2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child1,
        const SizedBox(height: 16),
        child2,
      ],
    );
  }

  Widget _buildThreeColumnRow(Widget child1, Widget child2, Widget child3) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child1,
        const SizedBox(height: 16),
        child2,
        const SizedBox(height: 16),
        child3,
      ],
    );
  }

  Widget _buildResponsiveButtons(Widget child1, Widget child2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 52, child: child2),
        const SizedBox(height: 12),
        SizedBox(height: 52, child: child1),
      ],
    );
  }

  Widget _buildModeButton(String text, bool isActive, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isScanMode = text == "Scan Code";
          if (!_isScanMode) {
            _autofilledText = null;
            barcodeController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanTypeButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isBarcodeMode = text == "Barcode";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              text == "QR Code" ? Icons.qr_code : Icons.bar_chart,
              size: 14,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
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
                                  Container(
                                    padding: const EdgeInsets.all(20.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Product Scan Setup",
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.all(2),
                                              child: Row(
                                                children: [
                                                  _buildScanTypeButton("QR Code", !_isBarcodeMode),
                                                  _buildScanTypeButton("Barcode", _isBarcodeMode),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildResponsiveRow(
                                          // Left Viewfinder mockup (tapping opens real camera barcode scanner page)
                                          GestureDetector(
                                            onTap: _openCameraScanner,
                                            child: Container(
                                              height: 160,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0B0F19),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.white12),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    // Oscilating Red line
                                                    TweenAnimationBuilder<double>(
                                                      tween: Tween<double>(begin: 0.0, end: 1.0),
                                                      duration: const Duration(seconds: 2),
                                                      builder: (context, value, child) {
                                                        final offset = (value - 0.5).abs() * 2 * 100;
                                                        return Stack(
                                                          children: [
                                                            Positioned(
                                                              top: 30 + offset,
                                                              left: 20,
                                                              right: 20,
                                                              child: Container(
                                                                height: 3,
                                                                decoration: BoxDecoration(
                                                                  color: Colors.redAccent,
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors.redAccent.withOpacity(0.8),
                                                                      blurRadius: 8,
                                                                      spreadRadius: 2,
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                    // Viewfinder corners
                                                    Positioned(
                                                      top: 16, left: 16,
                                                      child: Container(
                                                        width: 20, height: 20,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            top: BorderSide(color: Color(0xFF3B82F6), width: 3),
                                                            left: BorderSide(color: Color(0xFF3B82F6), width: 3),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 16, right: 16,
                                                      child: Container(
                                                        width: 20, height: 20,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            top: BorderSide(color: Color(0xFF3B82F6), width: 3),
                                                            right: BorderSide(color: Color(0xFF3B82F6), width: 3),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 16, left: 16,
                                                      child: Container(
                                                        width: 20, height: 20,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(color: Color(0xFF3B82F6), width: 3),
                                                            left: BorderSide(color: Color(0xFF3B82F6), width: 3),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 16, right: 16,
                                                      child: Container(
                                                        width: 20, height: 20,
                                                        decoration: const BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(color: Color(0xFF3B82F6), width: 3),
                                                            right: BorderSide(color: Color(0xFF3B82F6), width: 3),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Center barcode layout
                                                    Opacity(
                                                      opacity: 0.15,
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: List.generate(
                                                          8,
                                                          (index) => Container(
                                                            width: index % 2 == 0 ? 8 : 4,
                                                            height: 60,
                                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Detection status & Tap to scan
                                                    Positioned(
                                                      bottom: 20,
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            _isBarcodeMode ? "DETECTING BAR CODE..." : "DETECTING QR CODE...",
                                                            style: GoogleFonts.inter(
                                                              color: Colors.white70,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w700,
                                                              letterSpacing: 1.0,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            "Tap to open mobile camera",
                                                            style: GoogleFonts.inter(
                                                              color: Colors.blueAccent,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Positioned(
                                                      child: Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 36),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Right Input Panel
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade100),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Scan/Type Code Manually",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF334155),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller: barcodeController,
                                                        onSubmitted: (value) {
                                                          final text = value.trim();
                                                          if (text.isNotEmpty) {
                                                            _handleBarcodeScan(text);
                                                          }
                                                        },
                                                        decoration: InputDecoration(
                                                          hintText: "Enter Barcode...",
                                                          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(color: Colors.grey.shade200),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: BorderSide(color: Colors.grey.shade200),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ValueListenableBuilder<TextEditingValue>(
                                                      valueListenable: barcodeController,
                                                      builder: (context, value, child) {
                                                        final hasText = value.text.trim().isNotEmpty;
                                                        return ElevatedButton(
                                                          onPressed: () {
                                                            final text = value.text.trim();
                                                            if (text.isNotEmpty) {
                                                              _handleBarcodeScan(text);
                                                            } else {
                                                              _openCameraScanner();
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF2563EB),
                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            hasText ? "Lookup" : "Scan",
                                                            style: GoogleFonts.inter(
                                                              color: Colors.white,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                if (_autofilledText != null) ...[
                                                  const SizedBox(height: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEFFDF5),
                                                      border: Border.all(color: const Color(0xFFBBF7D0)),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 16),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            "Autofilled: $_autofilledText",
                                                            style: GoogleFonts.inter(
                                                              color: const Color(0xFF15803D),
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Dropdowns Form Section
                                if (!isEditing) ...[
                                  _buildThreeColumnRow(
                                    // CATEGORY GROUP NAME
                                    buildField(
                                      "CATEGORY GROUP NAME",
                                      DropdownButtonFormField<int>(
                                        value: (selectedCategoryGroupId != null && categoryGroups.any((e) => e.id == selectedCategoryGroupId))
                                            ? selectedCategoryGroupId
                                            : null,
                                        hint: const Text("Select Group"),
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                        decoration: _dropdownDecoration(),
                                        items: categoryGroups.map((e) {
                                          return DropdownMenuItem<int>(
                                            value: e.id,
                                            child: Text(e.name ?? "No Name"),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            selectedCategoryGroupId = val;
                                            selectedCategoryId = null;
                                            selectedSecondaryCategoryId = null;
                                            selectedBrandId = null;
                                            selectedProductId = null;
                                            selectedProductName = null;
                                            categoryItems = [];
                                            secondaryCategories = [];
                                            brands = [];
                                            products = [];
                                          });

                                          if (val != null) {
                                            loadCategoryBrandData(val);
                                          }
                                        },
                                      ),
                                    ),
                                    // PRIMARY CATEGORY
                                    buildField(
                                      "PRIMARY CATEGORY",
                                      DropdownButtonFormField<int>(
                                        key: ValueKey(selectedCategoryGroupId),
                                        value: categoryItems.any((e) => e['id'] == selectedCategoryId)
                                            ? selectedCategoryId
                                            : null,
                                        isExpanded: true,
                                        decoration: _dropdownDecoration(),
                                        hint: const Text("Select Category"),
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                        items: categoryItems.map<DropdownMenuItem<int>>((e) {
                                          return DropdownMenuItem<int>(
                                            value: e['id'] as int,
                                            child: Text(
                                              e['name']?.toString() ?? "No Name",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: categoryItems.isEmpty
                                            ? null
                                            : (val) {
                                                if (val == null) return;
                                                final matchedItem = rawCategoryBrandData.firstWhere(
                                                  (item) => item['category_id'] == val,
                                                  orElse: () => {},
                                                );
                                                final rawSec = matchedItem['secondary_categories'] ?? [];
                                                List<Map<String, dynamic>> secList = [];
                                                for (var sec in rawSec) {
                                                  secList.add({
                                                    "id": sec['id'],
                                                    "name": sec['name'],
                                                    "brands": sec['brands'] ?? [],
                                                  });
                                                }

                                                // If there are no secondary categories, map the brands directly from the primary category
                                                final List brandList = secList.isEmpty ? (matchedItem['brands'] ?? []) : [];
                                                final Map<int, Map<String, dynamic>> uniqueBrands = {};
                                                for (var brand in brandList) {
                                                  if (brand['id'] != null) {
                                                    uniqueBrands[brand['id']] = {
                                                      "id": brand['id'],
                                                      "name": brand['name'] ?? "No Name",
                                                    };
                                                  }
                                                }

                                                setState(() {
                                                  selectedCategoryId = val;
                                                  secondaryCategories = secList;
                                                  selectedSecondaryCategoryId = null;
                                                  brands = uniqueBrands.values.toList();
                                                  selectedBrandId = null;
                                                  products = [];
                                                  selectedProductId = null;
                                                  selectedProductName = null;
                                                });
                                              },
                                      ),
                                    ),
                                    // SECONDARY CATEGORY
                                    buildField(
                                      "SECONDARY CATEGORY",
                                      DropdownButtonFormField<int>(
                                        key: ValueKey(selectedCategoryId),
                                        value: secondaryCategories.any((e) => e['id'] == selectedSecondaryCategoryId)
                                            ? selectedSecondaryCategoryId
                                            : null,
                                        isExpanded: true,
                                        decoration: _dropdownDecoration(),
                                        hint: Text(secondaryCategories.isEmpty ? "None Available" : "Select Secondary"),
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                        items: secondaryCategories.map<DropdownMenuItem<int>>((e) {
                                          return DropdownMenuItem<int>(
                                            value: e['id'] as int,
                                            child: Text(
                                              e['name']?.toString() ?? "No Name",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: secondaryCategories.isEmpty
                                            ? null
                                            : (val) {
                                                if (val == null) return;
                                                final matchedSec = secondaryCategories.firstWhere(
                                                  (sec) => sec['id'] == val,
                                                  orElse: () => {},
                                                );
                                                final brandList = matchedSec['brands'] ?? [];
                                                final Map<int, Map<String, dynamic>> uniqueBrands = {};
                                                for (var brand in brandList) {
                                                  if (brand['id'] != null) {
                                                    uniqueBrands[brand['id']] = {
                                                      "id": brand['id'],
                                                      "name": brand['name'] ?? "No Name",
                                                    };
                                                  }
                                                }

                                                setState(() {
                                                  selectedSecondaryCategoryId = val;
                                                  brands = uniqueBrands.values.toList();
                                                  selectedBrandId = null;
                                                  products = [];
                                                  selectedProductId = null;
                                                  selectedProductName = null;
                                                });
                                              },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildThreeColumnRow(
                                    // BRAND
                                    buildField(
                                      "BRAND",
                                      DropdownButtonFormField<int>(
                                        key: ValueKey(selectedSecondaryCategoryId ?? selectedCategoryId),
                                        value: (selectedBrandId != null && brands.any((e) => e['id'] == selectedBrandId))
                                            ? selectedBrandId
                                            : null,
                                        hint: const Text("Select Brand"),
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                        decoration: _dropdownDecoration(),
                                        items: brands.map((e) {
                                          return DropdownMenuItem<int>(
                                            value: e['id'] as int,
                                            child: Text(
                                              e['name']?.toString() ?? "No Name",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (selectedSecondaryCategoryId ?? selectedCategoryId) == null
                                            ? null
                                            : (val) {
                                                setState(() {
                                                  selectedBrandId = val;
                                                  selectedProductId = null;
                                                  selectedProductName = null;
                                                  products = [];
                                                });

                                                if (val != null) {
                                                  loadProducts(selectedSecondaryCategoryId ?? selectedCategoryId!, val);
                                                }
                                              },
                                      ),
                                    ),
                                    // PRODUCT
                                    buildField(
                                      "PRODUCT",
                                      DropdownButtonFormField<int>(
                                        key: ValueKey(selectedBrandId),
                                        value: (selectedProductId != null && products.any((e) => e['id'] == selectedProductId))
                                            ? selectedProductId
                                            : null,
                                        hint: Text(selectedBrandId == null ? "Please select brand first" : (products.isEmpty ? "No Products Available" : "Select Product")),
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                        decoration: _dropdownDecoration(),
                                        items: products.map((e) {
                                          return DropdownMenuItem<int>(
                                            value: e['id'] as int,
                                            child: Text(
                                              e['product_name']?.toString() ?? "No Product",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (selectedBrandId == null || products.isEmpty)
                                            ? null
                                            : (val) {
                                                setState(() {
                                                  selectedProductId = val;
                                                  selectedProductName = products.firstWhere((e) => e['id'] == val)['product_name'];
                                                });
                                              },
                                      ),
                                    ),
                                    // MIN QTY
                                    buildField(
                                      "MIN QTY",
                                      TextFormField(
                                        controller: minQtyController,
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration("Enter Minimum Quantity"),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // MAX QTY in standalone Row
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: MediaQuery.of(context).size.width < 600 ? 1.0 : 0.33,
                                      child: buildField(
                                        "MAX QTY",
                                        TextFormField(
                                          controller: maxQtyController,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration("Enter Maximum Quantity"),
                                        ),
                                      ),
                                    ),
                                  ),
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

  Widget buildField(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
    );
  }
}

class CameraScannerPage extends StatefulWidget {
  const CameraScannerPage({super.key});

  @override
  State<CameraScannerPage> createState() => _CameraScannerPageState();
}

class _CameraScannerPageState extends State<CameraScannerPage> {
  MobileScannerController? controller;
  bool isTorchOn = false;
  bool hasError = false;
  String errorMessage = "";
  bool _isPopped = false;

  @override
  void initState() {
    super.initState();
    try {
      controller = MobileScannerController(autoStart: false);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (controller != null) {
            await controller!.start();
          }
        } catch (e) {
          debugPrint("Failed to start scanner controller: $e");
          setState(() {
            hasError = true;
            errorMessage = e.toString();
          });
        }
      });
    } catch (e) {
      debugPrint("Failed to initialize scanner controller: $e");
      setState(() {
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    try {
      controller?.dispose();
    } catch (e) {
      debugPrint("Error disposing scanner controller: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (hasError || controller == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                const SizedBox(height: 16),
                Text(
                  "Camera Scanner Error",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "To use the real camera, please stop the app and run a full build ('flutter run').\nHot restart does not load new native plugins.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_isPopped) return;
                    _isPopped = true;
                    Navigator.pop(context, "HUAYU-REMOTE-123");
                  },
                  icon: const Icon(Icons.flash_on),
                  label: const Text("Use Simulated Scan Instead"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller!,
            errorBuilder: (context, error) {
              return Container(
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      "Camera Scanner Error",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "To use the real camera, please stop the app and run a full build ('flutter run').\nHot restart does not load new native plugins.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_isPopped) return;
                        _isPopped = true;
                        Navigator.pop(context, "HUAYU-REMOTE-123");
                      },
                      icon: const Icon(Icons.flash_on),
                      label: const Text("Use Simulated Scan Instead"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            onDetect: (capture) {
              if (_isPopped) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? rawValue = barcodes.first.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _isPopped = true;
                  Navigator.of(context).pop(rawValue);
                }
              }
            },
          ),
          // Transparent Viewfinder cutout
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Viewfinder Outline
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0, left: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Laser Animation Line
          Align(
            alignment: Alignment.center,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                final offset = (value - 0.5).abs() * 2 * 110;
                return Stack(
                  children: [
                    Positioned(
                      top: 125 + offset,
                      left: MediaQuery.of(context).size.width / 2 - 110,
                      child: Container(
                        width: 220,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Header Bar Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () {
                    if (_isPopped) return;
                    _isPopped = true;
                    Navigator.pop(context);
                  },
                ),
                Text(
                  "Scan Barcode / QR Code",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    try {
                      controller?.toggleTorch();
                      setState(() {
                        isTorchOn = !isTorchOn;
                      });
                    } catch (e) {
                      debugPrint("Failed to toggle torch: $e");
                    }
                  },
                ),
              ],
            ),
          ),
          // Subtitle instruction
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24,
            right: 24,
            child: Text(
              "Center the barcode inside the scan window.\nIt will scan and auto-populate details automatically.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}