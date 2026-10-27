import 'dart:io';
import 'package:billingapp/purchase/purchase_update.dart';
import 'package:billingapp/purchase/pricing_offers.dart';
import 'package:billingapp/purchase/seller_update.dart';
import 'package:billingapp/purchase/delivery_charges.dart';
import 'package:billingapp/product/add product.dart';
import 'package:billingapp/product/stock%20list.dart';
import 'package:billingapp/product/storage.dart';
import 'package:billingapp/product/viewpage.dart';
import 'package:billingapp/product/variant_master.dart';
import 'package:billingapp/product/storage_allocation.dart';
import 'package:billingapp/product/new_product_page.dart';
import 'package:flutter/material.dart';
import 'package:billingapp/sales/sales_point.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/product/stock entry.dart';
import 'package:billingapp/product/stock_orders.dart';
import 'package:billingapp/product/stock_status.dart';
import 'package:billingapp/product/restock_requests.dart';
import 'package:billingapp/product/inventory_settings.dart';

import '../billing/Generate Bill.dart';
import '../billing/invoices.dart';
import '../billing/purchase_bill_entry.dart';
import '../billing/purchase_list.dart';
import '../bussinjessscreate/select.dart';
import '../bussinjessscreate/categoryselect.dart';
import '../suppliers/Deliveries.dart';
import '../suppliers/Supplier Orders.dart';
import '../suppliers/Supplier Payments.dart';
import '../suppliers/Supplier Products.dart';
import '../suppliers/Supplier Quotations.dart';
import '../suppliers/add suppier.dart';
import '../suppliers/supplier_list.dart';
import '../suppliers/create_purchase_order.dart';
import '../store/create_store.dart';
import '../store/dynamic_selection.dart';
import 'profile.dart';
import 'settings_page.dart';
import 'package:billingapp/settings/pin_auth_gate.dart';
import 'package:billingapp/mainscreen/screens/profile_screen.dart';
import 'package:billingapp/mainscreen/screens/login_screen.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:billingapp/mainscreen/theme/theme_provider.dart';
import 'package:billingapp/Auth/api service.dart';

class DashboardController extends GetxController {
  var businessName = "".obs;
  var role = "business".obs;
  var loading = true.obs;
  var businessId = "".obs;
  var userMainId = "".obs;
  var businessEmail = "".obs;
  var businessPhone = "".obs;
  var localAvatarPath = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadBusiness();
  }

  Future<void> loadBusiness() async {
    final prefs = await SharedPreferences.getInstance();

    String fetchedRole = prefs.getString("business_type")?.toLowerCase() ?? 
                         prefs.getString("role")?.toLowerCase() ?? 
                         prefs.getString("user_role")?.toLowerCase() ??
                         "propagater";
    
    String bName = prefs.getString("business_name") ?? prefs.getString("user_name") ?? "";
    if (bName.isEmpty || bName == "Business") {
      bName = prefs.getString("user_name") ?? "";
    }
    
    String bId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? prefs.getString("user_id") ?? "";

    businessName.value = bName.isNotEmpty ? bName : "Billing Dashboard";
    businessId.value = bId;
    userMainId.value = prefs.getString("user_main_id") ?? prefs.getString("sec_cache_user_main_id") ?? prefs.getString("user_id") ?? "";
    businessEmail.value = prefs.getString("business_email") ?? prefs.getString("user_email") ?? "";
    businessPhone.value = prefs.getString("business_phone") ?? prefs.getString("user_phone") ?? "";
    localAvatarPath.value = prefs.getString("persistent_profile_photo_path") ?? "";
    role.value = fetchedRole;

    final cachedEmail = prefs.getString("cached_email");
    final cachedPassword = prefs.getString("cached_password");
    if (cachedEmail != null && cachedPassword != null) {
      try {
        final billingResponse = await ApiService.loginUser({
          "email": cachedEmail,
          "password": cachedPassword,
        });
        final billingToken = billingResponse["token"] ?? billingResponse["data"]?["token"];
        if (billingToken != null) {
          await prefs.setString("billing_auth_token", billingToken);
          print("Startup silent billing login renewed successfully.");
        }
      } catch (e) {
        print("Startup silent billing login failed: $e");
      }
    }

    loading.value = false;
  }

  void logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
      (route) => false,
    );
  }
}

class DashboardUI extends StatelessWidget {
  const DashboardUI({super.key});

