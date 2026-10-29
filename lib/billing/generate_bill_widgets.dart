part of 'Generate Bill.dart';

extension _CustomerScreenStateWidgets on _CustomerScreenState {
  Widget _buildAddNewCustomerButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [const Color(0xFF2563EB).withOpacity(0.05), const Color(0xFF1D4ED8).withOpacity(0.05)],
        ),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _launchCustomerRegistration,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Text(
                  "Add New Customer",
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCustomerCompact(Customer customer) {
    final bool isUnregistered = customer.type.toLowerCase().contains("unreg") || customer.type.isEmpty;
    final String cType = customer.type.trim().isEmpty ? "Unregistered" : customer.type;
    final String addr = customer.address.trim().isEmpty ? "-" : customer.address;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Customer Name [ UNREGISTERED ] / [ ✔ VERIFIED ] [close]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  customer.name.trim().isEmpty ? "CUSTOMER" : customer.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUnregistered ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isUnregistered ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Text(
                      isUnregistered ? "UNREGISTERED" : "✔ VERIFIED",
                      style: TextStyle(
                        color: isUnregistered ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectedCustomer = null;
                        _searchController.clear();
                        results = [];
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4-column responsive data row matching web screenshot
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 550;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildCustomerInfoCol("CUSTOMER NAME", customer.name)),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _buildCustomerInfoCol("PHONE", customer.mobile)),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _buildCustomerInfoCol("ADDRESS", addr)),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: _buildCustomerInfoCol("CUSTOMER TYPE", cType)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildCustomerInfoCol("CUSTOMER NAME", customer.name)),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildCustomerInfoCol("PHONE", customer.mobile)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildCustomerInfoCol("ADDRESS", addr)),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildCustomerInfoCol("CUSTOMER TYPE", cType)),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty ? "-" : value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildChargeInput({required String label, required TextEditingController controller, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => calculateTotals(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "0",
            hintStyle: TextStyle(color: Colors.grey.shade300),
            prefixIcon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow("item_total".tr, "₹${totalItemAmount.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _summaryRow("gst_tax".tr, "+ ₹${totalTaxAmount.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _summaryRow("additional_charges".tr, "+ ₹${totalAdditionalCharges.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _summaryRow("discount".tr, "- ₹${totalDiscountAmount.toStringAsFixed(2)}", isNegative: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("payable_total".tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text("₹${finalPayableAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.red : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _qtyActionBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 14, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _qtyBtnLarge(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
        ),
      ),
    );
  }

  Widget _variantBadge(ProductStock item) {
    if (item.variant.contains(" | ")) {
      final labels = item.variant.split(" | ");
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: labels.map((l) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _singleVariantBadge(l),
          );
        }).toList(),
      );
    }
    return _singleVariantBadge(item.variant);
  }

  Widget _singleVariantBadge(String label) {
    Color color;
    if (label == "Original") {
      color = Colors.green;
    } else if (label == "Import") {
      color = Colors.orange;
    } else if (label == "Complimentary" || label == "Compliment") {
      color = Colors.purple;
    } else {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _mobileInfoChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        splashRadius: 22,
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? badgeColor, bool isHighlight = false, bool noPadding = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: noPadding ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: badgeColor != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value, 
                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.normal,
                        fontSize: isHighlight ? 18 : 13,
                        color: isHighlight ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
