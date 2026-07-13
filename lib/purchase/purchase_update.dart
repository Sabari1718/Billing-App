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

class PurchaseChargesPage extends StatefulWidget {
  const PurchaseChargesPage({super.key});

  @override
  State<PurchaseChargesPage> createState() => _PurchaseChargesPageState();
}

class _PurchaseChargesPageState extends State<PurchaseChargesPage> {
  List<dynamic> _products = [];
  Map<String, dynamic>? _selectedProduct;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
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

      // Print debug statement with $print debug exactly as requested
      print("\$print debug: GET $url status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List list = (decoded is Map && decoded.containsKey('data')) 
            ? decoded['data'] 
            : (decoded is List ? decoded : []);
        
        setState(() {
          _products = list;
          _isLoading = false;
        });
      } else {
        String serverMsg = "";
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('message')) {
            serverMsg = decoded['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _errorMessage = serverMsg.isNotEmpty
              ? "Backend Error: $serverMsg"
              : "Failed to load products. Status: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("\$print debug: GET $url error: $e");
      setState(() {
        final errMsg = (e.toString().contains("SocketException") || e.toString().contains("Failed host lookup"))
            ? "Please connect network"
            : "Connection error: $e";
        _errorMessage = errMsg;
        _isLoading = false;
      });
    }
  }

