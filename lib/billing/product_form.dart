import 'package:flutter/material.dart';
import 'package:billingapp/theme.dart';

// ---------------------------------------------------
// MOBILE-FRIENDLY MODAL SEARCHABLE PRODUCT DROPDOWN
// ---------------------------------------------------
class SearchableProductDropdown extends StatefulWidget {
  final List<dynamic> products;
  final Map<String, dynamic>? selectedProduct;
  final ValueChanged<Map<String, dynamic>?> onSelected;
  final bool isLoading;

  const SearchableProductDropdown({
    super.key,
    required this.products,
    required this.selectedProduct,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  State<SearchableProductDropdown> createState() => _SearchableProductDropdownState();
}

class _SearchableProductDropdownState extends State<SearchableProductDropdown> {
  String searchQuery = "";

  void _showProductSearchSheet(BuildContext context) {
    searchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = widget.products.where((p) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.toLowerCase();
              final name = p['product_name'].toString().toLowerCase();
              final sku = p['sku'].toString().toLowerCase();
              final category = p['category_name'].toString().toLowerCase();
              return name.contains(q) || sku.contains(q) || category.contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Swipe Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Select Product",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Search Field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged: (val) {
                            setSheetState(() {
                              searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search by product name, category...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // List of products
                      Expanded(
                        child: widget.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      "No products found",
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final product = filtered[index];
                                      final String name = (product['product_name'] ?? product['name'] ?? "Unknown").toString().trim();
                                      final String sku = (product['sku'] ?? "").toString().trim();
                                      final String category = (product['category_name'] ?? "").toString();

                                      return InkWell(
                                        onTap: () {
                                          widget.onSelected(product);
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              if (sku.isNotEmpty || category.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  [
                                                    if (category.isNotEmpty) category,
                                                    if (sku.isNotEmpty) "SKU: $sku"
                                                  ].join("  •  "),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showProductSearchSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: widget.selectedProduct != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (widget.selectedProduct!['product_name'] ?? widget.selectedProduct!['name'] ?? "").toString(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((widget.selectedProduct!['sku'] ?? "").toString().isNotEmpty)
                              Text(
                                (widget.selectedProduct!['sku']).toString(),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        )
                      : const Text(
                          "-- Select Product --",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.selectedProduct != null)
                      GestureDetector(
                        onTap: () {
                          widget.onSelected(null);
                        },
                        child: Icon(Icons.close, color: Colors.grey.shade500, size: 18),
                      ),
                    if (widget.selectedProduct != null) const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
