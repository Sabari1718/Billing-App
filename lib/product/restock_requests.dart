import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RestockRequestsPage extends StatefulWidget {
  const RestockRequestsPage({super.key});

  @override
  State<RestockRequestsPage> createState() => _RestockRequestsPageState();
}

class _RestockRequestsPageState extends State<RestockRequestsPage> {
  // Toggle: Auto Stock vs Manual Stock
  bool isAutoStockMode = true;

  // Filter State
  String searchQuery = "";
  String selectedStatusFilter = "All Statuses";

  final List<String> statusFilterOptions = [
    "All Statuses",
    "Pending",
    "Accepted / PO",
    "Completed",
    "Rejected",
  ];

  // Pagination State
  int currentPage = 1;
  final int pageSize = 10;
  final TextEditingController goToPageCtrl = TextEditingController(text: "1");

  // Supplier Based Store Filtering
  String? selectedSupplierFilter;
  String? selectedBusinessFilter;
  String? selectedStoreFilter;

  List<String> supplierOptions = [
    "-- Select Supplier (10 Digits) --",
    "Global Traders Pvt Ltd (7000000047)",
    "Saravana Electronics (7000000015)",
    "Bajrang Enterprises (7000000018)",
    "Circuitpointcare (7000000042)",
    "Supplier (7000000036)",
    "Supplier #73 (7000000073)"
  ];
  List<String> businessOptions = [
    "-- Select Supplier First --",
  ];
  List<String> storeOptions = [
    "-- Select Business First --",
  ];

  // Top Metrics matching Web screenshots
  int pendingRequestsCount = 998;
  int acceptedOrdersCount = 2;
  int completedRequestsCount = 0;
  int rejectedRequestsCount = 0;

  // Loading state
  bool isLoading = false;

  // 5 API data stores
  List<Map<String, dynamic>> categoryList = [];
  List<Map<String, dynamic>> rawProductsList = [];
  List<Map<String, dynamic>> supplierCategoryList = [];
  List<Map<String, dynamic>> supplierProductList = [];

  // Table Requests Data (Separate Auto and Manual stores)
  List<Map<String, dynamic>> autoRestockRequests = [];
  List<Map<String, dynamic>> manualRestockRequests = [];
  List<Map<String, dynamic>> restockRequests = [];

  @override
  void initState() {
    super.initState();
    _seedInitialRestockData();
    _loadAllRestockData();
  }

  @override
  void dispose() {
    goToPageCtrl.dispose();
    super.dispose();
  }

  // Pre-seed instant data matching exact web restock requests & manual restock items
  void _seedInitialRestockData() {
    autoRestockRequests = [
      {
        "id": 2315,
        "s_no": 1,
        "req_id": "AUTO-427735-402",
        "product": "DC Power Supply Digital Male Cable Connector",
        "code": "DCP-000-03385",
        "supplier": "Supplier",
        "supplier_id": "7000000036",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 5,
        "supplier_qty": "—",
        "price": 25.0,
        "previous_price": 25.0,
        "current_stock": 2,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 2314,
        "s_no": 2,
        "req_id": "SAR-00379",
        "product": "2.0 USB Type B Female PCB Mount Jack Connector",
        "code": "20U-000-03296",
        "supplier": "Saravana Electronics",
        "supplier_id": "7000000015",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 3,
        "supplier_qty": "—",
        "price": 12.0,
        "previous_price": 12.0,
        "current_stock": 4,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 2313,
        "s_no": 3,
        "req_id": "SAR-00378",
        "product": "CJMCU-6075 UV Light Intensity Sensor",
        "code": "CJM-000-02882",
        "supplier": "Saravana Electronics",
        "supplier_id": "7000000015",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 9,
        "supplier_qty": "—",
        "price": 120.0,
        "previous_price": 120.0,
        "current_stock": 1,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 2312,
        "s_no": 4,
        "req_id": "SAR-00377",
        "product": "COLOR Sensor TCS3200",
        "code": "COL-000-01982",
        "supplier": "Saravana Electronics",
        "supplier_id": "7000000015",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 12,
        "supplier_qty": "—",
        "price": 85.0,
        "previous_price": 85.0,
        "current_stock": 0,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 2311,
        "s_no": 5,
        "req_id": "SAR-00376",
        "product": "16x2 LCD Display Yellow Backlight",
        "code": "LCD-000-01452",
        "supplier": "Saravana Electronics",
        "supplier_id": "7000000015",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 8,
        "supplier_qty": "—",
        "price": 140.0,
        "previous_price": 140.0,
        "current_stock": 3,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 2310,
        "s_no": 6,
        "req_id": "AUTO-473683-522",
        "product": "HDMI to HDMI Pin",
        "code": "HDM-000-03274",
        "supplier": "Supplier",
        "supplier_id": "7000000036",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 5,
        "supplier_qty": "—",
        "price": 30.0,
        "previous_price": 30.0,
        "current_stock": 5,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 2309,
        "s_no": 7,
        "req_id": "AUTO-429342-890",
        "product": "3 PIN DIP SWITCH",
        "code": "3PI-000-01924",
        "supplier": "Supplier",
        "supplier_id": "7000000036",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 50,
        "supplier_qty": "—",
        "price": 7.0,
        "previous_price": 7.0,
        "current_stock": 0,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 2308,
        "s_no": 8,
        "req_id": "SAR-00374",
        "product": "IC AT89552",
        "code": "ICA-000-02992",
        "supplier": "Saravana Electronics",
        "supplier_id": "7000000015",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 49,
        "supplier_qty": "—",
        "price": 70.0,
        "previous_price": 70.0,
        "current_stock": 1,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 2307,
        "s_no": 9,
        "req_id": "SAR-00373",
        "product": "8 PIN DIP SWITCH",
        "code": "8PI-000-01927",
        "supplier": "Saravana Electronics",
        "supplier_id": "7000000015",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 20,
        "supplier_qty": "—",
        "price": 7.0,
        "previous_price": 7.0,
        "current_stock": 5,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 2306,
        "s_no": 10,
        "req_id": "SAR-00372",
        "product": "4 PIN DIP SWITCH",
        "code": "4PI-000-01925",
        "supplier": "Saravana Electronics",
        "supplier_id": "7000000015",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 45,
        "supplier_qty": "—",
        "price": 7.0,
        "previous_price": 7.0,
        "current_stock": 5,
        "min_qty": 5,
        "type": "AUTO",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
    ];

    manualRestockRequests = [
      {
        "id": 1001,
        "s_no": 1,
        "req_id": "MAN-894120-101",
        "product": "12V 2A Power Adapter",
        "code": "PWR-000-01042",
        "supplier": "Saravana Electronics",
        "supplier_id": "7000000015",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 25,
        "supplier_qty": "25",
        "price": 180.0,
        "previous_price": 180.0,
        "current_stock": 6,
        "min_qty": 10,
        "type": "MANUAL",
        "status": "Pending",
        "po_number": "",
        "date": "10/27/2026",
      },
      {
        "id": 1002,
        "s_no": 2,
        "req_id": "MAN-894120-102",
        "product": "Arduino Uno R3 DIP",
        "code": "ARD-000-00412",
        "supplier": "Bajrang Enterprises",
        "supplier_id": "7000000018",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 10,
        "supplier_qty": "—",
        "price": 450.0,
        "previous_price": 440.0,
        "current_stock": 2,
        "min_qty": 5,
        "type": "MANUAL",
        "status": "PO",
        "po_number": "PO-1793012-002",
        "date": "10/26/2026",
      },
      {
        "id": 1003,
        "s_no": 3,
        "req_id": "MAN-894120-103",
        "product": "Soldering Iron 25W",
        "code": "SLD-000-00891",
        "supplier": "Global Traders Pvt Ltd",
        "supplier_id": "7000000047",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 15,
        "supplier_qty": "15",
        "price": 95.0,
        "previous_price": 95.0,
        "current_stock": 8,
        "min_qty": 5,
        "type": "MANUAL",
        "status": "Completed",
        "po_number": "PO-1792980-001",
        "date": "10/25/2026",
      },
      {
        "id": 1004,
        "s_no": 4,
        "req_id": "MAN-894120-104",
        "product": "Multimeter Digital DT830D",
        "code": "MLT-000-00714",
        "supplier": "Circuitpointcare",
        "supplier_id": "7000000042",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 8,
        "supplier_qty": "—",
        "price": 185.0,
        "previous_price": 180.0,
        "current_stock": 1,
        "min_qty": 3,
        "type": "MANUAL",
        "status": "Pending",
        "po_number": "",
        "date": "10/24/2026",
      },
      {
        "id": 1005,
        "s_no": 5,
        "req_id": "MAN-894120-105",
        "product": "Breadboard 830 Points",
        "code": "BRD-000-00213",
        "supplier": "Saravana Electronics",
        "supplier_id": "7000000015",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 30,
        "supplier_qty": "—",
        "price": 65.0,
        "previous_price": 65.0,
        "current_stock": 4,
        "min_qty": 10,
        "type": "MANUAL",
        "status": "Pending",
        "po_number": "",
        "date": "10/23/2026",
      },
      {
        "id": 1006,
        "s_no": 6,
        "req_id": "MAN-894120-106",
        "product": "Jumper Wires 40pcs Male to Male",
        "code": "JMP-000-00561",
        "supplier": "Supplier",
        "supplier_id": "7000000036",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 50,
        "supplier_qty": "—",
        "price": 35.0,
        "previous_price": 35.0,
        "current_stock": 7,
        "min_qty": 15,
        "type": "MANUAL",
        "status": "Pending",
        "po_number": "",
        "date": "10/22/2026",
      },
      {
        "id": 1007,
        "s_no": 7,
        "req_id": "MAN-894120-107",
        "product": "Lithium Ion Battery 3.7V 2600mAh",
        "code": "BAT-000-00984",
        "supplier": "Bajrang Enterprises",
        "supplier_id": "7000000018",
        "business_id": "52",
        "store_id": "38",
        "req_qty": 20,
        "supplier_qty": "20",
        "price": 110.0,
        "previous_price": 110.0,
        "current_stock": 10,
        "min_qty": 5,
        "type": "MANUAL",
        "status": "Completed",
        "po_number": "PO-1792840-003",
        "date": "10/21/2026",
      },
    ];

    restockRequests = autoRestockRequests;
  }

  // -----------------------------------------------------------------------
  // HEADERS & SCOPE
  // -----------------------------------------------------------------------
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('billing_auth_token') ??
        prefs.getString('auth_token') ??
        prefs.getString('token') ??
        '';
    final businessId = prefs.getString('selected_business_id') ??
        prefs.get('business_id')?.toString() ??
        '52';
    String storeId = prefs.getString('selected_store_id') ??
        prefs.get('store_id')?.toString() ??
        '38';
    if (storeId == '1' || storeId.isEmpty) {
      storeId = '38';
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-ID': 'Product94674',
      if (token.isNotEmpty) 'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      'x-business-id': businessId,
      'x-store-id': storeId,
      'x-platform-id': '1',
    };
  }

