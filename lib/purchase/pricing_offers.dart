import 'dart:convert';
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.dashLength = 5.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class PricingOffersPage extends StatefulWidget {
  const PricingOffersPage({super.key});

  @override
  State<PricingOffersPage> createState() => _PricingOffersPageState();
}

class _PricingOffersPageState extends State<PricingOffersPage> {
  // Screen index: 0 = Cards Grid (Main), 1 = Combo Offer Screen
  int _currentScreen = 0;

  List<dynamic> _products = [];
  Map<String, dynamic>? _selectedProduct;
  bool _isLoadingProducts = true;
  String? _productsErrorMessage;

  // Active Combo Banner state
  bool _showActiveBanner = false;
  String _activeBannerText = "";

  // States for the card endpoints
  bool _isLoadingCards = false;
  List<dynamic> _cardTypesData = [];
  List<dynamic> _couponCodesData = [];
  List<dynamic> _comboOffersData = [];
  List<dynamic> _discountsData = [];
  List<dynamic> _pricesData = [];

  // Track active combo id
  int? _activeComboId;
  int? _activeDiscountId;
  int? _activeCouponId;

  // Local states for Offer Card (No API, default sample included)
  List<Map<String, dynamic>> _localOffersData = [
    {
      "id": 1,
      "name": "fdhb",
      "description": "gfgf",
      "newPrice": 6573898.0,
      "status": "inactive"
    }
  ];
  int? _activeLocalOfferId;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _showToast(String message) {
    setState(() {
      _activeBannerText = message;
      _showActiveBanner = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showActiveBanner = false;
        });
      }
    });
  }

  Future<void> _fetchProducts() async {
    String url = "https://billing.srivagroups.in/api/products";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      List<String> queryParams = [];
      if (bId.isNotEmpty) {
        queryParams.add("business_id=$bId");
      }
      if (uId.isNotEmpty) {
        queryParams.add("user_main_id=$uId");
      }
      if (queryParams.isNotEmpty) {
        url += "?" + queryParams.join("&");
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("\$print debug: GET $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List list = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data']
            : (decoded is List ? decoded : []);

        // Sort alphabetically by product_name
        list.sort((a, b) {
          final nameA = (a['product_name']?.toString() ?? '').toLowerCase();
          final nameB = (b['product_name']?.toString() ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });

        if (!mounted) return;
        setState(() {
          _products = list;
          _isLoadingProducts = false;
        });
      } else {
        String serverMsg = "";
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('message')) {
            serverMsg = decoded['message'].toString();
          }
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _productsErrorMessage = serverMsg.isNotEmpty
              ? "Backend Error: $serverMsg"
              : "Failed to load products. Status: ${response.statusCode}";
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      print("\$print debug: GET $url error: $e");
      if (!mounted) return;
      setState(() {
        final errMsg = (e.toString().contains("SocketException") || e.toString().contains("Failed host lookup"))
            ? "Please connect network"
            : "Connection error: $e";
        _productsErrorMessage = errMsg;
        _isLoadingProducts = false;
      });
    }
  }

  // Load card lists from the 5 APIs and filter by selected product ID
  Future<void> _fetchCardsData(String productId) async {
    setState(() {
      _isLoadingCards = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      final headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      };

      String buildUrl(String base) {
        List<String> params = ["product_id=$productId"];
        if (bId.isNotEmpty) params.add("business_id=$bId");
        if (uId.isNotEmpty) params.add("user_main_id=$uId");
        return "$base?${params.join('&')}";
      }

      final cardTypeUrl = buildUrl("https://billing.srivagroups.in/api/add-card-type");
      final couponUrl = buildUrl("https://billing.srivagroups.in/api/add-coupon-code");
      final comboUrl = buildUrl("https://billing.srivagroups.in/api/add-combo-offer");
      final discountUrl = buildUrl("https://billing.srivagroups.in/api/add-discount");
      final priceUrl = buildUrl("https://billing.srivagroups.in/api/add-price");

      final results = await Future.wait([
        http.get(Uri.parse(cardTypeUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(couponUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(comboUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(discountUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
        http.get(Uri.parse(priceUrl), headers: headers).catchError((e) => http.Response('{"error": "$e"}', 500)),
      ]);

      // Print debug logs for each API call
      final urls = [cardTypeUrl, couponUrl, comboUrl, discountUrl, priceUrl];
      for (int i = 0; i < results.length; i++) {
        print("\$print debug: GET ${urls[i]} status: ${results[i].statusCode} response: ${results[i].body}");
      }

      setState(() {
        _cardTypesData = results[0].statusCode == 200 ? _filterByProduct(jsonDecode(results[0].body), productId) : [];
        _couponCodesData = results[1].statusCode == 200 ? _filterByProduct(jsonDecode(results[1].body), productId) : [];
        _comboOffersData = results[2].statusCode == 200 ? _filterByProduct(jsonDecode(results[2].body), productId) : [];
        _discountsData = results[3].statusCode == 200 ? _filterByProduct(jsonDecode(results[3].body), productId) : [];
        _pricesData = results[4].statusCode == 200 ? _filterByProduct(jsonDecode(results[4].body), productId) : [];
        
        // Find active combo from the combo offer list or SharedPreferences
        final savedComboId = prefs.getInt("active_combo_id_$productId");
        if (savedComboId != null && _comboOffersData.any((c) => c['id'] == savedComboId)) {
          _activeComboId = savedComboId;
        } else {
          final activeCombo = _comboOffersData.firstWhere(
            (c) => c['status']?.toString().toLowerCase() == 'active',
            orElse: () => null,
          );
          _activeComboId = activeCombo != null ? activeCombo['id'] : null;
        }

        // Find active discount from the discount list or SharedPreferences
        final savedDiscountId = prefs.getInt("active_discount_id_$productId");
        if (savedDiscountId != null && _discountsData.any((d) => d['id'] == savedDiscountId)) {
          _activeDiscountId = savedDiscountId;
        } else {
          final activeDiscount = _discountsData.firstWhere(
            (d) => d['status']?.toString().toLowerCase() == 'active',
            orElse: () => null,
          );
          _activeDiscountId = activeDiscount != null ? activeDiscount['id'] : null;
        }

        // Find active coupon from the coupon list or SharedPreferences
        final savedCouponId = prefs.getInt("active_coupon_id_$productId");
        if (savedCouponId != null && _couponCodesData.any((c) => c['id'] == savedCouponId)) {
          _activeCouponId = savedCouponId;
        } else {
          final activeCoupon = _couponCodesData.firstWhere(
            (c) => c['status']?.toString().toLowerCase() == 'active',
            orElse: () => null,
          );
          _activeCouponId = activeCoupon != null ? activeCoupon['id'] : null;
        }

        _isLoadingCards = false;
      });
    } catch (e) {
      print("\$print debug: GET card APIs error: $e");
      setState(() {
        _cardTypesData = [];
        _couponCodesData = [];
        _comboOffersData = [];
        _discountsData = [];
        _pricesData = [];
        _isLoadingCards = false;
      });
    }
  }

  List<dynamic> _filterByProduct(dynamic decodedBody, String productId) {
    List rawList = [];
    if (decodedBody is Map && decodedBody.containsKey('data')) {
      rawList = decodedBody['data'] is List ? decodedBody['data'] : [];
    } else if (decodedBody is List) {
      rawList = decodedBody;
    }

    return rawList.where((item) {
      if (item is Map) {
        final itemId = item['product_id'] ?? item['productId'];
        return itemId?.toString() == productId;
      }
      return false;
    }).toList();
  }

  // Custom Search & Filter Bottom Sheet for Product Selection
  void _showProductSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ProductSearchSheet(
          products: _products,
          selectedProduct: _selectedProduct,
          onSelected: (product) {
            setState(() {
              _selectedProduct = product;
              _currentScreen = 0; // Go back to main cards grid if a new product is selected
            });
            final pid = product['id'].toString();
            _fetchCardsData(pid);
          },
        );
      },
    );
  }

  // Dynamic lookup for card type item in _cardTypesData
  Map<String, dynamic>? _getCardTypeItem(String typeName) {
    for (var item in _cardTypesData) {
      final itemType = item['card_type']?.toString().toLowerCase() ?? '';
      if (itemType == typeName.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  // PUT: Update Card Type display title
  Future<void> _updateCardTypeTitle(int id, String newTitle) async {
    final url = "https://billing.srivagroups.in/api/add-card-type/$id";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final body = {"card_display_title": newTitle};

      print("\$print debug: PUT $url payload: ${jsonEncode(body)}");
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print("\$print debug: PUT $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 200) {
        _showToast("Card Display Title updated successfully!");
        if (_selectedProduct != null) {
          _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to update card title. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("\$print debug: PUT $url error: $e");
      _showToast("Error updating card title: $e");
    }
  }

  // DELETE: Delete Card Type
  Future<void> _deleteCardType(int id) async {
    final url = "https://billing.srivagroups.in/api/add-card-type/$id";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      print("\$print debug: DELETE $url");
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("\$print debug: DELETE $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 200) {
        _showToast("Card deleted successfully!");
        if (_selectedProduct != null) {
          _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to delete card. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("\$print debug: DELETE $url error: $e");
      _showToast("Error deleting card: $e");
    }
  }

  // Edit Card Type bottom sheet dialog (Screenshot 1 matching UI)
  void _showEditCardSheet(String typeKey, String currentDisplayTitle) {
    final item = _getCardTypeItem(typeKey);
    if (item == null) {
      _showToast("This card type is not initialized on the server yet.");
      return;
    }

    final id = item['id'];
    final displayTitleController = TextEditingController(text: currentDisplayTitle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_offer, color: Color(0xFF6366F1), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Edit Card",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Card Type Locked Container
              const Text(
                "Card Type *",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          typeKey.toLowerCase() == 'price' ? Icons.attach_money : Icons.local_offer_outlined,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          typeKey,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      "locked",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card Display Title Editable field
              const Text(
                "Card Display Title *",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: displayTitleController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade200),
                        backgroundColor: const Color(0xFFF8FAFC),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateCardTypeTitle(id, displayTitleController.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Action methods for Combo Cards
  Future<void> _updateComboOfferPayload(
    int id, {
    String? comboName,
    double? comboPrice,
    String? status,
    List<dynamic>? includedProducts,
    String? description,
  }) async {
    try {
      final combo = _comboOffersData.firstWhere((c) => c['id'] == id, orElse: () => null);
      if (combo == null) {
        _showToast("Combo not found locally.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      final List<dynamic> included = includedProducts ?? (combo['included_products'] is List ? combo['included_products'] : []);
      final formattedProducts = included.map((item) {
        final prodId = (item['productId'] ?? item['product_id'] ?? '').toString();
        final prodName = (item['productName'] ?? item['product_name'] ?? '').toString();
        return {
          "productId": prodId,
          "productName": prodName
        };
      }).toList();

      final finalName = comboName ?? combo['combo_name']?.toString() ?? "";
      final finalPriceVal = comboPrice ?? double.tryParse(combo['combo_price']?.toString() ?? '0') ?? 0.0;
      final finalStatus = status ?? combo['status']?.toString() ?? "inactive";
      final finalDesc = description ?? combo['description']?.toString() ?? "";

      final comboCard = _getCardTypeItem("Combo");
      final cardId = comboCard?['id'] ?? combo['card_id'] ?? 6;
      final cardName = comboCard?['card_display_title'] ?? combo['card_name'] ?? "Combo";
      final prodId = (combo['product_id'] ?? _selectedProduct!['id']).toString();
      final prodName = (combo['product_name'] ?? _selectedProduct!['product_name'] ?? 'Product').toString();

      // 1. Delete the old combo offer (since the server PUT ignores combo_price and included_products)
      final deleteUrl = "https://billing.srivagroups.in/api/add-combo-offer/$id";
      print("\$print debug: DELETE (for update workaround) $deleteUrl");
      try {
        final deleteResponse = await http.delete(
          Uri.parse(deleteUrl),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );
        print("\$print debug: DELETE status: ${deleteResponse.statusCode} response: ${deleteResponse.body}");
      } catch (deleteError) {
        print("\$print debug: DELETE error (proceeding to recreate): $deleteError");
      }

      // 2. POST the new combo offer with updated parameters
      final createUrl = "https://billing.srivagroups.in/api/add-combo-offer";
      final body = {
        "product_id": prodId,
        "productId": prodId,
        "product_name": prodName,
        "productName": prodName,
        "card_id": cardId,
        "cardId": cardId,
        "card_name": cardName,
        "cardName": cardName,
        "combo_name": finalName,
        "comboName": finalName,
        "combo_price": finalPriceVal.round(), // send as strict integer
        "comboPrice": finalPriceVal.round(),
        "included_products": formattedProducts,
        "includedProducts": formattedProducts,
        "business_id": bId,
        "businessId": bId,
        "user_main_id": uId,
        "userMainId": uId,
        "status": finalStatus,
        "description": finalDesc
      };

      print("\$print debug: POST (for update workaround) $createUrl payload: ${jsonEncode(body)}");
      final response = await http.post(
        Uri.parse(createUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print("\$print debug: POST status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        if (respData['success'] == true && respData['data'] != null) {
          final newCombo = respData['data'];
          final newId = newCombo['id'];
          
          setState(() {
            _comboOffersData.removeWhere((c) => c['id'] == id);
            _comboOffersData.add(newCombo);
            
            if (_activeComboId == id) {
              _activeComboId = newId;
            }
          });

          // Save to SharedPreferences if it is active
          if (_activeComboId == newId) {
            final prodId = (newCombo['product_id'] ?? _selectedProduct!['id']).toString();
            await prefs.setInt("active_combo_id_$prodId", newId);
          }
        }
        _showToast("Combo offer updated successfully!");
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (_selectedProduct != null) {
          await _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to update combo offer. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("\$print debug: Update workaround error: $e");
      _showToast("Error updating combo: $e");
    }
  }

  Future<void> _updateComboPrice(int id, double newPrice) async {
    await _updateComboOfferPayload(id, comboPrice: newPrice);
  }

  Future<void> _deleteComboOffer(int id) async {
    final url = "https://billing.srivagroups.in/api/add-combo-offer/$id";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      print("\$print debug: DELETE $url");
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("\$print debug: DELETE $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _comboOffersData.removeWhere((c) => c['id'] == id);
          if (_activeComboId == id) {
            _activeComboId = null;
          }
        });

        final prodId = _selectedProduct!['id'].toString();
        await prefs.remove("active_combo_id_$prodId");

        _showToast("Combo offer deleted successfully!");
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (_selectedProduct != null) {
          await _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to delete combo offer.");
      }
    } catch (e) {
      print("\$print debug: DELETE $url error: $e");
    }
  }

  Future<void> _setComboActiveStatus(int id, bool active) async {
    final status = active ? "active" : "inactive";
    final prefs = await SharedPreferences.getInstance();
    final prodId = _selectedProduct!['id'].toString();

    setState(() {
      if (active) {
        _activeComboId = id;
        prefs.setInt("active_combo_id_$prodId", id);
        _showToast("Active plan selected!");
      } else {
        if (_activeComboId == id) {
          _activeComboId = null;
          prefs.remove("active_combo_id_$prodId");
        }
        _showToast("Combo plan deactivated.");
      }
    });
    await _updateComboOfferPayload(id, status: status);
  }

  Future<void> _createComboOffer(String name, double price, List<Map<String, String>> selectedProds) async {
    final url = "https://billing.srivagroups.in/api/add-combo-offer";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      final comboCard = _getCardTypeItem("Combo");
      final cardId = comboCard?['id'] ?? 6;
      final cardName = comboCard?['card_display_title'] ?? "Combo";
      final prodId = _selectedProduct!['id'].toString();
      final prodName = _selectedProduct!['product_name']?.toString() ?? 'Product';

      final body = {
        "product_id": prodId,
        "productId": prodId,
        "product_name": prodName,
        "productName": prodName,
        "card_id": cardId,
        "cardId": cardId,
        "card_name": cardName,
        "cardName": cardName,
        "combo_name": name,
        "comboName": name,
        "combo_price": price.round(),
        "comboPrice": price.round(),
        "included_products": selectedProds,
        "includedProducts": selectedProds,
        "business_id": bId,
        "businessId": bId,
        "user_main_id": uId,
        "userMainId": uId,
        "status": "inactive"
      };

      print("\$print debug: POST $url payload: ${jsonEncode(body)}");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print("\$print debug: POST $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        if (respData['success'] == true && respData['data'] != null) {
          final newCombo = respData['data'];
          setState(() {
            _comboOffersData.add(newCombo);
          });
        }
        _showToast("Combo offer created successfully!");
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (_selectedProduct != null) {
          await _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to create combo offer.");
      }
    } catch (e) {
      print("\$print debug: POST $url error: $e");
    }
  }

  // Price Comparison Modal Bottom Sheet (Screenshot 3 UI)
  void _showPriceComparisonSheet(Map<String, dynamic> combo) {
    final comboName = combo['combo_name']?.toString() ?? 'AA';
    final comboId = combo['id'];
    final priceController = TextEditingController(text: combo['combo_price']?.toString() ?? '0');

    // Parse included products
    final List<dynamic> included = combo['included_products'] is List
        ? combo['included_products']
        : [];

    double totalMRP = 0.0;
    List<Map<String, dynamic>> resolvedProducts = [];

    for (var item in included) {
      final prodId = item['productId']?.toString();
      final prodName = item['productName']?.toString() ?? '';

      // Find in main products list to get real MRP
      final matched = _products.firstWhere(
        (p) => p['id']?.toString() == prodId,
        orElse: () => null,
      );

      double mrpVal = 0.0;
      if (matched != null) {
        mrpVal = double.tryParse(matched['mrp']?.toString() ?? '0') ?? 0.0;
      }

      totalMRP += mrpVal;
      resolvedProducts.add({
        "name": prodName,
        "mrp": mrpVal,
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.credit_card, color: Color(0xFF4F46E5), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Price Comparison",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            comboName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title label
              const Text(
                "INCLUDED PRODUCTS & MRPS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Product MRP lines
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: resolvedProducts.length,
                itemBuilder: (context, idx) {
                  final rp = resolvedProducts[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            rp['name'],
                            style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          "₹${rp['mrp'].toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 24),

              // Combined MRP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Combined MRP",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    "₹${totalMRP.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Textfield for price
              const Text(
                "Set New Combo Price (₹)",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // Cancel / Save
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade200),
                        backgroundColor: const Color(0xFFF8FAFC),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final val = double.tryParse(priceController.text) ?? 0.0;
                        _updateComboPrice(comboId, val);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 16),
                          SizedBox(width: 6),
                          Text("Done — Apply Combo", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Create/Add Combo Offer sheet
  void _showAddComboSheet() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    List<Map<String, dynamic>> productCheckList = _products.map((p) => {
      "id": p['id'].toString(),
      "name": p['product_name']?.toString() ?? 'No Name',
      "checked": false
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add Combo Offer",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("Combo Name *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        hintText: "Enter combo name (e.g. A5)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Combo Price (₹) *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter price",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Select Included Products *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        itemCount: productCheckList.length,
                        itemBuilder: (context, idx) {
                          final prod = productCheckList[idx];
                          return CheckboxListTile(
                            title: Text(prod['name'], style: const TextStyle(fontSize: 13)),
                            value: prod['checked'],
                            dense: true,
                            enabled: !isSaving,
                            onChanged: (val) {
                              setSheetState(() {
                                prod['checked'] = val ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              final name = nameController.text.trim();
                              final price = double.tryParse(priceController.text) ?? 0.0;
                              final selectedProds = productCheckList
                                  .where((p) => p['checked'] == true)
                                  .map((p) => {"productId": p['id'].toString(), "productName": p['name'].toString()})
                                  .toList();

                              if (name.isEmpty || price <= 0 || selectedProds.isEmpty) {
                                _showToast("Please fill all required fields");
                                return;
                              }

                              setSheetState(() {
                                isSaving = true;
                              });

                              try {
                                await _createComboOffer(name, price, selectedProds);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                setSheetState(() {
                                  isSaving = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Create Offer"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Edit Combo name dialog (Premium Mobile UI matching screenshot)
  void _showEditComboNameSheet(Map<String, dynamic> combo) {
    final nameController = TextEditingController(text: combo['combo_name']?.toString() ?? '');
    final priceController = TextEditingController(text: combo['combo_price']?.toString() ?? '0');
    final descController = TextEditingController(text: combo['description']?.toString() ?? '');
    final comboId = combo['id'];

    // Local copy of included products that we can mutate
    final List<dynamic> rawIncluded = combo['included_products'] is List ? combo['included_products'] : [];
    final List<Map<String, String>> selectedIncluded = rawIncluded.map((item) {
      return {
        "productId": (item['productId'] ?? item['product_id'] ?? '').toString(),
        "productName": (item['productName'] ?? item['product_name'] ?? '').toString()
      };
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row (Edit Entry)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.settings, color: Color(0xFF6366F1), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Edit Entry",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: isSaving ? null : () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Combo Name
                    const Text(
                      "Combo Name *",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        hintText: "Enter combo name",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    // Included Products
                    const Text(
                      "Included Products *",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...selectedIncluded.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['productName'] ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFF1E40AF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: isSaving ? null : () {
                                      setSheetState(() {
                                        selectedIncluded.remove(item);
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          
                          // Plus Button
                          GestureDetector(
                            onTap: isSaving ? null : () {
                              _showAddProductToComboSheet(context, (selectedProduct) {
                                setSheetState(() {
                                  final exists = selectedIncluded.any(
                                    (p) => p['productId'].toString() == selectedProduct['id'].toString()
                                  );
                                  if (!exists) {
                                    selectedIncluded.add({
                                      "productId": selectedProduct['id'].toString(),
                                      "productName": (selectedProduct['product_name'] ?? 'No Name').toString()
                                    });
                                  }
                                });
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, size: 16, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Combo Price
                    const Text(
                      "Combo Price (₹) *",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter price",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      "Description (optional)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      enabled: !isSaving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter short details...",
                        contentPadding: const EdgeInsets.all(16),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 28),

                    // Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade200),
                              backgroundColor: const Color(0xFFF1F5F9),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              final newName = nameController.text.trim();
                              final newPrice = double.tryParse(priceController.text) ?? 0.0;
                              if (newName.isEmpty || newPrice <= 0 || selectedIncluded.isEmpty) {
                                _showToast("Please fill all required fields");
                                return;
                              }

                              setSheetState(() {
                                isSaving = true;
                              });

                              try {
                                await _updateComboOfferPayload(
                                  comboId,
                                  comboName: newName,
                                  comboPrice: newPrice,
                                  includedProducts: selectedIncluded,
                                  description: descController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                setSheetState(() {
                                  isSaving = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    "Save Entry",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddProductToComboSheet(BuildContext context, ValueChanged<Map<String, dynamic>> onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ProductSearchSheet(
          products: _products,
          selectedProduct: null,
          onSelected: (product) {
            onSelected(product);
          },
        );
      },
    );
  }

  // SCREEN 1: Combo offer page view
  Widget _buildComboScreen() {
    final productName = _selectedProduct!['product_name']?.toString() ?? 'Product';

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Back and Add buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentScreen = 0;
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF4F46E5)),
                label: const Text(
                  "Back to Cards",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFF4F46E5), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddComboSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Add Combo Offer", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Combo title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Combo for $productName",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Manage details and offers for this card type",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Combos list
          _comboOffersData.isEmpty
              ? Container(
                  width: double.infinity,
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    "No combo offers found for this product.",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _comboOffersData.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final combo = _comboOffersData[index];
                    final id = combo['id'];
                    final comboName = combo['combo_name']?.toString() ?? 'AA';
                    final price = combo['combo_price']?.toString() ?? '0';
                    final isActive = _activeComboId == id || combo['status']?.toString().toLowerCase() == 'active';

                    // Join product names
                    final List<dynamic> included = combo['included_products'] is List
                        ? combo['included_products']
                        : [];
                    final includedStr = included.map((item) => item['productName'] ?? '').join(' + ');

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? const Color(0xFF10B981) : Colors.grey.shade200,
                          width: isActive ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top title & actions row
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 16, right: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comboName,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "ACTIVE COMBO",
                                          style: TextStyle(color: Color(0xFF065F46), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      onPressed: () => _showPriceComparisonSheet(combo),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      onPressed: () => _showEditComboNameSheet(combo),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      onPressed: () => _deleteComboOffer(id),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Contents
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Includes: $includedStr",
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Combo Price: ₹$price",
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Divider
                          CustomPaint(
                            size: const Size(double.infinity, 1),
                            painter: DashedBorderPainter(color: Colors.grey.shade200, gap: 3, dashLength: 4),
                          ),

                          // Bottom set active button
                          InkWell(
                            onTap: () {
                              _setComboActiveStatus(id, !isActive);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Text(
                                isActive ? "✓ Active Combo" : "Set as Active Combo",
                                style: TextStyle(
                                  color: isActive ? Colors.white : const Color(0xFF475569),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // SCREEN 0: Default Grid view
  Widget _buildMainGridScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gorgeous Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5E5DF0), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Color(0xFFFBBF24),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pricing & Offers Management",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Create and manage nested pricing & offer cards",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Select Product Dropdown Card (Now opens a searchable sheet)
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      "assets/box_emoji.png",
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.inventory_2,
                        color: Color(0xFFB45309),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Select Product",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _isLoadingProducts
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                        ),
                      )
                    : _productsErrorMessage != null
                        ? Text(
                            _productsErrorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          )
                        : InkWell(
                            onTap: _showProductSearchSheet,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                color: const Color(0xFFF8FAFC),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedProduct != null
                                        ? _selectedProduct!['product_name']?.toString() ?? 'No Name'
                                        : "— Choose a product —",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedProduct != null ? Colors.black87 : Colors.grey,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Dashed border or selected product options
        _selectedProduct == null
            ? SizedBox(
                width: double.infinity,
                height: 220,
                child: CustomPaint(
                  painter: DashedBorderPainter(
                    color: const Color(0xFFC7D2FE),
                    strokeWidth: 1.2,
                    gap: 5,
                    dashLength: 5,
                    borderRadius: 16,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/box_emoji.png",
                          width: 52,
                          height: 52,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.inventory_2_outlined,
                            size: 52,
                            color: const Color(0xFF4F46E5).withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Please select a product.",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : _buildProductDetailsSection(),
      ],
    );
  }

  Widget _buildProductDetailsSection() {
    return _isLoadingCards
        ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48.0),
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
          )
        : _buildCardsGridSection();
  }

  Widget _buildCardsGridSection() {
    final totalCount = _cardTypesData.length +
        _couponCodesData.length +
        _comboOffersData.length +
        _discountsData.length +
        _pricesData.length;

    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          "Cards for ${_selectedProduct!['product_name']?.toString() ?? 'Product'}",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: [
            // Offer card type lookup
            _buildGridCard(
              icon: Icons.credit_card,
              title: _getCardTypeItem("Offer")?['card_display_title'] ?? "Offer",
              subtitle: "${_localOffersData.length} offer${_localOffersData.length == 1 ? '' : 's'}",
              showActions: _getCardTypeItem("Offer") != null,
              onEdit: () => _showEditCardSheet("Offer", _getCardTypeItem("Offer")?['card_display_title'] ?? "Offer"),
              onDelete: () {
                final id = _getCardTypeItem("Offer")?['id'];
                if (id != null) _deleteCardType(id);
              },
              onTap: () {
                setState(() {
                  _currentScreen = 4; // Open Offer details screen
                });
              },
            ),
            // Combo Card type lookup
            _buildGridCard(
              icon: Icons.inventory_2_outlined,
              title: _getCardTypeItem("Combo")?['card_display_title'] ?? "Combo",
              subtitle: "${_comboOffersData.length} combo${_comboOffersData.length == 1 ? '' : 's'}",
              showActions: _getCardTypeItem("Combo") != null,
              onEdit: () => _showEditCardSheet("Combo", _getCardTypeItem("Combo")?['card_display_title'] ?? "Combo"),
              onDelete: () {
                final id = _getCardTypeItem("Combo")?['id'];
                if (id != null) _deleteCardType(id);
              },
              onTap: () {
                setState(() {
                  _currentScreen = 1; // Open Combo details screen
                });
              },
            ),
            // Price card type lookup
            _buildGridCard(
              icon: Icons.attach_money,
              title: _getCardTypeItem("price")?['card_display_title'] ?? "price",
              subtitle: "${_pricesData.length} price${_pricesData.length == 1 ? '' : 's'}",
              showActions: _getCardTypeItem("price") != null,
              onEdit: () => _showEditCardSheet("price", _getCardTypeItem("price")?['card_display_title'] ?? "price"),
              onDelete: () {
                final id = _getCardTypeItem("price")?['id'];
                if (id != null) _deleteCardType(id);
              },
            ),
            // Discount card type lookup
            _buildGridCard(
              icon: Icons.percent,
              title: _getCardTypeItem("discount")?['card_display_title'] ?? "discount",
              subtitle: "${_discountsData.length} discount${_discountsData.length == 1 ? '' : 's'}",
              showActions: _getCardTypeItem("discount") != null,
              onEdit: () => _showEditCardSheet("discount", _getCardTypeItem("discount")?['card_display_title'] ?? "discount"),
              onDelete: () {
                final id = _getCardTypeItem("discount")?['id'];
                if (id != null) _deleteCardType(id);
              },
              onTap: () {
                setState(() {
                  _currentScreen = 2; // Open Discount details screen
                });
              },
            ),
            // Coupon Code Card type lookup
            _buildGridCard(
              icon: Icons.confirmation_number_outlined,
              title: _getCardTypeItem("Coupon Code Card")?['card_display_title'] ?? "Coupon Code Card",
              subtitle: "${_couponCodesData.length} coupon${_couponCodesData.length == 1 ? '' : 's'}",
              showActions: _getCardTypeItem("Coupon Code Card") != null,
              onEdit: () => _showEditCardSheet("Coupon Code Card", _getCardTypeItem("Coupon Code Card")?['card_display_title'] ?? "Coupon Code Card"),
              onDelete: () {
                final id = _getCardTypeItem("Coupon Code Card")?['id'];
                if (id != null) _deleteCardType(id);
              },
              onTap: () {
                setState(() {
                  _currentScreen = 3; // Open Coupon details screen
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGridCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showActions = false,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                // Left indicator stripe
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (showActions) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Icon(Icons.edit_outlined, color: Colors.grey, size: 16),
                    ),
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Icon(Icons.delete_outline, color: Colors.grey, size: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text("Pricing & Offers"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF4F46E5),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: _currentScreen == 0
                ? _buildMainGridScreen()
                : (_currentScreen == 1
                    ? _buildComboScreen()
                    : (_currentScreen == 2
                        ? _buildDiscountScreen()
                        : (_currentScreen == 3
                            ? _buildCouponScreen()
                            : _buildOfferScreen()))),
          ),

          // Active toast plan alert (matching screenshots 4 & 5 banner layout)
          if (_showActiveBanner)
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFECFDF5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _activeBannerText,
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- DISCOUNT OFFERS METHODS ---

  Widget _buildDiscountScreen() {
    final productName = _selectedProduct!['product_name']?.toString() ?? 'Product';

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Back and Add buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentScreen = 0;
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF4F46E5)),
                label: const Text(
                  "Back to Cards",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFF4F46E5), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddDiscountSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Add Discount", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.percent, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "discount for $productName",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Manage details and offers for this card type",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Discounts list
          _discountsData.isEmpty
              ? Container(
                  width: double.infinity,
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    "No discounts found for this product.",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _discountsData.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final discount = _discountsData[index];
                    final id = discount['id'];
                    final name = discount['discount_name']?.toString() ?? 'AA';
                    final pct = discount['discount_pct']?.toString() ?? '0';
                    final type = discount['discount_type']?.toString() ?? 'Festival';
                    final isActive = _activeDiscountId == id || discount['status']?.toString().toLowerCase() == 'active';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? const Color(0xFF10B981) : Colors.grey.shade200,
                          width: isActive ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top title & actions row
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 16, right: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "ACTIVE DISCOUNT",
                                          style: TextStyle(color: Color(0xFF065F46), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      onPressed: () => _showDiscountCalculatorSheet(discount),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      onPressed: () => _showEditDiscountSheet(discount),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      onPressed: () => _deleteDiscount(id),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Contents
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Type: ${type.toUpperCase()}",
                                    style: const TextStyle(
                                      color: Color(0xFF4F46E5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Discount: $pct%",
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                if (discount['description']?.toString().isNotEmpty ?? false) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    discount['description'].toString(),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Divider
                          CustomPaint(
                            size: const Size(double.infinity, 1),
                            painter: DashedBorderPainter(color: Colors.grey.shade200, gap: 3, dashLength: 4),
                          ),

                          // Bottom set active button
                          InkWell(
                            onTap: () {
                              _setDiscountActiveStatus(id, !isActive);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Text(
                                isActive ? "✓ Active Discount" : "Set as Active Discount",
                                style: TextStyle(
                                  color: isActive ? Colors.white : const Color(0xFF475569),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showAddDiscountSheet() {
    final nameController = TextEditingController();
    final pctController = TextEditingController();
    final typeController = TextEditingController(text: "Festival");
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add Discount Offer",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("Discount Name *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        hintText: "Enter discount name (e.g. Festival Season)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Discount % *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: pctController,
                                enabled: !isSaving,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "e.g. 20",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Discount Type *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: typeController,
                                enabled: !isSaving,
                                decoration: InputDecoration(
                                  hintText: "Festival, Seasonal etc.",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("Description (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      enabled: !isSaving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter short description details...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              if (nameController.text.trim().isEmpty || pctController.text.trim().isEmpty) {
                                _showToast("Required fields are empty!");
                                return;
                              }
                              setSheetState(() {
                                isSaving = true;
                              });
                              try {
                                await _createDiscount(
                                  nameController.text.trim(),
                                  double.tryParse(pctController.text.trim()) ?? 0.0,
                                  typeController.text.trim(),
                                  descController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                setSheetState(() {
                                  isSaving = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Save Entry", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createDiscount(String name, double pct, String type, String desc) async {
    final url = "https://billing.srivagroups.in/api/add-discount";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      final discountCard = _getCardTypeItem("discount");
      final cardId = discountCard?['id'] ?? 4;
      final cardName = discountCard?['card_display_title'] ?? "discount";
      final prodId = _selectedProduct!['id'].toString();
      final prodName = _selectedProduct!['product_name']?.toString() ?? 'Product';

      final body = {
        "product_id": prodId,
        "productId": prodId,
        "product_name": prodName,
        "productName": prodName,
        "card_id": cardId,
        "cardId": cardId,
        "card_name": cardName,
        "cardName": cardName,
        "discount_name": name,
        "discountName": name,
        "discount_pct": pct.round(),
        "discountPct": pct.round(),
        "discount_type": type,
        "discountType": type,
        "description": desc,
        "business_id": bId,
        "businessId": bId,
        "user_main_id": uId,
        "userMainId": uId,
        "status": "inactive"
      };

      print("\$print debug: POST $url payload: ${jsonEncode(body)}");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print("\$print debug: POST $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        if (respData['success'] == true && respData['data'] != null) {
          final newDiscount = respData['data'];
          setState(() {
            _discountsData.add(newDiscount);
          });
        }
        _showToast("Discount created successfully!");
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (_selectedProduct != null) {
          await _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to create discount.");
      }
    } catch (e) {
      print("\$print debug: POST $url error: $e");
    }
  }

  // View Discount Calculator Modal Sheet (Screenshot 2 & 3 UI)
  void _showDiscountCalculatorSheet(Map<String, dynamic> discount) {
    final discountName = discount['discount_name']?.toString() ?? 'AA';
    final discountId = discount['id'];

    // Determine initial base price from active price or MRP
    double initialBase = 0.0;
    if (_pricesData.isNotEmpty) {
      final activePrice = _pricesData.firstWhere(
        (p) => p['status']?.toString().toLowerCase() == 'active',
        orElse: () => null,
      );
      if (activePrice != null) {
        initialBase = double.tryParse(activePrice['amount']?.toString() ?? '') ?? 0.0;
      }
    }
    if (initialBase == 0.0) {
      initialBase = double.tryParse(_selectedProduct!['mrp']?.toString() ?? '499.00') ?? 499.00;
    }

    final basePriceController = TextEditingController(text: initialBase.toStringAsFixed(2));
    final valueController = TextEditingController(text: discount['discount_pct']?.toString() ?? '20');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isPercentage = true;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double basePrice = double.tryParse(basePriceController.text) ?? 0.0;
            final double discountVal = double.tryParse(valueController.text) ?? 0.0;

            double appliedDiscount = 0.0;
            if (isPercentage) {
              appliedDiscount = basePrice * (discountVal / 100.0);
            } else {
              appliedDiscount = discountVal;
            }

            // Ensure applied discount does not exceed base price
            if (appliedDiscount > basePrice) {
              appliedDiscount = basePrice;
            }

            final double calculatedBalance = basePrice - appliedDiscount;

            // Setup listeners to update layout instantly
            basePriceController.addListener(() {
              if (context.mounted) {
                setSheetState(() {});
              }
            });
            valueController.addListener(() {
              if (context.mounted) {
                setSheetState(() {});
              }
            });

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payment, color: Color(0xFF4F46E5), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Discount Calculator",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  discountName,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Product Base Price
                    const Text(
                      "Product Base Price (₹)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: basePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: "Enter price",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Defaults to active price or product MRP (₹${initialBase.toStringAsFixed(2)})",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 20),

                    // Discount Type selector
                    const Text(
                      "Discount Type",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setSheetState(() {
                                isPercentage = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPercentage ? const Color(0xFF3B82F6) : Colors.white,
                              foregroundColor: isPercentage ? Colors.white : const Color(0xFF475569),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: isPercentage ? Colors.transparent : Colors.grey.shade200),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("% Percentage", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setSheetState(() {
                                isPercentage = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isPercentage ? const Color(0xFF3B82F6) : Colors.white,
                              foregroundColor: !isPercentage ? Colors.white : const Color(0xFF475569),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: !isPercentage ? Colors.transparent : Colors.grey.shade200),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("₹ Flat Cash Off", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Input Value
                    Text(
                      isPercentage ? "Discount Percentage (%)" : "Discount Amount (₹)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: isPercentage ? "Enter percentage (e.g. 20)" : "Enter flat cash off amount",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Simulated Invoice Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SIMULATED INVOICE",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Base Price", style: TextStyle(color: Color(0xFF475569), fontSize: 14)),
                              Text("₹${basePrice.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isPercentage ? "Discount Applied (${discountVal.toStringAsFixed(0)}%)" : "Discount Applied (Flat)",
                                style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              Text("- ₹${appliedDiscount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Calculated Balance", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15)),
                              Text(
                                "₹${calculatedBalance.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 17),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Cancel / Apply buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // We can save the simulated discount value back to the server.
                              _updateDiscountPayload(discountId, discountPct: discountVal);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 16),
                                SizedBox(width: 6),
                                Text("Done — Apply New Price", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Edit Discount Modal Bottom Sheet (Screenshot 4 UI)
  void _showEditDiscountSheet(Map<String, dynamic> discount) {
    final discountId = discount['id'];
    final nameController = TextEditingController(text: discount['discount_name']?.toString() ?? '');
    final pctController = TextEditingController(text: discount['discount_pct']?.toString() ?? '');
    final typeController = TextEditingController(text: discount['discount_type']?.toString() ?? 'Festival');
    final descController = TextEditingController(text: discount['description']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.settings_outlined, color: Color(0xFF4F46E5), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Edit Entry",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name
                    const Text("Discount Name *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pct & Type
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Discount % *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: pctController,
                                enabled: !isSaving,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Discount Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: typeController,
                                enabled: !isSaving,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Text("Description (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      enabled: !isSaving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter short details",
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              if (nameController.text.trim().isEmpty || pctController.text.trim().isEmpty) {
                                _showToast("Required fields are empty!");
                                return;
                              }
                              setSheetState(() {
                                isSaving = true;
                              });
                              try {
                                await _updateDiscountPayload(
                                  discountId,
                                  discountName: nameController.text.trim(),
                                  discountPct: double.tryParse(pctController.text.trim()) ?? 0.0,
                                  discountType: typeController.text.trim(),
                                  description: descController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                setSheetState(() {
                                  isSaving = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Save Entry", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Workaround: Since backend PUT ignores some properties, we delete and recreate.
  Future<void> _updateDiscountPayload(
    int id, {
    String? discountName,
    double? discountPct,
    String? discountType,
    String? description,
    String? status,
  }) async {
    try {
      final discount = _discountsData.firstWhere((d) => d['id'] == id, orElse: () => null);
      if (discount == null) {
        _showToast("Discount not found locally.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      final finalName = discountName ?? discount['discount_name']?.toString() ?? "";
      final finalPct = discountPct ?? double.tryParse(discount['discount_pct']?.toString() ?? '0') ?? 0.0;
      final finalType = discountType ?? discount['discount_type']?.toString() ?? "Festival";
      final finalDesc = description ?? discount['description']?.toString() ?? "";
      final finalStatus = status ?? discount['status']?.toString() ?? "inactive";

      final discountCard = _getCardTypeItem("discount");
      final cardId = discountCard?['id'] ?? discount['card_id'] ?? 4;
      final cardName = discountCard?['card_display_title'] ?? discount['card_name'] ?? "discount";
      final prodId = (discount['product_id'] ?? _selectedProduct!['id']).toString();
      final prodName = (discount['product_name'] ?? _selectedProduct!['product_name'] ?? 'Product').toString();

      // 1. Delete the old discount
      final deleteUrl = "https://billing.srivagroups.in/api/add-discount/$id";
      print("\$print debug: DELETE (for update workaround) $deleteUrl");
      try {
        final deleteResponse = await http.delete(
          Uri.parse(deleteUrl),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );
        print("\$print debug: DELETE status: ${deleteResponse.statusCode} response: ${deleteResponse.body}");
      } catch (deleteError) {
        print("\$print debug: DELETE error (proceeding to recreate): $deleteError");
      }

      // 2. Create the new discount
      final createUrl = "https://billing.srivagroups.in/api/add-discount";
      final body = {
        "product_id": prodId,
        "productId": prodId,
        "product_name": prodName,
        "productName": prodName,
        "card_id": cardId,
        "cardId": cardId,
        "card_name": cardName,
        "cardName": cardName,
        "discount_name": finalName,
        "discountName": finalName,
        "discount_pct": finalPct.round(),
        "discountPct": finalPct.round(),
        "discount_type": finalType,
        "discountType": finalType,
        "description": finalDesc,
        "business_id": bId,
        "businessId": bId,
        "user_main_id": uId,
        "userMainId": uId,
        "status": finalStatus
      };

      print("\$print debug: POST (for update workaround) $createUrl payload: ${jsonEncode(body)}");
      final response = await http.post(
        Uri.parse(createUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print("\$print debug: POST status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        if (respData['success'] == true && respData['data'] != null) {
          final newDiscount = respData['data'];
          final newId = newDiscount['id'];
          
          setState(() {
            _discountsData.removeWhere((d) => d['id'] == id);
            _discountsData.add(newDiscount);
            
            if (_activeDiscountId == id) {
              _activeDiscountId = newId;
            }
          });

          // Save to SharedPreferences if it is active
          if (_activeDiscountId == newId) {
            final prodId = (newDiscount['product_id'] ?? _selectedProduct!['id']).toString();
            await prefs.setInt("active_discount_id_$prodId", newId);
          }
        }
        _showToast("Discount updated successfully!");
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (_selectedProduct != null) {
          await _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to update discount. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("\$print debug: Update workaround error: $e");
      _showToast("Error updating discount: $e");
    }
  }

  Future<void> _deleteDiscount(int id) async {
    final url = "https://billing.srivagroups.in/api/add-discount/$id";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      print("\$print debug: DELETE $url");
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("\$print debug: DELETE $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _discountsData.removeWhere((d) => d['id'] == id);
          if (_activeDiscountId == id) {
            _activeDiscountId = null;
          }
        });

        final prodId = _selectedProduct!['id'].toString();
        await prefs.remove("active_discount_id_$prodId");

        _showToast("Discount deleted successfully!");
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (_selectedProduct != null) {
          await _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to delete discount.");
      }
    } catch (e) {
      print("\$print debug: DELETE $url error: $e");
    }
  }

  Future<void> _setDiscountActiveStatus(int id, bool active) async {
    final status = active ? "active" : "inactive";
    final prefs = await SharedPreferences.getInstance();
    final prodId = _selectedProduct!['id'].toString();

    setState(() {
      if (active) {
        _activeDiscountId = id;
        prefs.setInt("active_discount_id_$prodId", id);
        _showToast("Active discount selected!");
      } else {
        if (_activeDiscountId == id) {
          _activeDiscountId = null;
          prefs.remove("active_discount_id_$prodId");
        }
        _showToast("Discount deactivated.");
      }
    });
    await _updateDiscountPayload(id, status: status);
  }

  // --- COUPON CODE METHODS ---

  Widget _buildCouponScreen() {
    final productName = _selectedProduct!['product_name']?.toString() ?? 'Product';

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Back and Add buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentScreen = 0;
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF4F46E5)),
                label: const Text(
                  "Back to Cards",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFF4F46E5), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCouponSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Add Coupon", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Coupon for $productName",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Manage details and offers for this card type",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Coupons list
          _couponCodesData.isEmpty
              ? Container(
                  width: double.infinity,
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    "No coupons found for this product.",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _couponCodesData.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final coupon = _couponCodesData[index];
                    final id = coupon['id'];
                    final code = coupon['coupon_code']?.toString() ?? coupon['couponCode']?.toString() ?? 'AA';
                    final pct = coupon['discount_pct']?.toString() ?? coupon['discountPct']?.toString();
                    final fixedPrice = coupon['fixed_price']?.toString() ?? coupon['fixedPrice']?.toString();
                    final expiry = coupon['expiry_date']?.toString() ?? coupon['expiryDate']?.toString() ?? '';
                    final isActive = _activeCouponId == id || coupon['status']?.toString().toLowerCase() == 'active';

                    String offerValStr = "";
                    if (pct != null && pct != "0" && pct.isNotEmpty) {
                      offerValStr = "Discount: $pct%";
                    } else if (fixedPrice != null && fixedPrice != "0" && fixedPrice.isNotEmpty) {
                      offerValStr = "Discount: ₹$fixedPrice";
                    } else {
                      offerValStr = "No Discount Set";
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? const Color(0xFF10B981) : Colors.grey.shade200,
                          width: isActive ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top title & actions row
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 16, right: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      code,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "ACTIVE COUPON",
                                          style: TextStyle(color: Color(0xFF065F46), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      onPressed: () => _showCouponCalculatorSheet(coupon),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      onPressed: () => _showEditCouponSheet(coupon),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      onPressed: () => _deleteCouponCode(id),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Contents
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offerValStr,
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                if (expiry.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    "Expiry: $expiry",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                                if (coupon['description']?.toString().isNotEmpty ?? false) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    coupon['description'].toString(),
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Divider
                          CustomPaint(
                            size: const Size(double.infinity, 1),
                            painter: DashedBorderPainter(color: Colors.grey.shade200, gap: 3, dashLength: 4),
                          ),

                          // Bottom set active button
                          InkWell(
                            onTap: () {
                              _setCouponActiveStatus(id, !isActive);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Text(
                                isActive ? "✓ Active Coupon" : "Set as Active Coupon",
                                style: TextStyle(
                                  color: isActive ? Colors.white : const Color(0xFF475569),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showAddCouponSheet() {
    final codeController = TextEditingController();
    final pctController = TextEditingController();
    final priceController = TextEditingController();
    final expiryController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF4F46E5), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Create Coupon Entry",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Coupon Code
                    const Text("Coupon Code *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeController,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        hintText: "e.g. WELCOME20",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Discount % and Fixed Price side by side
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Discount % (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: pctController,
                                enabled: !isSaving,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "e.g. 10",
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Fixed Price (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: priceController,
                                enabled: !isSaving,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "e.g. 50",
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Expiry Date with DatePicker option
                    const Text("Expiry Date (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: expiryController,
                      enabled: !isSaving,
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          // Format as YYYY-MM-DD
                          final monthStr = pickedDate.month.toString().padLeft(2, '0');
                          final dayStr = pickedDate.day.toString().padLeft(2, '0');
                          expiryController.text = "${pickedDate.year}-$monthStr-$dayStr";
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Select Expiry Date",
                        suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Text("Description (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      enabled: !isSaving,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Enter short details...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              final code = codeController.text.trim();
                              if (code.isEmpty) {
                                _showToast("Coupon Code is required!");
                                return;
                              }
                              setSheetState(() {
                                isSaving = true;
                              });
                              try {
                                final pct = double.tryParse(pctController.text.trim());
                                final price = double.tryParse(priceController.text.trim());
                                await _createCouponCode(
                                  code,
                                  pct,
                                  price,
                                  expiryController.text.trim().isNotEmpty ? expiryController.text.trim() : null,
                                  descController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                setSheetState(() {
                                  isSaving = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Save Entry", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditCouponSheet(Map<String, dynamic> coupon) {
    final couponId = coupon['id'];
    final codeController = TextEditingController(text: coupon['coupon_code']?.toString() ?? coupon['couponCode']?.toString() ?? '');
    final pctController = TextEditingController(text: coupon['discount_pct'] != null ? coupon['discount_pct'].toString() : '');
    final priceController = TextEditingController(text: coupon['fixed_price'] != null ? coupon['fixed_price'].toString() : '');
    final expiryController = TextEditingController(text: coupon['expiry_date']?.toString() ?? coupon['expiryDate']?.toString() ?? '');
    final descController = TextEditingController(text: coupon['description']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.settings, color: Color(0xFF4F46E5), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Edit Entry",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Coupon Code
                    const Text("Coupon Code *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeController,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        hintText: "e.g. WELCOME20",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Discount % and Fixed Price side by side
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Discount % (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: pctController,
                                enabled: !isSaving,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "e.g. 10",
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Fixed Price (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: priceController,
                                enabled: !isSaving,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "e.g. 50",
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Expiry Date with DatePicker option
                    const Text("Expiry Date (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: expiryController,
                      enabled: !isSaving,
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          // Format as YYYY-MM-DD
                          final monthStr = pickedDate.month.toString().padLeft(2, '0');
                          final dayStr = pickedDate.day.toString().padLeft(2, '0');
                          expiryController.text = "${pickedDate.year}-$monthStr-$dayStr";
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Select Expiry Date",
                        suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    const Text("Description (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      enabled: !isSaving,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Enter short details...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              final code = codeController.text.trim();
                              if (code.isEmpty) {
                                _showToast("Coupon Code is required!");
                                return;
                              }
                              setSheetState(() {
                                isSaving = true;
                              });
                              try {
                                final pct = double.tryParse(pctController.text.trim());
                                final price = double.tryParse(priceController.text.trim());
                                await _updateCouponCodePayload(
                                  couponId,
                                  couponCode: code,
                                  discountPct: pct,
                                  fixedPrice: price,
                                  expiryDate: expiryController.text.trim().isNotEmpty ? expiryController.text.trim() : null,
                                  description: descController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                setSheetState(() {
                                  isSaving = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Save Entry", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCouponCalculatorSheet(Map<String, dynamic> coupon) {
    final couponName = coupon['coupon_code']?.toString() ?? coupon['couponCode']?.toString() ?? 'AA';
    final pct = coupon['discount_pct'] != null ? double.tryParse(coupon['discount_pct'].toString()) : null;
    final fixedPrice = coupon['fixed_price'] != null ? double.tryParse(coupon['fixed_price'].toString()) : null;

    // Determine initial base price from active price or MRP
    double initialBase = 0.0;
    if (_pricesData.isNotEmpty) {
      final activePrice = _pricesData.firstWhere(
        (p) => p['status']?.toString().toLowerCase() == 'active',
        orElse: () => null,
      );
      if (activePrice != null) {
        initialBase = double.tryParse(activePrice['amount']?.toString() ?? '') ?? 0.0;
      }
    }
    if (initialBase == 0.0) {
      initialBase = double.tryParse(_selectedProduct!['mrp']?.toString() ?? '499.00') ?? 499.00;
    }

    final basePriceController = TextEditingController(text: initialBase.toStringAsFixed(2));
    
    // Choose initial discount type and value based on coupon config
    bool initialIsPercentage = true;
    String initialVal = "0";
    if (pct != null && pct != 0) {
      initialIsPercentage = true;
      initialVal = pct.round().toString();
    } else if (fixedPrice != null && fixedPrice != 0) {
      initialIsPercentage = false;
      initialVal = fixedPrice.round().toString();
    }

    final valueController = TextEditingController(text: initialVal);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isPercentage = initialIsPercentage;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double basePrice = double.tryParse(basePriceController.text) ?? 0.0;
            final double discountVal = double.tryParse(valueController.text) ?? 0.0;

            double appliedDiscount = 0.0;
            if (isPercentage) {
              appliedDiscount = basePrice * (discountVal / 100.0);
            } else {
              appliedDiscount = discountVal;
            }

            // Ensure applied discount does not exceed base price
            if (appliedDiscount > basePrice) {
              appliedDiscount = basePrice;
            }

            final double calculatedBalance = basePrice - appliedDiscount;

            // Setup listeners to update layout instantly
            basePriceController.addListener(() {
              if (context.mounted) {
                setSheetState(() {});
              }
            });
            valueController.addListener(() {
              if (context.mounted) {
                setSheetState(() {});
              }
            });

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payment, color: Color(0xFF4F46E5), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Coupon Discount Calc",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  couponName,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Product Base Price
                    const Text(
                      "Product Base Price (₹)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: basePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: "Enter price",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Defaults to active price or product MRP (₹${initialBase.toStringAsFixed(2)})",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 20),

                    // Discount Type selector
                    const Text(
                      "Discount Type",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setSheetState(() {
                                isPercentage = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPercentage ? const Color(0xFF3B82F6) : Colors.white,
                              foregroundColor: isPercentage ? Colors.white : const Color(0xFF475569),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: isPercentage ? Colors.transparent : Colors.grey.shade200),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("% Percentage", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setSheetState(() {
                                isPercentage = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isPercentage ? const Color(0xFF3B82F6) : Colors.white,
                              foregroundColor: !isPercentage ? Colors.white : const Color(0xFF475569),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: !isPercentage ? Colors.transparent : Colors.grey.shade200),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("₹ Flat Cash Off", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Input Value
                    Text(
                      isPercentage ? "Discount Percentage (%)" : "Discount Amount (₹)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: isPercentage ? "Enter percentage (e.g. 20)" : "Enter flat cash off amount",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Invoice box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SIMULATED INVOICE",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF475569),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Base Price", style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                              Text("₹${basePrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isPercentage
                                    ? "Coupon Discount (${discountVal.toStringAsFixed(0)}%)"
                                    : "Coupon Discount",
                                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                              ),
                              Text("- ₹${appliedDiscount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Calculated Balance", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Text(
                                "₹${calculatedBalance.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Done — Apply Coupon", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createCouponCode(
    String couponCode,
    double? discountPct,
    double? fixedPrice,
    String? expiryDate,
    String description,
  ) async {
    final url = "https://billing.srivagroups.in/api/add-coupon-code";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      final couponCard = _getCardTypeItem("Coupon Code Card");
      final cardId = couponCard?['id'] ?? 5;
      final cardName = couponCard?['card_display_title'] ?? "Coupon Code Card";
      final prodId = _selectedProduct!['id'].toString();
      final prodName = _selectedProduct!['product_name']?.toString() ?? 'Product';

      final body = {
        "product_id": prodId,
        "productId": prodId,
        "product_name": prodName,
        "productName": prodName,
        "card_id": cardId,
        "cardId": cardId,
        "card_name": cardName,
        "cardName": cardName,
        "coupon_code": couponCode,
        "couponCode": couponCode,
        "discount_pct": discountPct?.round(),
        "discountPct": discountPct?.round(),
        "fixed_price": fixedPrice?.round(),
        "fixedPrice": fixedPrice?.round(),
        "expiry_date": expiryDate,
        "expiryDate": expiryDate,
        "description": description,
        "business_id": bId,
        "businessId": bId,
        "user_main_id": uId,
        "userMainId": uId,
        "status": "inactive"
      };

      print("\$print debug: POST $url payload: ${jsonEncode(body)}");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print("\$print debug: POST $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        if (respData['success'] == true && respData['data'] != null) {
          final newCoupon = respData['data'];
          setState(() {
            _couponCodesData.add(newCoupon);
          });
        }
        _showToast("Coupon created successfully!");
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (_selectedProduct != null) {
          await _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to create coupon.");
      }
    } catch (e) {
      print("\$print debug: POST $url error: $e");
    }
  }

  Future<void> _updateCouponCodePayload(
    int id, {
    String? couponCode,
    double? discountPct,
    double? fixedPrice,
    String? expiryDate,
    String? description,
    String? status,
  }) async {
    try {
      final coupon = _couponCodesData.firstWhere((c) => c['id'] == id, orElse: () => null);
      if (coupon == null) {
        _showToast("Coupon not found locally.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      final uId = prefs.getString("user_main_id") ?? "";

      final finalCode = couponCode ?? coupon['coupon_code']?.toString() ?? "";
      final double? finalPctVal = discountPct ?? (coupon['discount_pct'] != null ? double.tryParse(coupon['discount_pct'].toString()) : null);
      final double? finalFixedVal = fixedPrice ?? (coupon['fixed_price'] != null ? double.tryParse(coupon['fixed_price'].toString()) : null);
      final finalExpiry = expiryDate ?? coupon['expiry_date']?.toString();
      final finalDesc = description ?? coupon['description']?.toString() ?? "";
      final finalStatus = status ?? coupon['status']?.toString() ?? "inactive";

      final couponCard = _getCardTypeItem("Coupon Code Card");
      final cardId = couponCard?['id'] ?? coupon['card_id'] ?? 5;
      final cardName = couponCard?['card_display_title'] ?? coupon['card_name'] ?? "Coupon Code Card";
      final prodId = (coupon['product_id'] ?? _selectedProduct!['id']).toString();
      final prodName = (coupon['product_name'] ?? _selectedProduct!['product_name'] ?? 'Product').toString();

      // 1. Delete the old coupon
      final deleteUrl = "https://billing.srivagroups.in/api/add-coupon-code/$id";
      print("\$print debug: DELETE (for update workaround) $deleteUrl");
      try {
        final deleteResponse = await http.delete(
          Uri.parse(deleteUrl),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );
        print("\$print debug: DELETE status: ${deleteResponse.statusCode} response: ${deleteResponse.body}");
      } catch (deleteError) {
        print("\$print debug: DELETE error (proceeding to recreate): $deleteError");
      }

      // 2. Create the new coupon
      final createUrl = "https://billing.srivagroups.in/api/add-coupon-code";
      final body = {
        "product_id": prodId,
        "productId": prodId,
        "product_name": prodName,
        "productName": prodName,
        "card_id": cardId,
        "cardId": cardId,
        "card_name": cardName,
        "cardName": cardName,
        "coupon_code": finalCode,
        "couponCode": finalCode,
        "discount_pct": finalPctVal?.round(),
        "discountPct": finalPctVal?.round(),
        "fixed_price": finalFixedVal?.round(),
        "fixedPrice": finalFixedVal?.round(),
        "expiry_date": finalExpiry,
        "expiryDate": finalExpiry,
        "description": finalDesc,
        "business_id": bId,
        "businessId": bId,
        "user_main_id": uId,
        "userMainId": uId,
        "status": finalStatus
      };

      print("\$print debug: POST (for update workaround) $createUrl payload: ${jsonEncode(body)}");
      final response = await http.post(
        Uri.parse(createUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print("\$print debug: POST status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        if (respData['success'] == true && respData['data'] != null) {
          final newCoupon = respData['data'];
          final newId = newCoupon['id'];
          
          setState(() {
            _couponCodesData.removeWhere((c) => c['id'] == id);
            _couponCodesData.add(newCoupon);
            
            if (_activeCouponId == id) {
              _activeCouponId = newId;
            }
          });

          // Save to SharedPreferences if it is active
          if (_activeCouponId == newId) {
            final prodId = (newCoupon['product_id'] ?? _selectedProduct!['id']).toString();
            await prefs.setInt("active_coupon_id_$prodId", newId);
          }
        }
        _showToast("Coupon updated successfully!");
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (_selectedProduct != null) {
          await _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to update coupon. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("\$print debug: Update workaround error: $e");
      _showToast("Error updating coupon: $e");
    }
  }

  Future<void> _deleteCouponCode(int id) async {
    final url = "https://billing.srivagroups.in/api/add-coupon-code/$id";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      print("\$print debug: DELETE $url");
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("\$print debug: DELETE $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _couponCodesData.removeWhere((c) => c['id'] == id);
          if (_activeCouponId == id) {
            _activeCouponId = null;
          }
        });

        final prodId = _selectedProduct!['id'].toString();
        await prefs.remove("active_coupon_id_$prodId");

        _showToast("Coupon deleted successfully!");
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (_selectedProduct != null) {
          await _fetchCardsData(_selectedProduct!['id'].toString());
        }
      } else {
        _showToast("Failed to delete coupon.");
      }
    } catch (e) {
      print("\$print debug: DELETE $url error: $e");
    }
  }

  Future<void> _setCouponActiveStatus(int id, bool active) async {
    final status = active ? "active" : "inactive";
    final prefs = await SharedPreferences.getInstance();
    final prodId = _selectedProduct!['id'].toString();

    setState(() {
      if (active) {
        _activeCouponId = id;
        prefs.setInt("active_coupon_id_$prodId", id);
        _showToast("Active coupon selected!");
      } else {
        if (_activeCouponId == id) {
          _activeCouponId = null;
          prefs.remove("active_coupon_id_$prodId");
        }
        _showToast("Coupon deactivated.");
      }
    });
    await _updateCouponCodePayload(id, status: status);
  }

  // --- LOCAL OFFER CARD METHODS (NO API) ---

  Widget _buildOfferScreen() {
    final productName = _selectedProduct!['product_name']?.toString() ?? 'Product';

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Back and Add buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentScreen = 0;
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF4F46E5)),
                label: const Text(
                  "Back to Cards",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFF4F46E5), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddOfferSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Add Combo Offer", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.credit_card, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Offer for $productName",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Manage details and offers for this card type",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Offers list
          _localOffersData.isEmpty
              ? Container(
                  width: double.infinity,
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    "No offers found for this product.",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _localOffersData.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final offer = _localOffersData[index];
                    final id = offer['id'] as int;
                    final name = offer['name']?.toString() ?? '';
                    final desc = offer['description']?.toString() ?? '';
                    final isActive = _activeLocalOfferId == id || offer['status'] == 'active';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? const Color(0xFF10B981) : Colors.grey.shade200,
                          width: isActive ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top title & actions row
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 16, right: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "ACTIVE OFFER",
                                          style: TextStyle(color: Color(0xFF065F46), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      onPressed: () => _showOfferCalculatorSheet(offer),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      onPressed: () => _showEditOfferSheet(offer),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      onPressed: () => _deleteLocalOffer(id),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      color: const Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Contents
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (desc.isNotEmpty)
                                  Text(
                                    desc,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  "New Price: ₹${(offer['newPrice'] as double).toStringAsFixed(2)}",
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Divider
                          CustomPaint(
                            size: const Size(double.infinity, 1),
                            painter: DashedBorderPainter(color: Colors.grey.shade200, gap: 3, dashLength: 4),
                          ),

                          // Bottom set active button
                          InkWell(
                            onTap: () {
                              _setLocalOfferActiveStatus(id, !isActive);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Text(
                                isActive ? "✓ Active Combo" : "Set as Active Combo",
                                style: TextStyle(
                                  color: isActive ? Colors.white : const Color(0xFF475569),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showAddOfferSheet() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Color(0xFF4F46E5), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Create Offer Entry",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name Field
                const Text("Name *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "e.g. Special Offer",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Field
                const Text("Description (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Enter details...",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            _showToast("Name is required!");
                            return;
                          }
                          _createLocalOffer(name, descController.text.trim());
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Save Entry", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditOfferSheet(Map<String, dynamic> offer) {
    final id = offer['id'] as int;
    final nameController = TextEditingController(text: offer['name']?.toString() ?? '');
    final descController = TextEditingController(text: offer['description']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.settings, color: Color(0xFF4F46E5), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Edit Entry",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name Field
                const Text("Name *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "e.g. Special Offer",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Field
                const Text("Description (optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Enter details...",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            _showToast("Name is required!");
                            return;
                          }
                          _updateLocalOffer(id, name, descController.text.trim(), null, null);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Save Entry", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOfferCalculatorSheet(Map<String, dynamic> offer) {
    final id = offer['id'] as int;
    final offerName = offer['name']?.toString() ?? '';
    
    // Determine original MRP
    double originalMRP = 0.0;
    if (_pricesData.isNotEmpty) {
      final activePrice = _pricesData.firstWhere(
        (p) => p['status']?.toString().toLowerCase() == 'active',
        orElse: () => null,
      );
      if (activePrice != null) {
        originalMRP = double.tryParse(activePrice['amount']?.toString() ?? '') ?? 0.0;
      }
    }
    if (originalMRP == 0.0) {
      originalMRP = double.tryParse(_selectedProduct!['mrp']?.toString() ?? '499.00') ?? 499.00;
    }

    final double currentNewPrice = (offer['newPrice'] as double?) ?? originalMRP;
    final priceController = TextEditingController(text: currentNewPrice.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double enteredPrice = double.tryParse(priceController.text) ?? 0.0;
            final double diff = enteredPrice - originalMRP;
            final double pctDiff = originalMRP > 0 ? (diff / originalMRP) * 100.0 : 0.0;

            final isIncrease = diff > 0;
            final isDecrease = diff < 0;

            // Setup listener to update UI in real-time
            priceController.addListener(() {
              if (context.mounted) {
                setSheetState(() {});
              }
            });

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.credit_card, color: Color(0xFF4F46E5), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Price Comparison",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  offerName,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Price Comparison row boxes (original mrp vs new price)
                    Row(
                      children: [
                        // Box 1: Original MRP
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "ORIGINAL MRP",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "₹ ${originalMRP.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward, color: Color(0xFF64748B), size: 20),
                        const SizedBox(width: 10),
                        // Box 2: New Price
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "NEW PRICE",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "₹ ${enteredPrice.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Banner showing percentage diff
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isIncrease
                            ? const Color(0xFFECFDF5)
                            : (isDecrease ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isIncrease
                              ? const Color(0xFFA7F3D0)
                              : (isDecrease ? const Color(0xFFFCA5A5) : Colors.grey.shade200),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isIncrease
                                ? Icons.arrow_upward
                                : (isDecrease ? Icons.arrow_downward : Icons.remove),
                            color: isIncrease
                                ? const Color(0xFF047857)
                                : (isDecrease ? const Color(0xFFB91C1C) : Colors.grey.shade600),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isIncrease
                                ? "₹ ${diff.toStringAsFixed(2)} (${pctDiff.toStringAsFixed(1)}%)"
                                : (isDecrease
                                    ? "₹ ${diff.abs().toStringAsFixed(2)} (${pctDiff.abs().toStringAsFixed(1)}%)"
                                    : "₹ 0.00 (0.0%)"),
                            style: TextStyle(
                              color: isIncrease
                                  ? const Color(0xFF047857)
                                  : (isDecrease ? const Color(0xFFB91C1C) : Colors.grey.shade700),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input field
                    const Text("Enter New Price (₹)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _updateLocalOffer(id, offerName, offer['description'] ?? '', enteredPrice, null);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 16),
                                SizedBox(width: 6),
                                Text("Done — Apply New Price", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _createLocalOffer(String name, String desc) {
    setState(() {
      final int nextId = _localOffersData.isEmpty
          ? 1
          : (_localOffersData.map((o) => o['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
      _localOffersData.add({
        "id": nextId,
        "name": name,
        "description": desc,
        "newPrice": 499.0,
        "status": "inactive"
      });
    });
    _showToast("Offer created successfully!");
  }

  void _updateLocalOffer(int id, String name, String desc, double? newPrice, String? status) {
    setState(() {
      final index = _localOffersData.indexWhere((o) => o['id'] == id);
      if (index != -1) {
        final existing = _localOffersData[index];
        _localOffersData[index] = {
          "id": id,
          "name": name,
          "description": desc,
          "newPrice": newPrice ?? existing['newPrice'] ?? 499.0,
          "status": status ?? existing['status'] ?? "inactive"
        };
      }
    });
    _showToast("Offer updated successfully!");
  }

  void _deleteLocalOffer(int id) {
    setState(() {
      _localOffersData.removeWhere((o) => o['id'] == id);
      if (_activeLocalOfferId == id) {
        _activeLocalOfferId = null;
      }
    });
    _showToast("Offer deleted successfully!");
  }

  void _setLocalOfferActiveStatus(int id, bool active) {
    setState(() {
      if (active) {
        _activeLocalOfferId = id;
        for (var o in _localOffersData) {
          if (o['id'] == id) {
            o['status'] = 'active';
          } else {
            o['status'] = 'inactive';
          }
        }
        _showToast("Active combo selected!");
      } else {
        if (_activeLocalOfferId == id) {
          _activeLocalOfferId = null;
        }
        final index = _localOffersData.indexWhere((o) => o['id'] == id);
        if (index != -1) {
          _localOffersData[index]['status'] = 'inactive';
        }
        _showToast("Combo deactivated.");
      }
    });
  }
}

class _ProductSearchSheet extends StatefulWidget {
  final List<dynamic> products;
  final Map<String, dynamic>? selectedProduct;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _ProductSearchSheet({
    required this.products,
    required this.selectedProduct,
    required this.onSelected,
  });

  @override
  State<_ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<_ProductSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _sortedAndFilteredProducts = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _processProducts();
  }

  void _processProducts() {
    // 1. Sort the list alphabetically by product_name
    final List<dynamic> sorted = List.from(widget.products);
    sorted.sort((a, b) {
      final nameA = (a['product_name']?.toString() ?? '').toLowerCase();
      final nameB = (b['product_name']?.toString() ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    // 2. Filter based on query
    if (_searchQuery.isEmpty) {
      _sortedAndFilteredProducts = sorted;
    } else {
      _sortedAndFilteredProducts = sorted.where((p) {
        final name = (p['product_name']?.toString() ?? '').toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Row(
            children: [
              Icon(Icons.search, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                "Search & Select Product",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search TextField
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Type product name...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = "";
                          _processProducts();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _processProducts();
              });
            },
          ),
          const SizedBox(height: 16),
          // List of products
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _sortedAndFilteredProducts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      "No products found",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _sortedAndFilteredProducts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = _sortedAndFilteredProducts[index];
                      final isSelected = widget.selectedProduct != null &&
                          widget.selectedProduct!['id'] == p['id'];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        title: Text(
                          p['product_name']?.toString() ?? 'No Name',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF4F46E5) : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF4F46E5))
                            : null,
                        onTap: () {
                          widget.onSelected(p);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
