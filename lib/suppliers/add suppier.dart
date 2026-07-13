import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

class AddSupplierScreen extends StatefulWidget {
  @override
  _AddSupplierScreenState createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  TextEditingController supplierName = TextEditingController();
  TextEditingController companyName = TextEditingController();
  TextEditingController panNumber = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController gstNumber = TextEditingController();

  TextEditingController building = TextEditingController();
  TextEditingController street = TextEditingController();
  TextEditingController landmark = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController state = TextEditingController();
  TextEditingController pincode = TextEditingController();

  bool isGST = true;
  bool isLoading = false;
  bool isPincodeLoading = false;
  String token = "";

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("auth_token") ?? "";
    });
  }

  // 📍 PINCODE AUTOFILL
  Future<void> fetchLocationFromPincode(String pin) async {
    if (pin.length != 6) return;

    print("==================================================");
    print("[PINCODE ENTERED]");
    print("==================================================");
    print("PINCODE => $pin");
    print("==================================================");

    setState(() => isPincodeLoading = true);

    final url = Uri.parse("https://api.postalpincode.in/pincode/$pin");

    print("==================================================");
    print("[PINCODE API REQUEST]");
    print("==================================================");
    print("URL => $url");
    print("==================================================");

    try {
      final response = await http.get(url);
      print("==================================================");
      print("[PINCODE API RESPONSE]");
      print("==================================================");
      print(response.body);
      print("==================================================");

      final data = jsonDecode(response.body);

      if (data != null && data is List && data.isNotEmpty && data[0]['Status'] == 'Success') {
        final postOffice = data[0]['PostOffice'][0];
        final district = postOffice['District'];
        final stateName = postOffice['State'];

        setState(() {
          city.text = district;
          state.text = stateName;
        });

        print("==================================================");
        print("[AUTO LOCATION FILLED]");
        print("==================================================");
        print("CITY => $district");
        print("STATE => $stateName");
        print("==================================================");
      } else {
        print("==================================================");
        print("[INVALID PINCODE]");
        print("==================================================");
        print("PINCODE NOT FOUND");
        print("==================================================");
      }
    } catch (e) {
      print("Error fetching pincode: $e");
    } finally {
      if (mounted) setState(() => isPincodeLoading = false);
    }
  }

  // 🔥 API CALL
  Future<void> saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    print("==================================================");
    print("[SUPPLIER SAVE STARTED]");
    print("==================================================");

    print("==================================================");
    print("[GST STATUS]");
    print("==================================================");
    print("IS GST ENABLED => $isGST");
    print("GST NUMBER => ${gstNumber.text}");
    print("==================================================");

    setState(() => isLoading = true);

    final url = Uri.parse("https://billing.srivagroups.in/api/suppliers/");

    final body = {
      "supplier_name": supplierName.text,
      "company_name": companyName.text,
      "pan_number": panNumber.text,
      "email": email.text,
      "primary_phone": phone.text,
      "is_gst_registered": isGST,
      "gst_number": isGST ? gstNumber.text : "",
      "building_name": building.text,
      "street": street.text,
      "landmark": landmark.text,
      "city": city.text,
      "state": state.text,
      "pincode": pincode.text,
      "status": "verified",
      "is_same_as_permanent": false,
      "branches": [],
    };

    print("==================================================");
    print("[SUPPLIER API REQUEST]");
    print("==================================================");
    print("METHOD => POST");
    print("URL => $url");
    print("==================================================");

    print("==================================================");
    print("[REQUEST PAYLOAD]");
    print("==================================================");
    print(body);
    print("==================================================");

    // 1. LOAD TOKEN
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token") ?? "";

    // 3. PASS HEADERS EXACTLY
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print("==================================================");
      print("[SUPPLIER API RESPONSE]");
      print("==================================================");
      print("STATUS CODE => ${response.statusCode}");
      print("BODY => ${response.body}");
      print("==================================================");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Supplier Saved Successfully ✅")),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save: ${response.body} ❌")),
          );
        }
      }
    } catch (e, stack) {
      print("==================================================");
      print("[SUPPLIER API ERROR]");
      print("==================================================");
      print(e);
      print(stack);
      print("==================================================");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network Error ❌")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 🔹 INPUT FIELD
  Widget input(String label, TextEditingController controller,
      {bool required = false, Function(String)? onChanged, Widget? suffix}) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: required
          ? (v) => v == null || v.isEmpty ? "Required" : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: suffix,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Supplier")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // 🔹 GST SECTION
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Tax Information"),
                          Switch(
                            value: isGST,
                            onChanged: (v) => setState(() => isGST = v),
                          )
                        ],
                      ),
                      if (isGST)
                        input("GST Number", gstNumber, required: true),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 🔹 GENERAL INFO
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      input("Supplier Name", supplierName, required: true),
                      SizedBox(height: 10),
                      input("Company Name", companyName),
                      SizedBox(height: 10),
                      input("PAN Number", panNumber),
                      SizedBox(height: 10),
                      input("Email", email),
                      SizedBox(height: 10),
                      input("Phone", phone, required: true),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 🔹 ADDRESS
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      input("Building", building),
                      SizedBox(height: 10),
                      input("Street", street),
                      SizedBox(height: 10),
                      input("Landmark", landmark),
                      SizedBox(height: 10),
                      input("City", city),
                      SizedBox(height: 10),
                      input("State", state),
                      SizedBox(height: 10),
                      input(
                        "Pincode",
                        pincode,
                        onChanged: (v) {
                          if (v.length == 6) fetchLocationFromPincode(v);
                        },
                        suffix: isPincodeLoading
                            ? Container(
                                width: 20,
                                height: 20,
                                padding: const EdgeInsets.all(12),
                                child: const CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 🔹 BUTTON
              ElevatedButton(
                onPressed: isLoading ? null : saveSupplier,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Save Supplier"),
              )
            ],
          ),
        ),
      ),
    );
  }
}