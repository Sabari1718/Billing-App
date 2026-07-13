import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:billingapp/utils/app_logger.dart';
import 'package:billingapp/suppliers/Quotation Details.dart';
import 'package:billingapp/suppliers/Edit Quotation.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Shim to support console.log/error as requested
class _Console {
  void log(Object? message) => debugPrint(message?.toString());
  void error(Object? message) => debugPrint("ERROR: ${message?.toString()}");
}
final console = _Console();

// ------------------------------------------------------------------
// MAIN QUOTATION PAGE (LISTING)
// ------------------------------------------------------------------
class SupplierQuotationPage extends StatefulWidget {
  final String token;

  const SupplierQuotationPage({super.key, required this.token});

  @override
  State<SupplierQuotationPage> createState() => _SupplierQuotationPageState();
}

class _SupplierQuotationPageState extends State<SupplierQuotationPage> {
  List quotations = [];
  bool isLoading = true;
  String searchQuery = "";
  String filterStatus = "Status";

  String role = "propagater";
  String? businessId;

  @override
  void initState() {
    super.initState();
    AppLogger.info("SupplierQuotationPage opened");
    _loadRoleAndFetch();
  }

  Future<void> _loadRoleAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString("role")?.toLowerCase() ?? "propagater";
    businessId = prefs.get("business_id")?.toString();
    fetchQuotations();
  }

  Future<void> fetchQuotations() async {
    String url = "https://billing.srivagroups.in/api/quotation";
    
    // 🔥 Apply role-based filtering
    final prefs = await SharedPreferences.getInstance();
    if (role == "supplier" || role == "partner") {
      final userMainId = prefs.getString("user_main_id") ?? "";
      url += "?business_id=$businessId&user_main_id=$userMainId";
    } else if (role == "propagator" || role == "propagater" || role == "admin") {
      // Propagator sees all data
      AppLogger.info("Propagator role: Loading all quotations");
    } else if (businessId != null) {
      url += "?business_id=$businessId";
    }

    final headers = {
      "Authorization": "Bearer ${widget.token}",
      "Accept": "application/json",
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      AppLogger.api("GET", url, response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List list = data is Map ? (data['data'] ?? []) : (data is List ? data : []);
        setState(() {
          quotations = list;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      AppLogger.error("fetchQuotations error", e);
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteQuotation(int id) async {
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

    final url = "https://billing.srivagroups.in/api/quotation/$id";
    try {
      final response = await http.delete(Uri.parse(url), headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
      });
      if (response.statusCode == 200 || response.statusCode == 204) {
        fetchQuotations();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted successfully"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete"), backgroundColor: Colors.red));
      }
    } catch (e) {
      AppLogger.error("Delete error", e);
    }
  }

  Future<void> _downloadPdf(Map<String, dynamic> item) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating professional PDF..."), duration: Duration(seconds: 1)));
      
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      
      // Note: Listing items might not have full 'items' array. 
      // If missing, we show a basic summary.
      final items = item['items'] as List? ?? [];
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Sriva Groups", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                  pw.Text("RFQ: ${item['id']}", style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Quotation Summary", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Status: ${item['status']?.toString().toUpperCase() ?? 'PENDING'}"),
                    pw.Text("Date: ${item['request_date'] ?? 'N/A'}"),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            if (items.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['Product', 'Qty', 'Price'],
                data: items.map((i) => [
                  i['product_name'] ?? 'N/A',
                  i['quantity']?.toString() ?? '0',
                  "₹${i['target_price']?.toString() ?? '0'}"
                ]).toList(),
              )
            else
              pw.Text("Detailed item list not available in summary view. Please open details page for full PDF.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.red)),
            
            pw.SizedBox(height: 40),
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(
              children: [
                pw.Container(width: 100, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide()))),
                pw.SizedBox(height: 5),
                pw.Text("Authorized Sign", style: const pw.TextStyle(fontSize: 10)),
              ],
            )),
          ],
        ),
      );

      final bytes = await pdf.save();
      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: "Quotation_${item['id']}.pdf");
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/Quotation_${item['id']}.pdf");
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      }
    } catch (e) {
      AppLogger.error("PDF error", e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;
            bool isMobile = width < 600;

            return RefreshIndicator(
              onRefresh: fetchQuotations,
              color: Colors.deepPurple,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(isMobile),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildSearchAndFilter(isMobile),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: isLoading
                        ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.deepPurple)))
                        : quotations.isEmpty
                            ? const SliverFillRemaining(child: Center(child: Text("No quotations found")))
                            : isMobile
                                ? _buildMobileList()
                                : _buildDesktopTable(width),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      toolbarHeight: isMobile ? 130 : 80,
      title: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Supplier Quotations", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: _newQuotationButton()),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Supplier Quotations", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              _newQuotationButton(),
            ],
          ),
    );
  }

  Widget _newQuotationButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => NewQuotationPage(token: widget.token)));
        if (result == true) fetchQuotations();
      },
      icon: const Icon(Icons.add_rounded),
      label: const Text("New Quotation"),
    );
  }

  Widget _buildSearchAndFilter(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: isMobile 
        ? Column(children: [_searchField(), const Divider(height: 1), _statusDropdown(fullWidth: true)])
        : Row(children: [Expanded(flex: 3, child: _searchField()), Container(width: 1, height: 30, color: Colors.grey.shade200), Expanded(flex: 1, child: _statusDropdown(fullWidth: false))]),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => searchQuery = v),
      decoration: const InputDecoration(hintText: "Search...", prefixIcon: Icon(Icons.search_rounded), border: InputBorder.none),
    );
  }

  Widget _statusDropdown({required bool fullWidth}) {
    return DropdownButtonFormField<String>(
      value: filterStatus,
      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      items: ["Status", "Pending", "Accepted", "Rejected", "Expired"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => setState(() => filterStatus = v!),
    );
  }

  Widget _buildMobileList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = quotations[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("RFQ #${item['id']}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.deepPurple)), _statusBadge(item['status'] ?? "Pending")]),
                const SizedBox(height: 12),
                Text("Date: ${item['request_date'] ?? 'N/A'}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.visibility_rounded, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuotationDetailsPage(quotationId: item['id'], token: widget.token))).then((_) => fetchQuotations())),
                    IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.deepPurple), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditQuotationPage(quotationId: item['id'], token: widget.token, initialData: item))).then((_) => fetchQuotations())),
                    IconButton(icon: const Icon(Icons.download_rounded, color: Colors.green), onPressed: () => _downloadPdf(item)),
                    IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.red), onPressed: () => _deleteQuotation(item['id'])),
                  ],
                )
              ],
            ),
          );
        },
        childCount: quotations.length,
      ),
    );
  }

  Widget _buildDesktopTable(double width) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("RFQ ID")),
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Valid Until")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Actions")),
            ],
            rows: quotations.map((item) {
              return DataRow(cells: [
                DataCell(Text("#${item['id']}", style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(item['request_date'] ?? "N/A")),
                DataCell(Text(item['validity_date'] ?? "N/A")),
                DataCell(_statusBadge(item['status'] ?? "Pending")),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.visibility_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuotationDetailsPage(quotationId: item['id'], token: widget.token))).then((_) => fetchQuotations())),
                    IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditQuotationPage(quotationId: item['id'], token: widget.token, initialData: item))).then((_) => fetchQuotations())),
                    IconButton(icon: const Icon(Icons.download_rounded), onPressed: () => _downloadPdf(item)),
                    IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent), onPressed: () => _deleteQuotation(item['id'])),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'accepted') color = Colors.green;
    if (status.toLowerCase() == 'rejected') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ------------------------------------------------------------------
