part of 'purchase_bill_entry.dart';

extension _PurchaseBillEntryPageStateStep3 on _PurchaseBillEntryPageState {
  Widget _buildStep3View() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Summary Details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              
              _buildSummaryField("Invoice Number", invoiceNumber),
              const SizedBox(height: 12),
              _buildSummaryField(
                "Supplier",
                selectedSupplier != null ? (selectedSupplier!['supplier_name'] ?? selectedSupplier!['company_name'] ?? "-").toString() : "-",
              ),
              
              const Divider(height: 24),

              _buildSummaryRow("Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
              const SizedBox(height: 10),
              _buildSummaryRow("Tax Total", "₹${taxTotal.toStringAsFixed(0)}"),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Shipping Charges",
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(
                    width: 100,
                    height: 36,
                    child: TextField(
                      controller: shippingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: "₹",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Grand Total",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    "₹${grandTotal.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Payment Information",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),

              const Text(
                "Payment Method *",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ["Cash", "Bank Transfer", "UPI", "Credit Card"].map((method) {
                  final isSelected = selectedPaymentMethod == method;
                  return ChoiceChip(
                    label: Text(
                      method,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          selectedPaymentMethod = method;
                        });
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _buildInputTextField("Purchase Notes / Details", notesController, "Add purchase notes here..."),
            ],
          ),
        ),
      ],
    );
  }
}
