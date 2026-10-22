part of 'purchase_bill_entry.dart';

extension _PurchaseBillEntryPageStateStep1 on _PurchaseBillEntryPageState {
  Widget _buildStep1View() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.business, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        "Supplier Selection",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddSupplierScreen()),
                      ).then((_) => _fetchSuppliers());
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text("+ Add New Supplier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                "Select Supplier (Searchable Dropdown) *",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                                const Icon(Icons.business, color: Color(0xFF1E293B), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (selectedSupplier!['company_name'] ?? selectedSupplier!['supplier_name'] ?? "Supplier Details").toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Selected",
                              style: TextStyle(
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: CustomPaint(
                          size: const Size(double.infinity, 1),
                          painter: DashedDividerPainter(color: Colors.grey.shade300),
                        ),
                      ),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          _buildDetailItem(
                            Icons.phone,
                            "Phone: ",
                            (selectedSupplier!['primary_phone'] ?? "-").toString(),
                            screenWidth: MediaQuery.of(context).size.width,
                          ),
                          _buildDetailItem(
                            Icons.receipt,
                            "GSTIN: ",
                            (selectedSupplier!['gst_number'] ?? "-").toString(),
                            screenWidth: MediaQuery.of(context).size.width,
                          ),
                          _buildDetailItem(
                            Icons.email,
                            "Email: ",
                            (selectedSupplier!['email'] ?? "-").toString(),
                            screenWidth: MediaQuery.of(context).size.width,
                          ),
                          _buildDetailItem(
                            Icons.location_on,
                            "Location: ",
                            _getSupplierLocation(selectedSupplier!),
                            screenWidth: MediaQuery.of(context).size.width,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Metadata Card
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
                "Purchase Metadata",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),

              _buildDateField("Purchase Date *", DateFormat('MM/dd/yyyy').format(purchaseDate), _selectPurchaseDate),
              const SizedBox(height: 16),
              
              _buildTimeField("Purchase Time *", _formatTimeOfDay(purchaseTime), _selectPurchaseTime),
              const SizedBox(height: 16),

              _buildTextField("Invoice Number *", invoiceNumber, isEditable: false),
              const SizedBox(height: 16),

              _buildDateField("Delivery Date", DateFormat('MM/dd/yyyy').format(deliveryDate), _selectDeliveryDate),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Reference Details Card
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
                "Reference Information (Optional)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),

              _buildInputTextField("Reference Number", refNumberController, "Ref Number..."),
              const SizedBox(height: 16),

              _buildDateField(
                "Reference Date",
                refDate != null ? DateFormat('MM/dd/yyyy').format(refDate!) : "mm/dd/yyyy",
                _selectRefDate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