  void _handleCardTap(BuildContext context, String title, String role) {
    if (title == "Business Setup") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessSetupMenuPage(role: role),
        ),
      );
    } else if (title == "Product") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductMenuPage(role: role),
        ),
      );
    } else if (title == "Supplier") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupplierMenuPage(role: role),
        ),
      );
    } else if (title == "Billing") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillingMenuPage(role: role),
        ),
      );
    } else if (title == "Reorder") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReorderMenuPage(role: role),
        ),
      );
    } else if (title == "Sales") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SalesMenuPage(role: role),
        ),
      );
    } else if (title == "Store") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreMenuPage(role: role),
        ),
      );
    } else if (title == "Seller Update") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerUpdateMenuPage(role: role),
        ),
      );
    }
  }

  Widget buildCard(BuildContext context, String title, IconData iconData, Color iconColor, String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _handleCardTap(context, title, role),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 32, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      drawer: Obx(() {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                    controller.loadBusiness();
                  },
                  child: UserAccountsDrawerHeader(
                    margin: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withRed(100),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white24,
                      backgroundImage: controller.localAvatarPath.value.isNotEmpty && File(controller.localAvatarPath.value).existsSync()
                          ? FileImage(File(controller.localAvatarPath.value)) as ImageProvider
                          : null,
                      child: controller.localAvatarPath.value.isEmpty
                          ? const Icon(Icons.person, size: 40, color: Colors.white)
                          : null,
                    ),
                    accountName: Text(
                      controller.businessName.value.isNotEmpty ? controller.businessName.value : "My Business",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    accountEmail: Text(
                      "User Type: ${controller.role.value.toUpperCase()}",
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text("Dashboard"),
                  onTap: () => Navigator.pop(context),
                ),
                ExpansionTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Settings"),
                  childrenPadding: const EdgeInsets.only(left: 16),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.tune),
                      title: const Text("General Settings"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.build_circle_outlined),
                      title: const Text("Manage"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PinAuthGatePage()));
                      },
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
                  onTap: () => controller.logout(context),
                )
              ],
            ),
          ),
        );
      }),
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final rText = controller.role.value.isNotEmpty 
                    ? controller.role.value[0].toUpperCase() + controller.role.value.substring(1) 
                    : "Admin";
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rText,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.search_outlined, size: 20),
                onPressed: () {},
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.notifications_none_outlined, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark 
                        ? Icons.light_mode_outlined 
                        : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    final themeProvider = provider_pkg.Provider.of<ThemeProvider>(context, listen: false);
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Obx(() {
                  final currentRole = controller.role.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${currentRole.isNotEmpty ? currentRole[0].toUpperCase() + currentRole.substring(1) : ''} Overview",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
                          children: [
                            buildCard(context, "Business Setup", Icons.domain, Colors.blue, currentRole),
                            buildCard(context, "Product", Icons.inventory_2_outlined, Colors.orange, currentRole),
                            buildCard(context, "Supplier", Icons.delivery_dining, Colors.orange, currentRole),
                            buildCard(context, "Reorder", Icons.sync_alt, Colors.deepPurple, currentRole),
                            buildCard(context, "Billing", Icons.receipt_long, Colors.green, currentRole),
                            buildCard(context, "Seller Update", Icons.update_outlined, Colors.pink, currentRole),
                          ],
                        ),
                      )
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BusinessSetupMenuPage extends StatelessWidget {
  final String role;
  const BusinessSetupMenuPage({super.key, required this.role});

  Widget buildItem(BuildContext context, String title, Widget page, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPropagator = role == "propagator" || role == "propagater" || role == "admin";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Business Setup"),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        children: [
          buildItem(context, "Setup Guide", const PlaceholderDetailPage(title: "Setup Guide"), Icons.help_outline, Colors.teal),
        ],
      ),
    );
  }
}

class ProductMenuPage extends StatelessWidget {
  final String role;
  const ProductMenuPage({super.key, required this.role});

  Widget buildItem(BuildContext context, String title, Widget page, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title, 
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Product Management"),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        children: [
          buildItem(context, "Add Product", const ProductEntryPage(), Icons.add_box_outlined, Colors.blue),
          buildItem(context, "Product List", const ProductAllocationPage(), Icons.format_list_bulleted, Colors.indigo),
          buildItem(context, "Stock Entry", StockEntryPage(), Icons.input_outlined, Colors.teal),
          buildItem(context, "Stock List", const StockListPage(), Icons.fact_check_outlined, Colors.green),
          buildItem(context, "Stock Status", const StockStatusPage(), Icons.analytics_outlined, Colors.cyan),
          buildItem(context, "Restock Requests", const RestockRequestsPage(), Icons.published_with_changes_outlined, Colors.deepOrange),
          buildItem(context, "Storage", const StoragePage(), Icons.warehouse_outlined, Colors.blueGrey),
          buildItem(context, "Storage Allocation", const StorageAllocationPage(), Icons.hub_outlined, Colors.indigo),
        ],
      ),
    );
  }
}

