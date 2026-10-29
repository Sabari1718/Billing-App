part of 'Generate Bill.dart';

extension _CustomerScreenStateViews on _CustomerScreenState {
  Widget _buildCustomerSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Customer Selection Card (Photo 4)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: | Customer Selection   [+ Unregistered Customer]  [+ Add New Customer]
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        color: const Color(0xFF0D6EFD),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Customer Selection",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showUnregisteredCustomerDialog,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          "Unregistered Customer",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEA580C),
                          side: const BorderSide(color: Color(0xFFEA580C)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _launchCustomerRegistration,
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 14),
                        label: const Text(
                          "Add New Customer",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter row: Customer Type [User] [Business]   Mobile No [Enter Mobile]
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Customer Type",
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  isUser = true;
                                  verifyBy = "Mobile No";
                                  results = [];
                                  _showDropdown = false;
                                  _searchController.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isUser ? const Color(0xFF0D6EFD) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  "User",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isUser ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  isUser = false;
                                  results = [];
                                  _showDropdown = false;
                                  _searchController.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: !isUser ? const Color(0xFF0D6EFD) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  "Business",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !isUser ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        verifyBy == "Mobile No" ? "Mobile No" : verifyBy,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 220,
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          keyboardType: TextInputType.phone,
                          onChanged: searchCustomer,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: "Enter Mobile",
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // If dropdown is open (searching)
        if (_showDropdown && (results.isNotEmpty || errorMessage != null || loading))
          _buildAutocompleteDropdown(),

        // If customer is selected or unregistered customer exists
        if (selectedCustomer != null) ...[
          _buildSelectedCustomerCompact(selectedCustomer!),
        ],
      ],
    );
  }

  Widget _buildProductSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Search Card (Photo 1)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: | Product Search   [ Advanced Search ]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        color: const Color(0xFF0D6EFD),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Product Search",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: _showAdvancedProductSearch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D6EFD),
                      side: const BorderSide(color: Color(0xFF0D6EFD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text("Advanced Search", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Inputs: Search By: [Product Name ▾]  Enter Value: [Filter by first letter (A-Z)]
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Search By:", style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: productSearchBy,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                            items: ["Product Name", "Product Code", "Brand", "Category"]
                                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => productSearchBy = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Enter Value:", style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 220,
                        height: 38,
                        child: TextField(
                          controller: _productSearchController,
                          onChanged: searchProduct,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: "Filter by first letter (A-Z)",
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (isStocksInitialLoading) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D6EFD)),
                ),
                SizedBox(width: 10),
                Text("Loading stocks from server...", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Live Product Results (if typing in Enter Value or searching)
        if (productLoading) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D6EFD)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (productResults.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Found Products (${productResults.length}) - Tap to add to bill",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _productSearchController.clear();
                          productResults.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...productResults.map((item) => _buildProductCard(item)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else if (_productSearchController.text.trim().isNotEmpty && !productLoading) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                "No products found for '${_productSearchController.text.trim()}'",
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Selected Products / Empty State Card (Photo 1)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: selectedBillItems.isEmpty
              ? _buildEmptyProductsCard()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSelectedItemsList(),
                    const SizedBox(height: 20),
                    _buildAdditionalChargesSection(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyProductsCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "No Products Selected",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Search and add products to create a bill.",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeadline(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF2563EB), width: 4)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildProductCard(ProductStock item) {
    bool isSelected = selectedBillItems.any((e) => e.stockId == item.stockId && e.variantId == item.variantId);
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return GestureDetector(
          onTap: () async {
            if (!isSelected) {
              final stockTypes = item.stockTypes.isNotEmpty
                  ? item.stockTypes
                  : await fetchStockDetails(item.stockId, item.variantId);
              setState(() {
                selectedBillItems.add(item.copyWith(stockTypes: stockTypes));
                calculateTotals();
              });
              addBillProductApi(item, 1);
            } else {
              setState(() {
                selectedBillItems.removeWhere((e) => e.stockId == item.stockId && e.variantId == item.variantId);
                calculateTotals();
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB).withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0xFF2563EB).withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  isMobile ? _buildMobileCard(item) : _buildDesktopCard(item),
                  if (isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopCard(ProductStock item) {
    return Row(
      children: [
        if (item.baseImage.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.baseImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: Colors.grey.shade100,
                child: const Icon(Icons.inventory_2_outlined, size: 24, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(
                [
                  if (item.productCode.isNotEmpty) item.productCode,
                  if (item.brand.isNotEmpty) item.brand,
                  if (item.category.isNotEmpty) item.category,
                ].join(" • "),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(flex: 2, child: _variantBadge(item)),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.warranty.isNotEmpty)
                Text("Warranty: ${item.warranty}", style: const TextStyle(fontSize: 12)),
              Text("Stock: ${item.qty}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹${item.unitPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              if (item.mrp > item.unitPrice)
                Text("MRP ₹${item.mrp.toStringAsFixed(2)}", style: TextStyle(fontSize: 11, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildActionButtons(item),
      ],
    );
  }

  Widget _buildMobileCard(ProductStock item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.baseImage.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.baseImage,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.inventory_2_outlined, size: 22, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  if (item.productCode.isNotEmpty || item.brand.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (item.productCode.isNotEmpty) item.productCode,
                        if (item.brand.isNotEmpty) item.brand,
                      ].join(" • "),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _variantBadge(item),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (item.category.isNotEmpty)
              _mobileInfoChip(Icons.category_outlined, item.category, const Color(0xFF0D6EFD)),
            if (item.warranty.isNotEmpty)
              _mobileInfoChip(Icons.verified_user_outlined, item.warranty, Colors.green),
            _mobileInfoChip(Icons.inventory_2_outlined, "Stock: ${item.qty}", const Color(0xFF16A34A)),
          ],
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("₹${item.unitPrice.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2563EB))),
                if (item.mrp > item.unitPrice)
                  Text("MRP ₹${item.mrp.toStringAsFixed(2)}", style: TextStyle(fontSize: 11, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
              ],
            ),
            _buildActionButtons(item),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(ProductStock item) {
    bool isSelected = selectedBillItems.any((e) => e.stockId == item.stockId);
    if (item.isRequest) {
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text("Request", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionBtn(Icons.visibility_outlined, const Color(0xFF2563EB), () => _showProductDetails(item)),
          const SizedBox(width: 8),
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 16),
                  SizedBox(width: 6),
                  Text("Added", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            )
          else
            _actionBtn(Icons.add_circle_outline, const Color(0xFF2563EB), () async {
              final stockTypes = await fetchStockDetails(item.stockId, item.variantId);
              setState(() {
                selectedBillItems.add(item.copyWith(stockTypes: stockTypes));
                calculateTotals();
              });
            }),
        ],
      );
    }
  }

  Widget _buildProductAutocompleteDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: productErrorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(productErrorMessage!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: productResults.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade50),
              itemBuilder: (context, index) {
                final item = productResults[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text("${item.supplierName} • ${item.category}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  onTap: () {
                    setState(() {
                      bool isAlreadySelected = selectedBillItems.any((e) => e.stockId == item.stockId);
                      if (!isAlreadySelected) {
                        selectedBillItems.add(item);
                      } else {
                        selectedBillItems.removeWhere((e) => e.stockId == item.stockId);
                      }
                      calculateTotals();
                      _showProductDropdown = false;
                    });
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
    );
  }

  Widget _buildAutocompleteDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: errorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(errorMessage!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: results.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade50),
              itemBuilder: (context, index) {
                final item = results[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(item.mobile, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.address.isEmpty ? "No address" : item.address,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      selectedCustomer = item;
                      _showDropdown = false;
                      if (verifyBy == "GST No") {
                        _searchController.text = item.gst;
                      } else if (verifyBy == "PAN No") {
                        _searchController.text = item.pan;
                      } else {
                        _searchController.text = item.mobile;
                      }
                      results = [];
                    });
                  },
                );
              },
            ),
    );
  }
}
