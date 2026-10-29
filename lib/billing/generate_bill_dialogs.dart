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

  void _showUnregisteredCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: _searchController.text.trim());
    final addrCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool isSavingCustomer = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (Photo 5)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Unregistered Customer",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Enter customer details for this bill. This customer will not be added to the registered customer list.",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Customer Name *
                      _buildUnregisteredInput(
                        label: "Customer Name *",
                        controller: nameCtrl,
                        hint: "Enter Customer Name",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),

                      // Phone Number *
                      _buildUnregisteredInput(
                        label: "Phone Number *",
                        controller: phoneCtrl,
                        hint: "Enter Phone Number",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),

                      // Address *
                      _buildUnregisteredInput(
                        label: "Address *",
                        controller: addrCtrl,
                        hint: "Enter Customer Address",
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),

                      // Email ID (Optional)
                      _buildUnregisteredInput(
                        label: "Email ID",
                        controller: emailCtrl,
                        hint: "Enter Email Address (Optional)",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),

                      // Footer Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: isSavingCustomer ? null : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isSavingCustomer
                                ? null
                                : () async {
                                    final name = nameCtrl.text.trim();
                                    final phone = phoneCtrl.text.trim();
                                    final address = addrCtrl.text.trim();
                                    final email = emailCtrl.text.trim();

                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please enter customer name"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }
                                    if (phone.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please enter customer phone"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSavingCustomer = true);

                                    // Call API POST https://billing.srivagroups.in/api/unregister-customer
                                    final apiRes = await createUnregisteredCustomer(
                                      name: name,
                                      phone: phone,
                                      address: address.isEmpty ? "Walk-in Customer" : address,
                                      email: email,
                                    );

                                    String finalName = name;
                                    String finalPhone = phone;
                                    String finalAddr = address.isEmpty ? "Walk-in Customer" : address;
                                    String finalMail = email;

                                    if (apiRes != null && apiRes['data'] is Map) {
                                      final d = apiRes['data'];
                                      finalName = (d['customer_name'] ?? name).toString();
                                      finalPhone = (d['phone_number'] ?? phone).toString();
                                      finalAddr = (d['address'] ?? finalAddr).toString();
                                      finalMail = (d['email_id'] ?? email).toString();
                                    }

                                    if (!mounted) return;

                                    setState(() {
                                      selectedCustomer = Customer(
                                        name: finalName,
                                        mobile: finalPhone,
                                        type: "Unregistered",
                                        address: finalAddr,
                                        email: finalMail,
                                        gst: "",
                                        pan: "",
                                      );
                                      _searchController.text = finalPhone;
                                      _showDropdown = false;
                                      selectedMainTab = "User"; // Stay on Customer tab to see saved card
                                    });

                                    Navigator.pop(dialogContext);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Unregistered Customer: $finalName saved"),
                                        backgroundColor: const Color(0xFFEA580C),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: isSavingCustomer
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text("Save & Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildUnregisteredInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // ADVANCED PRODUCT SEARCH (Photos 2 & 3)
  // ----------------------------------------------------
  void _showAdvancedProductSearch() {
    String selectedCategoryGroup = filterCategoryGroup ?? "Electronics Basic Components";
    String selectedCat = filterCategory ?? "-- Category --";
    String selectedBrd = filterBrand ?? "-- Brand --";
    String selectedGst = filterGST ?? "All";

    final searchNameCtrl = TextEditingController(text: filterProductNameController.text);
    final hsnCtrl = TextEditingController(text: filterHSNController.text);
    final pMinCtrl = TextEditingController(text: filterPriceMinController.text);
    final pMaxCtrl = TextEditingController(text: filterPriceMaxController.text);
    final sMinCtrl = TextEditingController(text: filterStockMinController.text);
    final sMaxCtrl = TextEditingController(text: filterStockMaxController.text);

    List<ProductStock> dialogResults = List.from(productResults);
    List<ProductStock> tempSelected = List.from(selectedBillItems);
    bool hasSearched = dialogResults.isNotEmpty;
    bool isSearchingInDialog = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void performSearch() async {
              setModalState(() => isSearchingInDialog = true);

              final query = searchNameCtrl.text.trim();
              List<ProductStock> results = [];
              if (allAvailableStocks.isNotEmpty) {
                if (query.isNotEmpty) {
                  final q = query.toLowerCase();
                  results = allAvailableStocks.where((item) =>
                    item.productName.toLowerCase().contains(q) ||
                    item.productCode.toLowerCase().contains(q) ||
                    item.brand.toLowerCase().contains(q) ||
                    item.category.toLowerCase().contains(q) ||
                    item.sku.toLowerCase().contains(q)
                  ).toList();
                } else {
                  results = List.from(allAvailableStocks);
                }
              }

              if (results.isEmpty) {
                results = await fetchProductAllocations(query.isEmpty ? " " : query);
              }

              // Apply local filters
              final pMin = double.tryParse(pMinCtrl.text) ?? 0.0;
              final pMax = double.tryParse(pMaxCtrl.text) ?? double.infinity;
              final sMin = int.tryParse(sMinCtrl.text) ?? 0;
              final sMax = int.tryParse(sMaxCtrl.text) ?? 999999;
              final hsn = hsnCtrl.text.trim().toLowerCase();

              setModalState(() {
                dialogResults = results.where((item) {
                  if (selectedCat != "-- Category --" && item.category.toLowerCase() != selectedCat.toLowerCase()) {
                    return false;
                  }
                  if (selectedBrd != "-- Brand --" && item.brand.toLowerCase() != selectedBrd.toLowerCase()) {
                    return false;
                  }
                  if (pMin > 0 && item.unitPrice < pMin) return false;
                  if (pMax < double.infinity && item.unitPrice > pMax) return false;
                  if (item.qty < sMin || item.qty > sMax) return false;
                  if (hsn.isNotEmpty && !item.sku.toLowerCase().contains(hsn) && !item.productCode.toLowerCase().contains(hsn)) return false;
                  return true;
                }).toList();
                hasSearched = true;
                isSearchingInDialog = false;
              });
            }

            void clearFilters() {
              setModalState(() {
                searchNameCtrl.clear();
                hsnCtrl.clear();
                pMinCtrl.clear();
                pMaxCtrl.clear();
                sMinCtrl.clear();
                sMaxCtrl.clear();
                selectedCategoryGroup = "Electronics Basic Components";
                selectedCat = "-- Category --";
                selectedBrd = "-- Brand --";
                selectedGst = "All";
                dialogResults.clear();
                hasSearched = false;
              });
            }

            final List<String> catOptions = [
              "-- Category --",
              ...allAvailableStocks.map((e) => e.category).where((c) => c.isNotEmpty).toSet().toList()..sort(),
            ];
            final List<String> brdOptions = [
              "-- Brand --",
              ...allAvailableStocks.map((e) => e.brand).where((b) => b.isNotEmpty).toSet().toList()..sort(),
            ];

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blue Banner Header (Photos 2 & 3)
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF0D6EFD),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Advanced Product Search",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 18),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Group, Category, Brand
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                SizedBox(
                                  width: 170,
                                  child: _buildDialogDropdown(
                                    label: "Category Group",
                                    value: selectedCategoryGroup,
                                    items: const [
                                      "Electronics Basic Components",
                                      "Motors & Drivers",
                                      "Power Supply",
                                      "Sensors",
                                      "All Groups",
                                    ],
                                    onChanged: (v) {
                                      if (v != null) setModalState(() => selectedCategoryGroup = v);
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  child: _buildDialogDropdown(
                                    label: "Category",
                                    value: catOptions.contains(selectedCat) ? selectedCat : "-- Category --",
                                    items: catOptions,
                                    onChanged: (v) {
                                      if (v != null) setModalState(() => selectedCat = v);
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  child: _buildDialogDropdown(
                                    label: "Brand",
                                    value: brdOptions.contains(selectedBrd) ? selectedBrd : "-- Brand --",
                                    items: brdOptions,
                                    onChanged: (v) {
                                      if (v != null) setModalState(() => selectedBrd = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Search (Product Name / ID), HSN, GST
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                SizedBox(
                                  width: 240,
                                  child: _buildDialogField(
                                    label: "Search (Product Name / ID)",
                                    controller: searchNameCtrl,
                                    hint: "Type product name or ID...",
                                  ),
                                ),
                                SizedBox(
                                  width: 130,
                                  child: _buildDialogField(
                                    label: "HSN",
                                    controller: hsnCtrl,
                                    hint: "HSN",
                                  ),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: _buildDialogDropdown(
                                    label: "GST",
                                    value: selectedGst,
                                    items: const ["All", "0%", "5%", "12%", "18%", "28%"],
                                    onChanged: (v) {
                                      if (v != null) setModalState(() => selectedGst = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Price Min/Max & Stock Min/Max
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: _buildDialogField(
                                    label: "Price Min",
                                    controller: pMinCtrl,
                                    hint: "Price Min",
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: _buildDialogField(
                                    label: "Price Max",
                                    controller: pMaxCtrl,
                                    hint: "Price Max",
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: _buildDialogField(
                                    label: "Stock Min",
                                    controller: sMinCtrl,
                                    hint: "Stock Min",
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: _buildDialogField(
                                    label: "Stock Max",
                                    controller: sMaxCtrl,
                                    hint: "Stock Max",
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Action Buttons: [Search] [Clear]
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: isSearchingInDialog ? null : performSearch,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D6EFD),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  child: isSearchingInDialog
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text("Search", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: clearFilters,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF475569),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  child: const Text("Clear", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                ),
                              ],
                            ),
                            const Divider(height: 28),

                            // Results area
                            if (!hasSearched || dialogResults.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    "No products found. Try adjusting filters.",
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              const Text(
                                "Select products by checking the box on each card. Selections sync with the added-products list.",
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dialogResults.length,
                                separatorBuilder: (c, i) => const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final item = dialogResults[index];
                                  final isChecked = tempSelected.any((e) => e.stockId == item.stockId && e.variantId == item.variantId);

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isChecked ? const Color(0xFFEFF6FF) : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isChecked ? const Color(0xFF93C5FD) : Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isChecked,
                                          activeColor: const Color(0xFF0D6EFD),
                                          onChanged: (val) {
                                            setModalState(() {
                                              if (val == true) {
                                                if (!tempSelected.any((e) => e.stockId == item.stockId && e.variantId == item.variantId)) {
                                                  tempSelected.add(item);
                                                }
                                              } else {
                                                tempSelected.removeWhere((e) => e.stockId == item.stockId && e.variantId == item.variantId);
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "SKU: ${item.sku} • Stock: ${item.qty}",
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          "₹${item.unitPrice.toStringAsFixed(2)}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D6EFD)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Dialog Footer (Photos 2 & 3)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedBillItems = List.from(tempSelected);
                                calculateTotals();
                              });
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${tempSelected.length} product(s) applied to bill"),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            child: Text(
                              "Apply Selection (${tempSelected.length})",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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
    );
  }

  Widget _buildDialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
