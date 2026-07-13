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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/product/stock entry.dart';

import '../billing/Generate Bill.dart';
import '../billing/invoices.dart';
import '../bussinjessscreate/select.dart';
import '../bussinjessscreate/categoryselect.dart';
import '../chartfile/getenq.dart';
import '../suppliers/Deliveries.dart';
import '../suppliers/Supplier Orders.dart';
import '../suppliers/Supplier Payments.dart';
import '../suppliers/Supplier Products.dart';
import '../suppliers/Supplier Quotations.dart';
import '../suppliers/add suppier.dart';
import '../suppliers/supplier_list.dart';
import '../store/create_store.dart';
import '../store/dynamic_selection.dart';
import 'profile.dart';
import 'settings_page.dart';
import 'package:billingapp/settings/pin_auth_gate.dart';

class DashboardController extends GetxController {
  var businessName = "".obs;
  var role = "business".obs;
  var loading = true.obs;
  var businessId = "".obs;
  var userMainId = "".obs;
  var businessEmail = "".obs;
  var businessPhone = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadBusiness();
  }

  Future<void> loadBusiness() async {
    final prefs = await SharedPreferences.getInstance();

    String fetchedRole = prefs.getString("business_type")?.toLowerCase() ?? 
                         prefs.getString("role")?.toLowerCase() ?? 
                         "propagater";
    
    businessName.value = prefs.getString("business_name") ?? "";
    businessId.value = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
    userMainId.value = prefs.getString("user_main_id") ?? "";
    businessEmail.value = prefs.getString("business_email") ?? "";
    businessPhone.value = prefs.getString("business_phone") ?? "";
    role.value = fetchedRole;
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
    } else if (title == "Enquiry") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GetEnquiry(role: role, userId: 1),
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
    return GestureDetector(
      onTap: () => _handleCardTap(context, title, role),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 36, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
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
        return Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.account_circle, size: 50, color: Colors.blue),
                ),
                accountName: Text(
                  controller.businessName.value.isNotEmpty ? controller.businessName.value : "Loading...",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text("${controller.role.value.toUpperCase()} | ID: ${controller.businessId.value}"),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text("Dashboard"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Profile"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage()));
                },
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
              if (controller.role.value == "supplier" || controller.role.value == "partner") ...[
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text("Management"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.question_answer_outlined),
                  title: const Text("Enquiry"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GetEnquiry(role: controller.role.value, userId: 1)));
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
                onTap: () => controller.logout(context),
              )
            ],
          ),
        );
      }),
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Obx(() {
                return controller.loading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.storefront, size: 16, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              controller.businessName.value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
              }),
            ),
          )
        ],
      ),
      body: SafeArea(
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
                      if (currentRole == "supplier" || currentRole == "partner" || currentRole == "propagator" || currentRole == "propagater" || currentRole == "admin" || currentRole == "business")
                        buildCard(context, "Business Setup", Icons.domain, Colors.blue, currentRole),
                      
                      if (currentRole == "supplier" || currentRole == "partner" || currentRole == "propagator" || currentRole == "propagater" || currentRole == "admin")
                        buildCard(context, "Product", Icons.inventory_2_outlined, Colors.orange, currentRole),
                      
                      if (currentRole == "supplier" || currentRole == "partner" || currentRole == "propagator" || currentRole == "propagater" || currentRole == "admin")
                        buildCard(context, "Supplier", Icons.delivery_dining, Colors.orange, currentRole),
                      
                      if (currentRole == "supplier" || currentRole == "partner" || currentRole == "propagator" || currentRole == "propagater" || currentRole == "admin")
                        buildCard(context, "Billing", Icons.receipt_long, Colors.green, currentRole),
                      
                      if (currentRole == "supplier" || currentRole == "partner") ...[
                        buildCard(context, "Management", Icons.settings_outlined, Colors.purple, currentRole),
                        buildCard(context, "Enquiry", Icons.chat_outlined, Colors.teal, currentRole),
                      ],

                      buildCard(context, "Store", Icons.storefront, Colors.indigo, currentRole),
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
          buildItem(context, "Company Profile", const BusinessSelectionPage(), Icons.business, Colors.blue),
          if (!isPropagator) ...[
            buildItem(context, "Unit Master", const Scaffold(body: Center(child: Text("Unit Master"))), Icons.straighten, Colors.orange),
            buildItem(context, "Category Group", CategoryGroupPage(), Icons.category, Colors.purple),
            buildItem(context, "Brand Master", const Scaffold(body: Center(child: Text("Brand Master"))), Icons.branding_watermark, Colors.green),
            buildItem(context, "Category Master", const Scaffold(body: Center(child: Text("Category Master"))), Icons.grid_view, Colors.teal),
          ],
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
          buildItem(context, "Storage", const StoragePage(), Icons.inventory_2_outlined, Colors.blue),
          buildItem(context, "Add Product", const ProductEntryPage(), Icons.add_box_outlined, Colors.orange),
          buildItem(context, "Product List", const ProductAllocationPage(), Icons.list_alt, Colors.purple),
          buildItem(context, "Stock Entry", StockEntryPage(), Icons.input_outlined, Colors.green),
          buildItem(context, "Stock List", const StockListPage(), Icons.fact_check_outlined, Colors.teal),
          
          buildItem(context, "Storage Allocation", const StorageAllocationPage(), Icons.hub_outlined, Colors.indigo),
          buildItem(context, "Variant Master", const VariantMasterPage(), Icons.style_outlined, Colors.pink),
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

  Widget buildItem(BuildContext context, String title, Widget page) {
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
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.business_center, color: Colors.orange),
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
    bool isPropagator = role == "propagator" || role == "propagater" || role == "admin";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text("Supplier Management")),
      body: Obx(() {
        final currentToken = controller.token.value;
        return ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          children: [
            if (!isPropagator) ...[
              buildItem(context, "Add Supplier", AddSupplierScreen()), 
              buildItem(context, "View Suppliers", const SupplierListPage()),
            ],
            buildItem(context, "Supplier Products", SupplierProductsPage(token: currentToken)),
            buildItem(context, "Quotations", SupplierQuotationPage(token: currentToken)),
            buildItem(context, "Supplier Orders", SupplierOrdersPage(token: currentToken)),
            buildItem(context, "Supplier Payments", const SupplierPaymentsPage()),
            buildItem(context, "Deliveries", const DeliveriesPage()),
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
      BuildContext context, String title, IconData icon, Widget page) {
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
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.deepPurple),
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
      appBar: AppBar(title: const Text("Billing")),
      body: ListView(
        children: [
          buildItem(context, "Generate Bill", Icons.receipt_long, CustomerScreen()),
          buildItem(context, "Invoices", Icons.description, const BillListScreen(token: '',)),

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
          buildItem(context, "Purchase Charge", const PurchaseChargesPage(), Icons.payment, Colors.blue),
          buildItem(context, "Purchase List", const PurchaseChargesListPage(), Icons.list_alt, Colors.orange),
          buildItem(context, "Pricing and Offers", const PricingOffersPage(), Icons.local_offer, Colors.purple),
          buildItem(context, "Seller Update", const SellerUpdatePage(), Icons.update, Colors.green),
          buildItem(context, "Delivery Charges", const DeliveryChargesPage(), Icons.local_shipping, Colors.teal),
        ],
      ),
    );
  }
}
