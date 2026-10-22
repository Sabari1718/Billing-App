part of 'Generate Bill.dart';

extension _CustomerScreenStateViewsBilling on _CustomerScreenState {
  Widget _buildSelectedItemsList() {
    if (selectedBillItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text("Bill Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${selectedBillItems.length}",
                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 768) {
            return Column(
              children: List.generate(selectedBillItems.length, (index) {
                return _buildSelectedProductMobileCard(selectedBillItems[index], index + 1);
              }),
            );
          } else {
            return _buildSelectedProductDesktopTable();
          }
        }),
      ],
    );
  }

  Widget _buildSelectedProductMobileCard(ProductStock item, int sNo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      "$sNo",
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(item.variant, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                _actionBtn(Icons.edit_outlined, const Color(0xFF2563EB), () => _showEditPopup(item)),
                const SizedBox(width: 8),
                _actionBtn(Icons.delete_outline, Colors.red, () {
                  setState(() {
                    selectedBillItems.remove(item);
                    calculateTotals();
                  });
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyBtn(Icons.remove, () {
                            if (item.qty > 1) {
                              _updateItemQty(item, item.qty - 1);
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text("${item.qty}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _qtyBtn(Icons.add, () {
                            _updateItemQty(item, item.qty + 1);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("Stock: ${item.qty}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Unit: ₹${item.unitPrice.toStringAsFixed(2)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text("₹${item.total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2563EB))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildSelectedProductDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text("S.No")),
          DataColumn(label: Text("Product")),
          DataColumn(label: Text("Qty")),
          DataColumn(label: Text("Price")),
          DataColumn(label: Text("Total")),
          DataColumn(label: Text("Action")),
        ],
        rows: List.generate(selectedBillItems.length, (index) {
          final item = selectedBillItems[index];
          return DataRow(cells: [
            DataCell(Text("${index + 1}")),
            DataCell(Text(item.productName)),
            DataCell(Text("${item.qty}")),
            DataCell(Text("₹${item.unitPrice}")),
            DataCell(Text("₹${item.total}")),
            DataCell(Row(
              children: [
                _actionBtn(Icons.edit, Colors.blue, () => _showEditPopup(item)),
                const SizedBox(width: 8),
                _actionBtn(Icons.delete, Colors.red, () {
                  setState(() {
                    selectedBillItems.remove(item);
                    calculateTotals();
                  });
                }),
              ],
            )),
          ]);
        }),
      ),
    );
  }

  Widget _buildAdditionalChargesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCollapsibleChargesHeader(),
          _buildChargesTabsSection(),
          const SizedBox(height: 24),
          _buildSummaryCard(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a customer first.")),
                  );
                  setState(() {
                    selectedMainTab = "User";
                  });
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      customer: selectedCustomer!,
                      items: selectedBillItems,
                      subtotal: totalItemAmount,
                      discount: totalDiscountAmount,
                      tax: totalTaxAmount,
                      additionalCharges: totalAdditionalCharges,
                      grandTotal: finalPayableAmount,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Place Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleChargesHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              showAdditionalChargesDetails = !showAdditionalChargesDetails;
            });
            if (showAdditionalChargesDetails) {
              fetchAdditionalChargesData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(showAdditionalChargesDetails ? Icons.remove_circle : Icons.add_circle, color: const Color(0xFF2563EB), size: 20),
                const SizedBox(width: 8),
                Text("additional_charges".tr, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChargesTabsSection() {
    if (!showAdditionalChargesDetails) return const SizedBox.shrink();
    final List<Map<String, dynamic>> tabs = [
      {"label": "price".tr, "icon": Icons.currency_rupee, "color": const Color(0xFF2563EB)},
      {"label": "combo_offer".tr, "icon": Icons.card_giftcard, "color": const Color(0xFFEF4444)},
      {"label": "coupon_code".tr, "icon": Icons.local_offer, "color": const Color(0xFFF59E0B)},
      {"label": "discount_card".tr, "icon": Icons.credit_card, "color": const Color(0xFF10B981)},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (idx) {
                final tab = tabs[idx];
                final isSelected = activeChargesTab == idx;
                return InkWell(
                  onTap: () {
                    setState(() {
                      activeChargesTab = idx;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF2563EB) : Colors.transparent, width: 2)),
                      color: isSelected ? Colors.white : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab["icon"], size: 16, color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(tab["label"], style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade600)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
            child: loadingCharges ? const Center(child: CircularProgressIndicator()) : _buildActiveTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (activeChargesTab) {
      case 0: return _buildPricesList();
      case 1: return _buildCombosList();
      case 2: return _buildCouponsList();
      case 3: return _buildDiscountsList();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildPricesList() {
    if (fetchedPrices.isEmpty) {
      return Center(child: Text("no_price_plans".tr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)));
    }
    return Column(
      children: fetchedPrices.map((price) {
        final amount = price['amount']?.toString() ?? '0';
        final name = price['name']?.toString() ?? 'Price Plan';
        final desc = price['description']?.toString() ?? '';
        final isPriceActive = (price['status']?.toString() ?? 'inactive').toLowerCase() == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontSize: 16)),
                const SizedBox(width: 8),
                if (isPriceActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text("active".tr, style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            onTap: () {
              if (selectedBillItems.isNotEmpty) {
                final double newPrice = double.tryParse(amount) ?? 0.0;
                setState(() {
                  final firstItem = selectedBillItems.first;
                  int idx = selectedBillItems.indexOf(firstItem);
                  if (idx != -1) {
                    selectedBillItems[idx] = firstItem.copyWith(unitPrice: newPrice);
                  }
                  calculateTotals();
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Applied unit price ₹$amount to ${selectedBillItems.first.productName}")));
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCombosList() {
    if (fetchedCombos.isEmpty) {
      return Center(child: Text("no_combos".tr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)));
    }
    return Column(
      children: fetchedCombos.map((combo) {
        final name = combo['combo_name'] ?? combo['comboName'] ?? 'Combo Offer';
        final price = combo['combo_price'] ?? combo['comboPrice'] ?? '0';
        final desc = combo['description']?.toString() ?? '';
        final isComboActive = (combo['status']?.toString() ?? 'inactive').toLowerCase() == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("₹$price", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444), fontSize: 16)),
                const SizedBox(width: 8),
                if (isComboActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text("active".tr, style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            onTap: () {
              if (selectedBillItems.isNotEmpty) {
                final double newPrice = double.tryParse(price.toString()) ?? 0.0;
                setState(() {
                  final firstItem = selectedBillItems.first;
                  int idx = selectedBillItems.indexOf(firstItem);
                  if (idx != -1) {
                    selectedBillItems[idx] = firstItem.copyWith(unitPrice: newPrice);
                  }
                  calculateTotals();
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Applied combo price ₹$price to ${selectedBillItems.first.productName}")));
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCouponsList() {
    if (fetchedCoupons.isEmpty) {
      return Center(child: Text("no_coupons".tr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)));
    }
    return Column(
      children: fetchedCoupons.map((coupon) {
        final code = coupon['coupon_code'] ?? coupon['couponCode'] ?? 'COUPON';
        final pct = coupon['discount_pct'] ?? coupon['discountPct'];
        final fixed = coupon['fixed_price'] ?? coupon['fixedPrice'];
        final desc = coupon['description']?.toString() ?? '';
        final isCouponActive = (coupon['status']?.toString() ?? 'inactive').toLowerCase() == 'active';

        String valueText = "";
        if (pct != null && pct > 0) {
          valueText = "$pct%";
        } else if (fixed != null && fixed > 0) {
          valueText = "₹$fixed";
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(valueText, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF59E0B), fontSize: 16)),
                const SizedBox(width: 8),
                if (isCouponActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text("active".tr, style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            onTap: () {
              setState(() {
                if (pct != null && pct > 0) {
                  globalDiscountType = "%";
                  discountController.text = pct.toString();
                } else if (fixed != null && fixed > 0) {
                  globalDiscountType = "₹";
                  discountController.text = fixed.toString();
                }
                calculateTotals();
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Applied coupon $code ($valueText discount)")));
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiscountsList() {
    if (fetchedDiscounts.isEmpty) {
      return Center(child: Text("no_discounts".tr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)));
    }
    return Column(
      children: fetchedDiscounts.map((disc) {
        final name = disc['discount_name'] ?? disc['discountName'] ?? 'Discount';
        final pct = disc['discount_pct'] ?? disc['discountPct'] ?? 0;
        final desc = disc['description']?.toString() ?? '';
        final isDiscActive = (disc['status']?.toString() ?? 'inactive').toLowerCase() == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("$pct%", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 16)),
                const SizedBox(width: 8),
                if (isDiscActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text("active".tr, style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            onTap: () {
              setState(() {
                globalDiscountType = "%";
                discountController.text = pct.toString();
                calculateTotals();
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Applied discount $name ($pct%)")));
            },
          ),
        );
      }).toList(),
    );
  }
}
