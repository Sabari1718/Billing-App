part of 'create_purchase_order.dart';

// ---------------------------------------------------
// CUSTOM PAINTER FOR DASHED BORDER
// ---------------------------------------------------
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashedPath = Path();
    double distance = 0.0;
    
    for (var measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------
// SEARCHABLE SUPPLIER SELECTION BOTTOM SHEET
// ---------------------------------------------------
class SupplierSelectionBottomSheet extends StatefulWidget {
  final String token;
  final Function(Map<String, dynamic>) onSelected;

  const SupplierSelectionBottomSheet({super.key, required this.token, required this.onSelected});

  @override
  State<SupplierSelectionBottomSheet> createState() => _SupplierSelectionBottomSheetState();
}

class _SupplierSelectionBottomSheetState extends State<SupplierSelectionBottomSheet> {
  List allSuppliers = [];
  List filteredSuppliers = [];
  bool isLoading = true;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuppliers() async {
    const url = "https://billing.srivagroups.in/api/suppliers/";
    try {
      final res = await http.get(Uri.parse(url), headers: {
        "Authorization": "Bearer \${widget.token}",
        "Accept": "application/json",
      });

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final listData = decoded['data']?['data']?['data'] ?? decoded['data'] ?? decoded;
        if (listData is List) {
          setState(() {
            allSuppliers = listData;
            filteredSuppliers = listData;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      AppLogger.error("Fetch suppliers bottomsheet error", e);
      setState(() => isLoading = false);
    }
  }

  void _filterSuppliers(String q) {
    setState(() {
      searchQuery = q;
      if (q.trim().isEmpty) {
        filteredSuppliers = allSuppliers;
      } else {
        final query = q.toLowerCase();
        filteredSuppliers = allSuppliers.where((s) {
          final String sName = (s['supplier_name'] ?? "").toString().toLowerCase();
          final String cName = (s['company_name'] ?? "").toString().toLowerCase();
          final String phone = (s['primary_phone'] ?? "").toString().toLowerCase();
          return sName.contains(query) || cName.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Cancel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Supplier",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSuppliers,
              decoration: InputDecoration(
                hintText: "Search suppliers by name, company, or phone...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ),

          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSuppliers.isEmpty
                    ? Center(
                        child: Text(
                          "No suppliers found.",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = filteredSuppliers[index];
                          final String name = (supplier['supplier_name'] ?? "").toString().trim();
                          final String company = (supplier['company_name'] ?? "").toString().trim();
                          final String phone = (supplier['primary_phone'] ?? "").toString().trim();

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            title: Text(
                              name.isEmpty ? "No Name" : name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (company.isNotEmpty)
                                  Text(
                                    company,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                if (phone.isNotEmpty)
                                  Text(
                                    phone,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              widget.onSelected(supplier);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------
// SEARCHABLE PRODUCT SELECTION BOTTOM SHEET
// ---------------------------------------------------
class ProductSelectionBottomSheet extends StatefulWidget {
  final String token;
  final Function(Map<String, dynamic>) onSelected;

  const ProductSelectionBottomSheet({super.key, required this.token, required this.onSelected});

  @override
  State<ProductSelectionBottomSheet> createState() => _ProductSelectionBottomSheetState();
}

class _ProductSelectionBottomSheetState extends State<ProductSelectionBottomSheet> {
  List allProducts = [];
  List filteredProducts = [];
  bool isLoading = true;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    final List<String> urls = [
      "https://billing.srivagroups.in/api/stocks",
      "https://billing.srivagroups.in/api/supplierProduct",
      "https://billing.srivagroups.in/api/products"
    ];

    bool success = false;
    for (String url in urls) {
      if (success) break;
      try {
        final res = await http.get(Uri.parse(url), headers: {
          "Authorization": "Bearer \${widget.token}",
          "Accept": "application/json",
        });

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final listData = decoded['data']?['data']?['data'] ?? decoded['data'] ?? decoded;
          if (listData is List && listData.isNotEmpty) {
            List processedList = [];
            for (var item in listData) {
              if (item is! Map) continue;
              
              final variants = item['variants'];
              if (variants is List && variants.isNotEmpty) {
                for (var variant in variants) {
                  if (variant is! Map) continue;
                  
                  String variantLabel = "";
                  final typeId = (variant['variant_id'] ?? "").toString();
                  if (typeId == "1") {
                    variantLabel = "Original";
                  } else if (typeId == "2") {
                    variantLabel = "Import";
                  } else if (typeId == "3") {
                    variantLabel = "Complimentary";
                  } else if (variant['variant'] != null && variant['variant']['name'] != null) {
                    variantLabel = variant['variant']['name'].toString();
                  } else if (variant['name'] != null) {
                    variantLabel = variant['name'].toString();
                  }
                  
                  final String parentName = (item['product_name'] ?? item['name'] ?? "Unknown").toString();
                  final String displayName = variantLabel.isNotEmpty ? "\$parentName (\$variantLabel)" : parentName;
                  
                  processedList.add({
                    "id": item['id'] ?? item['product_id'] ?? "",
                    "variant_id": variant['id'] ?? "",
                    "product_name": displayName,
                    "name": displayName,
                    "sku": (variant['sku'] ?? item['sku'] ?? "").toString(),
                    "selling_price": (variant['selling_price'] ?? variant['price'] ?? item['selling_price'] ?? item['price'] ?? "0").toString(),
                    "price": (variant['selling_price'] ?? variant['price'] ?? item['selling_price'] ?? item['price'] ?? "0").toString(),
                    "category": item['category'],
                    "category_name": item['category_name'] ?? item['category']?['name'] ?? "",
                  });
                }
              } else {
                processedList.add({
                  "id": item['id'] ?? item['product_id'] ?? "",
                  "product_name": (item['product_name'] ?? item['name'] ?? "Unknown").toString(),
                  "name": (item['product_name'] ?? item['name'] ?? "Unknown").toString(),
                  "sku": (item['sku'] ?? "").toString(),
                  "selling_price": (item['selling_price'] ?? item['price'] ?? "0").toString(),
                  "price": (item['selling_price'] ?? item['price'] ?? "0").toString(),
                  "category": item['category'],
                  "category_name": item['category_name'] ?? item['category']?['name'] ?? "",
                });
              }
            }

            setState(() {
              allProducts = processedList;
              filteredProducts = processedList;
              isLoading = false;
            });
            success = true;
          }
        }
      } catch (e) {
        AppLogger.error("Fetch products bottomsheet fallback error for url: \$url", e);
      }
    }

    if (!success) {
      setState(() => isLoading = false);
    }
  }

  void _filterProducts(String q) {
    setState(() {
      searchQuery = q;
      if (q.trim().isEmpty) {
        filteredProducts = allProducts;
      } else {
        final query = q.toLowerCase();
        filteredProducts = allProducts.where((p) {
          final String pName = (p['product_name'] ?? p['name'] ?? "").toString().toLowerCase();
          final String sku = (p['sku'] ?? "").toString().toLowerCase();
          final String category = (p['category']?['name'] ?? p['category_name'] ?? "").toString().toLowerCase();
          return pName.contains(query) || sku.contains(query) || category.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Cancel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Product",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: "Search products by name, SKU, or category...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ),

          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          "No products found.",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final String name = (product['product_name'] ?? product['name'] ?? "Unknown").toString().trim();
                          final String sku = (product['sku'] ?? "").toString().trim();
                          final String priceStr = (product['selling_price'] ?? product['price'] ?? "0").toString();
                          final String category = (product['category']?['name'] ?? product['category_name'] ?? "").toString();

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Row(
                              children: [
                                if (category.isNotEmpty)
                                  Text(
                                    "\$category  •  ",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                if (sku.isNotEmpty)
                                  Text(
                                    "SKU: \$sku",
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: Text(
                              "₹\$priceStr",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                            ),
                            onTap: () {
                              widget.onSelected(product);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
