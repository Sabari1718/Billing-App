import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_store.dart';

class DynamicSelectionPage extends StatefulWidget {
  const DynamicSelectionPage({Key? key}) : super(key: key);

  @override
  State<DynamicSelectionPage> createState() => _DynamicSelectionPageState();
}

class _DynamicSelectionPageState extends State<DynamicSelectionPage> {
  bool _isLoadingStore = true;
  Map<String, dynamic>? _selectedStore;

  @override
  void initState() {
    super.initState();
    _fetchDefaultStore();
  }

  Future<void> _fetchDefaultStore() async {
    setState(() {
      _isLoadingStore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores?page=1"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: GET https://billing.srivagroups.in/api/stores?page=1 status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = (decoded is Map && decoded.containsKey('data'))
            ? (decoded['data'] is List ? decoded['data'] : [])
            : (decoded is List ? decoded : []);

        if (data.isNotEmpty) {
          setState(() {
            _selectedStore = Map<String, dynamic>.from(data.first);
            _isLoadingStore = false;
          });
          return;
        }
      }

      // Fallback
      setState(() {
        _selectedStore = {
          "id": 6,
          "store_name": "AA",
          "branch_type": "single",
          "third_party_coupon_accept": 1
        };
        _isLoadingStore = false;
      });
    } catch (e) {
      print("debug: Fetch default store error: $e");
      setState(() {
        _selectedStore = {
          "id": 6,
          "store_name": "AA",
          "branch_type": "single",
          "third_party_coupon_accept": 1
        };
        _isLoadingStore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate 50
      appBar: AppBar(
        title: const Text(
          "Dynamic Configuration",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      body: _isLoadingStore
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            )
          : DynamicSelectionWidget(
              onConfigureCategories: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoreCategoriesPage()),
                );
              },
              onConfigurePayments: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StorePaymentGatewaysPage()),
                );
              },
            ),
    );
  }
}

class DynamicSelectionWidget extends StatelessWidget {
  final VoidCallback onConfigureCategories;
  final VoidCallback onConfigurePayments;

