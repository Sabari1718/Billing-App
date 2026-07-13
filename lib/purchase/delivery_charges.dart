import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryChargesController extends GetxController {
  var products = <dynamic>[].obs;
  var selectedProductId = RxnString();
  var isLoadingProducts = true.obs;
  var isLoadingCharges = false.obs;
  var deliveryChargesData = <dynamic>[].obs;
  var showBanner = false.obs;
  var bannerText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Map<String, dynamic>? get selectedProduct {
    if (selectedProductId.value == null || products.isEmpty) return null;
    try {
      return products.firstWhere((p) => p['id'].toString() == selectedProductId.value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void toast(String msg) {
    bannerText.value = msg;
    showBanner.value = true;
    Future.delayed(const Duration(seconds: 3), () {
      showBanner.value = false;
    });
  }

  Future<void> fetchProducts() async {
    String url = 'https://billing.srivagroups.in/api/products';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final bId = prefs.getString('selected_business_id') ?? prefs.get('business_id')?.toString() ?? '';
      final uId = prefs.getString('user_main_id') ?? '';
      final q = [if (bId.isNotEmpty) 'business_id=$bId', if (uId.isNotEmpty) 'user_main_id=$uId'];
      if (q.isNotEmpty) url += '?${q.join('&')}';

      final res = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      print('\$print debug: GET $url status: ${res.statusCode} response: ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : (decoded is List ? decoded : []);
        list.sort((a, b) => (a['product_name']?.toString() ?? '').toLowerCase().compareTo((b['product_name']?.toString() ?? '').toLowerCase()));
        
        products.assignAll(list);
        isLoadingProducts.value = false;
        if (products.isNotEmpty) {
          selectedProductId.value = products.first['id'].toString();
          fetchDeliveryCharges(selectedProductId.value!);
        }
      } else {
        isLoadingProducts.value = false;
      }
    } catch (e) {
      print('\$print debug: GET $url error: $e');
      isLoadingProducts.value = false;
    }
  }

  Future<void> fetchDeliveryCharges(String productId) async {
    isLoadingCharges.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final bId = prefs.getString('selected_business_id') ?? prefs.get('business_id')?.toString() ?? '';
      final uId = prefs.getString('user_main_id') ?? '';
      final headers = {'Authorization': 'Bearer $token', 'Accept': 'application/json'};

      final p = ['product_id=$productId', if (bId.isNotEmpty) 'business_id=$bId', if (uId.isNotEmpty) 'user_main_id=$uId'];
      final url = 'https://billing.srivagroups.in/api/delivery-charge?${p.join('&')}';
      
      final res = await http.get(Uri.parse(url), headers: headers);
      print('\$print debug: GET $url status: ${res.statusCode} response: ${res.body}');

      List raw = [];
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body.containsKey('data')) raw = body['data'] is List ? body['data'] : [];
        else if (body is List) raw = body;
        raw = raw.where((item) => item is Map && item['product_id']?.toString() == productId).toList();
      }

      deliveryChargesData.assignAll(raw);
      isLoadingCharges.value = false;
    } catch (e) {
      print('\$print debug: delivery charges fetch error: $e');
      isLoadingCharges.value = false;
    }
  }

  Future<void> createCharge(Map<String, dynamic> data) async {
    const url = 'https://billing.srivagroups.in/api/delivery-charge';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final bId = prefs.getString('selected_business_id') ?? prefs.get('business_id')?.toString() ?? '';
      final uId = prefs.getString('user_main_id') ?? '';
      
      final body = {
        'product_id': selectedProductId.value!,
        'productId': selectedProductId.value!,
        'product_name': selectedProduct?['product_name'] ?? '',
        'productName': selectedProduct?['product_name'] ?? '',
        if (bId.isNotEmpty) 'business_id': bId,
        if (uId.isNotEmpty) 'user_main_id': uId,
        ...data,
      };
      
      print('\$print debug: POST $url payload: ${jsonEncode(body)}');
      final res = await http.post(Uri.parse(url),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(body));
      print('\$print debug: POST $url status: ${res.statusCode} response: ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        toast('Charge created!');
        fetchDeliveryCharges(selectedProductId.value!);
      } else {
        toast('Failed: ${res.statusCode}');
      }
    } catch (e) {
      print('\$print debug: POST error: $e');
      toast('Error: $e');
    }
  }

  Future<void> updateCharge(int id, Map<String, dynamic> data) async {
    final url = 'https://billing.srivagroups.in/api/delivery-charge/$id';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      print('\$print debug: PUT $url payload: ${jsonEncode(data)}');
      final res = await http.put(Uri.parse(url),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(data));
      print('\$print debug: PUT $url status: ${res.statusCode} response: ${res.body}');
      if (res.statusCode == 200) {
        toast('Charge updated!');
        fetchDeliveryCharges(selectedProductId.value!);
      } else {
        toast('Failed: ${res.statusCode}');
      }
    } catch (e) {
      print('\$print debug: PUT error: $e');
      toast('Error: $e');
    }
  }

  Future<void> deleteCharge(int id) async {
    final url = 'https://billing.srivagroups.in/api/delivery-charge/$id';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      print('\$print debug: DELETE $url');
      final res = await http.delete(Uri.parse(url), headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      print('\$print debug: DELETE $url status: ${res.statusCode} response: ${res.body}');
      if (res.statusCode == 200) {
        toast('Charge deleted!');
        fetchDeliveryCharges(selectedProductId.value!);
      } else {
        toast('Failed: ${res.statusCode}');
      }
    } catch (e) {
      print('\$print debug: DELETE error: $e');
      toast('Error: $e');
    }
  }
}

