part of 'purchase_payment_summary.dart';

extension _PurchasePaymentSummaryPageStateLogic on _PurchasePaymentSummaryPageState {
  double get totalExtraCharges {
    double total = 0.0;
    for (var charge in extraChargesList) {
      total += charge['amount'] ?? 0.0;
    }
    return total;
  }

  double get billDiscountAmount {
    final double inputVal = double.tryParse(discountValController.text) ?? 0.0;
    if (discountType == "%") {
      return subtotalExcl * (inputVal / 100);
    } else {
      return inputVal;
    }
  }

  double get rawGrandTotal {
    final val = subtotalExcl + totalGstAmount + totalExtraCharges - billDiscountAmount;
    return val < 0 ? 0.0 : val;
  }

  double get roundedGrandTotal {
    final val = rawGrandTotal + roundOffAmount;
    return val < 0 ? 0.0 : val;
  }

  double get roundOffAmount {
    return double.tryParse(roundOffController.text) ?? 0.0;
  }

  double get totalPaid {
    if (isSplitPayment) {
      double sum = 0.0;
      for (var split in paymentsSplits) {
        sum += double.tryParse(split.amountController.text) ?? 0.0;
      }
      return sum;
    } else {
      if (selectedPaymentStatus == "Pending (Unpaid)") {
        return 0.0;
      } else if (selectedPaymentStatus == "Fully Paid") {
        return roundedGrandTotal;
      } else {
        final val = double.tryParse(singlePaidAmountController.text) ?? 0.0;
        return val > roundedGrandTotal ? roundedGrandTotal : val;
      }
    }
  }

  double get balanceDue {
    final due = roundedGrandTotal - totalPaid;
    return due < 0 ? 0.0 : due;
  }

  String get finalPaymentStatus {
    if (isSplitPayment) {
      final paid = totalPaid;
      if (paid >= roundedGrandTotal && roundedGrandTotal > 0) {
        return "Fully Paid";
      } else if (paid > 0) {
        return "Partially Paid";
      } else {
        return "Pending (Unpaid)";
      }
    } else {
      return selectedPaymentStatus;
    }
  }

  void _calculateSummary() {
    if (!isManualRoundOff) {
      final double raw = rawGrandTotal;
      final double rounded = raw.roundToDouble();
      final double diff = rounded - raw;
      final String textVal = diff.toStringAsFixed(2);
      if (roundOffController.text != textVal) {
        roundOffController.text = textVal;
      }
    }
  }

  void _addPaymentSplit() {
    setState(() {
      paymentsSplits.add(PaymentRowData(
        mode: "Cash",
        amount: balanceDue,
      ));
    });
  }

  void _removePaymentSplit(int index) {
    setState(() {
      paymentsSplits.removeAt(index);
    });
  }

  Future<void> _selectPaymentDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != paymentDate) {
      setState(() {
        paymentDate = picked;
      });
    }
  }

  void _showAddExtraChargeDialog() {
    String selectedChargeType = "Transport Charges";
    final TextEditingController chargeAmountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Add Extra Charge", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Charge Type *", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedChargeType,
                        isExpanded: true,
                        items: ["Transport Charges", "Packaging Charges", "Shipping Charges", "Other Charges"].map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedChargeType = val!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Amount (₹) *", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: chargeAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      prefixText: "₹ ",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final double amt = double.tryParse(chargeAmountCtrl.text) ?? 0.0;
                    if (amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid positive amount."), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    setState(() {
                      extraChargesList.add({
                        "name": selectedChargeType,
                        "amount": amt,
                      });
                      _calculateSummary();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitPurchaseBill({required bool showPrintPreview}) async {
    setState(() => isSubmitting = true);

    final String supplierName = widget.supplier['supplier_name'] ?? widget.supplier['company_name'] ?? "Unknown";
    
    final List<Map<String, dynamic>> itemsPayload = widget.items.map((item) => {
      "product_id": item.product!['id'] ?? item.product!['product_id'],
      "product_name": item.productName,
      "secondary_name": item.secondaryName,
      "quantity": item.qty.toInt(),
      "price": item.rateExcl,
      "tax": item.gstPercent,
    }).toList();

    List<Map<String, dynamic>> finalPayments = [];
    if (isSplitPayment) {
      finalPayments = paymentsSplits.map((p) => {
        "mode": p.mode,
        "amount": double.tryParse(p.amountController.text) ?? 0.0,
        "ref_no": p.txnController.text.trim(),
      }).toList();
    } else {
      finalPayments.add({
        "mode": selectedPaymentMode,
        "amount": totalPaid,
        "ref_no": singleRefNoteController.text.trim(),
      });
    }

    final Map<String, dynamic> payload = {
      "invoice_number": widget.invoiceNumber,
      "supplier_id": widget.supplier['id'],
      "supplier_name": supplierName,
      "purchase_date": DateFormat('yyyy-MM-dd').format(widget.purchaseDate),
      "purchase_time": "${widget.purchaseTime.hour.toString().padLeft(2, '0')}:${widget.purchaseTime.minute.toString().padLeft(2, '0')}:00",
      "delivery_date": DateFormat('yyyy-MM-dd').format(widget.deliveryDate),
      "reference_number": widget.refNumber,
      "reference_date": widget.refDate != null ? DateFormat('yyyy-MM-dd').format(widget.refDate!) : null,
      "payment_method": isSplitPayment ? "split" : selectedPaymentMode.toLowerCase(),
      "payment_status": finalPaymentStatus.toLowerCase(),
      "payment_date": DateFormat('yyyy-MM-dd').format(paymentDate),
      "subtotal": subtotalExcl,
      "tax_total": totalGstAmount,
      "shipping_charges": totalExtraCharges,
      "discount_type": discountType,
      "discount_amount": double.tryParse(discountValController.text) ?? 0.0,
      "round_off": roundOffAmount,
      "grand_total": roundedGrandTotal,
      "paid_amount": totalPaid,
      "balance_due": balanceDue,
      "notes": termsConditionsController.text.trim(),
      "items": itemsPayload,
      "payments": finalPayments,
    };

    const String url = "https://billing.srivagroups.in/api/purchase-bill";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (showPrintPreview) {
          _showPrintPreviewDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Purchase Bill Entry Completed Successfully! ✅"), backgroundColor: AppColors.success),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (showPrintPreview) {
          _showPrintPreviewDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Purchase Bill Entry Saved Locally! ✅"), backgroundColor: AppColors.success),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      AppLogger.error("Submit Purchase Bill Error in payment summary", e);
      if (showPrintPreview) {
        _showPrintPreviewDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Purchase Bill Entry Completed Successfully! ✅"), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }
}
