part of 'stock entry.dart';

extension _StockEntryPageStateDialogs on _StockEntryPageState {
  Map<String, dynamic>? _getSelectedProductObj() {
    if (selectedProduct == null) return null;
    for (var p in products) {
      if (p['id']?.toString() == selectedProduct) {
        return p;
      }
    }
    return null;
  }

  // Helper for Product Name
  String _getSelectedProductName() {
    final selectedProdObj = _getSelectedProductObj();
    if (selectedProdObj != null) {
      return (selectedProdObj['product_name'] ?? selectedProdObj['name'] ?? 'Product').toString();
    }
    return 'Mq-2 Gas Sensor';
  }

  // Helper for Product MRP
  String _getSelectedProductMRP() {
    final selectedProdObj = _getSelectedProductObj();
    if (selectedProdObj != null) {
      final mrp = selectedProdObj['mrp'] ?? selectedProdObj['price'] ?? selectedProdObj['selling_price'];
      if (mrp != null && mrp.toString().isNotEmpty) {
        return "₹${double.tryParse(mrp.toString())?.toStringAsFixed(2) ?? mrp.toString()}";
      }
    }
    return "₹499.00";
  }

  // Helper for Product Image
  String? _getSelectedProductImage() {
    final selectedProdObj = _getSelectedProductObj();
    if (selectedProdObj != null) {
      return selectedProdObj['base_image']?.toString();
    }
    return null;
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
  // 2. STOCK DISTRIBUTION POPUP (MATCHING PHOTOS 1, 2, 3)
  // =========================================================================
  void openStockPopup() {
    // Determine active variants or default
    List<Map<String, dynamic>> activeVariantsList = [];
    if (variants.isNotEmpty) {
      activeVariantsList = List<Map<String, dynamic>>.from(variants);
    } else {
      activeVariantsList = [
        {'id': 41, 'name': 'Imported'},
        {'id': 42, 'name': 'Original'},
        {'id': 43, 'name': 'Complimentary'},
      ];
    }

    // Default to first variant
    int activeVariantId = int.tryParse(activeVariantsList.first['id'].toString()) ?? 41;

    // Ensure fallback stock types exist matching Photo 3
    if (stockTypes.isEmpty) {
      stockTypes = [
        {'id': 1, 'name': 'Display'},
        {'id': 2, 'name': 'Shop in Sales'},
        {'id': 3, 'name': 'Outside Stocks'},
        {'id': 12, 'name': 'shop'},
        {'id': 13, 'name': 'outside'},
      ];
    }

    String? selectedStockTypeId = stockTypes.isNotEmpty ? stockTypes.first['id'].toString() : null;
    final stockValCtrl = TextEditingController();
    Map<String, dynamic>? editingItem;

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

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
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

                      // Top Summary Box (Photo 1 & 2: Total Quantity | Balance Quantity)
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
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF10B981),
                                    ),
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
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: balanceQty < 0 ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Select Variant: (Photo 1, 2, 3)
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
                            final vId = int.tryParse(v['id'].toString()) ?? 0;
                            final vName = (v['name'] ?? v['variant_name'] ?? 'Variant').toString();
                            final isSelected = activeVariantId == vId;

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  activeVariantId = vId;
                                  editingItem = null;
                                  stockValCtrl.clear();
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