  const DynamicSelectionWidget({
    Key? key,
    required this.onConfigureCategories,
    required this.onConfigurePayments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pill Badge "Interactive Control Panel"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // soft blue
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Interactive Control Panel",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Title
            const Text(
              "Dynamic Selection Showcase",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B), // slate 800
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle Description
            Text(
              "Select a dynamic configuration module below to setup and manage your store front settings. Each section manages hierarchical values stored in the central database tables.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Card 1: Store Hierarchical Categories
            _buildShowcaseCard(
              context: context,
              badgeNumber: "01",
              iconData: Icons.layers_rounded,
              iconColor: const Color(0xFF3B82F6), // blue
              iconBgColor: const Color(0xFFEFF6FF),
              title: "Store Hierarchical Categories",
              description:
                  "Define your products category tree (Electronics, Apparel) and link child subcategories (Mobile Phones, T-shirts) directly in the database.",
              onTap: onConfigureCategories,
            ),
            const SizedBox(height: 20),

            // Card 2: Payment Gateways & Methods
            _buildShowcaseCard(
              context: context,
              badgeNumber: "02",
              iconData: Icons.payment_rounded,
              iconColor: const Color(0xFF8B5CF6), // violet
              iconBgColor: const Color(0xFFF5F3FF),
              title: "Payment Gateways & Methods",
              description:
                  "Establish checkout channels and nested structures (Cards > Debit Card / Credit Card) mapped to store profiles.",
              onTap: onConfigurePayments,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcaseCard({
    required BuildContext context,
    required String badgeNumber,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: iconColor.withOpacity(0.05),
            highlightColor: iconColor.withOpacity(0.02),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Number Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeNumber,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                      // Icon Badge
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Card Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Divider(color: Colors.grey.shade100, height: 1),
                  const SizedBox(height: 12),

                  // Configure Section Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Configure Section",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: iconColor,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StoreCategoriesPage extends StatefulWidget {
  const StoreCategoriesPage({Key? key}) : super(key: key);

  @override
  State<StoreCategoriesPage> createState() => _StoreCategoriesPageState();
}

class _StoreCategoriesPageState extends State<StoreCategoriesPage> {
  bool _isLoading = true;
  List<dynamic> _categories = [];

  // Controllers
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryDescController = TextEditingController();
  final TextEditingController _subNameController = TextEditingController();

  dynamic _selectedParentCategory;
  bool _isCreatingCategory = false;
  bool _isLinkingSub = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _categoryDescController.dispose();
    _subNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores/categories"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: GET https://billing.srivagroups.in/api/stores/categories status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          if (decoded is Map && decoded.containsKey('data')) {
            _categories = decoded['data'] is List ? decoded['data'] : [];
          } else if (decoded is List) {
            _categories = decoded;
          } else {
            _categories = [];
          }
          
          // Reset selected category if not in current categories list
          if (_selectedParentCategory != null) {
            final exists = _categories.any((c) => c['id'] == _selectedParentCategory['id']);
            if (!exists) {
              _selectedParentCategory = null;
            } else {
              // Refresh selected category reference
              _selectedParentCategory = _categories.firstWhere((c) => c['id'] == _selectedParentCategory['id']);
            }
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _categories = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("debug: GET categories error: $e");
      setState(() {
        _categories = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _createCategory() async {
    final name = _categoryNameController.text.trim();
    final desc = _categoryDescController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category name cannot be empty")),
      );
      return;
    }

    setState(() {
      _isCreatingCategory = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.post(
        Uri.parse("https://billing.srivagroups.in/api/stores/categories"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "category_name": name,
          "description": desc,
          "status": 1,
        }),
      );

      print("debug: POST https://billing.srivagroups.in/api/stores/categories status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _categoryNameController.clear();
        _categoryDescController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category created successfully")),
        );
        _fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create category: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("debug: POST category error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isCreatingCategory = false;
      });
    }
  }

  Future<void> _linkSubcategory() async {
    final subName = _subNameController.text.trim();

    if (_selectedParentCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a parent category")),
      );
      return;
    }

    if (subName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subcategory name cannot be empty")),
      );
      return;
    }

    setState(() {
      _isLinkingSub = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.post(
        Uri.parse("https://billing.srivagroups.in/api/stores/categories"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "category_id": _selectedParentCategory['id'],
          "subcategory_name": subName,
          "status": 1,
        }),
      );

      print("debug: POST https://billing.srivagroups.in/api/stores/categories (Subcategory) status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _subNameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subcategory linked successfully")),
        );
        _fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to link subcategory: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("debug: POST subcategory error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLinkingSub = false;
      });
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Are you sure you want to delete '$name'? This will delete all its linked subcategories."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.delete(
        Uri.parse("https://billing.srivagroups.in/api/stores/categories/$id"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: DELETE https://billing.srivagroups.in/api/stores/categories/$id status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category deleted")),
        );
        _fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("debug: DELETE category error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _deleteSubcategory(int subId, String subName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Subcategory"),
        content: Text("Are you sure you want to delete subcategory '$subName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.delete(
        Uri.parse("https://billing.srivagroups.in/api/stores/categories/subcategories/$subId"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: DELETE https://billing.srivagroups.in/api/stores/categories/subcategories/$subId status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subcategory deleted")),
        );
        _fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete subcategory: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("debug: DELETE subcategory error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate 50
      appBar: AppBar(
        title: const Text(
          "Store Categories Tree",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: _fetchCategories,
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Database Connected row
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Database Connected",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Main Title
            const Text(
              "Store Categories Tree",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              "Create and manage top-level categories and associate subcategories in the central database.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: Add Master Category
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFF2563EB), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Add Master Category",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "NEW TOP-LEVEL CATEGORY",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _categoryNameController,
                    decoration: InputDecoration(
                      hintText: "Category Name (e.g. Electronics)",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _categoryDescController,
                    decoration: InputDecoration(
                      hintText: "Short description...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isCreatingCategory ? null : _createCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isCreatingCategory
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              "+ Create Category",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: New Linked Subcategory
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link, color: Color(0xFF7C3AED), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "New Linked Subcategory",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "NEW LINKED SUBCATEGORY",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category Dropdown Selection
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<dynamic>(
                        value: _selectedParentCategory,
                        hint: Text(
                          "Select Parent Category...",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedParentCategory = newValue;
                          });
                        },
                        items: _categories.map<DropdownMenuItem<dynamic>>((dynamic category) {
                          final name = category['category_name'] ?? category['name'] ?? "Unknown";
                          return DropdownMenuItem<dynamic>(
                            value: category,
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subcategory name and Link Sub button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subNameController,
                          decoration: InputDecoration(
                            hintText: "Subcategory Name (e.g. Laptops)",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _isLinkingSub ? null : _linkSubcategory,
                          icon: _isLinkingSub
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.folder_shared_rounded, size: 16),
                          label: const Text(
                            "Link Sub",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card 3: Categories Hierarchy
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.layers_rounded, color: Color(0xFF9333EA), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Categories Hierarchy",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_isLoading && _categories.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                      ),
                    )
                  else if (_categories.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            const Text(
                              "No categories in hierarchy.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final catId = cat['id'] ?? 0;
                        final catName = cat['category_name'] ?? cat['name'] ?? "Unknown";
                        final description = cat['description'] ?? "";
                        final subcats = cat['subcategories'] is List ? cat['subcategories'] as List : [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Header Row
                              Row(
                                children: [
                                  const Icon(Icons.folder_rounded, color: Colors.amber, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          catName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        if (description.isNotEmpty)
                                          Text(
                                            description,
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
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteCategory(catId, catName),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),

                              // Subcategories list
                              if (subcats.isEmpty)
                                Container(
                                  margin: const EdgeInsets.only(left: 12, top: 8),
                                  padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                                  decoration: const BoxDecoration(
                                    border: Border(left: BorderSide(color: Color(0xFFCBD5E1), width: 2)),
                                  ),
                                  child: Text(
                                    "No linked subcategories.",
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  margin: const EdgeInsets.only(left: 12, top: 8),
                                  padding: const EdgeInsets.only(left: 12),
                                  decoration: const BoxDecoration(
                                    border: Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
                                  ),
                                  child: Column(
                                    children: subcats.map<Widget>((sub) {
                                      final subId = sub['id'] ?? 0;
                                      final subName = sub['subcategory_name'] ?? sub['name'] ?? "Unknown";

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.local_offer_outlined, color: Colors.orangeAccent, size: 14),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                subName,
                                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                              onPressed: () => _deleteSubcategory(subId, subName),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
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

class StorePaymentGatewaysPage extends StatefulWidget {
  const StorePaymentGatewaysPage({Key? key}) : super(key: key);

  @override
  State<StorePaymentGatewaysPage> createState() => _StorePaymentGatewaysPageState();
}

class _StorePaymentGatewaysPageState extends State<StorePaymentGatewaysPage> {
  bool _isLoading = true;
  List<dynamic> _paymentMethods = [];
  List<String> _languages = ["English", "Hindi (हिन्दी)", "Spanish (Español)", "French (Français)"];

  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _langController = TextEditingController();

  dynamic _selectedParentChannel; // holds the map of the selected parent channel or null
  bool _isAddingChannel = false;

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
  }

  @override
  void dispose() {
    _channelNameController.dispose();
    _langController.dispose();
    super.dispose();
  }

  Future<void> _fetchPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/stores/payment-methods"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("debug: GET https://billing.srivagroups.in/api/stores/payment-methods status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          if (decoded is Map && decoded.containsKey('data')) {
            _paymentMethods = decoded['data'] is List ? decoded['data'] : [];
          } else if (decoded is List) {
            _paymentMethods = decoded;
          } else {
            _paymentMethods = [];
          }
          
          // Reset selection
          _selectedParentChannel = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _paymentMethods = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("debug: GET payment-methods error: $e");
      setState(() {
        _paymentMethods = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _addPaymentChannel() async {
    final name = _channelNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Channel name cannot be empty")),
      );
      return;
    }

    setState(() {
      _isAddingChannel = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final parentId = _selectedParentChannel != null ? _selectedParentChannel['id'] : null;

      final response = await http.post(
        Uri.parse("https://billing.srivagroups.in/api/stores/payment-methods"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "method_name": name,
          "parent_id": parentId,
          "status": 1,
        }),
      );

      print("debug: POST https://billing.srivagroups.in/api/stores/payment-methods status: ${response.statusCode} body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _channelNameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment channel added successfully")),
        );
        _fetchPaymentMethods();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add channel: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("debug: POST payment-method error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isAddingChannel = false;
      });
    }
  }

  void _addLanguage() {
    final lang = _langController.text.trim();
    if (lang.isEmpty) return;

    setState(() {
      if (!_languages.contains(lang)) {
        _languages.add(lang);
      }
      _langController.clear();
    });
    
    print("debug: Added language locally: $lang");
  }

  void _removeLanguage(String lang) {
    setState(() {
      _languages.remove(lang);
    });
    print("debug: Removed language locally: $lang");
  }

  @override
  Widget build(BuildContext context) {
    // Dropdown list items containing "Top-Level Channel (No Parent)" as null
    final dropdownItems = <DropdownMenuItem<dynamic>>[
      const DropdownMenuItem<dynamic>(
        value: null,
        child: Text(
          "Top-Level Channel (No Parent)",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ),
    ];

    for (final method in _paymentMethods) {
      final name = method['method_name'] ?? method['name'] ?? "Unknown";
      dropdownItems.add(
        DropdownMenuItem<dynamic>(
          value: method,
          child: Text(
            name,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate 50
      appBar: AppBar(
        title: const Text(
          "Store Payment Gateways",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: _fetchPaymentMethods,
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Database Connected row
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Database Connected",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Main Title
            const Text(
              "Store Payment Gateways",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              "Setup nested payment modules (e.g. Cards > Debit/Credit Card) available to storefront checkouts.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: Add Payment Channel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_card_rounded, color: Color(0xFF9333EA), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Add Payment Channel",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "CUSTOM PAYMENT DETAILS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dropdown Parent Channel Selector
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<dynamic>(
                        value: _selectedParentChannel,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedParentChannel = newValue;
                          });
                        },
                        items: dropdownItems,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Method name and Link Channel row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _channelNameController,
                          decoration: InputDecoration(
                            hintText: "Method Name (e.g. PayPal)",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isAddingChannel ? null : _addPaymentChannel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isAddingChannel
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  "+ Add Channel",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Note: Creating a payment channel registers it globally in the database.",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Custom Languages Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.language_rounded, color: Color(0xFF2563EB), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Custom Languages Preview",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Add language row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _langController,
                          decoration: InputDecoration(
                            hintText: "Add language (e.g. Italian)",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _addLanguage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Add",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chips display
                  if (_languages.isEmpty)
                    const Text(
                      "No languages added yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _languages.map((lang) {
                        return InputChip(
                          label: Text(
                            lang,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide(color: Colors.grey.shade200),
                          onDeleted: () => _removeLanguage(lang),
                          deleteIcon: const Icon(Icons.close, size: 14, color: Colors.grey),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card 3: Payment Channels Tree
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.payment_rounded, color: Color(0xFF7C3AED), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Payment Channels Tree",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_isLoading && _paymentMethods.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                      ),
                    )
                  else if (_paymentMethods.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(Icons.credit_card_off_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            const Text(
                              "No payment channels configured.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = _paymentMethods[index];
                        final name = method['method_name'] ?? method['name'] ?? "Unknown";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.credit_card_rounded, color: Color(0xFF3B82F6), size: 18),
                              const SizedBox(width: 12),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
