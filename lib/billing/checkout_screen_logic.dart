part of 'checkout_screen.dart';

mixin CheckoutScreenLogic on State<CheckoutScreen> {
  bool isQuotationMode = false; // Toggle between Bill and Quotation
  final notesController = TextEditingController();
  bool isSaving = false;

  // List of payments for Split Payment
  List<PaymentRowData> payments = [];

  @override
  void initState() {
    super.initState();
    // Start with one payment row populated with the grand total
    payments.add(PaymentRowData(
      mode: "UPI",
      amount: widget.grandTotal,
    ));
  }

  // Calculates totals based on payment rows
  double get paidAmount {
    double total = 0;
    for (var p in payments) {
      total += double.tryParse(p.amountController.text) ?? 0;
    }
    return total;
  }

  double get balanceDue {
    final diff = widget.grandTotal - paidAmount;
    return diff < 0 ? 0.0 : diff;
  }

  String get paymentStatus {
    final paid = paidAmount;
    if (paid >= widget.grandTotal) {
      return "PAID";
    } else if (paid > 0) {
      return "PARTIALLY PAID";
    } else {
      return "UNPAID";
    }
  }

  void _addPaymentRow() {
    setState(() {
      payments.add(PaymentRowData(
        mode: "Cash",
        amount: balanceDue,
      ));
    });
  }

  void _removePaymentRow(int index) {
    if (payments.length > 1) {
      setState(() {
        payments.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one payment method is required.")),
      );
    }
  }

  Future<void> _saveBill() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("billing_auth_token") ?? prefs.getString("auth_token") ?? "";
      final businessId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";

      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

      // Formulate billing items payload
      final itemsPayload = widget.items.map((item) => {
        "stock_id": item.stockId,
        "product_id": item.productId,
        "product_name": item.productName,
        "variant": item.variant,
        "warranty": item.warranty,
        "qty": item.qty,
        "unit_price": item.unitPrice,
        "total": item.total,
      }).toList();

      // Formulate payments details
      final paymentsPayload = payments.map((p) => {
        "mode": p.mode,
        "amount": double.tryParse(p.amountController.text) ?? 0.0,
        "transaction_id": p.transactionIdController.text,
        "reference_bank": p.bankController.text,
      }).toList();

      final body = {
        "business_id": businessId,
        "customer_name": widget.customer.name,
        "customer_mobile": widget.customer.mobile,
        "customer_email": widget.customer.email,
        "customer_address": widget.customer.address,
        "items": itemsPayload,
        "payments": paymentsPayload,
        "subtotal": widget.subtotal,
        "discount": widget.discount,
        "tax": widget.tax,
        "additional_charges": widget.additionalCharges,
        "total": widget.grandTotal,
        "paid_amount": paidAmount,
        "balance_due": balanceDue,
        "status": paymentStatus,
        "notes": notesController.text,
        "type": isQuotationMode ? "QUOTATION" : "BILL",
      };

      final urlStr = isQuotationMode 
          ? "https://billing.srivagroups.in/api/quotation"
          : "https://billing.srivagroups.in/api/sales/bills";

      final requestBodyStr = jsonEncode(body);
      final tokenLen = token.length;
      final first20 = tokenLen >= 20 ? token.substring(0, 20) : token;
      final last20 = tokenLen >= 20 ? token.substring(tokenLen - 20) : token;

      print("==============================");
      print("API REQUEST");
      print("==============================");
      print("Method: POST");
      print("URL: $urlStr");
      print("");
      print("Authorization:");
      print("Bearer $token");
      print("");
      print("Token Length: $tokenLen");
      print("First 20: $first20...");
      print("Last 20: ...$last20");
      print("");
      print("Full Token (for debugging only):");
      print(token);
      print("");
      print("Request Body:");
      print(requestBodyStr);
      print("");

      final response = await http.post(
        Uri.parse(urlStr),
        headers: headers,
        body: requestBodyStr,
      );

      print("==============================");
      print("API RESPONSE");
      print("==============================");
      print("Status: \${response.statusCode}");
      print("");
      print(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text("Success"),
              ],
            ),
            content: Text(isQuotationMode 
                ? "Quotation saved successfully!" 
                : "Bill generated and saved successfully!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // pop CheckoutScreen
                  Navigator.pop(context); // pop CustomerScreen (Generate Bill)
                },
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      } else {
        final errorMsg = jsonDecode(response.body)["message"] ?? "Failed to save. Server error.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: \$errorMsg")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: \$e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }
}
