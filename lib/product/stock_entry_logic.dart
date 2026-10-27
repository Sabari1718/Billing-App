part of 'stock entry.dart';

extension _StockEntryPageStateLogic on _StockEntryPageState {
  Future<void> fetchVariants() async {
    if (!mounted) return;
    setState(() => isLoadingVariants = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      currentBusinessId = prefs.getString('selected_business_id') ??
          prefs.get("business_id")?.toString() ??
          "52";
      currentStoreId = prefs.getString('selected_store_id') ??
          prefs.get("store_id")?.toString() ??
          "38";

      const url = "https://billing.srivagroups.in/api/variant-master";
      final res = await http.get(Uri.parse(url), headers: headers);
      debugPrint("stockEntry fetchVariants [${res.statusCode}]: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        dynamic data = decoded['data'];

        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['data'] is List) {
          list = data['data'];
        }

        // Strict store_id and business_id filter to match Web 100%
        final filteredList = list.where((item) {
          if (item is Map) {
            final isDel = item['is_deleted'];
            final notDeleted = isDel == null || isDel == 0 || isDel == false || isDel == '0';
            if (!notDeleted) return false;

            final itemStoreId = item['store_id'];
            final itemBizId = item['business_id'];
            if (currentStoreId != null && itemStoreId != null) {
              if (itemStoreId.toString() != currentStoreId.toString()) {
                return false;
              }
            }
            if (currentBusinessId != null && itemBizId != null) {
              if (itemBizId.toString() != currentBusinessId.toString()) {
                return false;
              }
            }
            return true;
          }
          return true;
        }).toList();

        if (mounted) {
          setState(() {
            variants = filteredList.isNotEmpty
                ? filteredList.map((e) => Map<String, dynamic>.from(e as Map)).toList()
                : [
                    {'id': 41, 'name': 'Imported'},
                    {'id': 42, 'name': 'Original'},
                    {'id': 43, 'name': 'Complimentary'},
                  ];
            variantTabData.clear();
            stockTabData.clear();
            for (var v in variants) {
              int id = int.tryParse(v['id'].toString()) ?? 0;
              variantTabData[id] = {
                'qty': '0',
                'buying': '0.00',
                'gst_rate': productGstRate,
                'profit': '0.00',
                'selling': '0.00',
              };
              stockTabData[id] = [];
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error("Error fetching variants", e);
      if (mounted && variants.isEmpty) {
        setState(() {
          variants = [
            {'id': 41, 'name': 'Imported'},
            {'id': 42, 'name': 'Original'},
            {'id': 43, 'name': 'Complimentary'},
          ];
        });
      }
    } finally {
      if (mounted) setState(() => isLoadingVariants = false);
    }
  }

  /// Category Tree Tax API: GET https://productmultitab.srivagroups.in/api/outsideapis/tax/category-tree?categoryIds=19
  Future<String> fetchCategoryTax(String? categoryId) async {
    final catId = (categoryId == null || categoryId.isEmpty) ? "19" : categoryId;
    try {
      final url = "https://productmultitab.srivagroups.in/api/outsideapis/tax/category-tree?categoryIds=$catId";
      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "X-App-ID": "Product94674",
        },
      );
      debugPrint("fetchCategoryTax [$catId] status [${res.statusCode}]: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['data'] is List && (decoded['data'] as List).isNotEmpty) {
          final first = decoded['data'][0];
          if (first is Map && first['tax_percentage'] != null) {
            final rate = "${first['tax_percentage']}% GST";
            if (mounted) setState(() => productGstRate = rate);
            return rate;
          }
        }
      }
    } catch (e) {
      debugPrint("fetchCategoryTax error: $e");
    }
    if (mounted) setState(() => productGstRate = "18% GST");
    return "18% GST";
  }

  /// Product Allocated Variants: GET https://billing.srivagroups.in/api/variant-master/product-variants
  Future<void> fetchProductAllocatedVariants(String productId) async {
    try {
      const url = "https://billing.srivagroups.in/api/variant-master/product-variants";
      final res = await http.get(Uri.parse(url), headers: headers);
      debugPrint("fetchProductAllocatedVariants [$productId] status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }

        final filtered = list.where((item) {
          if (item is Map) {
            return (item['product_id'] ?? item['productId'])?.toString() == productId;
          }
          return false;
        }).toList();

        if (filtered.isNotEmpty && mounted) {
          setState(() {
            variants = filtered.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              m['id'] = int.tryParse((m['variant_id'] ?? m['id'] ?? 1).toString()) ?? 1;
              m['name'] = (m['variant_name'] ?? m['variant'] ?? m['name'] ?? 'Variant').toString();
              return m;
            }).toList();

            for (var v in variants) {
              int id = int.tryParse(v['id'].toString()) ?? 0;
              variantTabData[id] ??= {
                'qty': '0',
                'buying': '0.00',
                'gst_rate': productGstRate,
                'profit': '0.00',
                'selling': '0.00',
              };
            }
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("fetchProductAllocatedVariants error: $e");
    }

    // Preserve existing real business variants from fetchVariants()
    if (variants.isNotEmpty) {
      if (mounted) {
        setState(() {
          for (var v in variants) {
            int id = int.tryParse(v['id'].toString()) ?? 0;
            variantTabData[id] ??= {
              'qty': '0',
              'buying': '0.00',
              'gst_rate': productGstRate,
              'profit': '0.00',
              'selling': '0.00',
            };
          }
        });
      }
      return;
    }

    // Otherwise load real variants
    await fetchVariants();
  }

  Future<void> fetchStockTypes() async {
    final prefs = await SharedPreferences.getInstance();
    currentBusinessId = prefs.getString('selected_business_id') ??
        prefs.get("business_id")?.toString() ??
        "52";
    currentStoreId = prefs.getString('selected_store_id') ??
        prefs.get("store_id")?.toString() ??
        "38";

    if (mounted) setState(() => isLoadingStockTypes = true);
    try {
      const url = "https://billing.srivagroups.in/api/stockTypes";
      final res = await http.get(Uri.parse(url), headers: headers);
      debugPrint("stockEntry fetchStockTypes [${res.statusCode}]: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        dynamic data = decoded['data'];

        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          if (data['data'] is List) {
            list = data['data'];
          } else if (data['stockTypes'] is List) {
            list = data['stockTypes'];
          } else {
            list = [data];
          }
        } else if (decoded['stockTypes'] is List) {
          list = decoded['stockTypes'];
        }

        final uniqueNames = <String>{};
        if (mounted) {
          setState(() {
            stockTypes = list.where((e) {
              if (e is! Map) return false;
              if (e['deleted_at'] != null) return false;
              final isDel = e['is_deleted'];
              if (isDel == 1 || isDel == true || isDel == '1') return false;

              final name = (e['name'] ?? '').toString().replaceAll('\r', '').replaceAll('\n', '').trim();
              if (name.isEmpty || uniqueNames.contains(name.toLowerCase())) return false;
              uniqueNames.add(name.toLowerCase());
              return true;
            }).map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              map['name'] = (map['name'] ?? '').toString().replaceAll('\r', '').replaceAll('\n', '').trim();
              return map;
            }).toList();
          });
        }
      }
    } catch (e) {
      AppLogger.error("Error fetching stock types", e);
    } finally {
      if (mounted) setState(() => isLoadingStockTypes = false);
    }
  }

