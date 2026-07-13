import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import all sub-screens
import 'manage_dashboard.dart';
import 'manage_data_entry.dart';
import 'manage_list.dart';
import 'admin_dashboard.dart';
import 'admin_role.dart';
import 'admin_employee.dart';
import 'admin_team.dart';
import 'admin_employee_assign.dart';
import 'admin_page.dart';
import 'admin_security_pin.dart';

class ManagePortalPage extends StatefulWidget {
  const ManagePortalPage({super.key});

  @override
  State<ManagePortalPage> createState() => _ManagePortalPageState();
}

class _ManagePortalPageState extends State<ManagePortalPage> {
  // Navigation Menu state
  String _activeSection = 'Manage';
  String _activeSubSection = 'Dashboard';
  
  // History stack for navigation
  final List<Map<String, String>> _history = [];

  // Toggle flags for accordions
  bool _isManageExpanded = true;
  bool _isAdminExpanded = true;

  void _navigateTo(String section, String subSection) {
    if (_activeSection == section && _activeSubSection == subSection) return;
    setState(() {
      _history.add({
        'section': _activeSection,
        'subSection': _activeSubSection,
      });
      _activeSection = section;
      _activeSubSection = subSection;
    });
  }

  void _goBack() {
    if (_history.isNotEmpty) {
      setState(() {
        final prev = _history.removeLast();
        _activeSection = prev['section']!;
        _activeSubSection = prev['subSection']!;
      });
    } else {
      Navigator.pop(context);
    }
  }

  // Render the selected view widget
  Widget _buildActiveBody() {
    if (_activeSection == 'Manage') {
      switch (_activeSubSection) {
        case 'Dashboard':
          return const ManageDashboardPage();
        case 'Data Entry':
          return const ManageDataEntryPage();
        case 'Manage':
          return const ManageListPage();
      }
    } else if (_activeSection == 'Admin') {
      switch (_activeSubSection) {
        case 'Dashboard':
          return const AdminDashboardPage();
        case 'Role':
          return const AdminRolePage();
        case 'Employee':
          return const AdminEmployeePage();
        case 'Team':
          return const AdminTeamPage();
        case 'Employee Assign':
          return const AdminEmployeeAssignPage();
        case 'Page':
          return const AdminPageSettingsPage();
        case 'Security PIN':
          return const AdminSecurityPinPage();
      }
    }
    return const ManageDashboardPage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _history.isEmpty,
      onPopInvokedWithResult: (didPop, dynamic _) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            "$_activeSection / $_activeSubSection",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
            onPressed: _goBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
        drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Drawer header panel
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "MANAGE",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B), size: 20),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                children: [
                  // --- MANAGE ACCORDION ---
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: _isManageExpanded,
                      onExpansionChanged: (val) => setState(() => _isManageExpanded = val),
                      leading: const Icon(Icons.grid_view_rounded, color: Color(0xFF6366F1), size: 20),
                      title: Text(
                        "Manage",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                      trailing: Icon(
                        _isManageExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: const Color(0xFF6366F1),
                      ),
                      children: [
                        _buildSubMenuTile(
                          title: "Dashboard",
                          icon: Icons.dashboard_outlined,
                          section: "Manage",
                        ),
                        _buildSubMenuTile(
                          title: "Data Entry",
                          icon: Icons.edit_outlined,
                          section: "Manage",
                        ),
                        _buildSubMenuTile(
                          title: "Manage",
                          icon: Icons.widgets_outlined,
                          section: "Manage",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // --- ADMIN ACCORDION ---
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: _isAdminExpanded,
                      onExpansionChanged: (val) => setState(() => _isAdminExpanded = val),
                      leading: const Icon(Icons.shield_outlined, color: Color(0xFF475569), size: 20),
                      title: Text(
                        "Admin",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      trailing: Icon(
                        _isAdminExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: const Color(0xFF475569),
                      ),
                      children: [
                        _buildSubMenuTile(
                          title: "Dashboard",
                          icon: Icons.dashboard_outlined,
                          section: "Admin",
                        ),
                        _buildSubMenuTile(
                          title: "Role",
                          icon: Icons.shield_outlined,
                          section: "Admin",
                        ),
                        _buildSubMenuTile(
                          title: "Employee",
                          icon: Icons.people_outline,
                          section: "Admin",
                        ),
                        _buildSubMenuTile(
                          title: "Team",
                          icon: Icons.group_work_outlined,
                          section: "Admin",
                        ),
                        _buildSubMenuTile(
                          title: "Employee Assign",
                          icon: Icons.assignment_outlined,
                          section: "Admin",
                        ),
                        _buildSubMenuTile(
                          title: "Page",
                          icon: Icons.layers_outlined,
                          section: "Admin",
                        ),
                        _buildSubMenuTile(
                          title: "Security PIN",
                          icon: Icons.vpn_key_outlined,
                          section: "Admin",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Logout row at the bottom
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: Text(
                  "Logout",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close Drawer
                  Navigator.pop(context); // Exit Portal
                },
              ),
            ),
          ],
        ),
      ),
      body: _buildActiveBody(),
    ));
  }

  Widget _buildSubMenuTile({
    required String title,
    required IconData icon,
    required String section,
  }) {
    final bool isSelected = _activeSection == section && _activeSubSection == title;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
        leading: Icon(
          icon,
          size: 18,
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
          ),
        ),
        onTap: () {
          _navigateTo(section, title);
          Navigator.pop(context); // Close the drawer
        },
      ),
    );
  }
}
