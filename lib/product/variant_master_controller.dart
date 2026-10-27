part of 'variant_master.dart';

class VariantMasterController extends GetxController {
  var selectedTabIndex = 0.obs;
  var variantTypes = <dynamic>[].obs;
  var allocations = <dynamic>[].obs;
  var products = <dynamic>[].obs;

  var isLoadingVariants = true.obs;
  var isLoadingAllocations = false.obs;
  var isLoadingProducts = true.obs;
  var isSaving = false.obs;

  var selectedFilterProductId = RxnString();
  var showBanner = false.obs;
  var bannerText = ''.obs;

  var selectedProductIdForVariants = RxnString();
  var selectedVariantConfigs = <String, Map<String, dynamic>>{}.obs;
  var activeConfigVariant = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchVariants();
    fetchProducts();
    fetchAllocations();
  }

  void toast(String msg) {
    bannerText.value = msg;
    showBanner.value = true;
    Future.delayed(const Duration(seconds: 3), () {
      showBanner.value = false;
    });
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('billing_auth_token') ??
        prefs.getString('auth_token') ??
        prefs.getString('token') ??
        '';

    String cleanToken = token.trim();
    if (cleanToken.startsWith('Bearer ')) {
      cleanToken = cleanToken.substring(7).trim();
    }

    final bId = prefs.getString('selected_business_id') ??
        prefs.get('business_id')?.toString() ??
        '52';
    final sId = prefs.getString('selected_store_id') ??
        prefs.get('store_id')?.toString() ??
        '38';
    final pId = prefs.getString('selected_platform_id') ??
        prefs.get('platform_id')?.toString() ??
        '1';

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-App-ID': 'Product94674',
    };

    if (cleanToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $cleanToken';
    }
    if (bId.isNotEmpty) {
      headers['x-business-id'] = bId;
    }
    if (sId.isNotEmpty) {
      headers['x-store-id'] = sId;
    }
    if (pId.isNotEmpty) {
      headers['x-platform-id'] = pId;
    }

    return headers;
  }

  Future<bool> _trySilentLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString("cached_email") ?? "";
      final cachedPassword = prefs.getString("cached_password") ?? "";
      if (cachedEmail.isNotEmpty && cachedPassword.isNotEmpty) {
        final loginRes = await http.post(
          Uri.parse("https://billing.srivagroups.in/api/auth/login"),
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-App-ID": "Product94674",
          },
          body: jsonEncode({"email": cachedEmail, "password": cachedPassword}),
        ).timeout(const Duration(seconds: 10));

        if (loginRes.statusCode == 200) {
          final lDecoded = jsonDecode(loginRes.body);
          final newToken = (lDecoded['token'] ?? lDecoded['data']?['token'])?.toString();
          if (newToken != null && newToken.isNotEmpty) {
            final clean = newToken.startsWith("Bearer ") ? newToken.substring(7).trim() : newToken.trim();
            await prefs.setString("billing_auth_token", clean);
            await prefs.setString("auth_token", clean);
            await prefs.setString("token", clean);
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint("Silent login error in VariantMasterController: $e");
    }
    return false;
  }

  Future<Map<String, dynamic>> _getBusinessParams() async {
    final prefs = await SharedPreferences.getInstance();
    final bId = int.tryParse(prefs.getString('selected_business_id') ??
            prefs.get('business_id')?.toString() ??
            '52') ??
        52;
    final pId = int.tryParse(prefs.getString('selected_platform_id') ??
            prefs.get('platform_id')?.toString() ??
            '1') ??
        1;
    final sId = int.tryParse(prefs.getString('selected_store_id') ??
            prefs.get('store_id')?.toString() ??
            '38') ??
        38;

    return {
      'business_id': bId,
      'platform_id': pId,
      'store_id': sId,
    };
  }

  /// 1. GET https://billing.srivagroups.in/api/variant-master
  Future<void> fetchVariants() async {
    isLoadingVariants.value = true;
    try {
      final bParams = await _getBusinessParams();
      final bId = bParams['business_id'] ?? 52;
      final sId = bParams['store_id'] ?? 38;
      final pId = bParams['platform_id'] ?? 1;

      final url = 'https://billing.srivagroups.in/api/variant-master?business_id=$bId&store_id=$sId&platform_id=$pId';
      var res = await http.get(Uri.parse(url), headers: await _headers());
      debugPrint('fetchVariants [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 401 || (res.statusCode == 400 && res.body.contains("Session expired"))) {
        if (await _trySilentLogin()) {
          res = await http.get(Uri.parse(url), headers: await _headers());
          debugPrint('fetchVariants retry [${res.statusCode}]: ${res.body}');
        }
      }

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          if (decoded['data'] is List) {
            list = decoded['data'];
          } else if (decoded['variants'] is List) {
            list = decoded['variants'];
          }
        }

        // Show all active (non-deleted) variants from backend exactly as web does
        final activeList = list.where((item) {
          if (item is Map) {
            final isDel = item['is_deleted'];
            if (isDel == 1 || isDel == true || isDel == '1') return false;
            return true;
          }
          return true;
        }).toList();

        variantTypes.assignAll(activeList);
        if (selectedProductIdForVariants.value != null) {
          updateConfigMapping(selectedProductIdForVariants.value!);
        }
      } else {
        toast('Failed to load variants (${res.statusCode})');
      }
    } catch (e) {
      debugPrint('fetchVariants error: $e');
      toast('Error loading variants: $e');
    } finally {
      isLoadingVariants.value = false;
    }
  }

  /// 2. POST https://billing.srivagroups.in/api/variant-master
  Future<bool> createVariant(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;

    isSaving.value = true;
    try {
      final bParams = await _getBusinessParams();
      final bId = bParams['business_id'] ?? 52;
      final pId = bParams['platform_id'] ?? 1;
      final sId = bParams['store_id'] ?? 38;

      final url = 'https://billing.srivagroups.in/api/variant-master?business_id=$bId&store_id=$sId&platform_id=$pId';
      final body = {
        'name': cleanName,
        'variant_name': cleanName,
        'business_id': bId,
        'platform_id': pId,
        'store_id': sId,
        'businessId': bId,
        'platformId': pId,
        'storeId': sId,
      };

      debugPrint('createVariant request: ${jsonEncode(body)}');
      var res = await http.post(
        Uri.parse(url),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      debugPrint('createVariant response [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 401 || (res.statusCode == 400 && res.body.contains("Session expired"))) {
        if (await _trySilentLogin()) {
          res = await http.post(
            Uri.parse(url),
            headers: await _headers(),
            body: jsonEncode(body),
          );
          debugPrint('createVariant retry response [${res.statusCode}]: ${res.body}');
        }
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        toast('Variant "$cleanName" created successfully!');
        await fetchVariants();
        return true;
      } else {
        final decoded = jsonDecode(res.body);
        final msg = decoded is Map
            ? (decoded['message'] ?? 'Failed to create variant')
            : 'Failed to create variant (${res.statusCode})';
        toast(msg.toString());
        return false;
      }
    } catch (e) {
      debugPrint('createVariant error: $e');
      toast('Error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// 3. PUT https://billing.srivagroups.in/api/variant-master/{id}
  Future<bool> updateVariant(dynamic id, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;

    isSaving.value = true;
    try {
      final bParams = await _getBusinessParams();
      final bId = bParams['business_id'] ?? 52;
      final pId = bParams['platform_id'] ?? 1;
      final sId = bParams['store_id'] ?? 38;

      final url = 'https://billing.srivagroups.in/api/variant-master/$id?business_id=$bId&store_id=$sId&platform_id=$pId';
      final body = {
        'name': cleanName,
        'variant_name': cleanName,
        'business_id': bId,
        'platform_id': pId,
        'store_id': sId,
        'businessId': bId,
        'platformId': pId,
        'storeId': sId,
      };

      debugPrint('updateVariant request: ${jsonEncode(body)}');
      var res = await http.put(
        Uri.parse(url),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      debugPrint('updateVariant response [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 405 || res.statusCode == 404) {
        // Fallback to PATCH if PUT is not allowed
        res = await http.patch(
          Uri.parse(url),
          headers: await _headers(),
          body: jsonEncode(body),
        );
        debugPrint('updateVariant PATCH fallback response [${res.statusCode}]: ${res.body}');
      }

      if (res.statusCode == 401 || (res.statusCode == 400 && res.body.contains("Session expired"))) {
        if (await _trySilentLogin()) {
          res = await http.put(
            Uri.parse(url),
            headers: await _headers(),
            body: jsonEncode(body),
          );
          debugPrint('updateVariant retry response [${res.statusCode}]: ${res.body}');
        }
      }

      if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
        toast('Variant "$cleanName" updated successfully!');
        await fetchVariants();
        return true;
      } else {
        final decoded = jsonDecode(res.body);
        final msg = decoded is Map
            ? (decoded['message'] ?? 'Failed to update variant')
            : 'Failed to update variant (${res.statusCode})';
        toast(msg.toString());
        return false;
      }
    } catch (e) {
      debugPrint('updateVariant error: $e');
      toast('Error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// 4. DELETE https://billing.srivagroups.in/api/variant-master/{id}
  Future<bool> deleteVariant(dynamic id) async {
    isSaving.value = true;
    try {
      final bParams = await _getBusinessParams();
      final bId = bParams['business_id'] ?? 52;
      final sId = bParams['store_id'] ?? 38;
      final pId = bParams['platform_id'] ?? 1;

      final url = 'https://billing.srivagroups.in/api/variant-master/$id?business_id=$bId&store_id=$sId&platform_id=$pId';
      debugPrint('deleteVariant request: $url');
      var res = await http.delete(
        Uri.parse(url),
        headers: await _headers(),
      );
      debugPrint('deleteVariant response [${res.statusCode}]: ${res.body}');

      if (res.statusCode == 401 || (res.statusCode == 400 && res.body.contains("Session expired"))) {
        if (await _trySilentLogin()) {
          res = await http.delete(
            Uri.parse(url),
            headers: await _headers(),
          );
          debugPrint('deleteVariant retry response [${res.statusCode}]: ${res.body}');
        }
      }

      if (res.statusCode == 200 || res.statusCode == 204) {
        toast('Variant deleted successfully!');
        await fetchVariants();
        return true;
      } else {
        final decoded = jsonDecode(res.body);
        final msg = decoded is Map
            ? (decoded['message'] ?? 'Failed to delete variant')
            : 'Failed to delete variant (${res.statusCode})';
        toast(msg.toString());
        return false;
      }
    } catch (e) {
      debugPrint('deleteVariant error: $e');
      toast('Error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// 5. GET https://billing.srivagroups.in/api/productAllocation
  Future<void> fetchProducts() async {
    isLoadingProducts.value = true;
    try {
      const url = 'https://billing.srivagroups.in/api/productAllocation';
      final res = await http.get(Uri.parse(url), headers: await _headers());
      debugPrint('fetchProducts [${res.statusCode}]');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }

        List parsedProducts = [];
        for (var item in list) {
          if (item is Map) {
            final pId = (item['product_id'] ?? item['id'])?.toString() ?? '';
            final pName = (item['product_name'] ?? item['name'])?.toString() ?? '';
            final allocId = (item['allocation_id'] ?? pId).toString();
            if (pId.isNotEmpty && pName.isNotEmpty) {
              parsedProducts.add({
                'id': pId,
                'name': pName,
                'allocation_id': allocId,
                'mrp': (item['mrp'] ?? '').toString(),
                'brand_name': (item['brand_name'] ?? '').toString(),
                'base_image': (item['base_image'] ?? '').toString(),
                'category_name': (item['secondary_category_name'] ??
                        item['primary_category_name'] ??
                        '')
                    .toString(),
                'min_qty': (item['min_qty'] ?? '0').toString(),
                'max_qty': (item['max_qty'] ?? '999').toString(),
              });
            }
          }
        }
        products.assignAll(parsedProducts);

        if (selectedProductIdForVariants.value == null && parsedProducts.isNotEmpty) {
          selectedProductIdForVariants.value = parsedProducts.first['id'];
          updateConfigMapping(parsedProducts.first['id']);
        }
      }
    } catch (e) {
      debugPrint('fetchProducts error: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// 6. GET https://billing.srivagroups.in/api/variant-master/product-variants
  Future<void> fetchAllocations() async {
    isLoadingAllocations.value = true;
    try {
      const url = 'https://billing.srivagroups.in/api/variant-master/product-variants';
      final res = await http.get(Uri.parse(url), headers: await _headers());
      debugPrint('fetchAllocations [${res.statusCode}]');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data']
            : (decoded is List ? decoded : []);
        allocations.assignAll(list);
        if (selectedProductIdForVariants.value != null) {
          updateConfigMapping(selectedProductIdForVariants.value!);
        }
      }
    } catch (e) {
      debugPrint('fetchAllocations error: $e');
    } finally {
      isLoadingAllocations.value = false;
    }
  }

  Future<void> createAllocation(Map<String, dynamic> data) async {
    try {
      const url = 'https://billing.srivagroups.in/api/variant-master/product-variants';
      final bParams = await _getBusinessParams();
      final body = {
        ...data,
        ...bParams,
      };

      final res = await http.post(
        Uri.parse(url),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        toast('Variant allocated successfully!');
      } else {
        toast('Failed to save allocation (${res.statusCode})');
      }
    } catch (e) {
      toast('Error: $e');
    }
  }

  Future<void> updateAllocation(int id, Map<String, dynamic> data) async {
    try {
      final url = 'https://billing.srivagroups.in/api/variant-master/product-variants/$id';
      final bParams = await _getBusinessParams();
      final body = {
        ...data,
        ...bParams,
      };

      final res = await http.put(
        Uri.parse(url),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        toast('Allocation updated successfully!');
      } else {
        toast('Failed to update allocation (${res.statusCode})');
      }
    } catch (e) {
      toast('Error: $e');
    }
  }

  Future<void> deleteAllocation(int id) async {
    try {
      final url = 'https://billing.srivagroups.in/api/variant-master/product-variants/$id';
      final res = await http.delete(Uri.parse(url), headers: await _headers());
      if (res.statusCode == 200) {
        toast('Allocation deleted successfully!');
      } else {
        toast('Failed to delete allocation (${res.statusCode})');
      }
    } catch (e) {
      toast('Error: $e');
    }
  }

  void updateConfigMapping(String productId) {
    selectedVariantConfigs.clear();
    final productAllocations =
        allocations.where((a) => a['product_id']?.toString() == productId).toList();

    for (var v in variantTypes) {
      final vName = (v['name'] ?? v['variant_name'] ?? '').toString();
      final existing = productAllocations.firstWhereOrNull(
          (a) => (a['variant'] ?? a['variant_name'] ?? '').toString() == vName);

      if (existing != null) {
        bool wEnabled = false;
        String wDur = '1';
        String wUnit = 'Months';
        final wDuration = (existing['warranty_duration'] ?? '').toString();
        final wType = (existing['warranty_duration_type'] ?? 'months').toString();
        if (wDuration.isNotEmpty && wDuration != 'null') {
          wEnabled = true;
          wDur = wDuration;
          wUnit = wType.capitalizeFirst ?? 'Months';
        }

        bool gEnabled = false;
        String gDur = '1';
        String gUnit = 'Months';
        final gDuration = (existing['guarantee_duration'] ?? '').toString();
        final gType = (existing['guarantee_duration_type'] ?? 'months').toString();
        if (gDuration.isNotEmpty && gDuration != 'null') {
          gEnabled = true;
          gDur = gDuration;
          gUnit = gType.capitalizeFirst ?? 'Months';
        }

        selectedVariantConfigs[vName] = {
          'checked': true,
          'minStock': (existing['min_qty'] ??
                  existing['min_stock'] ??
                  existing['minStock'] ??
                  '0')
              .toString(),
          'maxStock': (existing['max_qty'] ??
                  existing['max_stock'] ??
                  existing['maxStock'] ??
                  '999')
              .toString(),
          'warrantyEnabled': wEnabled,
          'warrantyDuration': wDur,
          'warrantyUnit': wUnit,
          'guaranteeEnabled': gEnabled,
          'guaranteeDuration': gDur,
          'guaranteeUnit': gUnit,
        };
      } else {
        selectedVariantConfigs[vName] = {
          'checked': false,
          'minStock': '0',
          'maxStock': '999',
          'warrantyEnabled': false,
          'warrantyDuration': '1',
          'warrantyUnit': 'Months',
          'guaranteeEnabled': false,
          'guaranteeDuration': '1',
          'guaranteeUnit': 'Months',
        };
      }
    }
  }

  Future<void> saveAllocations() async {
    final productId = selectedProductIdForVariants.value;
    if (productId == null) return;

    final matchProd = products.firstWhereOrNull((p) => p['id']?.toString() == productId);
    final pName = matchProd != null ? (matchProd['name']?.toString() ?? '') : '';

    final existingAllocations =
        allocations.where((a) => a['product_id']?.toString() == productId).toList();

    for (var v in variantTypes) {
      final vName = (v['name'] ?? v['variant_name'] ?? '').toString();
      final vId = v['id'] as int? ?? 0;

      final config = selectedVariantConfigs[vName];
      if (config == null) continue;

      final isChecked = config['checked'] == true;
      final existing = existingAllocations.firstWhereOrNull(
          (a) => (a['variant'] ?? a['variant_name'] ?? '').toString() == vName);

      if (isChecked) {
        final data = {
          'product_id': int.tryParse(productId) ?? 0,
          'productId': int.tryParse(productId) ?? 0,
          'product_name': pName,
          'productName': pName,
          'variant': vName,
          'variant_name': vName,
          'variantName': vName,
          'variant_id': vId,
          'variantId': vId,
          'min_qty': int.tryParse(config['minStock']?.toString() ?? '0') ?? 0,
          'min_stock': int.tryParse(config['minStock']?.toString() ?? '0') ?? 0,
          'minStock': int.tryParse(config['minStock']?.toString() ?? '0') ?? 0,
          'max_qty': int.tryParse(config['maxStock']?.toString() ?? '999') ?? 999,
          'max_stock': int.tryParse(config['maxStock']?.toString() ?? '999') ?? 999,
          'maxStock': int.tryParse(config['maxStock']?.toString() ?? '999') ?? 999,
          'warranty': config['warrantyEnabled'] == true
              ? '${config['warrantyDuration']} ${config['warrantyUnit']}'
              : '',
          'warranty_duration': config['warrantyEnabled'] == true
              ? (int.tryParse(config['warrantyDuration']?.toString() ?? '') ?? 0)
              : 0,
          'warranty_duration_type': config['warrantyEnabled'] == true
              ? config['warrantyUnit']?.toString().toLowerCase()
              : '',
          'guarantee': config['guaranteeEnabled'] == true
              ? '${config['guaranteeDuration']} ${config['guaranteeUnit']}'
              : '',
          'guarantee_duration': config['guaranteeEnabled'] == true
              ? (int.tryParse(config['guaranteeDuration']?.toString() ?? '') ?? 0)
              : 0,
          'guarantee_duration_type': config['guaranteeEnabled'] == true
              ? config['guaranteeUnit']?.toString().toLowerCase()
              : '',
        };

        if (existing != null) {
          final id = existing['id'] as int;
          await updateAllocation(id, data);
        } else {
          await createAllocation(data);
        }
      } else {
        if (existing != null) {
          final id = existing['id'] as int;
          await deleteAllocation(id);
        }
      }
    }

    await fetchAllocations();
    toast('Allocations saved successfully!');
  }
}