// QUOTATION ITEM CONTROLLER MODEL
// ------------------------------------------------------------------
class QuotationItemController {
  final TextEditingController productController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final TextEditingController notesController;
  int? productId;
  int? variantId;
  int? supplierProductId;

  QuotationItemController({
    required this.productController,
    required this.qtyController,
    required this.priceController,
    required this.notesController,
    this.productId,
    this.variantId,
    this.supplierProductId,
  });

  void dispose() {
    productController.dispose();
    qtyController.dispose();
    priceController.dispose();
    notesController.dispose();
  }
}

// ------------------------------------------------------------------
// NEW QUOTATION PAGE
// ------------------------------------------------------------------
class NewQuotationPage extends StatefulWidget {
  final String token;

  const NewQuotationPage({super.key, required this.token});

  @override
  State<NewQuotationPage> createState() => _NewQuotationPageState();
}

class _NewQuotationPageState extends State<NewQuotationPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController requestDateCtrl = TextEditingController();
  final TextEditingController validityDateCtrl = TextEditingController();
  String selectedStatus = "Pending";
  String rfqId = "";

  List<QuotationItemController> itemControllers = [];
  List<Map<String, dynamic>> _allSupplierProducts = []; 
  bool isSaving = false;
  bool _isFetchingProducts = false;

  @override
  void initState() {
    super.initState();
    _generateRfqId();
    _setInitialDates();
    _addLineItem();
  }

  @override
  void dispose() {
    requestDateCtrl.dispose();
    validityDateCtrl.dispose();
    for (var controller in itemControllers) controller.dispose();
    super.dispose();
  }

  void _generateRfqId() => rfqId = "RFQ-${Random().nextInt(900000) + 100000}";

  void _setInitialDates() {
    requestDateCtrl.text = DateFormat('MM/dd/yyyy').format(DateTime.now());
    validityDateCtrl.text = DateFormat('MM/dd/yyyy').format(DateTime.now().add(const Duration(days: 7)));
  }

  void _addLineItem() {
    setState(() {
      itemControllers.add(QuotationItemController(
        productController: TextEditingController(),
        qtyController: TextEditingController(text: "1"),
        priceController: TextEditingController(),
        notesController: TextEditingController(),
      ));
    });
  }

  void _removeLineItem(int index) {
    if (itemControllers.length > 1) {
      setState(() {
        itemControllers[index].dispose();
        itemControllers.removeAt(index);
      });
    }
  }

  Future<void> _fetchSupplierProducts() async {
    if (_isFetchingProducts) return;
    setState(() => _isFetchingProducts = true);
    final prefs = await SharedPreferences.getInstance();
    final bId = prefs.get("business_id")?.toString() ?? "";
    final uId = prefs.getString("user_main_id") ?? "";
    final r = prefs.getString("role")?.toLowerCase() ?? "";

    String url = "https://billing.srivagroups.in/api/supplierProduct/my-products";
    if (r == "supplier" || r == "partner") {
      url += "?business_id=$bId&user_main_id=$uId";
    } else if (r != "propagator" && r != "propagater" && r != "admin") {
       url += "?business_id=$bId";
    }
    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
      });
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List list = jsonData is Map && jsonData['success'] == true ? jsonData['data'] ?? [] : [];
        setState(() {
          _allSupplierProducts = list.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      AppLogger.error("Fetch error", e);
    } finally {
      if (mounted) setState(() => _isFetchingProducts = false);
    }
  }

  Future<void> _submitQuotation() async {
    if (!_formKey.currentState!.validate()) return;
    DateTime reqDate = DateFormat('MM/dd/yyyy').parse(requestDateCtrl.text);
    DateTime valDate = DateFormat('MM/dd/yyyy').parse(validityDateCtrl.text);
    
    if (valDate.isBefore(reqDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Validity date must be today or future")));
      return;
    }

    setState(() => isSaving = true);
    const url = "https://billing.srivagroups.in/api/quotation";
    try {
      final payload = {
        "request_date": DateFormat('yyyy-MM-dd').format(reqDate),
        "validity_date": DateFormat('yyyy-MM-dd').format(valDate),
        "status": selectedStatus.toLowerCase(),
        "items": itemControllers.map((c) => {
          "supplier_product_mapping_id": c.supplierProductId,
          "quantity": int.tryParse(c.qtyController.text) ?? 1,
          "target_price": double.tryParse(c.priceController.text) ?? 0,
          "notes": c.notesController.text.trim(),
          "additional_charges": 0,
          "tax": 0,
          "packing": 0,
          "delivery": 0,
        }).toList()
      };
      final response = await http.post(Uri.parse(url), headers: {
        "Authorization": "Bearer ${widget.token}", 
        "Content-Type": "application/json",
        "Accept": "application/json"
      }, body: jsonEncode(payload));
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quotation Sent Successfully"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['message'] ?? "Failed to send")));
      }
    } catch (e) {
      AppLogger.error("Submit error", e);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: Text(rfqId), backgroundColor: Colors.white, elevation: 0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildBasicInfo(isMobile),
              const SizedBox(height: 16),
              _buildProductsSection(isMobile),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isSaving ? null : _submitQuotation,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Send Quotation Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _dateField("Request Date", requestDateCtrl),
          const SizedBox(height: 16),
          _dateField("Validity Date", validityDateCtrl, isValidity: true),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedStatus,
            items: ["Pending", "Accepted", "Rejected", "Expired"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => selectedStatus = v!),
            decoration: const InputDecoration(labelText: "Status"),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, TextEditingController ctrl, {bool isValidity = false}) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today)),
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(context: context, initialDate: now, firstDate: isValidity ? now : DateTime(2000), lastDate: DateTime(2101));
        if (date != null) setState(() => ctrl.text = DateFormat('MM/dd/yyyy').format(date));
      },
    );
  }

  Widget _buildProductsSection(bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(title: const Text("Items"), trailing: IconButton(onPressed: _addLineItem, icon: const Icon(Icons.add))),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemControllers.length,
            itemBuilder: (c, i) => _buildProductRow(i),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(int index) {
    final c = itemControllers[index];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showProductPicker(index),
            child: AbsorbPointer(
              child: TextFormField(controller: c.productController, decoration: const InputDecoration(labelText: "Select Product")),
            ),
          ),
          Row(children: [
            Expanded(child: TextFormField(controller: c.qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Qty"))),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: c.priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Target Price"))),
          ]),
          TextFormField(controller: c.notesController, decoration: const InputDecoration(labelText: "Notes")),
          if (itemControllers.length > 1) IconButton(onPressed: () => _removeLineItem(index), icon: const Icon(Icons.delete, color: Colors.red)),
        ],
      ),
    );
  }

  Future<void> _showProductPicker(int index) async {
    final c = itemControllers[index];
    if (_allSupplierProducts.isEmpty) await _fetchSupplierProducts();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: _allSupplierProducts.length,
        itemBuilder: (ctx, i) {
          final p = _allSupplierProducts[i];
          return ListTile(
            title: Text(p['product_name'] ?? ""),
            onTap: () {
              setState(() {
                c.productController.text = p['product_name'] ?? "";
                c.productId = p['product_id'];
                c.variantId = p['variant_id'];
                c.supplierProductId = p['id'];
              });
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }
}
