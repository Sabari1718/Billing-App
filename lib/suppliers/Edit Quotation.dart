import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:billingapp/utils/app_logger.dart';

// Shim to support console.log/error as requested
class _Console {
  void log(Object? message) => debugPrint(message?.toString());
  void error(Object? message) => debugPrint("ERROR: ${message?.toString()}");
}
final console = _Console();

class EditQuotationPage extends StatefulWidget {
  final int quotationId;
  final String token;
  final Map<String, dynamic> initialData;

  const EditQuotationPage({
    super.key,
    required this.quotationId,
    required this.token,
    required this.initialData,
  });

  @override
  State<EditQuotationPage> createState() => _EditQuotationPageState();
}

class _EditQuotationPageState extends State<EditQuotationPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController requestDateCtrl = TextEditingController();
  final TextEditingController validityDateCtrl = TextEditingController();
  String selectedStatus = "Pending";

  List<_EditItemController> itemControllers = [];
  List<Map<String, dynamic>> _allSupplierProducts = []; 
  bool isSaving = false;
  bool _isFetchingProducts = false;

  @override
  void initState() {
    super.initState();
    _prefillData();
    _fetchSupplierProducts();
  }

  void _prefillData() {
    final d = widget.initialData;
    requestDateCtrl.text = _formatDate(d['request_date']);
    validityDateCtrl.text = _formatDate(d['validity_date']);
    selectedStatus = _capitalize(d['status'] ?? "Pending");

    final items = d['items'] as List? ?? [];
    for (var item in items) {
      itemControllers.add(_EditItemController(
        productController: TextEditingController(text: item['product_name']),
        qtyController: TextEditingController(text: item['quantity']?.toString() ?? "1"),
        priceController: TextEditingController(text: item['target_price']?.toString() ?? ""),
        notesController: TextEditingController(text: item['notes'] ?? ""),
        productId: item['product_id'],
        variantId: item['variant_id'],
        supplierProductId: item['supplier_product_mapping_id'],
      ));
    }
    
    if (itemControllers.isEmpty) _addLineItem();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return DateFormat('MM/dd/yyyy').format(DateTime.now());
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('MM/dd/yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  void dispose() {
    requestDateCtrl.dispose();
    validityDateCtrl.dispose();
    for (var c in itemControllers) c.dispose();
    super.dispose();
  }

  void _addLineItem() {
    setState(() {
      itemControllers.add(_EditItemController(
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
    
    const url = "https://billing.srivagroups.in/api/supplierProduct/my-products";
    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
      });
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List list = jsonData is Map && jsonData['success'] == true ? jsonData['data'] ?? [] : [];
        
        final Map<String, dynamic> uniqueMap = {};
        for (var item in list) {
          if (item != null && item['product_id'] != null) {
            String key = "${item['product_id']}_${item['variant_id']}";
            uniqueMap[key] = item;
          }
        }
        setState(() {
          _allSupplierProducts = uniqueMap.values.toList().cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      AppLogger.error("Fetch error", e);
    } finally {
      if (mounted) setState(() => _isFetchingProducts = false);
    }
  }

  Future<void> _updateQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime reqDate = DateFormat('MM/dd/yyyy').parse(requestDateCtrl.text);
    DateTime valDate = DateFormat('MM/dd/yyyy').parse(validityDateCtrl.text);
    
    if (valDate.isBefore(reqDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Validity date must be today or future")));
      return;
    }

    setState(() => isSaving = true);
    final url = "https://billing.srivagroups.in/api/quotation/${widget.quotationId}";
    
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

      console.log("🚀 [UPDATE REQUEST]: PUT $url");
      console.log("📦 [PAYLOAD]: ${jsonEncode(payload)}");

      final response = await http.put(
        Uri.parse(url), 
        headers: {
          "Authorization": "Bearer ${widget.token}", 
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode(payload)
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quotation Updated Successfully"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['message'] ?? "Update failed")));
      }
    } catch (e) {
      AppLogger.error("Update error", e);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Edit Quotation", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  _buildBasicInfo(isMobile),
                  const SizedBox(height: 24),
                  _buildProductsSection(isMobile),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          isMobile 
            ? Column(children: [
                _dateField("Request Date", requestDateCtrl),
                const SizedBox(height: 20),
                _dateField("Validity Date", validityDateCtrl, isValidity: true),
              ])
            : Row(children: [
                Expanded(child: _dateField("Request Date", requestDateCtrl)),
                const SizedBox(width: 24),
                Expanded(child: _dateField("Validity Date", validityDateCtrl, isValidity: true)),
              ]),
          const SizedBox(height: 24),
          _statusDropdownField(),
        ],
      ),
    );
  }

  Widget _dateField(String label, TextEditingController ctrl, {bool isValidity = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
        const SizedBox(height: 10),
        TextFormField(
          controller: ctrl,
          readOnly: true,
          validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
          ),
          onTap: () async {
            final now = DateTime.now();
            final date = await showDatePicker(
              context: context, 
              initialDate: now, 
              firstDate: isValidity ? now : DateTime(2000), 
              lastDate: DateTime(2101),
            );
            if (date != null) setState(() => ctrl.text = DateFormat('MM/dd/yyyy').format(date));
          },
        )
      ],
    );
  }

  Widget _statusDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("STATUS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selectedStatus,
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: ["Pending", "Accepted", "Rejected", "Expired"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => selectedStatus = v!),
        )
      ],
    );
  }

  Widget _buildProductsSection(bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                TextButton.icon(onPressed: _addLineItem, icon: const Icon(Icons.add_circle_outline), label: const Text("Add Item")),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemControllers.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (c, i) => _buildProductRow(i, isMobile),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProductRow(int index, bool isMobile) {
    final c = itemControllers[index];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, child: Text("${index + 1}", style: const TextStyle(fontSize: 10))),
              const SizedBox(width: 12),
              Expanded(child: _productSearchField(index)),
            ],
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _rowField("Quantity", c.qtyController, isNumeric: true)),
            const SizedBox(width: 16),
            Expanded(child: _rowField("Target Price", c.priceController, isNumeric: true)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _rowField("Notes", c.notesController, isOptional: true)),
            if (itemControllers.length > 1) IconButton(onPressed: () => _removeLineItem(index), icon: const Icon(Icons.delete, color: Colors.red)),
          ]),
        ],
      ),
    );
  }

  Widget _rowField(String label, TextEditingController ctrl, {bool isOptional = false, bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          validator: (v) => (!isOptional && (v == null || v.isEmpty)) ? "Required" : null,
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        )
      ],
    );
  }

  Widget _productSearchField(int index) {
    final c = itemControllers[index];
    return GestureDetector(
      onTap: () => _showProductPicker(index),
      child: AbsorbPointer(
        child: TextFormField(
          controller: c.productController,
          validator: (v) => (v == null || v.isEmpty) ? "Select a product" : null,
          decoration: InputDecoration(
            hintText: "Browse products...", filled: true, fillColor: const Color(0xFFEEF2FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: const Icon(Icons.keyboard_arrow_right, color: Colors.deepPurple),
          ),
        ),
      ),
    );
  }

  Future<void> _showProductPicker(int index) async {
    final c = itemControllers[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Select Product", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _allSupplierProducts.length,
                itemBuilder: (ctx, i) {
                  final p = _allSupplierProducts[i];
                  return ListTile(
                    title: Text(p['product_name'] ?? ""),
                    subtitle: Text(p['variant_name'] ?? "Original"),
                    onTap: () {
                      setState(() {
                        c.productController.text = p['product_name'];
                        c.productId = p['product_id'];
                        c.variantId = p['variant_id'];
                        c.supplierProductId = p['id'];
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : _updateQuotation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple, foregroundColor: Colors.white,
          padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Update Quotation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _EditItemController {
  final TextEditingController productController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final TextEditingController notesController;
  int? productId;
  int? variantId;
  int? supplierProductId;

  _EditItemController({
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
