part of 'add product.dart';

extension _ProductEntryPageStateWidgets on _ProductEntryPageState {
  Widget _buildScanSetupArea() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Product Scan Setup",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildScanTypeButton("QR Code", !_isBarcodeMode),
                    _buildScanTypeButton("Barcode", _isBarcodeMode),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResponsiveRow(
            GestureDetector(
              onTap: _openCameraScanner,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F19),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 2),
                        builder: (context, value, child) {
                          final offset = (value - 0.5).abs() * 2 * 100;
                          return Stack(
                            children: [
                              Positioned(
                                top: 30 + offset,
                                left: 20,
                                right: 20,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withOpacity(0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      Positioned(
                        top: 16, left: 16,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFF3B82F6), width: 3),
                              left: BorderSide(color: Color(0xFF3B82F6), width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16, right: 16,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFF3B82F6), width: 3),
                              right: BorderSide(color: Color(0xFF3B82F6), width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16, left: 16,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFF3B82F6), width: 3),
                              left: BorderSide(color: Color(0xFF3B82F6), width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16, right: 16,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFF3B82F6), width: 3),
                              right: BorderSide(color: Color(0xFF3B82F6), width: 3),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: 0.15,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            8,
                            (index) => Container(
                              width: index % 2 == 0 ? 8 : 4,
                              height: 60,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: Column(
                          children: [
                            Text(
                              _isBarcodeMode ? "DETECTING BAR CODE..." : "DETECTING QR CODE...",
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap to open mobile camera",
                              style: GoogleFonts.inter(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        child: Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 36),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Scan/Type Code Manually",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: barcodeController,
                          onSubmitted: (value) {
                            final text = value.trim();
                            if (text.isNotEmpty) {
                              _handleBarcodeScan(text);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Enter Barcode...",
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: barcodeController,
                        builder: (context, value, child) {
                          final hasText = value.text.trim().isNotEmpty;
                          return ElevatedButton(
                            onPressed: () {
                              final text = value.text.trim();
                              if (text.isNotEmpty) {
                                _handleBarcodeScan(text);
                              } else {
                                _openCameraScanner();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              hasText ? "Lookup" : "Scan",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (_autofilledText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFDF5),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Autofilled: $_autofilledText",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF15803D),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownsFormArea() {
    return Column(
      children: [
        _buildThreeColumnRow(
          buildField(
            "CATEGORY GROUP NAME",
            DropdownButtonFormField<int>(
              value: (selectedCategoryGroupId != null && categoryGroups.any((e) => e.id == selectedCategoryGroupId))
                  ? selectedCategoryGroupId
                  : null,
              hint: const Text("Select Group"),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              decoration: _dropdownDecoration(),
              items: categoryGroups.map((e) {
                return DropdownMenuItem<int>(
                  value: e.id,
                  child: Text(e.name ?? "No Name"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedCategoryGroupId = val;
                  selectedCategoryId = null;
                  selectedSecondaryCategoryId = null;
                  selectedBrandId = null;
                  selectedProductId = null;
                  selectedProductName = null;
                  categoryItems = [];
                  secondaryCategories = [];
                  brands = [];
                  products = [];
                });
                if (val != null) {
                  loadCategoryBrandData(val);
                }
              },
            ),
          ),
          buildField(
            "PRIMARY CATEGORY",
            DropdownButtonFormField<int>(
              key: ValueKey(selectedCategoryGroupId),
              value: categoryItems.any((e) => e['id'] == selectedCategoryId)
                  ? selectedCategoryId
                  : null,
              isExpanded: true,
              decoration: _dropdownDecoration(),
              hint: const Text("Select Category"),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: categoryItems.map<DropdownMenuItem<int>>((e) {
                return DropdownMenuItem<int>(
                  value: e['id'] as int,
                  child: Text(
                    e['name']?.toString() ?? "No Name",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: categoryItems.isEmpty
                  ? null
                  : (val) {
                      if (val == null) return;
                      final matchedItem = rawCategoryBrandData.firstWhere(
                        (item) => item['category_id'] == val,
                        orElse: () => {},
                      );
                      final rawSec = matchedItem['secondary_categories'] ?? [];
                      List<Map<String, dynamic>> secList = [];
                      for (var sec in rawSec) {
                        secList.add({
                          "id": sec['id'],
                          "name": sec['name'],
                          "brands": sec['brands'] ?? [],
                        });
                      }
                      final List brandList = secList.isEmpty ? (matchedItem['brands'] ?? []) : [];
                      final Map<int, Map<String, dynamic>> uniqueBrands = {};
                      for (var brand in brandList) {
                        if (brand['id'] != null) {
                          uniqueBrands[brand['id']] = {
                            "id": brand['id'],
                            "name": brand['name'] ?? "No Name",
                          };
                        }
                      }
                      setState(() {
                        selectedCategoryId = val;
                        secondaryCategories = secList;
                        selectedSecondaryCategoryId = null;
                        brands = uniqueBrands.values.toList();
                        selectedBrandId = null;
                        products = [];
                        selectedProductId = null;
                        selectedProductName = null;
                      });
                    },
            ),
          ),
          buildField(
            "SECONDARY CATEGORY",
            DropdownButtonFormField<int>(
              key: ValueKey(selectedCategoryId),
              value: secondaryCategories.any((e) => e['id'] == selectedSecondaryCategoryId)
                  ? selectedSecondaryCategoryId
                  : null,
              isExpanded: true,
              decoration: _dropdownDecoration(),
              hint: Text(secondaryCategories.isEmpty ? "None Available" : "Select Secondary"),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: secondaryCategories.map<DropdownMenuItem<int>>((e) {
                return DropdownMenuItem<int>(
                  value: e['id'] as int,
                  child: Text(
                    e['name']?.toString() ?? "No Name",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: secondaryCategories.isEmpty
                  ? null
                  : (val) {
                      if (val == null) return;
                      final matchedSec = secondaryCategories.firstWhere(
                        (sec) => sec['id'] == val,
                        orElse: () => {},
                      );
                      final brandList = matchedSec['brands'] ?? [];
                      final Map<int, Map<String, dynamic>> uniqueBrands = {};
                      for (var brand in brandList) {
                        if (brand['id'] != null) {
                          uniqueBrands[brand['id']] = {
                            "id": brand['id'],
                            "name": brand['name'] ?? "No Name",
                          };
                        }
                      }
                      setState(() {
                        selectedSecondaryCategoryId = val;
                        brands = uniqueBrands.values.toList();
                        selectedBrandId = null;
                        products = [];
                        selectedProductId = null;
                        selectedProductName = null;
                      });
                    },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildThreeColumnRow(
          buildField(
            "BRAND",
            DropdownButtonFormField<int>(
              key: ValueKey(selectedSecondaryCategoryId ?? selectedCategoryId),
              value: (selectedBrandId != null && brands.any((e) => e['id'] == selectedBrandId))
                  ? selectedBrandId
                  : null,
              hint: const Text("Select Brand"),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              decoration: _dropdownDecoration(),
              items: brands.map((e) {
                return DropdownMenuItem<int>(
                  value: e['id'] as int,
                  child: Text(
                    e['name']?.toString() ?? "No Name",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (selectedSecondaryCategoryId ?? selectedCategoryId) == null
                  ? null
                  : (val) {
                      setState(() {
                        selectedBrandId = val;
                        selectedProductId = null;
                        selectedProductName = null;
                        products = [];
                      });
                      if (val != null) {
                        loadProducts(selectedSecondaryCategoryId ?? selectedCategoryId!, val);
                      }
                    },
            ),
          ),
          buildField(
            "PRODUCT",
            DropdownButtonFormField<int>(
              key: ValueKey(selectedBrandId),
              value: (selectedProductId != null && products.any((e) => e['id'] == selectedProductId))
                  ? selectedProductId
                  : null,
              hint: Text(selectedBrandId == null ? "Please select brand first" : (products.isEmpty ? "No Products Available" : "Select Product")),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              decoration: _dropdownDecoration(),
              items: products.map((e) {
                return DropdownMenuItem<int>(
                  value: e['id'] as int,
                  child: Text(
                    e['product_name']?.toString() ?? "No Product",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (selectedBrandId == null || products.isEmpty)
                  ? null
                  : (val) {
                      setState(() {
                        selectedProductId = val;
                        selectedProductName = products.firstWhere((e) => e['id'] == val)['product_name'];
                      });
                    },
            ),
          ),
          buildField(
            "MIN QTY",
            TextFormField(
              controller: minQtyController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Enter Minimum Quantity"),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: MediaQuery.of(context).size.width < 600 ? 1.0 : 0.33,
            child: buildField(
              "MAX QTY",
              TextFormField(
                controller: maxQtyController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Enter Maximum Quantity"),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRow(Widget child1, Widget child2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child1,
        const SizedBox(height: 16),
        child2,
      ],
    );
  }

  Widget _buildThreeColumnRow(Widget child1, Widget child2, Widget child3) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child1,
        const SizedBox(height: 16),
        child2,
        const SizedBox(height: 16),
        child3,
      ],
    );
  }

  Widget _buildResponsiveButtons(Widget child1, Widget child2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 52, child: child2),
        const SizedBox(height: 12),
        SizedBox(height: 52, child: child1),
      ],
    );
  }

  Widget _buildModeButton(String text, bool isActive, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isScanMode = text == "Scan Code";
          if (!_isScanMode) {
            _autofilledText = null;
            barcodeController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanTypeButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isBarcodeMode = text == "Barcode";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              text == "QR Code" ? Icons.qr_code : Icons.bar_chart,
              size: 14,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
    );
  }
}
