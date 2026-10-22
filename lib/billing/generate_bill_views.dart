part of 'Generate Bill.dart';

extension _CustomerScreenStateViews on _CustomerScreenState {
  Widget _buildCustomerSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Customer Type", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildSubTabButton("User", isUser, () {
                setState(() {
                  isUser = true;
                  selectedCustomer = null;
                  results = [];
                  _showDropdown = false;
                  _searchController.clear();
                });
              }),
              const SizedBox(width: 4),
              _buildSubTabButton("Business", !isUser, () {
                setState(() {
                  isUser = false;
                  selectedCustomer = null;
                  results = [];
                  _showDropdown = false;
                  _searchController.clear();
                });
              }),
            ],
          ),
        ),

        const SizedBox(height: 24),

        CompositedTransformTarget(
          link: _layerLink,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: verifyBy,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          items: ["Mobile No", "GST No", "PAN No"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                verifyBy = v;
                                results = [];
                                selectedCustomer = null;
                                _showDropdown = false;
                                _searchController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      keyboardType: verifyBy == "Mobile No" ? TextInputType.phone : TextInputType.text,
                      onChanged: searchCustomer,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Enter $verifyBy",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(verifyBy == "Mobile No" ? Icons.phone_android : Icons.assignment_ind, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: loading 
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    results = [];
                                    selectedCustomer = null;
                                    _showDropdown = false;
                                    loading = false;
                                    errorMessage = null;
                                  });
                                }
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_showDropdown && (results.isNotEmpty || errorMessage != null))
                _buildAutocompleteDropdown(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (selectedCustomer != null) ...[
          _buildSelectedCustomerCompact(selectedCustomer!),
        ] else ...[
          _buildAddNewCustomerButton(),
        ],
      ],
    );
  }

  Widget _buildProductSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Product Search", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            TextButton.icon(
              onPressed: () => _showAdvancedProductSearch(),
              icon: const Icon(Icons.tune, size: 18, color: Color(0xFF2563EB)),
              label: const Text("Advanced Search", style: TextStyle(color: Color(0xFF1F366A), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CompositedTransformTarget(
          link: _productLayerLink,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: productSearchBy,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        items: ["Name", "SKU", "Category"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => productSearchBy = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _productSearchController,
                      onChanged: searchProduct,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Enter $productSearchBy",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: productLoading 
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildProductResultsList(),
        const SizedBox(height: 24),
        _buildSelectedItemsList(),
        if (selectedBillItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildAdditionalChargesSection(),
        ],
      ],
    );
  }

  Widget _buildProductResultsList() {
    if (productResults.isEmpty && productErrorMessage == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text("No products to display. Search to find products.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (productErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: Text(productErrorMessage!, style: TextStyle(color: Colors.red.shade700)),
      );
    }

    return Column(
      children: [
        if (productResults.isNotEmpty) ...[
          _buildGroupHeadline("PRODUCT RESULTS"),
          ...productResults.map((item) => _buildProductCard(item)),
          const SizedBox(height: 24),
        ],
      ],
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
              final stockTypes = await fetchStockDetails(item.stockId, item.variantId);
              setState(() {
                selectedBillItems.add(item.copyWith(stockTypes: stockTypes));
                calculateTotals();
              });
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
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text("${item.supplierName} • ${item.category}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
        Expanded(flex: 2, child: _variantBadge(item)),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Warranty: ${item.warranty}", style: const TextStyle(fontSize: 12)),
              Text("Qty: ${item.qty}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹${item.unitPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14)),
              Text("₹${item.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            ],
          ),
        ),
        const SizedBox(width: 24),
        _buildActionButtons(item),
      ],
    );
  }

  Widget _buildMobileCard(ProductStock item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            _variantBadge(item),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _mobileInfoChip(Icons.verified_user_outlined, item.warranty, Colors.green),
            const SizedBox(width: 12),
            _mobileInfoChip(Icons.inventory_2_outlined, "Qty: ${item.qty}", Colors.orange),
          ],
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Price: ₹${item.unitPrice.toStringAsFixed(2)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text("Total: ₹${item.total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2563EB))),
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
