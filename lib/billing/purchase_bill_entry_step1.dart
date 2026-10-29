part of 'purchase_bill_entry.dart';

extension _PurchaseBillEntryPageStateStep1 on _PurchaseBillEntryPageState {
  Widget _buildStep1View() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        final Widget supplierCard = _buildSupplierCard();
        final Widget metadataCard = _buildMetadataAndTimingCard();

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: supplierCard),
              const SizedBox(width: 16),
              Expanded(flex: 6, child: metadataCard),
            ],
          );
        }

        return Column(
          children: [
            supplierCard,
            const SizedBox(height: 16),
            metadataCard,
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // CARD 1: SUPPLIER SELECTION (PHOTO 5)
  // ----------------------------------------------------
  Widget _buildSupplierCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.business_outlined, color: Color(0xFF6366F1), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Supplier Selection",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddSupplierScreen()),
                  ).then((_) => _fetchSuppliers());
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.person_add_alt_1, size: 13, color: Color(0xFF6366F1)),
                      SizedBox(width: 4),
                      Text(
                        "+ Add New Supplier",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            "Select Supplier (Searchable Dropdown) *",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),

          SearchableSupplierDropdown(
            suppliers: suppliers,
            selectedSupplier: selectedSupplier,
            isLoading: isSuppliersLoading,
            onSelected: (supplier) {
              setState(() {
                selectedSupplier = supplier;
              });
            },
          ),

          if (selectedSupplier != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.business, color: Color(0xFF1E293B), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (selectedSupplier!['company_name'] ?? selectedSupplier!['supplier_name'] ?? "Supplier Details").toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Selected",
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildDetailItem(Icons.phone, "Phone: ", (selectedSupplier!['primary_phone'] ?? "-").toString(), screenWidth: MediaQuery.of(context).size.width),
                      _buildDetailItem(Icons.receipt, "GSTIN: ", (selectedSupplier!['gst_number'] ?? "-").toString(), screenWidth: MediaQuery.of(context).size.width),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // CARD 2: PURCHASE METADATA & TIMING (PHOTO 5)
  // ----------------------------------------------------
  Widget _buildMetadataAndTimingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.event_note_outlined, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                "Purchase Metadata & Timing",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2-Column Fields Layout matching Photo 5
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 420;

              if (isWide) {
                return Column(
                  children: [
                    // Row 1: Purchase Date | Purchase Time
                    Row(
                      children: [
                        Expanded(
                          child: _buildCleanDateField(
                            "Purchase Date *",
                            DateFormat('dd - MM - yyyy').format(purchaseDate),
                            _selectPurchaseDate,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildCleanTimeField(
                            "Purchase Time *",
                            _formatTimeOfDay(purchaseTime),
                            _selectPurchaseTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 2: Invoice Number | Delivery Date
                    Row(
                      children: [
                        Expanded(
                          child: _buildCleanDisplayField(
                            "Invoice Number *",
                            invoiceNumber,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildCleanDateField(
                            "Delivery Date",
                            DateFormat('dd - MM - yyyy').format(deliveryDate),
                            _selectDeliveryDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 3: Reference Number | Reference Date
                    Row(
                      children: [
                        Expanded(
                          child: _buildCleanInputField(
                            "Reference Number (Optional)",
                            refNumberController,
                            "PO / Ref No...",
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildCleanDateField(
                            "Reference Date (Optional)",
                            refDate != null ? DateFormat('dd - MM - yyyy').format(refDate!) : DateFormat('dd - MM - yyyy').format(DateTime.now()),
                            _selectRefDate,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Mobile stacked layout
              return Column(
                children: [
                  _buildCleanDateField("Purchase Date *", DateFormat('dd - MM - yyyy').format(purchaseDate), _selectPurchaseDate),
                  const SizedBox(height: 12),
                  _buildCleanTimeField("Purchase Time *", _formatTimeOfDay(purchaseTime), _selectPurchaseTime),
                  const SizedBox(height: 12),
                  _buildCleanDisplayField("Invoice Number *", invoiceNumber),
                  const SizedBox(height: 12),
                  _buildCleanDateField("Delivery Date", DateFormat('dd - MM - yyyy').format(deliveryDate), _selectDeliveryDate),
                  const SizedBox(height: 12),
                  _buildCleanInputField("Reference Number (Optional)", refNumberController, "PO / Ref No..."),
                  const SizedBox(height: 12),
                  _buildCleanDateField("Reference Date (Optional)", refDate != null ? DateFormat('dd - MM - yyyy').format(refDate!) : DateFormat('dd - MM - yyyy').format(DateTime.now()), _selectRefDate),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // CLEAN FORM FIELD BUILDERS (PHOTO 5 AESTHETIC)
  // ----------------------------------------------------
  Widget _buildCleanDateField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanTimeField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanDisplayField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
