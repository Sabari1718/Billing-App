import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:billingapp/theme.dart';

part 'create_purchase_order_logic.dart';
part 'create_purchase_order_widgets.dart';
part 'create_purchase_order_sheets.dart';

class OrderItem {
  Map<String, dynamic>? product;
  final TextEditingController qtyController = TextEditingController(text: "1");
  final TextEditingController priceController = TextEditingController(text: "");
  final TextEditingController taxController = TextEditingController(text: "18");
  double total = 0.0;

  OrderItem({required VoidCallback onChanged}) {
    qtyController.addListener(() {
      _updateTotal();
      onChanged();
    });
    priceController.addListener(() {
      _updateTotal();
      onChanged();
    });
    taxController.addListener(() {
      onChanged();
    });
  }

  void _updateTotal() {
    final double qty = double.tryParse(qtyController.text) ?? 0.0;
    final double price = double.tryParse(priceController.text) ?? 0.0;
    total = qty * price;
  }

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
    taxController.dispose();
  }
}

class CreatePurchaseOrderPage extends StatefulWidget {
  final String token;

  const CreatePurchaseOrderPage({super.key, required this.token});

  @override
  State<CreatePurchaseOrderPage> createState() => _CreatePurchaseOrderPageState();
}

class _CreatePurchaseOrderPageState extends State<CreatePurchaseOrderPage> with CreatePurchaseOrderLogic {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Navigation header
                _buildTopNavigation(),
                const SizedBox(height: 20),

                // 2. Form details
                _buildBasicDetailsCard(isMobile),
                const SizedBox(height: 20),

                // 3. Items section
                _buildItemsSection(isMobile),
                const SizedBox(height: 20),

                // 4. Notes & Summary section
                _buildSummarySection(isMobile),
                const SizedBox(height: 32),

                // 5. Save/Cancel Actions
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
