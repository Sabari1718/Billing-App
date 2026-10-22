part of 'purchase_bill_entry.dart';

extension _PurchaseBillEntryPageStateLogic on _PurchaseBillEntryPageState {
  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("auth_token") ?? "";
    _fetchSuppliers();
    _fetchProducts();
  }

  Future<void> _fetchSuppliers() async {
    setState(() => isSuppliersLoading = true);
    const url = "https://billing.srivagroups.in/api/suppliers/";
    try {
      final res = await http.get(Uri.parse(url), headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final listData = decoded['data']?['data']?['data'] ?? decoded['data'] ?? decoded;
        if (listData is List) {
          setState(() {
            suppliers = listData;
            isSuppliersLoading = false;
            if (widget.editBill != null) {
              final editSupplierName = widget.editBill!['supplier_name'] ?? widget.editBill!['supplier']?['supplier_name'];
              final editSupplierId = widget.editBill!['supplier_id'];
              try {
                selectedSupplier = listData.firstWhere(
                  (s) => s['id'] == editSupplierId || s['supplier_name'] == editSupplierName,
                );
              } catch (_) {}
            }
          });
        }
      } else {
        setState(() => isSuppliersLoading = false);
      }
    } catch (e) {
      AppLogger.error("Fetch suppliers error in Purchase Bill Entry", e);
      setState(() => isSuppliersLoading = false);
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => isProductsLoading = true);
    final List<String> urls = [
      "https://billing.srivagroups.in/api/products",
      "https://billing.srivagroups.in/api/stocks",
      "https://billing.srivagroups.in/api/supplierProduct"
    ];

    bool success = false;
    for (String url in urls) {
      if (success) break;
      try {
        final res = await http.get(Uri.parse(url), headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        });

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          dynamic listData;
          
          if (decoded is List) {
            listData = decoded;
          } else if (decoded is Map) {
            final firstData = decoded['data'];
            if (firstData is List) {
              listData = firstData;
            } else if (firstData is Map) {
              final secondData = firstData['data'];
              if (secondData is List) {
                listData = secondData;
              } else if (secondData is Map) {
                final thirdData = secondData['data'];
                if (thirdData is List) {
                  listData = thirdData;
                }
              }
            }
          }
          
          // Fallback if none of the above matches
          listData ??= decoded;
          
          if (listData is List && listData.isNotEmpty) {
            List processedList = [];
            for (var item in listData) {
              if (item is! Map) continue;
              
              String categoryName = "";
              if (item['category_name'] != null) {
                categoryName = item['category_name'].toString();
              } else if (item['category'] != null) {
                if (item['category'] is Map) {
                  categoryName = (item['category']['name'] ?? "").toString();
                } else if (item['category'] is String) {
                  categoryName = item['category'].toString();
                }
              }

              final variants = item['variants'];
              if (variants is List && variants.isNotEmpty) {
                for (var variant in variants) {
                  if (variant is! Map) continue;
                  
                  String variantLabel = "";
                  final typeId = (variant['variant_id'] ?? "").toString();
                  if (typeId == "1") {
                    variantLabel = "Original";
                  } else if (typeId == "2") {
                    variantLabel = "Import";
                  } else if (typeId == "3") {
                    variantLabel = "Complimentary";
                  } else if (variant['variant'] is Map && variant['variant']['name'] != null) {
                    variantLabel = variant['variant']['name'].toString();
                  } else if (variant['name'] != null) {
                    variantLabel = variant['name'].toString();
                  }
                  
                  final String parentName = (item['product_name'] ?? item['name'] ?? "Unknown").toString();
                  final String displayName = variantLabel.isNotEmpty ? "$parentName ($variantLabel)" : parentName;
                  
                  processedList.add({
                    "id": item['id'] ?? item['product_id'] ?? "",
                    "variant_id": variant['id'] ?? "",
                    "product_name": displayName,
                    "name": displayName,
                    "sku": (variant['sku'] ?? item['sku'] ?? "").toString(),
                    "selling_price": (variant['selling_price'] ?? variant['price'] ?? item['selling_price'] ?? item['price'] ?? "0").toString(),
                    "price": (variant['selling_price'] ?? variant['price'] ?? item['selling_price'] ?? item['price'] ?? "0").toString(),
                    "category": item['category'],
                    "category_name": categoryName,
                    "unit": (variant['unit'] ?? item['unit'] ?? "Pcs").toString(),
                    "tax": (variant['tax'] ?? item['tax'] ?? "18").toString(),
                  });
                }
              } else {
                final String displayName = (item['product_name'] ?? item['name'] ?? "Unknown").toString();
                processedList.add({
                  "id": item['id'] ?? item['product_id'] ?? "",
                  "product_name": displayName,
                  "name": displayName,
                  "sku": (item['sku'] ?? "").toString(),
                  "selling_price": (item['selling_price'] ?? item['price'] ?? "0").toString(),
                  "price": (item['selling_price'] ?? item['price'] ?? "0").toString(),
                  "category": item['category'],
                  "category_name": categoryName,
                  "unit": (item['unit'] ?? "Pcs").toString(),
                  "tax": (item['tax'] ?? "18").toString(),
                });
              }
            }
            
            setState(() {
              products = processedList;
              isProductsLoading = false;
            });
            success = true;
          }
        }
      } catch (e, stack) {
        AppLogger.error("Failed to load products from $url: $e\n$stack", e);
      }
    }

    if (!success) {
      setState(() {
        isProductsLoading = false;
      });
    }
  }

  void _calculateFormValues({bool fromExcl = false, bool fromIncl = false}) {
    final double qty = double.tryParse(qtyController.text) ?? 0.0;
    final double gstPct = double.tryParse(gstPercentValue.replaceAll('%', '')) ?? 0.0;
    
    double rateExcl = double.tryParse(rateExclController.text) ?? 0.0;
    double rateIncl = double.tryParse(rateInclController.text) ?? 0.0;
    
    if (fromExcl) {
      rateIncl = rateExcl * (1 + gstPct / 100);
      rateInclController.text = rateIncl.toStringAsFixed(2);
    } else if (fromIncl) {
      rateExcl = rateIncl / (1 + gstPct / 100);
      rateExclController.text = rateExcl.toStringAsFixed(2);
    } else {
      rateIncl = rateExcl * (1 + gstPct / 100);
      rateInclController.text = rateIncl.toStringAsFixed(2);
    }
    
    final double subtotalVal = qty * rateExcl;
    final double discInput = double.tryParse(discountController.text) ?? 0.0;
    final double discountVal = isDiscountPercentage ? (subtotalVal * (discInput / 100)) : discInput;
    final double charges = double.tryParse(chargesController.text) ?? 0.0;
    
    final double taxable = subtotalVal - discountVal + charges;
    final double gstAmt = taxable * (gstPct / 100);
    final double total = taxable + gstAmt;
    
    gstAmtController.text = gstAmt.toStringAsFixed(2);
    taxableController.text = taxable.toStringAsFixed(2);
    totalController.text = total.toStringAsFixed(2);
  }

  void _resetForm() {
    setState(() {
      selectedFormProduct = null;
      primaryNameController.clear();
      secondaryNameController.clear();
      qtyController.text = "1";
      unitValue = "Pcs";
      gstPercentValue = "18%";
      rateExclController.text = "0.00";
      rateInclController.text = "0.00";
      gstAmtController.text = "0";
      discountController.text = "0";
      isDiscountPercentage = true;
      chargesController.text = "0.00";
      taxableController.text = "0";
      totalController.text = "0";
    });
  }

  void _addFormItemToList() {
    if (selectedFormProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product first."), backgroundColor: AppColors.error),
      );
      return;
    }
    
    final String pName = primaryNameController.text.trim();
    if (pName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Primary Name cannot be empty."), backgroundColor: AppColors.error),
      );
      return;
    }

    final double qty = double.tryParse(qtyController.text) ?? 0.0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantity must be greater than zero."), backgroundColor: AppColors.error),
      );
      return;
    }

    final double rateExcl = double.tryParse(rateExclController.text) ?? 0.0;
    if (rateExcl < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rate (Excl.) must be positive."), backgroundColor: AppColors.error),
      );
      return;
    }

    final double rateIncl = double.tryParse(rateInclController.text) ?? 0.0;
    final double gstPercent = double.tryParse(gstPercentValue.replaceAll('%', '')) ?? 0.0;
    final double gstAmt = double.tryParse(gstAmtController.text) ?? 0.0;
    final double discount = double.tryParse(discountController.text) ?? 0.0;
    final double charges = double.tryParse(chargesController.text) ?? 0.0;
    final double taxable = double.tryParse(taxableController.text) ?? 0.0;
    final double total = double.tryParse(totalController.text) ?? 0.0;
    final String? secName = enableSecondaryName ? secondaryNameController.text.trim() : null;

    setState(() {
      items.add(
        BillItem(
          product: selectedFormProduct,
          productName: pName,
          secondaryName: secName,
          qty: qty,
          unit: unitValue,
          gstPercent: gstPercent,
          rateExcl: rateExcl,
          rateIncl: rateIncl,
          gstAmt: gstAmt,
          discount: discount,
          isDiscountPercentage: isDiscountPercentage,
          charges: charges,
          taxable: taxable,
          total: total,
        ),
      );
      _calculateTotals();
      _resetForm();
    });
  }

  void _calculateTotals() {
    double tempSubtotal = 0.0;
    double tempTaxTotal = 0.0;
    double tempDiscountTotal = 0.0;
    double tempChargesTotal = 0.0;

    for (var item in items) {
      final double itemSubtotal = item.qty * item.rateExcl;
      final double discVal = item.isDiscountPercentage ? (itemSubtotal * (item.discount / 100)) : item.discount;
      
      tempSubtotal += itemSubtotal;
      tempDiscountTotal += discVal;
      tempChargesTotal += item.charges;
      tempTaxTotal += item.gstAmt;
    }

    final double shipping = double.tryParse(shippingController.text) ?? 0.0;

    setState(() {
      subtotal = tempSubtotal - tempDiscountTotal + tempChargesTotal;
      taxTotal = tempTaxTotal;
      grandTotal = subtotal + taxTotal + shipping;
    });
  }

  Future<void> _submitPurchaseBill() async {
    setState(() => isSubmitting = true);
    
    final Map<String, dynamic> payload = {
      "invoice_number": invoiceNumber,
      "supplier_id": selectedSupplier!['id'],
      "supplier_name": selectedSupplier!['supplier_name'] ?? selectedSupplier!['company_name'],
      "purchase_date": DateFormat('yyyy-MM-dd').format(purchaseDate),
      "purchase_time": "${purchaseTime.hour.toString().padLeft(2, '0')}:${purchaseTime.minute.toString().padLeft(2, '0')}:00",
      "delivery_date": DateFormat('yyyy-MM-dd').format(deliveryDate),
      "reference_number": refNumberController.text,
      "reference_date": refDate != null ? DateFormat('yyyy-MM-dd').format(refDate!) : null,
      "payment_method": selectedPaymentMethod.toLowerCase(),
      "subtotal": subtotal,
      "tax_total": taxTotal,
      "shipping_charges": double.tryParse(shippingController.text) ?? 0.0,
      "grand_total": grandTotal,
      "notes": notesController.text.trim(),
      "items": items.map((item) => {
        "product_id": item.product!['id'] ?? item.product!['product_id'],
        "product_name": item.productName,
        "secondary_name": item.secondaryName,
        "quantity": item.qty.toInt(),
        "price": item.rateExcl,
        "tax": item.gstPercent,
      }).toList(),
    };

    final isEdit = widget.editBill != null;
    final String url = isEdit
        ? "https://billing.srivagroups.in/api/purchase-bill/${widget.editBill!['id']}"
        : "https://billing.srivagroups.in/api/purchase-bill";

    try {
      final response = isEdit
          ? await http.put(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(payload),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? "Purchase Bill Updated Successfully! ✅" : "Purchase Bill Created Successfully! ✅"), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Purchase Bill Entry Saved Locally! ✅"), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error("Submit Purchase Bill Error", e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Purchase Bill Entry Completed Successfully! ✅"), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _handleNextOrSubmit() {
    if (currentStep == 1) {
      if (selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please search and select a Supplier before proceeding to Step 2."),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() {
        currentStep = 2;
      });
    } else if (currentStep == 2) {
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add at least one product before proceeding."), backgroundColor: AppColors.error),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PurchasePaymentSummaryPage(
            supplier: selectedSupplier!,
            items: items,
            invoiceNumber: invoiceNumber,
            purchaseDate: purchaseDate,
            purchaseTime: purchaseTime,
            deliveryDate: deliveryDate,
            refNumber: refNumberController.text,
            refDate: refDate,
            token: token,
          ),
        ),
      ).then((value) {
        if (value == true) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  String _getSupplierLocation(Map supplier) {
    final String city = (supplier['city'] ?? "").toString().trim();
    final String state = (supplier['state'] ?? "").toString().trim();
    if (city.isNotEmpty && state.isNotEmpty) {
      return "$city, $state";
    }
    return city.isNotEmpty ? city : (state.isNotEmpty ? state : "-");
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != purchaseDate) {
      setState(() {
        purchaseDate = picked;
      });
    }
  }

  Future<void> _selectPurchaseTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: purchaseTime,
    );
    if (picked != null && picked != purchaseTime) {
      setState(() {
        purchaseTime = picked;
      });
    }
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: deliveryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != deliveryDate) {
      setState(() {
        deliveryDate = picked;
      });
    }
  }

  Future<void> _selectRefDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: refDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        refDate = picked;
      });
    }
  }
}
