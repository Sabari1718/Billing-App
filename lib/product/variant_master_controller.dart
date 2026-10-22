part of 'variant_master.dart';

class VariantMasterController extends GetxController {
  var selectedTabIndex = 0.obs;
  var variantTypes = <dynamic>[].obs;
  var allocations = <dynamic>[].obs;
  var products = <dynamic>[].obs;
  
  var isLoadingVariants = true.obs;
  var isLoadingAllocations = true.obs;
  var isLoadingProducts = true.obs;
  
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
    final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<String> _queryParams() async {
    final prefs = await SharedPreferences.getInstance();
    final bId = prefs.getString('selected_business_id') ?? prefs.get('business_id')?.toString() ?? '';
    final uId = prefs.getString('user_main_id') ?? '';
    final q = [if (bId.isNotEmpty) 'business_id=$bId', if (uId.isNotEmpty) 'user_main_id=$uId'];
    return q.isNotEmpty ? '?${q.join('&')}' : '';
  }

  Future<void> fetchVariants() async {
    isLoadingVariants.value = true;
    try {
      final q = await _queryParams();
      final url = 'https://billing.srivagroups.in/api/variant-master$q';
      final res = await http.get(Uri.parse(url), headers: await _headers());
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = (decoded is Map && decoded.containsKey('data')) 
            ? decoded['data'] : (decoded is List ? decoded : []);
        variantTypes.assignAll(list);
      }
    } catch (e) {
      debugPrint('fetchVariants error: $e');
    } finally {
      isLoadingVariants.value = false;
    }
  }

  Future<void> createVariant(String name) async {
    try {
      const url = 'https://billing.srivagroups.in/api/variant-master';
      final prefs = await SharedPreferences.getInstance();
      final bId = prefs.getString('selected_business_id') ?? prefs.get('business_id')?.toString() ?? '';
      final uId = prefs.getString('user_main_id') ?? '';
      
      final body = {
        'name': name,
        'variant_name': name,
        'variantName': name,
        if (bId.isNotEmpty) 'business_id': bId,
        if (uId.isNotEmpty) 'user_main_id': uId,
      };

      final res = await http.post(Uri.parse(url), headers: await _headers(), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        toast('Variant created successfully!');
        fetchVariants();
      } else {
        toast('Failed to create variant');
      }
    } catch (e) {
      toast('Error: $e');
    }
  }

  Future<void> updateVariant(int id, String name) async {
    try {
      final url = 'https://billing.srivagroups.in/api/variant-master/$id';
      final body = {
        'name': name,
        'variant_name': name,
        'variantName': name,
      };

      final res = await http.put(Uri.parse(url), headers: await _headers(), body: jsonEncode(body));
      if (res.statusCode == 200) {
        toast('Variant updated successfully!');
        fetchVariants();
      } else {
        toast('Failed to update variant');
      }
    } catch (e) {
      toast('Error: $e');
    }
  }

  Future<void> deleteVariant(int id) async {
    try {
      final url = 'https://billing.srivagroups.in/api/variant-master/$id';
      final res = await http.delete(Uri.parse(url), headers: await _headers());
      if (res.statusCode == 200) {
        toast('Variant deleted successfully!');
        fetchVariants();
      } else {
        toast('Failed to delete variant');
      }
    } catch (e) {
      toast('Error: $e');
    }
  }

  Future<void> fetchAllocations() async {
    isLoadingAllocations.value = true;
    try {
      final q = await _queryParams();
      final url = 'https://billing.srivagroups.in/api/variant-master/product-variants$q';
      final headers = await _headers();
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = (decoded is Map && decoded.containsKey('data')) 
            ? decoded['data'] : (decoded is List ? decoded : []);
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
      final prefs = await SharedPreferences.getInstance();
      final bId = prefs.getString('selected_business_id') ?? prefs.get('business_id')?.toString() ?? '';
      final uId = prefs.getString('user_main_id') ?? '';
      
      final body = {
        ...data,
        if (bId.isNotEmpty) 'business_id': int.tryParse(bId) ?? bId,
        if (uId.isNotEmpty) 'user_main_id': int.tryParse(uId) ?? uId,
      };

      final res = await http.post(Uri.parse(url), headers: await _headers(), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        toast('Variant allocated successfully!');
      } else {
        toast('Failed to save allocation');
      }
    } catch (e) {
      toast('Error: $e');
    }
  }

  Future<void> updateAllocation(int id, Map<String, dynamic> data) async {
    try {
      final url = 'https://billing.srivagroups.in/api/variant-master/product-variants/$id';
      final res = await http.put(Uri.parse(url), headers: await _headers(), body: jsonEncode(data));
      if (res.statusCode == 200) {
        toast('Allocation updated successfully!');
      } else {
        toast('Failed to update allocation');
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
        toast('Failed to delete allocation');
      }
    } catch (e) {
      toast('Error: $e');
    }
  }

  Future<void> fetchProducts() async {
    isLoadingProducts.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role')?.toLowerCase() ?? 'propagater';
      final userName = prefs.getString('user_name') ?? '';

      final q = await _queryParams();
      final url = 'https://billing.srivagroups.in/api/productAllocation$q';
      final res = await http.get(Uri.parse(url), headers: await _headers());

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = (decoded is Map && decoded.containsKey('data')) 
            ? decoded['data'] : (decoded is List ? decoded : []);
        
        List parsedProducts = [];
        for (var allocation in list) {
          if (allocation is Map) {
            final supplierName = allocation['supplier_name'] ?? allocation['supplier']?['name'] ?? "Unknown Supplier";
            
            if (role != "propagater" && role != "propagator" && role != "admin" && userName.isNotEmpty) {
              if (!supplierName.toString().toLowerCase().contains(userName.toLowerCase())) {
                continue;
              }
            }

            if (allocation['Products'] is List) {
              final productsList = allocation['Products'] as List;
              for (var prod in productsList) {
                if (prod is Map) {
                  parsedProducts.add({
                    'id': prod['id']?.toString() ?? '',
                    'name': prod['name']?.toString() ?? '',
                    'allocation_id': prod['allocation_id']?.toString() ?? '',
                  });
                }
              }
            }
            else if (allocation['Categories'] is Map) {
              final categoriesMap = allocation['Categories'] as Map;
              
              void processCategoryList(List? catList) {
                if (catList == null) return;
                for (var category in catList) {
                  if (category is Map && category['Brand'] is List) {
                    final brandList = category['Brand'] as List;
                    for (var brand in brandList) {
                      if (brand is Map && brand['Products'] is List) {
                        final productsList = brand['Products'] as List;
                        for (var prod in productsList) {
                          if (prod is Map) {
                            parsedProducts.add({
                              'id': prod['id']?.toString() ?? '',
                              'name': prod['name']?.toString() ?? '',
                              'allocation_id': prod['allocation_id']?.toString() ?? '',
                            });
                          }
                        }
                      }
                    }
                  }
                }
              }

              if (categoriesMap['primary'] is List) {
                processCategoryList(categoriesMap['primary'] as List);
              }
              if (categoriesMap['secondary'] is List) {
                processCategoryList(categoriesMap['secondary'] as List);
              }
            }
            else {
              final idVal = (allocation['id'] ?? allocation['product_id'] ?? allocation['productId'])?.toString() ?? '';
              final nameVal = (allocation['name'] ?? allocation['product_name'] ?? allocation['productName'] ?? '').toString();
              final allocId = (allocation['allocation_id'] ?? allocation['allocationId'] ?? idVal).toString();
              if (idVal.isNotEmpty && nameVal.isNotEmpty) {
                parsedProducts.add({
                  'id': idVal,
                  'name': nameVal,
                  'allocation_id': allocId,
                });
              }
            }
          }
        }
        products.assignAll(parsedProducts);
      }
    } catch (e) {
      debugPrint('fetchProducts error: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  void updateConfigMapping(String productId) {
    selectedVariantConfigs.clear();
    final productAllocations = allocations.where((a) => a['product_id']?.toString() == productId).toList();
    
    for (var v in variantTypes) {
      final vName = (v['name'] ?? v['variant_name'] ?? '').toString();
      final existing = productAllocations.firstWhereOrNull((a) => (a['variant'] ?? a['variant_name'] ?? '').toString() == vName);
      
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
          'minStock': (existing['min_qty'] ?? existing['min_stock'] ?? existing['minStock'] ?? '0').toString(),
          'maxStock': (existing['max_qty'] ?? existing['max_stock'] ?? existing['maxStock'] ?? '999').toString(),
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
    
    final existingAllocations = allocations.where((a) => a['product_id']?.toString() == productId).toList();
    
    for (var v in variantTypes) {
      final vName = (v['name'] ?? v['variant_name'] ?? '').toString();
      final vId = v['id'] as int? ?? 0;
      
      final config = selectedVariantConfigs[vName];
      if (config == null) continue;
      
      final isChecked = config['checked'] == true;
      final existing = existingAllocations.firstWhereOrNull((a) => (a['variant'] ?? a['variant_name'] ?? '').toString() == vName);
      
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
          'warranty': config['warrantyEnabled'] == true ? '${config['warrantyDuration']} ${config['warrantyUnit']}' : '',
          'warranty_duration': config['warrantyEnabled'] == true ? (int.tryParse(config['warrantyDuration']?.toString() ?? '') ?? 0) : 0,
          'warranty_duration_type': config['warrantyEnabled'] == true ? config['warrantyUnit']?.toString().toLowerCase() : '',
          'guarantee': config['guaranteeEnabled'] == true ? '${config['guaranteeDuration']} ${config['guaranteeUnit']}' : '',
          'guarantee_duration': config['guaranteeEnabled'] == true ? (int.tryParse(config['guaranteeDuration']?.toString() ?? '') ?? 0) : 0,
          'guarantee_duration_type': config['guaranteeEnabled'] == true ? config['guaranteeUnit']?.toString().toLowerCase() : '',
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
