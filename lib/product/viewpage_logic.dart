part of 'viewpage.dart';

mixin ProductAllocationLogic on State<ProductAllocationPage> {
  List products = [];
  bool isLoading = true;

  final String baseUrl = "https://billing.srivagroups.in/api/productAllocation";

  String token = "";

  @override
  void initState() {
    super.initState();
    loadTokenAndFetch();
  }

  String role = "business";
  String userName = "";

  Future<void> loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? "";
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
          debugPrint("Error parsing user json: \$e");
        }
      }
    }
    
    fetchProducts();
  }

// ✅ FETCH PRODUCTS
  Future<void> fetchProducts() async {
    try {
      setState(() => isLoading = true);

      final res = await http.get(
        Uri.parse(baseUrl),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer \$token",
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        List finalList = [];

        final data = decoded['data'] ?? [];

        for (var group in data) {
          final supplierName = group['supplier_name'] ?? group['supplier']?['name'] ?? "Unknown Supplier";
          
          // 🔥 FRONTEND FILTERING BASED ON ROLE
          // propagater/business sees everything. supplier/partner only see their own records.
          if ((role == "supplier" || role == "partner") && userName.isNotEmpty) {
            if (!supplierName.toLowerCase().contains(userName.toLowerCase())) {
              continue;
            }
          }

          final categories = group['Categories'] ?? {};

          // PRIMARY
          for (var primary in (categories['primary'] ?? [])) {
            for (var brand in (primary['Brand'] ?? [])) {
              for (var product in (brand['Products'] ?? [])) {
                finalList.add({
                  "id": product['allocation_id'],
                  "category_group_id": group['CategoryGroupId'],
                  "category_id": primary['id'],
                  "brand_id": brand['id'],
                  "product_id": product['id'],
                  "name": product['name'] ?? "No Name",
                  "code": product['product_code'] ?? product['code'] ?? "-",
                  "min": product['Qty']?['min'] ?? 0,
                  "max": product['Qty']?['max'] ?? 0,
                  "supplier_name": supplierName,
                });
              }
            }
          }

          // SECONDARY
          for (var secondary in (categories['secondary'] ?? [])) {
            for (var brand in (secondary['Brand'] ?? [])) {
              for (var product in (brand['Products'] ?? [])) {
                finalList.add({
                  "id": product['allocation_id'],
                  "category_group_id": group['CategoryGroupId'],
                  "category_id": secondary['id'],
                  "brand_id": brand['id'],
                  "product_id": product['id'],
                  "name": product['name'] ?? "No Name",
                  "code": product['product_code'] ?? product['code'] ?? "-",
                  "min": product['Qty']?['min'] ?? 0,
                  "max": product['Qty']?['max'] ?? 0,
                  "supplier_name": supplierName,
                });
              }
            }
          }
        }

        if (!mounted) return;

        setState(() {
          products = finalList;
          isLoading = false;
        });

      } else {
        setState(() => isLoading = false);
      }

    } catch (e, stack) {
      AppLogger.error("fetchProducts error", e, stack);
      setState(() => isLoading = false);
    }
  }

// ✅ DELETE PRODUCT
  Future<void> deleteProduct(int id) async {

    try {

      print("==================================================");
      print("[DELETE BUTTON CLICKED]");
      print("==================================================");
      print("ALLOCATION ID => \$id");
      print("==================================================");

      print("==================================================");
      print("[DELETE API REQUEST]");
      print("==================================================");
      print("METHOD => DELETE");
      print("URL => \$baseUrl/\$id");
      print("==================================================");

      final res = await http.delete(
        Uri.parse("\$baseUrl/\$id"),
        headers: {
          "Authorization": "Bearer \$token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      print("==================================================");
      print("[DELETE API RESPONSE]");
      print("==================================================");
      print("STATUS CODE => \${res.statusCode}");
      print("BODY => \${res.body}");
      print("==================================================");

      if (res.statusCode == 200 ||
          res.statusCode == 201) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Deleted Successfully ✅"),
          ),
        );

        fetchProducts();

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Delete Failed ❌"),
          ),
        );
      }

    } catch (e, stack) {

      print("==================================================");
      print("[DELETE ERROR]");
      print("==================================================");
      print(e);
      print(stack);
      print("==================================================");
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

      print("==================================================");
      print("[UPDATE BUTTON CLICKED]");
      print("==================================================");
      print("ALLOCATION ID => \$id");
      print("PRODUCT NAME => \$name");
      print("MIN => \$min");
      print("MAX => \$max");
      print("==================================================");

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.get("business_id");
      final int setupId = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;

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

      print("==================================================");
      print("[UPDATE PAYLOAD]");
      print("==================================================");
      print(payload);
      print("==================================================");

      print("==================================================");
      print("[UPDATE API REQUEST]");
      print("==================================================");
      print("METHOD => PUT");
      print("URL => \$baseUrl/\$id");
      print("==================================================");

      final res = await http.put(
        Uri.parse("\$baseUrl/\$id"),
        headers: {
          "Authorization": "Bearer \$token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      print("==================================================");
      print("[UPDATE API RESPONSE]");
      print("==================================================");
      print("STATUS CODE => \${res.statusCode}");
      print("BODY => \${res.body}");
      print("==================================================");

      if (res.statusCode == 200 ||
          res.statusCode == 201) {

        if (!mounted) return;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Updated Successfully ✅"),
          ),
        );

        fetchProducts();

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Update Failed ❌"),
          ),
        );
      }

    } catch (e, stack) {

      print("==================================================");
      print("[UPDATE ERROR]");
      print("==================================================");
      print(e);
      print(stack);
      print("==================================================");
    }
  }
}
