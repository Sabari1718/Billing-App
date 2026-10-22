part of 'Generate Bill.dart';

extension _CustomerScreenStateDialogs on _CustomerScreenState {
  void _showEditPopup(ProductStock item) async {
    final selectedStockId = item.stockId;
    final selectedVariantId = item.variantId;

    final List stockTypesFromApi = await fetchStockDetails(selectedStockId, selectedVariantId);
    
    int tempQty = item.qty;
    final Map<String, int> distribution = Map<String, int>.from(item.selectedDistribution);
    
    String discountType = item.discountType;
    String taxType = item.taxType;
    final TextEditingController discountControllerPopup = TextEditingController(text: item.enteredDiscount == 0 ? "" : item.enteredDiscount.toString());
    final TextEditingController taxControllerPopup = TextEditingController(text: item.enteredTax == 0 ? "" : item.enteredTax.toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setPopupState) {
            final List itemStockTypes = List<dynamic>.from(stockTypesFromApi);

            void updateLiveItem() {
              int idx = selectedBillItems.indexWhere((e) => e.stockId == item.stockId && e.variantId == item.variantId);
              if (idx != -1) {
                double currentItemBaseTotal = tempQty * item.unitPrice;
                double enteredTaxVal = double.tryParse(taxControllerPopup.text) ?? 0;
                double enteredDiscountVal = double.tryParse(discountControllerPopup.text) ?? 0;
                
                double taxAmt = taxType == "%" ? (currentItemBaseTotal * enteredTaxVal) / 100 : enteredTaxVal;
                double discountAmt = discountType == "%" ? (currentItemBaseTotal * enteredDiscountVal) / 100 : enteredDiscountVal;
                double finalPayableItem = currentItemBaseTotal + taxAmt - discountAmt;

                setState(() {
                  selectedBillItems[idx] = item.copyWith(
                    qty: tempQty,
                    total: finalPayableItem,
                    taxAmount: taxAmt,
                    discountAmount: discountAmt,
                    enteredTax: enteredTaxVal,
                    enteredDiscount: enteredDiscountVal,
                    taxType: taxType,
                    discountType: discountType,
                  );
                  calculateTotals();
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              elevation: 24,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.edit_document, color: Color(0xFF2563EB), size: 20),
                          ),
                          const SizedBox(width: 16),
                          const Text("Update Item", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), padding: const EdgeInsets.all(8)),
                          ),
                        ],  
                      ),
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                const SizedBox(height: 6),
                                _variantBadge(item),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      const Text("Billing Quantity", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _qtyBtnLarge(Icons.remove_rounded, () {
                              if (tempQty > 1) {
                                setPopupState(() {
                                  tempQty--;
                                  updateLiveItem();
                                });
                              }
                            }),
                            Text("$tempQty", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            _qtyBtnLarge(Icons.add_rounded, () {
                              setPopupState(() {
                                tempQty++;
                                updateLiveItem();
                              });
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      const Text("Stock Distribution", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Distributed Stock", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                const SizedBox(height: 4),
                                Text(
                                  "Pending Dist: ${tempQty - distribution.values.fold(0, (sum, q) => sum + q)}", 
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600)
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("Total Balance", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534), letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(
                                  "${itemStockTypes.fold(0, (sum, st) => sum + (int.tryParse((st['qty'] ?? 0).toString()) ?? 0))}", 
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF15803D))
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildStockSourceDropdown(
                        context,
                        itemStockTypes,
                        distribution,
                        (selectedId) {
                          setPopupState(() {
                            if (distribution.containsKey(selectedId)) {
                              return;
                            }
                            distribution[selectedId] = 0;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      Column(
                        children: distribution.keys.map((id) {
                          final source = itemStockTypes.firstWhere((s) => s['stock_type_id'].toString() == id);
                          return _buildSourceSelectionCard(
                            source: source,
                            deducted: distribution[id]!,
                            onQtyChanged: (val) => setPopupState(() => distribution[id] = val),
                            onRemove: () => setPopupState(() => distribution.remove(id)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildManualInput(
                              label: "Discount", 
                              controller: discountControllerPopup, 
                              icon: Icons.local_offer_outlined,
                              currentType: discountType,
                              onToggle: (type) {
                                setPopupState(() {
                                  discountType = type;
                                  updateLiveItem();
                                });
                              },
                              onChanged: (_) {
                                setPopupState(() {
                                  updateLiveItem();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildManualInput(
                              label: "Tax / GST", 
                              controller: taxControllerPopup, 
                              icon: Icons.receipt_long_outlined,
                              currentType: taxType,
                              onToggle: (type) {
                                setPopupState(() {
                                  taxType = type;
                                  updateLiveItem();
                                });
                              },
                              onChanged: (_) {
                                setPopupState(() {
                                  updateLiveItem();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                int idx = selectedBillItems.indexWhere((e) => e.stockId == item.stockId);
                                if (idx != -1) {
                                  String summaryStockType = "Direct";
                                  if (distribution.isNotEmpty) {
                                    final firstId = distribution.keys.first;
                                    final firstSource = itemStockTypes.firstWhere((s) => s['stock_type_id'].toString() == firstId, orElse: () => null);
                                    summaryStockType = firstSource != null ? firstSource['name'] : "Direct";
                                    if (distribution.length > 1) summaryStockType += " (+${distribution.length - 1})";
                                  }

                                  final double currentItemBaseTotal = tempQty * item.unitPrice;
                                  final double enteredTaxVal = double.tryParse(taxControllerPopup.text) ?? 0;
                                  final double enteredDiscountVal = double.tryParse(discountControllerPopup.text) ?? 0;

                                  double taxAmt = taxType == "%" ? (currentItemBaseTotal * enteredTaxVal) / 100 : enteredTaxVal;
                                  double discountAmt = discountType == "%" ? (currentItemBaseTotal * enteredDiscountVal) / 100 : enteredDiscountVal;
                                  final double finalPayableItem = currentItemBaseTotal + taxAmt - discountAmt;

                                  selectedBillItems[idx] = item.copyWith(
                                    qty: tempQty,
                                    total: finalPayableItem,
                                    stockType: summaryStockType,
                                    selectedDistribution: Map<String, int>.from(distribution),
                                    taxAmount: taxAmt,
                                    discountAmount: discountAmt,
                                    enteredTax: enteredTaxVal,
                                    enteredDiscount: enteredDiscountVal,
                                    taxType: taxType,
                                    discountType: discountType,
                                  );
                                }
                                calculateTotals();
                              });
                              Navigator.pop(dialogContext);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Done", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildStockSourceDropdown(BuildContext context, List<dynamic> sources, Map<String, int> distribution, Function(String) onSelect) {
    final availableSources = sources.where((s) {
      final stockTypeId = (s['stock_type_id'] ?? "").toString();
      return !distribution.keys.contains(stockTypeId);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Source to Add", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 56),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 48, 
              maxWidth: MediaQuery.of(context).size.width - 48
            ),
            onSelected: (selectedId) {
              final selectedSource = sources.firstWhere(
                (s) => s['stock_type_id'].toString() == selectedId,
                orElse: () => null,
              );
              if (selectedSource != null && !distribution.containsKey(selectedId)) {
                onSelect(selectedId);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Stock Source", style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                  Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
                ],
              ),
            ),
            itemBuilder: (context) {
              if (availableSources.isEmpty) {
                return [
                  const PopupMenuItem(
                    enabled: false,
                    child: Text("All sources selected", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                ];
              }
              return availableSources.map((stockType) {
                final id = stockType['stock_type_id'].toString();
                final name = stockType['name'] ?? "Unknown";
                final qty = int.tryParse((stockType['qty'] ?? 0).toString()) ?? 0;
                
                return PopupMenuItem<String>(
                  value: id,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    "$name (Available: $qty)",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                  ),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSourceSelectionCard({
    required dynamic source,
    required int deducted,
    required Function(int) onQtyChanged,
    required VoidCallback onRemove,
  }) {
    final int available = int.tryParse((source['qty'] ?? 0).toString()) ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text("Deducted: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyActionBtn(Icons.remove, () {
                            if (deducted > 0) onQtyChanged(deducted - 1);
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text("$deducted", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          _qtyActionBtn(Icons.add, () {
                            if (deducted < available) onQtyChanged(deducted + 1);
                          }),
                        ],
                      ),
                    ),
                    Text(" / $available", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Balance: ${available - deducted}", 
                  style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 11)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualInput({
    required String label, 
    required TextEditingController controller, 
    required IconData icon,
    required String currentType,
    required Function(String) onToggle,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: onChanged,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    isDense: true,
                    hintText: "0",
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onToggle(currentType == "%" ? "₹" : "%"),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentType,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProductDetails(ProductStock item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Product Information",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text("Product Image", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _detailRow("Product Name", item.productName, isBold: true),
                      _detailRow("Variant", item.variant, badgeColor: const Color(0xFF2563EB)),
                      _detailRow("Warranty", item.warranty),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                      Row(
                        children: [
                          Expanded(child: _detailRow("Total Qty", item.qty.toString())),
                          const SizedBox(width: 24),
                          Expanded(child: _detailRow("Stock Type", item.stockType)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _detailRow("Normal Price", "₹${item.normalPrice.toStringAsFixed(2)}"),
                      _detailRow("Tax %", "${item.taxPercent}%"),
                      _detailRow("Tax Price", "₹${item.taxPrice.toStringAsFixed(2)}"),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.1)),
                        ),
                        child: _detailRow("Final Selling Price", "₹${item.unitPrice.toStringAsFixed(2)}", isHighlight: true, noPadding: true),
                      ),
                      const SizedBox(height: 24),
                      const Text("Description", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      Text(item.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.6)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Close Window", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStockSourceSheet(BuildContext context, List<dynamic> stockTypes, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Stock Source", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (stockTypes.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No stock sources available", style: TextStyle(color: Colors.grey))))
            else
              ...stockTypes.map((st) {
                final name = (st['name'] ?? 'Unknown').toString();
                final qty = st['qty'] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    onTap: () {
                      onSelect(st['stock_type_id'].toString());
                      Navigator.pop(context);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text("$name (Available: $qty)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB)),
                  ),
                );
              }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAdvancedProductSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        const Text("Advanced Search Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              filterProductNameController.clear();
                              filterHSNController.clear();
                              filterPriceMinController.clear();
                              filterPriceMaxController.clear();
                              filterStockMinController.clear();
                              filterStockMaxController.clear();
                              filterCategory = null;
                              filterBrand = null;
                            });
                          },
                          child: const Text("Reset All", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterField("Product Name", filterProductNameController, hint: "Enter product name"),
                          const SizedBox(height: 16),
                          _buildFilterField("HSN Code", filterHSNController, hint: "Enter HSN code"),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildFilterField("Min Price (₹)", filterPriceMinController, keyboardType: TextInputType.number, hint: "Min")),
                              const SizedBox(width: 16),
                              Expanded(child: _buildFilterField("Max Price (₹)", filterPriceMaxController, keyboardType: TextInputType.number, hint: "Max")),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildFilterField("Min Stock", filterStockMinController, keyboardType: TextInputType.number, hint: "Min")),
                              const SizedBox(width: 16),
                              Expanded(child: _buildFilterField("Max Stock", filterStockMaxController, keyboardType: TextInputType.number, hint: "Max")),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          setState(() {
                            productLoading = true;
                          });
                          // Trigger product search
                          final query = filterProductNameController.text.trim();
                          final results = await fetchProductAllocations(query.isEmpty ? " " : query);
                          
                          // Filter locally
                          final minPrice = double.tryParse(filterPriceMinController.text) ?? 0.0;
                          final maxPrice = double.tryParse(filterPriceMaxController.text) ?? double.infinity;
                          final minStock = int.tryParse(filterStockMinController.text) ?? 0;
                          final maxStock = int.tryParse(filterStockMaxController.text) ?? 999999;
                          final hsn = filterHSNController.text.trim().toLowerCase();

                          setState(() {
                            productResults = results.where((item) {
                              if (minPrice > 0 && item.unitPrice < minPrice) return false;
                              if (maxPrice < double.infinity && item.unitPrice > maxPrice) return false;
                              if (item.qty < minStock || item.qty > maxStock) return false;
                              if (hsn.isNotEmpty && !item.sku.toLowerCase().contains(hsn)) return false;
                              return true;
                            }).toList();
                            productLoading = false;
                            if (productResults.isEmpty) {
                              productErrorMessage = "No products match advanced filters";
                            } else {
                              productErrorMessage = null;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Apply Filters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterField(String label, TextEditingController controller, {String? hint, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}
