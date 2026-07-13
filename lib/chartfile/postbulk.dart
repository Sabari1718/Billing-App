import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BulkOrderPage extends StatefulWidget {
  const BulkOrderPage({super.key});

  @override
  State<BulkOrderPage> createState() => _BulkOrderPageState();
}

class _BulkOrderPageState extends State<BulkOrderPage>
    with SingleTickerProviderStateMixin {

  final String apiUrl = "http://localhost:3002/bulk_order/create";

  final name = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final company = TextEditingController();
  final link = TextEditingController();
  final product = TextEditingController();
  final quantity = TextEditingController();
  final instructions = TextEditingController();
  final file = TextEditingController();

  bool callback = true;
  bool sms = true;
  bool whatsapp = false;
  bool mail = true;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

////////////////////////////////////////////////////////////
  /// INIT
////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, .1),
      end: Offset.zero,
    ).animate(_fade);

    _controller.forward();
  }

////////////////////////////////////////////////////////////
  /// POST BULK ORDER
////////////////////////////////////////////////////////////

  Future<void> postBulkOrder() async {

    try {

      final body = {

        "name": name.text.trim(),
        "mobile": mobile.text.trim(),
        "email": email.text.trim(),
        "company": company.text.trim(),
        "link": link.text.trim(),
        "product": product.text.trim(),

        "quantity": int.tryParse(quantity.text) ?? 0,

        "special_instructions": instructions.text.trim(),

        /// BOOL → INT FIX
        "contact_sms": sms ? 1 : 0,
        "contact_whatsapp": whatsapp ? 1 : 0,
        "contact_mail": mail ? 1 : 0,

        "bulk_order_pdf": file.text.trim()

      };

      debugPrint("SENDING DATA => $body");

      final response = await http.post(

        Uri.parse(apiUrl),

        headers: {"Content-Type": "application/json"},

        body: jsonEncode(body),

      );

      debugPrint("STATUS CODE => ${response.statusCode}");
      debugPrint("RESPONSE => ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bulk Order Created Successfully"),
          ),
        );

        clearForm();

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${response.body}"),
          ),
        );

      }

    } catch (e) {

      debugPrint("ERROR => $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

    }
  }

////////////////////////////////////////////////////////////
  /// CLEAR FORM
////////////////////////////////////////////////////////////

  void clearForm() {

    name.clear();
    mobile.clear();
    email.clear();
    company.clear();
    link.clear();
    product.clear();
    quantity.clear();
    instructions.clear();
    file.clear();

  }

////////////////////////////////////////////////////////////
  /// UI
////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF3FF),
              Color(0xFFF8FAFF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),

        child: SafeArea(

          child: FadeTransition(

            opacity: _fade,

            child: SlideTransition(

              position: _slide,

              child: SingleChildScrollView(

                padding: const EdgeInsets.all(18),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Bulk Order",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Create a new bulk order request",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 24),

////////////////////////////////////////////////////////////
                    /// FORM
////////////////////////////////////////////////////////////

                    Container(

                      padding: const EdgeInsets.all(22),

                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFDFF),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A3B5BDB),
                            blurRadius: 30,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [

                          field("Name", Icons.person, name),
                          field("Mobile", Icons.phone, mobile,
                              keyboard: TextInputType.phone),
                          field("Email", Icons.email, email,
                              keyboard: TextInputType.emailAddress),
                          field("Company", Icons.business, company),
                          field("Website", Icons.link, link),
                          field("Product", Icons.inventory, product),
                          field("Quantity", Icons.numbers, quantity,
                              keyboard: TextInputType.number),
                          field("Instructions", Icons.notes, instructions),
                          field("Reference File", Icons.attach_file, file),

                          const SizedBox(height: 18),

////////////////////////////////////////////////////////////
                          /// OPTIONS
////////////////////////////////////////////////////////////

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              option("SMS", sms, (v) => sms = v),
                              option("WhatsApp", whatsapp, (v) => whatsapp = v),
                            ],
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              option("Mail", mail, (v) => mail = v),
                            ],
                          ),

                          const SizedBox(height: 28),

////////////////////////////////////////////////////////////
                          /// SUBMIT BUTTON
////////////////////////////////////////////////////////////

                          SizedBox(
                            width: double.infinity,
                            height: 54,

                            child: ElevatedButton(

                              onPressed: () async {
                                await postBulkOrder();
                              },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B5BDB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 6,
                              ),

                              child: const Text(
                                "Save Order",
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

////////////////////////////////////////////////////////////
  /// TEXT FIELD
////////////////////////////////////////////////////////////

  Widget field(String label, IconData icon, TextEditingController c,
      {TextInputType keyboard = TextInputType.text}) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),

      child: TextField(

        controller: c,
        keyboardType: keyboard,

        decoration: InputDecoration(

          prefixIcon: Icon(icon, color: const Color(0xFF3B5BDB)),
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),

          filled: true,
          fillColor: const Color(0xFFF1F4FF),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E6FF)),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF3B5BDB),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

////////////////////////////////////////////////////////////
  /// SWITCH OPTION
////////////////////////////////////////////////////////////

  Widget option(String label, bool value, Function(bool) onChanged) {

    return Row(
      children: [

        Switch(
          value: value,
          activeTrackColor: const Color(0xFF3B5BDB),
          onChanged: (v) => setState(() => onChanged(v)),
        ),

        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}