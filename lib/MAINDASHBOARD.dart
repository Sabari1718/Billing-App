import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'Auth/billing dashboardc.dart';
import 'Auth/profile.dart';
import 'mainscreen/screens/profile_screen.dart';



class Dash extends StatefulWidget {
  const Dash({super.key});

  @override
  State<Dash> createState() => _DashState();
}

class _DashState extends State<Dash> {

  ////////////////////////////////////////////////////////////
  /// DEFAULT VALUES (NO ARGUMENTS)
  ////////////////////////////////////////////////////////////

  String role = "user";     // change if needed
  int userId = 1;
  String userName = "Guest";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  String businessId = "";

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    String fetchedRole = prefs.getString("business_type")?.toLowerCase() ?? 
                         prefs.getString("role")?.toLowerCase() ?? 
                         "propagater";

    setState(() {
      userId = int.tryParse(prefs.get("user_id")?.toString() ?? "1") ?? 1;
      userName = prefs.getString("user_name") ?? prefs.getString("business_name") ?? "User";
      businessId = prefs.getString("selected_business_id") ?? prefs.get("business_id")?.toString() ?? "";
      role = fetchedRole;
    });
  }

  void openChat() {
    // Chat functionality removed
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      ////////////////////////////////////////////////////////////
      /// APPBAR
      ////////////////////////////////////////////////////////////

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: AppColors.background.withOpacity(0.8)),
          ),
        ),
        title: const Text(
          "CIRCUIT POINT",
          style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surface,
                child: Text(
                  userName[0].toUpperCase(),
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),

      ////////////////////////////////////////////////////////////
      /// DRAWER
      ////////////////////////////////////////////////////////////

      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: Container(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              /// HEADER
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.background,
                        child: Icon(Icons.person_rounded,
                            size: 35, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          letterSpacing: 2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              _drawerItem(
                icon: Icons.dashboard_rounded,
                title: "Dashboard",
                onTap: () => Navigator.pop(context),
                isActive: true,
              ),
              _drawerItem(
                icon: Icons.person_rounded,
                title: "Profile",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                },
              ),



              const Divider(color: Colors.white10, indent: 20, endIndent: 20),

              _drawerItem(
                icon: Icons.logout_rounded,
                title: "Logout",
                color: AppColors.error,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/login",
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),

      ////////////////////////////////////////////////////////////
      /// BODY
      ////////////////////////////////////////////////////////////

      body: Stack(
        children: [
          // Subtle background glow
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Welcome Back,",
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                
                // Chat Widget / Banner
                GlassContainer(
                   padding: EdgeInsets.all(AppSpacing.l),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: AppColors.primary.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(15),
                         ),
                         child: Icon(Icons.forum_rounded, color: AppColors.primary, size: 30),
                       ),
                       const SizedBox(width: 20),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text(
                               "Support Center",
                               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                             ),
                             Text(
                               "Ready to help with your orders",
                               style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                             ),
                           ],
                         ),
                       ),
                       ElevatedButton(
                         onPressed: openChat,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.primary,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           elevation: 0,
                         ),
                         child: const Text("Open"),
                       ),
                     ],
                   ),
                ),
                
                const SizedBox(height: 40),
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [

                      AppDashboardCard(
                        title: "Store",
                        icon: Icons.storefront_rounded,
                        accentColor: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoreMenuPage(role: role),
                          ),
                        ),
                      ),
                      AppDashboardCard(
                        title: "Seller Update",
                        icon: Icons.update_rounded,
                        accentColor: AppColors.secondary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerUpdateMenuPage(role: role),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String title, required VoidCallback onTap, Color color = Colors.white, bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? AppColors.primary : color.withOpacity(isActive ? 1 : 0.7), size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primary : color.withOpacity(isActive ? 1 : 0.7),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _drawerExpansionTile({required IconData icon, required String title, required List<Widget> children}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white.withOpacity(0.7), size: 24),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: Colors.white54,
        children: children,
      ),
    );
  }

  Widget _drawerSubItem({required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 45),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppDashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const AppDashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
