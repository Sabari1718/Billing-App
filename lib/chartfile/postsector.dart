import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddGets extends StatefulWidget {
  const AddGets({super.key});

  @override
  State<AddGets> createState() => _AddGetsState();
}

class _AddGetsState extends State<AddGets> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final mrpController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();

  final String apiUrl = "http://localhost:3002/cart/create";

  Future<void> postGets() async {
    if (!_formKey.currentState!.validate()) return;

    int price = int.tryParse(priceController.text) ?? 0;
    int quantity = int.tryParse(quantityController.text) ?? 0;

    int totalPrice = price * quantity;

    final body = {
      "name": nameController.text.trim(),
      "mobile": mobileController.text.trim(),
      "email": emailController.text.trim(),
      "mrp": int.tryParse(mrpController.text) ?? 0,
      "price": price,
      "quantity": quantity,
      "total_price": totalPrice
    };

    debugPrint("SENDING DATA => $body");

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      debugPrint("STATUS CODE => ${res.statusCode}");
      debugPrint("RESPONSE => ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data Inserted Successfully"),
            backgroundColor: Colors.green,
          ),
        );

        nameController.clear();
        mobileController.clear();
        emailController.clear();
        mrpController.clear();
        priceController.clear();
        quantityController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.body)),
        );
      }
    } catch (e) {
      debugPrint("ERROR => $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    mrpController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Widget field(
      String label,
      IconData icon,
      TextEditingController controller, {
        TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF3B5BDB)),
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF1F4FF),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E6FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Color(0xFF3B5BDB), width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Gets"),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEEF2FF),
              Color(0xFFF9FAFF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x223B5BDB),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  field(
                    "Name",
                    Icons.person,
                    nameController,
                    validator: (v) =>
                    v!.isEmpty ? "Name required" : null,
                  ),
                  field(
                    "Mobile",
                    Icons.phone,
                    mobileController,
                    keyboard: TextInputType.phone,
                    validator: (v) =>
                    v!.length < 10
                        ? "Enter valid mobile number"
                        : null,
                  ),
                  field(
                    "Email",
                    Icons.email,
                    emailController,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) =>
                    !v!.contains("@")
                        ? "Enter valid email"
                        : null,
                  ),
                  field(
                    "MRP",
                    Icons.currency_rupee,
                    mrpController,
                    keyboard: TextInputType.number,
                    validator: (v) =>
                    int.tryParse(v!) == null
                        ? "Enter valid MRP"
                        : null,
                  ),
                  field(
                    "Price",
                    Icons.sell,
                    priceController,
                    keyboard: TextInputType.number,
                    validator: (v) =>
                    int.tryParse(v!) == null
                        ? "Enter valid price"
                        : null,
                  ),
                  field(
                    "Quantity",
                    Icons.numbers,
                    quantityController,
                    keyboard: TextInputType.number,
                    validator: (v) =>
                    int.tryParse(v!) == null
                        ? "Enter valid quantity"
                        : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: postGets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B5BDB),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        "SAVE",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}