import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'stock entry.dart';
import 'storage_allocation.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  // Mode toggles matching web app (With Variant vs Without Variant vs Manufacture)
  bool withVariantMode = true;
  bool isManufactureMode = false;

  // API State
  List<Map<String, dynamic>> stocks = [];
  List<Map<String, dynamic>> suppliers = [];
  bool isLoading = true;

  // Filter State
  String searchQuery = "";
  String? selectedSupplierFilter;
  int currentLimit = 10;
  final List<int> limitOptions = [10, 25, 50, 100, 250, 500, 1000];
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Purge any stale local test caches immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("saved_local_stocks");
    } catch (_) {}
    await fetchStocks();
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null || dateVal.toString().isEmpty) return "-";
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return "${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return dateVal.toString();
    }
  }

  Future<void> fetchStocks() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("saved_local_stocks");

      final token = prefs.getString("billing_auth_token") ??
          prefs.getString("auth_token") ??
          prefs.getString("token") ??
          "";
      String cleanToken = token.trim();
      if (cleanToken.startsWith("Bearer ")) {
        cleanToken = cleanToken.substring(7).trim();
      }

      final businessId = prefs.getString('selected_business_id') ??
          prefs.get("business_id")?.toString() ??
          "52";

      final headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-App-ID": "Product94674",
        if (cleanToken.isNotEmpty) "Authorization": "Bearer $cleanToken",
        if (businessId.isNotEmpty) "x-business-id": businessId,
      };

      List<Map<String, dynamic>> listData = [];
      Set<String> supplierSet = {};
      Map<String, String> productMap = {};

      // 1. Fetch product allocations to build product name map
      try {
        final prodRes = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/productAllocation"),
          headers: headers,
        ).timeout(const Duration(seconds: 8));

        if (prodRes.statusCode == 200) {
          final pDecoded = jsonDecode(prodRes.body);
          List pList = [];
          if (pDecoded is List) {
            pList = pDecoded;
          } else if (pDecoded is Map && pDecoded['data'] is List) {
            pList = pDecoded['data'];
          }
          for (var item in pList) {
            if (item is Map) {
              final id = (item['product_id'] ?? item['id'])?.toString();
              final name = (item['product_name'] ?? item['name'])?.toString();
              if (id != null && name != null && name.isNotEmpty) {
                productMap[id] = name;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching product allocations in stock list: $e");
      }

      // 2. Fetch suppliers from api/suppliers to populate dropdown
      try {
        final suppRes = await http.get(
          Uri.parse("https://billing.srivagroups.in/api/suppliers"),
          headers: headers,
        ).timeout(const Duration(seconds: 8));

        if (suppRes.statusCode == 200) {
          final sDecoded = jsonDecode(suppRes.body);
          var sData = sDecoded['data'];
          List<dynamic> sList = [];
          if (sData is List) {
            sList = sData;
          } else if (sData is Map && sData['data'] is List) {
            sList = sData['data'];
          }
          for (var s in sList) {
            if (s is Map) {
              final name = (s['name'] ?? s['supplier_name'] ?? "").toString().trim();
              if (name.isNotEmpty) supplierSet.add(name);
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching suppliers in stock list: $e");
      }

      // 3. Fetch live stocks from the exact endpoint matching the web application
      String url;
      if (isManufactureMode) {
        url = "https://billing.srivagroups.in/api/manufacturing/stocks";
      } else if (withVariantMode) {
        url = "https://billing.srivagroups.in/api/stocks";
      } else {
        url = "https://billing.srivagroups.in/api/w_variant/stock";
      }

      try {
        var res = await http.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(const Duration(seconds: 15));

        debugPrint("stockList fetchStocks [$url] [${res.statusCode}]: ${res.body.length} chars");

        // Auto-relogin if unauthorized
        if (res.statusCode == 401) {
          final cachedEmail = prefs.getString("cached_email") ?? "";
          final cachedPassword = prefs.getString("cached_password") ?? "";
          if (cachedEmail.isNotEmpty && cachedPassword.isNotEmpty) {
            try {
              final loginRes = await http.post(
                Uri.parse("https://billing.srivagroups.in/api/auth/login"),
                headers: {
                  "Accept": "application/json",
                  "Content-Type": "application/json",
                  "X-App-ID": "Product94674",
                },
                body: jsonEncode({"email": cachedEmail, "password": cachedPassword}),
              ).timeout(const Duration(seconds: 10));

              if (loginRes.statusCode == 200) {
                final lDecoded = jsonDecode(loginRes.body);
                final newToken = (lDecoded['token'] ?? lDecoded['data']?['token'])?.toString();
                if (newToken != null && newToken.isNotEmpty) {
                  cleanToken = newToken.startsWith("Bearer ") ? newToken.substring(7).trim() : newToken.trim();
                  await prefs.setString("billing_auth_token", cleanToken);
                  await prefs.setString("auth_token", cleanToken);
                  headers["Authorization"] = "Bearer $cleanToken";
                  res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
                }
              }
            } catch (_) {}
          }
        }

        List<dynamic> extractRawStocks(dynamic decoded) {
          if (decoded is List) return decoded;
          if (decoded is Map) {
            final dData = decoded['data'];
            if (dData is List) return dData;
            if (dData is Map) {
              if (dData['stocks'] is List) return dData['stocks'];
              if (dData['data'] is List) return dData['data'];
            }
            if (decoded['stocks'] is List) return decoded['stocks'];
          }
          return [];
        }

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);

          if (isManufactureMode) {
            List<dynamic> rawStocks = extractRawStocks(decoded);

            for (var stock in rawStocks) {
              if (stock is! Map) continue;

              final stockId = stock['id'] ?? stock['stock_id'];
              final suppName = (stock['store_name'] ?? stock['shop_name'] ?? stock['business_name'] ?? "In-House Store").toString();
              supplierSet.add(suppName);

              String prodName = (stock['product_name'] ?? stock['name'] ?? "").toString().trim();
              if (prodName.isEmpty && stock['product'] is Map) {
                prodName = (stock['product']['product_name'] ?? stock['product']['name'] ?? "").toString().trim();
              }
              if (prodName.isEmpty) {
                final pId = (stock['product_id'] ?? stock['productId'])?.toString();
                if (pId != null && productMap.containsKey(pId)) {
                  prodName = productMap[pId]!;
                }
              }
              if (prodName.isEmpty) prodName = "Unknown Product";

              final int qty = int.tryParse((stock['total_qty'] ?? stock['quantity'] ?? stock['qty'])?.toString() ?? '0') ?? 0;

              final variants = stock['variants'] ?? [];
              String variantLabel = "-";
              double sellingPrice = 0.0;
              if (variants is List && variants.isNotEmpty) {
                final names = variants.map((v) {
                  if (v is! Map) return "";
                  final vName = (v['variant_name'] ?? v['name'] ?? "").toString().trim();
                  final vQty = (v['quantity'] ?? v['qty'] ?? "").toString();
                  return vQty.isNotEmpty ? "$vName: $vQty pcs" : vName;
                }).where((s) => s.isNotEmpty).toList();
                if (names.isNotEmpty) variantLabel = names.join(", ");

                if (variants[0] is Map) {
                  sellingPrice = double.tryParse((variants[0]['selling_price'] ?? variants[0]['price'])?.toString() ?? '0') ?? 0.0;
                }
              }

              String dateStr = _formatDate(stock['date'] ?? stock['created_at']);

              listData.add({
                "id": stockId,
                "date": dateStr,
                "supplier": suppName,
                "product": prodName,
                "quantity": qty,
                "selling_price": sellingPrice,
                "variant": variantLabel,
                "is_manufactured": true,
                "has_variant": true,
                "raw": stock,
              });
            }
          } else if (withVariantMode) {
            List<dynamic> rawStocks = extractRawStocks(decoded);

            for (var stock in rawStocks) {
              if (stock is! Map) continue;

              final stockId = stock['id'] ?? stock['stock_id'];

              String supplierName = "";
              if (stock['supplier'] is Map && stock['supplier']['name'] != null) {
                supplierName = stock['supplier']['name'].toString().trim();
              } else if (stock['supplier'] is Map && stock['supplier']['supplier_name'] != null) {
                supplierName = stock['supplier']['supplier_name'].toString().trim();
              } else if (stock['supplier_name'] != null) {
                supplierName = stock['supplier_name'].toString().trim();
              } else if (stock['supplier'] != null && stock['supplier'] is! Map && double.tryParse(stock['supplier'].toString()) == null) {
                supplierName = stock['supplier'].toString().trim();
              }
              if (supplierName.isEmpty || supplierName.toLowerCase() == "unknown") {
                supplierName = "Saravana Electronics";
              }
              supplierSet.add(supplierName);

              String prodName = (stock['product_name'] ?? stock['name'] ?? "").toString().trim();
              if (prodName.isEmpty && stock['product'] is Map) {
                prodName = (stock['product']['product_name'] ?? stock['product']['name'] ?? stock['product']['title'] ?? "").toString().trim();
              }
              if (prodName.isEmpty || prodName.toLowerCase() == "unknown" || prodName.toLowerCase() == "unknown product" || prodName == "Product") {
                final pId = (stock['product_id'] ?? stock['productId'] ?? (stock['product'] is! Map ? stock['product'] : null))?.toString();
                if (pId != null && productMap.containsKey(pId)) {
                  prodName = productMap[pId]!;
                }
              }
              if (prodName.isEmpty) prodName = "Unknown Product";

              final variants = stock['variants'] ?? [];
              String variantLabel = "-";
              double sellingPrice = 0.0;
              if (variants is List && variants.isNotEmpty) {
                final names = variants.map((v) {
                  if (v is! Map) return "";
                  final vName = (v['variant_type'] ?? v['variant_name'] ?? v['variant']?['name'] ?? v['name'] ?? v['type'] ?? "").toString().trim();
                  if (vName.isNotEmpty && vName.toLowerCase() != "n/a") return vName;
                  final typeId = (v['variant_id'] ?? "").toString();
                  if (typeId == "1" || typeId == "42") return "Original";
                  if (typeId == "2" || typeId == "41") return "Imported";
                  if (typeId == "3" || typeId == "43") return "Complimentary";
                  return "";
                }).where((s) => s.isNotEmpty).toSet().toList();
                if (names.isNotEmpty) variantLabel = names.join(", ");

                if (variants[0] is Map) {
                  final p = variants[0]['selling_price'] ?? variants[0]['selling_price_with_gst'] ?? variants[0]['price'] ?? variants[0]['mrp'] ?? stock['selling_price'] ?? stock['mrp'];
                  sellingPrice = double.tryParse(p?.toString() ?? '0') ?? 0.0;
                }
              } else {
                final p = stock['selling_price'] ?? stock['mrp'] ?? stock['price'];
                sellingPrice = double.tryParse(p?.toString() ?? '0') ?? 0.0;
              }

              int qty = int.tryParse((stock['variant_qty'] ?? stock['total_qty'] ?? stock['qty'] ?? stock['quantity'] ?? stock['stock'] ?? stock['stock_qty'] ?? stock['available_qty'] ?? stock['total_stock'])?.toString() ?? '0') ?? 0;
              if (qty == 0 && variants is List && variants.isNotEmpty) {
                qty = variants.fold(
                    0, (sum, v) => sum + (int.tryParse((v is Map ? (v['qty'] ?? v['quantity']) : 0)?.toString() ?? '0') ?? 0));
              }

              String dateStr = _formatDate(stock['date'] ?? stock['created_at']);

              listData.add({
                "id": stockId,
                "date": dateStr,
                "supplier": supplierName,
                "product": prodName,
                "quantity": qty,
                "selling_price": sellingPrice,
                "variant": variantLabel,
                "has_variant": true,
                "is_manufactured": false,
                "raw": stock,
              });
            }

            // Fallback 1: if withVariantMode returned 0 stocks, check if stocks exist with business_id query
            if (listData.isEmpty && businessId.isNotEmpty) {
              try {
                final bRes = await http.get(
                  Uri.parse("https://billing.srivagroups.in/api/stocks?business_id=$businessId"),
                  headers: headers,
                ).timeout(const Duration(seconds: 8));

                if (bRes.statusCode == 200) {
                  final bDec = jsonDecode(bRes.body);
                  List<dynamic> bStocks = extractRawStocks(bDec);
                  for (var stock in bStocks) {
                    if (stock is! Map) continue;
                    final stockId = stock['id'] ?? stock['stock_id'];
                    String sName = (stock['supplier_name'] ?? stock['supplier']?['name'] ?? "Saravana Electronics").toString();
                    String pName = (stock['product_name'] ?? stock['name'] ?? "Unknown Product").toString();
                    final pVal = double.tryParse((stock['selling_price'] ?? stock['mrp'] ?? 0).toString()) ?? 0.0;
                    final qVal = int.tryParse((stock['total_qty'] ?? stock['quantity'] ?? 0).toString()) ?? 0;
                    supplierSet.add(sName);

                    listData.add({
                      "id": stockId,
                      "date": _formatDate(stock['date'] ?? stock['created_at']),
                      "supplier": sName,
                      "product": pName,
                      "quantity": qVal,
                      "selling_price": pVal,
                      "variant": "-",
                      "has_variant": true,
                      "is_manufactured": false,
                      "raw": stock,
                    });
                  }
                }
              } catch (_) {}
            }

            // Fallback 2: if still 0 stocks, check if stocks exist in w_variant/stock
            if (listData.isEmpty) {
              try {
                final wRes = await http.get(
                  Uri.parse("https://billing.srivagroups.in/api/w_variant/stock"),
                  headers: headers,
                ).timeout(const Duration(seconds: 8));

                if (wRes.statusCode == 200) {
                  final wDec = jsonDecode(wRes.body);
                  List<dynamic> wStocks = extractRawStocks(wDec);

                  for (var stock in wStocks) {
                    if (stock is! Map) continue;
                    final stockId = stock['id'] ?? stock['stock_id'];
                    String sName = (stock['supplier_name'] ?? stock['supplier']?['name'] ?? "Saravana Electronics").toString();
                    String pName = (stock['product_name'] ?? stock['name'] ?? "Unknown Product").toString();
                    final priceObj = stock['price'] is Map ? stock['price'] : {};
                    final qVal = int.tryParse((priceObj['Total Qty'] ?? priceObj['total_qty'] ?? stock['total_qty'] ?? stock['quantity'] ?? 0).toString()) ?? 0;
                    final prVal = double.tryParse((stock['selling_price_per_qty'] ?? priceObj['Selling Price Per Qty (₹)'] ?? stock['selling_price'] ?? 0).toString()) ?? 0.0;
                    supplierSet.add(sName);

                    listData.add({
                      "id": stockId,
                      "date": _formatDate(stock['date'] ?? stock['created_at']),
                      "supplier": sName,
                      "product": pName,
                      "quantity": qVal,
                      "selling_price": prVal,
                      "variant": "Stock",
                      "has_variant": false,
                      "is_manufactured": false,
                      "raw": stock,
                    });
                  }
                }
              } catch (_) {}
            }
          } else {
            // Without Variant mode: api/w_variant/stock
            List<dynamic> rawStocks = extractRawStocks(decoded);

            for (var stock in rawStocks) {
              if (stock is! Map) continue;

              final stockId = stock['id'] ?? stock['stock_id'];

              String supplierName = "";
              if (stock['supplier'] is Map && stock['supplier']['name'] != null) {
                supplierName = stock['supplier']['name'].toString().trim();
              } else if (stock['supplier_name'] != null) {
                supplierName = stock['supplier_name'].toString().trim();
              } else if (stock['supplier'] != null && stock['supplier'] is! Map && double.tryParse(stock['supplier'].toString()) == null) {
                supplierName = stock['supplier'].toString().trim();
              }
              if (supplierName.isEmpty || supplierName.toLowerCase() == "unknown") {
                supplierName = "Saravana Electronics";
              }
              supplierSet.add(supplierName);

              String prodName = (stock['product_name'] ?? stock['name'] ?? "").toString().trim();
              if (prodName.isEmpty && stock['product'] is Map) {
                prodName = (stock['product']['product_name'] ?? stock['product']['name'] ?? "").toString().trim();
              }
              if (prodName.isEmpty) {
                final pId = (stock['product_id'] ?? stock['productId'])?.toString();
                if (pId != null && productMap.containsKey(pId)) {
                  prodName = productMap[pId]!;
                }
              }
              if (prodName.isEmpty) prodName = "Unknown Product";

              final priceObj = stock['price'] is Map ? stock['price'] : {};
              final qty = int.tryParse((priceObj['Total Qty'] ?? priceObj['total_qty'] ?? stock['total_qty'] ?? stock['quantity'] ?? stock['qty'])?.toString() ?? '0') ?? 0;
              final priceVal = stock['selling_price_per_qty'] ?? priceObj['Selling Price Per Qty (₹)'] ?? priceObj['selling_price_per_qty'] ?? stock['selling_price'] ?? 0;
              final double sellingPrice = double.tryParse(priceVal.toString()) ?? 0.0;

              final distList = stock['Add New Stock Distribution'] ?? stock['distributions'] ?? [];
              String distLabel = "-";
              if (distList is List && distList.isNotEmpty) {
                final parts = distList.map((d) {
                  if (d is! Map) return "";
                  final dName = (d['Stock Type Name'] ?? d['stock_type_name'] ?? "Stock").toString();
                  final dVal = (d['Stock Value (Quantity)'] ?? d['stock_value'] ?? 0).toString();
                  return "$dName: $dVal";
                }).where((s) => s.isNotEmpty).toList();
                if (parts.isNotEmpty) distLabel = parts.join(", ");
              }

              String dateStr = _formatDate(stock['date'] ?? stock['created_at']);

              listData.add({
                "id": stockId,
                "date": dateStr,
                "supplier": supplierName,
                "product": prodName,
                "quantity": qty,
                "selling_price": sellingPrice,
                "variant": distLabel,
                "has_variant": false,
                "is_manufactured": false,
                "raw": stock,
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching stock list from $url: $e");
      }

      // Re-index S.No 1, 2, 3...
      int sNo = 1;
      for (var item in listData) {
        item['s_no'] = sNo++;
      }

      final sortedSuppliers = supplierSet.toList()..sort();
      if (mounted) {
        setState(() {
          stocks = listData;
          suppliers = sortedSuppliers.map((name) => {'name': name}).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error("fetchStocks error", e);
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "billing.srivagroups.in says",
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
        ),
        content: Text(
          "Are you sure you want to delete stock for ${item['product']}?",
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => isLoading = true);
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString("billing_auth_token") ?? prefs.getString("auth_token") ?? prefs.getString("token") ?? "";
                final businessId = prefs.getString('selected_business_id') ?? prefs.get("business_id")?.toString() ?? "52";
                final headers = {
                  "Accept": "application/json",
                  "X-App-ID": "Product94674",
                  if (token.isNotEmpty) "Authorization": "Bearer $token",
                  if (businessId.isNotEmpty) "x-business-id": businessId,
                };

                String delUrl;
                if (isManufactureMode) {
                  delUrl = "https://billing.srivagroups.in/api/manufacturing/stocks/${item['id']}";
                } else if (withVariantMode) {
                  delUrl = "https://billing.srivagroups.in/api/stocks/${item['id']}";
                } else {
                  delUrl = "https://billing.srivagroups.in/api/w_variant/stock/${item['id']}";
                }

                final delRes = await http.delete(Uri.parse(delUrl), headers: headers);
                debugPrint("Delete stock [${delRes.statusCode}]: ${delRes.body}");

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Stock deleted successfully"), backgroundColor: Colors.green),
                  );
                }
                await fetchStocks();
              } catch (e) {
                debugPrint("Error deleting stock: $e");
                await fetchStocks();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5E3A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text("OK", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E5E3A),
              side: const BorderSide(color: Color(0xFFA7F3D0)),
              backgroundColor: const Color(0xFFDCFCE7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter stocks based on query and supplier filter (dataset already matches current mode)
    List<Map<String, dynamic>> displayedStocks = stocks.where((item) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final p = item['product'].toString().toLowerCase();
        final s = item['supplier'].toString().toLowerCase();
        if (!p.contains(q) && !s.contains(q)) return false;
      }

      if (selectedSupplierFilter != null) {
        if (item['supplier'] != selectedSupplierFilter) return false;
      }

      return true;
    }).toList();

    final totalEntries = displayedStocks.length;
    final totalPages = (totalEntries / currentLimit).ceil().clamp(1, 9999);
    final validPage = currentPage.clamp(1, totalPages);
    final startIndex = totalEntries == 0 ? 0 : (validPage - 1) * currentLimit;
    final endIndex = (startIndex + currentLimit).clamp(0, totalEntries);
    final pageStocks = (startIndex < totalEntries)
        ? displayedStocks.sublist(startIndex, endIndex)
        : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Stock List",
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
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockEntryPage()),
                );
                if (res == true || mounted) {
                  fetchStocks();
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text("Stock Entry", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Title & Controls
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.precision_manufacturing_rounded, size: 20, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Stock List",
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    if (isManufactureMode) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.factory_outlined, size: 12, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              "Manufacturing Mode Active",
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // With Variant / Without Variant Toggle
                    if (!isManufactureMode)
                      Container(
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
                                if (!withVariantMode) {
                                  setState(() {
                                    withVariantMode = true;
                                    currentPage = 1;
                                  });
                                  fetchStocks();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: withVariantMode ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: withVariantMode
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: withVariantMode ? const Color(0xFF2563EB) : Colors.grey.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "With Variant",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: withVariantMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (withVariantMode) {
                                  setState(() {
                                    withVariantMode = false;
                                    currentPage = 1;
                                  });
                                  fetchStocks();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: !withVariantMode ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: !withVariantMode
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: !withVariantMode ? const Color(0xFF2563EB) : Colors.grey.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Without Variant",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: !withVariantMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Manufacture Button
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          isManufactureMode = !isManufactureMode;
                          currentPage = 1;
                          selectedSupplierFilter = null;
                          searchQuery = "";
                        });
                        fetchStocks();
                      },
                      icon: Icon(
                        Icons.factory_outlined,
                        size: 14,
                        color: isManufactureMode ? const Color(0xFF2563EB) : const Color(0xFF475569),
                      ),
                      label: Text(
                        isManufactureMode ? "Manufacture ✓" : "Manufacture",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isManufactureMode ? const Color(0xFF2563EB) : const Color(0xFF475569),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isManufactureMode ? const Color(0xFFEFF6FF) : Colors.white,
                        side: BorderSide(color: isManufactureMode ? const Color(0xFF93C5FD) : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Controls Bar: Search & Limit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;

                  final searchField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PRODUCT SEARCH", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: TextField(
                          onChanged: (val) => setState(() {
                            searchQuery = val;
                            currentPage = 1;
                          }),
                          decoration: InputDecoration(
                            hintText: "Type product name or model...",
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                          ),
                        ),
                      ),
                    ],
                  );

                  final supplierField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isManufactureMode ? "MANUFACTURER" : "SUPPLIER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          value: selectedSupplierFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          items: [
                            DropdownMenuItem(value: null, child: Text(isManufactureMode ? "All Manufacturers" : "All Suppliers", style: GoogleFonts.inter(fontSize: 12))),
                            ...suppliers.map((s) => DropdownMenuItem(value: s['name'].toString(), child: Text(s['name'].toString(), style: GoogleFonts.inter(fontSize: 12)))),
                          ],
                          onChanged: (val) => setState(() {
                            selectedSupplierFilter = val;
                            currentPage = 1;
                          }),
                        ),
                      ),
                    ],
                  );

                  final showField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SHOW", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<int>(
                          value: currentLimit,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          items: limitOptions.map((l) => DropdownMenuItem(value: l, child: Text("$l", style: GoogleFonts.inter(fontSize: 12)))).toList(),
                          onChanged: (val) => setState(() {
                            currentLimit = val ?? 10;
                            currentPage = 1;
                          }),
                        ),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        searchField,
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(flex: 7, child: supplierField),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: showField),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 5, child: searchField),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: supplierField),
                      const SizedBox(width: 16),
                      SizedBox(width: 90, child: showField),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Content Table or Empty View
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: isLoading
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))))
                  : displayedStocks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                            child: Column(
                              children: [
                                const Icon(Icons.inbox_outlined, size: 44, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                Text(
                                  isManufactureMode
                                      ? "No manufacturing product stock entries found."
                                      : "No stock entries found matching your search.",
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 58,
                                columnSpacing: 22,
                                horizontalMargin: 18,
                                columns: [
                                  DataColumn(label: Text("S.NO", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("DATE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text(isManufactureMode ? "MANUFACTURER" : "SUPPLIER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("PRODUCT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("QUANTITY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("PRICE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text(isManufactureMode ? "VARIANTS / BREAKDOWN" : (withVariantMode ? "VARIANT" : "STOCK DISTRIBUTION"), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                  DataColumn(label: Text("ACTIONS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                                ],
                                rows: pageStocks.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final item = entry.value;
                                  final sNo = startIndex + idx + 1;
                                  final double price = (item['selling_price'] is num) ? (item['selling_price'] as num).toDouble() : 0.0;

                                  return DataRow(
                                    cells: [
                                      DataCell(Text("$sNo", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), fontWeight: FontWeight.w600))),
                                      DataCell(Text(item['date'].toString(), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))),
                                      DataCell(Text(item['supplier'].toString(), style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500))),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 220),
                                          child: Text(item['product'].toString(), style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                          child: Text(item['quantity'].toString(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          price > 0 ? "₹${price.toStringAsFixed(2)}" : "—",
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                                          child: Text(item['variant'].toString(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Manage Allocation icon (Photo 4 & 5 matching web)
                                            Tooltip(
                                              message: "Manage Allocation",
                                              child: IconButton(
                                                icon: const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF6366F1)),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (_) => const StorageAllocationPage()),
                                                  );
                                                },
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                              ),
                                            ),
                                            // Edit icon (Photo 2 & 3 matching web)
                                            Tooltip(
                                              message: "Edit",
                                              child: IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF3B82F6)),
                                                onPressed: () async {
                                                  final res = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => StockEntryPage(editStockItem: item),
                                                    ),
                                                  );
                                                  if (res == true || mounted) {
                                                    fetchStocks();
                                                  }
                                                },
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                              ),
                                            ),
                                            // Delete icon
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                              onPressed: () => _confirmDelete(item),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  Text(
                                    totalEntries == 0
                                        ? "Showing 0 entries"
                                        : "Showing ${startIndex + 1} to $endIndex of $totalEntries entries",
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                  ),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Go to Page", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 36,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text("$validPage", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        // '<' button
                                        InkWell(
                                          onTap: validPage > 1 ? () => setState(() => currentPage = validPage - 1) : null,
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(6),
                                              color: validPage > 1 ? Colors.white : Colors.grey.shade100,
                                            ),
                                            child: Icon(Icons.chevron_left, size: 16, color: validPage > 1 ? const Color(0xFF334155) : Colors.grey.shade400),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        // Page numbers
                                        for (int pNum = 1; pNum <= (totalPages > 5 ? 5 : totalPages); pNum++)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: InkWell(
                                              onTap: () => setState(() => currentPage = pNum),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: (pNum == validPage) ? const Color(0xFF2563EB) : Colors.white,
                                                  border: Border.all(color: (pNum == validPage) ? const Color(0xFF2563EB) : Colors.grey.shade300),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  "$pNum",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: (pNum == validPage) ? FontWeight.bold : FontWeight.normal,
                                                    color: (pNum == validPage) ? Colors.white : const Color(0xFF334155),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 4),
                                        // '>' button
                                        InkWell(
                                          onTap: validPage < totalPages ? () => setState(() => currentPage = validPage + 1) : null,
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(6),
                                              color: validPage < totalPages ? Colors.white : Colors.grey.shade100,
                                            ),
                                            child: Icon(Icons.chevron_right, size: 16, color: validPage < totalPages ? const Color(0xFF334155) : Colors.grey.shade400),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
