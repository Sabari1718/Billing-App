import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class EnquiryPage extends StatefulWidget {
  const EnquiryPage({super.key});

  @override
  State<EnquiryPage> createState() => _EnquiryPageState();
}

class _EnquiryPageState extends State<EnquiryPage> {

  final _formKey = GlobalKey<FormState>();

  final String apiUrl = "http://localhost:3002/enquiry/create";

  final name = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final company = TextEditingController();
  final link = TextEditingController();
  final subject = TextEditingController();
  final comments = TextEditingController();

  bool contactCallback = false;
  bool contactSms = false;
  bool contactWhatsapp = false;
  bool contactMail = false;

  String imagePath = "";
  String pdfPath = "";

  Future pickImage() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        imagePath = result.files.single.path!;
      });
    }
  }

  Future pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        pdfPath = result.files.single.path!;
      });
    }
  }

  Future<void> postEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      "name": name.text,
      "mobile": mobile.text,
      "email": email.text,
      "company": company.text,
      "link": link.text,
      "subject": subject.text,
      "comments": comments.text,
      "contact_callback": contactCallback,
      "contact_sms": contactSms,
      "contact_whatsapp": contactWhatsapp,
      "contact_mail": contactMail,
      "image_path": imagePath,
      "pdf_path": pdfPath
    };

    final res = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enquiry Saved"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget field(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: (v) => v!.isEmpty ? "Required" : null,
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

  Widget checkBox(String title, bool value, Function(bool?) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(title),
        value: value,
        // activeTrackColor: const Color(0xFF3B5BDB),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Create Enquiry"),
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

                  field("Name", Icons.person, name),
                  field("Mobile", Icons.phone, mobile),
                  field("Email", Icons.email, email),
                  field("Company", Icons.business, company),
                  field("Website Link", Icons.link, link),
                  field("Subject", Icons.subject, subject),
                  field("Comments", Icons.comment, comments),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Select Image"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5BDB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  if (imagePath.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(imagePath,
                          style: const TextStyle(fontSize: 12)),
                    ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: pickPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Select PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5BDB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  if (pdfPath.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(pdfPath,
                          style: const TextStyle(fontSize: 12)),
                    ),

                  const SizedBox(height: 20),

                  checkBox("Phone Call", contactCallback, (v) {
                    setState(() {
                      contactCallback = v!;
                    });
                  }),

                  checkBox("SMS", contactSms, (v) {
                    setState(() {
                      contactSms = v!;
                    });
                  }),

                  checkBox("WhatsApp", contactWhatsapp, (v) {
                    setState(() {
                      contactWhatsapp = v!;
                    });
                  }),

                  checkBox("Email", contactMail, (v) {
                    setState(() {
                      contactMail = v!;
                    });
                  }),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(

                      onPressed: postEnquiry,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B5BDB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),

                      child: const Text(
                        "SUBMIT ENQUIRY",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    ),
                  )

                ],

              ),

            ),

          ),

        ),

      ),

    );

  }

}