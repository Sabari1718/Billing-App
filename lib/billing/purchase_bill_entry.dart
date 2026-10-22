import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:billingapp/theme.dart';
import 'package:billingapp/suppliers/add suppier.dart';
import 'product_form.dart'; // Import SearchableProductDropdown
import 'purchase_payment_summary.dart';

part 'purchase_bill_entry_logic.dart';
part 'purchase_bill_entry_step1.dart';
part 'purchase_bill_entry_step2.dart';
part 'purchase_bill_entry_step3.dart';
part 'purchase_bill_entry_widgets.dart';
part 'purchase_bill_entry_dropdown.dart';

class BillItem {
  Map<String, dynamic>? product;
  String productName;
  String? secondaryName;
  double qty;
  String unit;
  double gstPercent;
  double rateExcl;
  double rateIncl;
  double gstAmt;
  double discount;
  bool isDiscountPercentage;
  double charges;
  double taxable;
  double total;

  BillItem({
    required this.product,
    required this.productName,
    this.secondaryName,
    required this.qty,
    required this.unit,
    required this.gstPercent,
    required this.rateExcl,
    required this.rateIncl,
    required this.gstAmt,
    required this.discount,
    required this.isDiscountPercentage,
    required this.charges,
    required this.taxable,
    required this.total,
  });
}

class PurchaseBillEntryPage extends StatefulWidget {
  final Map<String, dynamic>? editBill;
  const PurchaseBillEntryPage({super.key, this.editBill});

  @override
  State<PurchaseBillEntryPage> createState() => _PurchaseBillEntryPageState();
}

class _PurchaseBillEntryPageState extends State<PurchaseBillEntryPage> {
  int currentStep = 1; // 1 = Supplier & Metadata, 2 = Products, 3 = Payment & Summary

  // Step 1 Data
  String token = "";
  List suppliers = [];
  bool isSuppliersLoading = true;
  Map<String, dynamic>? selectedSupplier;
  
  DateTime purchaseDate = DateTime.now();
  TimeOfDay purchaseTime = TimeOfDay.now();
  String invoiceNumber = "PUR-${Random().nextInt(900000) + 100000}";
  DateTime deliveryDate = DateTime.now();
  final TextEditingController refNumberController = TextEditingController();
  DateTime? refDate;

  // Step 2 Data
  List products = [];
  bool isProductsLoading = true;
  List<BillItem> items = [];

  Map<String, dynamic>? selectedFormProduct;
  final TextEditingController primaryNameController = TextEditingController();
  final TextEditingController secondaryNameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: "1");
  String unitValue = "Pcs";
  String gstPercentValue = "18%";
  final TextEditingController rateExclController = TextEditingController(text: "0.00");
  final TextEditingController rateInclController = TextEditingController(text: "0.00");
  final TextEditingController gstAmtController = TextEditingController(text: "0");
  final TextEditingController discountController = TextEditingController(text: "0");
  bool isDiscountPercentage = true;
  final TextEditingController chargesController = TextEditingController(text: "0.00");
  final TextEditingController taxableController = TextEditingController(text: "0");
  final TextEditingController totalController = TextEditingController(text: "0");
  bool enableSecondaryName = false;
  
  String tableSearchQuery = "";
  final TextEditingController tableSearchController = TextEditingController();
  int rowsPerPage = 10;

  // Step 3 Data
  String selectedPaymentMethod = "Cash";
  final TextEditingController notesController = TextEditingController();
  final TextEditingController shippingController = TextEditingController(text: "0");
  double subtotal = 0.0;
  double taxTotal = 0.0;
  double grandTotal = 0.0;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
    shippingController.addListener(_calculateTotals);
    _prefillForEdit();
  }

  void _prefillForEdit() {
    if (widget.editBill != null) {
      final bill = widget.editBill!;
      invoiceNumber = (bill['invoice_no'] ?? bill['bill_no'] ?? bill['purchase_bill_no'] ?? invoiceNumber).toString();

      if (bill['bill_date'] != null) {
        try {
          purchaseDate = DateTime.parse(bill['bill_date'].toString());
        } catch (_) {}
      }

      notesController.text = (bill['notes'] ?? "").toString();
      shippingController.text = (double.tryParse(bill['shipping_charges']?.toString() ?? "0") ?? 0.0).toStringAsFixed(2);
      selectedPaymentMethod = (bill['payment_mode'] ?? bill['payment_method'] ?? "Cash").toString();

      final rawItems = bill['items'] as List? ?? [];
      items = rawItems.map((e) {
        final pName = (e['product_name'] ?? e['name'] ?? "Product").toString();
        final qtyVal = double.tryParse(e['quantity']?.toString() ?? e['qty']?.toString() ?? "0.0") ?? 0.0;
        final rateExclVal = double.tryParse(e['purchase_price']?.toString() ?? e['rate']?.toString() ?? "0.0") ?? 0.0;
        final taxPercent = double.tryParse(e['tax_rate']?.toString() ?? e['gst_percent']?.toString() ?? "0.0") ?? 0.0;
        final rateInclVal = rateExclVal * (1 + taxPercent / 100);
        final sub = qtyVal * rateExclVal;
        final gst = sub * (taxPercent / 100);
        final discountVal = double.tryParse(e['discount']?.toString() ?? "0.0") ?? 0.0;
        final totalVal = sub + gst - discountVal;

        return BillItem(
          product: {
            "id": e['product_id'] ?? e['id'] ?? 1,
            "product_id": e['product_id'] ?? e['id'] ?? 1,
            "product_name": pName,
          },
          productName: pName,
          secondaryName: e['secondary_name']?.toString(),
          qty: qtyVal,
          unit: e['unit']?.toString() ?? "Pcs",
          gstPercent: taxPercent,
          rateExcl: rateExclVal,
          rateIncl: rateInclVal,
          gstAmt: gst,
          discount: discountVal,
          isDiscountPercentage: false,
          charges: double.tryParse(e['charges']?.toString() ?? "0.0") ?? 0.0,
          taxable: sub,
          total: totalVal,
        );
      }).toList();

      _calculateTotals();
    }
  }

  @override
  void dispose() {
    refNumberController.dispose();
    shippingController.dispose();
    notesController.dispose();
    primaryNameController.dispose();
    secondaryNameController.dispose();
    qtyController.dispose();
    rateExclController.dispose();
    rateInclController.dispose();
    gstAmtController.dispose();
    discountController.dispose();
    chargesController.dispose();
    taxableController.dispose();
    totalController.dispose();
    tableSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Purchase Bill Entry"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "3-Step Purchase Order & Invoice Workflow",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    _buildStepIndicator(),
                    const SizedBox(height: 20),
                    if (currentStep == 1) _buildStep1View(),
                    if (currentStep == 2) _buildStep2View(),
                    if (currentStep == 3) _buildStep3View(),
                  ],
                ),
              ),
            ),
            _buildBottomButtonsBar(),
          ],
        ),
      ),
    );
  }
}
