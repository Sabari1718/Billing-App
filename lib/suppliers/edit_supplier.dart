import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

class EditSupplierScreen extends StatefulWidget {
  final Map<String, dynamic> supplier;

  const EditSupplierScreen({super.key, required this.supplier});

  @override
  State<EditSupplierScreen> createState() => _EditSupplierScreenState();
}

class _EditSupplierScreenState extends State<EditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isGst = true;
  int addressTabIndex = 0; // 0: Permanent, 1: Current
  bool isLoading = false;

  // Tax Info
  TextEditingController gstController = TextEditingController();

  // General Info
  TextEditingController supplierNameCtrl = TextEditingController();
  TextEditingController companyNameCtrl = TextEditingController();
  TextEditingController panNumberCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController phoneCtrl = TextEditingController();

  // Permanent Address
  TextEditingController permBuildingCtrl = TextEditingController();
  TextEditingController permStreetCtrl = TextEditingController();
  TextEditingController permLandmarkCtrl = TextEditingController();
  TextEditingController permCityCtrl = TextEditingController();
  TextEditingController permStateCtrl = TextEditingController();
  TextEditingController permPincodeCtrl = TextEditingController();

  // Current Address
  TextEditingController currBuildingCtrl = TextEditingController();
  TextEditingController currStreetCtrl = TextEditingController();
  TextEditingController currLandmarkCtrl = TextEditingController();
  TextEditingController currCityCtrl = TextEditingController();
  TextEditingController currStateCtrl = TextEditingController();
  TextEditingController currPincodeCtrl = TextEditingController();

  // Branches
  List<Map<String, TextEditingController>> branches = [];

  bool isPincodeLoading = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info("========== EDIT SUPPLIER SCREEN ==========");
    AppLogger.info("📥 SUPPLIER DATA: ${jsonEncode(widget.supplier)}");
    _prefillData();
  }

  void _prefillData() {
    AppLogger.info("📌 PREFILL START");
    try {
      final s = widget.supplier;
      
      // Check GST - handle int, bool or string
      final dynamic gstReg = s['is_gst_registered'];
      isGst = (gstReg == 1 || gstReg == true || (s['gst_number'] != null && s['gst_number'].toString().isNotEmpty));
      
      if (s['gst_number'] != null && s['gst_number'].toString() != 'null') {
        gstController.text = s['gst_number'].toString();
      }

      supplierNameCtrl.text = s['supplier_name']?.toString() ?? "";
      companyNameCtrl.text = s['company_name']?.toString() ?? "";
      panNumberCtrl.text = s['pan_number']?.toString() ?? "";
      emailCtrl.text = s['email']?.toString() ?? "";
      phoneCtrl.text = s['phone']?.toString() ?? s['primary_phone']?.toString() ?? "";

      // Address
      if (s['address'] is Map) {
        permBuildingCtrl.text = s['address']['building']?.toString() ?? "";
        permStreetCtrl.text = s['address']['street']?.toString() ?? "";
        permLandmarkCtrl.text = s['address']['landmark']?.toString() ?? "";
        permCityCtrl.text = s['address']['city']?.toString() ?? "";
        permStateCtrl.text = s['address']['state']?.toString() ?? "";
        permPincodeCtrl.text = s['address']['pincode']?.toString() ?? "";
      } else {
        // Fallback to flat fields
        permBuildingCtrl.text = s['building_name']?.toString() ?? s['building']?.toString() ?? "";
        permStreetCtrl.text = s['street']?.toString() ?? "";
        permLandmarkCtrl.text = s['landmark']?.toString() ?? "";
        permCityCtrl.text = s['city']?.toString() ?? "";
        permStateCtrl.text = s['state']?.toString() ?? "";
        permPincodeCtrl.text = s['pincode']?.toString() ?? "";
      }

      if (s['current_address'] is Map) {
        currBuildingCtrl.text = s['current_address']['building']?.toString() ?? "";
        currStreetCtrl.text = s['current_address']['street']?.toString() ?? "";
        currLandmarkCtrl.text = s['current_address']['landmark']?.toString() ?? "";
        currCityCtrl.text = s['current_address']['city']?.toString() ?? "";
        currStateCtrl.text = s['current_address']['state']?.toString() ?? "";
        currPincodeCtrl.text = s['current_address']['pincode']?.toString() ?? "";
      }

      // Branches
      if (s['branches'] != null && s['branches'] is List) {
        for (var branch in s['branches']) {
          branches.add({
            "name": TextEditingController(text: branch['branch_name']?.toString() ?? ""),
            "phone": TextEditingController(text: branch['branch_phone']?.toString() ?? ""),
          });
        }
      }
      
      if (branches.isEmpty) {
        _addBranch();
      }
      AppLogger.info("✅ PREFILL SUCCESS");
    } catch (e) {
      AppLogger.error("❌ PREFILL ERROR", e);
    }
  }

  Future<void> fetchLocationFromPincode(String pin, bool isPermanent) async {
    if (pin.length != 6) return;

    AppLogger.info("==================================================");
    AppLogger.info("[PINCODE AUTOFILL STARTED]");
    AppLogger.info("PINCODE => $pin");
    AppLogger.info("TYPE => ${isPermanent ? 'PERMANENT' : 'CURRENT'}");
    AppLogger.info("==================================================");

    setState(() => isPincodeLoading = true);

    final url = Uri.parse("https://api.postalpincode.in/pincode/$pin");

    try {
      final response = await http.get(url);
      AppLogger.api("GET", url.toString(), response.statusCode);

      final data = jsonDecode(response.body);

      if (data != null && data is List && data.isNotEmpty && data[0]['Status'] == 'Success') {
        final postOffice = data[0]['PostOffice'][0];
        final district = postOffice['District'];
        final stateName = postOffice['State'];

        setState(() {
          if (isPermanent) {
            permCityCtrl.text = district;
            permStateCtrl.text = stateName;
          } else {
            currCityCtrl.text = district;
            currStateCtrl.text = stateName;
          }
        });
        AppLogger.success("📍 LOCATION AUTO-FILLED: $district, $stateName");
      } else {
        AppLogger.warning("⚠️ INVALID PINCODE OR API ERROR");
      }
    } catch (e) {
      AppLogger.error("❌ PINCODE API EXCEPTION", e);
    } finally {
      setState(() => isPincodeLoading = false);
    }
  }

  void _addBranch() {
    setState(() {
      branches.add({
        "name": TextEditingController(),
        "phone": TextEditingController(),
      });
    });
    AppLogger.info("➕ NEW BRANCH ADDED");
  }

  Future<void> updateSupplier() async {
    AppLogger.info("==================================================");
    AppLogger.info("[SUPPLIER UPDATE STARTED]");
    AppLogger.info("==================================================");

    if (!_formKey.currentState!.validate()) {
      AppLogger.warning("⚠️ FORM VALIDATION FAILED");
      return;
    }
    
    if (isGst && gstController.text.trim().isEmpty) {
      AppLogger.warning("⚠️ GST ENABLED BUT NUMBER MISSING");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter GST Number")),
      );
      return;
    }

    setState(() => isLoading = true);

    final id = widget.supplier['id'];
    // BACKEND EXPECTS /update/{id}
    final url = Uri.parse("https://billing.srivagroups.in/api/suppliers/update/$id");
    
    AppLogger.info("🌐 TARGET URL: $url");

    List<Map<String, String>> branchList = [];
    for (var b in branches) {
      if (b["name"]!.text.trim().isNotEmpty) {
        branchList.add({
          "branch_name": b["name"]!.text.trim(),
          "branch_phone": b["phone"]!.text.trim(),
        });
      }
    }

    // 🛡️ SANITIZED PAYLOAD
    final body = {
      "supplier_name": supplierNameCtrl.text.trim(),
      "company_name": companyNameCtrl.text.trim(),
      "pan_number": panNumberCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "primary_phone": phoneCtrl.text.trim(),
      "is_gst_registered": isGst, // Standardized to Boolean for consistency
      "gst_number": isGst ? gstController.text.trim() : "",
      "building_name": permBuildingCtrl.text.trim(),
      "street": permStreetCtrl.text.trim(),
      "landmark": permLandmarkCtrl.text.trim(),
      "city": permCityCtrl.text.trim(),
      "state": permStateCtrl.text.trim(),
      "pincode": permPincodeCtrl.text.trim(),
      "status": "verified",
      "is_same_as_permanent": addressTabIndex == 0,
      "branches": branchList,
    };

    AppLogger.info("==================================================");
    AppLogger.info("[FINAL UPDATE PAYLOAD]");
    AppLogger.info("==================================================");
    AppLogger.info(jsonEncode(body));
    AppLogger.info("==================================================");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token") ?? "";

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      AppLogger.info("🚀 EXECUTING PUT REQUEST...");
      final response = await http.put(url, headers: headers, body: jsonEncode(body));
      
      AppLogger.info("==================================================");
      AppLogger.info("[SUPPLIER UPDATE RESPONSE]");
      AppLogger.info("==================================================");
      AppLogger.info("STATUS CODE => ${response.statusCode}");
      AppLogger.info("BODY => ${response.body}");
      AppLogger.info("==================================================");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Supplier Updated Successfully ✅"), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Update Failed (${response.statusCode}) ❌"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e, stack) {
      AppLogger.error("🔥 UPDATE EXCEPTION", e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network Error: $e ❌"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildSectionCard({required IconData icon, required String title, required Widget child, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFF1F5F9)),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _responsiveRow(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 16), child: w)).toList(),
        );
      }
      
      List<Widget> rowChildren = [];
      for (int i = 0; i < children.length; i++) {
        rowChildren.add(Expanded(child: children[i]));
        if (i < children.length - 1) {
          rowChildren.add(const SizedBox(width: 16));
        }
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ),
      );
    });
  }

  Widget _buildInput(String label, TextEditingController controller, {bool required = false, String hint = "", Function(String)? onChanged, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            children: [
              if (required) const TextSpan(text: " *", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: required ? (v) => v == null || v.isEmpty ? "Required" : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Widget _buildGstToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => isGst = true),
            child: Text("With GST", style: TextStyle(color: isGst ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => setState(() => isGst = false),
            child: Text("Without GST", style: TextStyle(color: !isGst ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Switch(
            value: isGst,
            onChanged: (v) => setState(() => isGst = v),
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF4F46E5),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Edit Supplier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1️⃣ Tax Information & Registration
              _buildSectionCard(
                icon: Icons.assignment_ind_outlined,
                title: "Tax Information & Registration",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGstToggle(),
                    if (isGst) ...[
                      const SizedBox(height: 24),
                      _responsiveRow([
                        _buildInput("GST NUMBER", gstController, required: true, hint: "E.G. 22AAAAA0000A1Z5"),
                        const SizedBox(), // Empty for layout mapping
                      ]),
                      const Text("Auto-fills company info based on GSTN", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ],
                ),
              ),

              // 2️⃣ General Information
              _buildSectionCard(
                icon: Icons.person_add_alt_outlined,
                title: "General Information",
                child: Column(
                  children: [
                    _responsiveRow([
                      _buildInput("SUPPLIER NAME", supplierNameCtrl, required: true),
                      _buildInput("COMPANY NAME", companyNameCtrl),
                    ]),
                    _responsiveRow([
                      _buildInput("PAN NUMBER", panNumberCtrl),
                      _buildInput("EMAIL ADDRESS", emailCtrl),
                    ]),
                    _responsiveRow([
                      _buildInput("PRIMARY PHONE NUMBER", phoneCtrl, required: true),
                      const SizedBox(), // empty flex slot for grid alignment
                    ]),
                  ],
                ),
              ),

              // 3️⃣ Address Details
              _buildSectionCard(
                icon: Icons.location_on_outlined,
                title: "Address Details",
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      currBuildingCtrl.text = permBuildingCtrl.text;
                      currStreetCtrl.text = permStreetCtrl.text;
                      currLandmarkCtrl.text = permLandmarkCtrl.text;
                      currCityCtrl.text = permCityCtrl.text;
                      currStateCtrl.text = permStateCtrl.text;
                      currPincodeCtrl.text = permPincodeCtrl.text;
                      addressTabIndex = 1; // auto-switch to show the copied data
                    });
                  },
                  child: const Text("Copy Permanent to Current", style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => addressTabIndex = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: addressTabIndex == 0 ? const Color(0xFF4F46E5) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: addressTabIndex == 0 ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                              ),
                              child: Center(child: Text("Permanent Address", style: TextStyle(color: addressTabIndex == 0 ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => addressTabIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: addressTabIndex == 1 ? const Color(0xFF4F46E5) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: addressTabIndex == 1 ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                              ),
                              child: Center(child: Text("Current Address", style: TextStyle(color: addressTabIndex == 1 ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Fields depending on active tab
                    if (addressTabIndex == 0) ...[
                      _responsiveRow([
                        _buildInput("BUILD NAME/NO", permBuildingCtrl),
                        _buildInput("STREET", permStreetCtrl),
                      ]),
                      _responsiveRow([
                        _buildInput("LANDMARK", permLandmarkCtrl),
                        _buildInput("CITY", permCityCtrl),
                      ]),
                      _responsiveRow([
                        _buildInput("STATE", permStateCtrl),
                        _buildInput("PINCODE", permPincodeCtrl, 
                          onChanged: (val) => fetchLocationFromPincode(val, true),
                          suffix: isPincodeLoading ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                        ),
                      ]),
                    ] else ...[
                      _responsiveRow([
                        _buildInput("BUILD NAME/NO", currBuildingCtrl),
                        _buildInput("STREET", currStreetCtrl),
                      ]),
                      _responsiveRow([
                        _buildInput("LANDMARK", currLandmarkCtrl),
                        _buildInput("CITY", currCityCtrl),
                      ]),
                      _responsiveRow([
                        _buildInput("STATE", currStateCtrl),
                        _buildInput("PINCODE", currPincodeCtrl,
                          onChanged: (val) => fetchLocationFromPincode(val, false),
                          suffix: isPincodeLoading ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                        ),
                      ]),
                    ],
                  ],
                ),
              ),

              // 4️⃣ Associated Branches
              _buildSectionCard(
                icon: Icons.language,
                title: "Associated Branches",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...branches.asMap().entries.map((entry) {
                      int index = entry.key;
                      var b = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: _responsiveRow([
                                  _buildInput("BRANCH NAME", b["name"]!, hint: "e.g. Head Office"),
                                  _buildInput("BRANCH PHONE", b["phone"]!, hint: "Phone Number"),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => setState(() => branches.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _addBranch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Color(0xFF4F46E5), size: 18),
                            SizedBox(width: 8),
                            Text("Add Another Branch", style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : updateSupplier,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
