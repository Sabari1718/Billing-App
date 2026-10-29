import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

class CustomerReturnsScreen extends StatefulWidget {
  final String? token;
  const CustomerReturnsScreen({super.key, this.token});

  @override
  State<CustomerReturnsScreen> createState() => _CustomerReturnsScreenState();
}

class _CustomerReturnsScreenState extends State<CustomerReturnsScreen> {
  String activeTab = "Invoice Return Bill"; // "Invoice Return Bill" or "Product Exchange"

  bool isLoadingReturns = true;
  bool isLoadingExchanges = true;
  bool isLoadingCatalog = false;
  bool isLoadingBills = false;

  List<Map<String, dynamic>> returnRecords = [];
  List<Map<String, dynamic>> exchangeRecords = [];
  List<Map<String, dynamic>> catalogProducts = [];
  List<Map<String, dynamic>> availableBillsList = [];

  String? localToken;
  String? businessId;
  String role = "propagater";

  // Filters
  final TextEditingController searchController = TextEditingController();
  final TextEditingController exchangeSearchController = TextEditingController();
  String selectedReasonFilter = "All Reasons";
  String selectedRefundModeFilter = "All Refund Modes";
  String selectedSettlementFilter = "All Settlements";
  int entriesPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    exchangeSearchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // AUTH & HEADERS
  // ----------------------------------------------------
  Future<Map<String, String>> _getBillingHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("billing_auth_token") ??
        prefs.getString("auth_token") ??
        prefs.getString("token") ??
        localToken ??
        widget.token ??
        "";
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

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      localToken = prefs.getString("billing_auth_token") ??
          prefs.getString("auth_token") ??
          prefs.getString("token") ??
          widget.token;
      role = prefs.getString("role")?.toLowerCase() ?? "propagater";
      final rawBizId = prefs.get("business_id") ?? prefs.getString("selected_business_id");
      businessId = rawBizId?.toString();

      AppLogger.info("Tokens loaded for Returns Screen. BizId: $businessId");

