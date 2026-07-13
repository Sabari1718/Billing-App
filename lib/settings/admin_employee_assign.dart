import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/Auth/api service.dart';
import 'package:intl/intl.dart';

class AdminEmployeeAssignPage extends StatefulWidget {
  const AdminEmployeeAssignPage({super.key});

  @override
  State<AdminEmployeeAssignPage> createState() => _AdminEmployeeAssignPageState();
}

class _AdminEmployeeAssignPageState extends State<AdminEmployeeAssignPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _modules = [];

  Map<String, dynamic>? _selectedProject;

  // Forms
  String? _selectedTeamId;
  String? _selectedEmployeeId;
  final _taskDetailsCtrl = TextEditingController();

  String? _selectedModule;
  String? _selectedPrivilegeSet;
  List<String> _selectedPages = [];

  List<Map<String, dynamic>> _activeAssignments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_selectedProject != null) {
        _fetchActiveAssignments();
      }
    });
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskDetailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final pRes = await ApiService.getProjects();
      final tRes = await ApiService.getTeams();
      final eRes = await ApiService.getEmployees();
      final mRes = await ApiService.getModulePageMapping();

      setState(() {
        if (pRes['data'] is List) _projects = List<Map<String, dynamic>>.from(pRes['data']);
        if (tRes['data'] is List) _teams = List<Map<String, dynamic>>.from(tRes['data']);
        if (eRes['data'] is List) _employees = List<Map<String, dynamic>>.from(eRes['data']);
        if (mRes['modules'] is List) _modules = List<Map<String, dynamic>>.from(mRes['modules']);
        else if (mRes['data'] is List) _modules = List<Map<String, dynamic>>.from(mRes['data']);
      });
    } catch (e) {
      debugPrint("Error fetching core data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchActiveAssignments() async {
    if (_selectedProject == null) return;
    setState(() => _isLoading = true);
    try {
      final isTeam = _tabController.index == 0;
      final res = isTeam ? await ApiService.getTeamAllocations() : await ApiService.getIndividualAllocations();
      
      setState(() {
        if (res['data'] is List) {
          _activeAssignments = List<Map<String, dynamic>>.from(res['data'])
            .where((a) => a['project_id'].toString() == _selectedProject!['id'].toString()).toList();
        } else {
          _activeAssignments = [];
        }
      });
    } catch (e) {
      debugPrint("Error fetching assignments: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createProject() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _CreateProjectDialog(),
    );

    if (payload != null) {
      setState(() => _isLoading = true);
      try {
        final apiRes = await ApiService.createProject(payload);
        if (apiRes.isNotEmpty) {
          _showSnack("Project Created Successfully!", Colors.green);
          await _fetchData();
        } else {
          _showSnack("Failed to create project. Check terminal.", Colors.red);
        }
      } catch (e) {
        _showSnack("Error: $e", Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedProject == null) {
      _showSnack("Please select a project first", Colors.red);
      return;
    }
    final isTeam = _tabController.index == 0;
    if (isTeam && _selectedTeamId == null) {
      _showSnack("Please select a team", Colors.red);
      return;
    }
    if (!isTeam && _selectedEmployeeId == null) {
      _showSnack("Please select an individual", Colors.red);
      return;
    }
    if (_taskDetailsCtrl.text.isEmpty) {
      _showSnack("Please enter task details", Colors.red);
      return;
    }
    if (_selectedModule == null || _selectedPages.isEmpty) {
      _showSnack("Please select allowed page access", Colors.red);
      return;
    }
    if (_selectedPrivilegeSet == null) {
      _showSnack("Please select a privilege set", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = isTeam ? {
        "Project": _selectedProject!['id'].toString(),
        "Select Team": _selectedTeamId,
        "Enter Work / Task Details": _taskDetailsCtrl.text,
        "Module Permissions": _selectedModule,
        "Allowed Page Access": _selectedPages,
        "Privilege Set": _selectedPrivilegeSet,
      } : {
        "Project": _selectedProject!['id'].toString(),
        "Select Individual Employee": _selectedEmployeeId,
        "Enter Work / Task Details": _taskDetailsCtrl.text,
        "Module Permissions": _selectedModule,
        "Allowed Page Access": _selectedPages,
        "Privilege Set": _selectedPrivilegeSet,
      };

      final res = isTeam 
        ? await ApiService.allocateTeamProject(payload)
        : await ApiService.allocateIndividualProject(payload);

      if (res.isNotEmpty) {
        _showSnack("Assignment saved successfully!", Colors.green);
        _taskDetailsCtrl.clear();
        setState(() {
          _selectedTeamId = null;
          _selectedEmployeeId = null;
          _selectedModule = null;
          _selectedPrivilegeSet = null;
          _selectedPages.clear();
        });
        await _fetchActiveAssignments();
      } else {
        _showSnack("Failed to assign. Check terminal logs.", Colors.red);
      }
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildProjectsSection(),
                  const SizedBox(height: 24),
                  if (_selectedProject == null)
                    _buildNoProjectSelected()
                  else
                    _buildAssignmentSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hexagon_outlined, color: Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Project Allocations", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text("Assign teams & individuals with access controls", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("PROJECTS", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFF94A3B8))),
              ElevatedButton.icon(
                onPressed: _createProject,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: Text("Create Project", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          if (_projects.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("No projects. Click '+ Create Project' to add one.", style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _projects.length,
                itemBuilder: (context, i) {
                  final p = _projects[i];
                  final isSelected = _selectedProject != null && _selectedProject!['id'] == p['id'];
                  final pName = p['Project Name'] ?? p['project_name'] ?? p['name'] ?? "Unknown";
                  final desc = p['Description'] ?? p['description'] ?? "No description";
                  final createdAt = p['created_at'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.tryParse(p['created_at'].toString())?.toLocal() ?? DateTime.now()) : "Unknown";

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedProject = p);
                      _fetchActiveAssignments();
                    },
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(pName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)))),
                              if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 16),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(createdAt, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoProjectSelected() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.folder_open_rounded, size: 64, color: Color(0xFFFFD166)),
          const SizedBox(height: 16),
          Text("No Project\nSelected", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Text("Select a project from the top panel or create a new one to begin assigning resources.", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildAssignmentSection() {
    final pName = _selectedProject!['Project Name'] ?? _selectedProject!['project_name'] ?? _selectedProject!['name'] ?? "Unknown";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "Team Assignment"),
              Tab(text: "Individual Assignment"),
            ],
          ),
        ),
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
              RichText(
                text: TextSpan(
                  text: "Assign to: ",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  children: [
                    TextSpan(text: pName, style: GoogleFonts.inter(color: const Color(0xFF6366F1))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 400, // Fixed height to handle TabBarView inside SingleChildScrollView safely
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAssignmentForm(isTeam: true),
                    _buildAssignmentForm(isTeam: false),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text("Active Assignments", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        const SizedBox(height: 12),
        _buildActiveAssignmentsList(),
      ],
    );
  }

  Widget _buildAssignmentForm({required bool isTeam}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isTeam ? "Select Team *" : "Select Individual *", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          if (isTeam)
            DropdownButtonFormField<String>(
              value: _selectedTeamId,
              decoration: _inputDec("Select a team..."),
              items: _teams.map((t) {
                final val = t['id']?.toString() ?? t['Team Name'] ?? t['team_name'];
                final teamName = t['Team Name'] ?? t['team_name'] ?? t['name'] ?? 'Unknown Team';
                final leader = t['Team Leader Name'] ?? '';
                final displayText = "$teamName — $leader".replaceAll(RegExp(r'\s+'), ' ').trim();
                return DropdownMenuItem<String>(value: val, child: Text(displayText));
              }).toList(),
              onChanged: (val) => setState(() => _selectedTeamId = val),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedEmployeeId,
              decoration: _inputDec("Select an employee..."),
              items: _employees.map((e) {
                final empName = e['name'] ?? 'Unknown';
                final empRole = e['role'] ?? '';
                final empIdStr = e['employee_id'] ?? '';
                final displayText = "$empName — $empRole ($empIdStr)".replaceAll(RegExp(r'\s+'), ' ').trim();
                return DropdownMenuItem<String>(
                  value: e['id']?.toString() ?? e['name'],
                  child: Text(displayText),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedEmployeeId = val),
            ),
          const SizedBox(height: 16),
          Text("Enter Work / Task Details *", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          TextField(
            controller: _taskDetailsCtrl,
            maxLines: 3,
            decoration: _inputDec("Explain project deliverables, tasks, and duties..."),
          ),
          const SizedBox(height: 16),
          Text("Select Allowed Page Access *", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          const SizedBox(height: 4),
          Text("Restrict access to selected routes. Unchecked pages will be hidden.", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          Text("Select Module", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedModule,
            decoration: _inputDec("Select module..."),
            items: _modules.map((m) {
              final val = m['Module Name'] ?? m['moduleName'] ?? m['name'] ?? m['id']?.toString();
              return DropdownMenuItem<String>(value: val, child: Text(val ?? 'Unknown'));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedModule = val;
                _selectedPages.clear();
              });
            },
          ),
          const SizedBox(height: 12),
          if (_selectedModule != null) _buildPagesCheckboxes(),
          const SizedBox(height: 20),
          Text("Select Privilege Set *", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPrivilegeSet,
            decoration: _inputDec("Select a privilege set..."),
            items: const [
              DropdownMenuItem(value: "Read Only (View Only)", child: Text("Read Only (View Only)")),
              DropdownMenuItem(value: "Write Access (Create & Edit)", child: Text("Write Access (Create & Edit)")),
              DropdownMenuItem(value: "Admin Access (Full Control)", child: Text("Admin Access (Full Control)")),
              DropdownMenuItem(value: "Custom Access", child: Text("Custom Access")),
            ],
            onChanged: (val) => setState(() => _selectedPrivilegeSet = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Save Assignment", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPagesCheckboxes() {
    // Find the module object
    final mod = _modules.firstWhere((m) {
      final val = m['Module Name'] ?? m['moduleName'] ?? m['name'] ?? m['id']?.toString();
      return val == _selectedModule;
    }, orElse: () => {});
    
    // We can't rely on nested 'pages' if the data is a flat list mapping module to page
    // The API returned: [{"id":1,"Module Name":"Product","Page Name":"Product List"}]
    // We should filter all mapping entries where Module Name == _selectedModule
    final moduleEntries = _modules.where((m) {
      final val = m['Module Name'] ?? m['moduleName'] ?? m['name'] ?? m['id']?.toString();
      return val == _selectedModule;
    }).toList();

    if (moduleEntries.isEmpty) return const SizedBox.shrink();

    return Column(
      children: moduleEntries.map((p) {
        final pName = p['Page Name'] ?? p['pageName'] ?? p['name'] ?? "Unknown Page";
        final isChecked = _selectedPages.contains(pName);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: CheckboxListTile(
            title: Text(pName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A))),
            value: isChecked,
            activeColor: const Color(0xFF6366F1),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedPages.add(pName);
                } else {
                  _selectedPages.remove(pName);
                }
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveAssignmentsList() {
    if (_activeAssignments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text("No assignments found\nfor this project yet.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeAssignments.length,
      itemBuilder: (context, i) {
        final a = _activeAssignments[i];
        final isTeamAssigned = a.containsKey('Select Team');
        final assigneeId = isTeamAssigned ? a['Select Team']?.toString() : a['Select Individual Employee']?.toString();
        
        String assigneeName = "Unknown";
        if (isTeamAssigned) {
          final t = _teams.firstWhere((t) => t['id']?.toString() == assigneeId, orElse: () => {});
          assigneeName = t['Team Name'] ?? t['team_name'] ?? t['name'] ?? "Unknown Team";
        } else {
          final e = _employees.firstWhere((e) => e['id']?.toString() == assigneeId, orElse: () => {});
          assigneeName = e['name'] ?? e['employee_name'] ?? "Unknown Employee";
        }

        final taskStr = a['Enter Work / Task Details']?.toString() ?? "N/A";
        final privilegeSet = a['Privilege Set']?.toString() ?? "N/A";
        
        List<dynamic> pages = [];
        if (a['Allowed Page Access'] is List) {
          pages = a['Allowed Page Access'];
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isTeamAssigned ? Icons.groups : Icons.person, size: 14, color: const Color(0xFF4F46E5)),
                        const SizedBox(width: 4),
                        Text(isTeamAssigned ? "Team" : "Individual", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _iconBtn(Icons.edit, Colors.orange),
                      const SizedBox(width: 8),
                      _iconBtn(Icons.delete_outline, Colors.grey),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 12),
              Text(assigneeName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  text: "Task: ",
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  children: [
                    TextSpan(text: taskStr, style: GoogleFonts.inter(fontWeight: FontWeight.normal)),
                  ]
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text("Privilege Set: ", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(privilegeSet, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB91C1C))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pages.isNotEmpty) ...[
                Text("Page Access:", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: pages.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: Text(p.toString(), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                  )).toList(),
                )
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _iconBtn(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))),
    );
  }
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog();

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _createDateCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();
  String _priority = "High";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 14));
    _createDateCtrl.text = DateFormat('MM/dd/yyyy hh:mm a').format(now);
    _expiryDateCtrl.text = DateFormat('MM/dd/yyyy hh:mm a').format(nextWeek);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _createDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1))),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Create New Project", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                  )
                ],
              ),
              const Divider(height: 32, color: Color(0xFFE2E8F0)),
              
              _buildLabel("Project Name *"),
              TextField(controller: _nameCtrl, decoration: _inputDec("e.g. Mobile Application")),
              const SizedBox(height: 16),
              
              _buildLabel("Description *"),
              TextField(controller: _descCtrl, maxLines: 3, decoration: _inputDec("Describe project goals...")),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Create Date & Time *"),
                        TextField(
                          controller: _createDateCtrl,
                          readOnly: true,
                          decoration: _inputDec("").copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Expiry Date & Time *"),
                        TextField(
                          controller: _expiryDateCtrl,
                          readOnly: true,
                          decoration: _inputDec("").copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildLabel("Priority *"),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: _inputDec("Select Priority"),
                items: ["High", "Medium", "Low"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Text("Cancel", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_nameCtrl.text.isEmpty) return;
                      Navigator.pop(context, {
                        "Project Name": _nameCtrl.text,
                        "Description": _descCtrl.text,
                        "Create Date & Time": _createDateCtrl.text,
                        "Expiry Date & Time": _expiryDateCtrl.text,
                        "Priority": _priority,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("Create Project", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
