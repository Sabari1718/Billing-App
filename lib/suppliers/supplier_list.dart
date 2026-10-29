import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'add suppier.dart';
import 'edit_supplier.dart';
import 'package:billingapp/billing/billing_mode_selector.dart';



class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key});

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  List suppliers = [];
  List filteredSuppliers = [];
  bool isLoading = true;
  String token = "";
  String errorMessage = "";
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String role = "business";
  String userName = "";

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("auth_token") ?? "";
    role = prefs.getString("role")?.toLowerCase() ?? "propagater";
    userName = prefs.getString("user_name") ?? "";

    if (prefs.getString("role") == null) {
      final userJson = prefs.getString("user");
      if (userJson != null) {
        try {
          final Map<String, dynamic> user = json.decode(userJson);
          String rawRole = user['role']?.toString().toLowerCase() ?? "business";
          role = (rawRole == "business") ? "propagater" : rawRole;
          userName = user['name']?.toString() ?? "";
        } catch (e) {
          debugPrint("Error parsing user json: $e");
        }
      }
    }

    fetchSuppliers();
  }

  // 🔥 FETCH SUPPLIERS
  Future<void> fetchSuppliers() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    const rawUrl = "https://demotesting.jobes24x7.com/api/billingapi/raw?limit=1000";
    const billingUrl = "https://billing.srivagroups.in/api/suppliers/";
    AppLogger.info("Fetching suppliers from live API: " + rawUrl);

    final headers = {
      if (token.isNotEmpty) "Authorization": "Bearer " + token,
      "Accept": "application/json",
    };

    try {
      http.Response? res;
      try {
        res = await http.get(Uri.parse(rawUrl), headers: {"Accept": "application/json"}).timeout(const Duration(seconds: 10));
      } catch (e) {
        AppLogger.error("Raw suppliers API failed, trying billing fallback", e);
      }

      if (res == null || res.statusCode != 200) {
        res = await http.get(Uri.parse(billingUrl), headers: headers).timeout(const Duration(seconds: 10));
      }

      AppLogger.api("GET", res.request?.url.toString() ?? rawUrl, res.statusCode);

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (!mounted) return;
        setState(() {
          List rawList = [];
          if (decoded != null) {
            if (decoded is List) {
              rawList = decoded;
            } else if (decoded is Map) {
              final d1 = decoded['data'];
              if (d1 is List) {
                rawList = d1;
              } else if (d1 is Map) {
                final d2 = d1['data'];
                if (d2 is List) {
                  rawList = d2;
                } else if (d2 is Map) {
                  final d3 = d2['data'];
                  if (d3 is List) {
                    rawList = d3;
                  }
                }
              }
            }
          }

          suppliers = rawList;
          filteredSuppliers = List.from(suppliers);
          isLoading = false;
        });
      } else {
        AppLogger.api("GET", billingUrl, res?.statusCode ?? 500, isError: true);
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load suppliers (${res?.statusCode ?? 500})";
        });
      }
    } catch (e) {
      AppLogger.error("fetchSuppliers error", e);
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "An error occurred while fetching data.";
      });
    }
  }

  // 🔥 DELETE SUPPLIER
  Future<void> deleteSupplier(String id) async {
    final url = "https://billing.srivagroups.in/api/suppliers/delete/$id";

    try {
      final res = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      AppLogger.api("DELETE", url, res.statusCode);
      if (mounted) {
        fetchSuppliers(); // refresh
      }
    } catch (e) {
      AppLogger.error("deleteSupplier error", e);
    }
  }

  void filterSuppliers(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        filteredSuppliers = List.from(suppliers);
      });
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      filteredSuppliers = suppliers.where((s) {
        final name = (s['supplier_name']?.toString() ?? "").toLowerCase();
        final company = (s['company_name']?.toString() ?? "").toLowerCase();
        final phone = (s['primary_phone']?.toString() ?? "").toLowerCase();
        final city = (s['city']?.toString() ?? "").toLowerCase();
        return name.contains(q) || company.contains(q) || phone.contains(q) || city.contains(q);
      }).toList();
    });
  }

  String getInitials(String name) {
    if (name.trim().isEmpty) return "NA";

    List<String> parts = name.trim().split(" ");

    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              errorMessage.isNotEmpty ? Icons.error_outline : Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage.isNotEmpty
                ? "Error Loading Data"
                : (searchController.text.isNotEmpty ? "No matching suppliers" : "No suppliers available"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage.isNotEmpty
                ? errorMessage
                : (searchController.text.isNotEmpty ? "Try a different search term" : "Add a new supplier to get started"),
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchSuppliers,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              side: const BorderSide(color: Colors.deepPurple),
              elevation: 0,
            ),
          )
        ],
      ),
    );
  }

  int showEntries = 10;
  int currentPage = 1;

  void _showViewSupplierModal(Map<String, dynamic> s) {
    final name = (s['supplier_name'] ?? "Supplier").toString();
    final company = (s['company_name'] ?? "-").toString();
    final gst = (s['gst_number'] ?? "-").toString();
    final pan = (s['pan_number'] ?? "-").toString();
    final phone = (s['primary_phone'] ?? "-").toString();
    final email = (s['email'] ?? "-").toString();
    final city = (s['city'] ?? "-").toString();
    final state = (s['state'] ?? "-").toString();
    final address = [
      s['building_name'],
      s['street'],
      s['landmark'],
      s['city'],
      s['state'],
      s['pincode']
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(", ");
    final branches = s['branches'] as List? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                getInitials(name),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                              Text(company, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildModalDetailRow("GST Number", gst),
                  _buildModalDetailRow("PAN Number", pan),
                  _buildModalDetailRow("Phone", phone),
                  _buildModalDetailRow("Email", email),
                  _buildModalDetailRow("City / State", "$city, $state"),
                  _buildModalDetailRow("Address", address.isEmpty ? "-" : address),
                  if (branches.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("Branches", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    ...branches.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text("• ${(b['branch_name'] ?? 'Branch')}: ${(b['branch_phone'] ?? '-')}", style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        )),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Close"),
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

  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Delete Supplier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to delete supplier '$name'?", style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteSupplier(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = filteredSuppliers.take(showEntries).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Suppliers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          const BillingModeSelector(currentMode: "Sale"),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddSupplierScreen()),
              ).then((_) => fetchSuppliers());
            },
            icon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF4F46E5)),
            tooltip: "Add New Supplier",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title & Subtitle + Add Button Row (Photo 1)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Suppliers",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Manage and view all your registered suppliers",
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddSupplierScreen()),
                          ).then((_) => fetchSuppliers());
                        },
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text("+ Add New Supplier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Main White Container Card with Table (Photo 1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search & Show entries header bar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              SizedBox(
                                width: 280,
                                height: 40,
                                child: TextField(
                                  controller: searchController,
                                  onChanged: filterSuppliers,
                                  decoration: InputDecoration(
                                    hintText: "Search by name, company or phone...",
                                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                                    suffixIcon: searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                            onPressed: () {
                                              searchController.clear();
                                              filterSuppliers("");
                                            },
                                          )
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    fillColor: const Color(0xFFF8FAFC),
                                    filled: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("SHOW ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: showEntries,
                                        items: [10, 25, 50, 100].map((int val) {
                                          return DropdownMenuItem<int>(
                                            value: val,
                                            child: Text("$val", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => showEntries = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        if (filteredSuppliers.isEmpty)
                          _buildEmptyState()
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 800),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                columnSpacing: 24,
                                horizontalMargin: 16,
                                columns: const [
                                  DataColumn(label: Text("S.NO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  DataColumn(label: Text("SUPPLIER NAME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  DataColumn(label: Text("BRANCH", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  DataColumn(label: Text("PHONE NUMBER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  DataColumn(label: Text("STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  DataColumn(label: Text("ACTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                ],
                                rows: List.generate(displayedList.length, (index) {
                                  final s = displayedList[index];
                                  final name = (s['supplier_name'] ?? s['name'] ?? "").toString().trim();
                                  final displayName = name.isEmpty ? "No Name" : name;
                                  final company = (s['business_name'] ?? s['company_name'] ?? displayName).toString().trim();
                                  final displayCompany = company.isEmpty ? displayName : company;
                                  final city = (s['city'] ?? s['district'] ?? s['branch'] ?? "").toString().trim();
                                  final branchName = city.isNotEmpty ? city : "Coimbatore";
                                  final phone = (s['phone'] ?? s['primary_phone'] ?? s['mobile'] ?? "-").toString().trim();
                                  final hasGst = (s['is_gst_registered'] == 1 || s['is_gst_registered'] == "1" || (s['gst_number'] != null && s['gst_number'].toString().trim().isNotEmpty));

                                  return DataRow(
                                    cells: [
                                      DataCell(Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6366F1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  getInitials(displayName),
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  displayName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  displayCompany,
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(branchName, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: hasGst ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            hasGst ? "With GST" : "Without GST",
                                            style: TextStyle(
                                              color: hasGst ? const Color(0xFF166534) : const Color(0xFF92400E),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => _showViewSupplierModal(s),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF3B82F6)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => EditSupplierScreen(supplier: s),
                                                  ),
                                                ).then((_) => fetchSuppliers());
                                              },
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFFD97706)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () {
                                                if (s['id'] != null) {
                                                  _confirmDelete(s['id'].toString(), displayName);
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEE2E2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF4444)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}