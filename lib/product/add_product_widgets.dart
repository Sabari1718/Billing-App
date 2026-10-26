part of 'add product.dart';

extension _ProductEntryPageStateWidgets on _ProductEntryPageState {
  Widget _buildScanSetupArea() {
    final bool isQR = !_isBarcodeMode;

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
          // Header with Title & QR/Barcode Toggle
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                "Product Scan Setup",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildScanTypeButton("QR Code", isQR),
                    _buildScanTypeButton("Barcode", !isQR),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Viewfinder & Input Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 550;

              final viewfinder = GestureDetector(
                onTap: _openCameraScanner,
                child: Container(
                  height: 140,
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
                        // Red scan laser line
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            final offset = (value - 0.5).abs() * 2 * 70;
                            return Positioned(
                              top: 25 + offset,
                              left: 20,
                              right: 20,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.8),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Corner brackets
                        _cornerBracket(top: 12, left: 12, isTop: true, isLeft: true),
                        _cornerBracket(top: 12, right: 12, isTop: true, isLeft: false),
                        _cornerBracket(bottom: 12, left: 12, isTop: false, isLeft: true),
                        _cornerBracket(bottom: 12, right: 12, isTop: false, isLeft: false),

                        // Center Icon (QR Code or Barcode)
                        if (isQR)
                          const Center(
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              size: 48,
                              color: Color(0xFF38BDF8),
                            ),
                          )
                        else
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                8,
                                (index) => Container(
                                  width: index % 2 == 0 ? 5 : 3,
                                  height: 44,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ),

                        // Bottom status text
                        Positioned(
                          bottom: 12,
                          child: Text(
                            isQR ? "Detecting QR CODE..." : "Detecting BAR CODE...",
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final inputArea = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Scan/Type Code Manually",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (constraints.maxWidth < 360) ...[
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: barcodeController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: isQR ? "Enter QR Code..." : "Enter Barcode...",
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _triggerSimulateScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Simulate Scan",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: barcodeController,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: isQR ? "Enter QR Code..." : "Enter Barcode...",
                                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _triggerSimulateScan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Simulate Scan",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );

              if (isSmall) {
                return Column(
                  children: [
                    viewfinder,
                    const SizedBox(height: 12),
                    inputArea,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 4, child: viewfinder),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: inputArea),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cornerBracket({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Color(0xFF38BDF8), width: 2.5) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownsFormArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: CATEGORY, BRAND, PRODUCT
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;
            final categoryField = buildField(
              "CATEGORY",
              DropdownButtonFormField<int>(
                value: (selectedCategoryId != null && categoryItems.any((e) => e['id'] == selectedCategoryId))
                    ? selectedCategoryId
                    : null,
                isExpanded: true,
                decoration: _dropdownDecoration(),
                hint: Text("Select Category", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: categoryItems.map<DropdownMenuItem<int>>((e) {
                  return DropdownMenuItem<int>(
                    value: e['id'] as int,
                    child: Text(
                      e['name']?.toString() ?? "No Name",
                      style: GoogleFonts.inter(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
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
            );

            final brandField = buildField(
              "BRAND",
              DropdownButtonFormField<int>(
                key: ValueKey(selectedCategoryId),
                value: (selectedBrandId != null && brands.any((e) => e['id'] == selectedBrandId))
                    ? selectedBrandId
                    : null,
                isExpanded: true,
                decoration: _dropdownDecoration(),
                hint: Text(
                  selectedCategoryId == null ? "Select Category First" : "Select Brand",
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: brands.map((e) {
                  return DropdownMenuItem<int>(
                    value: e['id'] as int,
                    child: Text(
                      e['name']?.toString() ?? "No Name",
                      style: GoogleFonts.inter(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: selectedCategoryId == null
                    ? null
                    : (val) {
                        setState(() {
                          selectedBrandId = val;
                          selectedProductId = null;
                          selectedProductName = null;
                          products = [];
                        });
                        if (val != null) {
                          loadProducts(selectedCategoryId!, val);
                        }
                      },
              ),
            );

            final productField = buildField(
              "PRODUCT",
              DropdownButtonFormField<int>(
                key: ValueKey(selectedBrandId),
                value: (selectedProductId != null && products.any((e) => e['id'] == selectedProductId))
                    ? selectedProductId
                    : null,
                isExpanded: true,
                decoration: _dropdownDecoration(),
                hint: Text(
                  selectedBrandId == null
                      ? "Select Brand First"
                      : (products.isEmpty ? "No Products Available" : "Select Product"),
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: products.map((e) {
                  return DropdownMenuItem<int>(
                    value: e['id'] as int,
                    child: Text(
                      e['product_name']?.toString() ?? "No Product",
                      style: GoogleFonts.inter(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
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
            );

            if (isNarrow) {
              return Column(
                children: [
                  categoryField,
                  const SizedBox(height: 16),
                  brandField,
                  const SizedBox(height: 16),
                  productField,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: categoryField),
                const SizedBox(width: 16),
                Expanded(child: brandField),
                const SizedBox(width: 16),
                Expanded(child: productField),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Row 2: MIN QTY, MAX QTY
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            final minField = buildField(
              "MIN QTY",
              TextFormField(
                controller: minQtyController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: _inputDecoration("Enter Minimum Quantity"),
              ),
            );

            final maxField = buildField(
              "MAX QTY",
              TextFormField(
                controller: maxQtyController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: _inputDecoration("Enter Maximum Quantity"),
              ),
            );

            if (isNarrow) {
              return Column(
                children: [
                  minField,
                  const SizedBox(height: 16),
                  maxField,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: minField),
                const SizedBox(width: 16),
                Expanded(child: maxField),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()), // spacer to match 3 cols alignment
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildModeButton(String text, bool isActive, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isScanMode = text == "Scanner";
          if (!_isScanMode) {
            _autofilledText = null;
            barcodeController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade600,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              text == "QR Code" ? Icons.qr_code_2 : Icons.bar_chart,
              size: 14,
              color: isActive ? const Color(0xFF0F172A) : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF0F172A) : Colors.grey,
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
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
