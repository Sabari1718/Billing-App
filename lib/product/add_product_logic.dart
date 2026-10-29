part of 'add product.dart';

extension _ProductEntryPageStateLogic on _ProductEntryPageState {
  Future<void> loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bId = prefs.getString("selected_business_id") ??
          prefs.get("business_id")?.toString() ??
          "52";
      final pId = prefs.getString("selected_platform_id") ??
          prefs.get("platform_id")?.toString() ??
          "1";
      final uId = prefs.getString("user_main_id") ??
          prefs.getString("user_id") ??
          prefs.get("user_id")?.toString() ??
          "4995251182";
      final sId = prefs.getString("selected_store_id") ??
          prefs.get("store_id")?.toString() ??
          "38";

      // 1. Primary Requirement: Fetch Category List directly from https://srivagroups.in/api/category/list
      bool categoryLoaded = false;
      try {
        final catListRes = await ApiService.getCategoryList();
        final rawCatList = catListRes['data'];
        if (rawCatList is List && rawCatList.isNotEmpty) {
          final List<Map<String, dynamic>> primaryList = [];
          final List<Map<String, dynamic>> secondaryList = [];

          for (var item in rawCatList) {
            if (item != null && item is Map && item['id'] != null) {
              final catId = int.tryParse(item['id'].toString()) ?? 0;
              final catName = (item['name'] ?? item['category_name'] ?? "").toString().trim();
              if (catId == 0 || catName.isEmpty) continue;
              final catCode = (item['code'] ?? "").toString().trim();
              final catType = (item['category_type'] ?? item['categoryType'] ?? "primary").toString().toLowerCase();
              final imgUrl = (item['image_url'] ?? item['image'] ?? "").toString();
              final pCatId = item['parent_category_id'] ?? item['parentCategoryId'];
              final pCatName = (item['parent_category_name'] ?? "").toString().trim();

              final catObj = {
                "id": catId,
                "name": catName,
                "code": catCode,
                "type": catType,
                "is_primary": catType == "primary",
                "parent_id": pCatId,
                "parent_name": pCatName,
                "image_url": imgUrl,
                "brands": [],
                "raw": item,
              };

              if (catType == "primary") {
                primaryList.add(catObj);
              } else {
                secondaryList.add(catObj);
              }
            }
          }

          // Build hierarchical list: Primary Category, followed by its subcategories (Matching Web Photo 3)
          final List<Map<String, dynamic>> hierarchical = [];
          final Set<int> addedSecondaryIds = {};

          for (var p in primaryList) {
            hierarchical.add(p);

            final children = secondaryList.where((s) {
              final pid = s['parent_id']?.toString();
              final pname = s['parent_name']?.toString().toLowerCase();
              return pid == p['id'].toString() || (pname != null && pname.isNotEmpty && pname == p['name'].toString().toLowerCase());
            }).toList();

            for (var c in children) {
              addedSecondaryIds.add(c['id'] as int);
              hierarchical.add(c);
            }
          }

          // Append any remaining unparented secondary categories
          for (var s in secondaryList) {
            if (!addedSecondaryIds.contains(s['id'] as int)) {
              hierarchical.add(s);
            }
          }

          if (hierarchical.isNotEmpty) {
            categoryItems = hierarchical;
            categoryLoaded = true;
            debugPrint("Successfully loaded ${hierarchical.length} categories hierarchically from srivagroups.in");
          }
        }
      } catch (e) {
        debugPrint("Error fetching category list from srivagroups: $e");
      }

      // 2. Auxiliary APIs: Stores, Notifications, Permissions, CategoryGroups, StoreSetup (Safe & Non-blocking)
      try {
        final storeRes = await ApiService.getStores(businessId: bId, platformId: pId);
        if (storeRes['success'] == true && storeRes['data'] is List) {
          stores = List<Map<String, dynamic>>.from(storeRes['data']);
          if (stores.isNotEmpty) currentStore = stores.first;
        }
      } catch (_) {}

      try {
        final notifRes = await ApiService.getNotifications();
        if (notifRes['success'] == true) {
          final counts = notifRes['counts'];
          if (counts is Map && counts['unread'] != null) {
            unreadNotificationsCount = int.tryParse(counts['unread'].toString()) ?? 0;
          } else if (notifRes['notifications'] is List) {
            unreadNotificationsCount = (notifRes['notifications'] as List).length;
          }
        }
      } catch (_) {}

