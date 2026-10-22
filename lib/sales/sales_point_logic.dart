part of 'sales_point.dart';

extension _SalesPointPageStateLogic on _SalesPointPageState {
  Future<void> fetchStocks({String query = ""}) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("billing_auth_token") ?? 
                    prefs.getString("auth_token") ?? 
                    prefs.getString("token") ?? "";
      final businessId = prefs.get("business_id")?.toString() ?? 
                         prefs.getString("selected_business_id") ?? "";
      final role = prefs.getString("role")?.toLowerCase() ?? 
                   prefs.getString("business_type")?.toLowerCase() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      String url = "https://billing.srivagroups.in/api/w_variant/stock";
      List<String> params = [];
      if (query.isNotEmpty) {
        params.add("search=${Uri.encodeComponent(query)}");
      }
      if (role == "supplier" || role == "partner") {
        if (businessId.isNotEmpty) params.add("business_id=$businessId");
        if (uId.isNotEmpty) params.add("user_main_id=$uId");
      } else if (role == "propagator" || role == "propagater" || role == "admin") {
        // admin role: load all
      } else if (businessId.isNotEmpty) {
        params.add("business_id=$businessId");
      }
      
      if (params.isNotEmpty) {
        url += "?${params.join('&')}";
      }

      AppLogger.info("SalesPoint fetching stocks from: $url");
      
      var response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      AppLogger.api("GET", url, response.statusCode);

      if (response.statusCode == 400 && url.contains("business_id=")) {
        AppLogger.warning("Stocks API returned 400. Retrying fallback without business_id...");
        String fallbackUrl = "https://billing.srivagroups.in/api/w_variant/stock";
        if (query.isNotEmpty) {
          fallbackUrl += "?search=${Uri.encodeComponent(query)}";
        }
        url = fallbackUrl;
        response = await http.get(
          Uri.parse(fallbackUrl),
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        ).timeout(const Duration(seconds: 15));
        AppLogger.api("GET", fallbackUrl, response.statusCode);
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        dynamic data = decoded['data'] ?? decoded;
        List<dynamic> rawStocks = [];
        if (data is List) {
          rawStocks = data;
        } else if (data is Map && data['data'] is List) {
          rawStocks = data['data'];
        }

        List<StockItem> parsedItems = [];
        for (final stock in rawStocks) {
          if (stock is! Map) continue;
          
          final String stockId = (stock['id'] ?? stock['stock_id'] ?? "").toString();
          final String productId = (stock['product_id'] ?? stock['product']?['id'] ?? "").toString();
          final String productName = (stock['product_name'] ?? 
                                      stock['product']?['name'] ?? 
                                      stock['name'] ?? 
                                      stock['product_title'] ?? 
                                      stock['title'] ?? 
                                      "Unnamed Product").toString();
          final String supplierName = (stock['supplier']?['name'] ?? stock['supplier_name'] ?? "").toString();
          
          String category = "";
          if (stock['category'] is Map) {
            category = (stock['category']['name'] ?? "").toString();
          } else if (stock['category'] != null) {
            category = stock['category'].toString();
          } else if (stock['category_name'] != null) {
            category = stock['category_name'].toString();
          }
          if (category.isEmpty) category = "General";
          
          String brand = "";
          if (stock['brand'] is Map) {
            brand = (stock['brand']['name'] ?? "").toString();
          } else if (stock['brand'] != null) {
            brand = stock['brand'].toString();
          } else if (stock['brand_name'] != null) {
            brand = stock['brand_name'].toString();
          } else if (stock['product']?['brand']?['name'] != null) {
            brand = stock['product']?['brand']?['name'].toString() ?? "";
          } else if (stock['product']?['brand_name'] != null) {
            brand = stock['product']?['brand_name'].toString() ?? "";
          }
          if (brand.isEmpty) brand = "Generic";
                                
          final String description = (stock['description'] ?? "").toString();
          
          final variants = stock['variants'] ?? [];
          if (variants is List && variants.isNotEmpty) {
            for (final variant in variants) {
              if (variant is! Map) continue;
              final String variantId = (variant['id'] ?? variant['variant_id'] ?? "").toString();
              final String variantTypeId = (variant['variant_id'] ?? variant['variant_type_id'] ?? "").toString();
              
              String variantLabel = "";
              if (variantTypeId == "1") {
                variantLabel = "Original";
              } else if (variantTypeId == "2") {
                variantLabel = "Import";
              } else if (variantTypeId == "3") {
                variantLabel = "Complimentary";
              } else {
                variantLabel = (variant['variant']?['name'] ?? 
                                variant['name'] ?? 
                                variant['variant_name'] ?? 
                                variant['variant_label'] ??
                                variant['label'] ??
                                "Variant $variantTypeId").toString();
              }
              
              final int qty = int.tryParse((variant['qty'] ?? variant['quantity'] ?? "0").toString()) ?? 
                              int.tryParse((stock['qty'] ?? stock['quantity'] ?? "0").toString()) ?? 0;
              final int totalQty = int.tryParse((variant['total_qty'] ?? variant['qty'] ?? "0").toString()) ?? 
                                   int.tryParse((stock['total_qty'] ?? stock['qty'] ?? "0").toString()) ?? 0;
              final double sellingPrice = double.tryParse((variant['selling_price'] ?? variant['price'] ?? variant['unit_price'] ?? variant['sellingPrice'] ?? "0").toString()) ?? 
                                          double.tryParse((stock['selling_price'] ?? stock['price'] ?? "0").toString()) ?? 0.0;
              final double mrp = double.tryParse((variant['mrp'] ?? variant['original_price'] ?? "").toString()) ?? 
                                 double.tryParse((stock['mrp'] ?? stock['original_price'] ?? "").toString()) ?? 
                                 (sellingPrice * 1.25);
              final String sku = (variant['sku'] ?? variant['product_sku'] ?? variant['sku_code'] ?? stock['sku'] ?? "").toString();
              final String barcode = (variant['barcode'] ?? variant['barcode_number'] ?? variant['code'] ?? stock['barcode'] ?? "").toString();

              parsedItems.add(StockItem(
                stockId: stockId,
                productId: productId,
                variantId: variantId,
                variantTypeId: variantTypeId,
                name: productName,
                supplierName: supplierName,
                category: category,
                brand: brand,
                sku: sku,
                barcode: barcode,
                variantLabel: variantLabel,
                qty: qty,
                totalQty: totalQty,
                sellingPrice: sellingPrice,
                mrp: mrp,
                description: description,
              ));
            }
          } else {
            final double sellingPrice = double.tryParse((stock['selling_price'] ?? stock['price'] ?? stock['unit_price'] ?? stock['sellingPrice'] ?? "0").toString()) ?? 0.0;
            final double mrp = double.tryParse((stock['mrp'] ?? stock['original_price'] ?? "").toString()) ?? (sellingPrice * 1.25);
            final String variantId = (stock['variant_id'] ?? stock['variant']?['id'] ?? "").toString();
            final String variantTypeId = (stock['variant_type_id'] ?? "").toString();
            String variantLabel = (stock['variant']?['name'] ?? 
                                   stock['variant_name'] ?? 
                                   stock['variant_label'] ?? 
                                   stock['label'] ?? 
                                   "Standard").toString();
            if (variantLabel == "Standard" && variantTypeId.isNotEmpty) {
              variantLabel = "Variant $variantTypeId";
            }
            
            parsedItems.add(StockItem(
              stockId: stockId,
              productId: productId,
              variantId: variantId,
              variantTypeId: variantTypeId,
              name: productName,
              supplierName: supplierName,
              category: category,
              brand: brand,
              sku: (stock['sku'] ?? stock['product_sku'] ?? stock['sku_code'] ?? "").toString(),
              barcode: (stock['barcode'] ?? stock['barcode_number'] ?? stock['code'] ?? "").toString(),
              variantLabel: variantLabel,
              qty: int.tryParse((stock['qty'] ?? stock['quantity'] ?? stock['available_qty'] ?? "0").toString()) ?? 0,
              totalQty: int.tryParse((stock['total_qty'] ?? stock['qty'] ?? stock['quantity'] ?? "0").toString()) ?? 0,
              sellingPrice: sellingPrice,
              mrp: mrp,
              description: description,
            ));
          }
        }

        if (mounted) {
          setState(() {
            allStocks = parsedItems;
            _applyFilters();
            isLoading = false;
          });
        }
      } else {
        AppLogger.error("Failed to fetch stocks: status code ${response.statusCode}");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e, stack) {
      AppLogger.error("fetchStocks error", e, stack);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<StockItem> results = allStocks;
    
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results.where((item) {
        return item.name.toLowerCase().contains(q) ||
               item.sku.toLowerCase().contains(q) ||
               item.barcode.toLowerCase().contains(q) ||
               item.category.toLowerCase().contains(q) ||
               item.brand.toLowerCase().contains(q);
      }).toList();
    }
    
