part of 'viewpage.dart';

mixin ProductAllocationLogic on State<ProductAllocationPage> {
  List products = [];
  bool isLoading = true;

  final String baseUrl = "https://billing.srivagroups.in/api/productAllocation";

  String token = "";
  String role = "business";
  String userName = "";

  @override
  void initState() {
    super.initState();
    loadTokenAndFetch();
  }

  Future<void> loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("billing_auth_token") ??
        prefs.getString("auth_token") ??
        prefs.getString("token") ??
        "";
    role = prefs.getString("role")?.toLowerCase() ?? "propagater";
    userName = prefs.getString("user_name") ?? "";

    // Fallback if role is not set yet
    if (prefs.getString("role") == null) {
      final userJson = prefs.getString("user");
      if (userJson != null) {
        try {
          final Map<String, dynamic> user = json.decode(userJson);
          String rawRole = user['role']?.toString().toLowerCase() ?? "business";
          role = (rawRole == "business") ? "propagater" : rawRole;
          userName = user['name']?.toString() ?? "";
        } catch (e) {
          debugPrint("Error parsing user json: $e");
        }
      }
    }

    await fetchProducts();
  }

  // ✅ FETCH PRODUCTS
  Future<void> fetchProducts() async {
    try {
      setState(() => isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString("billing_auth_token") ??
          prefs.getString("auth_token") ??
          prefs.getString("token") ??
          token;

      String cleanToken = token.trim();
      if (cleanToken.startsWith("Bearer ")) {
        cleanToken = cleanToken.substring(7).trim();
      }

      final bId = prefs.getString("selected_business_id") ??
          prefs.get("business_id")?.toString() ??
          "52";

      final headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-App-ID": "Product94674",
        if (cleanToken.isNotEmpty) "Authorization": "Bearer $cleanToken",
        if (bId.isNotEmpty) "x-business-id": bId,
      };

      // 1. Primary Request: Exact URL as in Web (no query params)
      String url = baseUrl;
      debugPrint("viewpage fetchProducts calling: $url with bId: $bId");
      var res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
      debugPrint("viewpage fetchProducts [$url] [${res.statusCode}]: ${res.body.length} chars");

      // Auto-relogin if unauthorized
      if (res.statusCode == 401) {
        final cachedEmail = prefs.getString("cached_email") ?? "";
        final cachedPassword = prefs.getString("cached_password") ?? "";
        if (cachedEmail.isNotEmpty && cachedPassword.isNotEmpty) {
          try {
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
                cleanToken = newToken.startsWith("Bearer ") ? newToken.substring(7).trim() : newToken.trim();
                await prefs.setString("billing_auth_token", cleanToken);
                await prefs.setString("auth_token", cleanToken);
                headers["Authorization"] = "Bearer $cleanToken";
                res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
              }
            }
          } catch (_) {}
        }
      }

      List finalList = [];

      void parseResponse(dynamic bodyStr) {
        try {
          final decoded = jsonDecode(bodyStr);
          final rawData = decoded['data'] ?? decoded;

          if (rawData is List) {
            for (var group in rawData) {
              if (group is! Map) continue;
              final supplierName = (group['brand_name'] ?? group['supplier_name'] ?? group['supplier']?['name'] ?? "Imported").toString();

              final categories = group['Categories'];
              if (categories != null && categories is Map) {
                void processList(dynamic pListRaw, dynamic catId) {
                  if (pListRaw is! List) return;
                  for (var product in pListRaw) {
                    if (product is! Map) continue;
                    finalList.add({
                      "id": product['allocation_id'] ?? product['id'],
                      "category_group_id": group['CategoryGroupId'],
                      "category_id": catId,
                      "brand_id": product['brand_id'],
                      "product_id": product['product_id'] ?? product['id'],
                      "name": product['product_name'] ?? product['name'] ?? "No Name",
                      "code": product['product_code'] ?? product['code'] ?? product['extra_product_code'] ?? "-",
                      "min": product['min_qty'] ?? product['Qty']?['min'] ?? 0,
                      "max": product['max_qty'] ?? product['Qty']?['max'] ?? 0,
                      "supplier_name": supplierName,
                      "mrp": product['mrp'],
                      "base_image": product['base_image'],
                      "raw": product,
                    });
                  }
                }

                for (var primary in (categories['primary'] ?? [])) {
                  if (primary is! Map) continue;
                  for (var brand in (primary['Brand'] ?? [])) {
                    if (brand is! Map) continue;
                    processList(brand['Products'] ?? [], primary['id']);
                  }
                }

                for (var secondary in (categories['secondary'] ?? [])) {
                  if (secondary is! Map) continue;
                  for (var brand in (secondary['Brand'] ?? [])) {
                    if (brand is! Map) continue;
                    processList(brand['Products'] ?? [], secondary['id']);
                  }
                }
              } else {
                // Direct flat product item in list (as in Web)
                finalList.add({
                  "id": group['allocation_id'] ?? group['id'],
                  "category_group_id": group['CategoryGroupId'] ?? group['category_group_id'],
                  "category_id": group['category_id'] ?? group['secondary_category_id'] ?? group['primary_category_id'],
                  "brand_id": group['brand_id'],
                  "product_id": group['product_id'] ?? group['id'],
                  "name": group['product_name'] ?? group['name'] ?? "No Name",
                  "code": group['product_code'] ?? group['code'] ?? group['extra_product_code'] ?? "-",
                  "min": group['min_qty'] ?? group['Qty']?['min'] ?? group['min'] ?? 0,
                  "max": group['max_qty'] ?? group['Qty']?['max'] ?? group['max'] ?? 0,
                  "supplier_name": supplierName,
                  "mrp": group['mrp'],
                  "base_image": group['base_image'],
                  "raw": group,
                });
              }
            }
          }
        } catch (e) {
          debugPrint("viewpage parseResponse error: $e");
        }
      }

      if (res.statusCode == 200) {
        parseResponse(res.body);
      }

      // 2. Fallback: If clean URL returned 0 products, try with ?business_id query param
      if (finalList.isEmpty && bId.isNotEmpty) {
        final queryUrl = "$baseUrl?business_id=$bId";
        debugPrint("viewpage fallback calling: $queryUrl");
        final qRes = await http.get(Uri.parse(queryUrl), headers: headers).timeout(const Duration(seconds: 15));
        if (qRes.statusCode == 200) {
          parseResponse(qRes.body);
        }
      }

      if (!mounted) return;
      setState(() {
        products = finalList;
        isLoading = false;
      });
    } catch (e, stack) {
      AppLogger.error("fetchProducts error", e, stack);
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ DELETE PRODUCT
  Future<void> deleteProduct(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentToken = prefs.getString("billing_auth_token") ??
          prefs.getString("auth_token") ??
          token;

      final res = await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-App-ID": "Product94674",
          if (currentToken.isNotEmpty) "Authorization": "Bearer $currentToken",
        },
      );

      debugPrint("deleteProduct [$id] Status: ${res.statusCode}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Deleted Successfully ✅")),
          );
        }
        await fetchProducts();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Delete Failed ❌")),
          );
        }
      }
    } catch (e, stack) {
      debugPrint("deleteProduct error: $e, stack: $stack");
    }
  }

  // ✅ UPDATE PRODUCT
  Future<void> updateProduct(
    int id,
    int categoryGroupId,
    int categoryId,
    int brandId,
    String name,
    String min,
    String max,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.get("business_id");
      final int setupId = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
      final currentToken = prefs.getString("billing_auth_token") ??
          prefs.getString("auth_token") ??
          token;

      final payload = {
        "allocation_id": id,
        "setup_id": setupId,
        "category_group_id": categoryGroupId,
        "category_id": categoryId,
        "brand_id": brandId,
        "product_name": name,
        "min_sale_qty": int.tryParse(min) ?? 0,
        "max_sale_qty": int.tryParse(max) ?? 0,
      };

      final res = await http.put(
        Uri.parse("$baseUrl/$id"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-App-ID": "Product94674",
          if (currentToken.isNotEmpty) "Authorization": "Bearer $currentToken",
        },
        body: jsonEncode(payload),
      );

      debugPrint("updateProduct [$id] Status: ${res.statusCode}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Updated Successfully ✅")),
        );
        await fetchProducts();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update Failed ❌")),
        );
      }
    } catch (e, stack) {
      debugPrint("updateProduct error: $e, stack: $stack");
    }
  }
}
