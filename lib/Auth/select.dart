import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'api service.dart';
import 'billing dashboardc.dart' hide ApiService;
import '../MAINDASHBOARD.dart';
import 'role_selection.dart';

class BusinessSelectionPage extends StatefulWidget {
  @override
  State<BusinessSelectionPage> createState() =>
      _BusinessSelectionPageState();
}

class _BusinessSelectionPageState
    extends State<BusinessSelectionPage> {

  List businessList = [];
  String selectedId = '';
  String selectedName = '';
  bool isLoading = true;
  bool isSelecting = false;

  @override
  void initState() {
    super.initState();
    fetchBusinesses();
  }

  void fetchBusinesses() async {
    try {
      final data = await ApiService.getBusinesses();
      AppLogger.info("Businesses fetched for auth");

      if (data is List) {
        businessList = data as List<dynamic>;
      } else if (data["data"] is List) {
        businessList = data["data"];
      } else {
        businessList = [];
      }
    } catch (e) {
      AppLogger.error("fetchBusinesses error", e);
      showError("Failed to load businesses");
    }

    setState(() => isLoading = false);
  }

  void handleContinue() async {
    if (selectedId.isEmpty) return;

    setState(() => isSelecting = true);

    try {
      final response = await ApiService.selectBusiness({
        "business_id": int.parse(selectedId),
      });
      AppLogger.success("Business selected: $selectedId");

      final selectedBiz = businessList.firstWhere(
        (b) => (b["id"] ?? b["business_id"]).toString() == selectedId,
        orElse: () => null,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("business_id", selectedId);
      await prefs.setString("business_name", selectedName);
      
      String type = "business";
      if (selectedBiz != null) {
        type = (selectedBiz["type"] ?? "business").toString().toLowerCase();
        await prefs.setString("business_type", type);
        await prefs.setString("business_email", (selectedBiz["business_email"] ?? "").toString());
        await prefs.setString("business_phone", (selectedBiz["business_phone"] ?? "").toString());
        await prefs.setString("user_main_id", (selectedBiz["user_main_id"] ?? "").toString());
        await prefs.setString("role", type); // Sync for dashboard
      }

      final token = response["token"] ?? response["data"]?["token"];
      if (token != null) {
        await prefs.setString("token", token);
      }

      Widget nextScreen = const RoleSelectionPage();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );

    } catch (e) {
      AppLogger.error("selectBusiness error", e);
      showError("Selection failed: $e");
      setState(() => isSelecting = false);
    }
  }
  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading businesses...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Select Business"),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Which business?",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose a business to access its dashboard and start billing.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          /// 🔽 BUSINESS LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: businessList.length,
              itemBuilder: (context, index) {
                final biz = businessList[index];
                final id = (biz["id"] ?? biz["business_id"]).toString();
                final name = biz["business_name"] ?? biz["name"] ?? "Unnamed";
                final type = biz["type"] ?? "unknown";
                final email = biz["business_email"] ?? "";
                final phone = biz["business_phone"] ?? "";
                
                final isSelected = selectedId == id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedId = id;
                      selectedName = name;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (!isSelected) 
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.storefront,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 18,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔽 CONTINUE BUTTON
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                (selectedId.isEmpty || isSelecting)
                    ? null
                    : handleContinue,
                child: isSelecting
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text("Continue to Dashboard", style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}