import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/Auth/api service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  int _totalEmployees = 0;
  int _totalRoles = 0;
  int _activeTeams = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardMetrics();
  }

  int _parseCount(dynamic response) {
    if (response == null) return 0;
    
    // Check if response contains success: true and a data list
    final data = response['data'] ?? response;
    
    if (data is List) {
      return data.length;
    }
    
    if (data is Map) {
      final countVal = data['count'] ?? 
                       data['total'] ?? 
                       data['total_count'] ?? 
                       data['length'] ?? 
                       data['members'] ?? 
                       data['roles_count'] ??
                       data['employee_count'] ??
                       data['teams_count'];
                       
      if (countVal != null) {
        return int.tryParse(countVal.toString()) ?? 0;
      }
      
      // Fallback: search values list
      if (data.containsKey('roles') && data['roles'] is List) {
        return (data['roles'] as List).length;
      }
      if (data.containsKey('employees') && data['employees'] is List) {
        return (data['employees'] as List).length;
      }
      if (data.containsKey('teams') && data['teams'] is List) {
        return (data['teams'] as List).length;
      }
    }
    
    return 0;
  }

  Future<void> _fetchDashboardMetrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all three endpoints in parallel
      final results = await Future.wait([
        ApiService.getEmployees(),
        ApiService.getRoles(),
        ApiService.getTeams(),
      ]);

      setState(() {
        _totalEmployees = _parseCount(results[0]);
        _totalRoles = _parseCount(results[1]);
        _activeTeams = _parseCount(results[2]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchDashboardMetrics,
              color: const Color(0xFF4F46E5),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Admin Dashboard",
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "System overview and key resource statistics",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Grid Layout matches the screenshot
                                        Column(
                      children: [
                        _buildMetricCard(
                          title: "TOTAL EMPLOYEES",
                          value: _totalEmployees.toString(),
                          icon: Icons.people_outline_rounded,
                          iconColor: const Color(0xFF4F46E5),
                          iconBgColor: const Color(0xFFEEF2FF),
                        ),
                        const SizedBox(height: 16),
                        _buildMetricCard(
                          title: "TOTAL ROLES",
                          value: _totalRoles.toString(),
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFFEC4899),
                          iconBgColor: const Color(0xFFFDF2F8),
                        ),
                        const SizedBox(height: 16),
                        _buildMetricCard(
                          title: "ACTIVE TEAMS",
                          value: _activeTeams.toString(),
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBgColor: const Color(0xFFECFDF5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