      try {
        final permRes = await ApiService.getUserPermissions();
        if (permRes['success'] == true) {
          userPermissions = permRes;
          isOwner = permRes['isOwner'] == true;
          final modules = permRes['modules'];
          if (modules is List) {
            for (var mod in modules) {
              if (mod['moduleName'] == 'Product' && mod['pages'] is List) {
                for (var page in mod['pages']) {
                  if (page['pageName'] == 'Add Product') {
                    final perms = page['permissions'] ?? {};
                    canCreateProduct = perms['create'] == true || isOwner;
                    canReadProduct = perms['read'] == true || isOwner;
                    canManageProduct = perms['manage'] == true || isOwner;
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      try {
        final list = await ApiService.getCategoryGroups();
        setState(() => categoryGroups = list);
        if (list.isNotEmpty) {
          selectedCategoryGroupId = editCategoryGroupId ?? list.first.id!;
        }
      } catch (_) {}

      // 3. Fallback: If category list failed, use Store Setup or Category Groups
      if (!categoryLoaded) {
        try {
          final storeSetupRes = await ApiService.getProductEntryStoreSetup(
            userId: uId,
            businessId: bId,
            platformId: pId,
            storeId: sId,
          );
          if (storeSetupRes['success'] == true && storeSetupRes['data'] is Map<String, dynamic>) {
            final setupData = storeSetupRes['data'] as Map<String, dynamic>;
            hierarchyMode = setupData['hierarchy_mode']?.toString() ?? "primary_secondary_brand";
            hasSecondaryCategories = setupData['has_secondary_categories'] == true;
            final rawPrimary = setupData['primaryCategories'];
            if (rawPrimary is List && rawPrimary.isNotEmpty) {
              final List<Map<String, dynamic>> parsedCategories = [];
              for (var item in rawPrimary) {
                if (item['id'] != null) {
                  parsedCategories.add({
                    "id": item['id'],
                    "name": item['name'] ?? "No Name",
                    "brands": List<Map<String, dynamic>>.from(item['brands'] ?? []),
                  });
                }
              }
              if (parsedCategories.isNotEmpty) {
                categoryItems = parsedCategories;
                categoryLoaded = true;
              }
            }
          }
        } catch (_) {}

        if (!categoryLoaded) {
          if (categoryGroups.isNotEmpty) {
            final targetGroupId = editCategoryGroupId ?? categoryGroups.first.id!;
            selectedCategoryGroupId = targetGroupId;
            await loadCategoryBrandData(targetGroupId);
          } else {
            await _loadCategoriesFallback();
          }
        }
      }

      // Initialize selection in edit mode if needed
      if (editCategoryId != null) {
        await _initializeEditCategoryBrand();
      }
    } catch (e) {
      AppLogger.error("INIT ERROR", e);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _initializeEditCategoryBrand() async {
    if (editCategoryId == null) return;

    // Check if category exists in categoryItems
    final matchedCat = categoryItems.firstWhere(
      (c) => c['id']?.toString() == editCategoryId.toString(),
      orElse: () => {},
    );

    if (matchedCat.isNotEmpty) {
      bool isPrimary = matchedCat['is_primary'] == true || matchedCat['type'] == 'primary';
      if (isPrimary) {
        selectedCategoryId = int.tryParse(matchedCat['id']?.toString() ?? "") ?? editCategoryId;
        selectedSecondaryCategoryId = null;

        final rawSec = matchedCat['secondaryCategories'] ?? matchedCat['secondary_categories'] ?? [];
        secondaryCategories = List<Map<String, dynamic>>.from(rawSec);

        if (secondaryCategories.isEmpty || !hasSecondaryCategories) {
          final brandList = matchedCat['brands'] ?? [];
          final Map<int, Map<String, dynamic>> uniqueBrands = {};
          for (var brand in brandList) {
            if (brand != null && brand['id'] != null) {
              final bId = int.tryParse(brand['id'].toString()) ?? 0;
              if (bId != 0) {
                uniqueBrands[bId] = {
                  "id": bId,
                  "name": brand['name'] ?? "No Name",
                };
              }
            }
          }
          brands = uniqueBrands.values.toList();
        }
      } else {
        int? parentPrimaryId;
        Map<String, dynamic>? matchedSec;
        List<Map<String, dynamic>> parentSecList = [];

        for (var cat in categoryItems) {
          final rawSec = cat['secondaryCategories'] ?? cat['secondary_categories'] ?? [];
          if (rawSec is List) {
            for (var sec in rawSec) {
              if (sec['id']?.toString() == editCategoryId.toString()) {
                parentPrimaryId = int.tryParse(cat['id']?.toString() ?? "");
                matchedSec = Map<String, dynamic>.from(sec);
                parentSecList = List<Map<String, dynamic>>.from(rawSec);
                break;
              }
            }
          }
          if (parentPrimaryId != null) break;
        }

        if (parentPrimaryId != null && matchedSec != null) {
          selectedCategoryId = parentPrimaryId;
          selectedSecondaryCategoryId = editCategoryId;
          secondaryCategories = parentSecList;

          final brandList = matchedSec['brands'] ?? [];
          final Map<int, Map<String, dynamic>> uniqueBrands = {};
          for (var brand in brandList) {
            if (brand != null && brand['id'] != null) {
              final bId = int.tryParse(brand['id'].toString()) ?? 0;
              if (bId != 0) {
                uniqueBrands[bId] = {
                  "id": bId,
                  "name": brand['name'] ?? "No Name",
                };
              }
            }
          }
          brands = uniqueBrands.values.toList();
        } else {
          selectedCategoryId = editCategoryId;
        }
      }
    } else {
      // Category not in list, add it to categoryItems so it can be selected and displayed
      final catName = widget.editItem?['category_name'] ??
          widget.editItem?['raw']?['primary_category_name'] ??
          "Category #$editCategoryId";
      final catObj = {
        "id": editCategoryId!,
        "name": catName.toString(),
        "code": "",
        "type": "primary",
        "is_primary": true,
        "parent_id": null,
        "parent_name": "",
        "image_url": "",
        "brands": [],
      };
      categoryItems.insert(0, catObj);
      selectedCategoryId = editCategoryId;
    }

    // If brands are still empty, fetch them for this category from API
    if (brands.isEmpty) {
      try {
        final targetCatId = selectedSecondaryCategoryId ?? selectedCategoryId ?? editCategoryId!;
        final brandRes = await ApiService.getBrandsByCategory(categoryId: targetCatId);
        final rawBrands = brandRes['data'];
        if (rawBrands is List && rawBrands.isNotEmpty) {
          final List<Map<String, dynamic>> parsedBrands = [];
          for (var b in rawBrands) {
            if (b != null && b['id'] != null) {
              final bId = int.tryParse(b['id'].toString()) ?? 0;
              if (bId != 0) {
                parsedBrands.add({
                  "id": bId,
                  "name": b['name']?.toString() ?? "No Name",
                  "code": b['code']?.toString() ?? "",
                  "image": b['image']?.toString() ?? "",
                });
              }
            }
          }
          if (parsedBrands.isNotEmpty) {
            brands = parsedBrands;
          }
        }
      } catch (e) {
        debugPrint("Error fetching brands in edit mode: $e");
      }
    }

    if (editBrandId != null) {
      selectedBrandId = editBrandId;

      // Ensure the brand exists in brands list so dropdown selects it
      if (!brands.any((b) => b['id'] == editBrandId)) {
        final bName = widget.editItem?['brand_name'] ??
            widget.editItem?['raw']?['brand_name'] ??
            "Brand #$editBrandId";
        brands.insert(0, {
          "id": editBrandId!,
          "name": bName.toString(),
          "code": "",
          "image": "",
        });
      }

      await loadProducts(selectedSecondaryCategoryId ?? selectedCategoryId!, editBrandId!);
      if (mounted) {
        setState(() {
          selectedProductId = int.tryParse(widget.editItem?['product_id']?.toString() ?? "");
          selectedProductName = widget.editItem?['name']?.toString();
          selectedProductMrp = widget.editItem?['mrp']?.toString();
          selectedProductCode = widget.editItem?['code']?.toString();

          if (selectedProductId != null && selectedProductName != null) {
            if (!products.any((p) => p['id'] == selectedProductId)) {
              products.insert(0, {
                "id": selectedProductId!,
                "product_name": selectedProductName!,
                "code": selectedProductCode ?? "",
                "mrp": selectedProductMrp ?? "0.00",
              });
            }
          }
        });
      }
    }
  }

  Future<void> onCategorySelected(int categoryId) async {
    final matchedItem = categoryItems.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => {},
    );

    setState(() {
      selectedCategoryId = categoryId;
      selectedSecondaryCategoryId = null;
      secondaryCategories = [];
      selectedBrandId = null;
      brands = [];
      products = [];
      selectedProductId = null;
      selectedProductName = null;
      selectedProductMrp = null;
      selectedProductCode = null;
    });

    // Check store setup brands first (exact brands assigned to this store category)
    final rawBrandsFallback = matchedItem['brands'];
    if (rawBrandsFallback is List && rawBrandsFallback.isNotEmpty) {
      final List<Map<String, dynamic>> uniqueBrands = [];
      for (var b in rawBrandsFallback) {
        if (b != null && b['id'] != null) {
          final bId = int.tryParse(b['id'].toString()) ?? 0;
          uniqueBrands.add({
            "id": bId,
            "name": b['name']?.toString() ?? "No Name",
            "code": b['code']?.toString() ?? "",
            "image": b['image']?.toString() ?? "",
          });
        }
      }
      if (uniqueBrands.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          brands = uniqueBrands;
        });
        return;
      }
    }

    // Fetch brands from API for this category
    try {
      final brandRes = await ApiService.getBrandsByCategory(categoryId: categoryId);
      final rawBrands = brandRes['data'];
      List<Map<String, dynamic>> parsedBrands = [];

      if (rawBrands is List && rawBrands.isNotEmpty) {
        for (var b in rawBrands) {
          if (b != null && b['id'] != null) {
            parsedBrands.add({
              "id": int.tryParse(b['id'].toString()) ?? 0,
              "name": b['name']?.toString() ?? "No Name",
              "code": b['code']?.toString() ?? "",
              "image": b['image']?.toString() ?? "",
            });
          }
        }
      }

      if (parsedBrands.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          brands = parsedBrands;
        });
        return;
      }
    } catch (e) {
      debugPrint("Error fetching brands by category: $e");
    }
  }

  Future<void> onSecondaryCategorySelected(int? secId) async {
    if (secId == null) {
      setState(() {
        selectedSecondaryCategoryId = null;
        selectedBrandId = null;
        products = [];
        selectedProductId = null;
        selectedProductName = null;
        selectedProductMrp = null;
        selectedProductCode = null;
      });

      // Restore parent category's brands
      if (selectedCategoryId != null) {
        final matchedItem = categoryItems.firstWhere(
          (c) => c['id'] == selectedCategoryId,
          orElse: () => {},
        );
        final rawBrands = matchedItem['brands'];
        if (rawBrands is List && rawBrands.isNotEmpty) {
          final List<Map<String, dynamic>> parentBrands = [];
          for (var b in rawBrands) {
            if (b != null && b['id'] != null) {
              parentBrands.add({
                "id": int.tryParse(b['id'].toString()) ?? 0,
                "name": b['name']?.toString() ?? "No Name",
                "code": b['code']?.toString() ?? "",
                "image": b['image']?.toString() ?? "",
              });
            }
          }
          if (parentBrands.isNotEmpty) {
            setState(() {
              brands = parentBrands;
            });
          }
        }
      }
      return;
    }

    final matchedSec = secondaryCategories.firstWhere(
      (s) => s['id'] == secId,
      orElse: () => {},
    );

    setState(() {
      selectedSecondaryCategoryId = secId;
      selectedBrandId = null;
      products = [];
      selectedProductId = null;
      selectedProductName = null;
      selectedProductMrp = null;
      selectedProductCode = null;
    });

    // Check store setup brands for this subcategory
    final secBrands = matchedSec['brands'];
    if (secBrands is List && secBrands.isNotEmpty) {
      final List<Map<String, dynamic>> parsedBrands = [];
      for (var b in secBrands) {
        if (b != null && b['id'] != null) {
          parsedBrands.add({
            "id": int.tryParse(b['id'].toString()) ?? 0,
            "name": b['name']?.toString() ?? "No Name",
            "code": b['code']?.toString() ?? "",
            "image": b['image']?.toString() ?? "",
          });
        }
      }
      if (parsedBrands.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          brands = parsedBrands;
        });
        return;
      }
    }

    // Fallback: fetch brands for this subcategory from API
    try {
      final brandRes = await ApiService.getBrandsByCategory(categoryId: secId);
      final rawBrands = brandRes['data'];
      List<Map<String, dynamic>> parsedBrands = [];

      if (rawBrands is List && rawBrands.isNotEmpty) {
        for (var b in rawBrands) {
          if (b != null && b['id'] != null) {
            parsedBrands.add({
              "id": int.tryParse(b['id'].toString()) ?? 0,
              "name": b['name']?.toString() ?? "No Name",
              "code": b['code']?.toString() ?? "",
              "image": b['image']?.toString() ?? "",
            });
          }
        }
      }

      if (parsedBrands.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          brands = parsedBrands;
        });
      }
    } catch (e) {
      debugPrint("Error fetching brands for subcategory: $e");
    }
  }

  void onBrandSelected(int? brandId) {
    setState(() {
      selectedBrandId = brandId;
      selectedProductId = null;
      selectedProductName = null;
      selectedProductMrp = null;
      selectedProductCode = null;
      products = [];
    });
    if (brandId != null && selectedCategoryId != null) {
      loadProducts(selectedSecondaryCategoryId ?? selectedCategoryId!, brandId);
    }
  }

  Future<void> _loadCategoriesFallback() async {
    try {
      final catRes = await ApiService.getCategoryList();
      final catData = catRes['data'] ?? [];
      final Map<int, Map<String, dynamic>> uniqueCategories = {};
      rawCategoryBrandData.clear();

      if (catData is List) {
        for (var primary in catData) {
          if (primary['id'] != null) {
            uniqueCategories[primary['id']] = {
              "id": primary['id'],
              "name": primary['name'] ?? primary['category_name'] ?? "No Name",
              "type": primary['category_type'] ?? "primary",
            };

            rawCategoryBrandData.add({
              "category_id": primary['id'],
              "category_name": primary['name'] ?? primary['category_name'] ?? "No Name",
              "type": primary['category_type'] ?? "primary",
              "brands": primary['brands'] ?? [],
              "secondary_categories": primary['secondary_categories'] ?? [],
            });
          }
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
      });
    } catch (e) {
      debugPrint("Error _loadCategoriesFallback: $e");
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

      if (sortedCategoryItems.isEmpty) {
        await _loadCategoriesFallback();
        return;
      }

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
      await _loadCategoriesFallback();
    }
  }

  List _extractProductList(dynamic res) {
    if (res == null) return [];
    if (res is List) return res;
    if (res is Map) {
      if (res['products'] is List) return res['products'];
      if (res['data'] is List) return res['data'];
      if (res['data'] is Map) {
        if (res['data']['products'] is List) return res['data']['products'];
        if (res['data']['data'] is List) return res['data']['data'];
        if (res['data']['items'] is List) return res['data']['items'];
      }
      if (res['items'] is List) return res['items'];
    }
    return [];
  }

  Future<void> loadProducts(int categoryId, int brandId) async {
    List<Map<String, dynamic>> extracted = [];

    void parseProductsList(List rawList) {
      for (var p in rawList) {
        if (p is Map && (p['id'] != null || p['product_id'] != null)) {
          final pId = int.tryParse((p['id'] ?? p['product_id']).toString()) ?? 0;
          if (pId == 0) continue;
          final pName = (p['product_name'] ?? p['name'] ?? "Product #$pId").toString();
          final pCode = (p['code'] ?? p['product_code'] ?? "").toString();
          final pMrp = (p['mrp'] ?? p['price'] ?? "0.00").toString();

          extracted.add({
            "id": pId,
            "product_name": pName,
            "code": pCode,
            "mrp": pMrp,
          });
        }
      }
    }

    try {
      // 1. Direct Web API: GET https://billing.srivagroups.in/api/products/$brandId
      try {
        final resBrandId = await ApiService.getProductsByBrandId(brandId);
        parseProductsList(_extractProductList(resBrandId));
      } catch (e) {
        debugPrint("getProductsByBrandId notice: $e");
      }

      // 2. Query getProductsByBrandAndCategory from srivagroups.in (with categoryId and brandId)
      if (extracted.isEmpty) {
        try {
          final res = await ApiService.getProductsByBrandAndCategory(
            brandId: brandId,
            categoryId: categoryId,
          );
          parseProductsList(_extractProductList(res));
        } catch (e) {
          debugPrint("getProductsByBrandAndCategory notice: $e");
        }
      }

      // 3. Fallback: try getBrandProducts (existing billing API)
      if (extracted.isEmpty) {
        try {
          final resFallback = await ApiService.getBrandProducts(
            categoryId: categoryId,
            brandId: brandId,
          );
          parseProductsList(_extractProductList(resFallback));
        } catch (e) {
          debugPrint("getBrandProducts notice: $e");
        }
      }
    } catch (e) {
      debugPrint("loadProducts error: $e");
    }

    final map = <int, Map<String, dynamic>>{};
    for (var p in extracted) {
      final pId = int.tryParse(p['id']?.toString() ?? "") ?? 0;
      if (pId != 0) {
        map[pId] = p;
      }
    }
    final finalVisibleProducts = map.values.toList();

    if (!mounted) return;
    setState(() {
      products = finalVisibleProducts;
      if (editAllocationId != null && selectedProductId != null && selectedProductName != null) {
        if (!finalVisibleProducts.any((p) => p['id'] == selectedProductId)) {
          finalVisibleProducts.insert(0, {
            "id": selectedProductId!,
            "product_name": selectedProductName!,
            "code": selectedProductCode ?? "",
            "mrp": selectedProductMrp ?? "0.00",
          });
        }
      } else if (selectedProductId != null && !finalVisibleProducts.any((p) => p['id'] == selectedProductId)) {
        selectedProductId = null;
        selectedProductName = null;
        selectedProductMrp = null;
        selectedProductCode = null;
      }
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
        final res = await ApiService.getCategoryBrands(categoryGroupId: group.id);
        final groupData = res['data'] ?? [];
        
        bool found = false;
        for (var mapping in mappings) {
          final targetCategoryId = int.tryParse(mapping["category_id"]?.toString() ?? "");
          if (targetCategoryId == null) continue;

          for (var g in groupData) {
            for (var primary in (g['primary_categories'] ?? [])) {
              if (primary['id']?.toString() == targetCategoryId.toString()) {
                found = true;
                break;
              }
              for (var secondary in (primary['secondary_categories'] ?? [])) {
                if (secondary['id']?.toString() == targetCategoryId.toString()) {
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

      final targetCategoryId = int.tryParse(selectedMapping["category_id"]?.toString() ?? "");
      final targetBrandId = int.tryParse(selectedMapping["brand_id"]?.toString() ?? "");
      final targetProductId = int.tryParse(data["id"]?.toString() ?? "");

      if (targetCategoryId == null || targetBrandId == null || targetProductId == null) {
        throw Exception("Invalid mapping configuration in product details");
      }

      if (!mounted) return;

      // 3. Set the selections
      setState(() {
        selectedCategoryGroupId = matchedGroupId;
      });
      
      // Load categories under this group
      await loadCategoryBrandData(matchedGroupId);
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
      await loadProducts(selectedCategoryId!, selectedBrandId!);
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
      selectedCategoryId = null;
      selectedSecondaryCategoryId = null;
      selectedBrandId = null;
      selectedProductId = null;
      selectedProductName = null;
      brands = [];
      products = [];
      minQtyController.clear();
      maxQtyController.clear();
      barcodeController.clear();
      _autofilledText = null;
    });
  }

  Future<void> saveOrUpdate() async {
    if (!canCreateProduct && !isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Permission Denied: You do not have permission to add/modify products."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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
        categoryGroupId: selectedCategoryGroupId ?? editCategoryGroupId ?? 0,
        categoryId: selectedSecondaryCategoryId ?? selectedCategoryId ?? editCategoryId ?? 0,
        brandId: selectedBrandId ?? editBrandId ?? 0,
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
      final bool requiresSubCat = hasSecondaryCategories && secondaryCategories.isNotEmpty;
      if (selectedCategoryId == null ||
          (requiresSubCat && selectedSecondaryCategoryId == null) ||
          selectedBrandId == null ||
          selectedProductId == null ||
          selectedProductName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fill all fields")),
        );
        return;
      }

      setState(() => isLoading = true);
      final groupId = selectedCategoryGroupId ?? (categoryGroups.isNotEmpty ? categoryGroups.first.id! : 1);
      final success = await ApiService.saveProductAllocation(
        categoryGroupId: groupId,
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

        // Navigate to Product List page (ProductAllocationPage)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProductAllocationPage()),
        );
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