class DeliveryChargesPage extends StatelessWidget {
  const DeliveryChargesPage({super.key});

  void _showChargeSheet(BuildContext context, DeliveryChargesController controller, {Map<String, dynamic>? existing}) {
    final defaultTypes = ['Loading Charges', 'Packing Charges', 'Transport Charges'];
    final defaultNames = ['Worker Loading', 'Heavy Lift Charges', 'Crane Loading'];
    
    String initialType = existing?['charge_type']?.toString() ?? existing?['chargeType']?.toString() ?? '';
    String initialName = existing?['charge_name']?.toString() ?? existing?['chargeName']?.toString() ?? '';
    
    bool isCustomType = initialType.isNotEmpty && !defaultTypes.contains(initialType);
    bool isCustomName = initialName.isNotEmpty && !defaultNames.contains(initialName);
    
    String selectedType = isCustomType ? '+ Custom Type...' : (initialType.isEmpty ? defaultTypes.first : initialType);
    String selectedName = isCustomName ? '+ Custom Option...' : (initialName.isEmpty ? defaultNames.first : initialName);

    final chargeTypeCtrl = TextEditingController(text: isCustomType ? initialType : '');
    final chargeNameCtrl = TextEditingController(text: isCustomName ? initialName : '');
    final amountCtrl     = TextEditingController(text: existing?['amount']?.toString() ?? '');
    final unitCtrl       = TextEditingController(text: existing?['unit']?.toString() ?? '');
    final estTimeCtrl    = TextEditingController(text: existing?['estimated_time']?.toString() ?? existing?['estimatedTime']?.toString() ?? '');
    String timeUnit      = existing?['time_unit']?.toString() ?? existing?['timeUnit']?.toString() ?? 'Hours';
    if (!['Hours', 'Days', 'Weeks', 'Months', 'Years'].contains(timeUnit)) timeUnit = 'Hours';
    final locationCtrl   = TextEditingController(text: existing?['delivery_location']?.toString() ?? existing?['deliveryLocation']?.toString() ?? '');
    final descCtrl       = TextEditingController(text: existing?['description']?.toString() ?? '');
    final notesCtrl      = TextEditingController(text: existing?['notes']?.toString() ?? '');
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSS) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              // Handle bar & Header
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Text(isEdit ? 'Update Delivery Charge' : 'Create Delivery Charge',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.pop(ctx),
                    child: Container(padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)))),
                ]),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade200),
              
              // Form Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Charge Type
                    const Text('Charge Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                        value: selectedType, isExpanded: true,
                        items: [...defaultTypes, '+ Custom Type...'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: t.startsWith('+') ? const Color(0xFF4F46E5) : const Color(0xFF1E293B))))).toList(),
                        onChanged: (v) { if (v != null) setSS(() => selectedType = v); },
                      )),
                    ),
                    if (selectedType == '+ Custom Type...') ...[
                      const SizedBox(height: 8),
                      TextField(controller: chargeTypeCtrl, decoration: _inputDeco('Enter custom charge type')),
                    ],
                    const SizedBox(height: 16),
                    
                    // Charge Name *
                    const Text('Charge Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                        value: selectedName, isExpanded: true,
                        items: [...defaultNames, '+ Custom Option...'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: t.startsWith('+') ? const Color(0xFF4F46E5) : const Color(0xFF1E293B))))).toList(),
                        onChanged: (v) { if (v != null) setSS(() => selectedName = v); },
                      )),
                    ),
                    if (selectedName == '+ Custom Option...') ...[
                      const SizedBox(height: 8),
                      TextField(controller: chargeNameCtrl, decoration: _inputDeco('Enter custom charge name')),
                    ],
                    const SizedBox(height: 16),
                    
                    // Amount & Unit
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Amount (₹) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: _inputDeco('e.g. 500')),
                      ])),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Unit (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(controller: unitCtrl, decoration: _inputDeco('e.g. per box')),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    
                    // Estimated Time
                    const Text('Estimated Time (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: TextField(controller: estTimeCtrl, keyboardType: TextInputType.number, decoration: _inputDeco('e.g. 2'))),
                      const SizedBox(width: 16),
                      Expanded(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                          value: timeUnit, isExpanded: true,
                          items: ['Hours', 'Days', 'Weeks', 'Months', 'Years'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) { if (v != null) setSS(() => timeUnit = v); },
                        )),
                      )),
                    ]),
                    const SizedBox(height: 16),
                    
                    // Delivery Location
                    const Text('Delivery Location (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(controller: locationCtrl, decoration: _inputDeco('e.g. Chennai, Mumbai')),
                    const SizedBox(height: 16),
                    
                    // Description
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(controller: descCtrl, maxLines: 3, decoration: _inputDeco('Provide details about the charges...')),
                    const SizedBox(height: 16),
                    
                    // Notes
                    const Text('Notes (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(controller: notesCtrl, maxLines: 3, decoration: _inputDeco('e.g. minimum volume required')),
                  ],
                ),
              ),
              
              // Bottom Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade100)),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300)),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final finalType = selectedType == '+ Custom Type...' ? chargeTypeCtrl.text.trim() : selectedType;
                      final finalName = selectedName == '+ Custom Option...' ? chargeNameCtrl.text.trim() : selectedName;
                      
                      if (finalType.isEmpty) { controller.toast('Charge Type is required'); return; }
                      if (finalName.isEmpty) { controller.toast('Charge Name is required'); return; }
                      if (amountCtrl.text.trim().isEmpty) { controller.toast('Amount is required'); return; }
                      
                      final data = {
                        'product_id': controller.selectedProductId.value!,
                        'productId': controller.selectedProductId.value!,
                        'product_name': controller.selectedProduct?['product_name']?.toString() ?? '',
                        'productName': controller.selectedProduct?['product_name']?.toString() ?? '',
                        'charge_type': finalType,
                        'chargeType': finalType,
                        'charge_name': finalName,
                        'chargeName': finalName,
                        'amount': amountCtrl.text.trim(),
                        'unit': unitCtrl.text.trim(),
                        'estimated_time': estTimeCtrl.text.trim(),
                        'estimatedTime': estTimeCtrl.text.trim(),
                        'time_unit': timeUnit,
                        'timeUnit': timeUnit,
                        'delivery_location': locationCtrl.text.trim(),
                        'deliveryLocation': locationCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'notes': notesCtrl.text.trim(),
                      };
                      
                      Navigator.pop(ctx);
                      if (isEdit) controller.updateCharge(existing!['id'] as int, data);
                      else controller.createCharge(data);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(isEdit ? 'Save Changes' : 'Save Charge', style: const TextStyle(fontWeight: FontWeight.bold))),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
  }

  InputDecoration _inputDeco(String hint, {bool isDropdown = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      suffixIcon: isDropdown ? const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
    );
  }

  Widget _buildSkeleton() {
    return Column(children: List.generate(2, (i) => Container(
      margin: const EdgeInsets.only(bottom: 12), height: 100,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
    )));
  }

  void _showProductSearch(BuildContext context, DeliveryChargesController controller) {
    final searchCtrl = TextEditingController();
    List<dynamic> filtered = List.from(controller.products);

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSS) {
        void onSearch(String q) {
          setSS(() {
            filtered = controller.products.where((p) => (p['product_name']?.toString() ?? '').toLowerCase().contains(q.toLowerCase())).toList();
          });
        }
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.80,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Text('Select Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(ctx),
                  child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.close, size: 18))),
              ])),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(controller: searchCtrl, autofocus: true, onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search products...', prefixIcon: const Icon(Icons.search, color: Color(0xFF4F46E5), size: 20),
                  filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
            const SizedBox(height: 8),
            Divider(height: 1, color: Colors.grey.shade100),
            Expanded(child: filtered.isEmpty
              ? Center(child: Text('No products found', style: TextStyle(color: Colors.grey.shade400)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    final pid = p['id'].toString();
                    final name = p['product_name']?.toString() ?? '';
                    final isSelected = pid == controller.selectedProductId.value;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        controller.selectedProductId.value = pid;
                        controller.fetchDeliveryCharges(pid);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Container(width: 36, height: 36, alignment: Alignment.center,
                            decoration: BoxDecoration(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade100, shape: BoxShape.circle),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? Colors.white : Colors.grey.shade600))),
                          const SizedBox(width: 12),
                          Expanded(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                          if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 20),
                        ]),
                      ),
                    );
                  })),
          ]),
        );
      }),
    );
  }

  void _showDeleteDialog(BuildContext context, DeliveryChargesController controller, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Charge?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This delivery charge will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); controller.deleteCharge(id); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DeliveryChargesController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Delivery Charges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white, elevation: 0, foregroundColor: const Color(0xFF1E293B), surfaceTintColor: Colors.white,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Colors.grey.shade100)),
      ),
      body: Obx(() {
        final prodName = controller.selectedProduct?['product_name']?.toString() ?? '';
        return Stack(children: [
          controller.isLoadingProducts.value
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
              : ListView(padding: const EdgeInsets.all(20), children: [
                  
                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Delivery Charges Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text('Configure loading, packing, and transport costs product-wise', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ])),
                  ]),
                  const SizedBox(height: 24),

                  // Product Selector
                  GestureDetector(
                    onTap: () => _showProductSearch(context, controller),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Row(children: [
                        const Icon(Icons.inventory_2_outlined, color: Color(0xFFCD9C7B), size: 20),
                        const SizedBox(width: 12),
                        const Text('Select Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF475569))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                            child: Row(children: [
                              Expanded(child: Text(prodName.isNotEmpty ? prodName : '— Choose a product —', style: TextStyle(fontSize: 14, color: prodName.isNotEmpty ? const Color(0xFF1E293B) : Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                              const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Content Area
                  if (controller.selectedProduct == null)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 60),
                      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.none)),
                      child: Column(children: [
                        const Icon(Icons.local_shipping, size: 48, color: Color(0xFFFFC107)),
                        const SizedBox(height: 16),
                        Text('Select a product to configure and view its delivery charges', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ]),
                    )
                  else ...[
                    // Charges Header
                    Row(children: [
                      Expanded(child: Text('Charges for $prodName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                      ElevatedButton.icon(
                        onPressed: () => _showChargeSheet(context, controller),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text('Add Delivery Charges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
                    ]),
                    const SizedBox(height: 24),

                    // Charges List
                    controller.isLoadingCharges.value
                        ? _buildSkeleton()
                        : controller.deliveryChargesData.isEmpty
                            ? Container(
                                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 48),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                                child: Column(children: [
                                  Icon(Icons.money_off_csred_outlined, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 10),
                                  Text('No delivery charges configured', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                ]))
                            : Column(
                                children: controller.deliveryChargesData.map((charge) {
                                  final type   = charge['charge_type']?.toString() ?? charge['chargeType']?.toString() ?? 'Charge';
                                  final name   = charge['charge_name']?.toString() ?? charge['chargeName']?.toString() ?? '';
                                  final amount = charge['amount']?.toString() ?? '0';
                                  final unit   = charge['unit']?.toString() ?? '';
                                  final estTime = charge['estimated_time']?.toString() ?? charge['estimatedTime']?.toString() ?? '';
                                  final timeUnit= charge['time_unit']?.toString() ?? charge['timeUnit']?.toString() ?? 'Hours';
                                  final id     = charge['id'] as int;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      // Section Header
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(children: [
                                          const Icon(Icons.local_shipping_outlined, color: Color(0xFF475569), size: 20),
                                          const SizedBox(width: 10),
                                          Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                          const SizedBox(width: 12),
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)), child: const Text('1', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12))),
                                        ]),
                                      ),
                                      Divider(height: 1, color: Colors.grey.shade100),
                                      
                                      // Card Body
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Container(
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Row(children: [
                                              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)))),
                                              GestureDetector(onTap: () => _showChargeSheet(context, controller, existing: Map<String, dynamic>.from(charge)), child: const Icon(Icons.edit, color: Color(0xFFFCA5A5), size: 18)),
                                              const SizedBox(width: 16),
                                              GestureDetector(onTap: () => _showDeleteDialog(context, controller, id), child: Icon(Icons.delete_outline, color: Colors.grey.shade300, size: 18)),
                                            ]),
                                            const SizedBox(height: 12),
                                            Text('₹ $amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF10B981))),
                                            const SizedBox(height: 12),
                                            if (unit.isNotEmpty) ...[
                                              Row(children: [
                                                Text('QTY/Unit: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: Text(unit, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600))),
                                              ]),
                                              const SizedBox(height: 12),
                                            ],
                                            if (estTime.isNotEmpty) ...[
                                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                const Icon(Icons.hourglass_empty, size: 12, color: Color(0xFFCD9C7B)),
                                                const SizedBox(width: 4),
                                                Text('$estTime $timeUnit', style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                                              ])),
                                            ]
                                          ]),
                                        ),
                                      )
                                    ]),
                                  );
                                }).toList()),
                    
                    // Save Configuration Button
                    if (!controller.isLoadingCharges.value && controller.deliveryChargesData.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => controller.toast('Configuration saved!'),
                          icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                          label: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]
                  ],
                ]),

          if (controller.showBanner.value)
            Positioned(
              top: 16, left: 16, right: 16,
              child: Material(
                elevation: 6, borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFA7F3D0))),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(controller.bannerText.value, style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13))),
                  ]),
                ),
              )),
        ]);
      }),
    );
  }
}
