import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class EditEnquiryPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditEnquiryPage({super.key, required this.data});

  @override
  State<EditEnquiryPage> createState() => _EditEnquiryPageState();
}

class _EditEnquiryPageState extends State<EditEnquiryPage> {

  final _formKey = GlobalKey<FormState>();

  bool loading = false;

  late TextEditingController name;
  late TextEditingController mobile;
  late TextEditingController email;
  late TextEditingController company;
  late TextEditingController link;
  late TextEditingController subject;
  late TextEditingController comments;
  late TextEditingController imagePath;
  late TextEditingController pdfPath;

  bool callback = false;
  bool sms = false;
  bool whatsapp = false;
  bool mail = false;

////////////////////////////////////////////////////////////
  /// INIT
////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    name = TextEditingController(text: widget.data["name"] ?? "");
    mobile = TextEditingController(text: widget.data["mobile"] ?? "");
    email = TextEditingController(text: widget.data["email"] ?? "");
    company = TextEditingController(text: widget.data["company"] ?? "");
    link = TextEditingController(text: widget.data["link"] ?? "");
    subject = TextEditingController(text: widget.data["subject"] ?? "");
    comments = TextEditingController(text: widget.data["comments"] ?? "");

    imagePath = TextEditingController(text: widget.data["image_path"] ?? "");
    pdfPath = TextEditingController(text: widget.data["pdf_path"] ?? "");

    callback = widget.data["contact_callback"] == true;
    sms = widget.data["contact_sms"] == true;
    whatsapp = widget.data["contact_whatsapp"] == true;
    mail = widget.data["contact_mail"] == true;
  }

////////////////////////////////////////////////////////////
  /// DISPOSE
////////////////////////////////////////////////////////////

  @override
  void dispose() {
    name.dispose();
    mobile.dispose();
    email.dispose();
    company.dispose();
    link.dispose();
    subject.dispose();
    comments.dispose();
    imagePath.dispose();
    pdfPath.dispose();
    super.dispose();
  }

////////////////////////////////////////////////////////////
  /// UPDATE API
////////////////////////////////////////////////////////////

  Future<void> updateEnquiry() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    int id = widget.data["id"];

    final body = {

      "name": name.text,
      "mobile": mobile.text,
      "email": email.text,
      "company": company.text,
      "link": link.text,
      "subject": subject.text,
      "comments": comments.text,

      "contact_callback": callback,
      "contact_sms": sms,
      "contact_whatsapp": whatsapp,
      "contact_mail": mail,

      "image_path": imagePath.text,
      "pdf_path": pdfPath.text.isEmpty ? null : pdfPath.text
    };

    final url = "http://localhost:3002/enquiry/update/$id";

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

    setState(() {
      loading = false;
    });
  }

////////////////////////////////////////////////////////////
  /// UI
////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xfff3f4f6),

      appBar: AppBar(

        title: const Text("Edit Enquiry"),

        elevation: 0,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3B5BDB),
                Color(0xFF5C7CFA),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            Card(

              elevation: 4,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),

              child: Padding(

                padding: const EdgeInsets.all(20),

                child: Form(

                  key: _formKey,

                  child: Column(

                    children: [

                      field("Name", name, Icons.person),
                      field("Mobile", mobile, Icons.phone),
                      field("Email", email, Icons.email),
                      field("Company", company, Icons.business),
                      field("Website", link, Icons.link),
                      field("Subject", subject, Icons.subject),
                      field("Comments", comments, Icons.comment),
                      field("Image Path", imagePath, Icons.image),
                      field("PDF Path", pdfPath, Icons.picture_as_pdf),

                      const SizedBox(height: 10),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Contact Preference",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Card(

                        elevation: 2,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Column(

                          children: [

                            option("Callback", callback, (v) {
                              setState(() => callback = v);
                            }),

                            option("SMS", sms, (v) {
                              setState(() => sms = v);
                            }),

                            option("WhatsApp", whatsapp, (v) {
                              setState(() => whatsapp = v);
                            }),

                            option("Mail", mail, (v) {
                              setState(() => mail = v);
                            }),

                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(

                        width: double.infinity,
                        height: 52,

                        child: ElevatedButton(

                          style: ElevatedButton.styleFrom(

                            backgroundColor: const Color(0xFF3B5BDB),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),

                          ),

                          onPressed: loading ? null : updateEnquiry,

                          child: loading
                              ? const CircularProgressIndicator(
                              color: Colors.white)
                              : const Text(
                            "UPDATE ENQUIRY",
                            style: TextStyle(
                              fontSize: 16,
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
          ],
        ),
      ),
    );
  }

////////////////////////////////////////////////////////////
  /// TEXT FIELD
////////////////////////////////////////////////////////////

  Widget field(String label, TextEditingController controller, IconData icon) {

    return Container(

      margin: const EdgeInsets.only(bottom: 18),

      decoration: BoxDecoration(

        boxShadow: [

          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0,4),
          )

        ],
      ),

      child: TextFormField(

        controller: controller,

        validator: (v) =>
        v == null || v.isEmpty ? "Please enter $label" : null,

        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),

        decoration: InputDecoration(

          labelText: label,

          prefixIcon: Icon(
            icon,
            color: const Color(0xFF3B5BDB),
          ),

          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.2,
            ),
          ),

          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(
              color: Color(0xFF3B5BDB),
              width: 2,
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

    return SwitchListTile(

      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),

      value: value,

      activeTrackColor: const Color(0xFF3B5BDB),

      onChanged: onChanged,
    );
  }
}