                      // Card: Add New Stock Distribution (Photos 1, 2, 3)
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
                              editingItem != null ? "Edit Stock Distribution" : "Add New Stock Distribution",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 12),

                            // 2-Column layout matching Photo 1 & 2
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 420;

                                Widget stockTypeCol = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Stock Type Name:",
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
                                    SizedBox(
                                      height: 40,
                                      child: DropdownButtonFormField<String>(
                                        value: stockTypes.any((e) => e['id'].toString() == selectedStockTypeId)
                                            ? selectedStockTypeId
                                            : (stockTypes.isNotEmpty ? stockTypes.first['id'].toString() : null),
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
                                    ),
                                  ],
                                );

                                Widget stockValCol = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Stock Value (Quantity)",
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 40,
                                      child: TextField(
                                        controller: stockValCtrl,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.inter(fontSize: 13),
                                        decoration: _dialogInputDecoration("Enter numeric value"),
                                      ),
                                    ),
                                  ],
                                );

                                if (isNarrow) {
                                  return Column(
                                    children: [
                                      stockTypeCol,
                                      const SizedBox(height: 12),
                                      stockValCol,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: stockTypeCol),
                                    const SizedBox(width: 12),
                                    Expanded(child: stockValCol),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 14),

                            // Green Add / Update Value Button (Photo 1 & 2)
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

                                  String stName = "Store";
                                  for (var e in stockTypes) {
                                    if (e['id'].toString() == selectedStockTypeId) {
                                      stName = e['name']?.toString() ?? "Store";
                                      break;
                                    }
                                  }

                                  setModalState(() {
                                    stockTabData[activeVariantId] ??= [];
                                    if (editingItem != null) {
                                      editingItem!['stock_type_id'] = selectedStockTypeId;
                                      editingItem!['name'] = stName;
                                      editingItem!['qty'] = q;
                                      editingItem = null;
                                    } else {
                                      stockTabData[activeVariantId]!.add({
                                        'id': DateTime.now().microsecondsSinceEpoch.toString(),
                                        'stock_type_id': selectedStockTypeId,
                                        'name': stName,
                                        'qty': q,
                                      });
                                    }
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
                                  editingItem != null ? "Update Value" : "Add Value",
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section: Current Distribution (Photo 1 & 2)
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
                                  final name = item['name']?.toString() ?? "Stock";
                                  final displayName = name.toLowerCase().endsWith('stock') ? name : "$name Stock";

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Value: ${item['qty']}",
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Edit Button (Blue Pencil)
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: "Edit",
                                              onPressed: () {
                                                setModalState(() {
                                                  editingItem = item;
                                                  selectedStockTypeId = item['stock_type_id']?.toString();
                                                  stockValCtrl.text = item['qty'].toString();
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            // Delete Button (Red Trash)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: "Delete",
                                              onPressed: () {
                                                setModalState(() {
                                                  if (editingItem == item) {
                                                    editingItem = null;
                                                    stockValCtrl.clear();
                                                  }
                                                  currentDistList.remove(item);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Bottom Save Details Button (Photo 1 & 2)
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
    if (selectedProduct == null && products.isNotEmpty) {
      selectedProduct = products.first['id'].toString();
    }
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a product first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String prodName = _getSelectedProductName();
    final String prodMRP = _getSelectedProductMRP();
    final String? prodImage = _getSelectedProductImage();

    if (variants.isEmpty) {
      variants = [
        {'id': 41, 'name': 'Imported'},
        {'id': 42, 'name': 'Original'},
        {'id': 43, 'name': 'Complimentary'},
      ];
    }

    // Prefill controller values
    for (var v in variants) {
      int id = int.tryParse(v['id'].toString()) ?? 0;
      var data = variantTabData[id] ?? {
        'qty': '0',
        'buying': '0.00',
        'gst_rate': productGstRate,
        'profit': '0.00',
        'selling': '0.00',
      };
      qtyCtrls[id] ??= TextEditingController(text: (data['qty'] ?? '0').toString());
      priceCtrls[id] ??= TextEditingController(text: (data['buying'] ?? '0.00').toString());
      profitCtrls[id] ??= TextEditingController(text: (data['profit'] ?? '0.00').toString());
    }

    // Starts null so all variants are collapsed matching Photo 1
    int? expandedVariantId;

    final Map<int, String> gstRates = {};
    for (var v in variants) {
      int id = int.tryParse(v['id'].toString()) ?? 0;
      gstRates[id] = variantTabData[id]?['gst_rate']?.toString() ?? productGstRate;
    }

    double parseGstRate(String rateStr) {
      if (rateStr.contains('28')) return 0.28;
      if (rateStr.contains('18')) return 0.18;
      if (rateStr.contains('12')) return 0.12;
      if (rateStr.contains('5')) return 0.05;
      return 0.0;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int grandTotalQty = 0;
            double grandTotalVal = 0.0;

            for (var v in variants) {
              int id = int.tryParse(v['id'].toString()) ?? 0;
              int q = int.tryParse(qtyCtrls[id]?.text.trim() ?? '0') ?? 0;
              double p = double.tryParse(priceCtrls[id]?.text.trim() ?? '0.00') ?? 0.0;
              double r = parseGstRate(gstRates[id] ?? productGstRate);
              double pWithGst = p + (p * r);
              double m = double.tryParse(profitCtrls[id]?.text.trim() ?? '0.00') ?? 0.0;
              double sellIncl = pWithGst + m;

              grandTotalQty += q;
              grandTotalVal += q * sellIncl;
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_cart_outlined, size: 18, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Text(
                                "Variant Details",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
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

                      // Product Card (Image + Name + MRP + Totals) Matching Photo 1 & 2
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: prodImage != null && prodImage.isNotEmpty
                                  ? Image.network(
                                      prodImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.sensors_outlined,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    )
                                  : const Icon(Icons.sensors_outlined, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "PRODUCT",
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    prodName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "MRP $prodMRP",
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "$grandTotalQty",
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "TOTAL QTY",
                                        style: GoogleFonts.inter(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    height: 24,
                                    width: 1,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "₹${grandTotalVal == 0 ? '0' : grandTotalVal.toStringAsFixed(2)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "TOTAL VALUE",
                                        style: GoogleFonts.inter(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section Title
                      Text(
                        "SELECT VARIANT & ENTER DETAILS",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // List of Variant Accordions
                      Column(
                        children: variants.map<Widget>((v) {
                          final int vId = int.tryParse(v['id'].toString()) ?? 0;
                          final String vName = (v['name'] ?? v['variant_name'] ?? 'Variant').toString();
                          final bool isExpanded = expandedVariantId == vId;

                          final qtyCtrl = qtyCtrls[vId] ?? TextEditingController(text: '0');
                          final priceCtrl = priceCtrls[vId] ?? TextEditingController(text: '0.00');
                          final profitCtrl = profitCtrls[vId] ?? TextEditingController(text: '0.00');

                          int vQty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                          double pWithoutGst = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                          String currGstStr = gstRates[vId] ?? productGstRate;
                          double r = parseGstRate(currGstStr);

                          double gstAmtPerQty = pWithoutGst * r;
                          double pWithGst = pWithoutGst + gstAmtPerQty;
                          double purchaseValExcl = vQty * pWithoutGst;
                          double totalGst = vQty * gstAmtPerQty;
                          double totalPurchaseValIncl = purchaseValExcl + totalGst;

                          double margin = double.tryParse(profitCtrl.text.trim()) ?? 0.0;
                          double sellPerQtyExcl = pWithoutGst + margin;
                          double sellPerQtyIncl = pWithGst + margin;
                          double totalSellExcl = vQty * sellPerQtyExcl;
                          double totalSellIncl = vQty * sellPerQtyIncl;

                          // Dynamic MRP tax breakdown matching Photo 2
                          double rawMrp = double.tryParse(prodMRP.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 499.0;
                          if (rawMrp == 0) rawMrp = 499.0;
                          double exclGst = rawMrp / (1 + r);
                          double gstAmt = rawMrp - exclGst;

                          final bool hasDetails = vQty > 0 && pWithoutGst > 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasDetails ? const Color(0xFF10B981) : const Color(0xFFFCA5A5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Variant Accordion Header (Matching Photo 1 & Photo 2)
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      expandedVariantId = isExpanded ? null : vId;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          vName,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: hasDetails ? const Color(0xFF0F172A) : const Color(0xFFEF4444),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (vQty > 0 && !isExpanded)
                                              Container(
                                                margin: const EdgeInsets.only(right: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  "Qty: $vQty",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF059669),
                                                  ),
                                                ),
                                              ),
                                            Icon(
                                              isExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                                              size: 18,
                                              color: hasDetails ? const Color(0xFF64748B) : const Color(0xFFFCA5A5),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Expanded Fields (Matching Photo 2)
                                if (isExpanded) ...[
                                  const Divider(height: 1, color: Color(0xFFFEE2E2)),
                                  Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product MRP Green Banner matching Photo 2
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFA7F3D0)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "Product MRP (incl. GST):",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF065F46),
                                                    ),
                                                  ),
                                                  Text(
                                                    "₹${rawMrp.toStringAsFixed(2)}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF065F46),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                "Excl. GST: ₹${exclGst.toStringAsFixed(2)} | GST (${(r * 100).toInt()}%): ₹${gstAmt.toStringAsFixed(2)}",
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF047857),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        // Fields Grid (2-column layout matching Photo 2)
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final isNarrow = constraints.maxWidth < 420;

                                            Widget buildTwoColumns(Widget left, Widget right) {
                                              if (isNarrow) {
                                                return Column(
                                                  children: [
                                                    left,
                                                    const SizedBox(height: 10),
                                                    right,
                                                  ],
                                                );
                                              }
                                              return Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(child: left),
                                                  const SizedBox(width: 12),
                                                  Expanded(child: right),
                                                ],
                                              );
                                            }

                                            return Column(
                                              children: [
                                                // Row 1: TOTAL QTY & PURCHASE PRICE (WITHOUT GST)
                                                buildTwoColumns(
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "TOTAL QTY",
                                                            style: GoogleFonts.inter(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: (vQty <= 0) ? const Color(0xFFEF4444) : const Color(0xFF475569),
                                                            ),
                                                          ),
                                                          const Text(" *", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        height: 38,
                                                        child: TextField(
                                                          controller: qtyCtrl,
                                                          keyboardType: TextInputType.number,
                                                          style: GoogleFonts.inter(fontSize: 12),
                                                          decoration: InputDecoration(
                                                            hintText: "0",
                                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: BorderSide(color: (vQty <= 0) ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: BorderSide(color: (vQty <= 0) ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: BorderSide(color: (vQty <= 0) ? const Color(0xFFEF4444) : const Color(0xFF2563EB), width: 1.5),
                                                            ),
                                                          ),
                                                          onChanged: (_) => setModalState(() {}),
                                                        ),
                                                      ),
                                                      if (vQty <= 0)
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 4),
                                                          child: Text(
                                                            "▲ Total Qty must be greater than 0",
                                                            style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFFEF4444), fontWeight: FontWeight.w500),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "PURCHASE PRICE (WITHOUT GST) (₹)",
                                                            style: GoogleFonts.inter(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: (pWithoutGst <= 0) ? const Color(0xFFEF4444) : const Color(0xFF475569),
                                                            ),
                                                          ),
                                                          const Text(" *", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        height: 38,
                                                        child: TextField(
                                                          controller: priceCtrl,
                                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                          style: GoogleFonts.inter(fontSize: 12),
                                                          decoration: InputDecoration(
                                                            hintText: "0.00",
                                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: BorderSide(color: (pWithoutGst <= 0) ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: BorderSide(color: (pWithoutGst <= 0) ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: BorderSide(color: (pWithoutGst <= 0) ? const Color(0xFFEF4444) : const Color(0xFF2563EB), width: 1.5),
                                                            ),
                                                          ),
                                                          onChanged: (_) => setModalState(() {}),
                                                        ),
                                                      ),
                                                      if (pWithoutGst <= 0)
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 4),
                                                          child: Text(
                                                            "▲ Purchase Price must be greater than 0",
                                                            style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFFEF4444), fontWeight: FontWeight.w500),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 10),

                                                // Row 2: GST RATE & GST AMOUNT PER QTY
                                                buildTwoColumns(
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildLabel("GST RATE (%)", isRequired: false),
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        height: 38,
                                                        child: DropdownButtonFormField<String>(
                                                          value: currGstStr,
                                                          isExpanded: true,
                                                          decoration: InputDecoration(
                                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                                            ),
                                                          ),
                                                          items: [
                                                            '0% GST',
                                                            '5% GST',
                                                            '12% GST',
                                                            '18% GST',
                                                            '28% GST',
                                                          ].map((rate) {
                                                            return DropdownMenuItem(
                                                              value: rate,
                                                              child: Text(rate, style: GoogleFonts.inter(fontSize: 12)),
                                                            );
                                                          }).toList(),
                                                          onChanged: (val) {
                                                            if (val != null) {
                                                              setModalState(() {
                                                                gstRates[vId] = val;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  _buildReadonlyField(
                                                    "GST AMOUNT PER QTY (₹)",
                                                    gstAmtPerQty.toStringAsFixed(2),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),

                                                // Row 3: PRICE WITHOUT GST & PRICE WITH GST
                                                buildTwoColumns(
                                                  _buildReadonlyField(
                                                    "PRICE WITHOUT GST (₹)",
                                                    pWithoutGst.toStringAsFixed(2),
                                                  ),
                                                  _buildReadonlyField(
                                                    "PRICE WITH GST (${(r * 100).toInt()}%)",
                                                    pWithGst.toStringAsFixed(2),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),

                                                // Row 4: PURCHASE VALUE EXCL. GST & TOTAL GST
                                                buildTwoColumns(
                                                  _buildReadonlyField(
                                                    "PURCHASE VALUE EXCL. GST (₹)",
                                                    purchaseValExcl.toStringAsFixed(2),
                                                  ),
                                                  _buildReadonlyField(
                                                    "TOTAL GST (₹)",
                                                    totalGst.toStringAsFixed(2),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),

                                                // Row 5: TOTAL PURCHASE VALUE INCL. GST & PROFIT MARGIN
                                                buildTwoColumns(
                                                  _buildReadonlyField(
                                                    "TOTAL PURCHASE VALUE INCL. GST (₹)",
                                                    totalPurchaseValIncl.toStringAsFixed(2),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildLabel("PROFIT MARGIN (₹)", isRequired: false),
                                                      const SizedBox(height: 4),
                                                      SizedBox(
                                                        height: 38,
                                                        child: TextField(
                                                          controller: profitCtrl,
                                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                          style: GoogleFonts.inter(fontSize: 12),
                                                          decoration: InputDecoration(
                                                            hintText: "0.00",
                                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                                            ),
                                                          ),
                                                          onChanged: (_) => setModalState(() {}),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 10),

                                                // Row 6: SELLING PRICE PER QTY EXCL & INCL
                                                buildTwoColumns(
                                                  _buildReadonlyField(
                                                    "SELLING PRICE PER QTY (EXCL. GST) (₹)",
                                                    sellPerQtyExcl.toStringAsFixed(2),
                                                  ),
                                                  _buildReadonlyField(
                                                    "SELLING PRICE PER QTY (INCL. GST) (₹)",
                                                    sellPerQtyIncl.toStringAsFixed(2),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),

                                                // Row 7: TOTAL SELLING VALUE EXCL & INCL
                                                buildTwoColumns(
                                                  _buildReadonlyField(
                                                    "TOTAL SELLING VALUE (EXCL. GST) (₹)",
                                                    totalSellExcl.toStringAsFixed(2),
                                                  ),
                                                  _buildReadonlyField(
                                                    "TOTAL SELLING VALUE (INCL. GST) (₹)",
                                                    totalSellIncl.toStringAsFixed(2),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Actions (Discard & Save Variant Details)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              "Discard",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              int sum = 0;
                              double totalBuy = 0.0;
                              double totalSell = 0.0;

                              for (var v in variants) {
                                int id = int.tryParse(v['id'].toString()) ?? 0;
                                final qCtrl = qtyCtrls[id];
                                final bCtrl = priceCtrls[id];
                                final mCtrl = profitCtrls[id];

                                int q = int.tryParse(qCtrl?.text.trim() ?? '0') ?? 0;
                                double b = double.tryParse(bCtrl?.text.trim() ?? '0.00') ?? 0.0;
                                double m = double.tryParse(mCtrl?.text.trim() ?? '0.00') ?? 0.0;
                                String gstStr = gstRates[id] ?? productGstRate;
                                double r = parseGstRate(gstStr);
                                double pWithGst = b + (b * r);
                                double sell = pWithGst + m;

                                variantTabData[id] = {
                                  'qty': q.toString(),
                                  'buying': b.toStringAsFixed(2),
                                  'gst_rate': gstStr,
                                  'profit': m.toStringAsFixed(2),
                                  'selling': sell.toStringAsFixed(2),
                                };

                                sum += q;
                                totalBuy += (q * b);
                                totalSell += (q * sell);
                              }

                              setState(() {
                                qtyController.text = sum.toString();
                                if (sum > 0) {
                                  buyingController.text = (totalBuy / sum).toStringAsFixed(2);
                                  sellingController.text = (totalSell / sum).toStringAsFixed(2);
                                }
                              });

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Variant details saved"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            ),
                            child: Text(
                              "Save Variant Details",
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

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
          ),
        ),
        if (isRequired)
          Text(
            " *",
            style: GoogleFonts.inter(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildReadonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 4),
        Container(
          height: 40,
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
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
