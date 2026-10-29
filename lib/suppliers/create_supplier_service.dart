import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'list_service_management.dart';
import 'package:billingapp/billing/billing_mode_selector.dart';
import 'supplier_db_seed.dart';

class CreateSupplierServicePage extends StatefulWidget {
  final String token;
  const CreateSupplierServicePage({super.key, required this.token});

  @override
  State<CreateSupplierServicePage> createState() => _CreateSupplierServicePageState();
}

class _CreateSupplierServicePageState extends State<CreateSupplierServicePage> {
  List suppliersList = List.from(kLiveRawSuppliersData);
  bool isSuppliersLoading = true;
  Map<String, dynamic>? selectedSupplier;
  String? selectedSupplierId;
  bool isSupplierDetailsLoading = false;
  bool isSaving = false;

  final TextEditingController supplierNameController = TextEditingController();
  final TextEditingController contactDetailsController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController serviceCodeController = TextEditingController();
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String selectedServiceType = "One-Time Repair";
  String selectedStatus = "Active";
  String filterStatusTab = "All"; // All, Active, Inactive
  int showEntries = 10;
  String? editingServiceId;

  List<Map<String, dynamic>> supplierCategoryRecords = List<Map<String, dynamic>>.from(kLiveSupplierCategoryData);
  List<Map<String, dynamic>> supplierProductRecords = List<Map<String, dynamic>>.from(kLiveSupplierProductData);

  List<Map<String, dynamic>> registeredServices = [
    {
      "id": "10",
      "service_code": "SRV-8874",
      "service_name": "AK",
      "supplier": "YUDESH (ABD)",
      "type": "One-Time Repair",
      "status": "Active",
      "contact": "9876543210 / yudeshprasath@gmail.com",
      "location": "12, 2W, SD, CCC, 1QW, 1234567",
      "description": "Standard chip level diagnostic & repair",
    }
  ];

  @override
  void initState() {
    super.initState();
    _autoGenerateCode();
    _fetchInitialData();
  }

  @override
  void dispose() {
    supplierNameController.dispose();
    contactDetailsController.dispose();
    locationController.dispose();
    serviceCodeController.dispose();
    serviceNameController.dispose();
    descriptionController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _autoGenerateCode() {
    final rand = Random().nextInt(9000) + 1000;
    serviceCodeController.text = "SRV-$rand";
  }

  Future<String> _getEffectiveToken() async {
    if (widget.token.isNotEmpty) return widget.token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("billing_auth_token") ?? prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
  }

  Future<Map<String, String>> _getEffectiveHeaders({bool jsonBody = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _getEffectiveToken();
    final platformId = prefs.getString("selected_platform_id") ??
        prefs.getString("platform_id") ??
        prefs.getString("platformId") ??
        "1";
    final businessId = prefs.getString("selected_business_id") ??
        prefs.getString("business_id") ??
        prefs.getString("businessId") ??
        prefs.get("business_id")?.toString() ??
        "52";
    final storeId = prefs.getString("selected_store_id") ??
        prefs.getString("store_id") ??
        prefs.getString("storeId") ??
        "38";

    final headers = <String, String>{
      "Accept": "application/json",
      if (jsonBody) "Content-Type": "application/json",
      "X-App-ID": "Product94674",
      "x-platform-id": platformId,
      "platform-id": platformId,
      "x-business-id": businessId,
      "business-id": businessId,
      if (storeId.isNotEmpty) "x-store-id": storeId,
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
    return headers;
  }

  // ---------------------------------------------------
  // 4 APIS ON LOAD (Matches Web Network Inspection):
  // 1) https://demotesting.jobes24x7.com/api/billingapi/raw?limit=1000
  // 2) https://billing.srivagroups.in/api/supplier-services
  // 3) https://billing.srivagroups.in/api/supplier-category
  // 4) https://billing.srivagroups.in/api/supplier-product
  // ---------------------------------------------------
  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchRawSuppliers(),
      _fetchSupplierServices(),
      _fetchSupplierCategoryData(),
      _fetchSupplierProductData(),
    ]);
  }