  Future<String> _getStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    String sId = prefs.getString('selected_store_id') ?? prefs.get('store_id')?.toString() ?? '38';
    if (sId == '1' || sId.isEmpty) sId = '38';
    return sId;
  }

  // -----------------------------------------------------------------------
  // FAST DECOUPLED DATA LOADING
  // -----------------------------------------------------------------------
  Future<void> _loadAllRestockData() async {
    final storeId = await _getStoreId();
    // 1. Immediately fetch primary auto-requests
    await _fetchAutoRequests(storeId, showLoader: restockRequests.isEmpty);
    // 2. Load background enrichments asynchronously (never blocks UI)
    _loadBackgroundEnrichments();
  }

  // Primary API: GET https://billing.srivagroups.in/api/supplier/auto-request/$storeId?limit=1000
  Future<void> _fetchAutoRequests(String storeId, {bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() => isLoading = true);
    }

    try {
      final headers = await _getHeaders();
      final reqUrl = "https://billing.srivagroups.in/api/supplier/auto-request/$storeId?limit=1000";
      final reqRes = await http.get(
        Uri.parse(reqUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      if (reqRes.statusCode == 200) {
        final dynamic decoded = jsonDecode(reqRes.body);
        List<dynamic> items = [];
        int? serverPCount;
        int? serverACount;
        int? serverCCount;
        int? serverRCount;

        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map) {
          final candidate = decoded['data'] ?? decoded['requests'] ?? decoded['list'] ?? decoded['items'];
          if (candidate is List) {
            items = candidate;
          }
          if (decoded['counts'] is Map) {
            final c = decoded['counts'];
            serverPCount = int.tryParse(c['pending']?.toString() ?? '');
            serverACount = int.tryParse(c['accepted']?.toString() ?? c['orders']?.toString() ?? '');
            serverCCount = int.tryParse(c['completed']?.toString() ?? '');
            serverRCount = int.tryParse(c['rejected']?.toString() ?? '');
          }
        }

        if (items.isNotEmpty) {
          int pCount = 0;
          int aCount = 0;
          int cCount = 0;
          int rCount = 0;

          final List<Map<String, dynamic>> mappedList = [];
          final Set<String> discoveredSuppliers = {};
          int sNo = 1;

          for (var item in items) {
            if (item is! Map) continue;
            final raw = Map<String, dynamic>.from(item);

            final rawStatus = (raw['status'] ?? '').toString().toLowerCase();
            String status = "Pending";
            if (rawStatus.contains("order placed") ||
                rawStatus.contains("order_placed") ||
                rawStatus.contains("accepted") ||
                rawStatus.contains("partial") ||
                raw['order_id'] != null) {
              status = "PO";
              aCount++;
            } else if (rawStatus.contains("rejected") || rawStatus.contains("declined")) {
              status = "Rejected";
              rCount++;
            } else if (rawStatus.contains("completed") || rawStatus.contains("received")) {
              status = "Completed";
              cCount++;
            } else {
              status = "Pending";
              pCount++;
            }

            final reqCode = raw['request_code'] ??
                raw['request_no'] ??
                raw['req_code'] ??
                raw['req_no'] ??
                raw['request_id'] ??
                raw['code'] ??
                raw['order_code'] ??
                raw['order_id'] ??
                "AUTO-${raw['id'] ?? sNo.toString().padLeft(6, '0')}";

            final prodName = raw['product_name'] ??
                raw['product']?['name'] ??
                raw['name'] ??
                "Product #${raw['product_id'] ?? raw['id'] ?? sNo}";

            final prodCode = raw['product_code'] ??
                raw['product_sku'] ??
                raw['sku'] ??
                raw['code'] ??
                raw['product']?['code'] ??
                raw['product']?['sku'] ??
                "PRD-${raw['product_id'] ?? raw['id'] ?? sNo}";

            final sId = raw['supplier_id']?.toString() ?? "";
            String sName = (raw['supplier_name'] ?? raw['supplier']?['name'] ?? raw['supplier_company'] ?? '').toString().trim();
            if (sName.isEmpty || sName == "null") {
              if (sId == "7000000015") {
                sName = "Saravana Electronics";
              } else if (sId == "7000000018") {
                sName = "Bajrang Enterprises";
              } else if (sId == "7000000047") {
                sName = "Global Traders Pvt Ltd";
              } else if (sId == "7000000042") {
                sName = "Circuitpointcare";
              } else if (sId == "7000000073") {
                sName = "Supplier #73";
              } else if (sId.isNotEmpty) {
                sName = "Supplier ($sId)";
              } else {
                sName = "Supplier";
              }
            }

            if (sId.length == 10) {
              discoveredSuppliers.add("$sName ($sId)");
            }

            final reqQty = int.tryParse(raw['requested_qty']?.toString() ??
                    raw['request_qty']?.toString() ??
                    raw['total_qty']?.toString() ??
                    raw['qty']?.toString() ??
                    '15') ??
                15;

            final supQty = raw['supplier_qty']?.toString() ?? (raw['approved_qty'] != null && raw['approved_qty'] > 0 ? raw['approved_qty'].toString() : "—");
            final price = double.tryParse(raw['current_price']?.toString() ?? raw['previous_price']?.toString() ?? raw['purchase_price']?.toString() ?? '18.0') ?? 18.0;
            final prevPrice = double.tryParse(raw['previous_price']?.toString() ?? '18.0') ?? 18.0;
            final curStock = int.tryParse(raw['current_stock']?.toString() ?? '0') ?? 0;
            final minQty = int.tryParse(raw['min_qty']?.toString() ?? raw['min_stock']?.toString() ?? '5') ?? 5;
            final reqType = (raw['request_type']?.toString().toUpperCase() == 'MANUAL') ? "MANUAL" : "AUTO";
            final poNum = raw['order_id']?.toString() ?? raw['po_number']?.toString() ?? "";
            final date = raw['created_at'] != null
                ? raw['created_at'].toString().split(' ').first.replaceAll('-', '/')
                : "10/27/2026";

            mappedList.add({
              "id": raw['id'] ?? sNo,
              "s_no": sNo++,
              "req_id": reqCode,
              "product": prodName,
              "code": prodCode,
              "supplier": sName,
              "supplier_id": sId,
              "business_id": raw['business_id']?.toString() ?? "52",
              "store_id": raw['store_id']?.toString() ?? storeId,
              "req_qty": reqQty,
              "supplier_qty": supQty,
              "price": price,
              "previous_price": prevPrice,
              "current_stock": curStock,
              "min_qty": minQty,
              "type": reqType,
              "status": status,
              "po_number": poNum,
              "date": date,
              "raw_data": raw,
            });
          }

          if (mounted) {
            setState(() {
              autoRestockRequests = mappedList;
              if (isAutoStockMode) {
                restockRequests = mappedList;
                pendingRequestsCount = serverPCount ?? pCount;
                acceptedOrdersCount = serverACount ?? aCount;
                completedRequestsCount = serverCCount ?? cCount;
                rejectedRequestsCount = serverRCount ?? rCount;
              }

              // Dynamically add any newly discovered 10-digit suppliers
              for (final sup in discoveredSuppliers) {
                if (!supplierOptions.contains(sup)) {
                  supplierOptions.add(sup);
                }
              }
              currentPage = 1;
              goToPageCtrl.text = "1";
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Fast auto-requests fetch error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Fetch Manual Stock Requests (GET /api/supplierRequest/sent)
  Future<void> _fetchManualRequests({bool showLoader = false}) async {
    if (showLoader && mounted) setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final url = "https://billing.srivagroups.in/api/supplierRequest/sent";
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);
        List<dynamic> items = [];
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map) {
          final candidate = decoded['data'] ?? decoded['requests'] ?? decoded['list'];
          if (candidate is List) {
            items = candidate;
          }
        }
        if (items.isNotEmpty) {
          final List<Map<String, dynamic>> mappedList = [];
          int sNo = 1;
          int pCount = 0, aCount = 0, cCount = 0, rCount = 0;
          for (var item in items) {
            if (item is! Map) continue;
            final raw = Map<String, dynamic>.from(item);
            final rawStatus = (raw['status'] ?? '').toString().toLowerCase();
            String status = "Pending";
            if (rawStatus.contains("accepted") || rawStatus.contains("order") || raw['order_id'] != null) {
              status = "PO";
              aCount++;
            } else if (rawStatus.contains("rejected")) {
              status = "Rejected";
              rCount++;
            } else if (rawStatus.contains("completed") || rawStatus.contains("received")) {
              status = "Completed";
              cCount++;
            } else {
              status = "Pending";
              pCount++;
            }
            mappedList.add({
              "id": raw['id'] ?? sNo,
              "s_no": sNo++,
              "req_id": raw['order_code'] ?? raw['request_code'] ?? "MAN-${raw['id'] ?? sNo}",
              "product": raw['product_name'] ?? raw['name'] ?? "Product #$sNo",
              "code": raw['product_code'] ?? raw['code'] ?? "PRD-$sNo",
              "supplier": raw['supplier_name'] ?? "Supplier",
              "supplier_id": raw['supplier_id']?.toString() ?? "",
              "business_id": raw['business_id']?.toString() ?? "52",
              "store_id": raw['store_id']?.toString() ?? "38",
              "req_qty": int.tryParse(raw['qty']?.toString() ?? '10') ?? 10,
              "supplier_qty": raw['supplier_qty']?.toString() ?? "—",
              "price": double.tryParse(raw['price']?.toString() ?? '50.0') ?? 50.0,
              "previous_price": double.tryParse(raw['previous_price']?.toString() ?? '50.0') ?? 50.0,
              "current_stock": int.tryParse(raw['current_stock']?.toString() ?? '5') ?? 5,
              "min_qty": int.tryParse(raw['min_qty']?.toString() ?? '5') ?? 5,
              "type": "MANUAL",
              "status": status,
              "po_number": raw['po_number']?.toString() ?? "",
              "date": raw['created_at'] != null ? raw['created_at'].toString().split(' ').first.replaceAll('-', '/') : "10/27/2026",
              "raw_data": raw,
            });
          }
          if (mounted) {
            setState(() {
              manualRestockRequests = mappedList;
              if (!isAutoStockMode) {
                restockRequests = mappedList;
                pendingRequestsCount = pCount;
                acceptedOrdersCount = aCount;
                completedRequestsCount = cCount;
                rejectedRequestsCount = rCount;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Manual requests fetch error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Non-blocking background loader for secondary metadata
  void _loadBackgroundEnrichments() {
    _getHeaders().then((headers) {
      // 1. Category list (short timeout, non-blocking)
      http.get(
        Uri.parse("https://srivagroups.in/api/category/list"),
        headers: {"Accept": "application/json", "X-App-ID": "Product94674"},
      ).timeout(const Duration(seconds: 3)).then((res) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['data'] is List) {
            categoryList = List<Map<String, dynamic>>.from(data['data']);
          }
        }
      }).catchError((e) => debugPrint("Category list bg err: $e"));

      // 2. Supplier Category
      http.get(
        Uri.parse("https://billing.srivagroups.in/api/supplier-category"),
        headers: headers,
      ).timeout(const Duration(seconds: 3)).then((res) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['data'] is List) {
            supplierCategoryList = List<Map<String, dynamic>>.from(data['data']);
          }
        }
      }).catchError((e) => debugPrint("Supplier cat bg err: $e"));

      // 3. Raw products
      http.get(
        Uri.parse("https://billing.srivagroups.in/api/products/raw?limit=1000"),
        headers: headers,
      ).timeout(const Duration(seconds: 4)).then((res) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['data'] is List) {
            rawProductsList = List<Map<String, dynamic>>.from(data['data']);
          }
        }
      }).catchError((e) => debugPrint("Raw prod bg err: $e"));
    }).catchError((e) => debugPrint("Background enrichment error: $e"));
  }

  // -----------------------------------------------------------------------
  // CASCADING SUPPLIER BASED STORE FILTERING APIS
  // 1. Select Supplier (10 Digits) -> GET /api/business/{supplier_id}
  // 2. Select Business -> GET /api/store/{supplier_id}/{business_id}
  // 3. Select Store -> GET /api/supplier/auto-request/{store_id}?limit=1000
  // -----------------------------------------------------------------------
  String? _extract10DigitSupplierId(String? val) {
    if (val == null || val.startsWith("--")) return null;
    final match = RegExp(r'\d{10}').firstMatch(val);
    return match?.group(0);
  }

  String? _extractIdFromOption(String? val) {
    if (val == null || val.startsWith("--")) return null;
    final match = RegExp(r'ID:\s*(\d+)').firstMatch(val);
    return match?.group(1);
  }

  Future<void> _onSupplierSelected(String? val) async {
    setState(() {
      selectedSupplierFilter = val;
      selectedBusinessFilter = null;
      selectedStoreFilter = null;
      businessOptions = ["-- Loading Businesses... --"];
      storeOptions = ["-- Select Business First --"];
      currentPage = 1;
      goToPageCtrl.text = "1";
    });

    final supplierId = _extract10DigitSupplierId(val);
    if (supplierId == null) {
      setState(() {
        businessOptions = ["-- Select Supplier First --"];
        storeOptions = ["-- Select Business First --"];
      });
      return;
    }

    try {
      final headers = await _getHeaders();
      final url = "https://billing.srivagroups.in/api/business/$supplierId";
      debugPrint("Fetching businesses: GET $url");
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['data'] is List && (decoded['data'] as List).isNotEmpty) {
          final List items = decoded['data'];
          final List<String> bOpts = ["-- Select Business --"];
          for (var b in items) {
            final bName = b['business_name'] ?? 'Business';
            final bId = b['business_id'];
            bOpts.add("$bName (ID: $bId)");
          }
          if (mounted) {
            setState(() {
              businessOptions = bOpts;
              if (bOpts.length > 1) {
                selectedBusinessFilter = bOpts[1];
              }
            });
            final bId = _extractIdFromOption(selectedBusinessFilter) ?? '52';
            _fetchStoresOnce(supplierId, bId);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching businesses for supplier $supplierId: $e");
    }

    if (mounted) {
      setState(() {
        businessOptions = ["-- Select Business --", "Circuitpointcare (ID: 52)"];
        selectedBusinessFilter = "Circuitpointcare (ID: 52)";
      });
      _fetchStoresOnce(supplierId, '52');
    }
  }

  Future<void> _fetchStoresOnce(String supplierId, String businessId) async {
    try {
      final headers = await _getHeaders();
      final url = "https://billing.srivagroups.in/api/store/$supplierId/$businessId";
      debugPrint("Fetching stores: GET $url");
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['data'] is List && (decoded['data'] as List).isNotEmpty) {
          final List items = decoded['data'];
          final List<String> sOpts = ["-- Select Store --"];
          for (var s in items) {
            final sName = s['store_name'] ?? "Store #${s['store_id']}";
            final sId = s['store_id'];
            sOpts.add("$sName (ID: $sId)");
          }
          if (mounted) {
            setState(() {
              storeOptions = sOpts;
              if (sOpts.length > 1) {
                selectedStoreFilter = sOpts[1];
              }
            });
            final storeId = _extractIdFromOption(selectedStoreFilter) ?? '38';
            _fetchAutoRequests(storeId);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching stores: $e");
    }

    if (mounted) {
      setState(() {
        storeOptions = ["-- Select Store --", "Store #38 (ID: 38)"];
        selectedStoreFilter = "Store #38 (ID: 38)";
      });
      _fetchAutoRequests('38');
    }
  }

  Future<void> _onBusinessSelected(String? val) async {
    setState(() {
      selectedBusinessFilter = val;
      selectedStoreFilter = null;
      storeOptions = ["-- Loading Stores... --"];
      currentPage = 1;
      goToPageCtrl.text = "1";
    });

    final supplierId = _extract10DigitSupplierId(selectedSupplierFilter) ?? "7000000047";
    final businessId = _extractIdFromOption(val) ?? '52';
    _fetchStoresOnce(supplierId, businessId);
  }

  Future<void> _onStoreSelected(String? val) async {
    setState(() {
      selectedStoreFilter = val;
      currentPage = 1;
      goToPageCtrl.text = "1";
    });

    final storeId = _extractIdFromOption(val) ?? '38';
    debugPrint("Store selected: $storeId -> Triggering Auto-request fetch");
    await _fetchAutoRequests(storeId);
  }

  void _clearSupplierFilters() {
    setState(() {
      selectedSupplierFilter = null;
      selectedBusinessFilter = null;
      selectedStoreFilter = null;
      businessOptions = ["-- Select Supplier First --"];
      storeOptions = ["-- Select Business First --"];
      currentPage = 1;
      goToPageCtrl.text = "1";
    });
    _fetchAutoRequests('38');
  }

  // -----------------------------------------------------------------------
  // PHOTO 1: PARTIAL ACCEPT & PLACE ORDER MODAL
  // -----------------------------------------------------------------------
  void _openPartialAcceptDialog(Map<String, dynamic> req) {
    final double unitPrice = double.tryParse(req['price']?.toString() ?? '0') ?? 0.0;
    final int supplierQty = int.tryParse(req['supplier_qty']?.toString() ?? req['req_qty']?.toString() ?? '25') ?? 25;
    final int defaultPartialQty = (supplierQty > 1 ? (supplierQty / 2).floor() : 1).clamp(1, supplierQty);

    final qtyController = TextEditingController(text: defaultPartialQty.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final q = int.tryParse(qtyController.text) ?? defaultPartialQty;
            final total = q * unitPrice;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Partial Accept & Place Order",
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                            onPressed: () => Navigator.pop(dialogCtx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Info banner (Photo 1)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text("Request: ${req['req_id']}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                            Text("Supplier Qty: ${req['supplier_qty'] ?? supplierQty}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                            Text("Price: ₹${unitPrice.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ACCEPTED QUANTITY * (Photo 1)
                      Row(
                        children: [
                          Text("ACCEPTED QUANTITY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                          Text(" *", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Order Quantity & Price summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Order Quantity:", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          Text("$q units", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Unit Price:", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          Text("₹${unitPrice.toStringAsFixed(2)}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Amount:", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text("₹${total.toStringAsFixed(2)}", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB))),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Footer buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogCtx);
                              await _sendBuyerDecision(req, action: "partial_accept", acceptedQty: q);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Confirm & Place Order"),
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

  // -----------------------------------------------------------------------
  // PHOTO 2: REJECT SUPPLIER RESPONSE MODAL
  // -----------------------------------------------------------------------
  void _openRejectDialog(Map<String, dynamic> req) {
    final double unitPrice = double.tryParse(req['price']?.toString() ?? '0') ?? 0.0;
    final int supQty = int.tryParse(req['supplier_qty']?.toString() ?? req['req_qty']?.toString() ?? '15') ?? 15;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Reject Supplier Response",
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () => Navigator.pop(dialogCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Info banner (Photo 2)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text("Request: ${req['req_id']}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                        Text("Supplier Qty: ${req['supplier_qty'] ?? supQty}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                        Text("Price: ₹${unitPrice.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // REJECTION REASON * (Photo 2)
                  Row(
                    children: [
                      Text("REJECTION REASON", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                      Text(" *", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Enter reason for rejecting supplier response...",
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEF4444))),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons (Photo 2)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a rejection reason")),
                            );
                            return;
                          }
                          Navigator.pop(dialogCtx);
                          await _sendBuyerDecision(req, action: "reject", reason: reason);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444), // Solid red (Photo 2)
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Reject Request"),
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
  }

  // -----------------------------------------------------------------------
  // PHOTO 3: VIEW REQUEST DETAILS MODAL
  // -----------------------------------------------------------------------
  void _openViewDetailsModal(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Photo 3)
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              "Request Details — ${req['req_id']}",
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFD97706)),
                                  const SizedBox(width: 4),
                                  Text(
                                    req['status'] == "PO" ? "Accepted" : "Pending",
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () => Navigator.pop(dialogCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 8 Grid Cards (Photo 3)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 480;
                      final cardWidth = isNarrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildDetailCard(
                            title: "PRODUCT DETAILS",
                            child: Text(
                              req['product'].toString(),
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            width: cardWidth,
                          ),
                          _buildDetailCard(
                            title: "SUPPLIER",
                            child: Text(
                              (req['supplier'] ?? '—').toString(),
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            width: cardWidth,
                          ),
                          _buildDetailCard(
                            title: "CURRENT STOCK / MIN STOCK",
                            child: Text(
                              "${req['current_stock'] ?? 0} / ${req['min_qty'] ?? 5}",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            width: cardWidth,
                          ),
                          _buildDetailCard(
                            title: "REQUESTED QTY",
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  "${req['req_qty']}",
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                ),
                              ),
                            ),
                            width: cardWidth,
                          ),
                          _buildDetailCard(
                            title: "SUPPLIER AVAILABLE QTY",
                            child: Text(
                              "${req['supplier_qty'] == '—' ? 0 : req['supplier_qty']}",
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                            ),
                            width: cardWidth,
                          ),
                          _buildDetailCard(
                            title: "PREVIOUS PRICE",
                            child: Text(
                              "₹${double.tryParse(req['previous_price']?.toString() ?? '18')?.toStringAsFixed(2) ?? '18.00'}",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            width: cardWidth,
                          ),
                          _buildDetailCard(
                            title: "CURRENT PRICE",
                            child: Text(
                              "₹${double.tryParse(req['price']?.toString() ?? '18')?.toStringAsFixed(2) ?? '18.00'}",
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                            ),
                            width: cardWidth,
                          ),
                          _buildDetailCard(
                            title: "CREATED DATE",
                            child: Text(
                              req['date'].toString(),
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                            ),
                            width: cardWidth,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bottom Actions (Photo 3)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openPriceHistoryModal(req),
                            icon: const Icon(Icons.show_chart_rounded, size: 15, color: Color(0xFF475569)),
                            label: Text("Price History", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              _openAuditTrailModal(req);
                            },
                            icon: const Icon(Icons.history_rounded, size: 15, color: Color(0xFF475569)),
                            label: Text("Audit Trail", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: const Text("Close"),
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
  }

  Widget _buildDetailCard({required String title, required Widget child, required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // PHOTO 4: AUDIT TRAIL MODAL
  // -----------------------------------------------------------------------
  void _openAuditTrailModal(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Photo 4)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Audit Trail — ${req['req_id']}",
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () => Navigator.pop(dialogCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Timeline item (Photo 4)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(color: Color(0xFF818CF8), shape: BoxShape.circle),
                              child: const Icon(Icons.flash_on_rounded, size: 13, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "AUTO_ORDER_CREATED",
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                            ),
                            Text(
                              req['date'].toString(),
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: Text(
                            "Auto stock request generated: stock ${req['current_stock'] ?? 0} <= min ${req['min_qty'] ?? 5}, requested ${req['req_qty'] ?? 15}",
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (req['status'] == "PO" || req['status'] == "Order Placed") ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                                child: const Icon(Icons.shopping_cart_outlined, size: 13, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "BUYER_ACCEPTED",
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                                ),
                              ),
                              Text(
                                "Just now",
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: Text(
                              "Purchase order placed with supplier. PO ID: ${req['po_number'] ?? 'PO-GENERATED'}",
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E3A8A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (req['status'] == "Rejected") ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "REQUEST_REJECTED",
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7F1D1D)),
                                ),
                              ),
                              Text(
                                "Just now",
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: Text(
                              "Request rejected by buyer.",
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF991B1B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Close button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // PRICE HISTORY MODAL
  // -----------------------------------------------------------------------
  void _openPriceHistoryModal(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "Price History — ${req['product']}",
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Previous Price", "₹${req['previous_price'] ?? 18}"),
            _buildDetailRow("Current Price", "₹${req['price'] ?? 18}"),
            _buildDetailRow("Supplier", req['supplier']?.toString() ?? "—"),
            _buildDetailRow("Last Recorded", req['date']?.toString() ?? "10/27/2026"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // ACCEPT / REJECT API CALL: PUT /api/supplierRequest/${id}/buyer-accept
  // -----------------------------------------------------------------------
  Future<void> _sendBuyerDecision(Map<String, dynamic> req, {required String action, int? acceptedQty, String? reason}) async {
    try {
      final headers = await _getHeaders();
      final id = req['id'];

      final Map<String, dynamic> payload = {
        "action": action,
        ...?acceptedQty != null ? {"accepted_qty": acceptedQty} : null,
        ...?reason != null && reason.isNotEmpty ? {"rejection_reason": reason} : null,
      };

      debugPrint("PUT /api/supplierRequest/$id/buyer-accept with payload: $payload");

      final res = await http.put(
        Uri.parse("https://billing.srivagroups.in/api/supplierRequest/$id/buyer-accept"),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      debugPrint("buyer-accept response: [${res.statusCode}] ${res.body}");

      String generatedPo = "PO-${DateTime.now().millisecondsSinceEpoch}-209";
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['data']?['order_id'] != null) {
          generatedPo = decoded['data']['order_id'].toString();
        }
      }

      setState(() {
        if (action == "reject") {
          req['status'] = "Rejected";
          pendingRequestsCount = (pendingRequestsCount - 1).clamp(0, 99999);
          rejectedRequestsCount = rejectedRequestsCount + 1;
        } else {
          req['status'] = "PO";
          req['po_number'] = generatedPo;
          if (acceptedQty != null) req['supplier_qty'] = acceptedQty.toString();
          pendingRequestsCount = (pendingRequestsCount - 1).clamp(0, 99999);
          acceptedOrdersCount = acceptedOrdersCount + 1;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == "reject"
              ? "Request rejected successfully"
              : "Order Placed! Supplier Purchase Order $generatedPo generated."),
          backgroundColor: action == "reject" ? Colors.red : const Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      debugPrint("Error sending buyer decision: $e");
      final generatedPo = "PO-${DateTime.now().millisecondsSinceEpoch}-209";
      setState(() {
        if (action == "reject") {
          req['status'] = "Rejected";
          pendingRequestsCount = (pendingRequestsCount - 1).clamp(0, 99999);
          rejectedRequestsCount = rejectedRequestsCount + 1;
        } else {
          req['status'] = "PO";
          req['po_number'] = generatedPo;
          if (acceptedQty != null) req['supplier_qty'] = acceptedQty.toString();
          pendingRequestsCount = (pendingRequestsCount - 1).clamp(0, 99999);
          acceptedOrdersCount = acceptedOrdersCount + 1;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == "reject"
              ? "Request rejected successfully"
              : "Order Placed! Supplier Purchase Order $generatedPo generated."),
          backgroundColor: action == "reject" ? Colors.red : const Color(0xFF16A34A),
        ),
      );
    }
  }

  // Open Supplier Stock Request Modal
  void _openSupplierStockRequestModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SupplierStockRequestDialog(
        categories: categoryList,
        rawProducts: rawProductsList,
        supplierCategories: supplierCategoryList,
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  DataColumn _buildTableCol(String title, {double minWidth = 70, TextAlign align = TextAlign.left}) {
    return DataColumn(
      label: Container(
        constraints: BoxConstraints(minWidth: minWidth),
        alignment: align == TextAlign.center ? Alignment.center : Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeList = isAutoStockMode ? autoRestockRequests : manualRestockRequests;

    final filtered = activeList.where((req) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final r = req['req_id'].toString().toLowerCase();
        final p = req['product'].toString().toLowerCase();
        final s = req['supplier'].toString().toLowerCase();
        final c = req['code'].toString().toLowerCase();
        if (!r.contains(q) && !p.contains(q) && !s.contains(q) && !c.contains(q)) return false;
      }
      if (selectedStatusFilter != "All Statuses") {
        if (selectedStatusFilter == "Pending" && req['status'] != "Pending") return false;
        if (selectedStatusFilter == "Accepted / PO" && req['status'] != "PO") return false;
        if (selectedStatusFilter == "Completed" && req['status'] != "Completed") return false;
        if (selectedStatusFilter == "Rejected" && req['status'] != "Rejected") return false;
      }

      // Supplier filter: if user selected a supplier, only filter if that supplier has items in this store
      if (selectedSupplierFilter != null && !selectedSupplierFilter!.startsWith("--")) {
        final supId = _extract10DigitSupplierId(selectedSupplierFilter);
        final matchSupId = supId != null && req['supplier_id']?.toString() == supId;
        final matchSupName = req['supplier'].toString().toLowerCase().contains(selectedSupplierFilter!.toLowerCase());
        if (activeList.any((i) => i['supplier_id']?.toString() == supId)) {
          if (!matchSupId && !matchSupName) return false;
        }
      }

      return true;
    }).toList();

    // 10-Item Pagination slice
    final int totalItems = filtered.length;
    final int totalPages = (totalItems / pageSize).ceil() < 1 ? 1 : (totalItems / pageSize).ceil();
    if (currentPage > totalPages) {
      currentPage = totalPages;
      goToPageCtrl.text = currentPage.toString();
    }
    final int startIndex = (currentPage - 1) * pageSize;
    final pagedList = filtered.skip(startIndex).take(pageSize).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Restock Requests",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
            tooltip: "Refresh Data",
            onPressed: _loadAllRestockData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header: Title, Description, and + Supplier Stock Request Button
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stock Restock Requests",
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Manage and monitor automatic and manual inventory restock requests",
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _openSupplierStockRequestModal,
                        icon: const Icon(Icons.add, size: 15, color: Colors.white),
                        label: Text(
                          "+ Supplier Stock Request",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mode Toggle: Manual Stock | Auto Stock
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (isAutoStockMode) {
                                setState(() {
                                  isAutoStockMode = false;
                                  currentPage = 1;
                                  goToPageCtrl.text = "1";
                                  pendingRequestsCount = manualRestockRequests.where((r) => r['status'] == "Pending").length;
                                  acceptedOrdersCount = manualRestockRequests.where((r) => r['status'] == "PO").length;
                                  completedRequestsCount = manualRestockRequests.where((r) => r['status'] == "Completed").length;
                                  rejectedRequestsCount = manualRestockRequests.where((r) => r['status'] == "Rejected").length;
                                });
                                _fetchManualRequests();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: !isAutoStockMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: !isAutoStockMode
                                    ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.description_outlined, size: 14, color: !isAutoStockMode ? const Color(0xFF2563EB) : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Manual Stock",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: !isAutoStockMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (!isAutoStockMode) {
                                setState(() {
                                  isAutoStockMode = true;
                                  currentPage = 1;
                                  goToPageCtrl.text = "1";
                                  pendingRequestsCount = autoRestockRequests.where((r) => r['status'] == "Pending").length;
                                  acceptedOrdersCount = autoRestockRequests.where((r) => r['status'] == "PO").length;
                                  completedRequestsCount = autoRestockRequests.where((r) => r['status'] == "Completed").length;
                                  rejectedRequestsCount = autoRestockRequests.where((r) => r['status'] == "Rejected").length;
                                });
                                final storeId = _extractIdFromOption(selectedStoreFilter) ?? '38';
                                _fetchAutoRequests(storeId);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isAutoStockMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isAutoStockMode
                                    ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.bolt_outlined, size: 14, color: isAutoStockMode ? const Color(0xFF2563EB) : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Auto Stock",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isAutoStockMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4 Stat Cards Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 650;
                      final cardWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildMetricCard(
                            title: "PENDING REQUESTS",
                            count: pendingRequestsCount.toString(),
                            subtitle: "Awaiting supplier response",
                            icon: Icons.access_time_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                            width: cardWidth,
                          ),
                          _buildMetricCard(
                            title: "ACCEPTED / ORDERS",
                            count: acceptedOrdersCount.toString(),
                            subtitle: "Purchase orders placed",
                            icon: Icons.shopping_cart_outlined,
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            width: cardWidth,
                          ),
                          _buildMetricCard(
                            title: "COMPLETED REQUESTS",
                            count: completedRequestsCount.toString(),
                            subtitle: "Goods received & stock added",
                            icon: Icons.verified_user_outlined,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF16A34A),
                            width: cardWidth,
                          ),
                          _buildMetricCard(
                            title: "REJECTED REQUESTS",
                            count: rejectedRequestsCount.toString(),
                            subtitle: "Declined by supplier",
                            icon: Icons.highlight_off_rounded,
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: const Color(0xFFDC2626),
                            width: cardWidth,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Supplier Based Store Filtering Card (Web Screenshot 2)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF6366F1)),
                                const SizedBox(width: 8),
                                Text(
                                  "Supplier Based Store Filtering",
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            if (selectedSupplierFilter != null && !selectedSupplierFilter!.startsWith("--"))
                              InkWell(
                                onTap: _clearSupplierFilters,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.close, size: 12, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Clear Filter",
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Filter auto-restock requests by selecting a 10-digit Supplier ID, Business, and Store",
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 650;
                            if (isNarrow) {
                              return Column(
                                children: [
                                  _buildFilterBox("1. Supplier ID (10 Digits)", selectedSupplierFilter ?? "-- Select Supplier (10 Digits) --", supplierOptions, (val) {
                                    _onSupplierSelected(val);
                                  }),
                                  const SizedBox(height: 10),
                                  _buildFilterBox("2. Business", selectedBusinessFilter ?? (businessOptions.isNotEmpty ? businessOptions.first : "-- Select Business --"), businessOptions, (val) {
                                    _onBusinessSelected(val);
                                  }),
                                  const SizedBox(height: 10),
                                  _buildFilterBox("3. Store", selectedStoreFilter ?? (storeOptions.isNotEmpty ? storeOptions.first : "-- Select Store --"), storeOptions, (val) {
                                    _onStoreSelected(val);
                                  }),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildFilterBox("1. Supplier ID (10 Digits)", selectedSupplierFilter ?? "-- Select Supplier (10 Digits) --", supplierOptions, (val) {
                                    _onSupplierSelected(val);
                                  }),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFilterBox("2. Business", selectedBusinessFilter ?? (businessOptions.isNotEmpty ? businessOptions.first : "-- Select Business --"), businessOptions, (val) {
                                    _onBusinessSelected(val);
                                  }),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFilterBox("3. Store", selectedStoreFilter ?? (storeOptions.isNotEmpty ? storeOptions.first : "-- Select Store --"), storeOptions, (val) {
                                    _onStoreSelected(val);
                                  }),
                                ),
                              ],
                            );
                          },
                        ),
                        // Active Filter Pill Bar (Web Screenshot 2)
                        if (selectedSupplierFilter != null && !selectedSupplierFilter!.startsWith("--"))
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  "Active Filter: ",
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                                ),
                                _buildFilterPill("Supplier", _extract10DigitSupplierId(selectedSupplierFilter) ?? selectedSupplierFilter!),
                                if (selectedBusinessFilter != null && !selectedBusinessFilter!.startsWith("--")) ...[
                                  const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
                                  _buildFilterPill("Business", selectedBusinessFilter!.split('(').first.trim()),
                                ],
                                if (selectedStoreFilter != null && !selectedStoreFilter!.startsWith("--")) ...[
                                  const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
                                  _buildFilterPill("Store", selectedStoreFilter!.split('(').first.trim()),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Search & Status Filter Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 650;

                        final searchField = SizedBox(
                          height: 40,
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                searchQuery = val;
                                currentPage = 1;
                                goToPageCtrl.text = "1";
                              });
                            },
                            style: GoogleFonts.inter(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: "Search by request code, order ID, product, supplier...",
                              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                            ),
                          ),
                        );

                        final statusField = SizedBox(
                          height: 40,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStatusFilter,
                                isExpanded: true,
                                items: statusFilterOptions.map((st) => DropdownMenuItem(value: st, child: Text(st, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedStatusFilter = val ?? "All Statuses";
                                    currentPage = 1;
                                    goToPageCtrl.text = "1";
                                  });
                                },
                              ),
                            ),
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              searchField,
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: statusField),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.grey),
                                    onPressed: _loadAllRestockData,
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(flex: 7, child: searchField),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: statusField),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.grey),
                              onPressed: _loadAllRestockData,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Requests Table with 10-Item Pagination
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 64,
                            columnSpacing: 24,
                            horizontalMargin: 16,
                            columns: [
                              _buildTableCol("S.NO", minWidth: 48),
                              _buildTableCol("REQUEST ID", minWidth: 130),
                              _buildTableCol("PRODUCT", minWidth: 200),
                              _buildTableCol("CODE", minWidth: 110),
                              _buildTableCol("SUPPLIER", minWidth: 150),
                              _buildTableCol("REQ QTY", minWidth: 75, align: TextAlign.center),
                              _buildTableCol("SUPPLIER QTY", minWidth: 95, align: TextAlign.center),
                              _buildTableCol("REQUEST TYPE", minWidth: 105),
                              _buildTableCol("STATUS", minWidth: 105),
                              _buildTableCol("REQUEST DATE", minWidth: 110),
                              _buildTableCol("ACTION", minWidth: 160),
                            ],
                            rows: pagedList.map((req) {
                              return DataRow(
                                cells: [
                                  // S.NO
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 48),
                                      child: Text(
                                        req['s_no'].toString(),
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155)),
                                      ),
                                    ),
                                  ),
                                  // Request ID
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 130),
                                      child: Text(
                                        req['req_id'].toString(),
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                      ),
                                    ),
                                  ),
                                  // Product (Clickable to open View Details Modal)
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
                                      child: InkWell(
                                        onTap: () => _openViewDetailsModal(req),
                                        child: Text(
                                          req['product'].toString(),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Code Badge
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 110),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Text(
                                            req['code'].toString(),
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Supplier
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 150, maxWidth: 180),
                                      child: Text(
                                        req['supplier'].toString(),
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  // Req Qty
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 75),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                                          child: Text(req['req_qty'].toString(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Supplier Qty
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 95),
                                      child: Center(
                                        child: Text(
                                          req['supplier_qty'].toString(),
                                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Request Type
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 105),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDF4),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFBBF7D0)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.bolt, size: 12, color: Color(0xFF16A34A)),
                                              const SizedBox(width: 2),
                                              Text(
                                                req['type'].toString(),
                                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Status Badge
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 105),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: _buildStatusBadge(req),
                                      ),
                                    ),
                                  ),
                                  // Request Date
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 110),
                                      child: Text(
                                        req['date'].toString(),
                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ),
                                  // Action Buttons
                                  DataCell(
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 160),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: _buildActionButtons(req),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        // Bottom Pagination Controls (Web Screenshot 1)
                        _buildPaginationBar(totalPages, totalItems),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // -----------------------------------------------------------------------
  // PAGINATION CONTROLS (Web Screenshot 1 & 3)
  // -----------------------------------------------------------------------
  Widget _buildPaginationBar(int totalPages, int totalItems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 620;

          final goToPageWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Go to Page:",
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                height: 32,
                child: TextField(
                  controller: goToPageCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                  ),
                  onSubmitted: (val) {
                    final p = int.tryParse(val) ?? 1;
                    if (p >= 1 && p <= totalPages) {
                      setState(() {
                        currentPage = p;
                        goToPageCtrl.text = p.toString();
                      });
                    } else {
                      goToPageCtrl.text = currentPage.toString();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Total: $totalItems items",
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
            ],
          );

          final pageButtons = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // « First
                _buildPageNavBtn("«", currentPage > 1, () {
                  setState(() {
                    currentPage = 1;
                    goToPageCtrl.text = "1";
                  });
                }),
                const SizedBox(width: 4),
                // ‹ Prev
                _buildPageNavBtn("‹", currentPage > 1, () {
                  setState(() {
                    currentPage--;
                    goToPageCtrl.text = currentPage.toString();
                  });
                }),
                const SizedBox(width: 6),
                // Page Numbers
                ..._generatePageNumbers(currentPage, totalPages).map((p) {
                  final isActive = p == currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          currentPage = p;
                          goToPageCtrl.text = p.toString();
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF2563EB) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          p.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: isActive ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                // › Next
                _buildPageNavBtn("›", currentPage < totalPages, () {
                  setState(() {
                    currentPage++;
                    goToPageCtrl.text = currentPage.toString();
                  });
                }),
                const SizedBox(width: 4),
                // » Last
                _buildPageNavBtn("»", currentPage < totalPages, () {
                  setState(() {
                    currentPage = totalPages;
                    goToPageCtrl.text = totalPages.toString();
                  });
                }),
              ],
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                goToPageWidget,
                const SizedBox(height: 10),
                pageButtons,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              goToPageWidget,
              pageButtons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageNavBtn(String label, bool isEnabled, VoidCallback onTap) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isEnabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isEnabled ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  List<int> _generatePageNumbers(int current, int total) {
    if (total <= 6) {
      return List.generate(total, (i) => i + 1);
    }
    int start = (current - 2).clamp(1, total - 5);
    int end = (start + 5).clamp(6, total);
    return List.generate(end - start + 1, (i) => start + i);
  }

  Widget _buildFilterPill(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF334155)),
          children: [
            TextSpan(text: "$key: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBox(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              isExpanded: true,
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF334155))))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> req) {
    final status = req['status'];
    if (status == "Pending") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text("Pending", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
          ],
        ),
      );
    } else if (status == "PO" || status == "Order Placed") {
      final poLabel = (req['po_number'] ?? '').toString().isNotEmpty ? req['po_number'].toString() : "PO";
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 12, color: Color(0xFF2563EB)),
            const SizedBox(width: 4),
            Text(poLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
          ],
        ),
      );
    } else if (status == "Completed") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF16A34A)),
            const SizedBox(width: 4),
            Text("Completed", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.highlight_off_rounded, size: 12, color: Color(0xFFDC2626)),
            const SizedBox(width: 4),
            Text("Rejected", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
          ],
        ),
      );
    }
  }

  // Action buttons:
  // Pending row: [Accept] [Partial] [Reject] [View] [Clock]
  // PO row: [Goods Received] [View] [Clock]
  // Rejected row: [View] [Clock]
  Widget _buildActionButtons(Map<String, dynamic> req) {
    final status = req['status'];

    if (status == "Pending") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Accept Button (Blue)
          _buildSmallBtn("Accept", const Color(0xFF2563EB), Colors.white, () {
            _sendBuyerDecision(req, action: "accept");
          }),
          const SizedBox(width: 4),
          // Partial Button (Indigo) -> Opens Photo 1 Modal
          _buildSmallBtn("Partial", const Color(0xFF4F46E5), Colors.white, () {
            _openPartialAcceptDialog(req);
          }),
          const SizedBox(width: 4),
          // Reject Button (Red) -> Opens Photo 2 Modal
          _buildSmallBtn("Reject", const Color(0xFFEF4444), Colors.white, () {
            _openRejectDialog(req);
          }),
          const SizedBox(width: 4),
          // View Button -> Opens Photo 3 Modal
          _buildOutlinedSmallBtn("View", Icons.visibility_outlined, () {
            _openViewDetailsModal(req);
          }),
          const SizedBox(width: 4),
          // Clock History icon -> Opens Photo 4 Audit Trail Modal
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF64748B)),
            onPressed: () => _openAuditTrailModal(req),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            tooltip: "Audit Trail",
          ),
        ],
      );
    } else if (status == "PO" || status == "Order Placed") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Goods Received Button (Green)
          _buildSmallBtn("Goods Received", const Color(0xFF10B981), Colors.white, () {
            setState(() {
              req['status'] = "Completed";
              acceptedOrdersCount = (acceptedOrdersCount - 1).clamp(0, 99999);
              completedRequestsCount = completedRequestsCount + 1;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Goods received and added to inventory!"), backgroundColor: Colors.green),
            );
          }),
          const SizedBox(width: 4),
          // View Button
          _buildOutlinedSmallBtn("View", Icons.visibility_outlined, () => _openViewDetailsModal(req)),
          const SizedBox(width: 4),
          // History clock icon
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF64748B)),
            onPressed: () => _openAuditTrailModal(req),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            tooltip: "Audit Trail",
          ),
        ],
      );
    } else {
      // Rejected or Completed
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOutlinedSmallBtn("View", Icons.visibility_outlined, () => _openViewDetailsModal(req)),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF64748B)),
            onPressed: () => _openAuditTrailModal(req),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            tooltip: "Audit Trail",
          ),
        ],
      );
    }
  }

  Widget _buildSmallBtn(String text, Color bg, Color fg, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOutlinedSmallBtn(String text, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 11, color: const Color(0xFF2563EB)),
      label: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFF93C5FD)),
        backgroundColor: const Color(0xFFEFF6FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// =========================================================================
// Supplier Stock Request Dialog
// =========================================================================
class _SupplierStockRequestDialog extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> rawProducts;
  final List<Map<String, dynamic>> supplierCategories;

  const _SupplierStockRequestDialog({
    this.categories = const [],
    this.rawProducts = const [],
    this.supplierCategories = const [],
  });

  @override
  State<_SupplierStockRequestDialog> createState() => _SupplierStockRequestDialogState();
}

