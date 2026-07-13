import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/Auth/api service.dart';
import 'package:intl/intl.dart';

class AdminTeamPage extends StatefulWidget {
  const AdminTeamPage({super.key});

  @override
  State<AdminTeamPage> createState() => _AdminTeamPageState();
}

class _AdminTeamPageState extends State<AdminTeamPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _roles = [];

  // Team Form Controllers
  final _teamNameCtrl = TextEditingController();
  final _teamLeaderCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _memberSearchCtrl = TextEditingController();

  List<int> _selectedMembers = [];
  String _memberSearchQuery = "";
  
  // Role Setting
  int? _selectedTeamId;
  String? _selectedRole;
  final _departmentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _memberSearchCtrl.addListener(() {
      setState(() {
        _memberSearchQuery = _memberSearchCtrl.text.toLowerCase();
      });
    });
    _fetchData();
    _setCurrentDateTime();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teamNameCtrl.dispose();
    _teamLeaderCtrl.dispose();
    _empIdCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _descCtrl.dispose();
    _memberSearchCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final tRes = await ApiService.getTeams();
      final eRes = await ApiService.getEmployees();
      final rRes = await ApiService.getRoles();

      setState(() {
        if (tRes['data'] is List) _teams = List<Map<String, dynamic>>.from(tRes['data']);
        if (eRes['data'] is List) _employees = List<Map<String, dynamic>>.from(eRes['data']);
        if (rRes['data'] is List) _roles = List<Map<String, dynamic>>.from(rRes['data']);
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTeam() async {
    if (_teamNameCtrl.text.isEmpty) {
      _showSnack("Team Name is required", Colors.red);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final payload = {
        "team_name": _teamNameCtrl.text,
        "team_leader_name": _teamLeaderCtrl.text,
        "employee_id": _empIdCtrl.text,
        "date": _dateCtrl.text,
        "time": _timeCtrl.text,
        "description": _descCtrl.text,
        "members": _selectedMembers,
      };
      
      final res = await ApiService.createTeam(payload);
      print("--------------------------------------------------");
      print("TEAM CREATE SUBMITTED");
      print("PAYLOAD: $payload");
      print("RESPONSE: $res");
      print("--------------------------------------------------");

      if (res.isNotEmpty) {
        _showSnack("Team created successfully!", Colors.green);
        _clearTeamForm();
        await _fetchData();
      } else {
        _showSnack("Failed to save to team-create API. Check terminal.", Colors.red);
      }
    } catch (e) {
      print("ERROR DURING TEAM CREATE: $e");
      _showSnack("Failed to create team: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setTeamRole() async {
    if (_selectedTeamId == null || _selectedRole == null || _departmentCtrl.text.isEmpty) {
      _showSnack("Please select team, role, and department", Colors.red);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final payload = {
        "team_id": _selectedTeamId,
        "role_id": _selectedRole,
        "department": _departmentCtrl.text,
      };
      
      final res = await ApiService.setTeamRole(payload);
      if (res.isNotEmpty) {
        _showSnack("Team role set successfully!", Colors.green);
        _selectedTeamId = null;
        _selectedRole = null;
        _departmentCtrl.clear();
        await _fetchData();
      }
    } catch (e) {
      _showSnack("Failed to set role: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _clearTeamForm() {
    _teamNameCtrl.clear();
    _teamLeaderCtrl.clear();
    _empIdCtrl.clear();
    _dateCtrl.clear();
    _timeCtrl.clear();
    _descCtrl.clear();
    _memberSearchCtrl.clear();
    setState(() => _selectedMembers.clear());
    _setCurrentDateTime();
  }

  void _setCurrentDateTime() {
    final now = DateTime.now();
    setState(() {
      _dateCtrl.text = DateFormat('MM/dd/yyyy').format(now);
      _timeCtrl.text = DateFormat('hh:mm a').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
        : Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTeamTab(),
                    _buildRoleTab(),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hexagon_outlined, color: Color(0xFF4F46E5), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Team Management", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text("Build squads and assign operational leadership", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text("${_teams.length} Active Teams", style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(30),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: "Team"),
          Tab(text: "Role"),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormSectionTitle("NEW TEAM FORM"),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Team Name *"),
                _buildTextField(_teamNameCtrl, "e.g. Quality Assurance Squad"),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Team Leader Name"), _buildTextField(_teamLeaderCtrl, "e.g. Ananya Rao")])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Employee ID"), _buildTextField(_empIdCtrl, "e.g. 101")])),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Date"), _buildTextField(_dateCtrl, "MM/DD/YYYY", icon: Icons.calendar_today)])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Time"), _buildTextField(_timeCtrl, "HH:MM AM", icon: Icons.access_time)])),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _setCurrentDateTime,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Refresh Date & Time", style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel("Description"),
                _buildTextField(_descCtrl, "Briefly state the team's operational scope...", maxLines: 3),
                const SizedBox(height: 16),
                _buildLabel("Assign Team Members"),
                _buildTextField(_memberSearchCtrl, "Search team members..."),
                const SizedBox(height: 12),
                _buildMembersList(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text("${_selectedMembers.length} member(s) selected", style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Create Team", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildFormSectionTitle("ACTIVE TEAMS"),
          const SizedBox(height: 16),
          _teams.isEmpty 
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text("No teams found. Create a team using the form.", style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _teams.length,
                itemBuilder: (context, i) {
                  final t = _teams[i];
                  return _buildActiveTeamCard(t);
                },
              )
        ],
      ),
    );
  }

  Widget _buildActiveTeamCard(Map<String, dynamic> t) {
    final teamName = t['Team Name'] ?? t['team_name'] ?? t['name'] ?? "Unknown";
    final desc = t['Description'] ?? t['description'] ?? "";
    final leaderName = t['Team Leader Name'] ?? t['team_leader_name'] ?? t['lead'] ?? "N/A";
    final leaderId = t['Employee ID'] ?? t['employee_id'] ?? "";
    final List members = t['Assign Team Members'] ?? t['members'] ?? [];
    final createdAt = t['created_at'] != null ? DateFormat('MM/dd/yyyy, hh:mm a').format(DateTime.tryParse(t['created_at'].toString())?.toLocal() ?? DateTime.now()) : "Unknown";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(teamName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(desc, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
          ],
          const SizedBox(height: 20),
          Text("TEAM LEADER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1),
                  radius: 20,
                  child: Text(leaderName.isNotEmpty ? leaderName.substring(0, 1).toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leaderName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), fontSize: 14)),
                      if (leaderId.isNotEmpty)
                        Text("Team Leader (ID: $leaderId)", style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("MEMBERS (${members.length})", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          if (members.isNotEmpty)
            Wrap(
              spacing: -8,
              children: members.take(5).map((m) {
                final mName = (m is Map ? (m['name'] ?? 'U') : 'U').toString();
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.8),
                    radius: 16,
                    child: Text(mName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text("Created on $createdAt", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormSectionTitle("TEAMS LIST"),
          const SizedBox(height: 16),
          _teams.isEmpty 
            ? Text("No teams available. Create one in the Team tab first.", style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _teams.length,
                itemBuilder: (context, i) {
                  final t = _teams[i];
                  final isSelected = _selectedTeamId == t['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTeamId = t['id']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(t['team_name'] ?? t['name'] ?? "Unknown", style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF0F172A))),
                    ),
                  );
                },
              ),
          const SizedBox(height: 32),
          _buildFormSectionTitle("SET ROLE & DEPARTMENT"),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: _selectedTeamId == null 
              ? Center(
                  child: Column(
                    children: [
                      const Icon(Icons.people_alt, size: 48, color: Color(0xFF4F46E5)),
                      const SizedBox(height: 16),
                      Text("No Team Selected", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 8),
                      Text("Click a team from the list above to assign/set its Role and Department.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Select Role"),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: _inputDec("Choose a role"),
                      items: _roles.map((r) => DropdownMenuItem<String>(value: r['id']?.toString() ?? r['name'], child: Text(r['name'] ?? ''))).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Department"),
                    _buildTextField(_departmentCtrl, "Enter department..."),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _setTeamRole,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("Assign Role to Team", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
          )
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    final filtered = _employees.where((e) {
      final name = (e['name'] ?? "").toString().toLowerCase();
      return name.contains(_memberSearchQuery);
    }).toList();

    return Container(
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: filtered.isEmpty 
        ? Center(child: Text("No members found", style: GoogleFonts.inter(color: const Color(0xFF94A3B8))))
        : ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: filtered.length,
            separatorBuilder: (c,i) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
            itemBuilder: (context, i) {
              final emp = filtered[i];
              final eId = emp['id'] as int? ?? 0;
              final isSelected = _selectedMembers.contains(eId);
              
              return ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFF6366F1), child: Text((emp['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                title: Text(emp['name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("ID: $eId", style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12)),
                trailing: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1)),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedMembers.remove(eId);
                    } else {
                      _selectedMembers.add(eId);
                    }
                  });
                },
              );
            },
          ),
    );
  }

  Widget _buildFormSectionTitle(String title) {
    return Center(
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {IconData? icon, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: _inputDec(hint, icon: icon),
    );
  }

  InputDecoration _inputDec(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
      suffixIcon: icon != null ? Icon(icon, color: const Color(0xFF94A3B8), size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
    );
  }
}
