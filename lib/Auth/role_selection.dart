import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'billing dashboardc.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String businessName = '';
  bool isApiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessName();
  }

  Future<void> _loadBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      businessName = prefs.getString("business_name") ?? "Business";
    });
  }

  Future<void> _handleAdminAccess() async {
    setState(() {
      isApiLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? prefs.getString("token") ?? "";

      print("$print debug: API call started to https://billing.srivagroups.in/api/user/permissions");

      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/user/permissions"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      // Print status code and response as debug log in terminal
      print("--------------------------------------------------");
      print("\$print debug: API Status Code: ${response.statusCode}");
      try {
        final decoded = jsonDecode(response.body);
        final prettyResponse = const JsonEncoder.withIndent('  ').convert(decoded);
        print("\$print debug: API Response:\n$prettyResponse");
      } catch (e) {
        print("\$print debug: API Response (Raw): ${response.body}");
      }
      print("--------------------------------------------------");

    } catch (e) {
      print("--------------------------------------------------");
      print("\$print debug: API Call Failed: $e");
      print("--------------------------------------------------");
    } finally {
      setState(() {
        isApiLoading = false;
      });
      // Proceed to the current dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardUI()),
        );
      }
    }
  }

  void _handleEmployeeAccess() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeEmptyPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Very soft slate background
      body: SafeArea(
        child: isApiLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Fetching administrative details...",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          // Top Icon Container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              size: 40,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Business Name Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF7C3AED).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              businessName.toLowerCase(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Heading
                          Text(
                            "How are you accessing?",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            "Choose your role to continue into the dashboard",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ADMIN CARD
                          _buildRoleCard(
                            title: "Admin",
                            badgeText: "DIRECT ACCESS",
                            badgeBgColor: const Color(0xFFFEF3C7),
                            badgeTextColor: const Color(0xFFD97706),
                            icon: Icons.workspace_premium_rounded,
                            iconBgGradient: const LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            description: "Full administrative access. Click to open the dashboard.",
                            onTap: _handleAdminAccess,
                          ),

                          const SizedBox(height: 20),

                          // EMPLOYEE CARD
                          _buildRoleCard(
                            title: "Employee",
                            badgeText: "LOGIN REQUIRED",
                            badgeBgColor: const Color(0xFFDBEAFE),
                            badgeTextColor: const Color(0xFF2563EB),
                            icon: Icons.people_alt_rounded,
                            iconBgGradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            description: "Staff access with assigned permissions. Enter your credentials.",
                            onTap: _handleEmployeeAccess,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      "© 2026 BillFlow Systems. All rights reserved.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required IconData icon,
    required Gradient iconBgGradient,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: const Color(0xFF2563EB).withOpacity(0.04),
          highlightColor: const Color(0xFF2563EB).withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Gradient Icon Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: iconBgGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmployeeEmptyPage extends StatelessWidget {
  const EmployeeEmptyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(), // Completely empty page
    );
  }
}