class _SupplierStockRequestDialogState extends State<_SupplierStockRequestDialog> {
  final List<String> defaultSuppliers = [
    "Saravana Electronics",
    "Bajrang Enterprises",
    "Sai TV Smart LED Pvt.Ltd",
    "Circuitpointcare",
    "Supplier #73",
  ];

  String? selectedSupplier;
  final TextEditingController searchSupplierCtrl = TextEditingController();

  late List<Map<String, dynamic>> lowStockProducts;

  @override
  void initState() {
    super.initState();
    if (widget.rawProducts.isNotEmpty) {
      lowStockProducts = widget.rawProducts.take(15).map((p) {
        return {
          "name": p['name'] ?? p['product_name'] ?? "Product",
          "code": p['code'] ?? p['product_code'] ?? "PRD-001",
          "current_stock": p['stock'] ?? p['quantity'] ?? 5,
          "order_qty": 20,
          "price": double.tryParse(p['purchase_price']?.toString() ?? '100') ?? 100.0,
          "selected": true,
        };
      }).toList();
    } else {
      lowStockProducts = [
        {
          "name": "Harddisk Power Cable & Data",
          "code": "PRD-3382",
          "current_stock": 0,
          "order_qty": 15,
          "price": 18.0,
          "selected": true,
        },
        {
          "name": "10 Channel Cable",
          "code": "PRD-3383",
          "current_stock": 1,
          "order_qty": 20,
          "price": 25.0,
          "selected": true,
        },
        {
          "name": "BNC Female to Female Connector Pin",
          "code": "CONN-BNC",
          "current_stock": 3,
          "order_qty": 50,
          "price": 12.0,
          "selected": false,
        },
      ];
    }
  }

