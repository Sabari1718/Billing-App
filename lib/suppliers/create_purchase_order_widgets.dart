part of 'create_purchase_order.dart';

extension CreatePurchaseOrderWidgets on _CreatePurchaseOrderPageState {
  Widget _buildTopNavigation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 600;

        final Widget leftHeader = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Reorder Products",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Create and send purchase reorder requests to suppliers with live stock tracking and custom tax breakdowns.",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final Widget rightActions = Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text("Back", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Text(
                "${items.length} Products Selected",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftHeader,
              const SizedBox(height: 12),
              rightActions,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: leftHeader),
            const SizedBox(width: 12),
            rightActions,
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // SECTION 1: SELECT SUPPLIER
  // ----------------------------------------------------
  Widget _buildSupplierSection() {
    final String displaySupplier = selectedSupplier != null
        ? (selectedSupplier!['supplier_name'] ?? selectedSupplier!['company_name'] ?? "Selected Supplier").toString()
        : "-- Click to search & select a supplier --";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline, size: 18, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                "1. Select Supplier *",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _showSupplierSelection,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displaySupplier,
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedSupplier != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                        fontWeight: selectedSupplier != null ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SECTION 2: AVAILABLE PRODUCT CATALOG
  // ----------------------------------------------------
  Widget _buildCatalogSection(bool isMobile) {
    final filtered = getFilteredCatalog();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 600;
              final Widget titleWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.layers_outlined, size: 18, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text(
                    "2. Available Product Catalog",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              );

              final Widget rightInfo = Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (selectedSupplier == null)
                    const Text(
                      "Select a supplier above to view items",
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  OutlinedButton(
                    onPressed: selectedSupplier != null ? selectAllFilteredProducts : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: const Text("Select All Filtered", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 8),
                    rightInfo,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleWidget,
                  rightInfo,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Search + Category Filters
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: catalogSearchController,
              decoration: const InputDecoration(
                hintText: "Search by product name, code, brand",
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),

          // Category Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(
                      cat,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedCategory = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Content Area (Empty State or Product Table / Cards)
          if (selectedSupplier == null)
            _buildNoSupplierEmptyState()
          else if (isCatalogLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
            )
          else if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text("No products found.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ),
            )
          else
            _buildCatalogTableOrCards(filtered, isMobile),
        ],
      ),
    );
  }

  Widget _buildNoSupplierEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.store_mall_directory_outlined, size: 40, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            "No Supplier Selected",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Please select a supplier from 1. Select Supplier above to display its catalog.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogTableOrCards(List catalog, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columnSpacing: 18,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text("PRODUCT NAME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
          DataColumn(label: Text("PRODUCT CODE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
          DataColumn(label: Text("BRAND", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
          DataColumn(label: Text("CATEGORY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
          DataColumn(label: Text("CURRENT STOCK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
          DataColumn(label: Text("EST. PRICE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
          DataColumn(label: Text("ACTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        ],
        rows: catalog.map((prod) {
          final pMap = prod is Map<String, dynamic> ? prod : <String, dynamic>{};
          final pName = (pMap['product_name'] ?? pMap['name'] ?? "Item").toString();
          final pCode = (pMap['product_code'] ?? pMap['code'] ?? "-").toString();
          final brand = (pMap['brand'] ?? "-").toString();
          final category = (pMap['category'] ?? pMap['category_name'] ?? "General").toString();
          final stock = (pMap['current_stock'] ?? pMap['stock'] ?? 0).toString();
          final price = double.tryParse((pMap['selling_price'] ?? pMap['price'] ?? "0").toString()) ?? 0.0;

          final pId = pMap['id'] ?? pMap['product_id'];
          final isAlreadySelected = items.any((it) => (it.product?['id'] ?? it.product?['product_id']) == pId);

          return DataRow(
            cells: [
              DataCell(
                Text(pName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B))),
              ),
              DataCell(Text(pCode, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
              DataCell(Text(brand, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                ),
              ),
              DataCell(Text(stock, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)))),
              DataCell(Text("₹${price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
              DataCell(
                ElevatedButton.icon(
                  onPressed: () => addProductToOrder(pMap),
                  icon: Icon(isAlreadySelected ? Icons.check : Icons.add, size: 13),
                  label: Text(isAlreadySelected ? "Added" : "Add", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlreadySelected ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ----------------------------------------------------
  // SECTION 3: SELECTED PRODUCTS FOR REORDER
  // ----------------------------------------------------
  Widget _buildSelectedProductsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 450;
              final title = Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text(
                    "3. Selected Products for Reorder",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              );

              final countBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${items.length} Products ($totalUnits Units)",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    countBadge,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [title, countBadge],
              );
            },
          ),
          const SizedBox(height: 16),

          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_cart_outlined, size: 36, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 10),
                  Text(
                    "No products selected yet. Select products from the catalog above.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (c, i) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final item = items[index];
                final pName = (item.product?['product_name'] ?? item.product?['name'] ?? "Product").toString();
                final pCode = (item.product?['product_code'] ?? item.product?['code'] ?? "-").toString();
                final price = double.tryParse(item.priceController.text) ?? 0.0;
                final qty = int.tryParse(item.qtyController.text) ?? 1;
                final rowTotal = qty * price;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // Product Title & Code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Code: $pCode • ₹${price.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Quantity Stepper
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => decrementQty(index),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.remove, size: 14, color: Color(0xFF475569)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: Text(
                                "$qty",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                              ),
                            ),
                            InkWell(
                              onTap: () => incrementQty(index),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.add, size: 14, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Total
                      Text(
                        "₹${rowTotal.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E)),
                      ),
                      const SizedBox(width: 8),

                      // Remove
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: () => _removeItemRow(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SECTION 4 & 5: INSTRUCTIONS & ORDER SUMMARY
  // ----------------------------------------------------
  Widget _buildSummaryAndScheduleSection(bool isMobile) {
    final Widget scheduleCard = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.event_note, size: 18, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                "Additional Instructions & Schedule",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expected Delivery Date Picker
          const Text(
            "Expected Delivery Date",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectExpectedDeliveryDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expectedDeliveryDate != null
                        ? DateFormat('dd - MM - yyyy').format(expectedDeliveryDate!)
                        : DateFormat('dd - MM - yyyy').format(DateTime.now().add(const Duration(days: 7))),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Order Notes
          const Text(
            "Order Notes / Special Supplier Instructions",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter any notes, payment terms, or delivery conditions for the supplier...",
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );

    final Widget summaryCard = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_outlined, size: 18, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                "5. ORDER SUMMARY",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSummaryRow("Selected Items:", "${items.length} products"),
          const SizedBox(height: 10),
          _buildSummaryRow("Total Units:", "$totalUnits units"),
          const SizedBox(height: 10),
          _buildSummaryRow("Subtotal:", "₹${subtotal.toStringAsFixed(2)}"),
          const SizedBox(height: 10),
          _buildSummaryRow("Total Tax:", "+ ₹${taxTotal.toStringAsFixed(2)}", isGreen: true),
          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grand Total:",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                "₹${grandTotal.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : _savePurchaseOrder,
                  icon: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check, size: 16),
                  label: Text(
                    isSaving ? "Saving..." : "Save Reorder",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          scheduleCard,
          const SizedBox(height: 20),
          summaryCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: scheduleCard),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: summaryCard),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
