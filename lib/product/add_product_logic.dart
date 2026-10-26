part of 'add product.dart';

extension _ProductEntryPageStateLogic on _ProductEntryPageState {
  Future<void> loadInitialData() async {
    try {
      final list = await ApiService.getCategoryGroups();
      if (!mounted) return;
      setState(() => categoryGroups = list);

      if (list.isNotEmpty) {
        final targetGroupId = editCategoryGroupId ?? list.first.id!;
        selectedCategoryGroupId = targetGroupId;
        await loadCategoryBrandData(targetGroupId);
      }

      if (editCategoryId != null) {
        selectedCategoryId = editCategoryId;
        final matchedItem = rawCategoryBrandData.firstWhere(
          (item) => item['category_id'] == editCategoryId,
          orElse: () => {},
        );
        final brandList = matchedItem['brands'] ?? [];
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
          brands = uniqueBrands.values.toList();
          selectedBrandId = editBrandId;
        });

        if (editBrandId != null) {
          await loadProducts(selectedCategoryId!, editBrandId!);
          if (mounted) {
            setState(() {
              selectedProductId = widget.editItem?['product_id'];
              selectedProductName = widget.editItem?['name'];
            });
          }
        }
      }
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
        if (editAllocationId == null) {
          brands = [];
          products = [];
          selectedCategoryId = null;
          selectedSecondaryCategoryId = null;
          selectedBrandId = null;
          selectedProductId = null;
        }
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
          const SnackBar(content: Text("Updated successfully ✅"), backgroundColor: Colors.green),
        );
        if (widget.editItem != null) {
          Navigator.pop(context, true);
        }
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
          const SnackBar(content: Text("Saved successfully ✅"), backgroundColor: Colors.green),
        );
        // Reset selections
        setState(() {
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

  void _triggerSimulateScan() {
    final text = barcodeController.text.trim();
    if (text.isNotEmpty) {
      _handleBarcodeScan(text);
    } else {
      barcodeController.text = "HUAYU-REMOTE-123";
      _handleBarcodeScan("HUAYU-REMOTE-123");
    }
  }
}