class SupplierMenuController extends GetxController {
  var token = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadToken();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token.value = prefs.getString("auth_token") ?? "";
  }
}

class SupplierMenuPage extends StatelessWidget {
  final String role;
  const SupplierMenuPage({super.key, required this.role});

  Widget buildItem(BuildContext context, String title, Widget page, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupplierMenuController());

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text("Supplier Management")),
      body: Obx(() {
        final currentToken = controller.token.value;
        return ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          children: [
            buildItem(context, "View Suppliers", const SupplierListPage(), Icons.people_alt_outlined, Colors.blue),
            buildItem(context, "Supplier Product & Category", SupplierProductsPage(token: currentToken), Icons.category_outlined, Colors.orange),
            buildItem(context, "Create Services", const PlaceholderDetailPage(title: "Create Services"), Icons.design_services_outlined, Colors.teal),
            buildItem(context, "List Services", const PlaceholderDetailPage(title: "List Services"), Icons.format_list_bulleted_outlined, Colors.indigo),
            buildItem(context, "Quotations", SupplierQuotationPage(token: currentToken), Icons.request_quote_outlined, Colors.purple),
          ],
        );
      }),
    );
  }
}

class ReorderMenuPage extends StatelessWidget {
  final String role;
  const ReorderMenuPage({super.key, required this.role});

  Widget buildItem(BuildContext context, String title, Widget page, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupplierMenuController());

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Reorder"),
      ),
      body: Obx(() {
        final currentToken = controller.token.value;
        return ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          children: [
            buildItem(context, "Reorders", CreatePurchaseOrderPage(token: currentToken), Icons.sync_alt, Colors.blue),
            buildItem(context, "Reorders list", SupplierOrdersPage(token: currentToken), Icons.format_list_bulleted, Colors.orange),
            buildItem(context, "Supplier bill", const PurchaseBillEntryPage(), Icons.receipt_long, Colors.purple),
          ],
        );
      }),
    );
  }
}

class BillingMenuPage extends StatelessWidget {
  final String role;
  const BillingMenuPage({super.key, required this.role});

  Widget buildItem(
      BuildContext context, String title, IconData icon, Widget page, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing:
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text("Billing")),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        children: [
          buildItem(context, "Generate Bill", Icons.receipt_long, CustomerScreen(), Colors.blue),
          buildItem(context, "Invoices", Icons.description_outlined, const BillListScreen(token: ''), Colors.green),
          buildItem(context, "Returns", Icons.assignment_return_outlined, const PlaceholderDetailPage(title: "Returns"), Colors.deepOrange),
        ],
      ),
    );
  }
}

class PlaceholderDetailPage extends StatelessWidget {
  final String title;
  const PlaceholderDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "$title Screen",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              "Feature coming soon",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreMenuPage extends StatelessWidget {
  final String role;
  const StoreMenuPage({super.key, required this.role});

  Widget buildItem(BuildContext context, String title, Widget page, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Store Management"),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        children: [
          buildItem(context, "Create Store", const RegisteredStorefrontsPage(), Icons.add_business, Colors.blue),
          buildItem(context, "Dynamic Selection", const DynamicSelectionPage(), Icons.dynamic_feed, Colors.orange),
        ],
      ),
    );
  }
}

class SellerUpdateMenuPage extends StatelessWidget {
  final String role;
  const SellerUpdateMenuPage({super.key, required this.role});

  Widget buildItem(BuildContext context, String title, Widget page, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Seller Update"),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        children: [
          buildItem(context, "Purchase Charge", const PurchaseBillEntryPage(), Icons.payment, Colors.blue),
          buildItem(context, "Purchase List", const PurchaseListPage(), Icons.list_alt, Colors.orange),
          buildItem(context, "Pricing & Offers", const PricingOffersPage(), Icons.local_offer, Colors.purple),
          buildItem(context, "Seller Update", const SellerUpdatePage(), Icons.update, Colors.green),
          buildItem(context, "Delivery Charges", const DeliveryChargesPage(), Icons.local_shipping, Colors.teal),
          buildItem(context, "Terms & Conditions", const PlaceholderDetailPage(title: "Terms & Conditions"), Icons.article_outlined, Colors.indigo),
          buildItem(context, "Warranty & Guarantee", const PlaceholderDetailPage(title: "Warranty & Guarantee"), Icons.verified_user_outlined, Colors.deepOrange),
        ],
      ),
    );
  }
}

