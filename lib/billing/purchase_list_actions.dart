part of 'purchase_list.dart';

extension _PurchaseListPageActions on _PurchaseListPageState {
  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFFEE2E2);
    Color txt = const Color(0xFF991B1B);
    Color dot = const Color(0xFFEF4444);

    if (status.toLowerCase().contains("paid") && !status.toLowerCase().contains("unpaid") && !status.toLowerCase().contains("partial")) {
      bg = const Color(0xFFDCFCE7);
      txt = const Color(0xFF166534);
      dot = const Color(0xFF22C55E);
    } else if (status.toLowerCase().contains("partial") || status.toLowerCase().contains("pending")) {
      bg = const Color(0xFFFEF3C7);
      txt = const Color(0xFF92400E);
      dot = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: txt)),
        ],
      ),
    );
  }

  // --- PRINT & SHARE PDF IMPLEMENTATION ---
  Future<Uint8List> _generateInvoicePDF(dynamic bill) async {
    final pdf = pw.Document();
    final items = bill['items'] as List? ?? [];
    final supplierName = bill['supplier_name'] ?? bill['supplier']?['supplier_name'] ?? bill['company_name'] ?? "Mass";
    final invoiceNo = bill['invoice_no'] ?? bill['bill_no'] ?? bill['purchase_bill_no'] ?? "-";
    final grandTotal = double.tryParse(bill['grand_total']?.toString() ?? "0.0") ?? 0.0;
    final discount = double.tryParse(bill['discount_amount']?.toString() ?? "0.0") ?? 0.0;
    final subtotal = double.tryParse(bill['subtotal']?.toString() ?? "0.0") ?? 0.0;
    final gstTotal = double.tryParse(bill['tax_amount']?.toString() ?? "0.0") ?? 0.0;
    final paymentMode = bill['payment_mode'] ?? bill['payment_method'] ?? "Cash";
    final paymentStatus = (bill['payment_status'] ?? bill['status'] ?? "Unpaid").toString();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("PURCHASE INVOICE", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                        pw.SizedBox(height: 4),
                        pw.Text("Invoice No: $invoiceNo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Supplier Name:", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                        pw.Text(supplierName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(height: 24, thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 12),
                pw.Text("Purchased Products", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(4),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(2),
                    4: pw.FlexColumnWidth(2),
                    5: pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("S.No", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Product Name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Qty", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Excl. Rate", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("GST %", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Amount", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      ],
                    ),
                    ...List.generate(items.length, (idx) {
                      final item = items[idx];
                      final name = item['product_name'] ?? item['name'] ?? "Product";
                      final qty = item['quantity'] ?? item['qty'] ?? 0;
                      final exclRate = double.tryParse(item['purchase_price']?.toString() ?? item['rate']?.toString() ?? "0.0") ?? 0.0;
                      final taxRate = double.tryParse(item['tax_rate']?.toString() ?? "0.0") ?? 0.0;
                      final total = double.tryParse(item['total']?.toString() ?? item['amount']?.toString() ?? "0.0") ?? (qty * exclRate * (1 + taxRate/100));

                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${idx + 1}", style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(name.toString(), style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(qty.toString(), style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Rs.${exclRate.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${taxRate.toStringAsFixed(2)}%", style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Rs.${total.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Payment Mode: $paymentMode", style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text("Payment Status: $paymentStatus", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: paymentStatus.toLowerCase().contains("paid") ? PdfColors.green : PdfColors.red)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Subtotal (Excl. Tax): Rs.${subtotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text("GST Amount: + Rs.${gstTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        if (discount > 0) pw.Text("Discount: - Rs.${discount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                        if (discount > 0) pw.SizedBox(height: 4),
                        pw.Divider(thickness: 1, color: PdfColors.grey300),
                        pw.Text("Grand Total: Rs.${grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _downloadPDF(dynamic bill) async {
    try {
      final bytes = await _generateInvoicePDF(bill);
      final invoiceNo = bill['invoice_no'] ?? bill['bill_no'] ?? "purchase";
      await Printing.sharePdf(
        bytes: bytes,
        filename: "Invoice_$invoiceNo.pdf",
      );
    } catch (e) {
      AppLogger.error("Download PDF failed", e);
    }
  }

  Future<void> _printBill(dynamic bill) async {
    try {
      final bytes = await _generateInvoicePDF(bill);
      final invoiceNo = bill['invoice_no'] ?? bill['bill_no'] ?? "purchase";
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: "Invoice_$invoiceNo.pdf",
      );
    } catch (e) {
      AppLogger.error("Print Bill failed", e);
    }
  }

  // --- RECONSTRUCTED VIEW BILL DETAILS DIALOG ---
  void _viewBillDetails(dynamic bill) {
    showDialog(
      context: context,
      builder: (context) {
        final items = bill['items'] as List? ?? [];
        final invoiceNo = bill['invoice_no'] ?? bill['bill_no'] ?? bill['purchase_bill_no'] ?? "-";
        final grandTotal = double.tryParse(bill['grand_total']?.toString() ?? "0.0") ?? 0.0;
        final subtotal = double.tryParse(bill['subtotal']?.toString() ?? "0.0") ?? 0.0;
        final gstTotal = double.tryParse(bill['tax_amount']?.toString() ?? "0.0") ?? 0.0;
        final paymentMode = bill['payment_mode'] ?? bill['payment_method'] ?? "Cash";
        final paymentStatus = (bill['payment_status'] ?? bill['status'] ?? "Unpaid").toString();

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Purchased Products",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),

                  // Products Table with Horizontal Scroll
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        border: TableBorder.symmetric(
                          inside: BorderSide(color: Colors.grey.shade200, width: 0.5),
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(50),
                          1: FixedColumnWidth(160),
                          2: FixedColumnWidth(64),
                          3: FixedColumnWidth(50),
                          4: FixedColumnWidth(50),
                          5: FixedColumnWidth(80),
                          6: FixedColumnWidth(80),
                          7: FixedColumnWidth(80),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                            children: const [
                              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("S.NO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("PRODUCT NAME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("GST %", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("QTY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("UNIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("EXCL. RATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("INCL. RATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("AMOUNT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                            ],
                          ),
                          ...List.generate(items.length, (idx) {
                            final item = items[idx];
                            final name = item['product_name'] ?? item['name'] ?? "Product";
                            final qty = item['quantity'] ?? item['qty'] ?? 0;
                            final unit = item['unit'] ?? "Pcs";
                            final taxRate = double.tryParse(item['tax_rate']?.toString() ?? "0.0") ?? 0.0;
                            final exclRate = double.tryParse(item['purchase_price']?.toString() ?? item['rate']?.toString() ?? "0.0") ?? 0.0;
                            final inclRate = exclRate * (1 + taxRate / 100);
                            final total = double.tryParse(item['total']?.toString() ?? item['amount']?.toString() ?? "0.0") ?? (qty * inclRate);

                            return TableRow(
                              children: [
                                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("${idx + 1}", style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text(name.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("${taxRate.toStringAsFixed(2)}%", style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text(qty.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text(unit, style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("₹${exclRate.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("₹${inclRate.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom detail layout (Vertical Column for Mobile compatibility)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Payment Mode:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          Text(paymentMode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Status:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          _buildStatusPill(paymentStatus),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Subtotal (Excl. Tax):", style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                          Text("₹${subtotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("GST Amount:", style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                          Text("+ ₹${gstTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Grand Total:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(
                            "₹${grandTotal.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Actions row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text("Close", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _downloadPDF(bill),
                        icon: const Icon(Icons.download, size: 14),
                        label: const Text("Download PDF", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _printBill(bill),
                        icon: const Icon(Icons.print, size: 14),
                        label: const Text("Print Bill", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
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
  }

  void _editBill(dynamic bill) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseBillEntryPage(editBill: bill),
      ),
    );
    if (res == true) {
      _fetchPurchaseBills();
    }
  }
}
