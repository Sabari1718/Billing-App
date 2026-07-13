import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'editbulk.dart';

class GetEnquiry extends StatefulWidget {
  final String role;
  final int userId;

  const GetEnquiry({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<GetEnquiry> createState() => _GetEnquiryState();
}

class _GetEnquiryState extends State<GetEnquiry> {

  List<dynamic> enquiries = [];
  List<dynamic> filteredEnquiries = [];

  String role = "";
  int userId = 0;

  int expandedIndex = -1;

  TextEditingController searchController = TextEditingController();

  bool isLoading = true;

////////////////////////////////////////////////
  /// LOAD USER
////////////////////////////////////////////////

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString("role") ?? widget.role;
    userId = prefs.getInt("userId") ?? widget.userId;
  }

////////////////////////////////////////////////
  /// FETCH ENQUIRIES (FIXED)
////////////////////////////////////////////////

  Future<void> fetchOrders() async {
    try {
      setState(() => isLoading = true);

      String url;

      if (role == "user") {
        url =
        "https://av.circuitpointes.com/oc-content/themes/sigma/ex_add/shop_cart/api.php?key=productcircuitpointesform321&type=enquiries&user_id=$userId";
      } else {
        url =
        "https://av.circuitpointes.com/oc-content/themes/sigma/ex_add/shop_cart/api.php?key=productcircuitpointesform321&type=enquiries";
      }

      AppLogger.info("Fetching enquiries from external API");

      final response = await http.get(Uri.parse(url));

      AppLogger.api("GET", url, response.statusCode);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        dynamic data = decoded["data"];

        if (data is Map && data.containsKey("data")) {
          data = data["data"];
        }

        if (data is List) {
          enquiries = data;
        } else if (data is Map) {
          enquiries = [data];
        } else {
          enquiries = [];
        }

        filteredEnquiries = List.from(enquiries);
      } else {
        AppLogger.api("GET", url, response.statusCode, isError: true);
      }
    } catch (e) {
      AppLogger.error("fetchOrders error", e);
    } finally {
      setState(() => isLoading = false);
    }
  }

////////////////////////////////////////////////
  /// SEARCH (FIXED)
////////////////////////////////////////////////

  void searchOrders(String value) {
    value = value.toLowerCase();

    setState(() {
      filteredEnquiries = enquiries.where((o) {
        return (o["name"] ?? "")
            .toString()
            .toLowerCase()
            .contains(value) ||

            (o["company_name"] ?? o["company"] ?? "")
                .toString()
                .toLowerCase()
                .contains(value) ||

            (o["subject"] ?? "")
                .toString()
                .toLowerCase()
                .contains(value);
      }).toList();
    });
  }

////////////////////////////////////////////////
  /// CALL
////////////////////////////////////////////////

  Future<void> call(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

////////////////////////////////////////////////
  /// EMAIL
////////////////////////////////////////////////

  Future<void> email(String mail) async {
    final uri = Uri.parse("mailto:$mail");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

////////////////////////////////////////////////
  /// DELETE (⚠️ UPDATE THIS URL TO YOUR SERVER)
////////////////////////////////////////////////

  Future<void> deleteEnquiry(int id) async {

    // ❗ CHANGE THIS TO YOUR LIVE SERVER (NOT localhost)
    String url = "https://yourdomain.com/enquiry/delete/$id";

    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Deleted Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      fetchOrders();
    } else {
      AppLogger.api("DELETE", url, response.statusCode, isError: true);
    }
  }

////////////////////////////////////////////////
  /// CONFIRM DELETE
////////////////////////////////////////////////

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Delete this enquiry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await deleteEnquiry(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

////////////////////////////////////////////////
  /// INIT
////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await loadUser();
    await fetchOrders();
  }

////////////////////////////////////////////////
  /// UI
////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Enquiries"),
        centerTitle: true,
        backgroundColor: const Color(0xFF3B5BDB),
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: searchController,
              onChanged: searchOrders,
              decoration: InputDecoration(
                hintText: "Search enquiries...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEnquiries.isEmpty
                ? const Center(child: Text("No Enquiries Found"))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: filteredEnquiries.length,
              itemBuilder: (context, index) {

                final o = filteredEnquiries[index];
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
                                child: Icon(Icons.person, color: Colors.white),
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      o["company_name"] ??
                                          o["company"] ??
                                          "",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text("📌 ${o["subject"] ?? ""}"),
                          Text("📞 ${o["mobile"] ?? ""}"),

                          if (expanded) ...[
                            const Divider(height: 20),

                            Text("✉ ${o["email"] ?? ""}"),

                            const SizedBox(height: 10),

                            Text(o["comments"] ?? ""),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.end,
                              children: [

                                IconButton(
                                  icon: const Icon(Icons.phone,
                                      color: Colors.green),
                                  onPressed: () =>
                                      call(o["mobile"]),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.email,
                                      color: Colors.orange),
                                  onPressed: () =>
                                      email(o["email"]),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditBULK(data: o),
                                      ),
                                    ).then((updated) {
                                      if (updated == true) {
                                        fetchOrders();
                                      }
                                    });
                                  },
                                ),

                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    confirmDelete(o["id"]);
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
            ),
          )
        ],
      ),
    );
  }
}