  void onProductSelected(String? val) {
    if (val == null) return;
    final matched = products.where((p) => p['id']?.toString() == val).toList();
    if (matched.isNotEmpty) {
      currentMin = int.tryParse(matched.first['min']?.toString() ?? '1') ?? 1;
      currentMax = int.tryParse(matched.first['max']?.toString() ?? '100') ?? 100;
      final catId = matched.first['secondary_category_id'] ?? matched.first['primary_category_id'] ?? '19';
      fetchProductAllocatedVariants(val);
      fetchCategoryTax(catId.toString());
    } else {
      currentMin = null;
      currentMax = null;
    }
  }

  void _populateEditData() {
    if (widget.editStockItem == null) return;
    final item = widget.editStockItem!;
    final raw = item['raw'] is Map ? Map<String, dynamic>.from(item['raw'] as Map) : item;

    // 1. Mode: With Variant vs Without Variant vs Manufacture
    if (item['is_manufactured'] == true || raw['is_manufactured'] == true || raw['is_self_produced'] == 1) {
      isManufactureMode = true;
    }
    if (item['has_variant'] == false || raw['has_variant'] == false) {
      withVariantMode = false;
    } else {
      withVariantMode = true;
    }

    // 2. Match Supplier
    final suppId = (raw['supplier_id'] ?? raw['supplierId'] ?? item['supplier_id'])?.toString();
    final suppName = (item['supplier'] ?? raw['supplier_name'] ?? (raw['supplier'] is Map ? raw['supplier']['name'] : null))?.toString().trim();
    if (suppId != null && suppliers.any((s) => s['id']?.toString() == suppId)) {
      selectedSupplier = suppId;
    } else if (suppName != null && suppName.isNotEmpty) {
      for (var s in suppliers) {
        final sName = (s['supplier_name'] ?? s['name'] ?? s['company_name'] ?? '').toString().trim();
        if (sName.toLowerCase() == suppName.toLowerCase()) {
          selectedSupplier = s['id']?.toString();
          break;
        }
      }
      if (selectedSupplier == null) {
        final newId = suppId ?? '1';
        suppliers.insert(0, {
          'id': newId,
          'name': suppName,
          'supplier_name': suppName,
        });
        selectedSupplier = newId;
      }
    }

    // 3. Match Product
    final prodId = (raw['product_id'] ?? raw['productId'] ?? item['product_id'])?.toString();
    final prodName = (item['product'] ?? raw['product_name'] ?? (raw['product'] is Map ? raw['product']['name'] : null))?.toString().trim();
    final priceStr = (item['selling_price'] ?? raw['selling_price'] ?? '0.00').toString();

    if (prodId != null && products.any((p) => p['id']?.toString() == prodId)) {
      selectedProduct = prodId;
      onProductSelected(prodId);
    } else if (prodName != null && prodName.isNotEmpty) {
      for (var p in products) {
        final pName = (p['product_name'] ?? p['name'] ?? '').toString().trim();
        if (pName.toLowerCase() == prodName.toLowerCase()) {
          selectedProduct = p['id']?.toString();
          onProductSelected(p['id']?.toString());
          break;
        }
      }
      if (selectedProduct == null) {
        final newPId = prodId ?? '1';
        products.insert(0, {
          'id': newPId,
          'name': prodName,
          'product_name': prodName,
          'mrp': priceStr,
          'min': 0,
          'max': 999,
        });
        selectedProduct = newPId;
        onProductSelected(newPId);
      }
    }

    // 4. Quantities & Prices
    final qty = (item['quantity'] ?? raw['total_qty'] ?? raw['qty'] ?? '0').toString();
    qtyController.text = qty;
    sellingController.text = priceStr;
    sellingPriceNotifier.value = priceStr;

    // 5. Variants & Distribution
    final rawVariants = raw['variants'];
    if (rawVariants is List && rawVariants.isNotEmpty) {
      for (var rv in rawVariants) {
        if (rv is Map) {
          final vId = int.tryParse((rv['variant_id'] ?? rv['id'])?.toString() ?? '0') ?? 0;
          if (vId != 0) {
            variantTabData[vId] = {
              'qty': (rv['quantity'] ?? rv['qty'] ?? '0').toString(),
              'buying': (rv['buying_price'] ?? rv['purchase_price'] ?? '0.00').toString(),
              'gst_rate': (rv['gst_rate'] ?? productGstRate).toString(),
              'profit': (rv['profit'] ?? rv['profit_margin'] ?? '0.00').toString(),
              'selling': (rv['selling_price'] ?? rv['price'] ?? '0.00').toString(),
            };

            final rawStockTypes = rv['stock_types'] ?? rv['distributions'];
            if (rawStockTypes is List) {
              stockTabData[vId] = rawStockTypes.map((st) {
                if (st is Map) {
                  return {
                    'stock_type_id': st['stock_type_id'] ?? 2,
                    'qty': st['qty'] ?? 0,
                  };
                }
                return <String, dynamic>{};
              }).toList();
            }
          }
        }
      }
    }
  }