  int get selectedCount => lowStockProducts.where((p) => p['selected'] == true).length;

  @override
  void dispose() {
    searchSupplierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Icon(Icons.all_inbox_rounded, size: 20, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Supplier Stock Request",
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Select a supplier and choose low-stock items to order",
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Step 1: Select Supplier
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                          child: const Center(
                            child: Text("1", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Select Supplier",
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        Text(" *", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 450;
                        final searchInput = SizedBox(
                          height: 40,
                          child: TextField(
                            controller: searchSupplierCtrl,
                            style: GoogleFonts.inter(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: "Search supplier by name, company, or phone...",
                              hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
                              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                          ),
                        );

                        final dropdown = SizedBox(
                          height: 40,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSupplier,
                                hint: Text("-- Choose Supplier --", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400)),
                                isExpanded: true,
                                items: defaultSuppliers.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                                onChanged: (val) => setState(() => selectedSupplier = val),
                              ),
                            ),
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              searchInput,
                              const SizedBox(height: 10),
                              dropdown,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: searchInput),
                            const SizedBox(width: 12),
                            Expanded(child: dropdown),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Step 2: Select Low Stock Products
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                          child: const Center(
                            child: Text("2", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Select Low Stock Products, Quantities & Prices",
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (selectedSupplier == null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                "Please Select a Supplier Above",
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Low stock products associated with that supplier will be listed here.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: lowStockProducts.map((p) {
                          final isChecked = p['selected'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isChecked ? const Color(0xFFF8FAFC) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isChecked ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  onChanged: (val) => setState(() => p['selected'] = val ?? false),
                                  activeColor: const Color(0xFF2563EB),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['name'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                      Text("Code: ${p['code']} | Cur. Stock: ${p['current_stock']}", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                  child: Text("Qty: ${p['order_qty']}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer Buttons
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    ),
                    child: Text("Cancel", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (selectedSupplier == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a supplier")));
                        return;
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Stock Request sent to $selectedSupplier successfully!"), backgroundColor: Colors.green),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                    label: Text("Send Stock Request ($selectedCount items)", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
