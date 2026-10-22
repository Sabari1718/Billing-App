part of 'sales_point.dart';

extension _SalesPointPageStateWidgets on _SalesPointPageState {
  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sales Point & Product Selection",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Browse in-stock products, apply category & brand filters, and process sales entries.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildStatBadge(
                icon: Icons.inventory_2_outlined,
                label: "In-Stock Products: ${allStocks.length}",
                bg: Colors.grey.shade100,
                borderCol: Colors.grey.shade300,
                textCol: Colors.grey.shade700,
              ),
              _buildStatBadge(
                icon: Icons.shopping_cart_outlined,
                label: "Selected Items: $totalSelectedItems (₹${totalSelectedAmount.toStringAsFixed(0)})",
                bg: AppColors.secondary.withOpacity(0.08),
                borderCol: AppColors.secondary.withOpacity(0.2),
                textCol: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required Color bg,
    required Color borderCol,
    required Color textCol,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textCol),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final bool showSideBySide = w > 500;

          final Widget textField = TextField(
            controller: searchController,
            onChanged: (val) {
              setState(() {
                searchQuery = val;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: "Search stock products by name, SKU, code, brand, or category...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          );

          final Widget limitDropdown = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Show", style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: itemsPerPage,
                    items: [10, 20, 50].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text("$value", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          itemsPerPage = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text("items per page", style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
            ],
          );

          if (showSideBySide) {
            return Row(
              children: [
                Expanded(child: textField),
                const SizedBox(width: 16),
                limitDropdown,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textField,
                const SizedBox(height: 12),
                Center(child: limitDropdown),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildFiltersCard(List<String> categories, List<String> brands, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final double w = constraints.maxWidth;
              final bool isVertical = w < 580;

              final List<Widget> filterWidgets = [
                Expanded(
                  flex: isVertical ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          const Text("CATEGORY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildFilterDropdown(
                        value: selectedCategory,
                        hint: "All Categories (${allStocks.length})",
                        items: [
                          DropdownMenuItem<String>(
                            value: "All Categories",
                            child: Text("All Categories (${allStocks.length})"),
                          ),
                          ...categories.map((cat) {
                            final count = allStocks.where((s) => s.category == cat).length;
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text("$cat ($count)"),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedCategory = val == "All Categories" ? null : val;
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (isVertical) const SizedBox(height: 12) else const SizedBox(width: 12),

                Expanded(
                  flex: isVertical ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_outlined, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text("SECONDARY CATEGORY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.remove_red_eye_outlined, size: 10, color: Colors.grey),
                                SizedBox(width: 2),
                                Text("Disabled", style: TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildDisabledDropdown("-- Disabled --"),
                    ],
                  ),
                ),
                if (isVertical) const SizedBox(height: 12) else const SizedBox(width: 12),

                Expanded(
                  flex: isVertical ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.label_outline, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          const Text("BRAND", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildFilterDropdown(
                        value: selectedBrand,
                        hint: "All Brands (${allStocks.length})",
                        items: [
                          DropdownMenuItem<String>(
                            value: "All Brands",
                            child: Text("All Brands (${allStocks.length})"),
                          ),
                          ...brands.map((br) {
                            final count = allStocks.where((s) => s.brand == br).length;
                            return DropdownMenuItem<String>(
                              value: br,
                              child: Text("$br ($count)"),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedBrand = val == "All Brands" ? null : val;
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (isVertical) const SizedBox(height: 16) else const SizedBox(width: 16),

                SizedBox(
                  width: isVertical ? double.infinity : null,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.grey.shade50,
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text("Reset", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ];

              if (isVertical) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filterWidgets.map((w) {
                    if (w is Expanded) return w.child;
                    return w;
                  }).toList(),
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: filterWidgets,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDisabledDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No Products Found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Text(
            "There are no stock products matching the criteria.",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Clear Filters", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(double screenWidth, bool isMobile) {
    int crossAxisCount = 2;
    double childAspectRatio = 0.76;
    
    if (screenWidth < 450) {
      crossAxisCount = 1;
      childAspectRatio = 1.35;
    } else if (screenWidth < 750) {
      crossAxisCount = 2;
      childAspectRatio = 0.8;
    } else if (screenWidth < 1100) {
      crossAxisCount = 3;
      childAspectRatio = 0.82;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 0.85;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: filteredStocks.length,
      itemBuilder: (context, index) {
        final item = filteredStocks[index];
        return _buildProductCard(item, screenWidth < 450);
      },
    );
  }

  Widget _buildProductCard(StockItem item, bool isSingleColumnMobile) {
    return InkWell(
      onTap: () => _showProductDetails(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isSingleColumnMobile
            ? Row(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey.shade400),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.variantLabel.isNotEmpty && item.variantLabel != "Standard")
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.variantLabel,
                                      style: const TextStyle(color: AppColors.secondary, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "₹${item.sellingPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    "₹${item.mrp.toStringAsFixed(0)}",
                                    style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey.shade400, fontSize: 11),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => addToBill(item, 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  elevation: 0,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 14),
                                    Text("Add", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey.shade50,
                      child: Center(
                        child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.variantLabel.isNotEmpty && item.variantLabel != "Standard")
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.variantLabel,
                                      style: const TextStyle(color: AppColors.secondary, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "₹${item.sellingPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "₹${item.mrp.toStringAsFixed(0)}",
                                    style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey.shade400, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () => addToBill(item, 1),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text("Add to Bill", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
