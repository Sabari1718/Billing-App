part of 'purchase_bill_entry.dart';

extension _PurchaseBillEntryPageStateStep2 on _PurchaseBillEntryPageState {
  Widget _buildStep2View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Add Product Row Box Header
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Add Product Row (Fill fields & Press Enter)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  InkWell(
                    onTap: _showCategoryBrandFilterDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (filterCategory != null || filterBrand != null)
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (filterCategory != null || filterBrand != null)
                              ? const Color(0xFF3B82F6)
                              : Colors.blue.shade100,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_alt_outlined, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            filterCategory != null || filterBrand != null
                                ? "Filtered (${[filterCategory, filterBrand].where((e) => e != null).join(', ')})"
                                : "Filter Category & Brand",
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: enableSecondaryName,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            enableSecondaryName = val ?? false;
                          });
                        },
                      ),
                      const Text("Enable Secondary Name", style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    ],
                  ),
                  const Text(
                    "Press Enter key anytime to add product",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Add Product Row Fields Form Container
        Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 600;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFormProductSelectField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormTextField("Primary Name", primaryNameController, "Primary Name...")),
                        if (enableSecondaryName) ...[
                          const SizedBox(width: 12),
                          Expanded(child: _buildFormTextField("Secondary Name", secondaryNameController, "Local / Secondary...")),
                        ],
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormTextField("Qty *", qtyController, "1", isNumeric: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormDropdownField("Unit", unitValue, ["Pcs", "Kgs", "Boxes", "Dozen", "Meters", "Liters"], (val) {
                          setState(() {
                            unitValue = val!;
                          });
                        })),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildFormProductSelectField(),
                        const SizedBox(height: 12),
                        _buildFormTextField("Primary Name", primaryNameController, "Primary Name..."),
                        if (enableSecondaryName) ...[
                          const SizedBox(height: 12),
                          _buildFormTextField("Secondary Name", secondaryNameController, "Local / Secondary..."),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildFormTextField("Qty *", qtyController, "1", isNumeric: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildFormDropdownField("Unit", unitValue, ["Pcs", "Kgs", "Boxes", "Dozen", "Meters", "Liters"], (val) {
                              setState(() {
                                unitValue = val!;
                              });
                            })),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 600;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFormDropdownField("GST % (Tax)", gstPercentValue, ["0%", "5%", "12%", "18%", "28%"], (val) {
                          setState(() {
                            gstPercentValue = val!;
                            _calculateFormValues();
                          });
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormTextField("Rate (Excl.) *", rateExclController, "0.00", isNumeric: true, onChanged: (_) => _calculateFormValues(fromExcl: true))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormTextField("Rate (Incl.)", rateInclController, "0.00", isNumeric: true, onChanged: (_) => _calculateFormValues(fromIncl: true))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormTextField("GST Amt", gstAmtController, "0", isNumeric: true, isEnabled: false)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildFormDropdownField("GST % (Tax)", gstPercentValue, ["0%", "5%", "12%", "18%", "28%"], (val) {
                              setState(() {
                                gstPercentValue = val!;
                                _calculateFormValues();
                              });
                            })),
                            const SizedBox(width: 12),
                            Expanded(child: _buildFormTextField("Rate (Excl.) *", rateExclController, "0.00", isNumeric: true, onChanged: (_) => _calculateFormValues(fromExcl: true))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildFormTextField("Rate (Incl.)", rateInclController, "0.00", isNumeric: true, onChanged: (_) => _calculateFormValues(fromIncl: true))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildFormTextField("GST Amt", gstAmtController, "0", isNumeric: true, isEnabled: false)),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 600;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _buildFormDiscountField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormTextField("Charges", chargesController, "0.00", isNumeric: true, onChanged: (_) => _calculateFormValues())),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormTextField("Taxable", taxableController, "0", isNumeric: true, isEnabled: false)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildFormTextField("Total", totalController, "0", isNumeric: true, isEnabled: false)),
                              const SizedBox(width: 8),
                              _buildFormAddButton(),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildFormDiscountField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildFormTextField("Charges", chargesController, "0.00", isNumeric: true, onChanged: (_) => _calculateFormValues())),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: _buildFormTextField("Taxable", taxableController, "0", isNumeric: true, isEnabled: false)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildFormTextField("Total", totalController, "0", isNumeric: true, isEnabled: false)),
                            const SizedBox(width: 8),
                            _buildFormAddButton(),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),

        _buildAddedProductsList(),
      ],
    );
  }

  Widget _buildFormProductSelectField() {
    final filteredDropdownProducts = products.where((p) {
      if (filterCategory != null && filterCategory!.isNotEmpty && filterCategory != "-- All Categories --") {
        final cat = (p['category_name'] ?? p['category']?['name'] ?? p['category'] ?? "").toString().toLowerCase();
        if (!cat.contains(filterCategory!.toLowerCase())) return false;
      }
      if (filterBrand != null && filterBrand!.isNotEmpty && filterBrand != "-- All Brands --") {
        final name = (p['product_name'] ?? p['name'] ?? "").toString().toLowerCase();
        final brand = (p['brand'] ?? p['brand_name'] ?? "").toString().toLowerCase();
        if (!name.contains(filterBrand!.toLowerCase()) && !brand.contains(filterBrand!.toLowerCase())) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product *",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        SearchableProductDropdown(
          products: filteredDropdownProducts.isNotEmpty ? filteredDropdownProducts : products,
          selectedProduct: selectedFormProduct,
          isLoading: isProductsLoading,
          onSelected: (product) {
            setState(() {
              selectedFormProduct = product;
              if (product != null) {
                primaryNameController.text = (product['product_name'] ?? product['name'] ?? "").toString();
                final double productPrice = double.tryParse((product['selling_price'] ?? product['price'] ?? "0").toString()) ?? 0.0;
                rateExclController.text = productPrice.toStringAsFixed(2);
                
                final double productTax = double.tryParse((product['tax'] ?? product['tax_percent'] ?? "18").toString()) ?? 18.0;
                gstPercentValue = "${productTax.toStringAsFixed(0)}%";
                
                unitValue = (product['unit'] ?? product['unit_name'] ?? "Pcs").toString();
                if (!["Pcs", "Kgs", "Boxes", "Dozen", "Meters", "Liters"].contains(unitValue)) {
                  unitValue = "Pcs";
                }
                
                _calculateFormValues(fromExcl: true);
              } else {
                primaryNameController.clear();
                secondaryNameController.clear();
                rateExclController.text = "0.00";
                rateInclController.text = "0.00";
                gstPercentValue = "18%";
                unitValue = "Pcs";
                _calculateFormValues();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildAddedProductsList() {
    final filtered = items.where((item) {
      if (tableSearchQuery.trim().isEmpty) return true;
      return item.productName.toLowerCase().contains(tableSearchQuery.toLowerCase());
    }).toList();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Added Products List (${filtered.length})",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 36,
                      child: TextField(
                        controller: tableSearchController,
                        onChanged: (val) {
                          setState(() {
                            tableSearchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search products...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 16),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          fillColor: Colors.grey.shade50,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text("Show ", style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: rowsPerPage,
                          items: [5, 10, 20, 50].map((int val) {
                            return DropdownMenuItem<int>(
                              value: val,
                              child: Text("$val", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              rowsPerPage = val!;
                            });
                          },
                        ),
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    "No products added yet. Use the form above to add products to this purchase bill.",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columnSpacing: 20,
                horizontalMargin: 16,
                columns: const [
                  DataColumn(label: Text("S.NO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  DataColumn(label: Text("PRODUCT NAME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  DataColumn(label: Text("GST %", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  DataColumn(label: Text("QUANTITY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  DataColumn(label: Text("UNIT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  DataColumn(label: Text("RATE (EXCL. TAX)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  DataColumn(label: Text("RATE (INCL. TAX)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  DataColumn(label: Text("DISCOUNT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  DataColumn(label: Text("TAXABLE AMOUNT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  DataColumn(label: Text("ACTIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                ],
                rows: List.generate(filtered.length, (index) {
                  final item = filtered[index];
                  return DataRow(
                    cells: [
                      DataCell(Text("${index + 1}", style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            if (item.secondaryName != null && item.secondaryName!.isNotEmpty)
                              Text(
                                "Sec: ${item.secondaryName}",
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      ),
                      DataCell(Text("${item.gstPercent.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 12))),
                      DataCell(Text(item.qty.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
                      DataCell(Text(item.unit, style: const TextStyle(fontSize: 12))),
                      DataCell(Text("₹${item.rateExcl.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12))),
                      DataCell(Text("₹${item.rateIncl.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12))),
                      DataCell(Text("₹${item.discount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12))),
                      DataCell(Text("₹${item.taxable.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          onPressed: () {
                            setState(() {
                              items.remove(item);
                              _calculateTotals();
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  filtered.isEmpty 
                      ? "Showing 0 to 0 of 0 entries" 
                      : "Showing 1 to ${filtered.length} of ${filtered.length} entries",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Go to Page: ", style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    Container(
                      width: 40,
                      height: 28,
                      child: TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          hintText: "1",
                          hintStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                          fillColor: Colors.grey.shade50,
                          filled: true,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(child: Text("«", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(child: Text("1", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(child: Text("»", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