  Future<void> _fetchRawSuppliers() async {
    const rawUrl = "https://demotesting.jobes24x7.com/api/billingapi/raw?limit=1000";
    try {
      final res = await http.get(Uri.parse(rawUrl), headers: {"Accept": "application/json"}).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = decoded['data'] ?? [];
        }
        if (list.isNotEmpty && mounted) {
          setState(() {
            suppliersList = list;
            isSuppliersLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("raw?limit=1000 fetch error: $e");
    }

    try {
      final token = await _getEffectiveToken();
      final res = await http.get(Uri.parse("https://billing.srivagroups.in/api/suppliers/"), headers: {
        if (token.isNotEmpty) "Authorization": "Bearer $token",
        "Accept": "application/json",
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data']?['data']?['data'] ?? decoded['data'] ?? [];
        if (list is List && list.isNotEmpty && mounted) {
          setState(() {
            suppliersList = list;
            isSuppliersLoading = false;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => isSuppliersLoading = false);
  }

  Future<void> _fetchSupplierServices() async {
    const url = "https://billing.srivagroups.in/api/supplier-services";
    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (list.isNotEmpty) {
          final List<Map<String, dynamic>> parsed = [];
          for (var item in list) {
            parsed.add({
              "id": item['id']?.toString() ?? "",
              "service_code": item['service_code'] ?? "-",
              "service_name": item['service_name'] ?? "-",
              "supplier": item['supplier_name'] ?? item['supplier'] ?? "-",
              "supplier_id": item['supplier_id'],
              "type": item['service_type'] ?? "One-Time Repair",
              "status": (item['status']?.toString().toLowerCase() == "active") ? "Active" : "Inactive",
              "contact": item['contact_details'] ?? "-",
              "location": item['location_address'] ?? "-",
              "description": item['service_description_terms'] ?? "",
            });
          }
          if (mounted) {
            setState(() {
              registeredServices = parsed;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("supplier-services fetch error: $e");
    }
  }

  Future<void> _fetchSupplierCategoryData() async {
    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse("https://billing.srivagroups.in/api/supplier-category"), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (list.isNotEmpty && mounted) {
          setState(() {
            supplierCategoryRecords = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (e) {
      debugPrint("supplier-category fetch error: $e");
    }
  }

  Future<void> _fetchSupplierProductData() async {
    try {
      final headers = await _getEffectiveHeaders(jsonBody: false);
      final res = await http.get(Uri.parse("https://billing.srivagroups.in/api/supplier-product"), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] is List ? decoded['data'] as List : [];
        if (list.isNotEmpty && mounted) {
          setState(() {
            supplierProductRecords = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (e) {
      debugPrint("supplier-product fetch error: $e");
    }
  }

  // ---------------------------------------------------
  // SUPPLIER SELECTION & DETAIL AUTO-FILL VIA raw/{id}
  // ---------------------------------------------------
  Future<void> _onSupplierSelected(Map<String, dynamic>? val) async {
    if (val == null) return;
    final sIdStr = (val['id'] ?? val['supplier_id'] ?? "").toString();

    setState(() {
      selectedSupplier = val;
      selectedSupplierId = sIdStr;
      isSupplierDetailsLoading = true;

      // Immediate pre-fill from dropdown item
      supplierNameController.text = (val['supplier_name'] ?? val['business_name'] ?? val['company_name'] ?? val['office_name'] ?? "").toString();
      final p = (val['phone'] ?? val['primary_phone'] ?? "").toString().trim();
      final e = (val['email'] ?? "").toString().trim();
      contactDetailsController.text = (p.isNotEmpty && e.isNotEmpty) ? "$p / $e" : (p.isNotEmpty ? p : e);

      final loc = [val['street'], val['area_locality'], val['city'], val['district'], val['state']].where((x) => x != null && x.toString().trim().isNotEmpty).join(', ');
      final pin = (val['pincode'] ?? "").toString().trim();
      locationController.text = (pin.isNotEmpty && loc.isNotEmpty) ? "$loc - $pin" : (loc.isNotEmpty ? loc : pin);
    });

    final suppId = val['id'] ?? val['supplier_id'];
    if (suppId != null) {
      await _fetchSupplierDetails(suppId);
    } else {
      if (mounted) setState(() => isSupplierDetailsLoading = false);
    }
  }

  Future<void> _fetchSupplierDetails(dynamic suppId) async {
    final rawUrl = "https://demotesting.jobes24x7.com/api/billingapi/raw/$suppId";
    try {
      final res = await http.get(Uri.parse(rawUrl), headers: {"Accept": "application/json"}).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && mounted) {
          final sName = (data['supplier_name'] ?? data['business_name'] ?? data['office_name'] ?? "").toString().trim();
          final phone = (data['phone'] ?? "").toString().trim();
          final email = (data['email'] ?? "").toString().trim();
          final contact = (phone.isNotEmpty && email.isNotEmpty) ? "$phone / $email" : (phone.isNotEmpty ? phone : email);

          final List<String> addressParts = [];
          for (var field in ['street', 'street_road', 'area_locality', 'city', 'district', 'state']) {
            final val = data[field]?.toString().trim();
            if (val != null && val.isNotEmpty && !addressParts.contains(val)) {
              addressParts.add(val);
            }
          }
          final pincode = data['pincode']?.toString().trim();
          String location = addressParts.join(', ');
          if (pincode != null && pincode.isNotEmpty) {
            location = location.isNotEmpty ? "$location - $pincode" : pincode;
          }

          setState(() {
            if (sName.isNotEmpty) supplierNameController.text = sName;
            if (contact.isNotEmpty) contactDetailsController.text = contact;
            if (location.isNotEmpty) locationController.text = location;
            isSupplierDetailsLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("raw/$suppId fetch error: $e");
    }
    if (mounted) setState(() => isSupplierDetailsLoading = false);
  }

  void _resetForm() {
    setState(() {
      selectedSupplier = null;
      selectedSupplierId = null;
      supplierNameController.clear();
      contactDetailsController.clear();
      locationController.clear();
      _autoGenerateCode();
      serviceNameController.clear();
      descriptionController.clear();
      selectedServiceType = "One-Time Repair";
      selectedStatus = "Active";
      editingServiceId = null;
      isSupplierDetailsLoading = false;
      isSaving = false;
    });
  }

  Future<void> _saveService() async {
    if (selectedSupplier == null && supplierNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a supplier ⚠️"), backgroundColor: Colors.orange),
      );
      return;
    }
    if (serviceNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter service name ⚠️"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isSaving = true);
    final headers = await _getEffectiveHeaders(jsonBody: true);

    final sName = supplierNameController.text.trim().isNotEmpty
        ? supplierNameController.text.trim()
        : (selectedSupplier?['supplier_name'] ?? selectedSupplier?['business_name'] ?? "Supplier").toString();

    final rawSuppId = selectedSupplier?['id'] ?? selectedSupplier?['supplier_id'] ?? 47;
    final intSuppId = int.tryParse(rawSuppId.toString()) ?? rawSuppId;

    final requestPayload = {
      "supplier_id": intSuppId,
      "supplier_name": sName,
      "contact_details": contactDetailsController.text.trim(),
      "location_address": locationController.text.trim(),
      "service_code": serviceCodeController.text.trim(),
      "service_description_terms": descriptionController.text.trim(),
      "service_name": serviceNameController.text.trim(),
      "service_type": selectedServiceType,
      "status": selectedStatus.toLowerCase(),
    };

    final body = jsonEncode(requestPayload);

    try {
      http.Response res;
      if (editingServiceId != null) {
        res = await http.put(
          Uri.parse("https://billing.srivagroups.in/api/supplier-services/$editingServiceId"),
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 10));
      } else {
        res = await http.post(
          Uri.parse("https://billing.srivagroups.in/api/supplier-services"),
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 10));
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _fetchSupplierServices();
      }
    } catch (e) {
      debugPrint("Save service error: $e");
    }

    if (!mounted) return;
    setState(() {
      isSaving = false;
      if (editingServiceId != null) {
        final idx = registeredServices.indexWhere((s) => s['id'] == editingServiceId);
        if (idx != -1) {
          registeredServices[idx] = {
            "id": editingServiceId!,
            "service_code": serviceCodeController.text.trim(),
            "service_name": serviceNameController.text.trim(),
            "supplier": sName,
            "supplier_id": intSuppId,
            "type": selectedServiceType,
            "status": selectedStatus,
            "contact": contactDetailsController.text.trim(),
            "location": locationController.text.trim(),
            "description": descriptionController.text.trim(),
          };
        }
      } else {
        final exists = registeredServices.any((s) => s['service_code'] == serviceCodeController.text.trim());
        if (!exists) {
          registeredServices.insert(0, {
            "id": DateTime.now().millisecondsSinceEpoch.toString(),
            "service_code": serviceCodeController.text.trim(),
            "service_name": serviceNameController.text.trim(),
            "supplier": sName,
            "supplier_id": intSuppId,
            "type": selectedServiceType,
            "status": selectedStatus,
            "contact": contactDetailsController.text.trim(),
            "location": locationController.text.trim(),
            "description": descriptionController.text.trim(),
          });
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(editingServiceId != null ? "Updated successfully ✅" : "Created successfully ✅"),
        backgroundColor: const Color(0xFF10B981),
      ),
    );

    _resetForm();
  }

  void _editService(Map<String, dynamic> item) {
    setState(() {
      editingServiceId = item['id'];
      serviceCodeController.text = item['service_code'] ?? "";
      serviceNameController.text = item['service_name'] ?? "";
      supplierNameController.text = item['supplier'] ?? "";
      contactDetailsController.text = item['contact'] ?? "";
      locationController.text = item['location'] ?? "";
      descriptionController.text = item['description'] ?? "";
      selectedServiceType = item['type'] ?? "One-Time Repair";
      selectedStatus = (item['status']?.toString().toLowerCase() == "active" || item['status'] == "Active") ? "Active" : "Inactive";

      final targetId = item['supplier_id']?.toString();
      final targetName = (item['supplier'] ?? "").toString().toLowerCase();

      final sMatch = suppliersList.firstWhere(
        (s) {
          final sId = (s['id'] ?? s['supplier_id'])?.toString();
          if (targetId != null && sId == targetId) return true;
          final sName = (s['supplier_name'] ?? s['company_name'] ?? s['business_name'] ?? "").toString().toLowerCase();
          return sName.isNotEmpty && (sName == targetName || targetName.contains(sName));
        },
        orElse: () => null,
      );
      if (sMatch != null) {
        selectedSupplier = sMatch is Map<String, dynamic> ? sMatch : Map<String, dynamic>.from(sMatch);
        selectedSupplierId = (sMatch['id'] ?? sMatch['supplier_id'])?.toString();
      }
    });
  }

  void _deleteService(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Delete Service", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to delete service '${item['service_name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final delId = item['id'];
              setState(() => registeredServices.remove(item));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Service deleted"), duration: Duration(seconds: 1)),
              );

              try {
                final headers = await _getEffectiveHeaders(jsonBody: false);
                await http.delete(
                  Uri.parse("https://billing.srivagroups.in/api/supplier-services/$delId"),
                  headers: headers,
                ).timeout(const Duration(seconds: 8));
                await _fetchSupplierServices();
              } catch (_) {}
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
    final filtered = registeredServices.where((s) {
      if (filterStatusTab != "All" && s['status'] != filterStatusTab) return false;
      if (searchController.text.trim().isNotEmpty) {
        final q = searchController.text.toLowerCase();
        final name = (s['service_name'] ?? "").toString().toLowerCase();
        final code = (s['service_code'] ?? "").toString().toLowerCase();
        final supp = (s['supplier'] ?? "").toString().toLowerCase();
        if (!name.contains(q) && !code.contains(q) && !supp.contains(q)) return false;
      }
      return true;
    }).toList();

    final displayed = filtered.take(showEntries).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Create Supplier Service", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF6366F1)),
            tooltip: "Sync with Web",
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Syncing services with web... 🔄"), duration: Duration(milliseconds: 800)),
              );
              await _fetchSupplierServices();
            },
          ),
          const BillingModeSelector(currentMode: "Sale"),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSupplierServices,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Title & View All Services Button (Photo 2)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.handyman_outlined, color: Color(0xFF6366F1), size: 22),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Create Supplier Service",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Configure & list services offered by suppliers.",
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ListServiceManagementPage(token: widget.token)),
                    );
                  },
                  icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF475569)),
                  label: const Text("View All Services", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Card 1: Service Registration Form (Photo 2)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.add, color: Color(0xFF4F46E5), size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Service Registration Form",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("New Service", style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Responsive Form Grid (Photo 2)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 700;
                      if (isWide) {
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildSupplierSelectField()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInputField("Supplier Name *", supplierNameController, "Enter Supplier Name")),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInputField("Contact Details", contactDetailsController, "Phone number or Email")),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildInputField("Location / Address", locationController, "e.g. City, State or Branch location")),
                                const SizedBox(width: 12),
                                Expanded(child: _buildServiceCodeField()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInputField("Service Name *", serviceNameController, "e.g. Chip Level Repairing / AC Servicing")),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildServiceTypeDropdown()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatusDropdown()),
                                const SizedBox(width: 12),
                                const Spacer(),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildSupplierSelectField(),
                            const SizedBox(height: 12),
                            _buildInputField("Supplier Name *", supplierNameController, "Enter Supplier Name"),
                            const SizedBox(height: 12),
                            _buildInputField("Contact Details", contactDetailsController, "Phone number or Email"),
                            const SizedBox(height: 12),
                            _buildInputField("Location / Address", locationController, "e.g. City, State or Branch location"),
                            const SizedBox(height: 12),
                            _buildServiceCodeField(),
                            const SizedBox(height: 12),
                            _buildInputField("Service Name *", serviceNameController, "e.g. Chip Level Repairing / AC Servicing"),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildServiceTypeDropdown()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatusDropdown()),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Service Description / Terms
                  const Text("Service Description / Terms", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter detailed description, inclusions, and terms...",
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons: Reset Form | Create & Save Service
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _resetForm,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Reset Form", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isSaving ? null : _saveService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                editingServiceId != null ? "Update Service" : "Create & Save Service",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card 2: Registered Supplier Services Table (Photo 2)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Controls Bar (Photo 2)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.handyman_outlined, color: Color(0xFF6366F1), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Registered Supplier Services (${filtered.length})",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("SHOW ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: showEntries,
                                      items: [10, 25, 50].map((v) => DropdownMenuItem(value: v, child: Text("$v", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => showEntries = v);
                                      },
                                    ),
                                  ),
                                ),
                                const Text(" ENTRIES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              ],
                            ),
                            // Filter Tabs: All | Active | Inactive
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: ["All", "Active", "Inactive"].map((tab) {
                                  final isSel = filterStatusTab == tab;
                                  return InkWell(
                                    onTap: () => setState(() => filterStatusTab = tab),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSel ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: isSel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)] : null,
                                      ),
                                      child: Text(
                                        tab,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                          color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Search field
                            SizedBox(
                              width: 180,
                              height: 34,
                              child: TextField(
                                controller: searchController,
                                onChanged: (v) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: "Search by name, code or supplie...",
                                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                  prefixIcon: const Icon(Icons.search, size: 15, color: Color(0xFF94A3B8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
                                ),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  if (displayed.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.handyman_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text("No services found", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 800),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columnSpacing: 20,
                          horizontalMargin: 16,
                          columns: const [
                            DataColumn(label: Text("S.NO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                            DataColumn(label: Text("SERVICE CODE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                            DataColumn(label: Text("SERVICE NAME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                            DataColumn(label: Text("SUPPLIER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                            DataColumn(label: Text("TYPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                            DataColumn(label: Text("STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                            DataColumn(label: Text("ACTIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                          ],
                          rows: List.generate(displayed.length, (index) {
                            final s = displayed[index];
                            final isActive = s['status'] == "Active";
                            return DataRow(
                              cells: [
                                DataCell(Text("${index + 1}", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(s['service_code'] ?? "-", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  ),
                                ),
                                DataCell(Text(s['service_name'] ?? "-", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                                DataCell(Text(s['supplier'] ?? "-", style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(s['type'] ?? "One-Time Repair", style: const TextStyle(color: Color(0xFF92400E), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(s['status'] ?? "Active", style: TextStyle(color: isActive ? const Color(0xFF166534) : const Color(0xFF991B1B), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _editService(s),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _deleteService(s),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFEF4444)),
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
    ),
  );
}

  Widget _buildSupplierSelectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Supplier *", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            if (isSupplierDetailsLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSupplierId,
              hint: Text(
                isSuppliersLoading ? "Loading suppliers..." : "-- Select Supplier --",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              isExpanded: true,
              items: suppliersList.map((s) {
                final sId = (s['id'] ?? s['supplier_id'] ?? "").toString();
                final name = (s['supplier_name'] ?? s['business_name'] ?? s['company_name'] ?? s['office_name'] ?? "Supplier").toString();
                return DropdownMenuItem<String>(
                  value: sId,
                  child: Text(name, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                final match = suppliersList.firstWhere(
                  (s) => (s['id'] ?? s['supplier_id']).toString() == val,
                  orElse: () => null,
                );
                if (match != null) {
                  _onSupplierSelected(match is Map<String, dynamic> ? match : Map<String, dynamic>.from(match));
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Service Code / SKU *", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextFormField(
                  controller: serviceCodeController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: _autoGenerateCode,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh, size: 12, color: Color(0xFF2563EB)),
                    SizedBox(width: 2),
                    Text("Auto Generate", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
              fillColor: Colors.white,
              filled: true,
            ),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Service Type", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedServiceType,
              isExpanded: true,
              items: ["One-Time Repair", "Annual Maintenance", "Installation", "Inspection", "Consulting"].map((t) {
                return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => selectedServiceType = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Status", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              items: ["Active", "Inactive"].map((s) {
                return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => selectedStatus = v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
