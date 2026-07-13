import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SellerUpdateController extends GetxController {
  var products = <dynamic>[].obs;
  var selectedProductId = RxnString();
  var isLoadingProducts = true.obs;
  var isLoadingCards = false.obs;
  var cardTypesData = <dynamic>[].obs;
  var comboCount = 0.obs;
  var discountCount = 0.obs;
  var couponCount = 0.obs;
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
      return products.firstWhere((p) => p['id'].toString() == selectedProductId.value)
          as Map<String, dynamic>;
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

      final res = await http.get(Uri.parse(url),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      print('\$print debug: GET $url status: ${res.statusCode} response: ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List list = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data'] : (decoded is List ? decoded : []);
        list.sort((a, b) => (a['product_name']?.toString() ?? '').toLowerCase()
            .compareTo((b['product_name']?.toString() ?? '').toLowerCase()));
        
        products.assignAll(list);
        isLoadingProducts.value = false;
        if (products.isNotEmpty) {
          selectedProductId.value = products.first['id'].toString();
          fetchCardsData(selectedProductId.value!);
        }
      } else {
        isLoadingProducts.value = false;
      }
    } catch (e) {
      print('\$print debug: GET $url error: $e');
      isLoadingProducts.value = false;
    }
  }

  Future<void> fetchCardsData(String productId) async {
    isLoadingCards.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final bId = prefs.getString('selected_business_id') ?? prefs.get('business_id')?.toString() ?? '';
      final uId = prefs.getString('user_main_id') ?? '';
      final headers = {'Authorization': 'Bearer $token', 'Accept': 'application/json'};

      String buildUrl(String base) {
        final p = ['product_id=$productId', if (bId.isNotEmpty) 'business_id=$bId', if (uId.isNotEmpty) 'user_main_id=$uId'];
        return '$base?${p.join('&')}';
      }

      final urls = [
        buildUrl('https://billing.srivagroups.in/api/add-card-type'),
        buildUrl('https://billing.srivagroups.in/api/add-combo-offer'),
        buildUrl('https://billing.srivagroups.in/api/add-discount'),
        buildUrl('https://billing.srivagroups.in/api/add-coupon-code'),
      ];

      final results = await Future.wait(urls.map((u) =>
          http.get(Uri.parse(u), headers: headers)
              .catchError((_) => http.Response('{}', 500))));

      for (int i = 0; i < results.length; i++) {
        print('\$print debug: GET ${urls[i]} status: ${results[i].statusCode} response: ${results[i].body}');
      }

      List<dynamic> filter(dynamic body, String pid) {
        List raw = [];
        if (body is Map && body.containsKey('data')) raw = body['data'] is List ? body['data'] : [];
        else if (body is List) raw = body;
        return raw.where((item) => item is Map && item['product_id']?.toString() == pid).toList();
      }

      cardTypesData.assignAll(results[0].statusCode == 200 ? filter(jsonDecode(results[0].body), productId) : []);
      comboCount.value    = results[1].statusCode == 200 ? filter(jsonDecode(results[1].body), productId).length : 0;
      discountCount.value = results[2].statusCode == 200 ? filter(jsonDecode(results[2].body), productId).length : 0;
      couponCount.value   = results[3].statusCode == 200 ? filter(jsonDecode(results[3].body), productId).length : 0;
      isLoadingCards.value = false;
    } catch (e) {
      print('\$print debug: cards fetch error: $e');
      isLoadingCards.value = false;
    }
  }

  Future<void> createCard(String cardType, String title) async {
    const url = 'https://billing.srivagroups.in/api/add-card-type';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final bId = prefs.getString('selected_business_id') ?? prefs.get('business_id')?.toString() ?? '';
      final uId = prefs.getString('user_main_id') ?? '';
      final prodId = selectedProductId.value!;
      final body = {
        'productId': prodId,
        'cardType': cardType,
        'cardDisplayTitle': title,
        if (bId.isNotEmpty) 'business_id': bId,
        if (uId.isNotEmpty) 'user_main_id': uId,
      };
      print('\$print debug: POST $url payload: ${jsonEncode(body)}');
      final res = await http.post(Uri.parse(url),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(body));
      print('\$print debug: POST $url status: ${res.statusCode} response: ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        toast('Card created!');
        fetchCardsData(prodId);
      } else {
        toast('Failed: ${res.statusCode}');
      }
    } catch (e) {
      print('\$print debug: POST error: $e');
      toast('Error: $e');
    }
  }

  Future<void> updateCard(int id, String cardType, String title) async {
    final url = 'https://billing.srivagroups.in/api/add-card-type/$id';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final body = {'cardType': cardType, 'cardDisplayTitle': title};
      print('\$print debug: PUT $url payload: ${jsonEncode(body)}');
      final res = await http.put(Uri.parse(url),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(body));
      print('\$print debug: PUT $url status: ${res.statusCode} response: ${res.body}');
      if (res.statusCode == 200) {
        toast('Card updated!');
        fetchCardsData(selectedProductId.value!);
      } else {
        toast('Failed: ${res.statusCode}');
      }
    } catch (e) {
      print('\$print debug: PUT error: $e');
      toast('Error: $e');
    }
  }

  Future<void> deleteCard(int id) async {
    final url = 'https://billing.srivagroups.in/api/add-card-type/$id';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      print('\$print debug: DELETE $url');
      final res = await http.delete(Uri.parse(url),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      print('\$print debug: DELETE $url status: ${res.statusCode} response: ${res.body}');
      if (res.statusCode == 200) {
        toast('Card deleted!');
        fetchCardsData(selectedProductId.value!);
      } else {
        toast('Failed: ${res.statusCode}');
      }
    } catch (e) {
      print('\$print debug: DELETE error: $e');
      toast('Error: $e');
    }
  }
}

