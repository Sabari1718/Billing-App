import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'add suppier.dart';
import 'edit_supplier.dart';



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
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final url = "https://billing.srivagroups.in/api/suppliers/";
    AppLogger.info("Fetching suppliers");

    final headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };

    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      AppLogger.api("GET", url, res.statusCode);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        setState(() {
          if (decoded != null) {
            final supplierData = decoded['data']?['data']?['data'];
            if (supplierData is List) {
              List rawList = supplierData;

              // 🔥 FRONTEND FILTERING BASED ON ROLE
              if (role != "propagater" && userName.isNotEmpty) {
                suppliers = rawList.where((s) {
                  final sName = s['supplier_name']?.toString().toLowerCase() ?? "";
                  final cName = s['company_name']?.toString().toLowerCase() ?? "";
                  final uName = userName.toLowerCase();
                  return sName.contains(uName) || cName.contains(uName);
                }).toList();
              } else {
                suppliers = rawList;
              }
            } else {
              suppliers = [];
            }
          } else {
            suppliers = [];
          }
          filteredSuppliers = List.from(suppliers);
          isLoading = false;
        });
      } else {
        AppLogger.api("GET", url, res.statusCode, isError: true);
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load suppliers (${res.statusCode})";
        });
      }
    } catch (e) {
      AppLogger.error("fetchSuppliers error", e);
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
      fetchSuppliers(); // refresh
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Suppliers"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddSupplierScreen()),
                ).then((_) => fetchSuppliers()); // Refresh after returning
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Add"),
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔍 SEARCH UI
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: filterSuppliers,
              decoration: InputDecoration(
                hintText: "Search by name, company or phone...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    searchController.clear();
                    filterSuppliers("");
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
              ),
            ),
          ),

          // 📄 LIST UI
          Expanded(
            child: filteredSuppliers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: filteredSuppliers.length,
              itemBuilder: (context, index) {
                final s = filteredSuppliers[index];
                final name = (s['supplier_name']?.toString() ?? "").trim();
                final displayName = name.isEmpty ? "No Name" : name;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // 🔵 ICON
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.deepPurple.shade50,
                        child: Text(
                          getInitials(displayName),
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 📄 DETAILS
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                            ),
                            if ((s['company_name']?.toString() ?? "").isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                s['company_name'].toString(),
                                style: TextStyle(color: Colors.deepPurple.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                            if ((s['city']?.toString() ?? "").isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                s['city'].toString(),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                            if ((s['primary_phone']?.toString() ?? "").isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                s['primary_phone'].toString(),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // 🟢 GST
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (s['gst_number'] != null && s['gst_number'].toString().trim().isNotEmpty)
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (s['gst_number'] != null && s['gst_number'].toString().trim().isNotEmpty)
                              ? "With GST"
                              : "No GST",
                          style: TextStyle(
                            color: (s['gst_number'] != null && s['gst_number'].toString().trim().isNotEmpty)
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ✏️ EDIT
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditSupplierScreen(supplier: s),
                            ),
                          ).then((_) => fetchSuppliers());
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.edit_outlined, color: Colors.blue.shade600, size: 22),
                        ),
                      ),

                      // 👁 VIEW
                      InkWell(
                        onTap: () {
                          // View implementation
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.remove_red_eye, color: Colors.blue.shade600, size: 22),
                        ),
                      ),

                      // 🗑 DELETE
                      InkWell(
                        onTap: () {
                          if (s['id'] != null) {
                            deleteSupplier(s['id'].toString());
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 22),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}