class SalesMenuPage extends StatelessWidget {
  final String role;
  const SalesMenuPage({super.key, required this.role});

  Widget buildItem(BuildContext context, String title, Widget page, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Sales"),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        children: [
          buildItem(context, "Sales Point", const SalesPointPage(), Icons.shopping_cart_outlined, Colors.red),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> serverNotifications = [];
  List<dynamic> filteredNotifications = [];
  Map<String, dynamic> userPermissions = {};
  bool isLoading = true;
  String currentTab = "All";
  String searchQuery = "";

  final List<Map<String, dynamic>> fallbackAlerts = [
    {
      "id": 1,
      "title": "Low Stock Warning",
      "message": "Product 'Premium Wireless Earbuds' is below the safety threshold of 15 units. Current stock: 4.",
      "type": "Stock Alerts",
      "priority": "High",
      "timestamp": "10 mins ago",
      "isRead": false,
    },
    {
      "id": 2,
      "title": "Sales Invoice Generated",
      "message": "Invoice #INV-2026-0043 of amount \$349.99 was successfully generated and sent to customer.",
      "type": "Billing Updates",
      "priority": "Normal",
      "timestamp": "1 hr ago",
      "isRead": false,
    },
    {
      "id": 3,
      "title": "Purchase Order Pending Approval",
      "message": "Purchase bill #PO-8874 requires supervisor approval before release to supplier.",
      "type": "Billing Updates",
      "priority": "High",
      "timestamp": "3 hrs ago",
      "isRead": true,
    },
    {
      "id": 4,
      "title": "Database Backup Completed",
      "message": "Daily automated backup of sales databases has completed successfully. Size: 48 MB.",
      "type": "System",
      "priority": "Normal",
      "timestamp": "1 day ago",
      "isRead": true,
    },
    {
      "id": 5,
      "title": "New Supplier Quotation",
      "message": "Supplier 'Tech Gadgets Ltd' submitted a new quotation for component RF-21.",
      "type": "Stock Alerts",
      "priority": "Normal",
      "timestamp": "2 days ago",
      "isRead": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final notifResult = await ApiService.getNotifications();
      final permResult = await ApiService.getUserPermissions();

      if (notifResult != null && notifResult['success'] == true) {
        final data = notifResult['data'] ?? notifResult['notifications'] ?? [];
        if (data is List) {
          serverNotifications = data;
        } else {
          serverNotifications = [];
        }
      }

      if (permResult != null && permResult['success'] == true) {
        userPermissions = permResult['data'] ?? permResult['permissions'] ?? {};
      }
    } catch (e) {
      print("Failed loading notifications: $e");
    } finally {
      if (serverNotifications.isEmpty) {
        serverNotifications = List.from(fallbackAlerts);
      }
      filterAndSearch();
      setState(() => isLoading = false);
    }
  }

  void filterAndSearch() {
    List<dynamic> result = List.from(serverNotifications);

    // Apply Tab Filter
    if (currentTab == "Unread") {
      result = result.where((n) {
        final isRead = n['isRead'] ?? n['is_read'] ?? false;
        return isRead == false || isRead == 0 || isRead == '0';
      }).toList();
    } else if (currentTab == "High & Critical") {
      result = result.where((n) {
        final prio = (n['priority'] ?? '').toString().toLowerCase();
        return prio == 'high' || prio == 'critical' || prio == 'urgent';
      }).toList();
    } else if (currentTab == "Stock Alerts") {
      result = result.where((n) {
        final type = (n['type'] ?? '').toString().toLowerCase();
        return type.contains('stock') || type.contains('inventory');
      }).toList();
    } else if (currentTab == "Billing Updates") {
      result = result.where((n) {
        final type = (n['type'] ?? '').toString().toLowerCase();
        return type.contains('bill') || type.contains('invoice') || type.contains('payment');
      }).toList();
    }

    // Apply Search query
    if (searchQuery.isNotEmpty) {
      result = result.where((n) {
        final title = (n['title'] ?? '').toString().toLowerCase();
        final message = (n['message'] ?? '').toString().toLowerCase();
        return title.contains(searchQuery) || message.contains(searchQuery);
      }).toList();
    }

    setState(() {
      filteredNotifications = result;
    });
  }

  void clearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Notifications?"),
        content: const Text("Are you sure you want to dismiss all current alerts?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.clearAllNotifications();
              } catch (e) {
                print("Failed calling clear-all API: $e");
              }
              setState(() {
                serverNotifications.clear();
                filteredNotifications.clear();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Clear All", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget buildTabChip(String label, String countStr) {
    final isActive = currentTab == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentTab = label;
        });
        filterAndSearch();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF2563EB).withOpacity(0.1) 
              : (isDark ? Colors.white10 : Colors.grey.shade100),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "$label$countStr",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive 
                ? const Color(0xFF2563EB) 
                : (isDark ? Colors.white70 : Colors.grey.shade700),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = serverNotifications.where((n) {
      final isRead = n['isRead'] ?? n['is_read'] ?? false;
      return isRead == false || isRead == 0 || isRead == '0';
    }).length;

