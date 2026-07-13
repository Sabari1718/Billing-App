import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/Auth/api service.dart';

class AdminPageSettingsPage extends StatefulWidget {
  const AdminPageSettingsPage({super.key});

  @override
  State<AdminPageSettingsPage> createState() => _AdminPageSettingsPageState();
}

class _AdminPageSettingsPageState extends State<AdminPageSettingsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSaving = false;

  late TabController _tabController;

  // Data lists
  List<dynamic> _modules = [];
  List<dynamic> _pages = [];
  List<dynamic> _mappings = [];

  // Controllers - Module
  final TextEditingController _moduleNameCtrl = TextEditingController();
  final TextEditingController _moduleDescCtrl = TextEditingController();
  String _moduleStatus = 'Active';

  // Controllers - Page
  final TextEditingController _pageNameCtrl = TextEditingController();
  final TextEditingController _pageDescCtrl = TextEditingController();
  String _pageStatus = 'Active';

  // Controllers - Mapping
  String? _selectedModuleForMap;
  String? _selectedPageForMap;
  final TextEditingController _mapDescCtrl = TextEditingController();
  String _mapStatus = 'Active';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final moduleRes = await ApiService.getRaw(url: "/admin/module-create");
      final pageRes = await ApiService.getRaw(url: "/admin/page-create");
      final mapRes = await ApiService.getRaw(url: "/admin/module-page-mapping");

      if (mounted) {
        setState(() {
          _modules = (moduleRes['data'] as List<dynamic>?) ?? [];
          _pages = (pageRes['data'] as List<dynamic>?) ?? [];
          _mappings = (mapRes['data'] as List<dynamic>?) ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching page data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============== SUBMIT HANDLERS ============== //

  Future<void> _submitModule() async {
    if (_moduleNameCtrl.text.isEmpty) {
      _showSnack("Module Name is required", isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final payload = {
        "Module Name": _moduleNameCtrl.text.trim(),
        "Description": _moduleDescCtrl.text.trim(),
        "Status": _moduleStatus,
      };
      await ApiService.postRaw(url: "/admin/module-create", body: payload);
      _showSnack("Module created successfully!");
      _moduleNameCtrl.clear();
      _moduleDescCtrl.clear();
      _moduleStatus = 'Active';
      _fetchAllData();
    } catch (e) {
      _showSnack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitPage() async {
    if (_pageNameCtrl.text.isEmpty) {
      _showSnack("Page Name is required", isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final payload = {
        "Page Name": _pageNameCtrl.text.trim(),
        "Description": _pageDescCtrl.text.trim(),
        "Status": _pageStatus,
      };
      await ApiService.postRaw(url: "/admin/page-create", body: payload);
      _showSnack("Page created successfully!");
      _pageNameCtrl.clear();
      _pageDescCtrl.clear();
      _pageStatus = 'Active';
      _fetchAllData();
    } catch (e) {
      _showSnack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitMapping() async {
    if (_selectedModuleForMap == null || _selectedPageForMap == null) {
      _showSnack("Module and Page are required", isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final payload = {
        "Module Name": _selectedModuleForMap,
        "Page Name": _selectedPageForMap,
        "Description": _mapDescCtrl.text.trim(),
        "Status": _mapStatus,
      };
      await ApiService.postRaw(url: "/admin/module-page-mapping", body: payload);
      _showSnack("Mapping created successfully!");
      _mapDescCtrl.clear();
      _selectedModuleForMap = null;
      _selectedPageForMap = null;
      _mapStatus = 'Active';
      _fetchAllData();
    } catch (e) {
      _showSnack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============== UI BUILDERS ============== //

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabs(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildModuleCreateTab(),
                    _buildPageCreateTab(),
                    _buildMappingTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
            child: const Icon(Icons.settings_suggest, color: Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Page & Module Configuration", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text("Manage system modules, pages, and their relational mappings", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4F46E5),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF4F46E5),
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: "Module Create"),
          Tab(text: "Page Create"),
          Tab(text: "Module & Page Mapping"),
        ],
      ),
    );
  }

  Widget _buildModuleCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormCard(
            title: "Create New Module",
            children: [
              _buildLabel("Module Name *"),
              _buildTextField(_moduleNameCtrl, "e.g. Sales Management"),
              const SizedBox(height: 16),
              _buildLabel("Status"),
              _buildStatusDropdown(_moduleStatus, (val) => setState(() => _moduleStatus = val!)),
              const SizedBox(height: 16),
              _buildLabel("Description"),
              _buildTextField(_moduleDescCtrl, "Module scope details...", maxLines: 3),
              const SizedBox(height: 20),
              _buildSubmitButton("Create Module", _submitModule),
            ],
          ),
          const SizedBox(height: 24),
          _buildListCard("Active Modules", "Search modules...", _modules, (m) {
            return _buildListItem(
              title: m['Module Name'] ?? 'Unknown',
              subtitle: m['Description'] ?? '-',
              status: m['Status'] ?? 'Active',
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPageCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormCard(
            title: "Create New Page",
            children: [
              _buildLabel("Page Name *"),
              _buildTextField(_pageNameCtrl, "e.g. Invoice Register"),
              const SizedBox(height: 16),
              _buildLabel("Status"),
              _buildStatusDropdown(_pageStatus, (val) => setState(() => _pageStatus = val!)),
              const SizedBox(height: 16),
              _buildLabel("Description"),
              _buildTextField(_pageDescCtrl, "Page purpose or path...", maxLines: 3),
              const SizedBox(height: 20),
              _buildSubmitButton("Create Page", _submitPage),
            ],
          ),
          const SizedBox(height: 24),
          _buildListCard("Active Pages", "Search pages...", _pages, (p) {
            return _buildListItem(
              title: p['Page Name'] ?? 'Unknown',
              subtitle: p['Description'] ?? '-',
              status: p['Status'] ?? 'Active',
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMappingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormCard(
            title: "Create New Mapping",
            children: [
              _buildLabel("Module *"),
              DropdownButtonFormField<String>(
                value: _selectedModuleForMap,
                decoration: _inputDec("Select a Module"),
                items: _modules.map((m) {
                  final name = m['Module Name']?.toString() ?? 'Unknown';
                  return DropdownMenuItem<String>(value: name, child: Text(name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedModuleForMap = val),
              ),
              const SizedBox(height: 16),
              _buildLabel("Page *"),
              DropdownButtonFormField<String>(
                value: _selectedPageForMap,
                decoration: _inputDec("Select a Page"),
                items: _pages.map((p) {
                  final name = p['Page Name']?.toString() ?? 'Unknown';
                  return DropdownMenuItem<String>(value: name, child: Text(name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedPageForMap = val),
              ),
              const SizedBox(height: 16),
              _buildLabel("Description"),
              _buildTextField(_mapDescCtrl, "Provide context for this mapping...", maxLines: 3),
              const SizedBox(height: 16),
              _buildLabel("Status"),
              _buildStatusDropdown(_mapStatus, (val) => setState(() => _mapStatus = val!)),
              const SizedBox(height: 20),
              _buildSubmitButton("Create Mapping", _submitMapping),
            ],
          ),
          const SizedBox(height: 24),
          _buildListCard("Mapped Module & Page Links", "Search mappings...", _mappings, (mapItem) {
            return _buildListItem(
              title: mapItem['Module Name'] ?? mapItem['Module'] ?? 'Unknown Module',
              badgeText: mapItem['Page Name'] ?? mapItem['Page'] ?? 'Unknown Page',
              subtitle: mapItem['Description'] ?? '-',
              status: mapItem['Status'] ?? 'Active',
            );
          }),
        ],
      ),
    );
  }

  // ============== HELPER WIDGETS ============== //

  Widget _buildFormCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListCard(String title, String searchHint, List<dynamic> items, Widget Function(dynamic) builder) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: _inputDec(searchHint).copyWith(
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
            ),
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text("No items found.", style: GoogleFonts.inter(color: const Color(0xFF94A3B8)))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) => builder(items[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildListItem({required String title, String? badgeText, required String subtitle, required String status}) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8FAFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade500),
                ],
              )
            ],
          ),
          if (badgeText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badgeText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
            ),
          ],
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? const Color(0xFF10B981).withOpacity(0.2) : Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? const Color(0xFF10B981) : Colors.red)),
                const SizedBox(width: 6),
                Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF10B981) : Colors.red)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: _inputDec(hint),
    );
  }

  Widget _buildStatusDropdown(String val, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: val,
      decoration: _inputDec("Select Status"),
      items: const [
        DropdownMenuItem(value: "Active", child: Text("Active")),
        DropdownMenuItem(value: "Inactive", child: Text("Inactive")),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSubmitButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