  Future<void> _initToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String safeToken = prefs.getString("billing_auth_token") ??
          prefs.getString("auth_token") ??
          prefs.getString("token") ??
          "";
      currentBusinessId = prefs.getString('selected_business_id') ??
          prefs.get("business_id")?.toString() ??
          "52";
      currentStoreId = prefs.getString('selected_store_id') ??
          prefs.get("store_id")?.toString() ??
          "38";

      if (mounted) {
        setState(() {
          token = safeToken;
        });
      }

      await loadData();
      await fetchVariants();
      await fetchStockTypes();

      if (widget.editStockItem != null && mounted) {
        setState(() {
          _populateEditData();
        });
      }
    } catch (e) {
      AppLogger.error("Token initialization error", e);
    }
  }

  Future<void> saveStock() async {
    int parseQty(dynamic value) {
      if (value == null) return 0;
      final s = value.toString().trim();
      if (s.isEmpty) return 0;
      return int.tryParse(s) ?? 0;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    if (!isManufactureMode && (selectedSupplier == null || selectedSupplier!.isEmpty)) {
      if (suppliers.isNotEmpty) {
        selectedSupplier = (suppliers.first['id'] ?? '1').toString();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select supplier first")),
        );
        return;
      }
    }
    if (selectedProduct == null || selectedProduct!.isEmpty) {
      if (products.isNotEmpty) {
        selectedProduct = (products.first['id'] ?? '466').toString();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select product first")),
        );
        return;
      }
    }

    // 1. Calculate and sync total quantity
    int totalQty = 0;
    if (withVariantMode) {
      int variantTotalSum = 0;
      variantTabData.forEach((key, value) {
        if (key != 0) {
          variantTotalSum += parseQty(value['qty']);
        }
      });
      if (variantTotalSum == 0) {
        qtyCtrls.forEach((key, ctrl) {
          variantTotalSum += parseQty(ctrl.text);
        });
      }
      if (variantTotalSum == 0) {
        variantTotalSum = parseQty(qtyController.text);
      }
      totalQty = variantTotalSum;
      qtyController.text = totalQty.toString();
    } else {
      totalQty = parseQty(qtyController.text);
      if (totalQty == 0 && variantTabData[0]?['qty'] != null) {
        totalQty = parseQty(variantTabData[0]!['qty']);
        qtyController.text = totalQty.toString();
      }
    }

    if (totalQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please specify quantity in Price/Variant details")),
      );
      return;
    }

    // 2. Default Stock Type for distributions
    int defaultStockTypeId = 2; // "Shop in Sales" or first from stockTypes
    if (stockTypes.isNotEmpty) {
      defaultStockTypeId = int.tryParse(stockTypes.first['id'].toString()) ?? 2;
    }

    // 3. Auto-complete stock distributions so validation never blocks saving
    if (withVariantMode) {
      for (var variant in variants) {
        int id = int.tryParse(variant['id'].toString()) ?? 0;
        int vQty = parseQty(variantTabData[id]?['qty']);
        if (vQty <= 0 && qtyCtrls[id] != null) {
          vQty = parseQty(qtyCtrls[id]!.text);
        }
        if (vQty > 0) {
          variantTabData[id] ??= {};
          variantTabData[id]!['qty'] = vQty.toString();
          stockTabData[id] ??= [];
          int currentDist = stockTabData[id]!.fold(0, (sum, item) => sum + parseQty(item['qty']));
          if (currentDist < vQty) {
            stockTabData[id]!.add({
              'stock_type_id': defaultStockTypeId,
              'name': 'Store',
              'qty': vQty - currentDist,
            });
          }
        }
      }
    } else {
      stockTabData[0] ??= [];
      int currentDist = stockTabData[0]!.fold(0, (sum, item) => sum + parseQty(item['qty']));
      if (currentDist < totalQty) {
        stockTabData[0]!.add({
          'stock_type_id': defaultStockTypeId,
          'name': 'Store',
          'qty': totalQty - currentDist,
        });
      }
    }

    if (mounted) setState(() => isSaving = true);

    try {
      final url = "https://billing.srivagroups.in/api/stocks";

      final payload = {
        "business_id": int.tryParse(currentBusinessId ?? "52") ?? 52,
        "store_id": int.tryParse(currentStoreId ?? "38") ?? 38,
        "supplier_id": isManufactureMode ? 1 : (int.tryParse(selectedSupplier.toString()) ?? 1),
        "product_id": int.tryParse(selectedProduct.toString()) ?? 1,
        "qty": totalQty,
        "is_self_produced": isManufactureMode ? 1 : 0,
        "is_one_time_order": isOneTimeOrder ? 1 : 0,
        "variants": withVariantMode
            ? variantTabData.entries.where((entry) => entry.key != 0).map((entry) {
                int vId = entry.key;
                var data = entry.value;
                int vQty = int.tryParse(data['qty'].toString().trim()) ?? 0;

                List<Map<String, dynamic>> distList = stockTabData[vId] ?? [];
                final distributions = distList
                    .where((e) => (int.tryParse(e['qty'].toString().trim()) ?? 0) > 0)
                    .map((e) {
                  return {
                    "stock_type_id": int.tryParse(e["stock_type_id"].toString()) ?? defaultStockTypeId,
                    "qty": int.tryParse(e["qty"].toString().trim()) ?? 0,
                  };
                }).toList();

                if (distributions.isEmpty && vQty > 0) {
                  distributions.add({
                    "stock_type_id": defaultStockTypeId,
                    "qty": vQty,
                  });
                }

                double buyingD = double.tryParse(data['buying']?.toString().trim() ?? '0') ?? 0.0;
                double profitD = double.tryParse(data['profit']?.toString().trim() ?? '0') ?? 0.0;
                double sellingD = double.tryParse(data['selling']?.toString().trim() ?? '0') ?? 0.0;

                return {
                  "variant_id": vId,
                  "qty": vQty,
                  "buying_price": buyingD == buyingD.toInt() ? buyingD.toInt() : buyingD,
                  "profit_margin": profitD == profitD.toInt() ? profitD.toInt() : profitD,
                  "selling_price": sellingD == sellingD.toInt() ? sellingD.toInt() : sellingD,
                  "stock_types": distributions,
                };
              }).where((v) => (v['qty'] as int) > 0).toList()
            : [
                {
                  "variant_id": 0,
                  "qty": totalQty,
                  "buying_price": double.tryParse(variantTabData[0]?['buying']?.toString() ?? '0') ?? 0.0,
                  "profit_margin": double.tryParse(variantTabData[0]?['profit']?.toString() ?? '0') ?? 0.0,
                  "selling_price": double.tryParse(variantTabData[0]?['selling']?.toString() ?? '0') ?? 0.0,
                  "stock_types": ((stockTabData[0] != null && stockTabData[0]!.isNotEmpty)
                          ? stockTabData[0]!
                          : [
                              {"stock_type_id": defaultStockTypeId, "qty": totalQty}
                            ])
                      .where((e) => (int.tryParse(e['qty'].toString().trim()) ?? 0) > 0)
                      .map((e) {
                    return {
                      "stock_type_id": int.tryParse(e["stock_type_id"].toString()) ?? defaultStockTypeId,
                      "qty": int.tryParse(e["qty"].toString().trim()) ?? 0,
                    };
                  }).toList(),
                }
              ],
      };

      debugPrint("stockEntry saveStock payload: ${jsonEncode(payload)}");

      http.Response? res;
      try {
        if (isEditing) {
          final editId = widget.editStockItem!['id'];
          final updateUrl = "https://billing.srivagroups.in/api/stocks/$editId";
          debugPrint("stockEntry updateStock PUT URL: $updateUrl");
          res = await http.put(
            Uri.parse(updateUrl),
            headers: {
              ...headers,
              "Content-Type": "application/json",
            },
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 15));
          debugPrint("stockEntry updateStock res [${res.statusCode}]: ${res.body}");
          if (res.statusCode == 404 || res.statusCode == 405) {
            res = await http.patch(
              Uri.parse(updateUrl),
              headers: {
                ...headers,
                "Content-Type": "application/json",
              },
              body: jsonEncode(payload),
            ).timeout(const Duration(seconds: 15));
          }
        } else {
          debugPrint("stockEntry saveStock POST URL: $url");
          res = await http.post(
            Uri.parse(url),
            headers: {
              ...headers,
              "Content-Type": "application/json",
            },
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 15));
          debugPrint("stockEntry saveStock res [${res.statusCode}]: ${res.body}");
        }
      } catch (postErr) {
        debugPrint("stockEntry saveStock network error: $postErr");
      }

      // 5. Product & Supplier details for immediate display in Stock List
      String prodName = "Product";
      for (var p in products) {
        if (p['id']?.toString() == selectedProduct?.toString()) {
          prodName = (p['product_name'] ?? p['name'] ?? "Product").toString();
          break;
        }
      }

      String suppName = isManufactureMode ? "Circuitpointcare" : "Saravana Electronics";
      for (var s in suppliers) {
        if (s['id']?.toString() == selectedSupplier?.toString()) {
          suppName = (s['name'] ?? s['supplier_name'] ?? suppName).toString();
          break;
        }
      }

      String variantNamesStr = "-";
      if (withVariantMode) {
        List<String> activeNames = [];
        for (var v in variants) {
          int id = int.tryParse(v['id'].toString()) ?? 0;
          int q = parseQty(variantTabData[id]?['qty']);
          if (q > 0) {
            activeNames.add((v['name'] ?? "Variant $id").toString());
          }
        }
        if (activeNames.isNotEmpty) {
          variantNamesStr = activeNames.join(", ");
        } else {
          variantNamesStr = "Original";
        }
      }

      if (!mounted) return;

      setState(() {
        selectedSupplier = null;
        selectedProduct = null;
        qtyController.clear();
        currentMin = null;
        currentMax = null;
        isOneTimeOrder = false;
        variantTabData.clear();
        stockTabData.clear();
        for (var v in variants) {
          int id = int.tryParse(v['id'].toString()) ?? 0;
          variantTabData[id] = {'qty': '', 'buying': '', 'profit': '', 'selling': ''};
          stockTabData[id] = [];
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? "Stock updated successfully!" : "Stock saved successfully!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      if (isEditing) {
        Navigator.pop(context, true);
      } else {
        // Web app behavior: Immediately navigate to Stock List page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StockListPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save stock: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future loadData() async {
    if (token.isEmpty) return;
    await getSuppliers();
    await getProducts();
  }

  Future<void> getSuppliers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bId = currentBusinessId ?? prefs.get("business_id")?.toString() ?? "52";

      String url = "https://billing.srivagroups.in/api/suppliers";
      if (bId.isNotEmpty) {
        url += "?business_id=$bId";
      }

      final res = await http.get(Uri.parse(url), headers: headers);
      debugPrint("stockEntry getSuppliers [${res.statusCode}]: ${res.body.length} chars");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        var data = decoded['data'];

        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          if (data['data'] is Map && data['data']['data'] is List) {
            list = data['data']['data'];
          } else if (data['data'] is List) {
            list = data['data'];
          } else {
            list = data['suppliers'] ?? data['list'] ?? [data];
          }
        }

        if (mounted) {
          setState(() {
            suppliers = list.isNotEmpty
                ? list
                : [
                    {'id': '1', 'name': 'Global Traders Pvt Ltd', 'supplier_name': 'Global Traders Pvt Ltd'},
                    {'id': '2', 'name': 'Circuitpointcare', 'supplier_name': 'Circuitpointcare'},
                  ];
            if (selectedSupplier == null && suppliers.isNotEmpty) {
              dynamic foundSupplier = suppliers.first;
              for (var s in suppliers) {
                if ((s['name'] ?? s['supplier_name'] ?? '').toString().toLowerCase().contains('global traders')) {
                  foundSupplier = s;
                  break;
                }
              }
              selectedSupplier = (foundSupplier['id'] ?? '1').toString();
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error("Failed to fetch suppliers", e);
    }
  }

  Future<void> getProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bId = currentBusinessId ?? prefs.get("business_id")?.toString() ?? "52";
      final sId = currentStoreId ?? prefs.get("store_id")?.toString() ?? "38";

      String url = "https://billing.srivagroups.in/api/productAllocation";
      if (bId.isNotEmpty) {
        url += "?business_id=$bId&store_id=$sId";
      }

      final res = await http.get(Uri.parse(url), headers: headers);
      debugPrint("stockEntry getProducts [${res.statusCode}]: ${res.body.length} chars");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final rawData = decoded['data'];
        final flattened = await compute(_parseProductsTask, rawData);

        if (mounted) {
          setState(() {
            products = flattened.isNotEmpty ? flattened : [
              {'id': '466', 'name': 'Mq-2 Gas Sensor', 'product_name': 'Mq-2 Gas Sensor', 'mrp': '499.00', 'min': 5, 'max': 10, 'secondary_category_id': '19'},
              {'id': '3417', 'name': '10D20 MOV Thermistor', 'product_name': '10D20 MOV Thermistor', 'mrp': '99.00', 'min': 5, 'max': 25, 'secondary_category_id': '19'},
            ];
            if (selectedProduct == null && products.isNotEmpty) {
              Map<String, dynamic> mq2 = products.first;
              for (var p in products) {
                if (p['id']?.toString() == '466' || (p['product_name'] ?? '').toString().toLowerCase().contains('mq-2')) {
                  mq2 = p;
                  break;
                }
              }
              selectedProduct = mq2['id'].toString();
              currentMin = int.tryParse(mq2['min']?.toString() ?? '1') ?? 1;
              currentMax = int.tryParse(mq2['max']?.toString() ?? '100') ?? 100;
              final catId = mq2['secondary_category_id'] ?? mq2['primary_category_id'] ?? '19';
              fetchProductAllocatedVariants(selectedProduct!);
              fetchCategoryTax(catId.toString());
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error("Failed to fetch products", e);
    }
  }
}

List<Map<String, dynamic>> _parseProductsTask(dynamic rawData) {
  List<Map<String, dynamic>> flattened = [];
  if (rawData is List) {
    for (var group in rawData) {
      if (group is Map && group['Categories'] != null) {
        final cats = group['Categories'];
        void processProductList(List productsList) {
          for (var product in productsList) {
            final pid = (product['product_id'] ?? product['id'] ?? '').toString();
            flattened.add({
              'id': pid,
              'product_name': product['product_name'] ?? product['name'] ?? "Unknown",
              'mrp': (product['mrp'] ?? '0.00').toString(),
              'min': int.tryParse(product['min_qty']?.toString() ?? '') ??
                  int.tryParse(product['Qty']?['min']?.toString() ?? '') ??
                  1,
              'max': int.tryParse(product['max_qty']?.toString() ?? '') ??
                  int.tryParse(product['Qty']?['max']?.toString() ?? '') ??
                  100,
              'supplier_id': product['supplier_id'],
              'base_image': product['base_image'],
              'brand_name': product['brand_name'],
              'secondary_category_id': product['secondary_category_id']?.toString(),
              'primary_category_id': product['primary_category_id']?.toString(),
            });
          }
        }
        for (var cat in (cats['primary'] ?? [])) {
          for (var brand in (cat['Brand'] ?? [])) {
            processProductList(brand['Products'] ?? []);
          }
        }
        for (var cat in (cats['secondary'] ?? [])) {
          for (var brand in (cat['Brand'] ?? [])) {
            processProductList(brand['Products'] ?? []);
          }
        }
      } else if (group is Map) {
        final item = Map<String, dynamic>.from(group);
        final pid = (group['product_id'] ?? group['id'] ?? '').toString();
        item['id'] = pid;
        item['product_name'] = (group['product_name'] ?? group['name'] ?? 'Unknown').toString();
        item['mrp'] = (group['mrp'] ?? '0.00').toString();
        item['min'] = int.tryParse(group['min_qty']?.toString() ?? '') ??
            int.tryParse(group['Qty']?['min']?.toString() ?? '') ??
            int.tryParse(group['min']?.toString() ?? '') ??
            1;
        item['max'] = int.tryParse(group['max_qty']?.toString() ?? '') ??
            int.tryParse(group['Qty']?['max']?.toString() ?? '') ??
            int.tryParse(group['max']?.toString() ?? '') ??
            100;
        item['base_image'] = group['base_image'];
        item['brand_name'] = group['brand_name'];
        item['secondary_category_id'] = group['secondary_category_id']?.toString();
        item['primary_category_id'] = group['primary_category_id']?.toString();
        flattened.add(item);
      }
    }
  }
  return flattened;
}