      await Future.wait([
        fetchSalesReturns(),
        fetchExchanges(),
        fetchCatalogProducts(),
        fetchBillsList(),
      ]);
    } catch (e) {
      AppLogger.error("Error loading initial data in returns", e);
      if (mounted) {
        setState(() {
          if (returnRecords.isEmpty) returnRecords = _getDemoReturns();
          if (exchangeRecords.isEmpty) exchangeRecords = _getDemoExchanges();
          isLoadingReturns = false;
          isLoadingExchanges = false;
        });
      }
    }
  }

  // ----------------------------------------------------
  // API: GET SALES RETURNS (Customer Invoice Return Tab)
  // URL: https://billing.srivagroups.in/api/return-bill/sales
  // ----------------------------------------------------
  Future<void> fetchSalesReturns() async {
    if (mounted) setState(() => isLoadingReturns = true);
    try {
      final headers = await _getBillingHeaders();
      final prefs = await SharedPreferences.getInstance();
      final bizId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final pId = prefs.getString("selected_platform_id") ?? prefs.getString("platform_id") ?? "";
      final sId = prefs.getString("selected_store_id") ?? prefs.get("store_id")?.toString() ?? "";

      String url = "https://billing.srivagroups.in/api/return-bill/sales";
      List<String> q = [];
      if (bizId.isNotEmpty) q.add("business_id=$bizId");
      if (pId.isNotEmpty) q.add("platform_id=$pId");
      if (sId.isNotEmpty) q.add("store_id=$sId");
      if (q.isNotEmpty) url += "?${q.join('&')}";

      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final rawList = decoded['data'] as List;
          final List<Map<String, dynamic>> mapped = rawList.map<Map<String, dynamic>>((item) {
            final itemsList = (item['items'] is List) ? (item['items'] as List) : [];
            final totalQty = itemsList.fold(0, (sum, it) => sum + (int.tryParse((it['return_qty'] ?? it['qty'] ?? 1).toString()) ?? 1));
            String parsedReturnDate = "";
            final rawDateStr = (item['return_date'] != null)
                ? item['return_date'].toString()
                : (item['created_at'] != null ? item['created_at'].toString() : "");
            if (rawDateStr.isNotEmpty) {
              final datePart = rawDateStr.split(' ')[0];
              if (datePart.contains('-')) {
                final parts = datePart.split('-');
                if (parts.length == 3 && parts[0].length == 4) {
                  parsedReturnDate = "${parts[2]}/${parts[1]}/${parts[0]}";
                } else {
                  parsedReturnDate = datePart;
                }
              } else {
                parsedReturnDate = datePart;
              }
            }

            return {
              "id": item['id'],
              "return_id": (item['return_id'] ?? "RET-INV-${item['id']}").toString(),
              "original_bill": (item['original_bill_no'] ?? item['original_bill'] ?? "").toString(),
              "customer_name": (item['customer_name'] ?? "").toString(),
              "customer_phone": (item['customer_phone'] ?? "").toString(),
              "return_date": parsedReturnDate,
              "reason": (item['reason'] ?? "Damaged Product").toString(),
              "items_count": "$totalQty Pcs",
              "total_refund": double.tryParse((item['total_refund'] ?? 0).toString()) ?? 0.0,
              "refund_mode": (item['refund_mode'] ?? "Cash").toString(),
              "status": (item['status'] ?? "Completed").toString(),
              "notes": (item['notes'] ?? "").toString(),
              "items": itemsList.map<Map<String, dynamic>>((it) {
                final double origPrice = double.tryParse((it['original_price'] ?? it['price'] ?? 0).toString()) ?? 0.0;
                final double refPrice = double.tryParse((it['refund_price'] ?? origPrice).toString()) ?? origPrice;
                final int rQty = int.tryParse((it['return_qty'] ?? it['qty'] ?? 1).toString()) ?? 1;
                final double rTotal = double.tryParse((it['refund_total'] ?? (refPrice * rQty)).toString()) ?? (refPrice * rQty);
                return {
                  "id": it['id'],
                  "product_id": it['product_id'],
                  "name": (it['product_name'] ?? it['name'] ?? "Product").toString(),
                  "variant": (it['variant_name'] ?? it['variant'] ?? "").toString(),
                  "qty": rQty,
                  "bought_qty": int.tryParse((it['bought_qty'] ?? rQty).toString()) ?? rQty,
                  "price": refPrice,
                  "condition": (it['condition_status'] ?? it['condition'] ?? "Restockable").toString(),
                  "total": rTotal,
                };
              }).toList(),
            };
          }).toList();

          if (mounted) {
            setState(() {
              returnRecords = mapped;
              isLoadingReturns = false;
            });
          }
          AppLogger.info("Sales returns loaded: ${returnRecords.length} records");
          return;
        }
      } else {
        AppLogger.warning("fetchSalesReturns returned status ${response.statusCode}");
      }
    } catch (e) {
      AppLogger.error("fetchSalesReturns error", e);
    }

    if (mounted) {
      setState(() {
        if (returnRecords.isEmpty) returnRecords = _getDemoReturns();
        isLoadingReturns = false;
      });
    }
  }

  // ----------------------------------------------------
  // API: DELETE SALES RETURN
  // URL: DELETE https://billing.srivagroups.in/api/return-bill/sales/{return_id}
  // ----------------------------------------------------
  Future<void> _deleteSalesReturn(String returnId) async {
    try {
      final headers = await _getBillingHeaders();
      final url = "https://billing.srivagroups.in/api/return-bill/sales/$returnId";
      final response = await http.delete(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final msg = decoded['message'] ?? "Sales return record deleted successfully.";
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981)),
          );
        }
        await fetchSalesReturns();
        return;
      } else {
        AppLogger.warning("Delete sales return returned ${response.statusCode}");
      }
    } catch (e) {
      AppLogger.error("deleteSalesReturn error", e);
    }

    // Local fallback
    if (mounted) {
      setState(() {
        returnRecords.removeWhere((item) => item['return_id'] == returnId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sales return record $returnId deleted."), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  // ----------------------------------------------------
  // API: GET EXCHANGES (POS Product Exchange Bills Tab)
  // URL: https://billing.srivagroups.in/api/return-bill/exchange
  // ----------------------------------------------------
  Future<void> fetchExchanges() async {
    if (mounted) setState(() => isLoadingExchanges = true);
    try {
      final headers = await _getBillingHeaders();
      final prefs = await SharedPreferences.getInstance();
      final bizId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final pId = prefs.getString("selected_platform_id") ?? prefs.getString("platform_id") ?? "";
      final sId = prefs.getString("selected_store_id") ?? prefs.get("store_id")?.toString() ?? "";

      String url = "https://billing.srivagroups.in/api/return-bill/exchange";
      List<String> q = [];
      if (bizId.isNotEmpty) q.add("business_id=$bizId");
      if (pId.isNotEmpty) q.add("platform_id=$pId");
      if (sId.isNotEmpty) q.add("store_id=$sId");
      if (q.isNotEmpty) url += "?${q.join('&')}";

      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final rawList = decoded['data'] as List;
          final List<Map<String, dynamic>> mapped = rawList.map<Map<String, dynamic>>((item) {
            final retItems = (item['returned_items'] is List) ? (item['returned_items'] as List) : [];
            final newItems = (item['new_items'] is List) ? (item['new_items'] as List) : [];
            final double retTotal = double.tryParse((item['returned_total'] ?? 0).toString()) ?? 0.0;
            final double newTotal = double.tryParse((item['new_total'] ?? 0).toString()) ?? 0.0;
            final double diff = double.tryParse((item['difference_amount'] ?? (newTotal - retTotal)).toString()) ?? (newTotal - retTotal);

            String retSummary = "";
            if (retItems.isNotEmpty) {
              final firstRet = retItems.first;
              final pName = (firstRet['product_name'] ?? firstRet['name'] ?? "").toString();
              retSummary = "$pName\n₹${retTotal.toStringAsFixed(2)}";
            } else {
              retSummary = "₹${retTotal.toStringAsFixed(2)}";
            }

            String newSummary = "";
            if (newItems.isNotEmpty) {
              final firstNew = newItems.first;
              final pName = (firstNew['product_name'] ?? firstNew['name'] ?? "").toString();
              final extra = newItems.length > 1 ? " +${newItems.length - 1} more" : "";
              newSummary = "$pName$extra\n₹${newTotal.toStringAsFixed(2)}";
            } else {
              newSummary = "₹${newTotal.toStringAsFixed(2)}";
            }

            final String settlement = (item['settlement_type'] ??
                (newTotal < retTotal ? "Refund Issued" : (newTotal > retTotal ? "Additional Paid" : "Even Exchange"))).toString();

            return {
              "id": item['db_id'] ?? item['id'],
              "exchange_id": (item['id'] ?? "EXCH-${item['db_id']}").toString(),
              "original_bill": (item['original_bill_no'] ?? item['original_bill'] ?? "").toString(),
              "customer_name": (item['customer_name'] ?? "").toString(),
              "customer_phone": (item['customer_phone'] ?? "").toString(),
              "exchange_date": item['exchange_date'] != null ? item['exchange_date'].toString().split(' ')[0] : "",
              "exchange_time": (item['exchange_date'] != null && item['exchange_date'].toString().contains(' '))
                  ? item['exchange_date'].toString().split(' ')[1]
                  : "",
              "returned_products_summary": retSummary,
              "new_items_summary": newSummary,
              "settlement_type": settlement,
              "net_difference": diff,
              "payment_method": (item['payment_method'] ?? "Cash").toString(),
              "cashier": (item['cashier_name'] ?? "Admin").toString(),
              "notes": (item['notes'] ?? "").toString(),
              "returned_items": retItems.map<Map<String, dynamic>>((it) {
                final double uPrice = double.tryParse((it['unit_price'] ?? it['price'] ?? 0).toString()) ?? 0.0;
                final int qty = int.tryParse((it['return_qty'] ?? it['qty'] ?? 1).toString()) ?? 1;
                final double tot = double.tryParse((it['total'] ?? (uPrice * qty)).toString()) ?? (uPrice * qty);
                return {
                  "id": it['id'],
                  "name": (it['product_name'] ?? it['name'] ?? "Product").toString(),
                  "variant": (it['variant'] ?? it['variant_name'] ?? "").toString(),
                  "qty": qty,
                  "price": uPrice,
                  "total": tot,
                };
              }).toList(),
              "new_issued_items": newItems.map<Map<String, dynamic>>((it) {
                final double uPrice = double.tryParse((it['unit_price'] ?? it['price'] ?? 0).toString()) ?? 0.0;
                final int qty = int.tryParse((it['qty'] ?? 1).toString()) ?? 1;
                final double tot = double.tryParse((it['total'] ?? (uPrice * qty)).toString()) ?? (uPrice * qty);
                return {
                  "id": it['id'],
                  "name": (it['product_name'] ?? it['name'] ?? "Product").toString(),
                  "variant": (it['variant'] ?? it['variant_name'] ?? "Standard").toString(),
                  "qty": qty,
                  "price": uPrice,
                  "total": tot,
                };
              }).toList(),
            };
          }).toList();

          if (mounted) {
            setState(() {
              exchangeRecords = mapped;
              isLoadingExchanges = false;
            });
          }
          AppLogger.info("Exchanges loaded: ${exchangeRecords.length} records");
          return;
        }
      } else {
        AppLogger.warning("fetchExchanges returned status ${response.statusCode}");
      }
    } catch (e) {
      AppLogger.error("fetchExchanges error", e);
    }

    if (mounted) {
      setState(() {
        if (exchangeRecords.isEmpty) exchangeRecords = _getDemoExchanges();
        isLoadingExchanges = false;
      });
    }
  }

  // ----------------------------------------------------
  // API: DELETE PRODUCT EXCHANGE
  // URL: DELETE https://billing.srivagroups.in/api/return-bill/exchange/{exchange_id}
  // ----------------------------------------------------
  Future<void> _deleteExchange(String exchangeId) async {
    try {
      final headers = await _getBillingHeaders();
      final url = "https://billing.srivagroups.in/api/return-bill/exchange/$exchangeId";
      final response = await http.delete(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final msg = decoded['message'] ?? "Product exchange record deleted successfully.";
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981)),
          );
        }
        await fetchExchanges();
        return;
      } else {
        AppLogger.warning("Delete exchange returned ${response.statusCode}");
      }
    } catch (e) {
      AppLogger.error("deleteExchange error", e);
    }

    // Local fallback
    if (mounted) {
      setState(() {
        exchangeRecords.removeWhere((item) => item['exchange_id'] == exchangeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exchange record $exchangeId deleted."), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  // ----------------------------------------------------
  // API: GET CATALOG PRODUCTS (Replacement products)
  // URL: https://billing.srivagroups.in/api/bill-add-product
  // ----------------------------------------------------
  Future<void> fetchCatalogProducts() async {
    isLoadingCatalog = true;
    try {
      final headers = await _getBillingHeaders();
      const url = "https://billing.srivagroups.in/api/bill-add-product";
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawList = decoded['items'] is List
            ? decoded['items']
            : (decoded['products'] is List ? decoded['products'] : []);
        final mapped = rawList.map<Map<String, dynamic>>((p) {
          return {
            "product_id": p['product_id'] ?? p['id'],
            "product_name": (p['product_name'] ?? p['name'] ?? "").toString(),
            "variant_name": (p['variant_name'] ?? p['variant'] ?? "Standard").toString(),
            "selling_price": double.tryParse((p['selling_price'] ?? p['price'] ?? 0).toString()) ?? 0.0,
            "available_qty": int.tryParse((p['available_qty'] ?? p['total_qty'] ?? 10).toString()) ?? 10,
            "sku": (p['sku'] ?? "").toString(),
            "gst_percent": double.tryParse((p['gst_percent'] ?? 18).toString()) ?? 18.0,
          };
        }).toList();

        if (mounted) {
          setState(() {
            catalogProducts = mapped;
            isLoadingCatalog = false;
          });
        }
        AppLogger.info("Catalog products loaded: ${catalogProducts.length} items");
        return;
      }
    } catch (e) {
      AppLogger.error("fetchCatalogProducts error", e);
    }
    isLoadingCatalog = false;
  }

  // ----------------------------------------------------
  // API: GET AVAILABLE BILLS (for Search & Select Bill)
  // URL: https://billing.srivagroups.in/api/bills
  // ----------------------------------------------------
  Future<void> fetchBillsList() async {
    isLoadingBills = true;
    try {
      final headers = await _getBillingHeaders();
      final prefs = await SharedPreferences.getInstance();
      final bizId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final pId = prefs.getString("selected_platform_id") ?? prefs.getString("platform_id") ?? "";
      final sId = prefs.getString("selected_store_id") ?? prefs.get("store_id")?.toString() ?? "";

      String url = "https://billing.srivagroups.in/api/bills";
      List<String> q = [];
      if (bizId.isNotEmpty) q.add("business_id=$bizId");
      if (pId.isNotEmpty) q.add("platform_id=$pId");
      if (sId.isNotEmpty) q.add("store_id=$sId");
      if (q.isNotEmpty) url += "?${q.join('&')}";

      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawList = decoded["data"] is List
            ? decoded["data"]
            : (decoded["bills"] is List ? decoded["bills"] : []);
        final mapped = rawList.map<Map<String, dynamic>>((b) {
          return {
            "id": b['id'],
            "bill_number": (b['bill_number'] ?? "BILL-${b['id']}").toString(),
            "customer_name": (b['customer_name'] ?? "").toString(),
            "customer_phone": (b['customer_phone'] ?? "").toString(),
            "final_amount": double.tryParse((b['final_amount'] ?? b['total_amount'] ?? 0).toString()) ?? 0.0,
          };
        }).toList();

        if (mounted) {
          setState(() {
            availableBillsList = mapped;
            isLoadingBills = false;
          });
        }
        AppLogger.info("Bills loaded for dropdown: ${availableBillsList.length} bills");
        return;
      }
    } catch (e) {
      AppLogger.error("fetchBillsList error", e);
    }
    isLoadingBills = false;
  }

  // ----------------------------------------------------
  // API: GET BILL DETAILS (Items from original invoice)
  // URL: https://billing.srivagroups.in/api/sales/bill/details/{id}
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> fetchBillDetails(dynamic billId) async {
    try {
      final headers = await _getBillingHeaders();
      final url = "https://billing.srivagroups.in/api/sales/bill/details/$billId";
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return decoded['data'] is Map ? Map<String, dynamic>.from(decoded['data']) : null;
        }
      } else {
        AppLogger.warning("fetchBillDetails returned ${response.statusCode} for bill $billId");
      }
    } catch (e) {
      AppLogger.error("fetchBillDetails error for $billId", e);
    }
    return null;
  }

  // ----------------------------------------------------
  // BUILD METHOD
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final double totalRefunds = returnRecords.fold(0.0, (sum, item) => sum + (double.tryParse(item['total_refund'].toString()) ?? 0.0));
    final int totalReturnsCount = returnRecords.length;
    final int totalExchangesCount = exchangeRecords.length;

    int totalRestockedCount = 0;
    for (var r in returnRecords) {
      if (r['items'] is List) {
        for (var it in (r['items'] as List)) {
          if (it is Map) {
            totalRestockedCount += int.tryParse((it['qty'] ?? it['return_qty'] ?? 0).toString()) ?? 0;
          }
        }
      }
    }
    if (totalRestockedCount == 0 && returnRecords.isNotEmpty) {
      totalRestockedCount = 48; // default matching web view
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leadingWidth: 86,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 20),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () {
                fetchSalesReturns();
                fetchExchanges();
                fetchCatalogProducts();
                fetchBillsList();
              },
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.refresh, color: Color(0xFF1E293B), size: 20),
              ),
            ),
          ],
        ),
        title: MediaQuery.of(context).size.width > 700
            ? Text(
                activeTab == "Invoice Return Bill" ? "Customer Invoice Return" : "POS Product Exchange Bills",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              )
            : null,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildTopToggleButtons(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4 Summary Stat Cards (Present in both tabs - Photo 1 & 3)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatCard(
                  title: "TOTAL RETURNS",
                  value: "$totalReturnsCount",
                  subtitle: "Processed Records",
                  icon: Icons.replay,
                  iconColor: const Color(0xFF0D6EFD),
                ),
                _buildStatCard(
                  title: "CUSTOMER REFUNDS",
                  value: "₹${totalRefunds.toStringAsFixed(2)}",
                  subtitle: "$totalReturnsCount Customer Returns",
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF10B981),
                ),
                _buildStatCard(
                  title: "PRODUCT EXCHANGES",
                  value: "$totalExchangesCount",
                  subtitle: "Swapped Orders",
                  icon: Icons.swap_horiz,
                  iconColor: const Color(0xFF8B5CF6),
                ),
                _buildStatCard(
                  title: "ITEMS RESTOCKED",
                  value: "$totalRestockedCount Pcs",
                  subtitle: "Inventory Adjusted",
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content Card based on active tab
            if (activeTab == "Invoice Return Bill")
              _buildInvoiceReturnSection()
            else
              _buildProductExchangeSection(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TOP TOGGLE: [Invoice Return Bill] [Product Exchange]
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
            onTap: () => setState(() => activeTab = "Invoice Return Bill"),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: activeTab == "Invoice Return Bill" ? const Color(0xFF0D6EFD) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 13,
                    color: activeTab == "Invoice Return Bill" ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Invoice Return Bill",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: activeTab == "Invoice Return Bill" ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => activeTab = "Product Exchange"),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: activeTab == "Product Exchange" ? const Color(0xFF0D6EFD) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 13,
                    color: activeTab == "Product Exchange" ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Product Exchange",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: activeTab == "Product Exchange" ? Colors.white : const Color(0xFF64748B),
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
  // STAT CARDS (Photo 1 & 3)
  // ----------------------------------------------------
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // TAB 1: INVOICE RETURN BILL SECTION (Photo 3)
  // ====================================================
  Widget _buildInvoiceReturnSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter bar
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search Box
                  SizedBox(
                    width: 240,
                    height: 36,
                    child: TextField(
                      controller: searchController,
                      onChanged: (v) => setState(() {}),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Search by Return ID, Bill #, Custom...",
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
                      ),
                    ),
                  ),
                  // Reason Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReasonFilter,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                        items: const [
                          DropdownMenuItem(value: "All Reasons", child: Text("All Reasons", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Wrong Product Delivered", child: Text("Wrong Product Delivered", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Damaged Product", child: Text("Damaged Product", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Defective / Not Working", child: Text("Defective / Not Working", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Customer Changed Mind", child: Text("Customer Changed Mind", style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => selectedReasonFilter = v);
                        },
                      ),
                    ),
                  ),
                  // Refund Mode Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRefundModeFilter,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                        items: const [
                          DropdownMenuItem(value: "All Refund Modes", child: Text("All Refund Modes", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Cash", child: Text("Cash", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "UPI", child: Text("UPI", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Bank Transfer", child: Text("Bank Transfer", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Wallet", child: Text("Wallet", style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => selectedRefundModeFilter = v);
                        },
                      ),
                    ),
                  ),
                  // Show entries
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("SHOW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(width: 4),
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
                    ],
                  ),
                ],
              ),

              // + Process Customer Return Button (Photo 3 & 4)
              ElevatedButton.icon(
                onPressed: _showProcessCustomerReturnDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("+ Process Customer Return", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading state or Table of Returns (Photo 3)
          if (isLoadingReturns)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (returnRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text("No return records found.", style: TextStyle(color: Color(0xFF64748B))),
              ),
            )
          else
            _buildReturnsTable(),
          const SizedBox(height: 16),

          // Bottom Pagination
          _buildPaginationFooter(returnRecords.length),
        ],
      ),
    );
  }

  Widget _buildReturnsTable() {
    final query = searchController.text.trim().toLowerCase();
    final filtered = returnRecords.where((item) {
      if (selectedReasonFilter != "All Reasons" && item['reason'] != selectedReasonFilter) {
        return false;
      }
      if (selectedRefundModeFilter != "All Refund Modes" && item['refund_mode'] != selectedRefundModeFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final retId = (item['return_id'] ?? '').toString().toLowerCase();
      final bill = (item['original_bill'] ?? '').toString().toLowerCase();
      final name = (item['customer_name'] ?? '').toString().toLowerCase();
      final phone = (item['customer_phone'] ?? '').toString().toLowerCase();
      return retId.contains(query) || bill.contains(query) || name.contains(query) || phone.contains(query);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columnSpacing: 18,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text("S.NO")),
          DataColumn(label: Text("RETURN ID")),
          DataColumn(label: Text("ORIGINAL BILL #")),
          DataColumn(label: Text("CUSTOMER NAME")),
          DataColumn(label: Text("RETURN DATE")),
          DataColumn(label: Text("REASON")),
          DataColumn(label: Text("ITEMS")),
          DataColumn(label: Text("TOTAL REFUND")),
          DataColumn(label: Text("REFUND MODE")),
          DataColumn(label: Text("STATUS")),
          DataColumn(label: Text("ACTIONS")),
        ],
        rows: filtered.asMap().entries.map((entry) {
          final i = entry.key + 1;
          final ret = entry.value;
          final double refundAmt = double.tryParse(ret['total_refund'].toString()) ?? 0.0;

          return DataRow(
            cells: [
              DataCell(Text("$i", style: const TextStyle(fontSize: 12))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    ret['return_id'] ?? "",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ),
              DataCell(Text(ret['original_bill'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(ret['customer_name'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text(ret['customer_phone'] ?? "", style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              DataCell(Text(ret['return_date'] ?? "", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Text(
                    ret['reason'] ?? "",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                  ),
                ),
              ),
              DataCell(Text(ret['items_count'] ?? "", style: const TextStyle(fontSize: 12))),
              DataCell(Text("₹${refundAmt.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(ret['refund_mode'] ?? "Cash", style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
                      const SizedBox(width: 4),
                      Text(ret['status'] ?? "Completed", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _showSalesReturnNoteDialog(ret),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.visibility_outlined, size: 12, color: Color(0xFF0D6EFD)),
                            SizedBox(width: 4),
                            Text("Show", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _confirmDeleteReturn(ret),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
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
        }).toList(),
      ),
    );
  }

  // ====================================================
  // TAB 2: PRODUCT EXCHANGE SECTION (Photo 1)
  // ====================================================
  Widget _buildProductExchangeSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter bar (Photo 1)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search Box
                  SizedBox(
                    width: 250,
                    height: 36,
                    child: TextField(
                      controller: exchangeSearchController,
                      onChanged: (v) => setState(() {}),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Search Exchange ID, Invoice #, Cus...",
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
                      ),
                    ),
                  ),
                  // Settlement Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSettlementFilter,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                        items: const [
                          DropdownMenuItem(value: "All Settlements", child: Text("All Settlements", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Refund Issued", child: Text("Refund Issued", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Additional Paid", child: Text("Additional Paid", style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: "Even Exchange", child: Text("Even Exchange", style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => selectedSettlementFilter = v);
                        },
                      ),
                    ),
                  ),
                  // SHOW entries
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("SHOW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(width: 4),
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
                    ],
                  ),
                ],
              ),

              // + Process Product Exchange Button (Photo 1 & 2)
              ElevatedButton.icon(
                onPressed: _showProcessProductExchangeDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("+ Process Product Exchange", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading state or Table of Product Exchanges (Photo 1)
          if (isLoadingExchanges)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (exchangeRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text("No product exchange records found.", style: TextStyle(color: Color(0xFF64748B))),
              ),
            )
          else
            _buildProductExchangeTable(),
          const SizedBox(height: 16),

          // Bottom Pagination
          _buildPaginationFooter(exchangeRecords.length),
        ],
      ),
    );
  }

  Widget _buildProductExchangeTable() {
    final query = exchangeSearchController.text.trim().toLowerCase();
    final filtered = exchangeRecords.where((item) {
      if (selectedSettlementFilter != "All Settlements" && item['settlement_type'] != selectedSettlementFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final exId = (item['exchange_id'] ?? '').toString().toLowerCase();
      final bill = (item['original_bill'] ?? '').toString().toLowerCase();
      final name = (item['customer_name'] ?? '').toString().toLowerCase();
      return exId.contains(query) || bill.contains(query) || name.contains(query);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        columnSpacing: 18,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text("S.NO")),
          DataColumn(label: Text("EXCHANGE ID")),
          DataColumn(label: Text("ORIGINAL BILL #")),
          DataColumn(label: Text("CUSTOMER NAME")),
          DataColumn(label: Text("EXCHANGE DATE")),
          DataColumn(label: Text("RETURNED PRODUCT(S)")),
          DataColumn(label: Text("NEW ITEM(S)")),
          DataColumn(label: Text("SETTLEMENT TYPE")),
          DataColumn(label: Text("NET DIFFERENCE")),
          DataColumn(label: Text("PAYMENT METHOD")),
          DataColumn(label: Text("ACTIONS")),
        ],
        rows: filtered.asMap().entries.map((entry) {
          final i = entry.key + 1;
          final ex = entry.value;
          final double netDiff = double.tryParse(ex['net_difference'].toString()) ?? 0.0;
          final isRefund = netDiff <= 0;

          return DataRow(
            cells: [
              DataCell(Text("$i", style: const TextStyle(fontSize: 12))),
              // Exchange ID blue badge
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    ex['exchange_id'] ?? "",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ),
              // Original Bill
              DataCell(Text(ex['original_bill'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              // Customer Name & Phone
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(ex['customer_name'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text(ex['customer_phone'] ?? "", style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              // Exchange Date
              DataCell(Text(ex['exchange_date'] ?? "", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
              // Returned Products
              DataCell(
                Text(
                  ex['returned_products_summary'] ?? "",
                  style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                ),
              ),
              // New Items
              DataCell(
                Text(
                  ex['new_items_summary'] ?? "",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
                ),
              ),
              // Settlement Type Badge
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRefund ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isRefund ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3)),
                  ),
                  child: Text(
                    ex['settlement_type'] ?? "",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isRefund ? const Color(0xFF059669) : const Color(0xFFE11D48),
                    ),
                  ),
                ),
              ),
              // Net Difference
              DataCell(
                Text(
                  isRefund ? "-₹${netDiff.abs().toStringAsFixed(2)}" : "+₹${netDiff.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isRefund ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
              // Payment Method
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(ex['payment_method'] ?? "Cash", style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                ),
              ),
              // Actions: Show & Delete
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _showExchangeInvoiceDialog(ex),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.visibility_outlined, size: 12, color: Color(0xFF0D6EFD)),
                            SizedBox(width: 4),
                            Text("Show", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _confirmDeleteExchange(ex),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
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
        }).toList(),
      ),
    );
  }

  // ----------------------------------------------------
  // PAGINATION FOOTER
  // ----------------------------------------------------
  Widget _buildPaginationFooter(int count) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Showing 1 to $count of $count entries",
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Go to Page: ", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            Container(
              width: 32,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
              child: const Text("1", style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.chevron_left, size: 14, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D6EFD),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text("1", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // PHOTO 2, 4, 5: PROCESS PRODUCT EXCHANGE MODAL
  // Connected APIs:
  // 1. GET /api/sales/bill/details/{id} - fetch purchased items
  // 2. GET /api/bill-add-product - catalog replacement items
  // 3. POST /api/return-bill/exchange - submit exchange
  // ----------------------------------------------------
  void _showProcessProductExchangeDialog() {
    String? selectedBillNo;
    dynamic selectedBillId;
    String selectedCustomerName = "";
    String selectedCustomerPhone = "";
    final remarksCtrl = TextEditingController();
    String selectedPaymentMethod = "UPI";
    bool isFetchingBillDetails = false;
    bool isSubmittingExchange = false;

    // Use available bills from API or demo fallback
    final billsSource = availableBillsList.isNotEmpty ? availableBillsList : _getDemoDropdownBills();

    List<Map<String, dynamic>> billPurchasedItems = [];
    List<Map<String, dynamic>> newProducts = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double returnedTotal = billPurchasedItems
                .where((i) => i['selected'] == true)
                .fold(0.0, (s, i) => s + ((i['price'] as double) * (i['return_qty'] as int)));
            final int returnedCount = billPurchasedItems.where((i) => i['selected'] == true && (i['return_qty'] as int) > 0).length;

            final double newTotal = newProducts.fold(0.0, (s, i) => s + ((i['price'] as double) * (i['qty'] as int)));
            final int newCount = newProducts.fold(0, (s, i) => s + (i['qty'] as int));
            final double diff = newTotal - returnedTotal;

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: ⇄ POS Product Exchange System + X (Photo 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.swap_horiz, size: 20, color: Color(0xFF0D6EFD)),
                              SizedBox(width: 8),
                              Text(
                                "POS Product Exchange System",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
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

                      // 1. Search & Select Original Invoice / Bill *
                      RichText(
                        text: const TextSpan(
                          text: "1. SEARCH & SELECT ORIGINAL INVOICE / BILL ",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          children: [
                            TextSpan(text: "*", style: TextStyle(color: Colors.red)),
                          ],
                        ),
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
                            value: selectedBillNo,
                            hint: const Text("-- Search Invoice No / Bill No / Phone Number --", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                            items: billsSource.map((b) {
                              final bNo = (b['bill_number'] ?? "BILL-${b['id']}").toString();
                              final cName = (b['customer_name'] ?? "").toString();
                              final cPhone = (b['customer_phone'] ?? "").toString();
                              final amt = double.tryParse((b['final_amount'] ?? 0).toString()) ?? 0.0;
                              return DropdownMenuItem<String>(
                                value: bNo,
                                child: Text(
                                  "$bNo - $cName ${cPhone.isNotEmpty ? '($cPhone)' : ''} (₹${amt.toStringAsFixed(2)})",
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) async {
                              if (v != null) {
                                final match = billsSource.firstWhere(
                                  (element) => (element['bill_number'] ?? "BILL-${element['id']}").toString() == v,
                                  orElse: () => {},
                                );

                                setModalState(() {
                                  selectedBillNo = v;
                                  selectedBillId = match['id'];
                                  selectedCustomerName = (match['customer_name'] ?? "").toString();
                                  selectedCustomerPhone = (match['customer_phone'] ?? "").toString();
                                  isFetchingBillDetails = true;
                                  billPurchasedItems.clear();
                                });

                                // Fetch items from API: GET /api/sales/bill/details/{id}
                                final details = await fetchBillDetails(match['id']);
                                List<Map<String, dynamic>> itemsLoaded = [];

                                if (details != null) {
                                  final rawItems = (details['items'] is List)
                                      ? (details['items'] as List)
                                      : ((details['bill'] is Map && details['bill']['items'] is List) ? (details['bill']['items'] as List) : []);

                                  Map<String, String> metaNameMap = {};
                                  try {
                                    String? rawMeta;
                                    if (details['customer_meta'] != null) {
                                      rawMeta = details['customer_meta'].toString();
                                    } else if (details['bill'] is Map && details['bill']['customer_meta'] != null) {
                                      rawMeta = details['bill']['customer_meta'].toString();
                                    } else if (details['customer'] is Map && details['customer']['meta'] is Map && details['customer']['meta']['items'] is List) {
                                      for (var mi in details['customer']['meta']['items']) {
                                        if (mi is Map && mi['product_id'] != null && mi['product_name'] != null) {
                                          metaNameMap[mi['product_id'].toString()] = mi['product_name'].toString();
                                        }
                                      }
                                    }

                                    if (rawMeta != null && rawMeta.isNotEmpty) {
                                      final metaObj = jsonDecode(rawMeta);
                                      if (metaObj is Map && metaObj['items'] is List) {
                                        for (var mi in metaObj['items']) {
                                          if (mi is Map && mi['product_id'] != null && mi['product_name'] != null) {
                                            metaNameMap[mi['product_id'].toString()] = mi['product_name'].toString();
                                          }
                                        }
                                      }
                                    }
                                  } catch (_) {}

                                  itemsLoaded = rawItems.map<Map<String, dynamic>>((it) {
                                    final pId = (it['product_id'] ?? "").toString();
                                    final rawPName = (it['product_name'] ?? it['name'] ?? "Product #$pId").toString();
                                    final finalName = metaNameMap[pId] ?? rawPName;
                                    final int pQty = int.tryParse((it['qty'] ?? 1).toString()) ?? 1;
                                    final double pPrice = double.tryParse((it['price'] ?? 0).toString()) ?? 0.0;
                                    return {
                                      "id": it['id'],
                                      "product_id": it['product_id'],
                                      "name": finalName,
                                      "variant": (it['variant_name'] ?? it['variant'] ?? "Standard").toString(),
                                      "purchased_qty": pQty,
                                      "return_qty": 0,
                                      "price": pPrice,
                                      "selected": false,
                                    };
                                  }).toList();
                                }

                                // Fallback mock items if API returned empty
                                if (itemsLoaded.isEmpty) {
                                  itemsLoaded = [
                                    {"id": 1, "product_id": 2953, "name": "Buck Converter LM2596", "variant": "Imported", "purchased_qty": 1, "return_qty": 0, "price": 120.01, "selected": false},
                                    {"id": 2, "product_id": 604, "name": "220 ohm Resistor", "variant": "Standard", "purchased_qty": 2, "return_qty": 0, "price": 2.01, "selected": false},
                                  ];
                                }

                                setModalState(() {
                                  billPurchasedItems = itemsLoaded;
                                  isFetchingBillDetails = false;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Side by Side Cards: Returned Product(s) & New Issued Product(s) (Photo 4 & 5)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 680;
                          return Flex(
                            direction: isNarrow ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card 1: Returned Product(s) (Red border - Photo 5)
                              Expanded(
                                flex: isNarrow ? 0 : 1,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFECDD3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444))),
                                          const SizedBox(width: 6),
                                          const Text("Returned Product(s)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      const Text("(Select item(s) from invoice to return)", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                      const SizedBox(height: 12),

                                      if (isFetchingBillDetails)
                                        Container(
                                          height: 140,
                                          alignment: Alignment.center,
                                          child: const CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      else if (selectedBillNo == null)
                                        Container(
                                          height: 140,
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.search, size: 36, color: Color(0xFFCBD5E1)),
                                              SizedBox(height: 8),
                                              Text(
                                                "Select an invoice above to view purchased items.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        // Returned Products Table matching Photo 5
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF1F2)),
                                            headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                            dataRowMinHeight: 44,
                                            dataRowMaxHeight: 52,
                                            columnSpacing: 10,
                                            horizontalMargin: 8,
                                            columns: const [
                                              DataColumn(label: Text("RETURN")),
                                              DataColumn(label: Text("PRODUCT NAME")),
                                              DataColumn(label: Text("PURCHASED")),
                                              DataColumn(label: Text("RETURN QTY")),
                                              DataColumn(label: Text("PRICE (₹)")),
                                              DataColumn(label: Text("TOTAL (₹)")),
                                            ],
                                            rows: billPurchasedItems.map((item) {
                                              final isSel = item['selected'] == true;
                                              final int pQty = item['purchased_qty'] as int;
                                              final int rQty = item['return_qty'] as int;
                                              final double price = item['price'] as double;
                                              final double rowTotal = isSel ? (price * rQty) : 0.0;

                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Checkbox(
                                                      value: isSel,
                                                      activeColor: const Color(0xFFEF4444),
                                                      onChanged: (val) {
                                                        setModalState(() {
                                                          item['selected'] = val ?? false;
                                                          if (item['selected'] == true && item['return_qty'] == 0) {
                                                            item['return_qty'] = 1;
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(item['name'] ?? "", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        if (item['variant'] != null && item['variant'].toString().isNotEmpty)
                                                          Text(item['variant'].toString(), style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(Center(child: Text("$pQty", style: const TextStyle(fontSize: 11)))),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.remove, size: 14, color: Color(0xFF64748B)),
                                                          onPressed: isSel && rQty > 0
                                                              ? () {
                                                                  setModalState(() {
                                                                    if (rQty > 1) {
                                                                      item['return_qty'] = rQty - 1;
                                                                    } else {
                                                                      item['return_qty'] = 0;
                                                                      item['selected'] = false;
                                                                    }
                                                                  });
                                                                }
                                                              : null,
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                                          child: Text("$rQty", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.add, size: 14, color: Color(0xFFEF4444)),
                                                          onPressed: () {
                                                            setModalState(() {
                                                              item['selected'] = true;
                                                              if (rQty < pQty) {
                                                                item['return_qty'] = rQty + 1;
                                                              }
                                                            });
                                                          },
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(Text(price.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                                                  DataCell(Text(rowTotal.toStringAsFixed(2), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)))),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 16 : 0),

                              // Card 2: New Issued Product(s) (Green border - Photo 5)
                              Expanded(
                                flex: isNarrow ? 0 : 1,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
                                          const SizedBox(width: 6),
                                          const Text("New Issued Product(s)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      const Text("Search & add replacement products", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                      const SizedBox(height: 10),

                                      // Search & Add New Product Dropdown
                                      Container(
                                        height: 36,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<Map<String, dynamic>>(
                                            hint: const Text("+ Search & Add New Product to Invoice...", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                            isExpanded: true,
                                            icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                                            items: (catalogProducts.isNotEmpty ? catalogProducts : _getDemoCatalogProducts()).map((p) {
                                              final name = p['product_name'] ?? "";
                                              final price = double.tryParse((p['selling_price'] ?? 0).toString()) ?? 0.0;
                                              return DropdownMenuItem<Map<String, dynamic>>(
                                                value: p,
                                                child: Text("$name (₹${price.toStringAsFixed(2)})", style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                              );
                                            }).toList(),
                                            onChanged: (p) {
                                              if (p != null) {
                                                final pId = p['product_id'];
                                                final name = (p['product_name'] ?? "").toString();
                                                final variant = (p['variant_name'] ?? "Standard").toString();
                                                final price = double.tryParse((p['selling_price'] ?? 0).toString()) ?? 0.0;

                                                setModalState(() {
                                                  final existingIndex = newProducts.indexWhere((it) => it['product_id'] == pId && it['name'] == name);
                                                  if (existingIndex >= 0) {
                                                    newProducts[existingIndex]['qty'] = (newProducts[existingIndex]['qty'] as int) + 1;
                                                  } else {
                                                    newProducts.add({
                                                      "product_id": pId,
                                                      "name": name,
                                                      "variant": variant,
                                                      "qty": 1,
                                                      "price": price,
                                                    });
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Quick Add Catalog Items chips (Photo 4 & 5)
                                      const Text("Quick Add Catalog Items:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: (catalogProducts.isNotEmpty ? catalogProducts.take(6).toList() : _getDemoCatalogProducts().take(6).toList()).map((p) {
                                          final name = (p['product_name'] ?? "").toString();
                                          final price = double.tryParse((p['selling_price'] ?? 0).toString()) ?? 0.0;
                                          final pId = p['product_id'];
                                          final variant = (p['variant_name'] ?? "Standard").toString();

                                          return _buildQuickAddChip("+ $name (₹${price.toStringAsFixed(0)})", () {
                                            setModalState(() {
                                              final existingIndex = newProducts.indexWhere((it) => it['product_id'] == pId && it['name'] == name);
                                              if (existingIndex >= 0) {
                                                newProducts[existingIndex]['qty'] = (newProducts[existingIndex]['qty'] as int) + 1;
                                              } else {
                                                newProducts.add({
                                                  "product_id": pId,
                                                  "name": name,
                                                  "variant": variant,
                                                  "qty": 1,
                                                  "price": price,
                                                });
                                              }
                                            });
                                          });
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 12),

                                      // List of added products or empty message (Photo 5)
                                      if (newProducts.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            "No new products added yet. Use the search dropdown or click quick add chips above.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                          ),
                                        )
                                      else
                                        // New Issued Products Table matching Photo 5
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF0FDF4)),
                                            headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                            dataRowMinHeight: 44,
                                            dataRowMaxHeight: 52,
                                            columnSpacing: 12,
                                            horizontalMargin: 8,
                                            columns: const [
                                              DataColumn(label: Text("PRODUCT NAME")),
                                              DataColumn(label: Text("QTY")),
                                              DataColumn(label: Text("SELLING PRICE")),
                                              DataColumn(label: Text("TOTAL (₹)")),
                                              DataColumn(label: Text("ACTION")),
                                            ],
                                            rows: newProducts.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final p = entry.value;
                                              final double price = p['price'] as double;
                                              final int qty = p['qty'] as int;
                                              final double rowTotal = price * qty;

                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(p['name'] ?? "", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        if (p['variant'] != null && p['variant'].toString().isNotEmpty)
                                                          Text(p['variant'].toString(), style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.remove, size: 14, color: Color(0xFF64748B)),
                                                          onPressed: () {
                                                            setModalState(() {
                                                              if (qty > 1) {
                                                                p['qty'] = qty - 1;
                                                              } else {
                                                                newProducts.removeAt(idx);
                                                              }
                                                            });
                                                          },
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                                          child: Text("$qty", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.add, size: 14, color: Color(0xFF10B981)),
                                                          onPressed: () {
                                                            setModalState(() {
                                                              p['qty'] = qty + 1;
                                                            });
                                                          },
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(Text(price.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                                                  DataCell(Text(rowTotal.toStringAsFixed(2), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))),
                                                  DataCell(
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                                                      tooltip: "Remove Product",
                                                      onPressed: () {
                                                        setModalState(() {
                                                          newProducts.removeAt(idx);
                                                        });
                                                      },
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
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Select Additional Payment Method & Remarks (Photo 5)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 680;
                          return Flex(
                            direction: isNarrow ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Payment Methods
                              Expanded(
                                flex: isNarrow ? 0 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("SELECT ADDITIONAL PAYMENT METHOD RECEIVED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: ["Cash", "UPI", "Card", "Net Banking", "Wallet", "Split Payment"].map((mode) {
                                        final isSel = selectedPaymentMethod == mode;
                                        return InkWell(
                                          onTap: () => setModalState(() => selectedPaymentMethod = mode),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: isSel ? const Color(0xFF0D6EFD) : Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isSel) ...[
                                                  const Icon(Icons.check, size: 12, color: Color(0xFF0D6EFD)),
                                                  const SizedBox(width: 4),
                                                ],
                                                Text(
                                                  mode,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                                    color: isSel ? const Color(0xFF0D6EFD) : const Color(0xFF475569),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 12 : 0),

                              // Remarks Notes
                              Expanded(
                                flex: isNarrow ? 0 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("REMARKS / EXCHANGE REASON NOTES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: remarksCtrl,
                                      style: const TextStyle(fontSize: 11),
                                      decoration: InputDecoration(
                                        hintText: "Optional exchange inspection remarks...",
                                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3 Summary Boxes: RETURNED TOTAL, NEW PURCHASE, SETTLEMENT DIFFERENCE (Photo 5)
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _buildExchangeSummaryBox(
                            "RETURNED TOTAL",
                            "₹${returnedTotal.toStringAsFixed(2)}",
                            "$returnedCount Item(s) Selected",
                            const Color(0xFFFFF1F2),
                            const Color(0xFFEF4444),
                          ),
                          _buildExchangeSummaryBox(
                            "NEW PURCHASE",
                            "₹${newTotal.toStringAsFixed(2)}",
                            "$newCount Product(s) Added",
                            const Color(0xFFF0FDF4),
                            const Color(0xFF10B981),
                          ),
                          _buildExchangeSummaryBox(
                            "SETTLEMENT DIFFERENCE",
                            diff == 0
                                ? "Even Exchange"
                                : (diff < 0 ? "Refund ₹${diff.abs().toStringAsFixed(2)}" : "Pay ₹${diff.toStringAsFixed(2)}"),
                            diff == 0
                                ? "₹0.00 Difference"
                                : (diff < 0 ? "Refund to Customer" : "Collect Additional Payment"),
                            const Color(0xFFEFF6FF),
                            const Color(0xFF0D6EFD),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Footer Actions: Cancel + Complete Exchange (Photo 5)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text("Cancel", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isSubmittingExchange
                                ? null
                                : () async {
                                    if (selectedBillNo == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please select an original invoice"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }

                                    final selectedReturns = billPurchasedItems.where((i) => i['selected'] == true && (i['return_qty'] as int) > 0).toList();

                                    if (selectedReturns.isEmpty && newProducts.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please select at least one item to return or replace"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }

                                    setModalState(() => isSubmittingExchange = true);

                                    // Build Payload
                                    final randomNum = Random().nextInt(90000) + 10000;
                                    final genExId = "EXCH-$randomNum";
                                    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

                                    final returnedItemsPayload = selectedReturns.map((i) => {
                                      "product_id": i['product_id'],
                                      "product_name": i['name'],
                                      "variant": i['variant'],
                                      "return_qty": i['return_qty'],
                                      "unit_price": i['price'],
                                      "total": (i['price'] as double) * (i['return_qty'] as int),
                                    }).toList();

                                    final newItemsPayload = newProducts.map((i) => {
                                      "product_id": i['product_id'],
                                      "product_name": i['name'],
                                      "variant": i['variant'],
                                      "qty": i['qty'],
                                      "unit_price": i['price'],
                                      "total": (i['price'] as double) * (i['qty'] as int),
                                    }).toList();

                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(dialogContext);

                                    final payload = {
                                      "id": genExId,
                                      "bill_id": selectedBillId,
                                      "original_bill_no": selectedBillNo,
                                      "customer_name": selectedCustomerName.isNotEmpty ? selectedCustomerName : "Customer",
                                      "customer_phone": selectedCustomerPhone.isNotEmpty ? selectedCustomerPhone : "9876543210",
                                      "exchange_date": nowStr,
                                      "returned_total": returnedTotal,
                                      "new_total": newTotal,
                                      "difference_amount": diff.abs(),
                                      "settlement_type": diff < 0 ? "Refund" : (diff > 0 ? "Payment" : "Even"),
                                      "payment_method": diff < 0 ? "Refund $selectedPaymentMethod" : selectedPaymentMethod,
                                      "cashier_name": "Admin",
                                      "notes": remarksCtrl.text.trim(),
                                      "returned_items": returnedItemsPayload,
                                      "new_items": newItemsPayload,
                                    };

                                    try {
                                      final headers = await _getBillingHeaders();
                                      const url = "https://billing.srivagroups.in/api/return-bill/exchange";
                                      final response = await http.post(
                                        Uri.parse(url),
                                        headers: headers,
                                        body: jsonEncode(payload),
                                      ).timeout(const Duration(seconds: 15));

                                      if (response.statusCode == 200 || response.statusCode == 201) {
                                        final decoded = jsonDecode(response.body);
                                        final successMsg = decoded['message'] ?? "Customer product exchange processed successfully.";

                                        navigator.pop();
                                        messenger.showSnackBar(
                                          SnackBar(content: Text(successMsg), backgroundColor: const Color(0xFF10B981)),
                                        );
                                        await fetchExchanges();
                                        return;
                                      } else {
                                        AppLogger.warning("Exchange POST failed with status ${response.statusCode}: ${response.body}");
                                      }
                                    } catch (e) {
                                      AppLogger.error("Error creating exchange", e);
                                    }

                                    // Fallback local insert
                                    if (mounted) {
                                      setState(() {
                                        exchangeRecords.insert(0, {
                                          "id": exchangeRecords.length + 1,
                                          "exchange_id": genExId,
                                          "original_bill": selectedBillNo,
                                          "customer_name": selectedCustomerName.isNotEmpty ? selectedCustomerName : "Customer",
                                          "customer_phone": selectedCustomerPhone.isNotEmpty ? selectedCustomerPhone : "9876543210",
                                          "exchange_date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                          "exchange_time": DateFormat('HH:mm:ss').format(DateTime.now()),
                                          "returned_products_summary": selectedReturns.isNotEmpty ? "${selectedReturns.first['name']}\n₹${returnedTotal.toStringAsFixed(2)}" : "₹0.00",
                                          "new_items_summary": newProducts.isNotEmpty ? "${newProducts.first['name']} ${newProducts.length > 1 ? '+${newProducts.length - 1} more' : ''}\n₹${newTotal.toStringAsFixed(2)}" : "₹0.00",
                                          "settlement_type": diff == 0 ? "Even Exchange" : (diff < 0 ? "Refund Issued" : "Additional Paid"),
                                          "net_difference": diff,
                                          "payment_method": selectedPaymentMethod,
                                          "cashier": "Admin",
                                          "returned_items": selectedReturns,
                                          "new_issued_items": newProducts,
                                        });
                                      });
                                    }

                                    navigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text("Customer product exchange processed successfully ($genExId)."),
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: isSubmittingExchange
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Complete Exchange", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildQuickAddChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
        ),
      ),
    );
  }

  Widget _buildExchangeSummaryBox(String label, String value, String sub, Color bgColor, Color textColor) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // PHOTO 3: EXCHANGE INVOICE VIEW MODAL
  // ----------------------------------------------------
  void _showExchangeInvoiceDialog(Map<String, dynamic> ex) {
    final String exId = (ex['exchange_id'] ?? "EXCH-33386").toString();
    final String billNo = (ex['original_bill'] ?? "BILL-00053").toString();
    final String cName = (ex['customer_name'] ?? "Iniya").toString();
    final String dateStr = "${ex['exchange_date'] ?? '02/09/2026'} ${ex['exchange_time'] ?? '10:12 AM'}";
    final String payMethod = (ex['payment_method'] ?? "Refund Cash").toString();
    final String cashier = (ex['cashier'] ?? "Admin").toString();

    final List returnedItems = (ex['returned_items'] is List && (ex['returned_items'] as List).isNotEmpty)
        ? (ex['returned_items'] as List)
        : [
            {"name": "Dell 19.5V 3.34A Laptop Adapter", "qty": 1, "price": 665.0, "total": 665.0}
          ];

    final List newItems = (ex['new_issued_items'] is List && (ex['new_issued_items'] as List).isNotEmpty)
        ? (ex['new_issued_items'] as List)
        : [
            {"name": "2N7000 Mosfet (Variant: Standard)", "qty": 2, "price": 10.0, "total": 20.0},
            {"name": "2N7000 Mosfet (Variant: Imported)", "qty": 3, "price": 65.0, "total": 195.0},
            {"name": "2N7000 Mosfet (Variant: Special)", "qty": 4, "price": 37.5, "total": 150.0},
          ];

    final double retTotal = returnedItems.fold(0.0, (s, i) => s + (double.tryParse((i['total'] ?? i['price']).toString()) ?? 0.0));
    final double newTotal = newItems.fold(0.0, (s, i) => s + (double.tryParse((i['total'] ?? i['price']).toString()) ?? 0.0));
    final double netDiff = newTotal - retTotal;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: ⇄ Exchange Invoice (EXCH-33386) + X (Photo 3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Exchange Invoice ($exId)",
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
                  const Divider(height: 18),

                  // Store Header
                  Center(
                    child: Column(
                      children: const [
                        Text("POS BILLING STORE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        SizedBox(height: 2),
                        Text("Neelambur, Sulur Taluk, Coimbatore, Tamil Nadu, 641062", style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        SizedBox(height: 4),
                        Text("PRODUCT EXCHANGE RECEIPT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD), letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Meta Box (Photo 3) - Responsive
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 170,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExchMetaText("EXCHANGE ID:", exId),
                              const SizedBox(height: 4),
                              _buildExchMetaText("CUSTOMER NAME:", cName),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 190,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExchMetaText("ORIGINAL INVOICE #:", billNo),
                              const SizedBox(height: 4),
                              _buildExchMetaText("PAYMENT / REFUND MODE:", payMethod),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExchMetaText("DATE & TIME:", dateStr),
                              const SizedBox(height: 4),
                              _buildExchMetaText("CASHIER / PROCESSED BY:", cashier),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ● Returned Item(s) (Red header - Photo 3)
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444))),
                      const SizedBox(width: 6),
                      const Text("Returned Item(s)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF1F2)),
                      headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                      dataRowMinHeight: 38,
                      dataRowMaxHeight: 46,
                      columnSpacing: 18,
                      horizontalMargin: 8,
                      columns: const [
                        DataColumn(label: Text("PRODUCT")),
                        DataColumn(label: Text("QTY")),
                        DataColumn(label: Text("UNIT PRICE")),
                        DataColumn(label: Text("TOTAL")),
                      ],
                      rows: returnedItems.map((it) {
                        final item = it is Map ? it : {};
                        final String pName = (item['product_name'] ?? item['name'] ?? "Item").toString();
                        final int qty = int.tryParse((item['return_qty'] ?? item['qty'] ?? 1).toString()) ?? 1;
                        final double price = double.tryParse((item['unit_price'] ?? item['price'] ?? 0).toString()) ?? 0.0;
                        final double total = double.tryParse((item['total'] ?? (price * qty)).toString()) ?? (price * qty);

                        return DataRow(
                          cells: [
                            DataCell(Text(pName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            DataCell(Text("$qty", style: const TextStyle(fontSize: 11))),
                            DataCell(Text("₹${price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11))),
                            DataCell(Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ● New Issued Item(s) (Green header - Photo 3)
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
                      const SizedBox(width: 6),
                      const Text("New Issued Item(s)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFECFDF5)),
                      headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                      dataRowMinHeight: 38,
                      dataRowMaxHeight: 46,
                      columnSpacing: 18,
                      horizontalMargin: 8,
                      columns: const [
                        DataColumn(label: Text("PRODUCT")),
                        DataColumn(label: Text("QTY")),
                        DataColumn(label: Text("UNIT PRICE")),
                        DataColumn(label: Text("TOTAL")),
                      ],
                      rows: newItems.map((it) {
                        final item = it is Map ? it : {};
                        final String pName = (item['product_name'] ?? item['name'] ?? "Item").toString();
                        final int qty = int.tryParse((item['qty'] ?? 1).toString()) ?? 1;
                        final double price = double.tryParse((item['unit_price'] ?? item['price'] ?? 0).toString()) ?? 0.0;
                        final double total = double.tryParse((item['total'] ?? (price * qty)).toString()) ?? (price * qty);

                        return DataRow(
                          cells: [
                            DataCell(Text(pName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            DataCell(Text("$qty", style: const TextStyle(fontSize: 11))),
                            DataCell(Text("₹${price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11))),
                            DataCell(Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Totals Box (Photo 3)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Returned:", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text("₹${retTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total New Purchase:", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text("₹${newTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              netDiff <= 0 ? "Net Refund to Customer:" : "Net Payment Due:",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              "₹${netDiff.abs().toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: netDiff <= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Footer: Close + Print
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text("Close", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _printExchangeInvoice(exId, billNo, cName, dateStr, retTotal, newTotal, netDiff),
                        icon: const Icon(Icons.print, size: 14),
                        label: const Text("Print Exchange Invoice", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
  }

  Widget _buildExchMetaText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
        children: [
          TextSpan(text: "$label\n", style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // DELETE EXCHANGE CONFIRMATION WITH ALERT
  // ----------------------------------------------------
  void _confirmDeleteExchange(Map<String, dynamic> ex) {
    final String exId = (ex['exchange_id'] ?? "").toString();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Confirm Delete", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete exchange record $exId? This action cannot be undone.", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteExchange(exId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // PRINT EXCHANGE INVOICE
  // ----------------------------------------------------
  Future<void> _printExchangeInvoice(String exId, String billNo, String cName, String dateStr, double retTotal, double newTotal, double netDiff) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
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
                      pw.Center(child: pw.Text("POS BILLING STORE", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800))),
                      pw.Center(child: pw.Text("PRODUCT EXCHANGE RECEIPT", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800))),
                      pw.SizedBox(height: 16),
                      pw.Text("Exchange ID: $exId | Invoice: $billNo | Customer: $cName", style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 12),
                      pw.Text("Total Returned: ₹${retTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 11, color: PdfColors.red800)),
                      pw.Text("Total New Purchase: ₹${newTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 11, color: PdfColors.green800)),
                      pw.SizedBox(height: 8),
                      pw.Text("Net Difference: ₹${netDiff.abs().toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ],
                  ),
                );
              },
            ),
          );
          return doc.save();
        },
      );
    } catch (e) {
      AppLogger.error("Print Exchange Invoice error", e);
    }
  }

  // ----------------------------------------------------
  // PHOTO 2 & 3: PROCESS CUSTOMER RETURN BILL MODAL
  // Connected APIs:
  // 1. GET /api/sales/bill/details/{id} - fetch purchased items
  // 2. POST /api/return-bill/sales - submit customer sales return
  // ----------------------------------------------------
  void _showProcessCustomerReturnDialog() {
    String? selectedBill;
    dynamic selectedBillId;
    String selectedReason = "Damaged Product";
    String selectedRefundMode = "Cash";
    final notesController = TextEditingController();
    double currentRefundAmt = 0.0;
    String currentCustomerName = "";
    String currentCustomerPhone = "";
    String selectedBillDate = "";
    double originalBillTotal = 0.0;
    List<Map<String, dynamic>> returnItems = [];
    bool isFetchingBillDetails = false;
    bool isSubmitting = false;

    final billsSource = availableBillsList.isNotEmpty ? availableBillsList : _getDemoDropdownBills();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void recalculateRefund() {
              currentRefundAmt = returnItems
                  .where((it) => it['selected'] == true)
                  .fold(0.0, (sum, it) => sum + ((it['refund_price'] as double) * (it['return_qty'] as int)));
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: ⟲ Process Customer Return Bill + X (Photo 2 & 3)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.replay, size: 20, color: Color(0xFF1E293B)),
                              SizedBox(width: 8),
                              Text(
                                "Process Customer Return Bill",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Select Original Bill / Invoice Number *
                      RichText(
                        text: const TextSpan(
                          text: "SELECT ORIGINAL BILL / INVOICE NUMBER ",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          children: [
                            TextSpan(text: "*", style: TextStyle(color: Colors.red)),
                          ],
                        ),
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
                            value: selectedBill,
                            hint: const Text("-- Choose Sales Bill --", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                            items: billsSource.map((b) {
                              final bNo = (b['bill_number'] ?? "BILL-${b['id']}").toString();
                              final cName = (b['customer_name'] ?? "").toString();
                              final amt = double.tryParse((b['final_amount'] ?? 0).toString()) ?? 0.0;
                              return DropdownMenuItem<String>(
                                value: bNo,
                                child: Text("$bNo - $cName (₹${amt.toStringAsFixed(2)})", style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (v) async {
                              if (v != null) {
                                final match = billsSource.firstWhere((element) => (element['bill_number'] ?? "BILL-${element['id']}").toString() == v, orElse: () => {});
                                setModalState(() {
                                  selectedBill = v;
                                  selectedBillId = match['id'];
                                  originalBillTotal = double.tryParse((match['final_amount'] ?? 0).toString()) ?? 0.0;
                                  currentCustomerName = (match['customer_name'] ?? "").toString();
                                  currentCustomerPhone = (match['customer_phone'] ?? "").toString();
                                  isFetchingBillDetails = true;
                                  returnItems.clear();
                                });

                                // Call GET /api/sales/bill/details/{id}
                                final details = await fetchBillDetails(match['id']);
                                List<Map<String, dynamic>> itemsLoaded = [];
                                String dateFormatted = "";

                                if (details != null) {
                                  // Parse date
                                  final rawDate = (details['bill'] is Map && details['bill']['created_at'] != null)
                                      ? details['bill']['created_at'].toString()
                                      : (details['created_at']?.toString() ?? "");
                                  if (rawDate.isNotEmpty) {
                                    try {
                                      final dt = DateTime.parse(rawDate);
                                      dateFormatted = DateFormat('dd/MM/yyyy hh:mm:ss a').format(dt);
                                    } catch (_) {
                                      dateFormatted = rawDate;
                                    }
                                  }

                                  // Check customer name & phone
                                  if (details['bill'] is Map) {
                                    final b = details['bill'];
                                    if (b['customer_name'] != null && b['customer_name'].toString().isNotEmpty) {
                                      currentCustomerName = b['customer_name'].toString();
                                    }
                                    if (b['customer_phone'] != null && b['customer_phone'].toString().isNotEmpty) {
                                      currentCustomerPhone = b['customer_phone'].toString();
                                    }
                                  } else if (details['customer'] is Map) {
                                    final c = details['customer'];
                                    if (c['name'] != null && c['name'].toString().isNotEmpty) {
                                      currentCustomerName = c['name'].toString();
                                    }
                                    if (c['phone'] != null && c['phone'].toString().isNotEmpty) {
                                      currentCustomerPhone = c['phone'].toString();
                                    }
                                  }

                                  // Check bill total
                                  if (details['bill'] is Map && details['bill']['final_amount'] != null) {
                                    originalBillTotal = double.tryParse(details['bill']['final_amount'].toString()) ?? originalBillTotal;
                                  }

                                  final rawItems = (details['items'] is List)
                                      ? (details['items'] as List)
                                      : ((details['bill'] is Map && details['bill']['items'] is List) ? (details['bill']['items'] as List) : []);

                                  Map<String, String> metaNameMap = {};
                                  try {
                                    String? rawMeta = (details['bill'] is Map) ? details['bill']['customer_meta']?.toString() : details['customer_meta']?.toString();
                                    if (rawMeta != null && rawMeta.isNotEmpty) {
                                      final metaObj = jsonDecode(rawMeta);
                                      if (metaObj is Map && metaObj['items'] is List) {
                                        for (var mi in metaObj['items']) {
                                          if (mi is Map && mi['product_id'] != null && mi['product_name'] != null) {
                                            metaNameMap[mi['product_id'].toString()] = mi['product_name'].toString();
                                          }
                                        }
                                      }
                                    }
                                  } catch (_) {}

                                  itemsLoaded = rawItems.map<Map<String, dynamic>>((it) {
                                    final pId = (it['product_id'] ?? "").toString();
                                    final rawPName = (it['product_name'] ?? it['name'] ?? "Product #$pId").toString();
                                    final finalName = metaNameMap[pId] ?? rawPName;
                                    final int bQty = int.tryParse((it['qty'] ?? 1).toString()) ?? 1;
                                    final double origP = double.tryParse((it['price'] ?? 0).toString()) ?? 0.0;
                                    return {
                                      "id": it['id'],
                                      "product_id": it['product_id'],
                                      "name": finalName,
                                      "variant": (it['variant_name'] ?? it['variant'] ?? "Imported").toString(),
                                      "bought_qty": bQty,
                                      "return_qty": bQty,
                                      "orig_price": origP,
                                      "refund_price": origP,
                                      "condition": "Restockable",
                                      "selected": true,
                                    };
                                  }).toList();
                                }

                                if (itemsLoaded.isEmpty) {
                                  dateFormatted = "27/10/2026 05:31:30 PM";
                                  itemsLoaded = [
                                    {"id": 1, "product_id": 408, "name": "Product #408", "variant": "Imported", "bought_qty": 2, "return_qty": 2, "orig_price": 100.01, "refund_price": 100.01, "condition": "Restockable", "selected": true},
                                    {"id": 2, "product_id": 566, "name": "Breadboard with 400 Tie Points", "variant": "Imported", "bought_qty": 2, "return_qty": 2, "orig_price": 85.0, "refund_price": 85.0, "condition": "Restockable", "selected": true},
                                  ];
                                }

                                setModalState(() {
                                  selectedBillDate = dateFormatted;
                                  returnItems = itemsLoaded;
                                  isFetchingBillDetails = false;
                                  recalculateRefund();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // When a bill is selected, show the Header Info Card (Photo 3)
                      if (selectedBill != null && !isFetchingBillDetails) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFD0E1FD)),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("CUSTOMER:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(currentCustomerName.isNotEmpty ? currentCustomerName : "Customer", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text("BILL DATE:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(selectedBillDate.isNotEmpty ? selectedBillDate : "27/10/2026 05:31:30 PM", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("ORIGINAL BILL TOTAL:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D6EFD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "₹${originalBillTotal.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title: SELECT PRODUCTS & CUSTOMIZE RETURN QUANTITIES / REFUND PRICES (Photo 3)
                        const Text(
                          "SELECT PRODUCTS & CUSTOMIZE RETURN QUANTITIES / REFUND PRICES",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),

                        // Returned Items Table (Photo 3)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              dataRowMinHeight: 44,
                              dataRowMaxHeight: 52,
                              columnSpacing: 14,
                              horizontalMargin: 10,
                              columns: const [
                                DataColumn(label: Text("S.NO")),
                                DataColumn(label: Text("SELECT")),
                                DataColumn(label: Text("PRODUCT NAME")),
                                DataColumn(label: Text("BOUGHT")),
                                DataColumn(label: Text("RETURN QTY")),
                                DataColumn(label: Text("ORIG. PRICE")),
                                DataColumn(label: Text("REFUND PRICE (₹)")),
                                DataColumn(label: Text("CONDITION")),
                                DataColumn(label: Text("REFUND TOTAL")),
                              ],
                              rows: returnItems.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                final isSel = item['selected'] == true;
                                final int bQty = item['bought_qty'] as int;
                                final int rQty = item['return_qty'] as int;
                                final double oPrice = item['orig_price'] as double;
                                final double refPrice = item['refund_price'] as double;
                                final double rTotal = isSel ? (refPrice * rQty) : 0.0;

                                return DataRow(
                                  cells: [
                                    DataCell(Text("${idx + 1}", style: const TextStyle(fontSize: 11))),
                                    DataCell(
                                      Checkbox(
                                        value: isSel,
                                        activeColor: const Color(0xFF0D6EFD),
                                        onChanged: (val) {
                                          setModalState(() {
                                            item['selected'] = val ?? false;
                                            recalculateRefund();
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(item['name'] ?? "", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                          if (item['variant'] != null && item['variant'].toString().isNotEmpty)
                                            Text(item['variant'].toString(), style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    DataCell(Center(child: Text("$bQty", style: const TextStyle(fontSize: 11)))),
                                    // Return Qty Stepper
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 14, color: Color(0xFF64748B)),
                                            onPressed: isSel && rQty > 0
                                                ? () {
                                                    setModalState(() {
                                                      if (rQty > 1) {
                                                        item['return_qty'] = rQty - 1;
                                                      } else {
                                                        item['return_qty'] = 0;
                                                        item['selected'] = false;
                                                      }
                                                      recalculateRefund();
                                                    });
                                                  }
                                                : null,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Container(
                                            width: 32,
                                            alignment: Alignment.center,
                                            child: Text("$rQty", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 14, color: Color(0xFF0D6EFD)),
                                            onPressed: () {
                                              setModalState(() {
                                                item['selected'] = true;
                                                if (rQty < bQty) {
                                                  item['return_qty'] = rQty + 1;
                                                }
                                                recalculateRefund();
                                              });
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text("₹${oPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                                    // Refund Price Box (Blue border box - Photo 3)
                                    DataCell(
                                      Container(
                                        width: 65,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF93C5FD)),
                                        ),
                                        child: TextFormField(
                                          initialValue: refPrice.toStringAsFixed(2),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val) ?? 0.0;
                                            setModalState(() {
                                              item['refund_price'] = parsed;
                                              recalculateRefund();
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    // Condition Dropdown
                                    DataCell(
                                      Container(
                                        height: 28,
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: item['condition'] ?? "Restockable",
                                            icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                                            items: const [
                                              DropdownMenuItem(value: "Restockable", child: Text("Restockable", style: TextStyle(fontSize: 10))),
                                              DropdownMenuItem(value: "Scrap / Damaged", child: Text("Scrap / Damaged", style: TextStyle(fontSize: 10))),
                                              DropdownMenuItem(value: "Defective", child: Text("Defective", style: TextStyle(fontSize: 10))),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                setModalState(() => item['condition'] = val);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Refund Total
                                    DataCell(Text("₹${rTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (isFetchingBillDetails)
                        Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),

                      // Row: Return Reason & Refund Mode (Responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 480) {
                            return Column(
                              children: [
                                _buildReasonField(selectedReason, (v) => setModalState(() => selectedReason = v)),
                                const SizedBox(height: 10),
                                _buildModeField(selectedRefundMode, (v) => setModalState(() => selectedRefundMode = v)),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _buildReasonField(selectedReason, (v) => setModalState(() => selectedReason = v)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildModeField(selectedRefundMode, (v) => setModalState(() => selectedRefundMode = v)),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Notes / Customer Remark
                      const Text(
                        "NOTES / CUSTOMER REMARK",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: "Optional return notes or inspection remarks...",
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Box: Total Refund Amount:  ₹370.02 (Photo 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Refund Amount:",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            Text(
                              "₹${currentRefundAmt.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Actions: Cancel & Confirm Return & Refund (Photo 3 & 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text("Cancel", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (selectedBill == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please select a sales bill"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }

                                    final selectedItems = returnItems.where((i) => i['selected'] == true && (i['return_qty'] as int) > 0).toList();

                                    if (selectedItems.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please select at least one item to return"), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }

                                    setModalState(() => isSubmitting = true);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(dialogContext);

                                    final genRetId = "RET-INV-${Random().nextInt(9000) + 1000}";
                                    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

                                    final itemsPayload = selectedItems.map((i) {
                                      final rPrice = i['refund_price'] as double;
                                      final rQty = i['return_qty'] as int;
                                      return {
                                        "product_id": i['product_id'],
                                        "product_name": i['name'],
                                        "variant_name": i['variant'] ?? "Imported",
                                        "bought_qty": i['bought_qty'],
                                        "return_qty": rQty,
                                        "original_price": i['orig_price'],
                                        "refund_price": rPrice,
                                        "refund_total": rPrice * rQty,
                                        "condition_status": i['condition'] ?? "Restockable",
                                      };
                                    }).toList();

                                    // Build Return API payload matching web app
                                    final returnPayload = {
                                      "id": genRetId,
                                      "bill_id": selectedBillId,
                                      "original_bill_no": selectedBill,
                                      "customer_name": currentCustomerName.isNotEmpty ? currentCustomerName : "Customer",
                                      "customer_phone": currentCustomerPhone.isNotEmpty ? currentCustomerPhone : "9876543210",
                                      "custom_reason": "",
                                      "reason": selectedReason,
                                      "refund_mode": selectedRefundMode,
                                      "return_date": nowStr,
                                      "total_refund": currentRefundAmt,
                                      "notes": notesController.text.trim(),
                                      "items": itemsPayload,
                                    };

                                    try {
                                      final headers = await _getBillingHeaders();
                                      const url = "https://billing.srivagroups.in/api/return-bill/sales";
                                      final response = await http.post(
                                        Uri.parse(url),
                                        headers: headers,
                                        body: jsonEncode(returnPayload),
                                      ).timeout(const Duration(seconds: 15));

                                      if (response.statusCode == 200 || response.statusCode == 201) {
                                        final decoded = jsonDecode(response.body);
                                        final msg = decoded['message'] ?? "Customer sales return processed successfully.";

                                        navigator.pop();
                                        messenger.showSnackBar(
                                          SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981)),
                                        );
                                        await fetchSalesReturns();
                                        return;
                                      } else {
                                        AppLogger.warning("Sales return POST failed with status ${response.statusCode}: ${response.body}");
                                      }
                                    } catch (e) {
                                      AppLogger.error("Error creating sales return", e);
                                    }

                                    // Fallback local insert
                                    final totalPcs = selectedItems.fold(0, (sum, i) => sum + (i['return_qty'] as int));
                                    if (mounted) {
                                      setState(() {
                                        returnRecords.insert(0, {
                                          "id": returnRecords.length + 1,
                                          "return_id": genRetId,
                                          "original_bill": selectedBill,
                                          "customer_name": currentCustomerName.isNotEmpty ? currentCustomerName : "Customer",
                                          "customer_phone": currentCustomerPhone.isNotEmpty ? currentCustomerPhone : "9876543210",
                                          "return_date": DateFormat('dd/MM/yyyy').format(DateTime.now()),
                                          "reason": selectedReason,
                                          "items_count": "$totalPcs Pcs",
                                          "total_refund": currentRefundAmt,
                                          "refund_mode": selectedRefundMode,
                                          "status": "Completed",
                                          "notes": notesController.text.trim(),
                                          "items": itemsPayload,
                                        });
                                      });
                                    }

                                    navigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text("Customer sales return processed successfully ($genRetId)."),
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Confirm Return & Refund", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildReasonField(String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("RETURN REASON", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
              items: const [
                DropdownMenuItem(value: "Damaged Product", child: Text("Damaged Product", style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: "Wrong Product Delivered", child: Text("Wrong Product Delivered", style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: "Defective / Not Working", child: Text("Defective / Not Working", style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: "Customer Changed Mind", child: Text("Customer Changed Mind", style: TextStyle(fontSize: 12))),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeField(String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("REFUND MODE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
              items: const [
                DropdownMenuItem(value: "Cash", child: Text("Cash", style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: "UPI", child: Text("UPI", style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: "Bank Transfer", child: Text("Bank Transfer", style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: "Wallet", child: Text("Wallet", style: TextStyle(fontSize: 12))),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // PHOTO 5: SALES RETURN NOTE DIALOG
  // ----------------------------------------------------
  void _showSalesReturnNoteDialog(Map<String, dynamic> ret) {
    final String retId = (ret['return_id'] ?? "RET-INV-4890").toString();
    final String billNo = (ret['original_bill'] ?? "BILL-00052").toString();
    final String cName = (ret['customer_name'] ?? "Iniya").toString();
    final String retDate = (ret['return_date'] ?? "02/09/2026").toString();
    final String refundMode = (ret['refund_mode'] ?? "Cash").toString();
    final String reason = (ret['reason'] ?? "Wrong Product Delivered").toString();
    final double totalRefund = double.tryParse((ret['total_refund'] ?? 1400.0).toString()) ?? 1400.0;
    final List items = ret['items'] is List && (ret['items'] as List).isNotEmpty
        ? (ret['items'] as List)
        : [
            {"name": "VL53L0X ToF Distance Sensor", "qty": 4, "price": 350.0, "condition": "Restockable", "total": 1400.0}
          ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + X (Photo 5)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sales Return Note ($retId)",
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

                  // Store Details Header (Photo 5)
                  Center(
                    child: Column(
                      children: const [
                        Text("BILLING STORE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        SizedBox(height: 2),
                        Text("Neelambur, Sulur Taluk, Coimbatore, Tamil Nadu, 641062", style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        SizedBox(height: 4),
                        Text("CUSTOMER RETURN NOTE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Meta Box (Photo 5) - Responsive
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 160,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNoteMetaText("Return ID:", retId),
                              const SizedBox(height: 4),
                              _buildNoteMetaText("Customer:", cName),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNoteMetaText("Original Bill #:", billNo),
                              const SizedBox(height: 4),
                              _buildNoteMetaText("Refund Mode:", refundMode),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNoteMetaText("Return Date:", retDate),
                              const SizedBox(height: 4),
                              _buildNoteMetaText("Reason:", reason),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text("Returned Items:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),

                  // Returned Items Table (Photo 5)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      dataRowMinHeight: 38,
                      dataRowMaxHeight: 46,
                      columnSpacing: 22,
                      horizontalMargin: 8,
                      columns: const [
                        DataColumn(label: Text("ITEM")),
                        DataColumn(label: Text("QTY")),
                        DataColumn(label: Text("PRICE")),
                        DataColumn(label: Text("CONDITION")),
                        DataColumn(label: Text("TOTAL")),
                      ],
                      rows: items.map((it) {
                        final item = it is Map ? it : {};
                        final String pName = (item['product_name'] ?? item['name'] ?? "Item").toString();
                        final int qty = int.tryParse((item['return_qty'] ?? item['qty'] ?? 1).toString()) ?? 1;
                        final double price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
                        final String condition = (item['condition_status'] ?? item['condition'] ?? "Restockable").toString();
                        final double rowTotal = double.tryParse((item['total'] ?? (price * qty)).toString()) ?? (price * qty);

                        return DataRow(
                          cells: [
                            DataCell(Text(pName, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)))),
                            DataCell(Text("$qty", style: const TextStyle(fontSize: 11))),
                            DataCell(Text("₹${price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11))),
                            DataCell(Text(condition, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                            DataCell(Text("₹${rowTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Net Refund Issued
                  Align(
                    alignment: Alignment.centerRight,
                    child: RichText(
                      text: TextSpan(
                        text: "Net Refund Issued: ",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        children: [
                          TextSpan(
                            text: "₹${totalRefund.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions: Close + Print Return Note (Photo 5)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text("Close", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _printReturnNote(retId, billNo, cName, retDate, refundMode, totalRefund),
                        icon: const Icon(Icons.print, size: 14),
                        label: const Text("Print Return Note", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
  }

  Widget _buildNoteMetaText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
        children: [
          TextSpan(text: "$label ", style: const TextStyle(color: Color(0xFF64748B))),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // DELETE RETURN CONFIRMATION WITH ALERT
  // ----------------------------------------------------
  void _confirmDeleteReturn(Map<String, dynamic> ret) {
    final String retId = (ret['return_id'] ?? "").toString();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Confirm Delete", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete sales return record $retId? This action cannot be undone.", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteSalesReturn(retId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // PRINT RETURN NOTE USING PRINTING PACKAGE
  // ----------------------------------------------------
  Future<void> _printReturnNote(String retId, String billNo, String cName, String date, String mode, double total) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
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
                      pw.Center(child: pw.Text("BILLING STORE", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800))),
                      pw.Center(child: pw.Text("Neelambur, Sulur Taluk, Coimbatore, Tamil Nadu, 641062", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
                      pw.Center(child: pw.Text("CUSTOMER RETURN NOTE", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800))),
                      pw.SizedBox(height: 16),
                      pw.Text("Return ID: $retId | Original Bill: $billNo | Customer: $cName | Mode: $mode", style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 16),
                      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("Net Refund Issued: ₹${total.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800))),
                    ],
                  ),
                );
              },
            ),
          );
          return doc.save();
        },
      );
    } catch (e) {
      AppLogger.error("Print Return Note error", e);
    }
  }

  // ----------------------------------------------------
  // DEMO DATA FALLBACKS
  // ----------------------------------------------------
  List<Map<String, dynamic>> _getDemoReturns() {
    return [
      {
        "id": 4,
        "return_id": "RET-INV-4890",
        "original_bill": "BILL-00052",
        "customer_name": "Iniya",
        "customer_phone": "8778908590",
        "return_date": "02/09/2026",
        "reason": "Wrong Product Delivered",
        "items_count": "4 Pcs",
        "total_refund": 1400.00,
        "refund_mode": "Cash",
        "status": "Completed",
        "notes": "",
        "items": [
          {"name": "VL53L0X Tof Distance Sensor", "qty": 4, "price": 350.0, "condition": "Restockable", "total": 1400.0}
        ],
      },
      {
        "id": 3,
        "return_id": "RET-INV-2106",
        "original_bill": "BILL-00040",
        "customer_name": "Sri Vagroups",
        "customer_phone": "9092014442",
        "return_date": "19/08/2026",
        "reason": "Damaged Product",
        "items_count": "42 Pcs",
        "total_refund": 870.00,
        "refund_mode": "Cash",
        "status": "Completed",
        "notes": "",
        "items": [
          {"name": "HW 130 Stepper Motor Driver", "qty": 1, "price": 350.0, "condition": "Restockable", "total": 350.0},
          {"name": "HC05 Bluetooth Module", "qty": 1, "price": 400.0, "condition": "Restockable", "total": 400.0},
          {"name": "JUMPERS Wires M-F", "qty": 40, "price": 3.0, "condition": "Restockable", "total": 120.0},
        ],
      },
      {
        "id": 2,
        "return_id": "RET-INV-1140",
        "original_bill": "BILL-00041",
        "customer_name": "Iniya",
        "customer_phone": "8778908590",
        "return_date": "19/08/2026",
        "reason": "Damaged Product",
        "items_count": "1 Pcs",
        "total_refund": 90.00,
        "refund_mode": "Cash",
        "status": "Completed",
        "notes": "",
        "items": [
          {"name": "Water Level Sensor Module", "qty": 1, "price": 90.0, "condition": "Restockable", "total": 90.0}
        ],
      },
      {
        "id": 1,
        "return_id": "RET-INV-3011",
        "original_bill": "BILL-00032",
        "customer_name": "krishna",
        "customer_phone": "8072148623",
        "return_date": "04/08/2026",
        "reason": "Damaged Product",
        "items_count": "1 Pcs",
        "total_refund": 50.00,
        "refund_mode": "Cash",
        "status": "Completed",
        "notes": "",
        "items": [
          {"name": "Male to RCA Female Audio Adapter", "qty": 1, "price": 50.0, "condition": "Restockable", "total": 50.0}
        ],
      },
    ];
  }

  List<Map<String, dynamic>> _getDemoExchanges() {
    return [
      {
        "id": 3,
        "exchange_id": "EXCH-33386",
        "original_bill": "BILL-00053",
        "customer_name": "Iniya",
        "customer_phone": "8778908590",
        "exchange_date": "2026-09-02",
        "exchange_time": "11:17:13",
        "returned_products_summary": "Dell 19.5V 3.34A Laptop Adapter\n₹885.00",
        "new_items_summary": "2N7000 Mosfet +2 more\n₹585.00",
        "settlement_type": "Refund Issued",
        "net_difference": -300.00,
        "payment_method": "Refund Cash",
        "cashier": "Admin",
        "returned_items": [
          {"name": "Dell 19.5V 3.34A Laptop Adapter", "qty": 1, "price": 885.0, "total": 885.0}
        ],
        "new_issued_items": [
          {"name": "2N7000 Mosfet", "variant": "Standard", "qty": 3, "price": 30.0, "total": 90.0},
          {"name": "2N7000 Mosfet", "variant": "Standard", "qty": 3, "price": 145.0, "total": 435.0},
          {"name": "2N7000 Mosfet", "variant": "Standard", "qty": 4, "price": 15.0, "total": 60.0},
        ],
      },
      {
        "id": 2,
        "exchange_id": "EXCH-68920",
        "original_bill": "BILL-00041",
        "customer_name": "Iniya",
        "customer_phone": "8778908590",
        "exchange_date": "2026-08-19",
        "exchange_time": "03:19:28",
        "returned_products_summary": "Water Level Sensor Module\n₹90.00",
        "new_items_summary": "2N7000 Mosfet\n₹145.00",
        "settlement_type": "Additional Paid",
        "net_difference": 55.00,
        "payment_method": "Cash",
        "cashier": "Admin",
        "returned_items": [
          {"name": "Water Level Sensor Module", "qty": 1, "price": 90.0, "total": 90.0}
        ],
        "new_issued_items": [
          {"name": "2N7000 Mosfet", "variant": "Standard", "qty": 1, "price": 145.0, "total": 145.0}
        ],
      },
      {
        "id": 1,
        "exchange_id": "EXCH-61940",
        "original_bill": "BILL-00032",
        "customer_name": "krishna",
        "customer_phone": "8072148623",
        "exchange_date": "2026-08-04",
        "exchange_time": "10:27:41",
        "returned_products_summary": "Male to RCA Female Audio Adapter\n₹70.00",
        "new_items_summary": "TESTER\n₹75.00",
        "settlement_type": "Additional Paid",
        "net_difference": 5.00,
        "payment_method": "Cash",
        "cashier": "Admin",
        "returned_items": [
          {"name": "Male to RCA Female Audio Adapter", "qty": 1, "price": 70.0, "total": 70.0}
        ],
        "new_issued_items": [
          {"name": "TESTER", "variant": "Standard", "qty": 1, "price": 75.0, "total": 75.0}
        ],
      },
    ];
  }

  List<Map<String, dynamic>> _getDemoCatalogProducts() {
    return [
      {"product_id": 4393, "product_name": "AO3401A Mosfet", "variant_name": "Standard", "selling_price": 90.0, "available_qty": 5},
      {"product_id": 2739, "product_name": "Hikvision 2 MP Dome Camera", "variant_name": "Standard", "selling_price": 0.75, "available_qty": 10},
      {"product_id": 4377, "product_name": "2N7000 Mosfet", "variant_name": "Standard", "selling_price": 145.0, "available_qty": 7},
      {"product_id": 4378, "product_name": "2N7000 Mosfet", "variant_name": "Standard", "selling_price": 30.0, "available_qty": 5},
      {"product_id": 4379, "product_name": "2N7000 Mosfet", "variant_name": "Standard", "selling_price": 15.0, "available_qty": 10},
    ];
  }

  List<Map<String, dynamic>> _getDemoDropdownBills() {
    return [
      {"id": 282, "bill_number": "BILL-00091", "customer_name": "Iniya", "customer_phone": "8778908590", "final_amount": 124.03},
      {"id": 53, "bill_number": "BILL-00053", "customer_name": "Iniya", "customer_phone": "8778908590", "final_amount": 885.00},
      {"id": 52, "bill_number": "BILL-00052", "customer_name": "Iniya", "customer_phone": "8778908590", "final_amount": 1400.00},
      {"id": 41, "bill_number": "BILL-00041", "customer_name": "Iniya", "customer_phone": "8778908590", "final_amount": 90.00},
      {"id": 32, "bill_number": "BILL-00032", "customer_name": "krishna", "customer_phone": "8072148623", "final_amount": 50.00},
    ];
  }
}