    if (selectedCategory != null && selectedCategory != "All Categories") {
      results = results.where((item) => item.category == selectedCategory).toList();
    }
    
    if (selectedBrand != null && selectedBrand != "All Brands") {
      results = results.where((item) => item.brand == selectedBrand).toList();
    }
    
    if (mounted) {
      setState(() {
        filteredStocks = results;
      });
    }
  }

  void _resetFilters() {
    searchController.clear();
    if (mounted) {
      setState(() {
        searchQuery = "";
        selectedCategory = null;
        selectedBrand = null;
        _applyFilters();
      });
    }
  }

  Future<void> addToBill(StockItem item, int quantity) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("billing_auth_token") ?? 
                    prefs.getString("auth_token") ?? 
                    prefs.getString("token") ?? "";
      final businessId = prefs.get("business_id")?.toString() ?? 
                         prefs.getString("selected_business_id") ?? "";

      const url = "https://billing.srivagroups.in/api/bill-add-product";
      
      final Map<String, dynamic> body = {
        "business_id": int.tryParse(businessId) ?? businessId,
        "stock_id": int.tryParse(item.stockId) ?? item.stockId,
        "product_id": int.tryParse(item.productId) ?? item.productId,
        "variant_id": int.tryParse(item.variantId) ?? item.variantId,
        "qty": quantity,
        "quantity": quantity,
        "unit_price": item.sellingPrice,
        "selling_price": item.sellingPrice,
        "total": quantity * item.sellingPrice,
        "product_name": item.name,
        "variant": item.variantLabel,
        "sku": item.sku,
      };

      AppLogger.info("Adding to bill payload: ${json.encode(body)}");
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      AppLogger.api("POST", url, response.statusCode, body: response.body);

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            totalSelectedItems += quantity;
            totalSelectedAmount += (quantity * item.sellingPrice);
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${item.name} ($quantity Unit${quantity > 1 ? 's' : ''}) added to bill successfully!",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        String errMsg = "Failed to add product: ${response.statusCode}";
        try {
          final decoded = json.decode(response.body);
          if (decoded['message'] != null) {
            errMsg = decoded['message'];
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errMsg)),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.error("addToBill error", e, stack);
      if (mounted) Navigator.pop(context); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text("Network Error: $e")),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
