import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'editsec.dart';

class GetById extends StatefulWidget {
  final String role;
  final int userId;

  const GetById({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<GetById> createState() => _GetByIdState();
}

class _GetByIdState extends State<GetById> {
  late Future<List<dynamic>> futureProducts;
  int expandedIndex = -1;

////////////////////////////////////////////////////////////
  /// FETCH DATA (FIXED)
////////////////////////////////////////////////////////////

  Future<List<dynamic>> fetchOrders() async {
    try {
      String url;

      if (widget.role == "user") {
        url =
        "https://av.circuitpointes.com/oc-content/themes/sigma/ex_add/shop_cart/api.php?key=productcircuitpointesform321&type=product&user_id=${widget.userId}";
      } else {
        url =
        "https://av.circuitpointes.com/oc-content/themes/sigma/ex_add/shop_cart/api.php?key=productcircuitpointesform321&type=product";
      }

      debugPrint("👉 API: $url");

      final response = await http.get(Uri.parse(url));

      debugPrint("👉 STATUS: ${response.statusCode}");
      debugPrint("👉 BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        dynamic data = decoded["data"];

        if (data is Map && data.containsKey("data")) {
          data = data["data"];
        }

        if (data is List) return data;
        if (data is Map) return [data];

        return [];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      return [];
    }
  }

////////////////////////////////////////////////////////////
  /// CALL USER
////////////////////////////////////////////////////////////

  Future<void> callUser(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

////////////////////////////////////////////////////////////
  /// EMAIL USER
////////////////////////////////////////////////////////////

  Future<void> emailUser(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Product Enquiry',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

////////////////////////////////////////////////////////////
  /// DELETE PRODUCT (FIXED)
////////////////////////////////////////////////////////////

  Future<void> deleteProduct(int id) async {
    try {
      // 🔴 IMPORTANT → replace with your real backend
      String deleteUrl =
          "https://yourdomain.com/cart/delete/$id";

      final res = await http.delete(Uri.parse(deleteUrl));

      if (res.statusCode == 200 || res.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Deleted Successfully"),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          futureProducts = fetchOrders();
        });
      } else {
        debugPrint("❌ DELETE FAILED: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ DELETE ERROR: $e");
    }
  }

////////////////////////////////////////////////////////////
  /// CONFIRM DELETE
////////////////////////////////////////////////////////////

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await deleteProduct(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

////////////////////////////////////////////////////////////
  /// INIT
////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    futureProducts = fetchOrders();
  }

////////////////////////////////////////////////////////////
  /// UI
////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Cart Products"),
        centerTitle: true,
        backgroundColor: const Color(0xFF3B5BDB),
      ),

      body: FutureBuilder<List<dynamic>>(
        future: futureProducts,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Data Found"));
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: products.length,
            itemBuilder: (context, index) {

              final p = products[index];
              bool expanded = expandedIndex == index;

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                margin: const EdgeInsets.only(bottom: 16),

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

                        Row(
                          children: [

                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0xFF3B5BDB),
                              child: Icon(Icons.shopping_cart,
                                  color: Colors.white),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    p["name"] ?? "",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Text("Qty : ${p["quantity"] ?? ""}"),

                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text("💰 Price : ${p["price"] ?? ""}"),
                        Text("🧮 Total : ${p["total_price"] ?? ""}"),

                        if (expanded) ...[

                          const Divider(),

                          Text("📞 ${p["mobile"] ?? ""}"),
                          Text("📧 ${p["email"] ?? ""}"),
                          Text("🏷 MRP : ${p["mrp"] ?? ""}"),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [

                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                icon: const Icon(Icons.call),
                                label: const Text("Call"),
                                onPressed: () =>
                                    callUser(p["mobile"].toString()),
                              ),

                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                icon: const Icon(Icons.email),
                                label: const Text("Email"),
                                onPressed: () =>
                                    emailUser(p["email"].toString()),
                              ),

                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditPage(data: p),
                                    ),
                                  ).then((_) {
                                    setState(() {
                                      futureProducts = fetchOrders();
                                    });
                                  });
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  confirmDelete(p["id"]);
                                },
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}