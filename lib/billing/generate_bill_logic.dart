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

  Future<List<Customer>> fetchCustomers(String search) async {
    try {
      final query = search.trim();
      final bool isMobileSearch = verifyBy == "Mobile No";
      final String endpoint = (isUser || isMobileSearch) ? "usercentral" : "businesscentral";

      final prefs = await SharedPreferences.getInstance();
      final bId = prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";
      final r = prefs.getString("role")?.toLowerCase() ?? "";

      String url = "https://billing.srivagroups.in/api/customer/$endpoint?search=$query";
      if (r == "supplier" || r == "partner") {
        url += "&business_id=$bId&user_main_id=$uId";
      } else if (bId.isNotEmpty) {
        url += "&business_id=$bId";
      }
      
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

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
          } else if (nested["list"] is List) {
            rawList = nested["list"];
          }
        } else if (decoded["customers"] is List) {
          rawList = decoded["customers"];
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

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        productLoading = true;
        productErrorMessage = null;
        _showProductDropdown = true;
      });

      try {
        final data = await fetchProductAllocations(query);
        if (!mounted) return;

        setState(() {
          productResults = data;
          productLoading = false;
          if (data.isEmpty) {
            productErrorMessage = "No products found";
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          productLoading = false;
          productErrorMessage = "Search failed";
        });
      }
    });
  }

  Future<List<ProductStock>> fetchProductAllocations(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
      final businessId = prefs.get("business_id")?.toString() ?? "";
      final r = prefs.getString("role")?.toLowerCase() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      String url = "https://billing.srivagroups.in/api/stocks?search=$query";
      if (r == "supplier" || r == "partner") {
        url += "&business_id=$businessId&user_main_id=$uId";
      } else if (businessId.isNotEmpty) {
        url += "&business_id=$businessId";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) return [];

      final decoded = json.decode(response.body);
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
        final String productName = (stock['product_name'] ?? "").toString();
        final String supplierName = (stock['supplier']?['name'] ?? "").toString();
        final String category = (stock['category']?['name'] ?? "").toString();
        final String description = (stock['description'] ?? "").toString();
        
        final variants = stock['variants'] ?? [];
        for (final variant in variants) {
          if (variant is! Map) continue;
          final String recordId = (variant['id'] ?? "").toString();
          final String typeId = (variant['variant_id'] ?? "").toString();
          final int vQty = int.tryParse((variant['qty'] ?? "0").toString()) ?? 0;
          final double vPrice = double.tryParse((variant['selling_price'] ?? "0").toString()) ?? 0;
          final int totalQty = int.tryParse((variant['total_qty'] ?? variant['qty'] ?? "0").toString()) ?? 0;
          bool isReq = totalQty == 0;

          String label = "";
          if (typeId == "1") {
            label = "Original";
          } else if (typeId == "2") {
            label = "Import";
          } else if (typeId == "3") {
            label = "Complimentary";
          } else if (variant['variant'] != null && variant['variant']['name'] != null) {
            label = variant['variant']['name'].toString();
          } else if (variant['name'] != null) {
            label = variant['name'].toString();
          } else {
            label = "Variant $typeId";
          }

          list.add(ProductStock(
            stockId: stockId,
            productId: (stock['product_id'] ?? "").toString(),
            variantId: recordId,
            variantTypeId: typeId,
            productName: productName,
            supplierName: supplierName,
            category: category,
            variant: label,
            qty: vQty, 
            unitPrice: vPrice, 
            total: vQty * vPrice, 
            isRequest: isReq,
            description: description,
            sku: (variant['sku'] ?? "").toString(),
          ));
        }
      }

      final searchText = query.trim().toLowerCase();
      if (searchText.isNotEmpty) {
        List<ProductStock> startsWithList = [];
        List<ProductStock> containsList = [];

        for (final item in list) {
          String searchField = "";
          if (productSearchBy == "SKU") {
            searchField = item.sku.toLowerCase();
          } else if (productSearchBy == "Category") {
            searchField = item.category.toLowerCase();
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
      AppLogger.error("fetchProductAllocations error", e);
      return [];
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
