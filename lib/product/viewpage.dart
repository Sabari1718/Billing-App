import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

class ProductAllocationPage extends StatefulWidget {
  const ProductAllocationPage({super.key});

  @override
  State<ProductAllocationPage> createState() =>
      _ProductAllocationPageState();
}

class _ProductAllocationPageState extends State<ProductAllocationPage> {
  List products = [];
  bool isLoading = true;

  final String baseUrl =
      "https://billing.srivagroups.in/api/productAllocation";

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
          debugPrint("Error parsing user json: $e");
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
          "Authorization": "Bearer $token",
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
      print("ALLOCATION ID => $id");
      print("==================================================");

      print("==================================================");
      print("[DELETE API REQUEST]");
      print("==================================================");
      print("METHOD => DELETE");
      print("URL => $baseUrl/$id");
      print("==================================================");

      final res = await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      print("==================================================");
      print("[DELETE API RESPONSE]");
      print("==================================================");
      print("STATUS CODE => ${res.statusCode}");
      print("BODY => ${res.body}");
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
      print("ALLOCATION ID => $id");
      print("PRODUCT NAME => $name");
      print("MIN => $min");
      print("MAX => $max");
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
      print("URL => $baseUrl/$id");
      print("==================================================");

      final res = await http.put(
        Uri.parse("$baseUrl/$id"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      print("==================================================");
      print("[UPDATE API RESPONSE]");
      print("==================================================");
      print("STATUS CODE => ${res.statusCode}");
      print("BODY => ${res.body}");
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

  // ✅ EDIT POPUP
  void showEditDialog(Map item) {
    TextEditingController name = TextEditingController(text: item['name']);
    TextEditingController min = TextEditingController(text: item['min'].toString());
    TextEditingController max = TextEditingController(text: item['max'].toString());

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Update Product",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: "Product Name",
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: min,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: "Min Qty",
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: max,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: "Max Qty",
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              updateProduct(
                                item['id'],
                                item['category_group_id'] ?? 0,
                                item['category_id'] ?? 0,
                                item['brand_id'] ?? 0,
                                name.text,
                                min.text,
                                max.text,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text(
                              "Update",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 SMALL UI HELPERS
  void confirmDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, size: 40, color: Colors.red.shade600),
              ),
              const SizedBox(height: 20),
              const Text(
                "Delete Product?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to delete this product allocation? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        deleteProduct(id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget qtyBox(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text("$value", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget actionBtn(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern slate-50 background
      appBar: AppBar(
        title: const Text(
          "Allocated Products",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: "Refresh List",
              onPressed: fetchProducts,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.white,
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 3, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 24),
                    Text(
                      "Loading products...",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              )
            : products.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          size: 72,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "No products found",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Allocated products will appear here.\nPull down to refresh.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final item = products[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.widgets_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.black87,
                                        letterSpacing: -0.5,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Allocation ID: ${item['id']}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: qtyBox("MIN QTY", item['min'] ?? 0)),
                              const SizedBox(width: 12),
                              Expanded(child: qtyBox("MAX QTY", item['max'] ?? 0)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            color: Colors.grey.shade100,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => showEditDialog(item),
                                  icon: Icon(Icons.edit_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                                  label: Text("Edit", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => confirmDeleteDialog(item['id']),
                                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade600),
                                  label: Text("Delete", style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: Colors.red.shade200),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: Colors.red.shade50,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}