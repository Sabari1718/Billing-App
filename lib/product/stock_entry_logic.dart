part of 'stock entry.dart';

extension _StockEntryPageStateLogic on _StockEntryPageState {
  Future<void> fetchVariants() async {
    if (!mounted) return;
    setState(() => isLoadingVariants = true);
    try {
      final url = "https://billing.srivagroups.in/api/variant-master";
      final res = await http.get(Uri.parse(url), headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        dynamic data = decoded['data'];

        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['data'] is List) {
          list = data['data'];
        }

        if (mounted) {
          setState(() {
            variants = list.map((e) => e as Map<String, dynamic>).toList();
            variantTabData.clear();
            stockTabData.clear();
            for (var v in variants) {
              int id = int.tryParse(v['id'].toString()) ?? 0;
              variantTabData[id] = {'qty': '', 'buying': '', 'profit': '', 'selling': ''};
              stockTabData[id] = [];
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error("Error fetching variants", e);
    } finally {
      if (mounted) setState(() => isLoadingVariants = false);
    }
  }

  Future<void> fetchStockTypes() async {
    if (stockTypes.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    currentBusinessId = prefs.get("business_id")?.toString();

    if (mounted) setState(() => isLoadingStockTypes = true);
    try {
      final url = "https://billing.srivagroups.in/api/stockTypes";
      final res = await http.get(Uri.parse(url), headers: headers);

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
              final bId = e['business_id']?.toString();
              if (e['deleted_at'] != null) return false;
              if (currentBusinessId != null && bId != null && bId != "0" && bId != "" && bId != currentBusinessId) {
                return false;
              }

              final name = (e['name'] ?? '').toString().replaceAll('\r', '').replaceAll('\n', '').trim();
              if (uniqueNames.contains(name)) return false;
              uniqueNames.add(name);
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

  Future<void> _initToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawToken1 = prefs.get("token");
      final rawToken2 = prefs.get("auth_token");
      final String safeToken = (rawToken1?.toString()) ?? (rawToken2?.toString()) ?? "";

      if (mounted) {
        setState(() {
          token = safeToken;
        });
      }

      await loadData();
      await fetchVariants();
      await fetchStockTypes();
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

    if (!isManufactureMode && selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select supplier first")),
      );
      return;
    }
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select product first")),
      );
      return;
    }

    // Sync total quantity before validation
    int totalQty = 0;
    if (withVariantMode) {
      int variantTotalSum = 0;
      variantTabData.forEach((key, value) {
        if (key != 0) {
          variantTotalSum += parseQty(value['qty']);
        }
      });
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

    // 2. Validate details based on mode
    if (withVariantMode) {
      bool distributionPassed = true;
      for (var variant in variants) {
        int id = int.tryParse(variant['id'].toString()) ?? 0;
        int vQty = parseQty(variantTabData[id]?['qty']);

        if (vQty > 0) {
          List<Map<String, dynamic>> distList = stockTabData[id] ?? [];
          int distributedTotal = distList.fold(0, (sum, item) => sum + parseQty(item['qty']));
          String variantName = variant['name'] ?? "Variant $id";

          if (distributedTotal != vQty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("$variantName stock distribution total ($distributedTotal) must be $vQty"),
                backgroundColor: Colors.redAccent,
              ));
            }
            distributionPassed = false;
            break;
          }
        }
      }
      if (!distributionPassed) return;
    } else {
      // Without Variant Mode
      int vQty = totalQty;
      List<Map<String, dynamic>> distList = stockTabData[0] ?? [];
      int distributedTotal = distList.fold(0, (sum, item) => sum + parseQty(item['qty']));

      if (distributedTotal != vQty && distList.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Stock distribution total ($distributedTotal) must be $vQty"),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
    }

    // Min/Max Validation
    if (currentMin != null && totalQty < currentMin!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Minimum allowed quantity is $currentMin")),
      );
      return;
    }
    if (!isOneTimeOrder && currentMax != null && totalQty > currentMax!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Maximum allowed quantity is $currentMax")),
      );
      return;
    }

    if (mounted) setState(() => isSaving = true);

    try {
      final url = "https://billing.srivagroups.in/api/stocks";

      final payload = {
        "supplier_id": isManufactureMode ? 1 : (int.tryParse(selectedSupplier.toString()) ?? 1),
        "product_id": int.tryParse(selectedProduct.toString()) ?? 1,
        "qty": totalQty,
        "is_self_produced": isManufactureMode ? 1 : 0,
        "is_one_time_order": isOneTimeOrder,
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
                    "stock_type_id": int.tryParse(e["stock_type_id"].toString()) ?? 0,
                    "qty": int.tryParse(e["qty"].toString().trim()) ?? 0,
                  };
                }).toList();

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
                  "stock_types": (stockTabData[0] ?? [])
                      .where((e) => (int.tryParse(e['qty'].toString().trim()) ?? 0) > 0)
                      .map((e) {
                    return {
                      "stock_type_id": int.tryParse(e["stock_type_id"].toString()) ?? 0,
                      "qty": int.tryParse(e["qty"].toString().trim()) ?? 0,
                    };
                  }).toList(),
                }
              ],
      };

      final res = await http.post(
        Uri.parse(url),
        headers: {
          ...headers,
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201 || (decoded is Map && decoded['success'] == true)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Stock saved successfully"),
          backgroundColor: Colors.green,
        ));

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
      } else {
        String errorMsg = decoded['message']?.toString() ?? "Failed to save stock";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
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
      final bId = prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";
      final r = prefs.getString("role")?.toLowerCase() ?? "";

      String url = "https://billing.srivagroups.in/api/suppliers";
      if (r == "supplier" || r == "partner") {
        url += "?business_id=$bId&user_main_id=$uId";
      } else if (bId.isNotEmpty) {
        url += "?business_id=$bId";
      }

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        var data = decoded['data'];

        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          if (data['data'] is Map && data['data']['data'] is List) {
            list = data['data']['data'];
          } else {
            list = data['suppliers'] ?? data['list'] ?? [data];
          }
        }

        if (mounted) {
          setState(() {
            suppliers = list.isNotEmpty ? list : [
              {'id': '1', 'name': 'Circuitpointcare', 'supplier_name': 'Circuitpointcare'},
              {'id': '2', 'name': 'TechSuppliers India', 'supplier_name': 'TechSuppliers India'},
            ];
          });
        }
      } else {
        if (mounted && suppliers.isEmpty) {
          setState(() {
            suppliers = [
              {'id': '1', 'name': 'Circuitpointcare', 'supplier_name': 'Circuitpointcare'},
              {'id': '2', 'name': 'TechSuppliers India', 'supplier_name': 'TechSuppliers India'},
            ];
          });
        }
      }
    } catch (e) {
      AppLogger.error("Failed to fetch suppliers", e);
      if (mounted && suppliers.isEmpty) {
        setState(() {
          suppliers = [
            {'id': '1', 'name': 'Circuitpointcare', 'supplier_name': 'Circuitpointcare'},
            {'id': '2', 'name': 'TechSuppliers India', 'supplier_name': 'TechSuppliers India'},
          ];
        });
      }
    }
  }

  Future<void> getProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bId = prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";
      final r = prefs.getString("role")?.toLowerCase() ?? "";

      String url = "https://billing.srivagroups.in/api/productAllocation";
      if (r == "supplier" || r == "partner") {
        url += "?business_id=$bId&user_main_id=$uId";
      } else if (bId.isNotEmpty) {
        url += "?business_id=$bId";
      }

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final rawData = decoded['data'];
        final flattened = await compute(_parseProductsTask, rawData);

        if (mounted) {
          setState(() {
            products = flattened.isNotEmpty ? flattened : [
              {'id': '1', 'name': 'Mq-2 Gas Sensor', 'product_name': 'Mq-2 Gas Sensor', 'mrp': '499.00', 'min': 1, 'max': 100},
              {'id': '2', 'name': '10D20 MOV Thermistor', 'product_name': '10D20 MOV Thermistor', 'mrp': '25.00', 'min': 1, 'max': 100},
              {'id': '3', 'name': '10D431 MOV Thermister', 'product_name': '10D431 MOV Thermister', 'mrp': '25.00', 'min': 1, 'max': 100},
            ];
          });
        }
      } else {
        if (mounted && products.isEmpty) {
          setState(() {
            products = [
              {'id': '1', 'name': 'Mq-2 Gas Sensor', 'product_name': 'Mq-2 Gas Sensor', 'mrp': '499.00', 'min': 1, 'max': 100},
              {'id': '2', 'name': '10D20 MOV Thermistor', 'product_name': '10D20 MOV Thermistor', 'mrp': '25.00', 'min': 1, 'max': 100},
              {'id': '3', 'name': '10D431 MOV Thermister', 'product_name': '10D431 MOV Thermister', 'mrp': '25.00', 'min': 1, 'max': 100},
            ];
          });
        }
      }
    } catch (e) {
      AppLogger.error("Failed to fetch products", e);
      if (mounted && products.isEmpty) {
        setState(() {
          products = [
            {'id': '1', 'name': 'Mq-2 Gas Sensor', 'product_name': 'Mq-2 Gas Sensor', 'mrp': '499.00', 'min': 1, 'max': 100},
            {'id': '2', 'name': '10D20 MOV Thermistor', 'product_name': '10D20 MOV Thermistor', 'mrp': '25.00', 'min': 1, 'max': 100},
            {'id': '3', 'name': '10D431 MOV Thermister', 'product_name': '10D431 MOV Thermister', 'mrp': '25.00', 'min': 1, 'max': 100},
          ];
        });
      }
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
            flattened.add({
              'id': product['id'],
              'product_name': product['name'] ?? product['product_name'] ?? "Unknown",
              'min': int.tryParse(product['Qty']?['min']?.toString() ?? '') ?? 1,
              'max': int.tryParse(product['Qty']?['max']?.toString() ?? '') ?? 100,
              'supplier_id': product['supplier_id'],
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
        item['min'] = int.tryParse(group['Qty']?['min']?.toString() ?? '') ?? int.tryParse(group['min']?.toString() ?? '') ?? 1;
        item['max'] = int.tryParse(group['Qty']?['max']?.toString() ?? '') ?? int.tryParse(group['max']?.toString() ?? '') ?? 100;
        flattened.add(item);
      }
    }
  }
  return flattened;
}
