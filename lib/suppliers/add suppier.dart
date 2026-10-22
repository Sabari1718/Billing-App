import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

part 'add_supplier_logic.dart';
part 'add_supplier_widgets.dart';

class BranchRowData {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  BranchRowData({String name = "", String phone = ""})
      : nameController = TextEditingController(text: name),
        phoneController = TextEditingController(text: phone);
}

class AddSupplierScreen extends StatefulWidget {
  @override
  _AddSupplierScreenState createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> with AddSupplierLogic {
  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Add Supplier",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add New Supplier",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Create a new supplier profile in your system step by step",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildStepIndicator(),
                      const SizedBox(height: 24),

                      if (currentStep == 1) _buildTaxInfoCard(),
                      if (currentStep == 2) ...[
                        _buildGeneralInfoCard(),
                        const SizedBox(height: 16),
                        _buildBranchesCard(),
                      ],
                      if (currentStep == 3) _buildAddressCard(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Step $currentStep of 3",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
              Text(
                currentStep == 1
                    ? "Tax Info & Registration"
                    : currentStep == 2
                        ? "General Information"
                        : "Address Details",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentStep / 3.0,
              backgroundColor: Colors.grey.shade100,
              color: const Color(0xFF6366F1),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (currentStep > 1) ...[
            OutlinedButton(
              onPressed: isLoading ? null : _handleBackStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back, size: 16, color: Color(0xFF475569)),
                  SizedBox(width: 6),
                  Text(
                    "Back",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (currentStep == 3) ...[
                          const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          currentStep == 3 ? "Save Supplier Profile" : "Next",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (currentStep < 3) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}