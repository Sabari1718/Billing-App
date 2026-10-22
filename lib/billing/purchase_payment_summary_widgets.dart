part of 'purchase_payment_summary.dart';

extension _PurchasePaymentSummaryPageStateWidgets on _PurchasePaymentSummaryPageState {
  Widget _buildStepIndicator() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStepRow(1, "Supplier & Metadata", "Step 1", true, false),
          const Padding(
            padding: EdgeInsets.only(left: 17, top: 4, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 18,
                child: VerticalDivider(color: Colors.grey, width: 2, thickness: 1),
              ),
            ),
          ),
          _buildStepRow(2, "Products Purchase Entry", "Step 2", true, false),
          const Padding(
            padding: EdgeInsets.only(left: 17, top: 4, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 18,
                child: VerticalDivider(color: Colors.grey, width: 2, thickness: 1),
              ),
            ),
          ),
          _buildStepRow(3, "Payment & Summary", "Step 3", false, true),
        ],
      ),
    );
  }

  Widget _buildStepRow(int stepNum, String title, String subtitle, bool isCompleted, bool isActive) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF10B981)
                : isActive
                    ? Colors.blue.shade600
                    : Colors.white,
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : isActive
                      ? Colors.blue.shade600
                      : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    stepNum.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.blue.shade600 : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsCard() {
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payment, color: Color(0xFF1E293B)),
                  SizedBox(width: 8),
                  Text(
                    "Payment Details & Notes",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isSplitPayment,
                    activeColor: Colors.blue.shade600,
                    onChanged: (val) {
                      setState(() {
                        isSplitPayment = val ?? false;
                        if (isSplitPayment && paymentsSplits.isEmpty) {
                          paymentsSplits.add(PaymentRowData(mode: "Cash", amount: balanceDue));
                        }
                      });
                    },
                  ),
                  const Text(
                    "Split Payment (Multiple Modes)",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (!isSplitPayment) ...[
            const Text("Payment Mode *", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            _buildDropdown(
              value: selectedPaymentMode,
              items: const [
                "Credit / Pay Later",
                "Cash",
                "UPI / GPay / PhonePe",
                "Credit Card",
                "Debit Card",
                "Net Banking",
                "Bank Transfer (NEFT/RTGS/IMPS)",
                "Cheque",
                "Demand Draft (DD)",
                "Wallet (PhonePe, Paytm, etc.)"
              ],
              onChanged: (val) {
                setState(() {
                  selectedPaymentMode = val!;
                  if (selectedPaymentMode == "Credit / Pay Later") {
                    selectedPaymentStatus = "Pending (Unpaid)";
                  } else {
                    selectedPaymentStatus = "Fully Paid";
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            const Text("Payment Status *", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            _buildDropdown(
              value: selectedPaymentStatus,
              items: const ["Pending (Unpaid)", "Fully Paid", "Partially Paid"],
              onChanged: (val) {
                setState(() {
                  selectedPaymentStatus = val!;
                });
              },
            ),
            
            if (selectedPaymentStatus == "Partially Paid") ...[
              const SizedBox(height: 16),
              const Text("Paid Amount (₹) *", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: singlePaidAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: "0.00",
                  prefixText: "₹ ",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 16),

            const Text("Ref / Note (Optional)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: singleRefNoteController,
              decoration: InputDecoration(
                hintText: "Optional payment note...",
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.credit_card, size: 18, color: Colors.blue),
                          SizedBox(width: 6),
                          Text(
                            "Add Multiple Payment Splits",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${paymentsSplits.length} Modes",
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paymentsSplits.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final row = paymentsSplits[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Split Payment Mode #${index + 1}",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade700),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _removePaymentSplit(index),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            const Text("Payment Mode *", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            _buildDropdown(
                              value: row.mode,
                              items: const [
                                "Credit / Pay Later",
                                "Cash",
                                "UPI / GPay / PhonePe",
                                "Credit Card",
                                "Debit Card",
                                "Net Banking",
                                "Bank Transfer (NEFT/RTGS/IMPS)",
                                "Cheque",
                                "Demand Draft (DD)",
                                "Wallet (PhonePe, Paytm, etc.)"
                              ],
                              onChanged: (val) {
                                setState(() {
                                  row.mode = val!;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text("Amount (₹) *", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: row.amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: "0.00",
                                prefixText: "₹ ",
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            const Text("Txn / Ref No (Optional)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: row.txnController,
                              decoration: InputDecoration(
                                hintText: "Optional transaction reference...",
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _addPaymentSplit,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text("Add Payment Mode", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade600,
                          side: BorderSide(color: Colors.blue.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Text(
                              "Total Paid: ₹${totalPaid.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: balanceDue > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                              border: Border.all(color: balanceDue > 0 ? Colors.red.shade200 : Colors.green.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Balance Due: ₹${balanceDue.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.bold, 
                                color: balanceDue > 0 ? const Color(0xFF991B1B) : const Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Text("Payment Date", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _selectPaymentDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MM/dd/yyyy').format(paymentDate),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.calendar_month, color: Colors.grey.shade400, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text("Notes / Terms & Conditions", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          TextField(
            controller: termsConditionsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter invoice notes, terms, or internal payment remarks...",
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
              const Text(
                "Purchase Summary",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: finalPaymentStatus == "Fully Paid" 
                      ? const Color(0xFFDCFCE7) 
                      : finalPaymentStatus == "Partially Paid" 
                          ? const Color(0xFFFFEDD5)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  finalPaymentStatus.toUpperCase(),
                  style: TextStyle(
                    color: finalPaymentStatus == "Fully Paid" 
                        ? const Color(0xFF166534) 
                        : finalPaymentStatus == "Partially Paid" 
                            ? const Color(0xFFC2410C)
                            : const Color(0xFF991B1B),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow("Total Products", "$totalProducts Items"),
          const SizedBox(height: 12),
          _buildSummaryRow("Total Quantity", "${totalQuantity.toInt()} Units"),
          const SizedBox(height: 12),
          _buildSummaryRow("Subtotal (Excl. Tax)", "₹${subtotalExcl.toStringAsFixed(2)}"),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("Extra Charges", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showAddExtraChargeDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.blue, size: 10),
                          SizedBox(width: 2),
                          Text("Add Charge", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Text("+ ₹${totalExtraCharges.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
            ],
          ),
          if (extraChargesList.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                children: extraChargesList.map((charge) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("- ${charge['name']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Row(
                          children: [
                            Text("₹${(charge['amount'] as double).toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                  setState(() {
                                    extraChargesList.remove(charge);
                                    _calculateSummary();
                                  });
                              },
                              child: const Icon(Icons.close, size: 12, color: Colors.red),
                            )
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Taxable Amount",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                ),
                Text(
                  "₹${(subtotalExcl + totalExtraCharges - billDiscountAmount).toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildSummaryRow("Total GST Amount", "+ ₹${totalGstAmount.toStringAsFixed(2)}"),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bill Level Discount", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade50,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: discountType,
                        items: const ["%", "₹"].map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            discountType = val!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    height: 28,
                    child: TextField(
                      controller: discountValController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Round Off", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
              SizedBox(
                width: 80,
                height: 28,
                child: TextField(
                  controller: roundOffController,
                  focusNode: roundOffFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: DashedDividerPainter(color: Colors.grey.shade300),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grand Total",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              Text(
                "₹${roundedGrandTotal.toStringAsFixed(2)}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow("Advance / Paid Amount", "₹${totalPaid.toStringAsFixed(2)}"),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Balance Amount", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(
                "₹${balanceDue.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 13, 
                  color: balanceDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500, size: 20),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBottomButtonsBar() {
    final double width = MediaQuery.of(context).size.width;
    final bool useVertical = width < 650;

    if (useVertical) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : () => _submitPurchaseBill(showPrintPreview: false),
              icon: const Icon(Icons.save, size: 16, color: Colors.white),
              label: const Text("Save Purchase Bill", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : () => _submitPurchaseBill(showPrintPreview: true),
              icon: const Icon(Icons.print, size: 16, color: Color(0xFF1E293B)),
              label: const Text("Save & Print Preview", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text(
                "← Back to Product Entry",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text(
              "← Back to Product Entry",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: isSubmitting ? null : () => _submitPurchaseBill(showPrintPreview: true),
                icon: const Icon(Icons.print, size: 16, color: Color(0xFF1E293B)),
                label: const Text(
                  "Save & Print Preview",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : () => _submitPurchaseBill(showPrintPreview: false),
                icon: const Icon(Icons.save, size: 16, color: Colors.white),
                label: const Text(
                  "Save Purchase Bill",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
