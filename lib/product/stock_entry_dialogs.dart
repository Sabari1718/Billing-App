part of 'stock entry.dart';

extension _StockEntryPageStateDialogs on _StockEntryPageState {
  // Helper for Product Name
  String _getSelectedProductName() {
    final selectedProdObj = products.firstWhere(
      (e) => e['id'].toString() == selectedProduct,
      orElse: () => null,
    );
    if (selectedProdObj != null) {
      return (selectedProdObj['product_name'] ?? selectedProdObj['name'] ?? 'Product').toString();
    }
    return 'Mq-2 Gas Sensor';
  }

  // Helper for Product MRP
  String _getSelectedProductMRP() {
    final selectedProdObj = products.firstWhere(
      (e) => e['id'].toString() == selectedProduct,
      orElse: () => null,
    );
    if (selectedProdObj != null) {
      final mrp = selectedProdObj['mrp'] ?? selectedProdObj['price'] ?? selectedProdObj['selling_price'];
      if (mrp != null && mrp.toString().isNotEmpty) {
        return "₹${double.tryParse(mrp.toString())?.toStringAsFixed(2) ?? mrp.toString()}";
      }
    }
    return "₹499.00";
  }

  // =========================================================================
  // 1. PRICE DETAILS POPUP (PHOTO 4 MATCHING)
  // =========================================================================
  void openPriceDetailsPopup() {
    final String prodName = _getSelectedProductName();
    final String prodMRP = _getSelectedProductMRP();

    // Prefill controllers from state or existing values
    final totalQtyCtrl = TextEditingController(text: qtyController.text.isEmpty || qtyController.text == "0" ? "" : qtyController.text);
    final purchasePriceCtrl = TextEditingController(text: buyingController.text.isEmpty || buyingController.text == "0.00" ? "" : buyingController.text);
    final profitMarginCtrl = TextEditingController(text: profitController.text.isEmpty || profitController.text == "0.00" ? "" : profitController.text);
    final sellingPriceCtrl = TextEditingController(text: sellingController.text.isEmpty || sellingController.text == "0.00" ? "" : sellingController.text);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double qty = double.tryParse(totalQtyCtrl.text) ?? 0.0;
            double purchasePrice = double.tryParse(purchasePriceCtrl.text) ?? 0.0;
            double profitMargin = double.tryParse(profitMarginCtrl.text) ?? 0.0;
            double sellingPrice = double.tryParse(sellingPriceCtrl.text) ?? (purchasePrice + profitMargin);

            double purchaseValue = qty * purchasePrice;
            double totalSellingValue = qty * sellingPrice;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Tag Icon & Close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_offer, size: 16, color: Color(0xFFF97316)),
                              const SizedBox(width: 8),
                              Text(
                                "Price Details",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Green Highlight Banner (Photo 4)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prodName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Product MRP Reference",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              prodMRP,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fields Grid (2 columns or responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;

                          // 1. TOTAL QTY *
                          final totalQtyField = _buildPriceField(
                            label: "TOTAL QTY",
                            isRequired: true,
                            child: TextField(
                              controller: totalQtyCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: _dialogInputDecoration("0"),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          );

                          // 2. PER QTY PURCHASE PRICE (₹) *
                          final purchasePriceField = _buildPriceField(
                            label: "PER QTY PURCHASE PRICE (₹)",
                            isRequired: true,
                            child: TextField(
                              controller: purchasePriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: _dialogInputDecoration("0.00"),
                              onChanged: (val) {
                                double p = double.tryParse(val) ?? 0.0;
                                double m = double.tryParse(profitMarginCtrl.text) ?? 0.0;
                                sellingPriceCtrl.text = (p + m).toStringAsFixed(2);
                                setModalState(() {});
                              },
                            ),
                          );

                          // 3. PURCHASE VALUE (₹) (Calculated)
                          final purchaseValueField = _buildPriceField(
                            label: "PURCHASE VALUE (₹)",
                            isRequired: false,
                            child: Container(
                              height: 42,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                purchaseValue.toStringAsFixed(2),
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                              ),
                            ),
                          );

                          // 4. PROFIT MARGIN (₹)
                          final profitMarginField = _buildPriceField(
                            label: "PROFIT MARGIN (₹)",
                            isRequired: false,
                            child: TextField(
                              controller: profitMarginCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: _dialogInputDecoration("0.00"),
                              onChanged: (val) {
                                double p = double.tryParse(purchasePriceCtrl.text) ?? 0.0;
                                double m = double.tryParse(val) ?? 0.0;
                                sellingPriceCtrl.text = (p + m).toStringAsFixed(2);
                                setModalState(() {});
                              },
                            ),
                          );

                          // 5. SELLING PRICE PER QTY (₹)
                          final sellingPriceField = _buildPriceField(
                            label: "SELLING PRICE PER QTY (₹)",
                            isRequired: false,
                            child: TextField(
                              controller: sellingPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: _dialogInputDecoration("0.00"),
                              onChanged: (val) {
                                double s = double.tryParse(val) ?? 0.0;
                                double p = double.tryParse(purchasePriceCtrl.text) ?? 0.0;
                                profitMarginCtrl.text = (s - p).toStringAsFixed(2);
                                setModalState(() {});
                              },
                            ),
                          );

                          // 6. TOTAL SELLING VALUE (₹) (Green highlighted box)
                          final totalSellingValueField = _buildPriceField(
                            label: "TOTAL SELLING VALUE (₹)",
                            isRequired: false,
                            child: Container(
                              height: 42,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Text(
                                totalSellingValue.toStringAsFixed(2),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                totalQtyField,
                                const SizedBox(height: 12),
                                purchasePriceField,
                                const SizedBox(height: 12),
                                purchaseValueField,
                                const SizedBox(height: 12),
                                profitMarginField,
                                const SizedBox(height: 12),
                                sellingPriceField,
                                const SizedBox(height: 12),
                                totalSellingValueField,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    totalQtyField,
                                    const SizedBox(height: 14),
                                    purchaseValueField,
                                    const SizedBox(height: 14),
                                    sellingPriceField,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    purchasePriceField,
                                    const SizedBox(height: 14),
                                    profitMarginField,
                                    const SizedBox(height: 14),
                                    totalSellingValueField,
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons (Cancel and Save Price Details)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                qtyController.text = totalQtyCtrl.text.trim().isEmpty ? "0" : totalQtyCtrl.text.trim();
                                buyingController.text = purchasePriceCtrl.text.trim().isEmpty ? "0.00" : purchasePriceCtrl.text.trim();
                                profitController.text = profitMarginCtrl.text.trim().isEmpty ? "0.00" : profitMarginCtrl.text.trim();
                                sellingController.text = sellingPriceCtrl.text.trim().isEmpty ? "0.00" : sellingPriceCtrl.text.trim();

                                variantTabData[0] = {
                                  'qty': qtyController.text,
                                  'buying': buyingController.text,
                                  'profit': profitController.text,
                                  'selling': sellingController.text,
                                };
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Price details saved successfully"), backgroundColor: Colors.green),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              "Save Price Details",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 2. STOCK DISTRIBUTION POPUP (PHOTO 5 MATCHING)
  // =========================================================================
  void openStockPopup() {
    // Determine active variants or default
    List<Map<String, dynamic>> activeVariantsList = [];
    if (variants.isNotEmpty) {
      activeVariantsList = List<Map<String, dynamic>>.from(variants);
    } else {
      activeVariantsList = [
        {'id': 1, 'name': 'Original'},
        {'id': 2, 'name': 'Imported'},
        {'id': 3, 'name': 'ssss'},
      ];
    }

    int activeVariantId = activeVariantsList.first['id'] as int;

    // Ensure fallback stock types exist
    if (stockTypes.isEmpty) {
      stockTypes = [
        {'id': 1, 'name': 'Main Store'},
        {'id': 2, 'name': 'Warehouse'},
        {'id': 3, 'name': 'Shelf 1'},
        {'id': 4, 'name': 'Damaged / Defective'},
      ];
    }

    String? selectedStockTypeId = stockTypes.isNotEmpty ? stockTypes.first['id'].toString() : null;
    final stockValCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Determine total quantity for this variant or main product
            int totalQty = 0;
            if (withVariantMode) {
              int qFromTab = int.tryParse(variantTabData[activeVariantId]?['qty'] ?? '') ?? 0;
              totalQty = qFromTab > 0 ? qFromTab : (int.tryParse(qtyCtrls[activeVariantId]?.text ?? '') ?? 0);
              if (totalQty == 0) {
                totalQty = int.tryParse(qtyController.text) ?? 0;
              }
            } else {
              totalQty = int.tryParse(qtyController.text) ?? 0;
            }

            // Get current distribution for active variant
            List<Map<String, dynamic>> currentDistList = stockTabData[activeVariantId] ?? [];

            int distributedQty = currentDistList.fold(
              0,
              (sum, item) => sum + (int.tryParse(item['qty']?.toString() ?? '0') ?? 0),
            );
            int balanceQty = totalQty - distributedQty;
            if (balanceQty < 0) balanceQty = 0;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Title & Close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Stock Distribution",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Top Summary Box (Photo 5: Total Quantity | Balance Quantity)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    "Total Quantity:",
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalQty.toString(),
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    "Balance Quantity:",
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    balanceQty.toString(),
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Select Variant: (Photo 5)
                      if (activeVariantsList.isNotEmpty) ...[
                        Text(
                          "Select Variant:",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: activeVariantsList.map<Widget>((v) {
                            final vId = v['id'] as int;
                            final vName = v['name'] ?? v['variant_name'] ?? 'Variant';
                            final isSelected = activeVariantId == vId;

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  activeVariantId = vId;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  vName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Card: Add New Stock Distribution (Photo 5)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add New Stock Distribution",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 12),

                            // Stock Type Name with "+ Create New"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Stock Type Name",
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                                ),
                                GestureDetector(
                                  onTap: () => _showCreateStockTypeDialog(context, (newName) {
                                    setModalState(() {
                                      final newId = DateTime.now().millisecondsSinceEpoch;
                                      stockTypes.add({'id': newId, 'name': newName});
                                      selectedStockTypeId = newId.toString();
                                    });
                                  }),
                                  child: Text(
                                    "+ Create New",
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedStockTypeId,
                              isExpanded: true,
                              hint: Text("Select Stock Type", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                              decoration: _dialogInputDecoration("Select Stock Type"),
                              items: stockTypes.map<DropdownMenuItem<String>>((st) {
                                return DropdownMenuItem(
                                  value: st['id'].toString(),
                                  child: Text(st['name']?.toString() ?? 'Store', style: GoogleFonts.inter(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedStockTypeId = val;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Stock Value (Quantity)
                            Text(
                              "Stock Value (Quantity)",
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: stockValCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: _dialogInputDecoration("Enter numeric value"),
                            ),
                            const SizedBox(height: 14),

                            // Green Add Value Button (Photo 5)
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  final q = int.tryParse(stockValCtrl.text.trim()) ?? 0;
                                  if (q <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please enter a valid quantity greater than 0")),
                                    );
                                    return;
                                  }

                                  final stName = stockTypes.firstWhere(
                                    (e) => e['id'].toString() == selectedStockTypeId,
                                    orElse: () => {'name': 'Store'},
                                  )['name']?.toString() ?? 'Store';

                                  setModalState(() {
                                    stockTabData[activeVariantId] ??= [];
                                    stockTabData[activeVariantId]!.add({
                                      'stock_type_id': selectedStockTypeId,
                                      'name': stName,
                                      'qty': q,
                                    });
                                    stockValCtrl.clear();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  "Add Value",
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section: Current Distribution (Photo 5)
                      Text(
                        "Current Distribution",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                        ),
                        child: currentDistList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Text(
                                    "No values added yet for this variant",
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                  ),
                                ),
                              )
                            : Column(
                                children: currentDistList.map<Widget>((item) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          item['name']?.toString() ?? "Store",
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "Qty: ${item['qty']}",
                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            setModalState(() {
                                              currentDistList.remove(item);
                                            });
                                          },
                                          child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Bottom Save Details Button (Photo 5)
                      Center(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Stock distribution saved"), backgroundColor: Colors.green),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                            ),
                            child: Text(
                              "Save Details",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 3. SPECIFY VARIANT DETAILS POPUP (FOR WITH VARIANT MODE)
  // =========================================================================
  void openVariantPopup() {
    final String prodName = _getSelectedProductName();
    final String prodMRP = _getSelectedProductMRP();

    if (variants.isEmpty) {
      variants = [
        {'id': 1, 'name': 'Original'},
        {'id': 2, 'name': 'Imported'},
        {'id': 3, 'name': 'ssss'},
      ];
    }

    // Prefill controller values
    for (var v in variants) {
      int id = int.tryParse(v['id'].toString()) ?? 0;
      var data = variantTabData[id] ?? {'qty': '', 'buying': '', 'profit': '', 'selling': ''};
      qtyCtrls[id] ??= TextEditingController(text: data['qty'] ?? '');
      priceCtrls[id] ??= TextEditingController(text: data['buying'] ?? '');
      profitCtrls[id] ??= TextEditingController(text: data['profit'] ?? '');
    }

    int activeVariantId = variants.first['id'] as int;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final vData = variantTabData[activeVariantId] ?? {'qty': '', 'buying': '', 'profit': '', 'selling': ''};
            final qtyCtrl = qtyCtrls[activeVariantId] ?? TextEditingController(text: vData['qty'] ?? '');
            final buyingCtrl = priceCtrls[activeVariantId] ?? TextEditingController(text: vData['buying'] ?? '');
            final profitCtrl = profitCtrls[activeVariantId] ?? TextEditingController(text: vData['profit'] ?? '');

            double q = double.tryParse(qtyCtrl.text) ?? 0.0;
            double p = double.tryParse(buyingCtrl.text) ?? 0.0;
            double m = double.tryParse(profitCtrl.text) ?? 0.0;
            double s = p + m;
            double totalVal = q * s;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.layers_outlined, size: 18, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Text(
                                "Variant Details",
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Green banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prodName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                                const SizedBox(height: 2),
                                Text("Product MRP Reference", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF047857))),
                              ],
                            ),
                            Text(prodMRP, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Select Variant Chips
                      Text("Select Variant:", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: variants.map<Widget>((v) {
                          final vId = v['id'] as int;
                          final vName = v['name'] ?? v['variant_name'] ?? 'Variant';
                          final isSelected = activeVariantId == vId;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                activeVariantId = vId;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: isSelected ? 1.5 : 1),
                              ),
                              child: Text(
                                vName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Variant Fields
                      _buildPriceField(
                        label: "TOTAL QTY",
                        isRequired: true,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _dialogInputDecoration("0"),
                          onChanged: (val) {
                            variantTabData[activeVariantId] = {
                              'qty': val,
                              'buying': buyingCtrl.text,
                              'profit': profitCtrl.text,
                              'selling': (p + m).toStringAsFixed(2),
                            };
                            setModalState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPriceField(
                        label: "PER QTY PURCHASE PRICE (₹)",
                        isRequired: true,
                        child: TextField(
                          controller: buyingCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _dialogInputDecoration("0.00"),
                          onChanged: (val) {
                            variantTabData[activeVariantId] = {
                              'qty': qtyCtrl.text,
                              'buying': val,
                              'profit': profitCtrl.text,
                              'selling': ((double.tryParse(val) ?? 0.0) + m).toStringAsFixed(2),
                            };
                            setModalState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPriceField(
                        label: "PROFIT MARGIN (₹)",
                        isRequired: false,
                        child: TextField(
                          controller: profitCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _dialogInputDecoration("0.00"),
                          onChanged: (val) {
                            variantTabData[activeVariantId] = {
                              'qty': qtyCtrl.text,
                              'buying': buyingCtrl.text,
                              'profit': val,
                              'selling': (p + (double.tryParse(val) ?? 0.0)).toStringAsFixed(2),
                            };
                            setModalState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPriceField(
                        label: "TOTAL SELLING VALUE (₹)",
                        isRequired: false,
                        child: Container(
                          height: 42,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            totalVal.toStringAsFixed(2),
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 14),
                          ElevatedButton(
                            onPressed: () {
                              // Sum total variant quantities
                              int sum = 0;
                              variantTabData.forEach((key, val) {
                                sum += int.tryParse(val['qty'] ?? '0') ?? 0;
                              });
                              setState(() {
                                qtyController.text = sum.toString();
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Variant details saved"), backgroundColor: Colors.green),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text("Save Variant Details", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Quick dialog to create new Stock Type
  void _showCreateStockTypeDialog(BuildContext context, Function(String) onCreated) {
    final typeNameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Create Stock Type", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: typeNameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "e.g. Shelf 2, Cold Storage",
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final val = typeNameCtrl.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                onCreated(val);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Form Fields inside Price Details
  Widget _buildPriceField({required String label, required bool isRequired, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
            ),
            if (isRequired)
              Text(
                " *",
                style: GoogleFonts.inter(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _dialogInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
