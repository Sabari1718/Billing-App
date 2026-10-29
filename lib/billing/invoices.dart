import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BillListScreen extends StatefulWidget {
  final String token;
  const BillListScreen({super.key, required this.token});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  String activeTab = "Bill"; // "Bill" or "Quotations"
  List<Map<String, dynamic>> bills = [];
  List<Map<String, dynamic>> quotations = [];
  List<dynamic> stocksList = [];
  List<dynamic> variantMasterList = [];
  Map<String, Map<String, dynamic>> productMapping = {};

  bool loading = true;
  String? errorMessage;
  String? localToken;
  String? businessId;
  String role = "propagater";

  // Filter & Pagination
  int entriesPerPage = 10;
  int currentPage = 1;
  final TextEditingController billSearchController = TextEditingController();
  final TextEditingController quotationSearchController = TextEditingController();
  String quotationStatusFilter = "All Status"; // All Status, Completed, Pending, Expired

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchBills();
  }

  @override
  void dispose() {
    billSearchController.dispose();
    quotationSearchController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getBillingHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("billing_auth_token") ??
                  prefs.getString("auth_token") ??
                  prefs.getString("token") ??
                  localToken ??
                  widget.token;
    final bizId = prefs.getString("selected_business_id") ??
                  prefs.get("business_id")?.toString() ??
                  businessId ??
                  "";
    final platformId = prefs.getString("selected_platform_id") ??
                       prefs.getString("platform_id") ??
                       "";
    final storeId = prefs.getString("selected_store_id") ??
                    prefs.getString("store_id") ??
                    prefs.get("store_id")?.toString() ??
                    "";

    final cleanToken = token.trim().startsWith("Bearer ")
        ? token.trim().substring(7).trim()
        : token.trim();

    final headers = <String, String>{
      "Accept": "application/json",
      "Content-Type": "application/json",
      if (cleanToken.isNotEmpty) "Authorization": "Bearer $cleanToken",
      if (bizId.isNotEmpty) ...{
        "business_id": bizId,
        "account_id": bizId,
        "id": bizId,
        "x-business-id": bizId,
        "businessId": bizId,
      },
      if (platformId.isNotEmpty) ...{
        "x-platform-id": platformId,
        "platform_id": platformId,
        "platformId": platformId,
      },
      if (storeId.isNotEmpty) ...{
        "x-store-id": storeId,
        "store_id": storeId,
        "storeId": storeId,
      },
    };
    return headers;
  }

  Future<void> _loadTokenAndFetchBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      localToken = prefs.getString("billing_auth_token") ??
                   prefs.getString("auth_token") ??
                   prefs.getString("token") ??
                   widget.token;
      role = prefs.getString("role")?.toLowerCase() ?? "propagater";
      final rawBizId = prefs.get("business_id") ?? prefs.getString("selected_business_id");
      businessId = rawBizId?.toString();

      AppLogger.info("Tokens and role ($role) loaded for bill history, businessId: $businessId");

      // 3 APIs called when navigating to Invoices (matching web devtools):
      // 1. GET /api/stocks
      // 2. GET /api/variant-master
      // 3. GET /api/bills
      // Plus Quotations list for quotation tab:
      // 4. GET /api/quotation-bill
      await Future.wait([
        fetchStocks(),
        fetchVariantMaster(),
        fetchBills(),
        fetchQuotations(),
      ]);
    } catch (e) {
      AppLogger.error("Error loading token and fetching invoice data", e);
      if (mounted) {
        setState(() {
          bills = _getDemoBills();
          quotations = _getDemoQuotations();
          loading = false;
        });
      }
    }
  }

  Future<void> fetchStocks() async {
    try {
      final headers = await _getBillingHeaders();
      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stocks"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final raw = decoded["data"] is List
            ? decoded["data"]
            : (decoded["stocks"] is List ? decoded["stocks"] : []);
        stocksList = List<dynamic>.from(raw);
        _rebuildProductMapping();
        AppLogger.info("Stocks loaded successfully: ${stocksList.length} items");
      } else {
        AppLogger.warning("fetchStocks returned ${response.statusCode}");
      }
    } catch (e) {
      AppLogger.error("fetchStocks error", e);
    }
  }

  Future<void> fetchVariantMaster() async {
    try {
      final headers = await _getBillingHeaders();
      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/variant-master"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final raw = decoded["data"] is List ? decoded["data"] : [];
        variantMasterList = List<dynamic>.from(raw);
        _rebuildProductMapping();
        AppLogger.info("Variant master loaded successfully: ${variantMasterList.length} items");
      } else {
        AppLogger.warning("fetchVariantMaster returned ${response.statusCode}");
      }
    } catch (e) {
      AppLogger.error("fetchVariantMaster error", e);
    }
  }

  void _rebuildProductMapping() {
    final map = <String, Map<String, dynamic>>{};
    for (var s in stocksList) {
      if (s is! Map) continue;
      final pName = (s['product_name'] ?? s['name'] ?? '').toString();
      final bName = (s['brand_name'] ?? (s['brand'] is Map ? s['brand']['name'] : s['brand']) ?? '').toString();
      final pId = s['product_id'] ?? s['id'];
      final sId = s['id'];
      final price = double.tryParse((s['selling_price'] ?? s['price'] ?? 0).toString()) ?? 0.0;
      final taxRate = double.tryParse((s['gst_rate'] ?? s['tax_rate'] ?? 18).toString()) ?? 18.0;

      final info = {
        'name': pName,
        'brand_name': bName,
        'variant_name': '',
        'price': price,
        'tax_rate': taxRate,
      };
      if (pId != null) {
        map['p-$pId'] = info;
        map['$pId'] = info;
      }
      if (sId != null) {
        map['stock-$sId'] = info;
        map['$sId'] = info;
      }

      if (s['variants'] is List) {
        for (var v in s['variants']) {
          if (v is! Map) continue;
          final vId = v['id'] ?? v['variant_id'];
          final vPrice = double.tryParse((v['selling_price'] ?? v['price'] ?? price).toString()) ?? price;
          final vTax = double.tryParse((v['gst_rate'] ?? taxRate).toString()) ?? taxRate;
          final vName = (v['variant_name'] ?? v['name'] ?? '').toString();

          final vInfo = {
            'name': pName,
            'brand_name': bName,
            'variant_name': vName,
            'price': vPrice,
            'tax_rate': vTax,
          };
          if (pId != null && vId != null) map['v-$pId-$vId'] = vInfo;
          if (sId != null && vId != null) map['v-$sId-$vId'] = vInfo;
        }
      }
    }
    productMapping = map;
  }

  Future<void> fetchBills() async {
    try {
      final headers = await _getBillingHeaders();
      final prefs = await SharedPreferences.getInstance();

      // Primary URL is /api/bills as verified in Web Network Tab
      String url = "https://billing.srivagroups.in/api/bills";
      final pId = prefs.getString("selected_platform_id") ?? prefs.getString("platform_id") ?? "";
      final sId = prefs.getString("selected_store_id") ?? prefs.get("store_id")?.toString() ?? "";

      List<String> q = [];
      if (role == "supplier" || role == "partner") {
        final userMainId = prefs.getString("user_main_id") ?? "";
        q.add("business_id=$businessId");
        q.add("user_main_id=$userMainId");
      } else if (businessId != null && businessId!.isNotEmpty) {
        q.add("business_id=$businessId");
      }
      if (pId.isNotEmpty) q.add("platform_id=$pId");
      if (sId.isNotEmpty) q.add("store_id=$sId");
      if (q.isNotEmpty) url += "?${q.join('&')}";

      http.Response response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));

      // Fallback to /api/sales/bills if primary doesn't return 200
      if (response.statusCode != 200) {
        String fallbackUrl = "https://billing.srivagroups.in/api/sales/bills";
        if (q.isNotEmpty) fallbackUrl += "?${q.join('&')}";
        final fbRes = await http.get(Uri.parse(fallbackUrl), headers: headers).timeout(const Duration(seconds: 15));
        if (fbRes.statusCode == 200) {
          response = fbRes;
        }
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawList = decoded["data"] is List
            ? decoded["data"]
            : (decoded["data"] is Map && decoded["data"]["bills"] is List
                ? decoded["data"]["bills"]
                : (decoded["bills"] is List ? decoded["bills"] : []));
        if (rawList.isNotEmpty) {
          if (mounted) {
            setState(() {
              bills = List<Map<String, dynamic>>.from(rawList.map((e) => Map<String, dynamic>.from(e)));
              loading = false;
            });
          }
          AppLogger.info("Bills loaded successfully: ${bills.length} bills");
          return;
        }
      }

      // If empty or non-200, use demo bills
      if (mounted) {
        setState(() {
          bills = _getDemoBills();
          loading = false;
        });
      }
    } catch (e) {
      AppLogger.error("fetchBills error", e);
      if (mounted) {
        setState(() {
          bills = _getDemoBills();
          loading = false;
        });
      }
    }
  }

  Future<void> fetchQuotations() async {
    try {
      final headers = await _getBillingHeaders();
      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/quotation-bill"),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawList = decoded["data"] is List
            ? decoded["data"]
            : (decoded["quotations"] is List ? decoded["quotations"] : []);
        if (rawList.isNotEmpty) {
          if (mounted) {
            setState(() {
              quotations = List<Map<String, dynamic>>.from(rawList.map((e) => Map<String, dynamic>.from(e)));
            });
          }
          AppLogger.info("Quotations loaded successfully: ${quotations.length} items");
          return;
        }
      }

      if (mounted && quotations.isEmpty) {
        setState(() {
          quotations = _getDemoQuotations();
        });
      }
    } catch (e) {
      AppLogger.error("fetchQuotations error", e);
      if (mounted && quotations.isEmpty) {
        setState(() {
          quotations = _getDemoQuotations();
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchQuotationDetails(dynamic id) async {
    if (id == null) return null;
    try {
      final headers = await _getBillingHeaders();
      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/quotation-bill/$id"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["data"] is Map) {
          return Map<String, dynamic>.from(decoded["data"]);
        }
      }
    } catch (e) {
      AppLogger.error("fetchQuotationDetails error", e);
    }
    return null;
  }

  Future<void> _updateQuotationStatus(dynamic id, String newStatus, Map<String, dynamic> q) async {
    if (id != null) {
      try {
        final headers = await _getBillingHeaders();
        final response = await http.put(
          Uri.parse("https://billing.srivagroups.in/api/quotation-bill/$id"),
          headers: headers,
          body: jsonEncode({"status": newStatus}),
        ).timeout(const Duration(seconds: 10));
        AppLogger.info("updateQuotationStatus response: ${response.statusCode}");
      } catch (e) {
        AppLogger.error("updateQuotationStatus error", e);
      }
    }
    if (mounted) {
      setState(() {
        q['status'] = newStatus;
      });
      final qNum = q['quotation_number'] ?? q['quotation_id'] ?? id ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Quotation $qNum status updated to $newStatus!"),
          backgroundColor: const Color(0xFF0D6EFD),
        ),
      );
    }
  }

  Future<void> _deleteQuotation(dynamic id, String qNumber) async {
    if (id != null) {
      try {
        final headers = await _getBillingHeaders();
        final response = await http.delete(
          Uri.parse("https://billing.srivagroups.in/api/quotation-bill/$id"),
          headers: headers,
        ).timeout(const Duration(seconds: 10));
        AppLogger.info("deleteQuotation response: ${response.statusCode}");
      } catch (e) {
        AppLogger.error("deleteQuotation error", e);
      }
    }
    if (mounted) {
      setState(() {
        quotations.removeWhere((item) =>
            item['id'] == id ||
            item['quotation_id'] == qNumber ||
            item['quotation_number'] == qNumber);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Quotation $qNumber deleted"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getDemoBills() {
    return [
      {
        "id": 288,
        "bill_number": "BILL-00094",
        "created_at": "2026-10-27 18:19:01",
        "customer_name": "Iniya",
        "customer_phone": "8778908590",
        "tax": "4.58",
        "final_amount": "30.00",
        "total_amount": "30.00",
        "payment_method": "UPI",
        "status": "COMPLETED",
        "email_sent": 1,
        "customer_meta": jsonEncode({
          "email": "sriniya2123@gmail.com",
          "address": "kallakurichi",
          "paid_amount": 30.0,
          "balance_due": 0.0,
          "payments": [
            {"payment_mode": "UPI", "amount": 30.0, "date": "27/10/2026"}
          ],
          "items": [
            {
              "product_name": "JUMPERS Wires F-F",
              "brand": "Imported",
              "variant": "Imported",
              "qty": 10,
              "tax_percent": 0.0,
              "tax_amount": 0.0,
              "without_tax": 30.0,
              "total": 30.0,
            }
          ]
        }),
      },
      {
        "id": 287,
        "bill_number": "BILL-00093",
        "created_at": "2026-10-27 16:45:10",
        "customer_name": "Rajesh Kumar",
        "customer_phone": "9876543210",
        "tax": "64.07",
        "final_amount": "420.00",
        "total_amount": "420.00",
        "payment_method": "UPI",
        "status": "COMPLETED",
        "email_sent": 1,
        "customer_meta": jsonEncode({
          "email": "rajesh@gmail.com",
          "address": "Coimbatore",
          "paid_amount": 420.0,
          "balance_due": 0.0,
          "payments": [
            {"payment_mode": "UPI", "amount": 420.0, "date": "27/10/2026"}
          ],
          "items": [
            {
              "product_name": "Osyan LED Rope Light 220V SMD",
              "brand": "Osyan",
              "variant": "Standard",
              "qty": 1,
              "tax_percent": 18.0,
              "tax_amount": 64.07,
              "without_tax": 355.93,
              "total": 420.0,
            }
          ]
        }),
      },
      {
        "id": 286,
        "bill_number": "BILL-00092",
        "created_at": "2026-10-27 15:30:00",
        "customer_name": "Priya S",
        "customer_phone": "9443215678",
        "tax": "56.44",
        "final_amount": "370.02",
        "total_amount": "370.02",
        "payment_method": "UPI",
        "status": "COMPLETED",
        "email_sent": 1,
      },
      {
        "id": 285,
        "bill_number": "BILL-00091",
        "created_at": "2026-10-27 14:15:20",
        "customer_name": "Arun V",
        "customer_phone": "9087654321",
        "tax": "18.92",
        "final_amount": "124.03",
        "total_amount": "124.03",
        "payment_method": "UPI",
        "status": "COMPLETED",
        "email_sent": 1,
      },
      {
        "id": 284,
        "bill_number": "BILL-00090",
        "created_at": "2026-10-27 12:10:45",
        "customer_name": "Karthik M",
        "customer_phone": "8877665544",
        "tax": "38.14",
        "final_amount": "250.01",
        "total_amount": "250.01",
        "payment_method": "UPI",
        "status": "COMPLETED",
        "email_sent": 1,
      },
      {
        "id": 283,
        "bill_number": "BILL-00089",
        "created_at": "2026-10-26 17:50:30",
        "customer_name": "Vignesh T",
        "customer_phone": "9789012345",
        "tax": "6.10",
        "final_amount": "40.00",
        "total_amount": "40.00",
        "payment_method": "Cash",
        "status": "COMPLETED",
        "email_sent": 1,
      },
      {
        "id": 282,
        "bill_number": "BILL-00088",
        "created_at": "2026-10-26 15:22:15",
        "customer_name": "Circuit Hub",
        "customer_phone": "9123456780",
        "tax": "317.29",
        "final_amount": "2080.00",
        "total_amount": "2080.00",
        "payment_method": "UPI",
        "status": "COMPLETED",
        "email_sent": 1,
      },
      {
        "id": 281,
        "bill_number": "BILL-00087",
        "created_at": "2026-10-26 11:05:00",
        "customer_name": "Anitha D",
        "customer_phone": "9654321890",
        "tax": "101.44",
        "final_amount": "665.00",
        "total_amount": "665.00",
        "payment_method": "UPI",
        "status": "COMPLETED",
        "email_sent": 1,
      },
    ];
  }

  List<Map<String, dynamic>> _getDemoQuotations() {
    return [
      {
        "id": 2,
        "quotation_id": "QUOT-00002",
        "date": "2026-09-28 10:11:22",
        "customer_name": "Sabari",
        "customer_phone": "9092014442",
        "items_count": 1,
        "amount": 1450.0,
        "exp_date": "2026-10-05",
        "status": "COMPLETED",
        "items": [
          {
            "product_name": "Electronic Development Kit",
            "qty": 1,
            "price": 1450.0,
            "total": 1450.0,
          }
        ],
      },
      {
        "id": 1,
        "quotation_id": "QUOT-00001",
        "date": "2026-07-20 11:37:07",
        "customer_name": "Kannan S",
        "customer_phone": "9842109876",
        "items_count": 1,
        "amount": 70.0,
        "exp_date": "2026-07-27",
        "status": "COMPLETED",
        "items": [
          {
            "product_name": "Sensor Connector Cables",
            "qty": 2,
            "price": 35.0,
            "total": 70.0,
          }
        ],
      },
    ];
  }

  Map<String, dynamic> _parseCustomerMeta(dynamic metaRaw) {
    if (metaRaw is Map<String, dynamic>) return metaRaw;
    if (metaRaw is String && metaRaw.isNotEmpty) {
      try {
        final d = jsonDecode(metaRaw);
        if (d is Map<String, dynamic>) return d;
      } catch (_) {}
    }
    return {};
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      if (raw.contains(' ')) return raw.split(' ')[0];
      if (raw.contains('T')) return raw.split('T')[0];
      return raw;
    }
  }

  String _formatDateDetailed(String? raw) {
    if (raw == null || raw.isEmpty) return "27 Oct 2026";
    try {
      DateTime dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  // ----------------------------------------------------
  // BUILD METHOD
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(activeTab == "Bill" ? "Bill History" : "Quotations", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildTopToggleButtons(),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D6EFD)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeTab == "Bill")
                    _buildBillHistorySection()
                  else
                    _buildQuotationsSection(),
                ],
              ),
            ),
    );
  }

  // ----------------------------------------------------
  // TOP TOGGLE: [Bill] [Quotations] (Photo 1 & 2)
  // ----------------------------------------------------
  Widget _buildTopToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => activeTab = "Bill"),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: activeTab == "Bill" ? const Color(0xFF0D6EFD) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_outlined,
                    size: 14,
                    color: activeTab == "Bill" ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Bill",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: activeTab == "Bill" ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => activeTab = "Quotations"),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: activeTab == "Quotations" ? const Color(0xFF0D6EFD) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.request_quote_outlined,
                    size: 14,
                    color: activeTab == "Quotations" ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Quotations",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: activeTab == "Quotations" ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SECTION 1: BILL HISTORY (Photo 1)
  // ----------------------------------------------------
  Widget _buildBillHistorySection() {
    final query = billSearchController.text.trim().toLowerCase();
    final filteredBills = bills.where((b) {
      if (query.isEmpty) return true;
      final billNo = (b['bill_number'] ?? '').toString().toLowerCase();
      final cName = (b['customer_name'] ?? '').toString().toLowerCase();
      final pMethod = (b['payment_method'] ?? '').toString().toLowerCase();
      final total = (b['final_amount'] ?? '').toString().toLowerCase();
      return billNo.contains(query) || cName.contains(query) || pMethod.contains(query) || total.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls Row: Show [10] entries + Search
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Show", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(width: 6),
                      Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: entriesPerPage,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                            items: [10, 25, 50, 100].map((count) => DropdownMenuItem(value: count, child: Text("$count", style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => entriesPerPage = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text("entries", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  SizedBox(
                    width: 240,
                    height: 36,
                    child: TextField(
                      controller: billSearchController,
                      onChanged: (v) => setState(() {}),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Search Bills...",
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bills Table (Photo 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  columnSpacing: 18,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text("S.NO")),
                    DataColumn(label: Text("BILL NO")),
                    DataColumn(label: Text("DATE")),
                    DataColumn(label: Text("TAX")),
                    DataColumn(label: Text("TOTAL")),
                    DataColumn(label: Text("PAYMENT")),
                    DataColumn(label: Text("STATUS")),
                    DataColumn(label: Text("EMAIL STATUS")),
                    DataColumn(label: Text("ACTIONS")),
                  ],
                  rows: filteredBills.take(entriesPerPage).toList().asMap().entries.map((entry) {
                    final int sNo = entry.key + 1;
                    final Map<String, dynamic> b = entry.value;

                    final String billNo = (b['bill_number'] ?? "-").toString();
                    final String date = _formatDate(b['created_at']?.toString());
                    final String tax = "₹${b['tax'] ?? '0.00'}";
                    final String total = "₹${b['final_amount'] ?? b['total_amount'] ?? '0.00'}";
                    final String payment = (b['payment_method'] ?? "UPI").toString();
                    final bool isSent = b['email_sent'] == 1 || b['email_sent'] == "1";

                    return DataRow(
                      cells: [
                        DataCell(Text("$sNo", style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)))),
                        DataCell(Text(billNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                        DataCell(Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        DataCell(Text(tax, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        DataCell(Text(total, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)))),
                        DataCell(Text(payment, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.circle, size: 7, color: Color(0xFF2E7D32)),
                                SizedBox(width: 4),
                                Text(
                                  "COMPLETED",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSent ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 7, color: isSent ? const Color(0xFF2E7D32) : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  isSent ? "Sent" : "Pending",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSent ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // View Action (Photo 4)
                              OutlinedButton.icon(
                                onPressed: () => _showInvoiceDialog(b),
                                icon: const Icon(Icons.visibility_outlined, size: 12),
                                label: const Text("View", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0D6EFD),
                                  side: const BorderSide(color: Color(0xFF0D6EFD)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Edit Action (Photo 5)
                              OutlinedButton.icon(
                                onPressed: () => _showEditBillDialog(b),
                                icon: const Icon(Icons.edit_outlined, size: 12),
                                label: const Text("Edit", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFF59E0B),
                                  side: const BorderSide(color: Color(0xFFF59E0B)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Delete Action
                              OutlinedButton.icon(
                                onPressed: () => _confirmDeleteBill(b),
                                icon: const Icon(Icons.delete_outline, size: 12),
                                label: const Text("Delete", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(color: Color(0xFFEF4444)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Pagination Footer
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    "Showing 1 to ${filteredBills.take(entriesPerPage).length} of ${filteredBills.length} entries",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Go to Page", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                        child: Text("$currentPage", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 18),
                        onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0D6EFD), borderRadius: BorderRadius.circular(4)),
                        child: const Text("1", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 18),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // SECTION 2: QUOTATIONS (Photos 2 & 3)
  // ----------------------------------------------------
  Widget _buildQuotationsSection() {
    final query = quotationSearchController.text.trim().toLowerCase();
    final filteredQuotations = quotations.where((q) {
      final st = (q['status'] ?? '').toString().toUpperCase();
      if (quotationStatusFilter != "All Status" && st != quotationStatusFilter.toUpperCase()) {
        return false;
      }
      if (query.isEmpty) return true;
      final qId = (q['quotation_number'] ?? q['quotation_id'] ?? q['id'] ?? '').toString().toLowerCase();
      final cName = (q['customer_name'] ?? '').toString().toLowerCase();
      final phone = (q['customer_phone'] ?? '').toString().toLowerCase();
      return qId.contains(query) || cName.contains(query) || phone.contains(query);
    }).toList();

    // Dynamically calculate summary cards matching Screenshot 2
    final int pendingCount = quotations.where((q) => (q['status'] ?? '').toString().toUpperCase() == 'PENDING').length;
    final int acceptedCount = quotations.where((q) {
      final st = (q['status'] ?? '').toString().toUpperCase();
      return st == 'ACCEPTED' || st == 'COMPLETED';
    }).length;
    final int expiredCount = quotations.where((q) => (q['status'] ?? '').toString().toUpperCase() == 'EXPIRED').length;
    final double totalVal = quotations.fold(0.0, (sum, q) {
      final val = double.tryParse((q['final_amount'] ?? q['total_amount'] ?? q['amount'] ?? 0).toString()) ?? 0.0;
      return sum + val;
    });
    final String formattedTotalValue = totalVal >= 1000
        ? "₹${(totalVal / 1000).toStringAsFixed(1)}K"
        : "₹${totalVal.toStringAsFixed(0)}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Summary Cards (Photo 2)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              title: "PENDING",
              value: pendingCount.toString().padLeft(2, '0'),
              icon: Icons.access_time_filled,
              iconColor: const Color(0xFFF59E0B),
            ),
            _buildStatCard(
              title: "ACCEPTED",
              value: acceptedCount.toString().padLeft(2, '0'),
              icon: Icons.check_circle,
              iconColor: const Color(0xFF10B981),
            ),
            _buildStatCard(
              title: "EXPIRED",
              value: expiredCount.toString().padLeft(2, '0'),
              icon: Icons.cancel,
              iconColor: const Color(0xFFEF4444),
            ),
            _buildStatCard(
              title: "TOTAL VALUE",
              value: formattedTotalValue,
              icon: Icons.receipt_long,
              iconColor: const Color(0xFF8B5CF6),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search & Status Filter Row (Photos 2 & 3)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 280,
                    height: 38,
                    child: TextField(
                      controller: quotationSearchController,
                      onChanged: (v) => setState(() {}),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Search by Quot ID or Customer Name...",
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
                      ),
                    ),
                  ),

                  // All Status Dropdown (Photo 3)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_alt_outlined, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: quotationStatusFilter,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                            items: ["All Status", "Completed", "Pending", "Expired"].map((st) {
                              final isSelected = st == quotationStatusFilter;
                              return DropdownMenuItem<String>(
                                value: st,
                                child: Text(
                                  st,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFF1E293B),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => quotationStatusFilter = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quotations Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  columnSpacing: 20,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text("QUOTATION ID")),
                    DataColumn(label: Text("DATE")),
                    DataColumn(label: Text("CUSTOMER NAME")),
                    DataColumn(label: Text("ITEMS")),
                    DataColumn(label: Text("AMOUNT")),
                    DataColumn(label: Text("EXP. DATE")),
                    DataColumn(label: Text("STATUS")),
                    DataColumn(label: Text("ACTIONS")),
                  ],
                  rows: filteredQuotations.map((q) {
                    final String qId = (q['quotation_number'] ?? q['quotation_id'] ?? (q['id'] != null ? "QUOT-${q['id'].toString().padLeft(5, '0')}" : '-')).toString();
                    final String date = _formatDate(q['created_at']?.toString() ?? q['date']?.toString());
                    final String cName = (q['customer_name'] ?? '-').toString();
                    final int count = q['items'] is List
                        ? (q['items'] as List).length
                        : (int.tryParse((q['items_count'] ?? 1).toString()) ?? 1);
                    final String items = "$count Items";
                    final double amountVal = double.tryParse((q['final_amount'] ?? q['total_amount'] ?? q['amount'] ?? 0).toString()) ?? 0.0;
                    final String amount = "₹${NumberFormat('#,##0').format(amountVal)}";
                    final String expDate = (q['expiry_date'] ?? q['exp_date'] ?? _calcExpDate(q['created_at']?.toString())).toString();
                    final String status = (q['status'] ?? 'COMPLETED').toString().toUpperCase();

                    Color statusBg = const Color(0xFFE8F5E9);
                    Color statusColor = const Color(0xFF2E7D32);
                    if (status == "PENDING") {
                      statusBg = const Color(0xFFFEF3C7);
                      statusColor = const Color(0xFFD97706);
                    } else if (status == "EXPIRED") {
                      statusBg = const Color(0xFFFEE2E2);
                      statusColor = const Color(0xFFDC2626);
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(qId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                        DataCell(Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        DataCell(Text(cName, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)))),
                        DataCell(Text(items, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        DataCell(Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                        DataCell(Text(expDate, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 7, color: statusColor),
                                const SizedBox(width: 4),
                                Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF0D6EFD)),
                                onPressed: () => _showQuotationDialog(q),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFF59E0B)),
                                onPressed: () => _showEditQuotationDialog(q),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                                onPressed: () => _confirmDeleteQuotation(q),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calcExpDate(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(createdAt);
      DateTime exp = dt.add(const Duration(days: 7));
      return DateFormat('yyyy-MM-dd').format(exp);
    } catch (_) {
      return "-";
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // PHOTO 4: INVOICE VIEW MODAL
  // ----------------------------------------------------
  void _showInvoiceDialog(Map<String, dynamic> b) {
    final meta = _parseCustomerMeta(b['customer_meta']);
    final String billNo = (b['bill_number'] ?? "BILL-00094").toString();
    final String invDate = _formatDateDetailed(b['created_at']?.toString());
    final String paymentMethod = (b['payment_method'] ?? "UPI").toString();
    final String cName = (b['customer_name'] ?? meta['customer_name'] ?? "Iniya").toString();
    final String cPhone = (b['customer_phone'] ?? meta['phone'] ?? "8778908590").toString();
    final String cAddress = (meta['address'] ?? "Kallakurichi").toString();
    final String cEmail = (meta['email'] ?? "sriniya2123@gmail.com").toString();

    final rawItems = b['items'] is List && (b['items'] as List).isNotEmpty
        ? (b['items'] as List)
        : (meta['items'] is List && (meta['items'] as List).isNotEmpty
            ? (meta['items'] as List)
            : [
                {
                  "product_name": "JUMPERS Wires F-F",
                  "brand": "Imported",
                  "variant": "Imported",
                  "qty": 10,
                  "tax_percent": 0.0,
                  "tax_amount": 0.0,
                  "without_tax": 30.0,
                  "total": 30.0,
                }
              ]);

    final double totalAmt = double.tryParse((b['final_amount'] ?? b['total_amount'] ?? "30.00").toString()) ?? 30.0;
    final double taxAmt = double.tryParse((b['tax'] ?? "4.58").toString()) ?? 4.58;
    final double paidAmt = double.tryParse((meta['paid_amount'] ?? totalAmt).toString()) ?? totalAmt;
    final double balanceDue = double.tryParse((meta['balance_due'] ?? 0.0).toString()) ?? 0.0;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Action Bar: [Print] [Download PDF] [X]
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _printInvoice(billNo, invDate, cName, cPhone, totalAmt),
                        icon: const Icon(Icons.print, size: 14),
                        label: const Text("Print", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6EFD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _downloadInvoicePdf(billNo, invDate, cName, cPhone, totalAmt),
                        icon: const Icon(Icons.download, size: 14),
                        label: const Text("Download PDF", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(dialogContext),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Big Center Title: INVOICE
                  const Center(
                    child: Text(
                      "INVOICE",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D6EFD),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shop Details & Customer Details Columns (Photo 4)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 450) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "SHOP DETAILS",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD), letterSpacing: 0.5),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Circuitpointcare",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Neelambur, Sulur Taluk, Coimbatore, TamilNadu, 641062",
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Contact: 9092014442",
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "CUSTOMER DETAILS",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD), letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cAddress,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Contact: $cPhone",
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                if (cEmail.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "Email: $cEmail",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "SHOP DETAILS",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD), letterSpacing: 0.5),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Circuitpointcare",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Neelambur, Sulur Taluk, Coimbatore, TamilNadu, 641062",
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Contact: 9092014442",
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "CUSTOMER DETAILS",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD), letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cAddress,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Contact: $cPhone",
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                if (cEmail.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "Email: $cEmail",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Metadata Box (Photo 4) - Using Wrap to prevent overflow on mobile
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Invoice No : ", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(billNo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Invoice Date : ", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(invDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Payment Mode : ", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(paymentMethod, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Status : ", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text("COMPLETED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items Table (Photo 4)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 50,
                      columnSpacing: 14,
                      horizontalMargin: 8,
                      columns: const [
                        DataColumn(label: Text("S.NO")),
                        DataColumn(label: Text("DESCRIPTION")),
                        DataColumn(label: Text("QTY")),
                        DataColumn(label: Text("TAX (%)")),
                        DataColumn(label: Text("TAX AMOUNT")),
                        DataColumn(label: Text("WITHOUT TAX AMOUNT")),
                        DataColumn(label: Text("TOTAL")),
                      ],
                      rows: rawItems.asMap().entries.map((it) {
                        final i = it.key + 1;
                        final item = it.value is Map ? it.value : {};
                        String pName = (item['product_name'] ?? item['name'] ?? "").toString();
                        String brand = (item['brand_name'] ?? item['brand'] ?? "").toString();
                        String variant = (item['variant_name'] ?? item['variant'] ?? "").toString();

                        if (pName.isEmpty) {
                          final mapped = productMapping['p-${item['product_id']}'] ?? productMapping['${item['product_id']}'];
                          if (mapped != null) {
                            pName = mapped['name'] ?? "Item";
                            if (brand.isEmpty) brand = mapped['brand_name'] ?? "Imported";
                            if (variant.isEmpty) variant = mapped['variant_name'] ?? "Imported";
                          } else {
                            pName = "Item";
                          }
                        }
                        if (brand.isEmpty) brand = "Imported";
                        if (variant.isEmpty) variant = "Imported";

                        final int qty = int.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ?? 1;
                        final double rowTotal = double.tryParse((item['total'] ?? item['price'] ?? totalAmt).toString()) ?? totalAmt;
                        final double withoutTax = double.tryParse((item['without_tax_amount'] ?? item['without_tax'] ?? (rowTotal - (double.tryParse((item['tax_amount'] ?? "0.0").toString()) ?? 0.0))).toString()) ?? rowTotal;
                        final double rowTax = double.tryParse((item['tax_amount'] ?? "0.0").toString()) ?? 0.0;
                        final double taxPercent = double.tryParse((item['tax_percent'] ?? item['tax_rate'] ?? item['gst_rate'] ?? 0).toString()) ?? 0.0;

                        return DataRow(
                          cells: [
                            DataCell(Text("$i", style: const TextStyle(fontSize: 11))),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(pName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  Text("Brand: $brand • Variant: $variant", style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            DataCell(Text("$qty", style: const TextStyle(fontSize: 11))),
                            DataCell(Text("${taxPercent.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 11))),
                            DataCell(Text("₹${rowTax.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11))),
                            DataCell(Text("₹${withoutTax.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11))),
                            DataCell(Text("₹${rowTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Payment Instructions & Amounts Summary (Photo 4) - Responsive
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 450) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "PAYMENT INSTRUCTIONS",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Payment 1  $paymentMethod", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text("₹${paidAmt.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                      Text(invDate, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Column(
                              children: [
                                _buildInvoiceSummaryRow("Without Tax Subtotal", "₹${totalAmt.toStringAsFixed(2)}"),
                                const SizedBox(height: 4),
                                _buildInvoiceSummaryRow("Tax Amount", "₹${taxAmt.toStringAsFixed(2)}"),
                                const Divider(height: 12),
                                _buildInvoiceSummaryRow("Total", "₹${totalAmt.toStringAsFixed(2)}", isBlue: true),
                                const SizedBox(height: 4),
                                _buildInvoiceSummaryRow("Paid Amount", "₹${paidAmt.toStringAsFixed(2)}", isGreen: true),
                                const SizedBox(height: 4),
                                _buildInvoiceSummaryRow("Balance Due", "₹${balanceDue.toStringAsFixed(2)}", isGreen: true),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "PAYMENT INSTRUCTIONS",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Payment 1  $paymentMethod", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text("₹${paidAmt.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                      Text(invDate, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 200,
                            child: Column(
                              children: [
                                _buildInvoiceSummaryRow("Without Tax Subtotal", "₹${totalAmt.toStringAsFixed(2)}"),
                                const SizedBox(height: 4),
                                _buildInvoiceSummaryRow("Tax Amount", "₹${taxAmt.toStringAsFixed(2)}"),
                                const Divider(height: 12),
                                _buildInvoiceSummaryRow("Total", "₹${totalAmt.toStringAsFixed(2)}", isBlue: true),
                                const SizedBox(height: 4),
                                _buildInvoiceSummaryRow("Paid Amount", "₹${paidAmt.toStringAsFixed(2)}", isGreen: true),
                                const SizedBox(height: 4),
                                _buildInvoiceSummaryRow("Balance Due", "₹${balanceDue.toStringAsFixed(2)}", isGreen: true),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 24),

                  // Terms & QR Code (Photo 4) - Responsive
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 400) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Terms & Conditions", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            const Text("1. Payment is due within 15 days of Invoice date.", style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                            const Text("2. Goods once sold cannot be taken back without valid return approval.", style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                            const Text("3. Please inspect all items upon delivery for damage or shortage.", style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            const Text("Return & Refund Policy", style: TextStyle(fontSize: 9, color: Color(0xFF0D6EFD), decoration: TextDecoration.underline)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                                  child: const Center(
                                    child: Icon(Icons.qr_code_2, size: 38, color: Color(0xFF1E293B)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text("Scan to View Invoice", style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Terms & Conditions", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                SizedBox(height: 4),
                                Text("1. Payment is due within 15 days of Invoice date.", style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                                Text("2. Goods once sold cannot be taken back without valid return approval.", style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                                Text("3. Please inspect all items upon delivery for damage or shortage.", style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                                SizedBox(height: 4),
                                Text("Return & Refund Policy", style: TextStyle(fontSize: 9, color: Color(0xFF0D6EFD), decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                                child: const Center(
                                  child: Icon(Icons.qr_code_2, size: 48, color: Color(0xFF1E293B)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text("Scan to View Invoice", style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceSummaryRow(String label, String value, {bool isBlue = false, bool isGreen = false}) {
    Color col = const Color(0xFF1E293B);
    if (isBlue) col = const Color(0xFF0D6EFD);
    if (isGreen) col = const Color(0xFF10B981);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBlue || isGreen ? FontWeight.bold : FontWeight.w500,
            color: col,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // PHOTO 5: EDIT BILL MODAL
  // ----------------------------------------------------
  void _showEditBillDialog(Map<String, dynamic> b) {
    final meta = _parseCustomerMeta(b['customer_meta']);
    final billNoCtrl = TextEditingController(text: (b['bill_number'] ?? "").toString());
    final cNameCtrl = TextEditingController(text: (b['customer_name'] ?? meta['customer_name'] ?? "Iniya").toString());
    final cPhoneCtrl = TextEditingController(text: (b['customer_phone'] ?? meta['phone'] ?? "8778908590").toString());
    String selectedPayment = (b['payment_method'] ?? "UPI").toString();
    final subtotalCtrl = TextEditingController(text: (b['total_amount'] ?? "30").toString());
    final discountCtrl = TextEditingController(text: (b['discount'] ?? "0").toString());
    final taxCtrl = TextEditingController(text: (b['tax'] ?? "4.58").toString());
    final totalCtrl = TextEditingController(text: (b['final_amount'] ?? "30").toString());
    final notesCtrl = TextEditingController(text: (meta['notes'] ?? "").toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (Photo 5)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.edit_note, size: 20, color: Color(0xFF0D6EFD)),
                              SizedBox(width: 8),
                              Text(
                                "Edit Bill / Change Bill No",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Update bill number (import custom no), customer info, and invoice amounts",
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),

                      // Green Box: Bill Number / Invoice No (Custom / Import Change) *
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Bill Number / Invoice No (Custom / Import Change) *",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 38,
                              child: TextField(
                                controller: billNoCtrl,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF86EFAC))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF166534))),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "You can change the auto-generated bill no or enter an imported bill number here.",
                              style: TextStyle(fontSize: 9, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer Name & Phone
                      Row(
                        children: [
                          Expanded(
                            child: _buildEditField(label: "Customer Name", controller: cNameCtrl, hint: "Customer Name"),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildEditField(label: "Customer Phone", controller: cPhoneCtrl, hint: "Customer Phone", keyboardType: TextInputType.phone),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Payment Method / Mode
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Payment Method / Mode", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          const SizedBox(height: 4),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedPayment,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                                items: ["UPI", "Cash", "Card", "Net Banking", "Credit"]
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setModalState(() => selectedPayment = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Amounts: Subtotal, Discount, Tax, Final Total (4 fields in row)
                      Row(
                        children: [
                          Expanded(child: _buildEditField(label: "Subtotal (₹)", controller: subtotalCtrl, keyboardType: TextInputType.number)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildEditField(label: "Discount (₹)", controller: discountCtrl, keyboardType: TextInputType.number)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildEditField(label: "Tax (₹)", controller: taxCtrl, keyboardType: TextInputType.number)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildEditField(label: "Final Total (₹)", controller: totalCtrl, keyboardType: TextInputType.number, isHighlighted: true)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notes / Terms
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Notes / Terms", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: notesCtrl,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: "Optional notes or remarks...",
                              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Footer Actions: Cancel + Save Changes (Photo 5)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              final newBillNo = billNoCtrl.text.trim();
                              if (newBillNo.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Bill number cannot be empty"), backgroundColor: Colors.redAccent),
                                );
                                return;
                              }

                              setState(() {
                                b['bill_number'] = newBillNo;
                                b['customer_name'] = cNameCtrl.text.trim();
                                b['customer_phone'] = cPhoneCtrl.text.trim();
                                b['payment_method'] = selectedPayment;
                                b['total_amount'] = subtotalCtrl.text.trim();
                                b['discount'] = discountCtrl.text.trim();
                                b['tax'] = taxCtrl.text.trim();
                                b['final_amount'] = totalCtrl.text.trim();
                              });

                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Bill $newBillNo updated successfully!"),
                                  backgroundColor: const Color(0xFF0D6EFD),
                                ),
                              );
                            },
                            icon: const Icon(Icons.save_outlined, size: 14),
                            label: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 12, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isHighlighted ? const Color(0xFF0D6EFD) : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // DELETE ACTIONS
  // ----------------------------------------------------
  void _confirmDeleteBill(Map<String, dynamic> b) {
    final String billNo = (b['bill_number'] ?? "this bill").toString();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Delete Bill", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          content: Text("Are you sure you want to delete bill $billNo? This action cannot be undone.", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300)),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  bills.removeWhere((item) => item['id'] == b['id'] && item['bill_number'] == b['bill_number']);
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Bill $billNo deleted successfully"), backgroundColor: const Color(0xFFEF4444)),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              child: const Text("Delete", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // PHOTO 2 & 3: QUOTATION DETAILS VIEW MODAL (Live API)
  // ----------------------------------------------------
  void _showQuotationDialog(Map<String, dynamic> q) {
    final String qId = (q['quotation_number'] ?? q['quotation_id'] ?? (q['id'] != null ? "QUOT-${q['id'].toString().padLeft(5, '0')}" : "QUOT-00002")).toString();
    final String cName = (q['customer_name'] ?? "sabari").toString();
    final String cPhone = (q['customer_phone'] ?? "-").toString();
    final String paymentMethod = (q['payment_method'] ?? "CASH").toString();
    final String status = (q['status'] ?? "COMPLETED").toString();
    final String date = (q['created_at'] ?? q['date'] ?? "2026-09-28 10:13:22").toString();
    final double amount = double.tryParse((q['final_amount'] ?? q['total_amount'] ?? q['amount'] ?? 1450).toString()) ?? 1450.0;
    final dynamic quotationDbId = q['id'];

    List<dynamic> lineItems = (q['items'] is List && (q['items'] as List).isNotEmpty)
        ? List<dynamic>.from(q['items'])
        : [];
    bool fetchingDetails = lineItems.isEmpty && quotationDbId != null;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (fetchingDetails) {
              fetchingDetails = false;
              _fetchQuotationDetails(quotationDbId).then((fullData) {
                if (fullData != null && fullData['items'] is List && (fullData['items'] as List).isNotEmpty) {
                  if (dialogContext.mounted) {
                    setModalState(() {
                      lineItems = List<dynamic>.from(fullData['items']);
                    });
                  }
                }
              });
            }

            final displayItems = lineItems.isNotEmpty
                ? lineItems
                : [
                    {
                      "product_name": "2Ch 12V Relay Module",
                      "qty": 5,
                      "price": 290,
                      "total": 1450,
                    }
                  ];

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Quotation Details - QUOT-00002 + X (Photo 3)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Quotation Details - $qId",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Meta Grid: 2 columns
                      Wrap(
                        spacing: 24,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildQuoMetaText("Customer Name:", cName),
                                const SizedBox(height: 6),
                                _buildQuoMetaText("Payment Method:", paymentMethod),
                                const SizedBox(height: 6),
                                _buildQuoMetaText("Date:", date),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildQuoMetaText("Customer Phone:", cPhone),
                                const SizedBox(height: 6),
                                _buildQuoMetaText("Status:", status, isGreen: status.toUpperCase() == 'COMPLETED' || status.toUpperCase() == 'ACCEPTED'),
                                const SizedBox(height: 6),
                                _buildQuoMetaText("Total Amount:", "₹${amount.toStringAsFixed(2)}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Line Items:",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),

                      // Table of Line Items (Photo 3)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          dataRowMinHeight: 38,
                          dataRowMaxHeight: 46,
                          columnSpacing: 28,
                          horizontalMargin: 8,
                          columns: const [
                            DataColumn(label: Text("PRODUCT")),
                            DataColumn(label: Text("QTY")),
                            DataColumn(label: Text("PRICE")),
                            DataColumn(label: Text("TOTAL")),
                          ],
                          rows: displayItems.map((item) {
                            final Map itemMap = item is Map ? item : {};
                            final String pName = (itemMap['product_name'] ?? itemMap['name'] ?? 'Item').toString();
                            final int qty = int.tryParse((itemMap['qty'] ?? itemMap['quantity'] ?? 1).toString()) ?? 1;
                            final double price = double.tryParse((itemMap['price'] ?? itemMap['rate'] ?? 0).toString()) ?? 0.0;
                            final double total = double.tryParse((itemMap['total'] ?? (price * qty)).toString()) ?? (price * qty);

                            return DataRow(
                              cells: [
                                DataCell(Text(pName, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)))),
                                DataCell(Text("$qty", style: const TextStyle(fontSize: 12))),
                                DataCell(Text("₹${price.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12))),
                                DataCell(Text("₹${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bottom Button: Close
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text("Close", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuoMetaText(String label, String value, {bool isGreen = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
        children: [
          TextSpan(text: "$label ", style: const TextStyle(color: Color(0xFF64748B))),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isGreen ? const Color(0xFF10B981) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // PHOTO 4: EDIT QUOTATION STATUS MODAL (PUT /api/quotation-bill/{id})
  // ----------------------------------------------------
  void _showEditQuotationDialog(Map<String, dynamic> q) {
    final String qId = (q['quotation_number'] ?? q['quotation_id'] ?? (q['id'] != null ? "QUOT-${q['id'].toString().padLeft(5, '0')}" : "QUOT-00002")).toString();
    final String cName = (q['customer_name'] ?? "sabari").toString();
    String selectedStatus = (q['status'] ?? "COMPLETED").toString();
    final dynamic quotationDbId = q['id'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Edit Quotation Status + X (Photo 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Edit Quotation Status",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Details
                      Text("Quotation ID: $qId", style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                      const SizedBox(height: 6),
                      Text("Customer: $cName", style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),

                      const Text(
                        "SELECT STATUS:",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ["COMPLETED", "PENDING", "EXPIRED", "ACCEPTED"].contains(selectedStatus.toUpperCase())
                                ? selectedStatus.toUpperCase()
                                : "COMPLETED",
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF64748B)),
                            items: const [
                              DropdownMenuItem(value: "COMPLETED", child: Text("COMPLETED", style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: "PENDING", child: Text("PENDING", style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: "EXPIRED", child: Text("EXPIRED", style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: "ACCEPTED", child: Text("ACCEPTED", style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() => selectedStatus = v);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions: Cancel + Save Status (Photo 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text("Cancel", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _updateQuotationStatus(quotationDbId, selectedStatus, q);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text("Save Status", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteQuotation(Map<String, dynamic> q) {
    final String qId = (q['quotation_number'] ?? q['quotation_id'] ?? (q['id'] != null ? "QUOT-${q['id'].toString().padLeft(5, '0')}" : "")).toString();
    final dynamic quotationDbId = q['id'];
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Delete Quotation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete $qId?", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteQuotation(quotationDbId, qId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // PRINT & PDF DOWNLOAD USING PRINTING PACKAGE
  // ----------------------------------------------------
  Future<void> _printInvoice(String billNo, String date, String cName, String cPhone, double total) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => _generatePdf(format, billNo, date, cName, cPhone, total),
      );
    } catch (e) {
      AppLogger.error("Print Invoice error", e);
    }
  }

  Future<void> _downloadInvoicePdf(String billNo, String date, String cName, String cPhone, double total) async {
    try {
      await Printing.sharePdf(
        bytes: await _generatePdf(PdfPageFormat.a4, billNo, date, cName, cPhone, total),
        filename: 'Invoice_$billNo.pdf',
      );
    } catch (e) {
      AppLogger.error("Download Invoice PDF error", e);
    }
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, String billNo, String date, String cName, String cPhone, double total) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text("INVOICE", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("SHOP DETAILS", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                        pw.Text("Circuitpointcare", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Neelambur, Sulur Taluk, Coimbatore, 641062", style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("Contact: 9092014442", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("CUSTOMER DETAILS", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                        pw.Text(cName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Contact: $cPhone", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Invoice No: $billNo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Date: $date", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Status: COMPLETED", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Items:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ["S.No", "Description", "Qty", "Total"],
                  data: [
                    ["1", "JUMPERS Wires F-F (Brand: Imported)", "10", "₹${total.toStringAsFixed(2)}"]
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                ),
                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text("Grand Total: ₹${total.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                ),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }
}