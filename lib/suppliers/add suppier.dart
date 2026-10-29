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
  final TextEditingController pincodeController;

  BranchRowData({String name = "", String phone = "", String pincode = ""})
      : nameController = TextEditingController(text: name),
        phoneController = TextEditingController(text: phone),
        pincodeController = TextEditingController(text: pincode);

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    pincodeController.dispose();
  }
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
    if (branchesList.isEmpty) {
      branchesList.add(BranchRowData());
    }
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
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.arrow_back, size: 13, color: Color(0xFF1E293B)),
                              SizedBox(width: 4),
                              Text(
                                "Back to Suppliers",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Add New Supplier",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Create a new supplier profile in your system step by step",
                        style: TextStyle(
                          fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepItem(1, "Tax Information", currentStep == 1, currentStep > 1),
            Container(
              width: 20,
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: currentStep > 1 ? const Color(0xFF10B981) : Colors.grey.shade200,
            ),
            _buildStepItem(2, "General Information", currentStep == 2, currentStep > 2),
            Container(
              width: 20,
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: currentStep > 2 ? const Color(0xFF10B981) : Colors.grey.shade200,
            ),
            _buildStepItem(3, "Address Details", currentStep == 3, false),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int stepNum, String title, bool isActive, bool isCompleted) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF10B981)
                : (isActive ? const Color(0xFF4F46E5) : Colors.white),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : (isActive ? const Color(0xFF4F46E5) : Colors.grey.shade300),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    "$stepNum",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep > 1)
            OutlinedButton.icon(
              onPressed: isLoading ? null : _handleBackStep,
              icon: const Icon(Icons.arrow_back, size: 15, color: Color(0xFF475569)),
              label: const Text(
                "Back",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: isLoading ? null : _handleNextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentStep == 3) ...[
                        const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        currentStep == 3 ? "Save Supplier Profile" : "Next",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (currentStep < 3) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 15),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}