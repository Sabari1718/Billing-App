import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:billingapp/mainscreen/theme/theme_provider.dart';
import 'package:billingapp/Auth/api service.dart';
import 'package:billingapp/settings/pin_auth_gate.dart';
import 'package:billingapp/Auth/billing dashboardc.dart';

/// Shows the top-right floating profile quick actions popup (matching Photo 3 & Photo 5)
void showProfileQuickActionsMenu(BuildContext context, DashboardController controller) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "ProfileQuickActions",
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, anim1, anim2) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight + 4, right: 12, left: 16),
            child: Material(
              color: Colors.transparent,
              child: ProfileQuickActionsCard(controller: controller),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (dialogContext, anim, secondaryAnim, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          alignment: Alignment.topRight,
          child: child,
        ),
      );
    },
  );
}

class ProfileQuickActionsCard extends StatefulWidget {
  final DashboardController controller;

  const ProfileQuickActionsCard({super.key, required this.controller});

  @override
  State<ProfileQuickActionsCard> createState() => _ProfileQuickActionsCardState();
}

class _ProfileQuickActionsCardState extends State<ProfileQuickActionsCard> {
  bool _isSettingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = provider_pkg.Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final userName = widget.controller.businessName.value.isNotEmpty
        ? widget.controller.businessName.value
        : "Kalaivani";
    final userEmail = widget.controller.businessEmail.value.isNotEmpty
        ? widget.controller.businessEmail.value
        : "kalaivanisut@gmail.com";
    final userRole = "Administrator";
    final initial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : "K";

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 560),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER INFO HEADER (Photo 3)
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userRole,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // QUICK ACTIONS TITLE
            Text(
              "QUICK ACTIONS",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 10),

            // TILE 1: STORE SELECTOR (Photo 3 & Photo 4)
            InkWell(
              onTap: () {
                Navigator.pop(context);
                showSelectBusinessStoreDialog(context, widget.controller);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withOpacity(0.4) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_outlined, size: 18, color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Store",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Obx(() => Text(
                                widget.controller.storeName.value.isNotEmpty
                                    ? widget.controller.storeName.value
                                    : "Circuitpointcare",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // TILE 2: SETTINGS (EXPANDABLE - Photo 3 & Photo 5)
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withOpacity(0.4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isSettingsExpanded
                      ? const Color(0xFF6366F1).withOpacity(0.5)
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isSettingsExpanded = !_isSettingsExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Settings",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  "Manage admin & Rental admin",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _isSettingsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 18,
                            color: const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SUB-ITEMS ACCORDION (Photo 5)
                  if (_isSettingsExpanded) ...[
                    Divider(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0), height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Column(
                        children: [
                          _buildSubActionRow(
                            icon: Icons.admin_panel_settings_outlined,
                            title: "Manage admin",
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PinAuthGatePage()),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          _buildSubActionRow(
                            icon: Icons.business_center_outlined,
                            title: "Rental admin",
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PinAuthGatePage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // TILE 3: THEME PREFERENCE (Photo 3 & Photo 5)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Theme",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      "Appearance preference",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // THEME PILL SWITCHER: Light | Dark | System
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _buildThemePill(
                    label: "Light",
                    icon: Icons.light_mode_outlined,
                    isSelected: !isDark,
                    onTap: () {
                      themeProvider.setDarkMode(false);
                      setState(() {});
                    },
                  ),
                  _buildThemePill(
                    label: "Dark",
                    icon: Icons.dark_mode_outlined,
                    isSelected: isDark,
                    onTap: () {
                      themeProvider.setDarkMode(true);
                      setState(() {});
                    },
                  ),
                  _buildThemePill(
                    label: "System",
                    icon: Icons.settings_system_daydream_outlined,
                    isSelected: false,
                    onTap: () {
                      final platformDark =
                          WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
                      themeProvider.setDarkMode(platformDark);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // LOGOUT BUTTON (Photo 3 & Photo 5)
            InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.controller.logout(context);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFEF4444).withOpacity(0.12) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 15, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Text(
                      "LOGOUT",
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFFEF4444),
                      ),
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

  Widget _buildSubActionRow({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the "Select Business Store" dialog matching Photo 4
void showSelectBusinessStoreDialog(BuildContext context, DashboardController controller) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) => SelectBusinessStoreDialog(controller: controller),
  );
}

class SelectBusinessStoreDialog extends StatefulWidget {
  final DashboardController controller;

  const SelectBusinessStoreDialog({super.key, required this.controller});

  @override
  State<SelectBusinessStoreDialog> createState() => _SelectBusinessStoreDialogState();
}

class _SelectBusinessStoreDialogState extends State<SelectBusinessStoreDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _stores = [];
  bool _isLoading = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getStores(
        businessId: widget.controller.businessId.value.isNotEmpty
            ? widget.controller.businessId.value
            : "52",
      );
      if (res["success"] == true && res["data"] is List) {
        if (mounted) {
          setState(() {
            _stores = res["data"] as List;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = provider_pkg.Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Filter stores by search query
    final query = _searchQuery.trim().toLowerCase();
    List<dynamic> filtered = _stores.where((item) {
      if (query.isEmpty) return true;
      if (item is! Map) return false;
      final name = (item["store_name"] ?? "").toString().toLowerCase();
      final address = (item["address"] ?? "").toString().toLowerCase();
      final phone = (item["phone"] ?? item["mobile"] ?? "").toString().toLowerCase();
      return name.contains(query) || address.contains(query) || phone.contains(query);
    }).toList();

    // If API returned no stores, provide the active store as fallback
    if (filtered.isEmpty && _stores.isEmpty && !_isLoading) {
      filtered = [
        {
          "store_id": 38,
          "store_name": widget.controller.storeName.value.isNotEmpty
              ? widget.controller.storeName.value
              : "Circuitpointcare",
          "status": widget.controller.storeStatus.value.isNotEmpty
              ? widget.controller.storeStatus.value
              : "Active",
          "address": widget.controller.storeAddress.value.isNotEmpty
              ? widget.controller.storeAddress.value
              : "Neelambur, Sulur Taluk, Coimbatore, TamilNadu, 641062",
          "phone": widget.controller.storeMobile.value.isNotEmpty
              ? widget.controller.storeMobile.value
              : "9092014442",
        }
      ];
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 440,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER (Photo 4)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Business Store",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Store selection is optional",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 0),
                  ),
                  child: Text(
                    "Skip",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // SEARCH BAR & REFRESH BUTTON (Photo 4)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                        hintText: "Search store name, business, address, city or phone...",
                        hintStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loadStores,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                        )
                      : const Icon(Icons.refresh, size: 14, color: Color(0xFF2563EB)),
                  label: Text(
                    "Refresh",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // STORES LIST
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              "No matching store found",
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final store = filtered[index];
                            final sName = (store["store_name"] ?? "Circuitpointcare").toString();
                            final sStatus = (store["status"] ?? "Active").toString();
                            final sAddr = (store["address"] ?? "").toString();
                            final sPhone = (store["mobile"] ?? store["phone"] ?? "9092014442").toString();
                            final isSelected = widget.controller.storeName.value.toLowerCase() == sName.toLowerCase();

                            return InkWell(
                              onTap: () async {
                                final prefs = await SharedPreferences.getInstance();
                                widget.controller.storeName.value = sName;
                                widget.controller.storeStatus.value = sStatus;
                                widget.controller.storeAddress.value = sAddr;
                                widget.controller.storeMobile.value = sPhone;

                                if (store["store_id"] != null) {
                                  final sIdStr = store["store_id"].toString();
                                  await prefs.setString("selected_store_id", sIdStr);
                                  await prefs.setString("store_id", sIdStr);
                                }
                                await prefs.setString("store_name", sName);
                                await prefs.setString("selected_store_name", sName);
                                await prefs.setString("store_address", sAddr);
                                await prefs.setString("store_phone", sPhone);

                                widget.controller.fetchDashboardData();

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Selected Store: $sName"),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? (isSelected ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFF0F172A))
                                      : (isSelected ? const Color(0xFFEFF6FF) : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // STORE NAME & ACTIVE BADGE (Photo 4)
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDBEAFE),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.store_outlined, size: 16, color: Color(0xFF1D4ED8)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sName,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              Text(
                                                "Business",
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFA7F3D0)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 5,
                                                height: 5,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF10B981),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                sStatus,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF059669),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (sAddr.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              sAddr,
                                              style: GoogleFonts.inter(
                                                fontSize: 10.5,
                                                color: isDark ? Colors.grey.shade400 : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    if (sPhone.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            sPhone,
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              color: isDark ? Colors.grey.shade400 : const Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 14),

            // BOTTOM FOOTER NOTE (Photo 4)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Selected store address will automatically print on all B2B Invoices & Receipts.",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: const Size(0, 0),
                  ),
                  child: Text(
                    "Skip for now →",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
