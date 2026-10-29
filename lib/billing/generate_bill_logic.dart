part of 'Generate Bill.dart';

extension _CustomerScreenStateLogic on _CustomerScreenState {
  Future<void> checkRegistrationAfterReturn() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      loading = true;
      errorMessage = null;
      _showDropdown = true;
    });

    try {
      final data = await fetchCustomers(query);
      if (!mounted) return;

      setState(() {
        results = data;
        loading = false;
        _showDropdown = true;

        if (data.isEmpty) {
          errorMessage = "No customer found with '$query'. Registration may not be completed.";
        } else {
          if (data.length == 1) {
            selectedCustomer = data.first;
            _showDropdown = false;
            if (verifyBy == "GST No") {
              _searchController.text = selectedCustomer!.gst;
            } else if (verifyBy == "PAN No") {
              _searchController.text = selectedCustomer!.pan;
            } else {
              _searchController.text = selectedCustomer!.mobile;
            }
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        results = [];
        errorMessage = "Failed to load customer. Error: $e";
        _showDropdown = true;
      });
    }
  }

  void _launchCustomerRegistration() async {
    final query = _searchController.text.trim();
    String urlStr = "https://user.jobes24x7.com/?key=bill";
    if (query.isNotEmpty) {
      if (verifyBy == "Mobile No") {
        urlStr += "&mobile=$query";
      } else if (verifyBy == "GST No") {
        urlStr += "&gst=$query";
      } else if (verifyBy == "PAN No") {
        urlStr += "&pan=$query";
      }
    }

    setState(() {
      _isLaunchingRegistration = true;
      errorMessage = null;
    });

    try {
      final bool? registered = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerRegisterWebView(url: urlStr),
        ),
      );
      if (registered == true) {
        checkRegistrationAfterReturn();
      } else {
        checkRegistrationAfterReturn();
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error launching page: $e";
      });
    } finally {
      setState(() {
        _isLaunchingRegistration = false;
      });
    }
  }

  void searchCustomer(String value) {
    final query = value.trim();

    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    if (query.isEmpty) {
      setState(() {
        results = [];
        loading = false;
        errorMessage = null;
        _showDropdown = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        loading = true;
        errorMessage = null;
        _showDropdown = true;
      });

      try {
        final data = await fetchCustomers(query);
        if (!mounted) return;

        setState(() {
          results = data;
          loading = false;
          _showDropdown = true;

          if (data.isEmpty) {
            errorMessage = "No customers found";
          } else {
            errorMessage = null;
            // Check for exact match or single result
            Customer? matched;
            for (final c in data) {
              if (c.mobile == query || (query.length >= 10 && c.mobile.contains(query))) {
                matched = c;
                break;
              }
            }
            if (matched != null) {
              selectedCustomer = matched;
              _showDropdown = false;
            } else if (data.length == 1) {
              selectedCustomer = data.first;
              _showDropdown = false;
            }
          }
        });
      } catch (e) {
        if (!mounted) return;

        if (e.toString().contains("Invalid or expired token")) {
          SharedPreferences.getInstance().then((prefs) {
            prefs.clear();
            Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
          });
          return;
        }

        setState(() {
          loading = false;
          results = [];
          errorMessage = "Failed to load customers";
          _showDropdown = true;
        });
      }
    });
  }

  Future<Map<String, String>> _getBillingHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("billing_auth_token") ?? 
                  prefs.getString("auth_token") ?? 
                  prefs.getString("token") ?? "";
    final businessId = prefs.getString("selected_business_id") ??
                       prefs.get("business_id")?.toString() ?? "";
    final employeeId = prefs.getString("employee_id") ?? 
                       prefs.getString("userId") ?? 
                       prefs.getString("user_id") ?? "";

    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      if (token.isNotEmpty) "Authorization": "Bearer $token",
      if (businessId.isNotEmpty) "business_id": businessId,
      if (businessId.isNotEmpty) "x-business-id": businessId,
      if (businessId.isNotEmpty) "account_id": businessId,
      if (businessId.isNotEmpty) "id": businessId,
      if (employeeId.isNotEmpty) "x-employee-id": employeeId,
    };
  }

  Future<List<Customer>> fetchCustomers(String search) async {
    try {
      final query = search.trim();
      final bool isMobileSearch = verifyBy == "Mobile No";
      final String endpoint = (isUser || isMobileSearch) ? "usercentral" : "businesscentral";

      final headers = await _getBillingHeaders();
      final String url = "https://billing.srivagroups.in/api/customer/$endpoint?search=$query";

      AppLogger.info("FETCH CUSTOMERS: GET $url");
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      AppLogger.api("GET", url, response.statusCode, body: response.body);

      if (response.statusCode != 200) {
        if (response.statusCode == 400 && response.body.contains("Invalid or expired token")) {
          throw Exception("Invalid or expired token");
        }
        return [];
      }

      final decoded = json.decode(response.body);
      List<dynamic> rawList = [];

      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded["data"] is List) {
          rawList = decoded["data"];
        } else if (decoded["data"] is Map<String, dynamic>) {
          final nested = decoded["data"];
          if (nested["data"] is List) {
            rawList = nested["data"];
          } else if (nested["customers"] is List) {
            rawList = nested["customers"];
          } else if (nested["users"] is List) {
            rawList = nested["users"];
          } else if (nested["list"] is List) {
            rawList = nested["list"];
          }
        } else if (decoded["customers"] is List) {
          rawList = decoded["customers"];
        } else if (decoded["users"] is List) {
          rawList = decoded["users"];
        } else if (decoded["results"] is List) {
          rawList = decoded["results"];
        } else if (decoded["list"] is List) {
          rawList = decoded["list"];
        }
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => Customer.fromJson(e))
          .where((customer) => customer.name.trim().isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.error("FETCH CUSTOMER ERROR", e);
      return [];
    }
  }

  Future<void> loadAllStocks() async {
    if (!mounted) return;
    setState(() {
      isStocksInitialLoading = true;
    });

    try {
      final stocks = await fetchProductAllocations("");
      if (!mounted) return;
      setState(() {
        allAvailableStocks = stocks;
        isStocksInitialLoading = false;
      });
      AppLogger.info("Loaded ${stocks.length} stocks successfully into Generate Bill");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isStocksInitialLoading = false;
      });
      AppLogger.error("Failed to load initial stocks", e);
    }
  }

  void searchProduct(String value) {
    final query = value.trim();
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        productResults = [];
        _showProductDropdown = false;
        productLoading = false;
        productErrorMessage = null;
      });
      return;
    }

    // 1. Immediate in-memory search from pre-loaded allAvailableStocks
    final q = query.toLowerCase();
    List<ProductStock> localMatches = allAvailableStocks.where((item) {
      if (productSearchBy == "Product Code") {
        return item.productCode.toLowerCase().contains(q);
      } else if (productSearchBy == "Brand") {
        return item.brand.toLowerCase().contains(q);
      } else if (productSearchBy == "Category") {
        return item.category.toLowerCase().contains(q);
      } else if (productSearchBy == "SKU") {
        return item.sku.toLowerCase().contains(q);
      } else {
        return item.productName.toLowerCase().contains(q);
      }
    }).toList();

    setState(() {
      productResults = localMatches;
      productLoading = localMatches.isEmpty;
      _showProductDropdown = true;
      productErrorMessage = null;
    });

    // 2. Debounce fetch from remote api/stocks if needed
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      if (localMatches.isEmpty) {
        setState(() {
          productLoading = true;
          productErrorMessage = null;
          _showProductDropdown = true;
        });
      }

      try {
        final data = await fetchProductAllocations(query);
        if (!mounted) return;

        setState(() {
          if (data.isNotEmpty || localMatches.isEmpty) {
            productResults = data.isNotEmpty ? data : localMatches;
          }
          productLoading = false;
          if (productResults.isEmpty) {
            productErrorMessage = "No products found";
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          productLoading = false;
          if (productResults.isEmpty) {
            productErrorMessage = "Search failed";
          }
        });
      }
    });
  }

  Future<List<ProductStock>> fetchProductAllocations(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("billing_auth_token") ?? 
                    prefs.getString("auth_token") ?? 
                    prefs.getString("token") ?? "";
      final businessId = prefs.getString("selected_business_id") ??
                         prefs.get("business_id")?.toString() ?? "";
      final r = prefs.getString("role")?.toLowerCase() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      String url = "https://billing.srivagroups.in/api/stocks";
      List<String> params = [];
      if (query.trim().isNotEmpty) {
        params.add("search=${Uri.encodeComponent(query.trim())}");
      }
      if (r == "supplier" || r == "partner") {
        if (businessId.isNotEmpty) params.add("business_id=$businessId");
        if (uId.isNotEmpty) params.add("user_main_id=$uId");
      } else if (businessId.isNotEmpty) {
        params.add("business_id=$businessId");
      }

      if (params.isNotEmpty) {
        url += "?${params.join('&')}";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        // Fallback retry without query params if 400
        if (response.statusCode == 400 && url.contains("?")) {
          final fallbackRes = await http.get(
            Uri.parse("https://billing.srivagroups.in/api/stocks"),
            headers: {
              "Accept": "application/json",
              if (token.isNotEmpty) "Authorization": "Bearer $token",
            },
          );
          if (fallbackRes.statusCode == 200) {
            return _parseStocksResponse(fallbackRes.body, query);
          }
        }
        return [];
      }

      return _parseStocksResponse(response.body, query);
    } catch (e) {
      AppLogger.error("fetchProductAllocations error", e);
      return [];
    }
  }

  List<ProductStock> _parseStocksResponse(String responseBody, String query) {
    try {
      final decoded = json.decode(responseBody);
      List<ProductStock> list = [];
      dynamic data = decoded['data'] ?? decoded;
      List<dynamic> rawStocks = [];
      if (data is List) {
        rawStocks = data;
      } else if (data is Map && data['data'] is List) {
        rawStocks = data['data'];
      }

      for (final stock in rawStocks) {
        if (stock is! Map) continue;
        final String stockId = (stock['id'] ?? "").toString();
        final String productId = (stock['product_id'] ?? "").toString();
        final String productName = (stock['product_name'] ?? stock['name'] ?? "").toString().trim();
        final String productCode = (stock['product_code'] ?? stock['code'] ?? "").toString().trim();
        final String baseImage = (stock['base_image'] ?? stock['image'] ?? "").toString();
        final double mrp = double.tryParse((stock['mrp'] ?? "0").toString()) ?? 0.0;
        final String supplierName = (stock['supplier']?['name'] ?? stock['supplier_name'] ?? "").toString();
        final String category = (stock['category_name'] ?? stock['category']?['name'] ?? stock['category'] ?? "").toString();
        final String brand = (stock['brand_name'] ?? stock['brand']?['name'] ?? stock['brand'] ?? "").toString();
        final String description = (stock['description'] ?? "").toString();
        final String mainSku = (stock['sku'] ?? "").toString();
        final int stockTotalQty = int.tryParse((stock['total_qty'] ?? stock['qty'] ?? "0").toString()) ?? 0;
        
        final variants = stock['variants'] ?? [];
        if (variants is List && variants.isNotEmpty) {
          for (final variant in variants) {
            if (variant is! Map) continue;
            final String recordId = (variant['id'] ?? "").toString();
            final String typeId = (variant['variant_id'] ?? "").toString();
            final int vQty = int.tryParse((variant['qty'] ?? "0").toString()) ?? 0;
            final int totalQty = int.tryParse((variant['total_qty'] ?? variant['qty'] ?? "0").toString()) ?? 0;
            final double vSellingPrice = double.tryParse((variant['selling_price'] ?? "0").toString()) ?? 0.0;
            final double vWithoutGst = double.tryParse((variant['selling_price_without_gst'] ?? "0").toString()) ?? 0.0;
            final double vWithGst = double.tryParse((variant['selling_price_with_gst'] ?? variant['selling_price'] ?? "0").toString()) ?? vSellingPrice;
            final double gstRate = double.tryParse((variant['gst_rate'] ?? "18").toString()) ?? 18.0;
            final List stockTypes = (variant['stock_types'] is List) ? variant['stock_types'] : [];

            String label = "";
            if (variant['variant_name'] != null && variant['variant_name'].toString().trim().isNotEmpty) {
              label = variant['variant_name'].toString().trim();
            } else if (variant['variant'] != null && variant['variant']['name'] != null) {
              label = variant['variant']['name'].toString().trim();
            } else if (variant['name'] != null) {
              label = variant['name'].toString().trim();
            } else if (typeId == "1") {
              label = "Original";
            } else if (typeId == "2") {
              label = "Imported";
            } else if (typeId == "3") {
              label = "Complimentary";
            } else {
              label = "Standard";
            }

            final String vSku = (variant['sku'] ?? mainSku).toString();

            list.add(ProductStock(
              stockId: stockId,
              productId: productId,
              variantId: recordId,
              variantTypeId: typeId,
              productName: productName,
              productCode: productCode,
              brand: brand,
              baseImage: baseImage,
              mrp: mrp,
              supplierName: supplierName,
              category: category,
              variant: label,
              qty: vQty > 0 ? vQty : (totalQty > 0 ? totalQty : 1), 
              unitPrice: vSellingPrice > 0 ? vSellingPrice : mrp, 
              total: vSellingPrice > 0 ? vSellingPrice : mrp, 
              isRequest: totalQty == 0 && vQty == 0,
              description: description,
              sku: vSku,
              gstRate: gstRate,
              sellingPriceWithoutGst: vWithoutGst,
              sellingPriceWithGst: vWithGst,
              stockTypes: stockTypes,
            ));
          }
        } else {
          // Single stock without variants
          final double sellingPrice = double.tryParse((stock['selling_price'] ?? "0").toString()) ?? mrp;
          list.add(ProductStock(
            stockId: stockId,
            productId: productId,
            variantId: "0",
            variantTypeId: "0",
            productName: productName,
            productCode: productCode,
            brand: brand,
            baseImage: baseImage,
            mrp: mrp,
            supplierName: supplierName,
            category: category,
            variant: "Standard",
            qty: stockTotalQty > 0 ? stockTotalQty : 1,
            unitPrice: sellingPrice,
            total: sellingPrice,
            isRequest: stockTotalQty == 0,
            description: description,
            sku: mainSku,
          ));
        }
      }

      final searchText = query.trim().toLowerCase();
      if (searchText.isNotEmpty) {
        List<ProductStock> startsWithList = [];
        List<ProductStock> containsList = [];

        for (final item in list) {
          String searchField = "";
          if (productSearchBy == "Product Code") {
            searchField = item.productCode.toLowerCase();
          } else if (productSearchBy == "Brand") {
            searchField = item.brand.toLowerCase();
          } else if (productSearchBy == "Category") {
            searchField = item.category.toLowerCase();
          } else if (productSearchBy == "SKU") {
            searchField = item.sku.toLowerCase();
          } else {
            searchField = item.productName.toLowerCase();
          }

          if (searchField.startsWith(searchText)) {
            startsWithList.add(item);
          } else if (searchField.contains(searchText)) {
            containsList.add(item);
          }
        }
        return [...startsWithList, ...containsList];
      }

      return list;
    } catch (e) {
      AppLogger.error("_parseStocksResponse error", e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> createUnregisteredCustomer({
    required String name,
    required String phone,
    required String address,
    required String email,
  }) async {
    try {
      final headers = await _getBillingHeaders();
      const url = "https://billing.srivagroups.in/api/unregister-customer";
      final body = {
        "customer_name": name,
        "phone_number": phone,
        "address": address,
        if (email.isNotEmpty) "email_id": email,
      };

      AppLogger.info("Creating unregistered customer: $url with body: ${json.encode(body)}");

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      AppLogger.api("POST", url, response.statusCode, body: response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {"data": decoded};
      }
    } catch (e) {
      AppLogger.error("createUnregisteredCustomer error", e);
    }
    return null;
  }

  Future<bool> addBillProductApi(ProductStock item, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getString("selected_business_id") ??
                         prefs.get("business_id")?.toString() ?? "";
      final headers = await _getBillingHeaders();

      const url = "https://billing.srivagroups.in/api/bill-add-product";
      final Map<String, dynamic> body = {
        "business_id": int.tryParse(businessId) ?? businessId,
        "stock_id": int.tryParse(item.stockId) ?? item.stockId,
        "product_id": int.tryParse(item.productId) ?? item.productId,
        "variant_id": int.tryParse(item.variantId) ?? item.variantId,
        "qty": quantity,
        "quantity": quantity,
        "unit_price": item.unitPrice,
        "selling_price": item.unitPrice,
        "total": quantity * item.unitPrice,
        "product_name": item.productName,
        "variant": item.variant,
        "sku": item.sku,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      AppLogger.error("addBillProductApi error", e);
      return false;
    }
  }

  Future<void> fetchExistingBillProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("billing_auth_token") ?? 
                    prefs.getString("auth_token") ?? 
                    prefs.getString("token") ?? "";
      if (token.isEmpty) return;

      const url = "https://billing.srivagroups.in/api/bill-add-product";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        dynamic data = decoded['data'] ?? decoded;
        if (data is List && data.isNotEmpty) {
          List<ProductStock> loadedItems = [];
          for (var item in data) {
            if (item is! Map) continue;
            final double price = double.tryParse((item['selling_price'] ?? item['unit_price'] ?? "0").toString()) ?? 0.0;
            final int qty = int.tryParse((item['bill_qty'] ?? item['qty'] ?? item['quantity'] ?? "1").toString()) ?? 1;
            loadedItems.add(ProductStock(
              stockId: (item['stock_id'] ?? item['id'] ?? "").toString(),
              productId: (item['product_id'] ?? "").toString(),
              variantId: (item['variant_id'] ?? "").toString(),
              productName: (item['product_name'] ?? "").toString(),
              variant: (item['variant_name'] ?? item['variant'] ?? "Standard").toString(),
              unitPrice: price,
              qty: qty,
              total: qty * price,
              sku: (item['sku'] ?? "").toString(),
              warranty: (item['warranty'] ?? "").toString(),
              category: (item['category'] ?? "General").toString(),
              brand: (item['brand'] ?? "Generic").toString(),
              supplierName: (item['supplier']?['name'] ?? "").toString(),
            ));
          }
          if (mounted && loadedItems.isNotEmpty) {
            setState(() {
              selectedBillItems = loadedItems;
              calculateTotals();
            });
          }
        }
      }
    } catch (e) {
      AppLogger.error("fetchExistingBillProducts error", e);
    }
  }

  Future<List<dynamic>> fetchStockDetails(String stockId, String variantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final url = "https://billing.srivagroups.in/api/stockTypes/by-stock?stock_id=$stockId";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List variantsList = (decoded['variants'] ?? (decoded['data'] is List ? decoded['data'][0]['variants'] : decoded['data']?['variants']) ?? []);
        final selectedVariant = variantsList.firstWhere(
          (v) => v['id'].toString() == variantId.toString(),
          orElse: () => null,
        );

        if (selectedVariant != null) {
          return selectedVariant['stock_types'] ?? [];
        }
      }
    } catch (e) {
      AppLogger.error("FETCH STOCK DETAILS ERROR", e);
    }
    return [];
  }

  Future<void> fetchAdditionalChargesData() async {
    if (selectedBillItems.isEmpty) {
      setState(() {
        fetchedPrices = [];
        fetchedCombos = [];
        fetchedCoupons = [];
        fetchedDiscounts = [];
      });
      return;
    }
    
    setState(() {
      loadingCharges = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      final headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      };

      final productId = selectedBillItems.first.productId;

      String buildUrl(String base) {
        List<String> params = [];
        if (productId.isNotEmpty) params.add("product_id=$productId");
        if (bId.isNotEmpty) params.add("business_id=$bId");
        if (uId.isNotEmpty) params.add("user_main_id=$uId");
        return params.isEmpty ? base : "$base?${params.join('&')}";
      }

      final priceUrl = buildUrl("https://billing.srivagroups.in/api/add-price");
      final comboUrl = buildUrl("https://billing.srivagroups.in/api/add-combo-offer");
      final couponUrl = buildUrl("https://billing.srivagroups.in/api/add-coupon-code");
      final discountUrl = buildUrl("https://billing.srivagroups.in/api/add-discount");

      final results = await Future.wait([
        http.get(Uri.parse(priceUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(comboUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(couponUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(discountUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
      ]);

      List<dynamic> parseResponse(http.Response res) {
        if (res.statusCode == 200) {
          final decoded = json.decode(res.body);
          if (decoded is Map && decoded.containsKey('data')) {
            return decoded['data'] is List ? decoded['data'] : [];
          } else if (decoded is List) {
            return decoded;
          }
        }
        return [];
      }

      setState(() {
        fetchedPrices = parseResponse(results[0]);
        fetchedCombos = parseResponse(results[1]);
        fetchedCoupons = parseResponse(results[2]);
        fetchedDiscounts = parseResponse(results[3]);
        loadingCharges = false;
      });
    } catch (e) {
      AppLogger.error("Error fetching additional charges", e);
      setState(() {
        loadingCharges = false;
      });
    }
  }

  void calculateTotals() {
    setState(() {
      final double itemTotalSum = selectedBillItems.fold(0, (sum, item) => sum + item.total);
      final double enteredTax = double.tryParse(taxController.text) ?? 0;
      final double enteredDiscount = double.tryParse(discountController.text) ?? 0;
      final double additionalCharges = double.tryParse(chargesController.text) ?? 0;

      double taxAmount = 0;
      if (globalTaxType == "%") {
        taxAmount = (itemTotalSum * enteredTax) / 100;
      } else {
        taxAmount = enteredTax;
      }

      double discountAmount = 0;
      if (globalDiscountType == "%") {
        discountAmount = (itemTotalSum * enteredDiscount) / 100;
      } else {
        discountAmount = enteredDiscount;
      }

      totalItemAmount = itemTotalSum;
      totalTaxAmount = taxAmount;
      totalDiscountAmount = discountAmount;
      totalAdditionalCharges = additionalCharges;
      finalPayableAmount = itemTotalSum + taxAmount + additionalCharges - discountAmount;
      
      itemTotal = itemTotalSum;
      payableTotal = finalPayableAmount;
    });
  }

  void _updateItemQty(ProductStock item, int newQty) {
    setState(() {
      int idx = selectedBillItems.indexWhere((e) => e.stockId == item.stockId && e.variantId == item.variantId);
      if (idx != -1) {
        double currentItemBaseTotal = newQty * item.unitPrice;
        double taxAmt = item.taxType == "%" ? (currentItemBaseTotal * item.enteredTax) / 100 : item.enteredTax;
        double discountAmt = item.discountType == "%" ? (currentItemBaseTotal * item.enteredDiscount) / 100 : item.enteredDiscount;
        double finalPayableItem = currentItemBaseTotal + taxAmt - discountAmt;
        
        selectedBillItems[idx] = item.copyWith(
          qty: newQty,
          total: finalPayableItem,
          taxAmount: taxAmt,
          discountAmount: discountAmt,
        );
      }
      calculateTotals();
    });
  }
}
