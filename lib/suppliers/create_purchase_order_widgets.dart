part of 'create_purchase_order.dart';

extension CreatePurchaseOrderWidgets on _CreatePurchaseOrderPageState {
  Widget _buildTopNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back to orders link
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back, color: AppColors.primary, size: 18),
                SizedBox(width: 4),
                Text(
                  "Back to Orders",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Draft order status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "DRAFT ORDER",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                orderCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicDetailsCard(bool isMobile) {
    return Container(
      width: double.infinity,
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
            "Create Purchase Order",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),

          // Fields layout
          if (isMobile) ...[
            _buildSupplierSelectField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDateField("ORDER DATE", DateFormat('MM/dd/yyyy').format(orderDate), _selectOrderDate)),
                const SizedBox(width: 12),
                Expanded(child: _buildTimeField()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    "EXPECTED DELIVERY",
                    expectedDeliveryDate != null ? DateFormat('MM/dd/yyyy').format(expectedDeliveryDate!) : "mm/dd/yyyy",
                    _selectExpectedDeliveryDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildStatusDropdownField()),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildSupplierSelectField()),
                const SizedBox(width: 12),
                Expanded(child: _buildDateField("ORDER DATE", DateFormat('MM/dd/yyyy').format(orderDate), _selectOrderDate)),
                const SizedBox(width: 12),
                Expanded(child: _buildTimeField()),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    "EXPECTED DELIVERY",
                    expectedDeliveryDate != null ? DateFormat('MM/dd/yyyy').format(expectedDeliveryDate!) : "mm/dd/yyyy",
                    _selectExpectedDeliveryDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildStatusDropdownField()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupplierSelectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SELECT SUPPLIER",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showSupplierSelection,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedSupplier != null
                        ? (selectedSupplier!['supplier_name'] ?? selectedSupplier!['company_name'] ?? "Unknown").toString()
                        : "Search supplier...",
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedSupplier != null ? const Color(0xFF1E293B) : Colors.grey.shade400,
                      fontWeight: selectedSupplier != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.search, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value.contains("dd/yyyy") ? Colors.grey.shade400 : const Color(0xFF1E293B),
                    fontWeight: value.contains("dd/yyyy") ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                Icon(Icons.calendar_month, color: Colors.grey.shade400, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    final String displayTime = _formatTimeOfDay(orderTime);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ORDER TIME",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectOrderTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayTime,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.access_time, color: Colors.grey.shade400, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Widget _buildStatusDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STATUS",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
              items: ["Pending", "Completed", "Cancelled"].map((String val) {
                Color dotColor = Colors.orange;
                if (val == "Completed") dotColor = Colors.green;
                if (val == "Cancelled") dotColor = Colors.red;

                return DropdownMenuItem<String>(
                  value: val,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        val,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedStatus = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order items section title + Manual/Scanner toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Order Items",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              
              // Custom Choice chips
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildToggleChip("Manual", Icons.keyboard, isManual),
                    _buildToggleChip("Scanner", Icons.qr_code_scanner, !isManual),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Items Headers (Only for desktop)
          if (!isMobile) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "PRODUCT / ITEM DESCRIPTION",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "QTY",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "PRICE",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "TAX %",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "TOTAL (EXCL.)",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                  SizedBox(width: 48), // Match width of delete button
                ],
              ),
            ),
            const Divider(),
          ],

          // Item lists
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (isMobile) {
                return _buildMobileItemCard(item, index);
              } else {
                return _buildDesktopItemRow(item, index);
              }
            },
          ),
          const SizedBox(height: 16),

          // Add another product button
          CustomPaint(
            painter: DashedBorderPainter(color: AppColors.primary, borderRadius: 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: InkWell(
                onTap: _addItemRow,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add, color: AppColors.primary, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "Add Another Product",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String text, IconData icon, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isManual = (text == "Manual");
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? AppColors.primary : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: active ? AppColors.primary : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopItemRow(OrderItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Search Box
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _showProductSelection(item),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product != null
                            ? (item.product!['product_name'] ?? item.product!['name'] ?? "Unknown").toString()
                            : "Search product...",
                        style: TextStyle(
                          fontSize: 13,
                          color: item.product != null ? const Color(0xFF1E293B) : Colors.grey.shade400,
                          fontWeight: item.product != null ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Qty Input
          Expanded(
            child: TextField(
              controller: item.qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Price Input
          Expanded(
            child: TextField(
              controller: item.priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "Price",
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),

          // Tax Input
          Expanded(
            child: TextField(
              controller: item.taxController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: "%",
                suffixStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Total Box
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "₹${item.total.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Delete button
          InkWell(
            onTap: () => _removeItemRow(index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileItemCard(OrderItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Header (Title + Delete)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Product Row #${index + 1}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              
              InkWell(
                onTap: () => _removeItemRow(index),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Product Search Box
          InkWell(
            onTap: () => _showProductSelection(item),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.product != null
                          ? (item.product!['product_name'] ?? item.product!['name'] ?? "Unknown").toString()
                          : "Search product...",
                      style: TextStyle(
                        fontSize: 13,
                        color: item.product != null ? const Color(0xFF1E293B) : Colors.grey.shade400,
                        fontWeight: item.product != null ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.search, color: Colors.grey.shade400, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Qty & Price side-by-side
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("QUANTITY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: item.qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PRICE (EXCL. TAX)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: item.priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: "Price",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tax % & Total side-by-side
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TAX %", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: item.taxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        suffixText: "%",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("TOTAL AMOUNT", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        "₹${item.total.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(bool isMobile) {
    final Widget notesBox = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ORDER NOTES",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Add any special instructions or terms...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );

    final Widget summaryBox = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSummaryRow("Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
          const SizedBox(height: 10),
          _buildSummaryRow("Tax Total", "₹${taxTotal.toStringAsFixed(0)}"),
          const SizedBox(height: 10),

          // Shipping charges editable field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Shipping",
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                width: 80,
                height: 32,
                child: TextField(
                  controller: shippingController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: "₹",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grand Total",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
              ),
              Text(
                "₹${grandTotal.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            notesBox,
            const SizedBox(height: 20),
            summaryBox,
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: notesBox),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: summaryBox),
          ],
        ),
      );
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel button
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.grey.shade300),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF475569),
          ),
          child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(width: 12),

        // Save Button
        ElevatedButton.icon(
          onPressed: isSaving ? null : _savePurchaseOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5), // Indigo blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 18),
          label: const Text("Save Purchase Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }
}
