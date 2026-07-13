import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/Auth/api service.dart';

class AdminRolePage extends StatefulWidget {
  const AdminRolePage({super.key});

  @override
  State<AdminRolePage> createState() => _AdminRolePageState();
}

class _AdminRolePageState extends State<AdminRolePage> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Role List
  List<Map<String, dynamic>> _activeRoles = [];
  List<Map<String, dynamic>> _filteredRoles = [];
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  String? _selectedDepartment;
  
  // Dropdown options
  final List<String> _departments = [
    "Engineering",
    "Design",
    "Product",
    "Quality",
    "Infrastructure",
    "Analytics",
    "Marketing",
    "Finance",
    "Human Resources",
    "Operations"
  ];

  // Edit/Update mode variables
  int? _editingRoleId;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRoles = _activeRoles.where((role) {
        final name = (role['name'] ?? "").toString().toLowerCase();
        final dept = (role['department'] ?? "").toString().toLowerCase();
        final desc = (role['description'] ?? "").toString().toLowerCase();
        return name.contains(query) || dept.contains(query) || desc.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchRoles() async {
    try {
      final response = await ApiService.getRoles();
      final data = response['data'] ?? response;
      
      List<Map<String, dynamic>> fetched = [];
      if (data is List) {
        fetched = List<Map<String, dynamic>>.from(data.map((item) {
          return {
            "id": item['id'],
            "name": item['Role Name'] ?? item['role_name'] ?? item['name'] ?? "",
            "department": item['Department'] ?? item['department'] ?? "",
            "description": item['Description'] ?? item['description'] ?? "",
          };
        }));
      }
      
      setState(() {
        _activeRoles = fetched;
        _isLoading = false;
      });
      _onSearchChanged();
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRole() async {
    if (_nameController.text.trim().isEmpty || _selectedDepartment == null) {
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
      "name": _nameController.text.trim(),
      "role_name": _nameController.text.trim(),
      "department": _selectedDepartment,
      "description": _descController.text.trim(),
    };

    try {
      if (_isEditMode && _editingRoleId != null) {
        // Update mode
        await ApiService.updateRole(_editingRoleId!, payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Role updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create mode
        await ApiService.createRole(payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Role created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reset Form and Refetch
      _resetForm();
      await _fetchRoles();
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

  Future<void> _deleteRole(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Role"),
        content: const Text("Are you sure you want to permanently delete this role?"),
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
      final success = await ApiService.deleteRole(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Role deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
        await _fetchRoles();
      } else {
        throw Exception("Delete API returned false");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delete failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editRole(Map<String, dynamic> role) {
    setState(() {
      _isEditMode = true;
      _editingRoleId = role['id'];
      _nameController.text = role['name'] ?? "";
      _descController.text = role['description'] ?? "";
      _selectedDepartment = _departments.contains(role['department']) ? role['department'] : null;
    });
  }

  void _resetForm() {
    setState(() {
      _isEditMode = false;
      _editingRoleId = null;
      _nameController.clear();
      _descController.clear();
      _selectedDepartment = null;
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
                  // Header Title
                  Text(
                    "Role Management",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Define and configure organizational responsibilities",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stacked Column layout for perfect mobile UI display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Create/Edit Role Form Container
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
                                _isEditMode ? "Edit Role" : "Create New Role",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Role Name Field
                            Row(
                              children: [
                                Text(
                                  "Role Name",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
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
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: "e.g. Lead Designer",
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
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Department Dropdown Field
                            Row(
                              children: [
                                Text(
                                  "Department",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
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
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              isExpanded: true,
                              items: _departments.map((dept) {
                                return DropdownMenuItem<String>(
                                  value: dept,
                                  child: Text(
                                    dept,
                                    style: GoogleFonts.inter(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Type or select a department...",
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                                prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF94A3B8), size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description Field
                            Text(
                              "Description",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _descController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: "Describe role responsibilities...",
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Submit Button Row
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
                                  onPressed: _isSaving ? null : _submitRole,
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
                                          _isEditMode ? "Update Role" : "Create Role",
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

                      // Active Roles Container
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
                            Text(
                              "Active Roles (${_filteredRoles.length})",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Search Field
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "Search roles...",
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Active roles list builder
                            if (_filteredRoles.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        "No roles found",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "matching criteria.",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredRoles.length,
                                itemBuilder: (context, idx) {
                                  final role = _filteredRoles[idx];
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
                                        // Title and buttons
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                role['name'] ?? "",
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                // Edit Button
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                                  onPressed: () => _editRole(role),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(6),
                                                  style: IconButton.styleFrom(
                                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Delete Button
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                  onPressed: () => _deleteRole(role['id']),
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(6),
                                                  style: IconButton.styleFrom(
                                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Department badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            role['department'] ?? "",
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Description
                                        if ((role['description'] ?? "").toString().isNotEmpty)
                                          Text(
                                            role['description'],
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF64748B),
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
                ],
              ),
            ),
    );
  }
}
