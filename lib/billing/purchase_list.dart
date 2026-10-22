import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/billing/purchase_bill_entry.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'purchase_list_actions.dart';

class PurchaseListPage extends StatefulWidget {
  const PurchaseListPage({super.key});

  @override
  State<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends State<PurchaseListPage> {
  List<dynamic> _bills = [];
  List<dynamic> _filteredBills = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchCtrl = TextEditingController();
  int _showEntriesCount = 10;

  @override
  void initState() {
    super.initState();
    _fetchPurchaseBills();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBills = _bills;
      } else {
        _filteredBills = _bills.where((bill) {
          final invoiceNo = (bill['invoice_no'] ?? bill['bill_no'] ?? "").toString().toLowerCase();
          final supplierName = (bill['supplier_name'] ?? bill['supplier']?['supplier_name'] ?? "").toString().toLowerCase();
          final date = (bill['bill_date'] ?? bill['created_at'] ?? "").toString().toLowerCase();
          return invoiceNo.contains(query) || supplierName.contains(query) || date.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchPurchaseBills() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/purchase-bill/bills"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List list = [];
        if (decoded is Map) {
          if (decoded.containsKey('data')) {
            list = decoded['data'] is List ? decoded['data'] : [];
          } else if (decoded.containsKey('bills')) {
            list = decoded['bills'] is List ? decoded['bills'] : [];
          }
        } else if (decoded is List) {
          list = decoded;
        }

        setState(() {
          _bills = list;
          _filteredBills = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load bills. Status: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error("Fetch Bills Error", e);
      setState(() {
        _errorMessage = "Network connection error ❌";
        _isLoading = false;
      });
    }
  }

  String formatDateTime(String? rawStr) {
    if (rawStr == null || rawStr.isEmpty) return "-";
    try {
      final dt = DateTime.parse(rawStr).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;

      int hour = dt.hour;
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? "PM" : "AM";
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final hrStr = hour.toString().padLeft(2, '0');

      return "$day/$month/$year\n$hrStr:$min $ampm";
    } catch (_) {
      return rawStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayBills = _filteredBills.take(_showEntriesCount).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Purchase Bills",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchPurchaseBills,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF6366F1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Purchase List",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "View, print and manage all supplier purchase bill records",
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PurchaseBillEntryPage()),
                          );
                          if (res == true) {
                            _fetchPurchaseBills();
                          }
                        },
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text("Create Bill", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filters Container Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Text("Show", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _showEntriesCount,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                            items: [5, 10, 20, 50].map((int val) {
                              return DropdownMenuItem<int>(
                                value: val,
                                child: Text("$val"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _showEntriesCount = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text("entries", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: "Search...",
                              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cards Listing Card (ListView.builder)
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchPurchaseBills,
                            child: const Text("Retry"),
                          )
                        ],
                      ),
                    ),
                  )
                else if (displayBills.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Text("No records found.", style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayBills.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bill = displayBills[index];

                      final supplier = bill['supplier_name'] ?? bill['supplier']?['supplier_name'] ?? bill['company_name'] ?? "Mass";
                      final invoiceNo = bill['invoice_no'] ?? bill['bill_no'] ?? bill['purchase_bill_no'] ?? "-";
                      final amount = double.tryParse(bill['grand_total']?.toString() ?? bill['total_amount']?.toString() ?? "0.0") ?? 0.0;
                      final status = (bill['payment_status'] ?? bill['status'] ?? "Unpaid").toString();
                      final dateStr = formatDateTime(bill['bill_date'] ?? bill['created_at']).replaceAll('\n', ' ');

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Text(
                                    invoiceNo,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("SUPPLIER", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      supplier,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ],
                                ),
                                _buildStatusPill(status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("AMOUNT", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      "₹${amount.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _viewBillDetails(bill),
                                      icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                                      label: const Text("View", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue.shade600,
                                        side: BorderSide(color: Colors.blue.shade200),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _editBill(bill),
                                      icon: const Icon(Icons.edit_outlined, size: 14),
                                      label: const Text("Edit", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange.shade700,
                                        side: BorderSide(color: Colors.orange.shade200),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
