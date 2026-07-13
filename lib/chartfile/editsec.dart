import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class EditPage extends StatefulWidget {
  final Map data;

  const EditPage({super.key, required this.data});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {

  final _formKey = GlobalKey<FormState>();

  bool loading = false;

  late TextEditingController name;
  late TextEditingController mobile;
  late TextEditingController email;
  late TextEditingController price;
  late TextEditingController quantity;

////////////////////////////////////////////////////////////
  /// INIT
////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    name = TextEditingController(text: widget.data["name"] ?? "");
    mobile = TextEditingController(text: widget.data["mobile"] ?? "");
    email = TextEditingController(text: widget.data["email"] ?? "");

    price = TextEditingController(
        text: widget.data["price"]?.toString() ?? "0");

    quantity = TextEditingController(
        text: widget.data["quantity"]?.toString() ?? "1");
  }

////////////////////////////////////////////////////////////
  /// DISPOSE
////////////////////////////////////////////////////////////

  @override
  void dispose() {
    name.dispose();
    mobile.dispose();
    email.dispose();
    price.dispose();
    quantity.dispose();
    super.dispose();
  }

////////////////////////////////////////////////////////////
  /// UPDATE API
////////////////////////////////////////////////////////////

  Future<void> updateData() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    int id = widget.data["id"];

    double priceValue = double.tryParse(price.text) ?? 0;
    int qty = int.tryParse(quantity.text) ?? 0;

    double total = priceValue * qty;

    final body = {

      "name": name.text,
      "mobile": mobile.text,
      "email": email.text,

      "mrp": priceValue,
      "price": priceValue,
      "quantity": qty,

      "total_price": total
    };

    final url = "http://localhost:3002/cart/update/$id";

    try {

      final res = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Updated Successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update Failed : ${res.body}")),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error : $e")),
      );
    }

    setState(() => loading = false);
  }

////////////////////////////////////////////////////////////
  /// UI
////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Edit Product"),
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
                    name,
                    validator: (v) =>
                    v!.isEmpty ? "Name required" : null,
                  ),

                  field(
                    "Mobile",
                    Icons.phone,
                    mobile,
                    keyboard: TextInputType.phone,
                    validator: (v) =>
                    v!.length < 10
                        ? "Enter valid mobile number"
                        : null,
                  ),

                  field(
                    "Email",
                    Icons.email,
                    email,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) =>
                    !v!.contains("@")
                        ? "Enter valid email"
                        : null,
                  ),

                  field(
                    "Price",
                    Icons.sell,
                    price,
                    keyboard: TextInputType.number,
                    validator: (v) =>
                    double.tryParse(v!) == null
                        ? "Enter valid price"
                        : null,
                  ),

                  field(
                    "Quantity",
                    Icons.numbers,
                    quantity,
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

                      onPressed: loading ? null : updateData,

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF3B5BDB),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),

                      child: loading
                          ? const CircularProgressIndicator(
                          color: Colors.white)
                          : const Text(
                        "UPDATE",
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

////////////////////////////////////////////////////////////
  /// FIELD WIDGET
////////////////////////////////////////////////////////////

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

          prefixIcon:
          Icon(icon, color: const Color(0xFF3B5BDB)),

          labelText: label,

          filled: true,
          fillColor: const Color(0xFFF1F4FF),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFE0E6FF)),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFF3B5BDB),
                width: 1.5),
          ),
        ),
      ),
    );
  }
}