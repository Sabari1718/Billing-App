import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:billingapp/theme.dart';
import 'purchase_bill_entry.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'purchase_payment_summary_logic.dart';
part 'purchase_payment_summary_pdf.dart';
part 'purchase_payment_summary_widgets.dart';

class PaymentRowData {
  String mode;
  final TextEditingController amountController;
  final TextEditingController txnController;

  PaymentRowData({
    required this.mode,
    double amount = 0.0,
    String txn = "",
  })  : amountController = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(2) : ""),
        txnController = TextEditingController(text: txn);
}

class PurchasePaymentSummaryPage extends StatefulWidget {
  final Map<String, dynamic> supplier;
  final List<BillItem> items;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final TimeOfDay purchaseTime;
  final DateTime deliveryDate;
  final String refNumber;
  final DateTime? refDate;
  final String token;

  const PurchasePaymentSummaryPage({
    super.key,
    required this.supplier,
    required this.items,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.purchaseTime,
    required this.deliveryDate,
    required this.refNumber,
    required this.refDate,
    required this.token,
  });

  @override
  State<PurchasePaymentSummaryPage> createState() => _PurchasePaymentSummaryPageState();
}

class _PurchasePaymentSummaryPageState extends State<PurchasePaymentSummaryPage> {
  bool isSubmitting = false;

  // Form states
  bool isSplitPayment = false;
  
  // Single payment details
  String selectedPaymentMode = "Credit / Pay Later";
  String selectedPaymentStatus = "Pending (Unpaid)";
  final TextEditingController singlePaidAmountController = TextEditingController(text: "0.00");
  final TextEditingController singleRefNoteController = TextEditingController();
  DateTime paymentDate = DateTime.now();
  final TextEditingController termsConditionsController = TextEditingController();

  // Split payment details
  List<PaymentRowData> paymentsSplits = [];

  // Summary and calculations
  double subtotalExcl = 0.0;
  double totalGstAmount = 0.0;
  int totalProducts = 0;
  double totalQuantity = 0.0;

  List<Map<String, dynamic>> extraChargesList = [];
  String discountType = "%";
  final TextEditingController discountValController = TextEditingController(text: "0");
  bool isManualRoundOff = false;
  final TextEditingController roundOffController = TextEditingController();
  final FocusNode roundOffFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    totalProducts = widget.items.length;
    for (var item in widget.items) {
      totalQuantity += item.qty;
      subtotalExcl += item.qty * item.rateExcl;
      totalGstAmount += item.gstAmt;
    }
    
    roundOffController.addListener(() {
      if (roundOffFocusNode.hasFocus) {
        if (roundOffController.text.isEmpty) {
          isManualRoundOff = false;
        } else {
          isManualRoundOff = true;
        }
      }
      setState(() {});
    });

    singlePaidAmountController.addListener(() {
      setState(() {});
    });
    discountValController.addListener(() {
      setState(() {
        _calculateSummary();
      });
    });
    _calculateSummary();
  }

  @override
  void dispose() {
    singlePaidAmountController.dispose();
    singleRefNoteController.dispose();
    termsConditionsController.dispose();
    discountValController.dispose();
    roundOffController.dispose();
    roundOffFocusNode.dispose();
    for (var split in paymentsSplits) {
      split.amountController.dispose();
      split.txnController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 900;

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
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildPaymentDetailsCard()),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildSummaryCard()),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildPaymentDetailsCard(),
                          const SizedBox(height: 16),
                          _buildSummaryCard(),
                        ],
                      ),
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
