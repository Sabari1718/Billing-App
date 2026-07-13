import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

class BillListScreen extends StatefulWidget {
  final String token;
  const BillListScreen({super.key, required this.token});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  List bills = [];
  bool loading = true;
  String? errorMessage;
  String? localToken;
  String? businessId;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchBills();
  }

  String role = "propagater";

  Future<void> _loadTokenAndFetchBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      localToken = prefs.getString('token');
      role = prefs.getString("role")?.toLowerCase() ?? "propagater";
      
      // Fetch business_id
      final rawBizId = prefs.get("business_id");
      businessId = rawBizId?.toString();
      
      AppLogger.info("Tokens and role ($role) loaded for bill history");

      if (localToken == null || localToken!.isEmpty) {
        setState(() {
          errorMessage = "Authentication token not found.";
          loading = false;
        });
        return;
      }

      await fetchBills();
    } catch (e) {
      setState(() {
        errorMessage = "Error loading token: $e";
        loading = false;
      });
      AppLogger.error("Error loading token", e);
    }
  }

  Future<void> fetchBills() async {
    try {
      String url = "https://billing.srivagroups.in/api/sales/bills";
      
      // 🔥 Apply role-based filtering
      final prefs = await SharedPreferences.getInstance();
      if (role == "supplier" || role == "partner") {
        final userMainId = prefs.getString("user_main_id") ?? "";
        url += "?business_id=$businessId&user_main_id=$userMainId";
      } else if (role == "propagator" || role == "propagater" || role == "admin") {
        // Propagator sees all data, no filtering applied to URL
        AppLogger.info("Propagator role: Loading all records");
      } else if (businessId != null) {
        // Fallback for other roles (like 'business')
        url += "?business_id=$businessId";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $localToken",
        },
      );

      AppLogger.api("GET", url, response.statusCode);

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded["success"] == true) {
        // 🔥 if empty → fallback try without token
        if (decoded["data"] == null || decoded["data"].isEmpty) {
          AppLogger.warning("No bills found with token, retrying without auth");

          final fallbackRes = await http.get(
            Uri.parse("https://billing.srivagroups.in/api/sales/bills"),
            headers: {
              "Accept": "application/json",
            },
          );

          final fallbackDecoded = jsonDecode(fallbackRes.body);

          setState(() {
            bills = fallbackDecoded["data"] ?? [];
            loading = false;
          });

          return;
        }

        // ✅ normal case
        setState(() {
          bills = decoded["data"] ?? [];
          loading = false;
        });

      } else {
        setState(() {
          errorMessage = decoded["message"] ?? "Error loading bills";
          loading = false;
        });
      }

    } catch (e) {
      AppLogger.error("fetchBills error", e);
      setState(() {
        errorMessage = "Failed to load bills";
        loading = false;
      });
    }
  }

  Color getStatusColor(String? status) {
    if (status == "COMPLETED") return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill History"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
              : bills.isEmpty
                  ? const Center(
                      child: Text(
                        "No Bills Found",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final b = bills[index];
                        final rawDate = b['created_at']?.toString() ?? '';
                        final formattedDate = rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;
                        final status = b['payment_method']?.toString() ?? 'CASH';

                        return Card(
                          child: ListTile(
                            title: Text(b['bill_number']?.toString() ?? 'No Bill #'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("₹${b['final_amount']?.toString() ?? '0.00'}", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                Text(formattedDate),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: getStatusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Flexible(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BillDetailScreen(bill: b),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text("View", style: TextStyle(fontSize: 13)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}






class BillDetailScreen extends StatelessWidget {
  final Map bill;
  const BillDetailScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bill Detail")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Bill: ${bill['bill_no']}"),
                Text("₹${bill['total']}"),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Payment: ${bill['payment_method']}"),
                Text("Status: ${bill['status']}"),
              ],
            ),

            const Divider(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Items",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: bill['items']?.length ?? 0,
                itemBuilder: (context, i) {
                  final item = bill['items'][i];

                  return ListTile(
                    title: Text(item['product_name']),
                    subtitle: Text("Qty: ${item['qty']}"),
                    trailing: Text("₹${item['total']}"),
                  );
                },
              ),
            ),

            Text("Total: ₹${bill['total']}"),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AppLogger.info("Print bill triggered");
                    },
                    child: const Text("Print"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}


class Bill {
  final String billNo;
  final String date;
  final double total;
  final String payment;
  final String status;

  Bill({
    required this.billNo,
    required this.date,
    required this.total,
    required this.payment,
    required this.status,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      billNo: json['bill_no'] ?? '',
      date: json['date'] ?? '',
      total: double.parse(json['total'].toString()),
      payment: json['payment_method'] ?? '',
      status: json['status'] ?? '',
    );
  }
}