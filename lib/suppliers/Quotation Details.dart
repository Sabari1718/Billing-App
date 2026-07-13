import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import 'package:billingapp/utils/app_logger.dart';
import 'package:billingapp/suppliers/Edit Quotation.dart';

class QuotationDetailsPage extends StatefulWidget {
  final int quotationId;
  final String token;

  const QuotationDetailsPage({
    super.key,
    required this.quotationId,
    required this.token,
  });

  @override
  State<QuotationDetailsPage> createState() => _QuotationDetailsPageState();
}

class _QuotationDetailsPageState extends State<QuotationDetailsPage> {
  Map<String, dynamic>? quotation;
  bool isLoading = true;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    fetchQuotationDetails();
  }

  Future<void> fetchQuotationDetails() async {
    final url = "https://billing.srivagroups.in/api/quotation/${widget.quotationId}";
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          quotation = data is Map && data.containsKey('data') ? data['data'] : data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      AppLogger.error("Error fetching details", e);
      setState(() => isLoading = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (quotation == null) return;
    setState(() => isDownloading = true);

    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      
      final items = quotation!['items'] as List? ?? [];
      final grandTotal = _calculateGrandTotal();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (context) => [
            // Company Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Sriva Groups", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                    pw.Text("Premium Billing Solutions", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("QUOTATION", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text("RFQ: ${quotation!['id']}", style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.deepPurple),
            pw.SizedBox(height: 20),

            // Info Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("BILL FROM:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text("Admin / Accounts Dept", style: const pw.TextStyle(fontSize: 12)),
                    pw.Text("Billing App System", style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _pdfInfoRow("Status:", (quotation!['status'] ?? 'Pending').toString().toUpperCase()),
                    _pdfInfoRow("Request Date:", (quotation!['request_date'] ?? 'N/A').toString()),
                    _pdfInfoRow("Valid Until:", (quotation!['validity_date'] ?? 'N/A').toString()),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Product Table
            pw.TableHelper.fromTextArray(
              border: null,
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
              headerHeight: 30,
              cellHeight: 25,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              headers: ['Product Details', 'Qty', 'Unit Price', 'Total'],
              data: items.map((item) {
                double qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
                double price = double.tryParse(item['target_price']?.toString() ?? '0') ?? 0;
                return [
                  item['product_name'] ?? 'N/A',
                  qty.toString(),
                  "₹${price.toStringAsFixed(2)}",
                  "₹${(qty * price).toStringAsFixed(2)}"
                ];
              }).toList(),
            ),

            // Summary Section
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Spacer(flex: 2),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    children: [
                      _pdfSummaryRow("Subtotal:", "₹${grandTotal.toStringAsFixed(2)}"),
                      _pdfSummaryRow("Tax (0%):", "₹0.00"),
                      pw.Divider(thickness: 1),
                      _pdfSummaryRow("Grand Total:", "₹${grandTotal.toStringAsFixed(2)}", isBold: true),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 60),
            // Footer / Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Terms & Conditions:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text("1. Prices are valid until the specified date.", style: const pw.TextStyle(fontSize: 8)),
                    pw.Text("2. Goods once sold will not be taken back.", style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 120, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1)))),
                    pw.SizedBox(height: 5),
                    pw.Text("Authorized Signature", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: "Quotation_${quotation!['id']}.pdf");
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/Quotation_${quotation!['id']}.pdf");
        await file.writeAsBytes(bytes);
        
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          throw Exception(result.message);
        }
      }
    } catch (e) {
      AppLogger.error("PDF Error", e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => isDownloading = false);
    }
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _pdfSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: isBold ? PdfColors.deepPurple : PdfColors.black)),
        ],
      ),
    );
  }

  double _calculateGrandTotal() {
    if (quotation == null) return 0;
    final items = quotation!['items'] as List? ?? [];
    double total = 0;
    for (var item in items) {
      double qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      double price = double.tryParse(item['target_price']?.toString() ?? '0') ?? 0;
      total += qty * price;
    }
    return total;
  }

  Future<void> _deleteQuotation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this quotation?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    final url = "https://billing.srivagroups.in/api/quotation/${widget.quotationId}";
    try {
      final response = await http.delete(Uri.parse(url), headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
      });
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quotation deleted successfully"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error("Delete Error", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(isLoading ? "Quotation Details" : "RFQ: ${quotation?['id']}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          if (!isLoading) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditQuotationPage(
                      quotationId: widget.quotationId,
                      token: widget.token,
                      initialData: quotation!,
                    ),
                  ),
                );
                if (result == true) fetchQuotationDetails();
              },
            ),
            IconButton(
              icon: isDownloading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_rounded),
              onPressed: isDownloading ? null : _downloadPdf,
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
              onPressed: _deleteQuotation,
            ),
          ]
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : quotation == null
              ? const Center(child: Text("Quotation not found"))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(isMobile),
                          const SizedBox(height: 24),
                          _buildProductDetailsSection(),
                          const SizedBox(height: 24),
                          _buildSummarySection(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("RFQ #${quotation!['id']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
                  const SizedBox(height: 4),
                  _buildStatusBadge(quotation!['status'] ?? 'Pending'),
                ],
              ),
            ],
          ),
          const Divider(height: 40),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _infoItem("REQUEST DATE", quotation!['request_date'] ?? 'N/A', Icons.calendar_today_rounded),
              _infoItem("VALID UNTIL", quotation!['validity_date'] ?? 'N/A', Icons.event_available_rounded),
              _infoItem("GRAND TOTAL", "₹${_calculateGrandTotal().toStringAsFixed(2)}", Icons.account_balance_wallet_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'accepted') color = Colors.green;
    if (status.toLowerCase() == 'rejected') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildProductDetailsSection() {
    final items = quotation!['items'] as List? ?? [];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.all(24), child: Text("Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (c, i) => _buildProductItem(items[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    double qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
    double price = double.tryParse(item['target_price']?.toString() ?? '0') ?? 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['product_name'] ?? 'Unknown Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                if (item['variant_name'] != null) Text("Variant: ${item['variant_name']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
              Text("₹${(qty * price).toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 20, runSpacing: 10, children: [
            _detailLabel("Qty", qty.toString()),
            _detailLabel("Price", "₹$price"),
            if (item['notes'] != null && item['notes'].toString().isNotEmpty) _detailLabel("Notes", item['notes']),
          ]),
        ],
      ),
    );
  }

  Widget _detailLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildSummarySection() {
    double grandTotal = _calculateGrandTotal();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurple.withOpacity(0.1))),
      child: Column(
        children: [
          _summaryRow("Subtotal", "₹${grandTotal.toStringAsFixed(2)}"),
          const Divider(height: 32),
          _summaryRow("GRAND TOTAL", "₹${grandTotal.toStringAsFixed(2)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600, color: isTotal ? Colors.deepPurple : const Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: isTotal ? 20 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700, color: isTotal ? Colors.deepPurple : const Color(0xFF1E293B))),
      ],
    );
  }
}
