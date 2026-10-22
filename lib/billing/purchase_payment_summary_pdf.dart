part of 'purchase_payment_summary.dart';

extension _PurchasePaymentSummaryPageStatePDF on _PurchasePaymentSummaryPageState {
  void _showPrintPreviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Print Invoice Preview",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        Navigator.pop(context); // close preview
                        Navigator.pop(context, true); // pop step 3 page
                      },
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "PURCHASE INVOICE",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      fontFamily: 'serif',
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Invoice #: ${widget.invoiceNumber}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Date: ${DateFormat('yyyy-MM-dd').format(widget.purchaseDate)} ${widget.purchaseTime.format(context)}",
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Supplier Details:",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${widget.supplier['supplier_name'] ?? widget.supplier['company_name'] ?? 'Mass Trading'}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "GSTIN: ${widget.supplier['gst_number'] ?? widget.supplier['gstin'] ?? '-'}",
                                    style: const TextStyle(fontSize: 11, color: Colors.black),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Phone: ${widget.supplier['mobile'] ?? widget.supplier['phone'] ?? '-'}",
                                    style: const TextStyle(fontSize: 11, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          Table(
                            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(4),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(1.2),
                              4: FlexColumnWidth(1.5),
                              5: FlexColumnWidth(2),
                              6: FlexColumnWidth(1.5),
                              7: FlexColumnWidth(2),
                              8: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey.shade50),
                                children: const [
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text("SI NO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)), textAlign: TextAlign.center)),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text("PRODUCT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text("BATCH", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)), textAlign: TextAlign.center)),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text("QTY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)), textAlign: TextAlign.center)),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text("UNIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)), textAlign: TextAlign.center)),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text("RATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)), textAlign: TextAlign.right)),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text("GST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)), textAlign: TextAlign.center)),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text("TAXABLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)), textAlign: TextAlign.right)),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text("TOTAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)), textAlign: TextAlign.right)),
                                ],
                              ),
                              ...List.generate(widget.items.length, (idx) {
                                final item = widget.items[idx];
                                return TableRow(
                                  children: [
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text("${idx + 1}", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text(item.productName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text("-", style: TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text("${item.qty.toInt()}", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text(item.unit, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text("₹${item.rateExcl.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text("${item.gstPercent.toInt()}%", style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text("₹${item.taxable.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text("₹${item.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                                  ],
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Payment Mode: ${isSplitPayment ? 'Split' : selectedPaymentMode}",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Status: $finalPaymentStatus",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Total Products: $totalProducts", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text("Total Qty: ${totalQuantity.toInt()}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text("Taxable Total: ₹${(subtotalExcl + totalExtraCharges - billDiscountAmount).toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text("Tax Total: ₹${totalGstAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Grand Total: ₹${roundedGrandTotal.toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // close preview
                        Navigator.pop(context, true); // pop step 3 page
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text("Close", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _shareAndDownloadPDF();
                      },
                      icon: const Icon(Icons.share, size: 16, color: Color(0xFF1E293B)),
                      label: const Text("Share & Download", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _generateAndDownloadPDF();
                      },
                      icon: const Icon(Icons.print, size: 16, color: Colors.white),
                      label: const Text("Print Invoice", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndDownloadPDF() async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "PURCHASE INVOICE",
                            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text("Invoice #: ${widget.invoiceNumber}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text("Date: ${DateFormat('yyyy-MM-dd').format(widget.purchaseDate)}", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("Supplier Details:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text("${widget.supplier['supplier_name'] ?? widget.supplier['company_name'] ?? 'Mass Trading'}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text("GSTIN: ${widget.supplier['gst_number'] ?? widget.supplier['gstin'] ?? '-'}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Phone: ${widget.supplier['mobile'] ?? widget.supplier['phone'] ?? '-'}", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("SI NO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("PRODUCT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("QTY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("UNIT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("RATE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("GST", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("TAXABLE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                        ],
                      ),
                      ...List.generate(widget.items.length, (idx) {
                        final item = widget.items[idx];
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${idx + 1}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.productName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${item.qty.toInt()}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.unit, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Rs.${item.rateExcl.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${item.gstPercent.toInt()}%", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Rs.${item.taxable.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Rs.${item.total.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Payment Mode: ${isSplitPayment ? 'Split' : selectedPaymentMode}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Status: $finalPaymentStatus", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("Total Products: $totalProducts", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Total Qty: ${totalQuantity.toInt()}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Taxable Total: Rs.${(subtotalExcl + totalExtraCharges - billDiscountAmount).toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Tax Total: Rs.${totalGstAmount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 6),
                          pw.Text("Grand Total: Rs.${roundedGrandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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

      final bytes = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: "PurchaseInvoice_${widget.invoiceNumber}.pdf",
      );
    } catch (e) {
      AppLogger.error("PDF generation failed", e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _shareAndDownloadPDF() async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "PURCHASE INVOICE",
                            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text("Invoice #: ${widget.invoiceNumber}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text("Date: ${DateFormat('yyyy-MM-dd').format(widget.purchaseDate)}", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("Supplier Details:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text("${widget.supplier['supplier_name'] ?? widget.supplier['company_name'] ?? 'Mass Trading'}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text("GSTIN: ${widget.supplier['gst_number'] ?? widget.supplier['gstin'] ?? '-'}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Phone: ${widget.supplier['mobile'] ?? widget.supplier['phone'] ?? '-'}", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("SI NO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("PRODUCT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("QTY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("UNIT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("RATE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("GST", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("TAXABLE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                        ],
                      ),
                      ...List.generate(widget.items.length, (idx) {
                        final item = widget.items[idx];
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${idx + 1}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.productName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${item.qty.toInt()}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.unit, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Rs.${item.rateExcl.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${item.gstPercent.toInt()}%", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Rs.${item.taxable.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Rs.${item.total.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Payment Mode: ${isSplitPayment ? 'Split' : selectedPaymentMode}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Status: $finalPaymentStatus", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("Total Products: $totalProducts", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Total Qty: ${totalQuantity.toInt()}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Taxable Total: Rs.${(subtotalExcl + totalExtraCharges - billDiscountAmount).toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Tax Total: Rs.${totalGstAmount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 6),
                          pw.Text("Grand Total: Rs.${roundedGrandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: "PurchaseInvoice_${widget.invoiceNumber}.pdf",
      );
    } catch (e) {
      AppLogger.error("PDF share failed", e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Share Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