    final highCount = serverNotifications.where((n) {
      final prio = (n['priority'] ?? '').toString().toLowerCase();
      return prio == 'high' || prio == 'critical' || prio == 'urgent';
    }).length;

    final stockCount = serverNotifications.where((n) {
      final type = (n['type'] ?? '').toString().toLowerCase();
      return type.contains('stock') || type.contains('inventory');
    }).length;

    final billingCount = serverNotifications.where((n) {
      final type = (n['type'] ?? '').toString().toLowerCase();
      return type.contains('bill') || type.contains('invoice') || type.contains('payment');
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Notification Screen Header Panel
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined, 
                        color: Color(0xFF2563EB), 
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Notifications",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "System alerts for Sales, Purchase bills, and Stock warnings (${serverNotifications.length} Total)",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons Row (Refresh & Clear All)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: loadData,
                      icon: const Icon(Icons.sync, size: 16, color: Colors.blueAccent),
                      label: const Text("Refresh", style: TextStyle(color: Colors.blueAccent)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: clearAll,
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      label: const Text("Clear All", style: TextStyle(color: Colors.redAccent)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: "Search by title, message, stock status...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                  ),
                  onChanged: (val) {
                    searchQuery = val.toLowerCase();
                    filterAndSearch();
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Horizontal scrollable Tabs
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    buildTabChip("All", " (${serverNotifications.length})"),
                    buildTabChip("Unread", " ($unreadCount)"),
                    buildTabChip("High & Critical", " ($highCount)"),
                    buildTabChip("Stock Alerts", " ($stockCount)"),
                    buildTabChip("Billing Updates", " ($billingCount)"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Show User Permissions list as a subtle indicator
              if (userPermissions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security, size: 14, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Permissions synced successfully.",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Notifications List View
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  "No notifications found",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final item = filteredNotifications[index];
                              final isRead = item['isRead'] ?? item['is_read'] ?? false;
                              final type = (item['type'] ?? 'Alert').toString();
                              final priority = (item['priority'] ?? 'Normal').toString();
                              final isHigh = priority.toLowerCase() == 'high';

                              IconData leadIcon = Icons.info_outline;
                              Color iconColor = Colors.blue;
                              if (type.toLowerCase().contains('stock')) {
                                leadIcon = Icons.warning_amber_rounded;
                                iconColor = Colors.orange;
                              } else if (type.toLowerCase().contains('billing')) {
                                leadIcon = Icons.receipt_long_outlined;
                                iconColor = Colors.green;
                              }

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (item is Map) {
                                      item['isRead'] = true;
                                      item['is_read'] = true;
                                    }
                                  });
                                  filterAndSearch();
                                },
                                child: Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isDark 
                                          ? Colors.white10 
                                          : (isRead ? Colors.grey.shade100 : Colors.blue.shade100),
                                      width: 1.5,
                                    ),
                                  ),
                                  color: isDark 
                                      ? (isRead ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.06))
                                      : (isRead ? Colors.white : const Color(0xFFEFF6FF)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: iconColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(leadIcon, color: iconColor, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['title'] ?? 'System Alert',
                                                      style: TextStyle(
                                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                        fontSize: 15,
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                  ),
                                                  if (isHigh)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        "HIGH",
                                                        style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                item['message'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                                  height: 1.3,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                item['timestamp'] ?? item['created_at'] ?? 'Just now',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
