import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';


class GetBulk extends StatefulWidget {
  const GetBulk({super.key});

  @override
  State<GetBulk> createState() => _GetBulkState();
}

class _GetBulkState extends State<GetBulk> {
  List<dynamic> orders = [];
  int expandedIndex = -1;
  bool isLoading = true;

  Future<void> fetchOrders() async {
    try {
      String url =
          "https://av.circuitpointes.com/oc-content/themes/sigma/ex_add/shop_cart/api.php?key=productcircuitpointesform321&type=bulk_orders";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["data"] != null) {
          setState(() {
            orders = decoded["data"];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> launchCall(String phone) async {
    await launchUrl(Uri.parse("tel:$phone"));
  }

  Future<void> launchSMS(String phone) async {
    await launchUrl(Uri.parse("sms:$phone"));
  }

  Future<void> launchEmail(String email) async {
    await launchUrl(Uri.parse("mailto:$email"));
  }

  Future<void> launchWhatsApp(String phone) async {
    await launchUrl(Uri.parse("https://wa.me/$phone"));
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Bulk Orders"),
        centerTitle: true,
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final o = orders[index];
          bool expanded = expandedIndex == index;

          String phone = o["mobile"] ?? "";
          String email = o["email"] ?? "";

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  expandedIndex =
                  expandedIndex == index ? -1 : index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                          const Color(0xFF3B5BDB),
                          child: Text(
                            (o["name"] ?? "U")
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                o["name"] ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              Text(
                                o["company_name"] ?? "",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        )
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// PRODUCT
                    Row(
                      children: [
                        const Icon(Icons.inventory,
                            size: 18,
                            color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            o["product_name"] ?? "",
                            style: const TextStyle(
                                fontWeight:
                                FontWeight.w500),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    /// PHONE
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            size: 18,
                            color: Colors.green),
                        const SizedBox(width: 6),
                        Text(phone),
                      ],
                    ),

                    if (expanded) ...[
                      const Divider(height: 20),

                      Text("Quantity: ${o["quantity"]}"),
                      Text(
                          "Delivery: ${o["preferred_delivery_date"]}"),
                      Text("Email: $email"),

                      const SizedBox(height: 14),

                      /// ACTION BUTTONS (PRO)
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          _actionBtn(Icons.call, Colors.green,
                                  () => launchCall(phone)),
                          _actionBtn(Icons.sms, Colors.orange,
                                  () => launchSMS(phone)),
                          _actionBtn(Icons.chat,
                              Colors.teal,
                                  () => launchWhatsApp(phone)),
                          _actionBtn(Icons.email,
                              Colors.red,
                                  () => launchEmail(email)),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

////////////////////////////////////////////////
  /// BUTTON UI
////////////////////////////////////////////////

  Widget _actionBtn(
      IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}