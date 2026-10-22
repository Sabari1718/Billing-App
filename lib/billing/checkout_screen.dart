import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/billing/Generate%20Bill.dart'; // Reuse Customer & ProductStock

part 'checkout_screen_logic.dart';

class CheckoutScreen extends StatefulWidget {
  final Customer customer;
  final List<ProductStock> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double additionalCharges;
  final double grandTotal;

  const CheckoutScreen({
    super.key,
    required this.customer,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.additionalCharges,
    required this.grandTotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with CheckoutScreenLogic {
  @override
  Widget build(BuildContext context) {
    final statusText = paymentStatus;
    Color statusColor = Colors.orange;
    if (statusText == "PAID") {
      statusColor = Colors.green;
    } else if (statusText == "UNPAID") {
      statusColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP CUSTOMER INFORMATION HEADER BAR
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    // Back Button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, size: 14, color: Color(0xFF334155)),
                            SizedBox(width: 4),
                            Text("Back", style: TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Customer Info Items
                    Expanded(
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _infoText("Customer", widget.customer.name),
                          _infoText("Mobile", widget.customer.mobile),
                          if (widget.customer.email.isNotEmpty)
                            _infoText("Email", widget.customer.email),
                          if (widget.customer.address.isNotEmpty)
                            _infoText("Address", widget.customer.address),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. MAIN LAYOUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Review Items Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Review Items & Select Payment",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                // Mode Toggle buttons (Bill / Quotation)
                                Row(
                                  children: [
                                    _modeButton(
                                      label: "Bill",
                                      icon: Icons.receipt_long,
                                      isSelected: !isQuotationMode,
                                      color: const Color(0xFF2563EB),
                                      onTap: () => setState(() {
                                        isQuotationMode = false;
                                        // Update payment row default mode
                                        if (payments.isNotEmpty) {
                                          payments.first.mode = "UPI";
                                        }
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    _modeButton(
                                      label: "Quotation",
                                      icon: Icons.description,
                                      isSelected: isQuotationMode,
                                      color: Colors.purple,
                                      onTap: () => setState(() {
                                        isQuotationMode = true;
                                        // Quotation mode default is Cash only
                                        for (var p in payments) {
                                          p.mode = "Cash";
                                        }
                                      }),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Items (${widget.items.length})",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 12),

                            // Items Table
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(0.5),
                                    1: FlexColumnWidth(2.5),
                                    2: FlexColumnWidth(1.2),
                                    3: FlexColumnWidth(1.2),
                                    4: FlexColumnWidth(0.8),
                                    5: FlexColumnWidth(1.2),
                                    6: FlexColumnWidth(1.2),
                                  },
                                  children: [
                                    // Header
                                    TableRow(
                                      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
                                      children: [
                                        _th("#"),
                                        _th("PRODUCT"),
                                        _th("VARIANT"),
                                        _th("WARRANTY"),
                                        _th("QTY"),
                                        _th("UNIT PRICE"),
                                        _th("LINE TOTAL"),
                                      ],
                                    ),
                                    // Rows
                                    ...List.generate(widget.items.length, (idx) {
                                      final item = widget.items[idx];
                                      return TableRow(
                                        decoration: BoxDecoration(
                                          color: idx % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                        ),
                                        children: [
                                          _td((idx + 1).toString()),
                                          _td(item.productName, alignLeft: true),
                                          TableCell(
                                            verticalAlignment: TableCellVerticalAlignment.middle,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDCFCE7),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    item.variant.isNotEmpty ? item.variant : "original",
                                                    style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          _td(item.warranty.isNotEmpty ? item.warranty : "-"),
                                          _td(item.qty.toString(), isBold: true),
                                          _td("₹${item.unitPrice.toStringAsFixed(2)}"),
                                          _td("₹${item.total.toStringAsFixed(2)}", isBold: true),
                                        ],
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Subtotal: ₹${widget.subtotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  if (widget.discount > 0)
                                    Text("Discount: -₹${widget.discount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontSize: 13)),
                                  if (widget.tax > 0)
                                    Text("Tax: +₹${widget.tax.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontSize: 13)),
                                  if (widget.additionalCharges > 0)
                                    Text("Charges: +₹${widget.additionalCharges.toStringAsFixed(2)}", style: const TextStyle(color: Colors.blue, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Grand Total: ₹${widget.grandTotal.toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Payment Method Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isQuotationMode ? "Payment Method (Quotation Mode)" : "Payment Method",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isQuotationMode 
                                  ? "Cash Payment Option Only for Quotation"
                                  : "Split payments across multiple modes (Cash, UPI, Cards, Net Banking, etc.)",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 20),

                            // Payment Rows Table/List
                            ...List.generate(payments.length, (index) {
                              final p = payments[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Mode Dropdown
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("PAYMENT MODE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade200),
                                                ),
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: p.mode,
                                                    isExpanded: true,
                                                    items: (isQuotationMode ? ["Cash"] : ["UPI", "Cash", "Card", "Net Banking"])
                                                        .map((mode) => DropdownMenuItem(
                                                              value: mode,
                                                              child: Text(mode, style: const TextStyle(fontSize: 14)),
                                                            ))
                                                        .toList(),
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() => p.mode = val);
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Amount Input
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("AMOUNT (₹)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                              const SizedBox(height: 6),
                                              TextField(
                                                controller: p.amountController,
                                                keyboardType: TextInputType.number,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                decoration: InputDecoration(
                                                  prefixText: "₹ ",
                                                  fillColor: Colors.white,
                                                  filled: true,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                                ),
                                                onChanged: (_) => setState(() {}), // Trigger total update
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Remove Row Button
                                        IconButton(
                                          onPressed: () => _removePaymentRow(index),
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.red.shade50,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        // Transaction ID (disable if cash)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("TRANSACTION ID", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                              const SizedBox(height: 6),
                                              TextField(
                                                controller: p.transactionIdController,
                                                enabled: p.mode != "Cash",
                                                style: const TextStyle(fontSize: 13),
                                                decoration: InputDecoration(
                                                  hintText: p.mode == "Cash" ? "-" : "e.g. UPI123456",
                                                  fillColor: p.mode == "Cash" ? Colors.grey.shade100 : Colors.white,
                                                  filled: true,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Bank / Branch
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("REFERENCE / BANK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                              const SizedBox(height: 6),
                                              TextField(
                                                controller: p.bankController,
                                                style: const TextStyle(fontSize: 13),
                                                decoration: InputDecoration(
                                                  hintText: "e.g. HDFC / Branch",
                                                  fillColor: Colors.white,
                                                  filled: true,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }),

                            // Add Payment Option
                            if (!isQuotationMode)
                              OutlinedButton.icon(
                                onPressed: _addPaymentRow,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Add Another Payment", style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                  minimumSize: const Size(double.infinity, 48),
                                  side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Payment Summary & Status Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Payment Summary",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              ],
                            ),
                            const Divider(height: 24),
                            _summaryRow("Grand Total", "₹${widget.grandTotal.toStringAsFixed(2)}"),
                            _summaryRow("Paid Amount", "₹${paidAmount.toStringAsFixed(2)}", valueColor: Colors.green, isBold: true),
                            _summaryRow("Balance Due", "₹${balanceDue.toStringAsFixed(2)}", valueColor: balanceDue > 0 ? Colors.red : Colors.grey),
                            _summaryRow("Payments", payments.length.toString()),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Payment Status", style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      if (statusText == "PAID")
                                        const Icon(Icons.check, size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        statusText,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes & Terms Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Notes & Terms",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Enter billing notes, payment terms, or special conditions...",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Bill Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveBill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D), // Green
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isQuotationMode 
                                    ? "Save Quotation" 
                                    : "Save Bill (₹${widget.grandTotal.toStringAsFixed(2)})",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Info header label value helper
  Widget _infoText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        children: [
          TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          TextSpan(text: value, style: const TextStyle(color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // Toggle button helper
  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Table styling helpers
  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    );
  }

  Widget _td(String text, {bool alignLeft = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF1E293B),
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Summary Row Helper
  Widget _summaryRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentRowData {
  String mode;
  final TextEditingController amountController;
  final TextEditingController transactionIdController;
  final TextEditingController bankController;

  PaymentRowData({
    required this.mode,
    double amount = 0.0,
    String transactionId = "",
    String bank = "",
  })  : amountController = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(2) : ""),
        transactionIdController = TextEditingController(text: transactionId),
        bankController = TextEditingController(text: bank);
}
