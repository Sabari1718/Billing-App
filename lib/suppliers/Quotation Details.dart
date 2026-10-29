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

// ============================================================================
// PDF GENERATOR MATCHING PHOTO 1 INVOICE LAYOUT
// ============================================================================
Future<Uint8List> generateQuotationPdf(Map<String, dynamic> d) async {
  final pdf = pw.Document();
  final font = await PdfGoogleFonts.notoSansRegular();
  final boldFont = await PdfGoogleFonts.notoSansBold();

  final rfqRef = (d['rfq_reference'] ?? d['rfq_id'] ?? "RFQ-${d['id'] ?? '365120'}").toString();
  final storeName = (d['store_name'] ?? (d['store'] is Map ? d['store']['name'] : null) ?? d['business_name'] ?? "Circuitpointcare").toString();
  final storeAddress = (d['store_address'] ?? (d['store'] is Map ? d['store']['address'] : null) ?? "Neelambur, Sulur Taluk, Coimbatore, TamilNadu, 641062").toString();
  final storePhone = (d['store_phone'] ?? (d['store'] is Map ? d['store']['phone'] : null) ?? "9092014442").toString();

  String reqDate = d['request_date']?.toString() ?? DateFormat('MM/dd/yyyy').format(DateTime.now());
  try {
    final parsed = DateTime.parse(reqDate);
    reqDate = DateFormat('MM/dd/yyyy').format(parsed);
  } catch (_) {}

  String valDate = (d['validity_until'] ?? d['validity_date'])?.toString() ?? DateFormat('MM/dd/yyyy').format(DateTime.now().add(const Duration(days: 1)));
  try {
    final parsed = DateTime.parse(valDate);
    valDate = DateFormat('MM/dd/yyyy').format(parsed);
  } catch (_) {}

  final rawItems = (d['items'] is List && (d['items'] as List).isNotEmpty)
      ? d['items'] as List
      : (d['products'] is List ? d['products'] as List : []);

  final List<Map<String, dynamic>> items = [];
  double subtotal = 0.0;
  double totalTax = 0.0;

  for (var p in rawItems) {
    if (p is Map) {
      final pName = (p['product_name'] ?? (p['product'] is Map ? p['product']['name'] : null) ?? p['name'] ?? 'Product').toString();
      final vName = (p['variant_name'] ?? (p['variant'] is Map ? p['variant']['name'] : null) ?? 'Imported').toString();
      final qty = int.tryParse((p['quantity'] ?? p['qty'] ?? 1).toString()) ?? 1;
      final unitPrice = double.tryParse((p['unit_price'] ?? p['price_without_gst'] ?? p['target_price'] ?? 0.0).toString()) ?? 0.0;
      final taxRate = double.tryParse((p['tax'] ?? p['gst_rate'] ?? 0.0).toString()) ?? 0.0;
      final taxPrice = double.tryParse((p['tax_amount'] ?? p['tax_price'] ?? ((unitPrice * qty) * (taxRate / 100))).toString()) ?? ((unitPrice * qty) * (taxRate / 100));
      final lineTotal = (unitPrice * qty) + taxPrice;

      items.add({
        'name': pName,
        'variant': vName,
        'unitPrice': unitPrice,
        'qty': qty,
        'tax': taxRate,
        'taxPrice': taxPrice,
        'total': lineTotal,
      });

      subtotal += (unitPrice * qty);
      totalTax += taxPrice;
    }
  }

  if (items.isEmpty) {
    items.add({
      'name': 'Var tech digital multimeter',
      'variant': 'Imported',
      'unitPrice': 650.0,
      'qty': 1,
      'tax': 0.0,
      'taxPrice': 0.0,
      'total': 650.0,
    });
    subtotal = 650.0;
    totalTax = 0.0;
  }

  final grandTotal = subtotal + totalTax;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Header: Store Info & Quote Info Box
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 36,
                          height: 28,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: pw.Border.all(color: PdfColors.blue300),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text("LOGO", style: pw.TextStyle(color: PdfColors.blue700, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(storeName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text("Store: $storeName", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text("Phone: $storePhone", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("QUOTE", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue600)),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: 170,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                      ),
                      child: pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                        children: [
                          _pdfTableRow("DATE", reqDate),
                          _pdfTableRow("QUOTE #", rfqRef),
                          _pdfTableRow("VALID UNTIL", valDate),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.2),
                1: pw.FlexColumnWidth(1.2),
                2: pw.FlexColumnWidth(0.8),
                3: pw.FlexColumnWidth(0.8),
                4: pw.FlexColumnWidth(1.1),
                5: pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _pdfHeaderCell("PRODUCT NAME", pw.Alignment.centerLeft),
                    _pdfHeaderCell("UNIT PRICE", pw.Alignment.centerRight),
                    _pdfHeaderCell("QTY", pw.Alignment.center),
                    _pdfHeaderCell("TAX", pw.Alignment.center),
                    _pdfHeaderCell("TAX PRICE", pw.Alignment.centerRight),
                    _pdfHeaderCell("AMOUNT", pw.Alignment.centerRight),
                  ],
                ),
                ...items.map((it) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(it['name'], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text("Variant: ${it['variant']}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue700)),
                          ],
                        ),
                      ),
                      _pdfDataCell("Rs. ${it['unitPrice'].toStringAsFixed(2)}", pw.Alignment.centerRight),
                      _pdfDataCell("${it['qty']}", pw.Alignment.center),
                      _pdfDataCell("${it['tax'].toStringAsFixed(0)}%", pw.Alignment.center),
                      _pdfDataCell("Rs. ${it['taxPrice'].toStringAsFixed(2)}", pw.Alignment.centerRight),
                      _pdfDataCell("Rs. ${it['total'].toStringAsFixed(2)}", pw.Alignment.centerRight),
                    ],
                  );
                }),
                for (int i = 0; i < (5 - items.length).clamp(0, 5); i++)
                  pw.TableRow(
                    children: List.generate(6, (_) => pw.Container(height: 20)),
                  ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Terms & Totals Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        color: PdfColors.blueGrey900,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text("TERMS AND CONDITIONS", style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text("1. Customer will be billed after indicating acceptance of this quote.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                      pw.Text("2. Payment will be due prior to delivery of service and goods.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                      pw.Text("3. Please sign and return the price quote to the address above.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                      pw.SizedBox(height: 14),
                      pw.Text("Customer Acceptance (sign below):", style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                      pw.SizedBox(height: 6),
                      pw.Text("X ________________________________________", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text("Print Name: ______________________________", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Subtotal", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.Text("Rs. ${subtotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Total Tax", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.Text("Rs. ${totalTax.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("TOTAL AMOUNT", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                          pw.Text("Rs. ${grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),

            // Bottom Footer
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text("If you have any questions about this price quote, please contact $storeName (Phone: $storePhone)", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.SizedBox(height: 3),
                  pw.Text("Thank You For Your Business!", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic, color: PdfColors.blueGrey900)),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.TableRow _pdfTableRow(String label, String value) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: pw.Text(value, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8)),
      ),
    ],
  );
}

pw.Widget _pdfHeaderCell(String text, pw.Alignment alignment) {
  return pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
  );
}

pw.Widget _pdfDataCell(String text, pw.Alignment alignment) {
  return pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
  );
}

// ============================================================================
// QUOTATION PREVIEW DIALOG (MATCHING PHOTO 1 EXACT POPUP MODAL)
// ============================================================================
class QuotationPreviewDialog extends StatefulWidget {
  final Map<String, dynamic> quotationData;
  final String token;

  const QuotationPreviewDialog({
    super.key,
    required this.quotationData,
    required this.token,
  });

  @override
  State<QuotationPreviewDialog> createState() => _QuotationPreviewDialogState();
}

class _QuotationPreviewDialogState extends State<QuotationPreviewDialog> {
  late Map<String, dynamic> currentData;
  bool isPrinting = false;
  bool isDownloading = false;
  bool isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    currentData = Map<String, dynamic>.from(widget.quotationData);
    _fetchFreshDetails();
  }

  Future<void> _fetchFreshDetails() async {
    final qId = currentData['id'];
    if (qId == null) return;
    setState(() => isLoadingDetails = true);
    try {
      final url = "https://billing.srivagroups.in/api/quotation/$qId";
      final response = await http.get(Uri.parse(url), headers: {
        "Accept": "application/json",
        if (widget.token.isNotEmpty) "Authorization": "Bearer ${widget.token}",
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final fresh = (decoded['data'] is Map) ? decoded['data'] as Map<String, dynamic> : null;
        if (fresh != null && mounted) {
          setState(() {
            currentData.addAll(fresh);
          });
        }
      }
    } catch (_) {
      // Keep existing data gracefully
    } finally {
      if (mounted) setState(() => isLoadingDetails = false);
    }
  }

  Future<void> _handlePrint() async {
    setState(() => isPrinting = true);
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => await generateQuotationPdf(currentData),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Print error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isPrinting = false);
    }
  }

  Future<void> _handleDownloadPdf() async {
    setState(() => isDownloading = true);
    try {
      final bytes = await generateQuotationPdf(currentData);
      final rfqRef = currentData['rfq_reference'] ?? "RFQ-${currentData['id'] ?? '365120'}";
      final filename = "Quotation_$rfqRef.pdf";

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      } else {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File("${dir.path}/$filename");
          await file.writeAsBytes(bytes);
          await OpenFile.open(file.path);
        } catch (_) {
          await Printing.sharePdf(bytes: bytes, filename: filename);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF Downloaded successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rfqRef = (currentData['rfq_reference'] ?? currentData['rfq_id'] ?? "RFQ-${currentData['id'] ?? '365120'}").toString();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Center(
        child: Container(
          width: 820,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.94,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Bar (Responsive Navy / Slate #1E293B)
                LayoutBuilder(
                  builder: (context, headerConstraints) {
                    final isCompact = headerConstraints.maxWidth < 460;
                    return Container(
                      color: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Quotation #$rfqRef",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isCompact ? 12 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Print Quote Button (Blue #2563EB)
                          ElevatedButton.icon(
                            icon: isPrinting
                                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.print, size: 13),
                            label: Text(isCompact ? "Print" : "Print Quote", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0,
                            ),
                            onPressed: isPrinting ? null : _handlePrint,
                          ),
                          const SizedBox(width: 6),
                          // Download PDF Button (Green #10B981)
                          ElevatedButton.icon(
                            icon: isDownloading
                                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.download, size: 13),
                            label: Text(isCompact ? "PDF" : "Download PDF", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0,
                            ),
                            onPressed: isDownloading ? null : _handleDownloadPdf,
                          ),
                          const SizedBox(width: 6),
                          // Close button
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Invoice Body (Scrollable vertically & horizontally so it never overflows and retains exact Photo 1 layout)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 720,
                        child: QuotationInvoiceCard(quotationData: currentData),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// QUOTATION INVOICE CARD (MATCHING PHOTO 1 LAYOUT EXACTLY)
// ============================================================================
class QuotationInvoiceCard extends StatelessWidget {
  final Map<String, dynamic> quotationData;

  const QuotationInvoiceCard({super.key, required this.quotationData});

  @override
  Widget build(BuildContext context) {
    final d = quotationData;

    final rfqRef = (d['rfq_reference'] ?? d['rfq_id'] ?? "RFQ-${d['id'] ?? '365120'}").toString();
    final storeName = (d['store_name'] ?? (d['store'] is Map ? d['store']['name'] : null) ?? d['business_name'] ?? "Circuitpointcare").toString();
    final storeAddress = (d['store_address'] ?? (d['store'] is Map ? d['store']['address'] : null) ?? "Neelambur, Sulur Taluk, Coimbatore, TamilNadu, 641062").toString();
    final storePhone = (d['store_phone'] ?? (d['store'] is Map ? d['store']['phone'] : null) ?? "9092014442").toString();

    String reqDate = d['request_date']?.toString() ?? DateFormat('MM/dd/yyyy').format(DateTime.now());
    try {
      final parsed = DateTime.parse(reqDate);
      reqDate = DateFormat('MM/dd/yyyy').format(parsed);
    } catch (_) {}

    String valDate = (d['validity_until'] ?? d['validity_date'])?.toString() ?? DateFormat('MM/dd/yyyy').format(DateTime.now().add(const Duration(days: 1)));
    try {
      final parsed = DateTime.parse(valDate);
      valDate = DateFormat('MM/dd/yyyy').format(parsed);
    } catch (_) {}

    final rawItems = (d['items'] is List && (d['items'] as List).isNotEmpty)
        ? d['items'] as List
        : (d['products'] is List ? d['products'] as List : []);

    final List<Map<String, dynamic>> items = [];
    double subtotal = 0.0;
    double totalTax = 0.0;

    for (var p in rawItems) {
      if (p is Map) {
        final pName = (p['product_name'] ?? (p['product'] is Map ? p['product']['name'] : null) ?? p['name'] ?? 'Product').toString();
        final vName = (p['variant_name'] ?? (p['variant'] is Map ? p['variant']['name'] : null) ?? 'Imported').toString();
        final qty = int.tryParse((p['quantity'] ?? p['qty'] ?? 1).toString()) ?? 1;
        final unitPrice = double.tryParse((p['unit_price'] ?? p['price_without_gst'] ?? p['target_price'] ?? 0.0).toString()) ?? 0.0;
        final taxRate = double.tryParse((p['tax'] ?? p['gst_rate'] ?? 0.0).toString()) ?? 0.0;
        final taxPrice = double.tryParse((p['tax_amount'] ?? p['tax_price'] ?? ((unitPrice * qty) * (taxRate / 100))).toString()) ?? ((unitPrice * qty) * (taxRate / 100));
        final lineTotal = (unitPrice * qty) + taxPrice;

        items.add({
          'name': pName,
          'variant': vName,
          'unitPrice': unitPrice,
          'qty': qty,
          'tax': taxRate,
          'taxPrice': taxPrice,
          'total': lineTotal,
        });

        subtotal += (unitPrice * qty);
        totalTax += taxPrice;
      }
    }

    if (items.isEmpty) {
      items.add({
        'name': 'Var tech digital multimeter',
        'variant': 'Imported',
        'unitPrice': 650.0,
        'qty': 1,
        'tax': 0.0,
        'taxPrice': 0.0,
        'total': 650.0,
      });
      subtotal = 650.0;
      totalTax = 0.0;
    }

    final grandTotal = subtotal + totalTax;
    final int emptyRowCount = (6 - items.length).clamp(0, 6);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Store branding
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "LOGO",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Store: $storeName",
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                    Text(
                      storeAddress,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      "Phone: $storePhone",
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

              // Right: QUOTE Title & 3-Row Info Box
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "QUOTE",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 190,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF94A3B8)),
                    ),
                    child: Table(
                      border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.4),
                      },
                      children: [
                        _buildInfoTableRow("DATE", reqDate),
                        _buildInfoTableRow("QUOTE #", rfqRef),
                        _buildInfoTableRow("VALID UNTIL", valDate),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Items Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Table(
              border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 1),
              columnWidths: const {
                0: FlexColumnWidth(3.4),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(0.7),
                3: FlexColumnWidth(0.8),
                4: FlexColumnWidth(1.1),
                5: FlexColumnWidth(1.3),
              },
              children: [
                // Header Row (Light Slate #F8FAFC)
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                  children: [
                    _buildGridHeader("PRODUCT NAME", Alignment.centerLeft),
                    _buildGridHeader("UNIT PRICE", Alignment.centerRight),
                    _buildGridHeader("QTY", Alignment.center),
                    _buildGridHeader("TAX", Alignment.center),
                    _buildGridHeader("TAX PRICE", Alignment.centerRight),
                    _buildGridHeader("AMOUNT", Alignment.centerRight),
                  ],
                ),
                // Data Rows
                ...items.map((it) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it['name'],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Variant: ${it['variant']}",
                              style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                      _buildGridCell("₹${it['unitPrice'].toStringAsFixed(2)}", Alignment.centerRight),
                      _buildGridCell("${it['qty']}", Alignment.center),
                      _buildGridCell("${it['tax'].toStringAsFixed(0)}%", Alignment.center),
                      _buildGridCell("₹${it['taxPrice'].toStringAsFixed(2)}", Alignment.centerRight),
                      _buildGridCell("₹${it['total'].toStringAsFixed(2)}", Alignment.centerRight),
                    ],
                  );
                }),
                // Empty grid rows matching Photo 1
                for (int i = 0; i < emptyRowCount; i++)
                  TableRow(
                    children: List.generate(
                      6,
                      (_) => const SizedBox(height: 24),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Bottom Section: Terms & Signature on Left, Totals on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Terms and Conditions
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: const Text(
                        "TERMS AND CONDITIONS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "1. Customer will be billed after indicating acceptance of this quote.",
                      style: TextStyle(fontSize: 10, color: Color(0xFF475569)),
                    ),
                    const Text(
                      "2. Payment will be due prior to delivery of service and goods.",
                      style: TextStyle(fontSize: 10, color: Color(0xFF475569)),
                    ),
                    const Text(
                      "3. Please sign and return the price quote to the address above.",
                      style: TextStyle(fontSize: 10, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Customer Acceptance (sign below):",
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "X ________________________________________",
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Print Name: ______________________________",
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right: Subtotal, Tax, Total Amount
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal", style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        Row(
                          children: [
                            const Text("₹", style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                            const SizedBox(width: 8),
                            Text(subtotal.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Tax", style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        Row(
                          children: [
                            const Text("₹", style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                            const SizedBox(width: 8),
                            Text(totalTax.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFCBD5E1), height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TOTAL\nAMOUNT",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          "₹${grandTotal.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Footer Notice
          Center(
            child: Column(
              children: [
                Text(
                  "If you have any questions about this price quote, please contact $storeName (Phone: $storePhone)",
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  "Thank You For Your Business!",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static TableRow _buildInfoTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  static Widget _buildGridHeader(String title, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  static Widget _buildGridCell(String text, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
      ),
    );
  }
}

// ============================================================================
// FULL PAGE DETAILS (FALLBACK IF ROUTED DIRECTLY)
// ============================================================================
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

  @override
  Widget build(BuildContext context) {
    final rfqRef = quotation != null ? (quotation!['rfq_reference'] ?? "RFQ-${quotation!['id']}") : "RFQ-${widget.quotationId}";

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(isLoading ? "Quotation Details" : "Quotation #$rfqRef"),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (quotation != null) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.print, size: 14),
              label: const Text("Print Quote", style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Printing.layoutPdf(
                onLayout: (format) async => await generateQuotationPdf(quotation!),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 14),
              label: const Text("Download PDF", style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                final bytes = await generateQuotationPdf(quotation!);
                await Printing.sharePdf(bytes: bytes, filename: "Quotation_$rfqRef.pdf");
              },
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : quotation == null
              ? const Center(child: Text("Quotation not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 720,
                        child: QuotationInvoiceCard(quotationData: quotation!),
                      ),
                    ),
                  ),
                ),
    );
  }
}
