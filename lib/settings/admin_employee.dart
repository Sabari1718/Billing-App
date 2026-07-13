import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/Auth/api service.dart';

class AdminEmployeePage extends StatefulWidget {
  const AdminEmployeePage({super.key});

  @override
  State<AdminEmployeePage> createState() => _AdminEmployeePageState();
}

class _AdminEmployeePageState extends State<AdminEmployeePage> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Master Lists loaded from APIs
  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _jobUsers = [];
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];

  // Dropdown selections
  String? _selectedBusiness;
  Map<String, dynamic>? _selectedJobUser;
  String? _selectedRole;

  // Controllers
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Edit / Update mode state
  bool _isEditMode = false;
  int? _editingEmployeeId;

  // Passwords visibility toggle set
  final Set<int> _visiblePasswordIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllDropdownsAndDirectory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employees.where((emp) {
        final name = (emp['employee_name'] ?? emp['name'] ?? "").toString().toLowerCase();
        final empId = (emp['employee_id'] ?? "").toString().toLowerCase();
        final role = (emp['role_name'] ?? emp['role'] ?? "").toString().toLowerCase();
        final userId = (emp['user_id'] ?? emp['username'] ?? "").toString().toLowerCase();
        return name.contains(query) || empId.contains(query) || role.contains(query) || userId.contains(query);
      }).toList();
    });
  }

  List<dynamic> _findFirstList(dynamic json) {
    if (json == null) return [];
    if (json is List) return json;
    if (json is Map) {
      if (json['data'] is List) return json['data'];
      if (json['approved'] is List) return json['approved'];
      if (json['users'] is List) return json['users'];
      if (json['data'] is Map && json['data']['data'] is List) {
        return json['data']['data'];
      }
      for (var val in json.values) {
        final res = _findFirstList(val);
        if (res.isNotEmpty) return res;
      }
    }
    return [];
  }

  Future<void> _loadAllDropdownsAndDirectory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch Businesses
      final bizRes = await ApiService.getBusinesses();
      final bizData = bizRes['data'] ?? bizRes;
      if (bizData is List) {
        _businesses = List<Map<String, dynamic>>.from(bizData);
      }

      // 2. Fetch Job Approved users
      final jobRes = await ApiService.getJobApproved();
      final rawJobUsers = _findFirstList(jobRes);

      List<Map<String, dynamic>> parsedJobUsers = [];
      for (var item in rawJobUsers) {
        if (item is Map) {
          final uName = item['user_name'] ?? item['username'] ?? item['name'] ?? item['employee_name'] ?? "";
          final uId = item['user_main_id'] ?? item['main_id'] ?? item['id'] ?? "";
          if (uName.toString().isNotEmpty) {
            parsedJobUsers.add({
              "user_name": uName.toString(),
              "user_main_id": uId.toString(),
            });
          }
        } else if (item is String && item.isNotEmpty) {
          parsedJobUsers.add({
            "user_name": item,
            "user_main_id": item,
          });
        }
      }
      _jobUsers = parsedJobUsers;

      // 3. Fetch Roles
      final roleRes = await ApiService.getRoles();
      final roleData = roleRes['data'] ?? roleRes;
      if (roleData is List) {
        _roles = List<Map<String, dynamic>>.from(roleData);
      }

      // 4. Fetch Employees
      await _fetchEmployeesListOnly();

    } catch (e) {
      debugPrint("Error loading dependencies: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEmployeesListOnly() async {
    try {
      final empRes = await ApiService.getEmployees();
      final empData = empRes['data'] ?? empRes;
      List<Map<String, dynamic>> fetched = [];
      if (empData is List) {
        fetched = List<Map<String, dynamic>>.from(empData.map((item) {
          return {
            "id": item['id'],
            "employee_name": item['employee_name'] ?? item['name'] ?? "",
            "employee_id": item['employee_id'] ?? "",
            "role_name": item['role_name'] ?? item['role'] ?? "",
            "user_id": item['user_id'] ?? item['userid'] ?? item['username'] ?? "",
            "password": item['password'] ?? "",
            "business_name": item['business_name'] ?? "",
          };
        }));
      }
      setState(() {
        _employees = fetched;
        _filteredEmployees = List<Map<String, dynamic>>.from(_employees);
      });
      _onSearchChanged();
    } catch (e) {
      debugPrint("Error fetching employees: $e");
    }
  }

  void _onJobUserSelected(Map<String, dynamic>? selectedUser) {
    setState(() {
      _selectedJobUser = selectedUser;
      if (selectedUser != null) {
        // Auto-fill only Employee ID using user_main_id. Do not auto-fill User ID.
        final mainId = (selectedUser['user_main_id'] ?? "").toString();
        _employeeIdController.text = mainId;
      } else {
        _employeeIdController.clear();
      }
    });
  }

  Future<void> _submitEmployee() async {
    if (_selectedBusiness == null ||
        _selectedJobUser == null ||
        _employeeIdController.text.trim().isEmpty ||
        _selectedRole == null ||
        _userIdController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required (*) fields."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final payload = {
      "name": _selectedJobUser!['user_name'],
      "employee_name": _selectedJobUser!['user_name'],
      "employee_id": _employeeIdController.text.trim(),
      "role": _selectedRole,
      "role_name": _selectedRole,
      "userid": _userIdController.text.trim(),
      "user_id": _userIdController.text.trim(),
      "password": _passwordController.text.trim(),
      "business_name": _selectedBusiness,
    };

    try {
      if (_isEditMode && _editingEmployeeId != null) {
        await ApiService.updateEmployee(_editingEmployeeId!, payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Employee updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await ApiService.createEmployee(payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Employee registered successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
      _resetForm();
      await _fetchEmployeesListOnly();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Action failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteEmployee(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Employee"),
        content: const Text("Are you sure you want to permanently delete this employee?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.deleteEmployee(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Employee deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
        await _fetchEmployeesListOnly();
      } else {
        throw Exception("Delete API response returned false");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delete failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editEmployee(Map<String, dynamic> emp) {
    setState(() {
      _isEditMode = true;
      _editingEmployeeId = emp['id'];

      // Business Dropdown match
      final bizName = emp['business_name'] ?? "";
      _selectedBusiness = _businesses.any((b) => b['business_name'] == bizName)
          ? bizName
          : null;

      // Full Name Job User dropdown match
      final empName = emp['employee_name'] ?? emp['name'] ?? "";
      final matchedJobUser = _jobUsers.firstWhere(
        (u) => u['user_name'] == empName,
        orElse: () => {"user_name": empName, "user_main_id": emp['employee_id'] ?? ""},
      );
      _selectedJobUser = matchedJobUser;

      _employeeIdController.text = (emp['employee_id'] ?? "").toString();
      
      // Role match
      final matchedRole = emp['role_name'] ?? emp['role'] ?? "";
      _selectedRole = _roles.any((r) => (r['Role Name'] ?? r['role_name'] ?? r['name']) == matchedRole)
          ? _roles.firstWhere((r) => (r['Role Name'] ?? r['role_name'] ?? r['name']) == matchedRole)['Role Name'] ?? matchedRole
          : null;

      _userIdController.text = (emp['user_id'] ?? emp['username'] ?? "").toString();
      _passwordController.text = (emp['password'] ?? "").toString();
    });
  }

  void _resetForm() {
    setState(() {
      _isEditMode = false;
      _editingEmployeeId = null;
      _selectedBusiness = null;
      _selectedJobUser = null;
      _selectedRole = null;
      _employeeIdController.clear();
      _userIdController.clear();
      _passwordController.clear();
    });
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Text(
                    "Employee Management",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Register and manage company personnel credentials",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stacked layout for Form and Directory List
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Register Employee Card
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                _isEditMode ? "Edit Employee Details" : "Register New Employee",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Business field dropdown
                            _buildLabel("Business"),
                            DropdownButtonFormField<String>(
                              value: _selectedBusiness,
                              isExpanded: true,
                              items: _businesses.map((biz) {
                                final name = biz['business_name'] ?? "";
                                return DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name, style: GoogleFonts.inter(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedBusiness = val;
                                });
                              },
                              decoration: _buildInputDecoration("Select a business..."),
                            ),
                            const SizedBox(height: 16),

                            // Full Name dropdown
                            _buildLabel("Full Name"),
                            DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedJobUser,
                              isExpanded: true,
                              items: _jobUsers.map((user) {
                                final name = user['user_name'] ?? "";
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: user,
                                  child: Text(name, style: GoogleFonts.inter(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: _onJobUserSelected,
                              decoration: _buildInputDecoration("Select Name"),
                            ),
                            const SizedBox(height: 16),

                            // Employee ID
                            _buildLabel("Employee ID"),
                            TextField(
                              controller: _employeeIdController,
                              decoration: _buildInputDecoration("e.g. EMP-1092"),
                            ),
                            const SizedBox(height: 16),

                            // Assign Role
                            _buildLabel("Assign Role"),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              items: _roles.map((role) {
                                final rName = role['Role Name'] ?? role['role_name'] ?? role['name'] ?? "";
                                return DropdownMenuItem<String>(
                                  value: rName,
                                  child: Text(rName, style: GoogleFonts.inter(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedRole = val;
                                });
                              },
                              decoration: _buildInputDecoration("Select a role..."),
                            ),
                            const SizedBox(height: 16),

                            // User ID
                            _buildLabel("User ID"),
                            TextField(
                              controller: _userIdController,
                              decoration: _buildInputDecoration("e.g. alex.pierce"),
                            ),
                            const SizedBox(height: 16),

                            // Password
                            _buildLabel("Password"),
                            TextField(
                              controller: _passwordController,
                              obscureText: false, // In form, show normal text as per screenshot hint
                              decoration: _buildInputDecoration("e.g. p@sswOrd123"),
                            ),
                            const SizedBox(height: 24),

                            // Form action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_isEditMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: TextButton(
                                      onPressed: _resetForm,
                                      child: Text(
                                        "Cancel",
                                        style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ElevatedButton(
                                  onPressed: _isSaving ? null : _submitEmployee,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          _isEditMode ? "Update Employee" : "Register Employee",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Directory Container
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Employee Directory (${_filteredEmployees.length})",
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF4F46E5)),
                                      onPressed: () {
                                        _fetchEmployeesListOnly();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Refreshing directory..."),
                                            duration: Duration(milliseconds: 600),
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: "Refresh Directory",
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 180),
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText: "Search directory...",
                                          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                                          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 16),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Directory List Table wrapped in horizontal scroll view
                            if (_filteredEmployees.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                                  child: Text(
                                    "No employees registered yet.",
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF64748B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            else
                                                            ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredEmployees.length,
                                itemBuilder: (context, idx) {
                                  final emp = _filteredEmployees[idx];
                                  final empId = emp['id'] ?? 0;
                                  final isPasswordVisible = _visiblePasswordIds.contains(empId);
                                  final String name = emp['employee_name'] ?? emp['name'] ?? "";
                                  final String employeeId = (emp['employee_id'] ?? "").toString();
                                  final String role = emp['role_name'] ?? emp['role'] ?? "";
                                  final String userId = (emp['user_id'] ?? emp['username'] ?? "").toString();
                                  final String rawPassword = (emp['password'] ?? "").toString();
                                  final String displayPassword = isPasswordVisible ? rawPassword : "••••••••";
                                  final String businessName = emp['business_name'] ?? "";

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (businessName.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      businessName,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color: const Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                                  onPressed: () => _editEmployee(emp),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(6),
                                                  style: IconButton.styleFrom(
                                                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                  onPressed: () => _deleteEmployee(empId),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(6),
                                                  style: IconButton.styleFrom(
                                                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                employeeId,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF4F46E5),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                role,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF3B82F6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "USER ID",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF94A3B8),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  userId,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "PASSWORD",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF94A3B8),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      displayPassword,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    IconButton(
                                                      icon: Icon(
                                                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                                        size: 16,
                                                        color: const Color(0xFF94A3B8),
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          if (isPasswordVisible) {
                                                            _visiblePasswordIds.remove(empId);
                                                          } else {
                                                            _visiblePasswordIds.add(empId);
                                                          }
                                                        });
                                                      },
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "*",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
    );
  }
}
