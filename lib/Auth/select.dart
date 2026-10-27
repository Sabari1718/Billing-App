import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'api service.dart';
import 'billing dashboardc.dart';

/// ============================================================================
/// 1️⃣ CHOOSE YOUR BUSINESS PAGE
/// ============================================================================
class BusinessSelectionPage extends StatefulWidget {
  const BusinessSelectionPage({super.key});

  @override
  State<BusinessSelectionPage> createState() => _BusinessSelectionPageState();
}

class _BusinessSelectionPageState extends State<BusinessSelectionPage> {
  List<dynamic> _businessList = [];
  String _selectedId = '';
  Map<String, dynamic>? _selectedBusiness;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBusinesses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getBusinesses();
      AppLogger.info("Businesses fetched from /businesses/my-businesses");

      List<dynamic> list = [];
      if (res['data'] is List) {
        list = res['data'];
      } else if (res['businesses'] is List) {
        list = res['businesses'];
      } else if (res is List) {
        list = res as List<dynamic>;
      }

      setState(() {
        _businessList = list;
        _isLoading = false;

        // Auto select first business if available
        if (_businessList.isNotEmpty && _selectedId.isEmpty) {
          final first = _businessList.first;
          _selectedId = (first['business_id'] ?? first['id'] ?? '').toString();
          _selectedBusiness = Map<String, dynamic>.from(first);
        }
      });
    } catch (e) {
      AppLogger.error("Failed to load businesses", e);
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Failed to load businesses. Please try again.", isError: true);
      }
    }
  }

  Future<void> _handleContinue() async {
    if (_selectedId.isEmpty || _selectedBusiness == null) {
      _showSnackBar("Please select a business to continue", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Post to select-business
      await ApiService.selectBusiness({
        "business_id": _selectedId,
      });
      AppLogger.success("Business selected API success: $_selectedId");

      final prefs = await SharedPreferences.getInstance();
      final businessName = _selectedBusiness!['business_name'] ?? _selectedBusiness!['name'] ?? 'Business';
      final businessType = _selectedBusiness!['business_type'] ?? _selectedBusiness!['type'] ?? 'Retail';
      final status = _selectedBusiness!['status'] ?? 'Active';

      await prefs.setString("selected_business_id", _selectedId);
      await prefs.setString("business_id", _selectedId);
      await prefs.setString("business_name", businessName.toString());
      await prefs.setString("business_type", businessType.toString());
      await prefs.setString("business_status", status.toString());

      // Pre-fetch permissions & notifications in background
      ApiService.getUserPermissions().ignore();
      ApiService.getNotifications().ignore();

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Navigate to Step 2: Select Your Platform
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlatformSelectionPage(
            businessId: _selectedId,
            businessName: businessName.toString(),
            businessType: businessType.toString(),
          ),
        ),
      );
    } catch (e) {
      AppLogger.error("Select business failed", e);
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar("Error selecting business: $e", isError: true);
      }
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<dynamic> get _filteredBusinesses {
    if (_searchQuery.trim().isEmpty) return _businessList;
    final query = _searchQuery.trim().toLowerCase();
    return _businessList.where((b) {
      final name = (b['business_name'] ?? b['name'] ?? '').toString().toLowerCase();
      final type = (b['business_type'] ?? b['type'] ?? '').toString().toLowerCase();
      return name.contains(query) || type.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      body: Stack(
        children: [
          const _FloatingBackgroundDecorations(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Badge
                        const _HeaderIconBadge(
                          icon: Icons.apartment_rounded,
                          color: Color(0xFF3B82F6),
                          bgColor: Color(0xFFEFF6FF),
                        ),
                        const SizedBox(height: 16),

                        // Title & Subtitle
                        const Text(
                          "Choose Your Business",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Choose the business you want to work with today",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Search Bar
                        _SearchInput(
                          controller: _searchController,
                          hintText: "Search business by name...",
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 20),

                        // Business List / Grid
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 2.5),
                                SizedBox(height: 12),
                                Text(
                                  "Loading your businesses...",
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        else if (_filteredBusinesses.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Column(
                              children: [
                                Icon(Icons.business_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  "No businesses found",
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? "Try a different search term"
                                      : "No registered businesses available for this account",
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _fetchBusinesses,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text("Refresh"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF3B82F6),
                                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isTwoColumn = constraints.maxWidth > 380;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isTwoColumn ? 2 : 1,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  mainAxisExtent: isTwoColumn ? 152 : 124,
                                ),
                                itemCount: _filteredBusinesses.length,
                                itemBuilder: (context, index) {
                                  final biz = _filteredBusinesses[index];
                                  final id = (biz['business_id'] ?? biz['id'] ?? '').toString();
                                  final name = (biz['business_name'] ?? biz['name'] ?? 'Unnamed').toString();
                                  final type = (biz['business_type'] ?? biz['type'] ?? 'Retail').toString();
                                  final status = (biz['status'] ?? 'Active').toString();
                                  final isSelected = _selectedId == id;

                                  return _BusinessCard(
                                    name: name,
                                    type: type,
                                    status: status,
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedId = id;
                                        _selectedBusiness = Map<String, dynamic>.from(biz);
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 24),

                        // Continue Button
                        _GradientButton(
                          title: "Continue to Platform Selection",
                          icon: Icons.arrow_forward_rounded,
                          isLoading: _isSubmitting,
                          onPressed: (_selectedId.isEmpty || _isSubmitting) ? null : _handleContinue,
                        ),

                        const SizedBox(height: 18),
                        const _FooterNotice(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 2️⃣ SELECT YOUR PLATFORM PAGE
/// ============================================================================
class PlatformSelectionPage extends StatefulWidget {
  final String businessId;
  final String businessName;
  final String businessType;

  const PlatformSelectionPage({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.businessType,
  });

  @override
  State<PlatformSelectionPage> createState() => _PlatformSelectionPageState();
}

class _PlatformSelectionPageState extends State<PlatformSelectionPage> {
  List<dynamic> _platformList = [];
  String _selectedPlatformId = '';
  String _selectedPlatformName = '';
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlatforms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlatforms() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getPlatforms(businessId: widget.businessId);
      AppLogger.info("Platforms fetched: $res");

      List<dynamic> list = [];
      if (res['data'] is List) {
        list = res['data'];
      }

      // Default fallback if server returned empty list
      if (list.isEmpty) {
        list = [
          {"platform_id": "1", "platform_name": "Shop"}
        ];
      }

      setState(() {
        _platformList = list;
        _isLoading = false;

        if (_platformList.isNotEmpty && _selectedPlatformId.isEmpty) {
          final first = _platformList.first;
          _selectedPlatformId = (first['platform_id'] ?? '1').toString();
          _selectedPlatformName = (first['platform_name'] ?? 'Shop').toString();
        }
      });
    } catch (e) {
      AppLogger.error("Failed to fetch platforms", e);
      if (mounted) {
        setState(() {
          _platformList = [
            {"platform_id": "1", "platform_name": "Shop"}
          ];
          _selectedPlatformId = "1";
          _selectedPlatformName = "Shop";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _proceedToStore({bool skip = false}) async {
    final prefs = await SharedPreferences.getInstance();

    final finalPlatformId = skip || _selectedPlatformId.isEmpty ? "1" : _selectedPlatformId;
    final finalPlatformName = skip || _selectedPlatformName.isEmpty ? "Shop" : _selectedPlatformName;

    await prefs.setString("selected_platform_id", finalPlatformId);
    await prefs.setString("platform_id", finalPlatformId);
    await prefs.setString("platform_name", finalPlatformName);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreSelectionPage(
          businessId: widget.businessId,
          businessName: widget.businessName,
          platformId: finalPlatformId,
          platformName: finalPlatformName,
        ),
      ),
    );
  }

  List<dynamic> get _filteredPlatforms {
    if (_searchQuery.trim().isEmpty) return _platformList;
    final query = _searchQuery.trim().toLowerCase();
    return _platformList.where((p) {
      final name = (p['platform_name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      body: Stack(
        children: [
          const _FloatingBackgroundDecorations(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Navigation Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                              label: const Text(
                                "Back to Business",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _proceedToStore(skip: true),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Skip Platform",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.keyboard_double_arrow_right_rounded, size: 16, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Center Icon
                        const _HeaderIconBadge(
                          icon: Icons.devices_rounded,
                          color: Color(0xFF2563EB),
                          bgColor: Color(0xFFEFF6FF),
                        ),
                        const SizedBox(height: 16),

                        // Title & Subtitle
                        const Text(
                          "Select Your Platform",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Choose the platform you want to access for this business",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Search Bar
                        _SearchInput(
                          controller: _searchController,
                          hintText: "Search platform by name...",
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 20),

                        // Platform List
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 2.5),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isTwoColumn = constraints.maxWidth > 380;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isTwoColumn ? 2 : 1,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  mainAxisExtent: isTwoColumn ? 152 : 124,
                                ),
                                itemCount: _filteredPlatforms.length,
                                itemBuilder: (context, index) {
                                  final platform = _filteredPlatforms[index];
                                  final id = (platform['platform_id'] ?? '').toString();
                                  final name = (platform['platform_name'] ?? 'Shop').toString();
                                  final isSelected = _selectedPlatformId == id;

                                  return _PlatformCard(
                                    name: name,
                                    subtitle: "$name Module",
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedPlatformId = id;
                                        _selectedPlatformName = name;
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 24),

                        // Continue Button
                        _GradientButton(
                          title: "Continue to Store Selection",
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => _proceedToStore(skip: false),
                        ),

                        const SizedBox(height: 12),

                        // Skip text button
                        TextButton(
                          onPressed: () => _proceedToStore(skip: true),
                          child: const Text(
                            "Skip Platform Selection >>",
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const _FooterNotice(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 3️⃣ SELECT YOUR STORE PAGE
/// ============================================================================
class StoreSelectionPage extends StatefulWidget {
  final String businessId;
  final String businessName;
  final String platformId;
  final String platformName;

  const StoreSelectionPage({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.platformId,
    required this.platformName,
  });

  @override
  State<StoreSelectionPage> createState() => _StoreSelectionPageState();
}

class _StoreSelectionPageState extends State<StoreSelectionPage> {
  List<dynamic> _storeList = [];
  String _selectedStoreId = '';
  Map<String, dynamic>? _selectedStore;
  bool _isLoading = true;
  bool _isNavigating = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStores() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getStores(
        businessId: widget.businessId,
        platformId: widget.platformId,
      );
      AppLogger.info("Stores fetched: $res");

      List<dynamic> list = [];
      if (res['data'] is List) {
        list = res['data'];
      }

      setState(() {
        _storeList = list;
        _isLoading = false;

        if (_storeList.isNotEmpty && _selectedStoreId.isEmpty) {
          final first = _storeList.first;
          _selectedStoreId = (first['store_id'] ?? first['id'] ?? '').toString();
          _selectedStore = Map<String, dynamic>.from(first);
        }
      });
    } catch (e) {
      AppLogger.error("Failed to fetch stores", e);
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Failed to load stores. You can still continue to dashboard.");
      }
    }
  }

  Future<void> _handleContinue() async {
    setState(() => _isNavigating = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_selectedStore != null) {
        final storeId = (_selectedStore!['store_id'] ?? _selectedStore!['id'] ?? _selectedStoreId).toString();
        final storeName = (_selectedStore!['store_name'] ?? _selectedStore!['name'] ?? widget.businessName).toString();
        final address = (_selectedStore!['address'] ?? '').toString();
        final phone = (_selectedStore!['phone'] ?? _selectedStore!['mobile'] ?? '').toString();
        final branchType = (_selectedStore!['branch_type'] ?? '').toString();

        await prefs.setString("selected_store_id", storeId);
        await prefs.setString("store_id", storeId);
        await prefs.setString("store_name", storeName);
        await prefs.setString("store_address", address);
        await prefs.setString("store_phone", phone);
        await prefs.setString("store_branch_type", branchType);
      } else {
        // Fallback default store
        await prefs.setString("selected_store_id", "1");
        await prefs.setString("store_id", "1");
        await prefs.setString("store_name", widget.businessName);
      }

      // Pre-warm bills API in background
      ApiService.getSalesBills().ignore();

      // Refresh DashboardController if registered
      if (Get.isRegistered<DashboardController>()) {
        try {
          Get.find<DashboardController>().loadBusiness();
        } catch (_) {}
      }

      AppLogger.success("Store selection complete, navigating to Dashboard");

      if (!mounted) return;

      // Navigate to DashboardUI and clear backstack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardUI()),
        (route) => false,
      );
    } catch (e) {
      AppLogger.error("Error finalizing store selection", e);
      if (mounted) {
        setState(() => _isNavigating = false);
        _showSnackBar("Error continuing to dashboard: $e");
      }
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<dynamic> get _filteredStores {
    if (_searchQuery.trim().isEmpty) return _storeList;
    final query = _searchQuery.trim().toLowerCase();
    return _storeList.where((s) {
      final name = (s['store_name'] ?? s['name'] ?? '').toString().toLowerCase();
      final address = (s['address'] ?? '').toString().toLowerCase();
      return name.contains(query) || address.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      body: Stack(
        children: [
          const _FloatingBackgroundDecorations(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Navigation Row
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                              label: const Text(
                                "Back to Platform",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Store Icon Badge
                        const _HeaderIconBadge(
                          icon: Icons.storefront_rounded,
                          color: Color(0xFF3B82F6),
                          bgColor: Color(0xFFEFF6FF),
                        ),
                        const SizedBox(height: 16),

                        // Title & Subtitle
                        const Text(
                          "Select Your Store",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Choose the store branch you want to operate for this session",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Search Bar
                        _SearchInput(
                          controller: _searchController,
                          hintText: "Search store by name or address...",
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 20),

                        // Store List
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 2.5),
                          )
                        else if (_filteredStores.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Column(
                              children: [
                                Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  "No branch stores configured",
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "You can continue directly to dashboard with default store setup",
                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredStores.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final store = _filteredStores[index];
                              final id = (store['store_id'] ?? store['id'] ?? '').toString();
                              final name = (store['store_name'] ?? store['name'] ?? widget.businessName).toString();
                              final address = (store['address'] ?? '').toString();
                              final phone = (store['phone'] ?? store['mobile'] ?? '').toString();
                              final branchType = (store['branch_type'] ?? '').toString();
                              final status = (store['status'] ?? 'Active').toString();
                              final isSelected = _selectedStoreId == id;

                              return _StoreCard(
                                name: name,
                                address: address,
                                phone: phone,
                                branchType: branchType,
                                status: status,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedStoreId = id;
                                    _selectedStore = Map<String, dynamic>.from(store);
                                  });
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 24),

                        // Continue to Dashboard Button
                        _GradientButton(
                          title: "Continue to Dashboard",
                          icon: Icons.arrow_forward_rounded,
                          isLoading: _isNavigating,
                          onPressed: _isNavigating ? null : _handleContinue,
                        ),

                        const SizedBox(height: 18),
                        const _FooterNotice(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 🎨 REUSABLE COMPONENTS FOR PREMIUM LOOK & FEEL
/// ============================================================================

class _HeaderIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _HeaderIconBadge({
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchInput({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final String name;
  final String type;
  final String status;
  final bool isSelected;
  final VoidCallback onTap;

  const _BusinessCard({
    required this.name,
    required this.type,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Stack(
          children: [
            // Top Right Check / Radio Indicator
            Align(
              alignment: Alignment.topRight,
              child: _CheckIndicator(isSelected: isSelected),
            ),

            // Content
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 3D Style Building Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE)]
                            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 26,
                        color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Business Name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Business Type
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
}

class _PlatformCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: _CheckIndicator(isSelected: isSelected),
            ),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE)]
                            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.desktop_windows_rounded,
                        size: 26,
                        color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
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
}

class _StoreCard extends StatelessWidget {
  final String name;
  final String address;
  final String phone;
  final String branchType;
  final String status;
  final bool isSelected;
  final VoidCallback onTap;

  const _StoreCard({
    required this.name,
    required this.address,
    required this.phone,
    required this.branchType,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.store_rounded,
                  size: 24,
                  color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Store Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      _CheckIndicator(isSelected: isSelected),
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (branchType.isNotEmpty || phone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (branchType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              branchType,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                            ),
                          ),
                        if (phone.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_rounded, size: 10, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  phone,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckIndicator extends StatelessWidget {
  final bool isSelected;

  const _CheckIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFF2563EB),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.check, size: 13, color: Colors.white),
        ),
      );
    } else {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
      );
    }
  }
}

class _GradientButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF4338CA), Color(0xFF3B82F6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: enabled ? null : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(icon, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FooterNotice extends StatelessWidget {
  const _FooterNotice();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "© 2026 BillFlow Systems. All rights reserved.",
      style: TextStyle(
        fontSize: 11,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

/// Floating subtle pastel background shapes matching web screen aesthetic
class _FloatingBackgroundDecorations extends StatelessWidget {
  const _FloatingBackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top Left
          Positioned(
            top: 40,
            left: 20,
            child: _DecorativeIcon(
              icon: Icons.apartment_rounded,
              color: const Color(0xFF818CF8).withOpacity(0.25),
              size: 38,
            ),
          ),
          // Top Right
          Positioned(
            top: 60,
            right: 30,
            child: _DecorativeIcon(
              icon: Icons.card_giftcard_rounded,
              color: const Color(0xFFF472B6).withOpacity(0.25),
              size: 32,
            ),
          ),
          // Middle Left
          Positioned(
            top: 280,
            left: 15,
            child: _DecorativeIcon(
              icon: Icons.analytics_rounded,
              color: const Color(0xFF38BDF8).withOpacity(0.25),
              size: 34,
            ),
          ),
          // Middle Right
          Positioned(
            top: 320,
            right: 20,
            child: _DecorativeIcon(
              icon: Icons.shopping_bag_rounded,
              color: const Color(0xFFF87171).withOpacity(0.25),
              size: 30,
            ),
          ),
          // Bottom Left
          Positioned(
            bottom: 40,
            left: 30,
            child: _DecorativeIcon(
              icon: Icons.credit_card_rounded,
              color: const Color(0xFFA78BFA).withOpacity(0.25),
              size: 34,
            ),
          ),
          // Bottom Right
          Positioned(
            bottom: 60,
            right: 40,
            child: _DecorativeIcon(
              icon: Icons.shield_rounded,
              color: const Color(0xFF34D399).withOpacity(0.25),
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _DecorativeIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}