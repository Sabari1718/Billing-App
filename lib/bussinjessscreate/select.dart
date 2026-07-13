import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

import '../Auth/api service.dart';
import 'categoryselect.dart';

class BusinessSelectionPage extends StatefulWidget {
  const BusinessSelectionPage({super.key});

  @override
  State<BusinessSelectionPage> createState() =>
      _BusinessSelectionPageState();
}

class _BusinessSelectionPageState
    extends State<BusinessSelectionPage> {

  List businessList = [];
  bool isLoading = true;
  int? loadingIndex;

  @override
  void initState() {
    super.initState();
    fetchBusinesses();
  }

  // ✅ FETCH BUSINESS (SAFE FIX)
  void fetchBusinesses() async {
    try {
      final data = await ApiService.getBusinesses();
      AppLogger.info("Businesses fetched");

      if (data["data"] is List) {
        businessList = data["data"];
      } else if (data["data"] is Map &&
          data["data"]["data"] is List) {
        businessList = data["data"]["data"]; // fallback
      } else {
        businessList = [];
      }
      AppLogger.success("Found ${businessList.length} businesses");

    } catch (e) {
      AppLogger.error("fetchBusinesses error", e);
      showError("Failed to load businesses");
    }

    setState(() => isLoading = false);
  }

  // ✅ SELECT BUSINESS (FIXED)
  Future<void> selectBusiness(int index) async {
    final business = businessList[index];

    // 🔥 FIX: correct id key
    final businessId = business['id'];

    setState(() => loadingIndex = index);

    try {
      final res = await ApiService.selectBusiness({
        "business_id": businessId, // keep same key
      });
      AppLogger.success("Business selected: $businessId");

      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        final token = res['data']['token'];
        await prefs.setString("auth_token", token);

        final int savedBusinessId =
        int.parse(res['data']['business_id'].toString());

        await prefs.setInt("business_id", savedBusinessId);

        final type = business['type']?.toString().toLowerCase() ?? "propagater";
        await prefs.setString("role", type);

        AppLogger.success("Session tokens and role ($type) updated");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CategoryGroupPage(),
          ),
        );
      }
    } catch (e) {
      AppLogger.error("selectBusiness error", e);
      showError("Selection failed");
    }

    setState(() => loadingIndex = null);
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Select Your Business"),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: businessList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final business = businessList[index];
                final isLoadingItem = loadingIndex == index;

                return GestureDetector(
                  onTap: () => selectBusiness(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Center(
                      child: isLoadingItem
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.storefront, size: 36, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    (business['business_name'] ?? business['name'] ?? '').toString(),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}