  void _showAddChargesBottomSheet() {
    final productName = _selectedProduct?['product_name']?.toString() ?? 'Product';
    
    // Controllers
    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final purchasePriceCtrl = TextEditingController(text: _selectedProduct?['cost_price']?.toString() ?? '');
    final transportChargeCtrl = TextEditingController();
    final additionalChargeCtrl = TextEditingController();
    final otherChargesCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    String selectedWeightUnit = 'kg';
    String selectedHeightUnit = 'cm';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "Create Purchase Charge",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Form Fields (Scrollable)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Weight and Height Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Weight
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Weight (Optional)",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: TextField(
                                            controller: weightCtrl,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              hintText: "e.g. 1.5",
                                              filled: true,
                                              fillColor: const Color(0xFFF8FAFC),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.grey.shade200),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.grey.shade200),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: selectedWeightUnit,
                                                isExpanded: true,
                                                items: ['kg', 'g', 'lbs'].map((String unit) {
                                                  return DropdownMenuItem<String>(
                                                    value: unit,
                                                    child: Text(unit),
                                                  );
                                                }).toList(),
                                                onChanged: (String? val) {
                                                  if (val != null) {
                                                    setModalState(() {
                                                      selectedWeightUnit = val;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Height
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Height (Optional)",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: TextField(
                                            controller: heightCtrl,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              hintText: "e.g. 45",
                                              filled: true,
                                              fillColor: const Color(0xFFF8FAFC),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.grey.shade200),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(color: Colors.grey.shade200),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: selectedHeightUnit,
                                                isExpanded: true,
                                                items: ['cm', 'inch', 'm'].map((String unit) {
                                                  return DropdownMenuItem<String>(
                                                    value: unit,
                                                    child: Text(unit),
                                                  );
                                                }).toList(),
                                                onChanged: (String? val) {
                                                  if (val != null) {
                                                    setModalState(() {
                                                      selectedHeightUnit = val;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Purchase Price
                          const Text(
                            "Purchase Price (₹) *",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: purchasePriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: "e.g. 5000",
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Transport Charge
                          const Text(
                            "Transport Charge (₹)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: transportChargeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: "e.g. 200",
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Additional Charge
                          const Text(
                            "Additional Charge (₹)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: additionalChargeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: "e.g. 150",
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Other Charges
                          const Text(
                            "Other Charges (₹)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: otherChargesCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: "e.g. 50",
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Notes
                          const Text(
                            "Notes",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: notesCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "e.g. special handling guidelines, supplier discounts, tax details...",
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (purchasePriceCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Purchase Price is required"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setModalState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      final prefs = await SharedPreferences.getInstance();
                                      final token = prefs.getString("auth_token") ?? "";

                                      final rawId = _selectedProduct?['id'];
                                      final parsedId = (rawId is int) 
                                          ? rawId 
                                          : (int.tryParse(rawId?.toString() ?? "") ?? rawId);

                                      final businessIdStr = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
                                      final businessIdInt = int.tryParse(businessIdStr);

                                      final bodyData = {
                                        "business_id": businessIdInt,
                                        "businessId": businessIdInt,
                                        "product_id": parsedId,
                                        "productId": parsedId,
                                        "productName": productName,
                                        "product_name": productName,
                                        "weight": double.tryParse(weightCtrl.text) ?? 0.0,
                                        "weightUnit": selectedWeightUnit,
                                        "weight_unit": selectedWeightUnit,
                                        "height": double.tryParse(heightCtrl.text) ?? 0.0,
                                        "heightUnit": selectedHeightUnit,
                                        "height_unit": selectedHeightUnit,
                                        "purchasePrice": double.tryParse(purchasePriceCtrl.text) ?? 0.0,
                                        "purchase_price": double.tryParse(purchasePriceCtrl.text) ?? 0.0,
                                        "transportCharge": double.tryParse(transportChargeCtrl.text) ?? 0.0,
                                        "transport_charge": double.tryParse(transportChargeCtrl.text) ?? 0.0,
                                        "additionalCharge": double.tryParse(additionalChargeCtrl.text) ?? 0.0,
                                        "additional_charge": double.tryParse(additionalChargeCtrl.text) ?? 0.0,
                                        "otherCharges": double.tryParse(otherChargesCtrl.text) ?? 0.0,
                                        "other_charges": double.tryParse(otherChargesCtrl.text) ?? 0.0,
                                        "notes": notesCtrl.text.trim(),
                                      };

                                      final response = await http.post(
                                        Uri.parse("https://billing.srivagroups.in/api/purchase-charge"),
                                        headers: {
                                          "Authorization": "Bearer $token",
                                          "Content-Type": "application/json",
                                          "Accept": "application/json",
                                        },
                                        body: jsonEncode(bodyData),
                                      );

                                      // Print debug statement with $print debug exactly as requested
                                      print("\$print debug: POST https://billing.srivagroups.in/api/purchase-charge status: ${response.statusCode} response: ${response.body}");

                                      if (response.statusCode == 200 || response.statusCode == 201) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Purchase charge saved successfully!"),
                                            backgroundColor: Color(0xFF059669),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Failed to save: ${response.statusCode}"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print("\$print debug: POST https://billing.srivagroups.in/api/purchase-charge error: $e");
                                      final isNetworkError = e.toString().contains("SocketException") || e.toString().contains("Failed host lookup");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isNetworkError ? "Please connect network" : "Error: $e"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } finally {
                                      setModalState(() {
                                        isSaving = false;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Save Charge",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text("Purchase Charges"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF065F46),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Purchase Charges Management",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Configure purchase prices, dimensions, transport, and additional charges product-wise",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Select Product Card
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Color(0xFF065F46)),
                        const SizedBox(width: 8),
                        const Text(
                          "Select Product",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _errorMessage != null
                            ? Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Map<String, dynamic>>(
                                    hint: const Text(
                                      "— Choose a product —",
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                    value: _selectedProduct,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                    items: _products.map((p) {
                                      return DropdownMenuItem<Map<String, dynamic>>(
                                        value: p as Map<String, dynamic>,
                                        child: Text(
                                          p['product_name']?.toString() ?? 'No Name',
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedProduct = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dashed Box or Selected Product charges UI
            if (_selectedProduct == null)
              CustomPaint(
                painter: DashedBorderPainter(
                  color: const Color(0xFF059669).withOpacity(0.3),
                  strokeWidth: 1.5,
                  gap: 6,
                  dashLength: 6,
                  borderRadius: 16,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 80,
                        color: const Color(0xFF059669).withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Select a product to configure and view its purchase charges",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Header when product is selected
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Charges for ${_selectedProduct!['product_name']?.toString() ?? ''}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddChargesBottomSheet,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      "Add Purchase Charges",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Empty purchase charges Card
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: const Color(0xFF34D399).withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No purchase charges set yet",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add purchase price, transport and additional charges for this product to manage inventory costs.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomPaint(
                          painter: DashedBorderPainter(
                            color: const Color(0xFF059669),
                            strokeWidth: 1.2,
                            gap: 4,
                            dashLength: 4,
                            borderRadius: 8,
                          ),
                          child: InkWell(
                            onTap: _showAddChargesBottomSheet,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: const Text(
                                "+ Add Charges",
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PurchaseChargesListPage extends StatefulWidget {
  const PurchaseChargesListPage({super.key});

  @override
  State<PurchaseChargesListPage> createState() => _PurchaseChargesListPageState();
}

class _PurchaseChargesListPageState extends State<PurchaseChargesListPage> {
  List<dynamic> _purchaseCharges = [];
  List<dynamic> _filteredCharges = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPurchaseCharges();
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
        _filteredCharges = _purchaseCharges;
      } else {
        _filteredCharges = _purchaseCharges.where((item) {
          final pName = item['productName']?.toString().toLowerCase() ?? 
                        item['product_name']?.toString().toLowerCase() ?? "";
          return pName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchPurchaseCharges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/purchase-charge"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      // Print debug statement with $print debug exactly as requested
      print("\$print debug: GET https://billing.srivagroups.in/api/purchase-charge status: ${response.statusCode} response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List list = [];
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] is List ? decoded['data'] : [];
        } else if (decoded is List) {
          list = decoded;
        }

        setState(() {
          _purchaseCharges = list;
          _filteredCharges = list;
          _isLoading = false;
        });
      } else {
        String serverMsg = "";
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('message')) {
            serverMsg = decoded['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _errorMessage = serverMsg.isNotEmpty
              ? "Backend Error: $serverMsg"
              : "Failed to load purchase charges. Status: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("\$print debug: GET https://billing.srivagroups.in/api/purchase-charge error: $e");
      setState(() {
        final errMsg = (e.toString().contains("SocketException") || e.toString().contains("Failed host lookup"))
            ? "Please connect network"
            : "Connection error: $e";
        _errorMessage = errMsg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Purchase List"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Card
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Purchase Charges List",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "View, search, edit, and delete configured purchase charges for all products",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Configure Charges button at top row for ease of navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PurchaseChargesPage()),
                    ).then((_) => _fetchPurchaseCharges());
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                  label: const Text(
                    "Configure Charges",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // White Main Card Container
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Search by product name...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content State Loader, Error, Empty list or Filtered items list
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            children: [
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchPurchaseCharges,
                                child: const Text("Retry"),
                              )
                            ],
                          ),
                        ),
                      )
                    else if (_filteredCharges.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No purchase charges found",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Configure purchase charges for your products\nto list them here.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PurchaseChargesPage()),
                                  ).then((_) => _fetchPurchaseCharges());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text(
                                  "Add Purchase Charge",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Render purchase charges list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredCharges.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final charge = _filteredCharges[index];
                          final pName = charge['productName']?.toString() ?? 
                                        charge['product_name']?.toString() ?? 'Unknown Product';
                          final purchasePrice = charge['purchasePrice']?.toString() ?? 
                                                charge['purchase_price']?.toString() ?? '0.00';
                          final transportCharge = charge['transportCharge']?.toString() ?? 
                                                  charge['transport_charge']?.toString() ?? '0.00';
                          final additionalCharge = charge['additionalCharge']?.toString() ?? 
                                                   charge['additional_charge']?.toString() ?? '0.00';
                          final otherCharges = charge['otherCharges']?.toString() ?? 
                                               charge['other_charges']?.toString() ?? '0.00';
                          final weight = charge['weight']?.toString() ?? '0';
                          final weightUnit = charge['weightUnit']?.toString() ?? 
                                             charge['weight_unit']?.toString() ?? 'kg';
                          final height = charge['height']?.toString() ?? '0';
                          final heightUnit = charge['heightUnit']?.toString() ?? 
                                             charge['height_unit']?.toString() ?? 'cm';
                          final notes = charge['notes']?.toString() ?? '';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                      onSelected: (val) {
                                        if (val == 'delete') {
                                          _deleteCharge(charge);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                              SizedBox(width: 8),
                                              Text("Delete", style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _buildChargeTag("Purchase: ₹$purchasePrice"),
                                    _buildChargeTag("Transport: ₹$transportCharge"),
                                    if (double.tryParse(additionalCharge) != 0)
                                      _buildChargeTag("Additional: ₹$additionalCharge"),
                                    if (double.tryParse(otherCharges) != 0)
                                      _buildChargeTag("Other: ₹$otherCharges"),
                                    if (double.tryParse(weight) != 0)
                                      _buildChargeTag("W: $weight $weightUnit"),
                                    if (double.tryParse(height) != 0)
                                      _buildChargeTag("H: $height $heightUnit"),
                                  ],
                                ),
                                if (notes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    "Notes: $notes",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargeTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
      ),
    );
  }

  Future<void> _deleteCharge(dynamic charge) async {
    final id = charge['id'] ?? charge['productId'];
    print("\$print debug: deleting purchase charge for ID: $id");
    setState(() {
      _purchaseCharges.removeWhere((item) => (item['id'] ?? item['productId']) == id);
      _onSearchChanged();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Purchase charge deleted successfully!")),
    );
  }
}