class SellerUpdatePage extends StatelessWidget {
  const SellerUpdatePage({super.key});

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'offer': return Icons.credit_card;
      case 'combo': return Icons.inventory_2_outlined;
      case 'discount': return Icons.percent;
      case 'coupon code card': return Icons.confirmation_number_outlined;
      default: return Icons.attach_money;
    }
  }

  String _subtitleFor(SellerUpdateController controller, String type) {
    switch (type.toLowerCase()) {
      case 'combo': return '${controller.comboCount.value} combo${controller.comboCount.value == 1 ? '' : 's'}';
      case 'discount': return '${controller.discountCount.value} discount${controller.discountCount.value == 1 ? '' : 's'}';
      case 'coupon code card': return '${controller.couponCount.value} coupon${controller.couponCount.value == 1 ? '' : 's'}';
      default: return '1 offer';
    }
  }

  void _showCardSheet(BuildContext context, SellerUpdateController controller, {Map<String, dynamic>? existing}) {
    final typeCtrl  = TextEditingController(text: existing?['card_type']?.toString() ?? '');
    final titleCtrl = TextEditingController(text: existing?['card_display_title']?.toString() ?? '');
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSS) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Handle bar
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(isEdit ? Icons.edit : Icons.add_card, color: const Color(0xFF4F46E5), size: 20)),
                const SizedBox(width: 12),
                Text(isEdit ? 'Edit Pricing Card' : 'Add Pricing Card',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(ctx),
                  child: Container(padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 18))),
              ]),
              const SizedBox(height: 20),

              // Card Type text field
              const Text('Card Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: typeCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Offer, Combo, Discount...',
                  prefixIcon: const Icon(Icons.label_outline, color: Color(0xFF4F46E5), size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              // Display Title
              const Text('Display Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: 'Enter title shown to customer',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                ),
              ),
              const SizedBox(height: 22),

              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300)),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    final ct = typeCtrl.text.trim();
                    final t  = titleCtrl.text.trim();
                    if (ct.isEmpty) { controller.toast('Card type is required'); return; }
                    if (t.isEmpty)  { controller.toast('Display title is required'); return; }
                    Navigator.pop(ctx);
                    if (isEdit) controller.updateCard(existing!['id'] as int, ct, t);
                    else controller.createCard(ct, t);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(isEdit ? 'Save Changes' : 'Add Card',
                      style: const TextStyle(fontWeight: FontWeight.bold)))),
              ]),
            ]),
          ),
        );
      }),
    );
  }

  Widget _buildSkeleton() {
    return Column(children: List.generate(4, (i) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16)),
    )));
  }

  Widget _buildCardItem(BuildContext context, SellerUpdateController controller, dynamic card) {
    final type  = card['card_type']?.toString() ?? '';
    final title = card['card_display_title']?.toString() ?? type;
    final id    = card['id'] as int;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Left accent bar
            Container(width: 5, color: const Color(0xFF4F46E5)),
            // Card body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0FF),
                      borderRadius: BorderRadius.circular(10)),
                    child: Icon(_iconFor(type), color: const Color(0xFF4F46E5), size: 20)),
                  const SizedBox(width: 10),
                  // Title + subtitle
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 2),
                      Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(_subtitleFor(controller, type),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  // Actions
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    GestureDetector(
                      onTap: () => _showCardSheet(context, controller, existing: Map<String, dynamic>.from(card)),
                      child: const Icon(Icons.edit, color: Color(0xFFF59E0B), size: 17)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showDeleteDialog(context, controller, id),
                      child: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 17)),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SellerUpdateController controller, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Card?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This card and its data will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); controller.deleteCard(id); },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete')),
        ],
      ),
    );
  }

  void _showProductSearch(BuildContext context, SellerUpdateController controller) {
    final searchCtrl = TextEditingController();
    List<dynamic> filtered = List.from(controller.products);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) {
          void onSearch(String q) {
            setSS(() {
              filtered = controller.products.where((p) =>
                (p['product_name']?.toString() ?? '').toLowerCase().contains(q.toLowerCase())
              ).toList();
            });
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.80,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(children: [
              // Handle bar
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const Text('Select Product',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18))),
                ])),
              const SizedBox(height: 12),
              // Search field
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4F46E5), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  ),
                )),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade100),
              // Product list
              Expanded(child: filtered.isEmpty
                ? Center(child: Text('No products found', style: TextStyle(color: Colors.grey.shade400)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: filtered.length,
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
                          controller.fetchCardsData(pid);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade100,
                                shape: BoxShape.circle),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14,
                                  color: isSelected ? Colors.white : Colors.grey.shade600))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B)),
                              overflow: TextOverflow.ellipsis)),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 20),
                          ]),
                        ),
                      );
                    },
                  )),
            ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerUpdateController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Seller Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100)),
      ),
      body: Obx(() {
        final prodName = controller.selectedProduct?['product_name']?.toString() ?? '';
        return Stack(children: [
          controller.isLoadingProducts.value
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
              : ListView(padding: const EdgeInsets.all(16), children: [

                  // ── Header ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.sync_alt_rounded, color: Colors.white, size: 24)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Seller Update',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Manage pricing cards per product',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Product selector ────────────────────────
                  GestureDetector(
                    onTap: () => _showProductSearch(context, controller),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(children: [
                            const Icon(Icons.widgets_outlined, color: Color(0xFF4F46E5), size: 18),
                            const SizedBox(width: 10),
                            const Text('Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                prodName.isNotEmpty ? prodName : 'Choose a product',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: prodName.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                  color: prodName.isNotEmpty ? const Color(0xFF1E293B) : Colors.grey.shade400),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4F46E5)),
                          ]),
                        ),
                        if (controller.selectedProduct != null) ...[
                          Divider(height: 1, color: Colors.grey.shade100),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(children: [
                              Container(width: 8, height: 8,
                                decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(prodName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5)),
                                  overflow: TextOverflow.ellipsis)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                                child: Text('${controller.cardTypesData.length} cards',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)))),
                            ]),
                          ),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Card list header ────────────────────────
                  if (controller.selectedProduct != null) ...[
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Pricing Cards', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text('for $prodName', style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis),
                      ])),
                      ElevatedButton.icon(
                        onPressed: () => _showCardSheet(context, controller),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text('Add Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
                    ]),
                    const SizedBox(height: 14),

                    // ── Cards 2-column grid ──────────────────────
                    controller.isLoadingCards.value
                        ? _buildSkeleton()
                        : controller.cardTypesData.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 48),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade100)),
                                child: Column(children: [
                                  Icon(Icons.credit_card_off_outlined, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 10),
                                  Text('No pricing cards yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('Tap "+ Add Card" to create one',
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                ]))
                            : Column(
                                children: controller.cardTypesData.asMap().entries.map((entry) {
                                  final i    = entry.key;
                                  final card = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: i < controller.cardTypesData.length - 1 ? 12 : 0),
                                    child: _buildCardItem(context, controller, card),
                                  );
                                }).toList(),
                              ),
                    const SizedBox(height: 24),

                    // ── Save Configuration button ────────────────
                    if (!controller.isLoadingCards.value && controller.cardTypesData.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => controller.toast('Configuration saved!'),
                          icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                          label: const Text('Save Configuration',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ]),

          // ── Toast banner ────────────────────────────────
          if (controller.showBanner.value)
            Positioned(
              top: 16, left: 16, right: 16,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0))),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(controller.bannerText.value,
                        style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13))),
                  ]),
                ),
              )),
        ]);
      }),
    );
  }
}
