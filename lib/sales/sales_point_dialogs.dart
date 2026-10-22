part of 'sales_point.dart';

extension _SalesPointPageStateDialogs on _SalesPointPageState {
  void _showProductDetails(StockItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int tempQty = 1;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final double savings = item.mrp - item.sellingPrice;
            final double savingsPct = item.mrp > 0 ? (savings / item.mrp) * 100 : 0.0;
            
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Product Specifications & Details",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(height: 24),
                    
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 550;
                        final Widget imageWidget = Container(
                          height: isWide ? 180 : 130,
                          width: isWide ? 180 : double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Icon(Icons.inventory_2_outlined, size: isWide ? 64 : 48, color: Colors.grey.shade400),
                          ),
                        );
                        
                        final Widget detailsWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildBadge("GENERAL", Colors.blue.shade50, AppColors.primary),
                                const SizedBox(width: 8),
                                _buildBadge("GENERIC", Colors.purple.shade50, AppColors.secondary),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            if (item.variantLabel.isNotEmpty && item.variantLabel != "Standard")
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Variant: ${item.variantLabel}",
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("SKU: ${item.sku.isNotEmpty ? item.sku : 'N/A'}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text("Barcode: ${item.barcode.isNotEmpty ? item.barcode : 'N/A'}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  _buildBarcodeGraphic(),
                                ],
                              ),
                            ),
                          ],
                        );
 
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              imageWidget,
                              const SizedBox(width: 20),
                              Expanded(child: detailsWidget),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              imageWidget,
                              const SizedBox(height: 16),
                              detailsWidget,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹${item.sellingPrice.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "MRP: ₹${item.mrp.toStringAsFixed(0)}",
                                style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ],
                          ),
                          if (savings > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Save ₹${savings.toStringAsFixed(0)} (${savingsPct.toStringAsFixed(0)}% OFF)",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow("Total Stock", "${item.totalQty} Units", false),
                          const Divider(height: 1),
                          _buildDetailRow("Available Stock", "${item.qty} Units", true),
                          const Divider(height: 1),
                          _buildDetailRow("Brand", item.brand.isNotEmpty ? item.brand : "Generic", false),
                          const Divider(height: 1),
                          _buildQuantityControllerRow("Bill Quantity", tempQty, (val) {
                            setModalState(() {
                              tempQty = val;
                            });
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          addToBill(item, tempQty);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: Text(
                          "Add to Bill (₹${(tempQty * item.sellingPrice).toStringAsFixed(0)})",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
 
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 580;
                        final Widget featuresWidget = _buildKeyFeaturesSection();
                        final Widget warrantyWidget = _buildWarrantySection();
                        
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: featuresWidget),
                              const SizedBox(width: 16),
                              Expanded(child: warrantyWidget),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              featuresWidget,
                              const SizedBox(height: 16),
                              warrantyWidget,
                            ],
                          );
                        }
                      },
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

  Widget _buildKeyFeaturesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Key Features & Specifications",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem("High Performance & Premium Quality Build"),
          _buildFeatureItem("Authentic Verified Brand Serial & SKU Code"),
          _buildFeatureItem("Fully Tested In-Stock Warehouse Allocation"),
          _buildFeatureItem("Ready for Immediate Sales Billing & Dispatch"),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.green.shade600, size: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Colors.indigo.shade600, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Warranty & Guarantee Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildWarrantyCard(
            title: "WARRANTY COVERAGE",
            subtitle: "1 Year Brand Manufacturer Warranty",
            bg: Colors.blue.shade50.withOpacity(0.4),
            borderCol: Colors.blue.shade100,
            iconCol: Colors.blue.shade600,
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 10),
          _buildWarrantyCard(
            title: "GUARANTEE / RETURN",
            subtitle: "7 Days Replacement Guarantee on Defects",
            bg: Colors.green.shade50.withOpacity(0.4),
            borderCol: Colors.green.shade100,
            iconCol: Colors.green.shade600,
            icon: Icons.replay_outlined,
          ),
          const SizedBox(height: 10),
          _buildWarrantyCard(
            title: "VERIFICATION SUPPORT",
            subtitle: "Official Invoice & Barcode Verification",
            bg: Colors.purple.shade50.withOpacity(0.4),
            borderCol: Colors.purple.shade100,
            iconCol: Colors.purple.shade600,
            icon: Icons.qr_code_scanner_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyCard({
    required String title,
    required String subtitle,
    required Color bg,
    required Color borderCol,
    required Color iconCol,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconCol, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: iconCol, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: textCol, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          highlight
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF854D0E), fontSize: 14),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 14),
                ),
        ],
      ),
    );
  }

  Widget _buildQuantityControllerRow(String label, int currentQty, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                onPressed: currentQty > 1 ? () => onChanged(currentQty - 1) : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                alignment: Alignment.center,
                child: Text(
                  "$currentQty",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () => onChanged(currentQty + 1),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBarcodeGraphic() {
    return Container(
      height: 36,
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(15, (index) {
          final width = (index % 3 == 0) ? 3.0 : (index % 2 == 0 ? 1.5 : 1.0);
          final color = (index == 5 || index == 11) ? Colors.transparent : Colors.black;
          return Container(
            width: width,
            color: color,
          );
        }),
      ),
    );
  }
}
