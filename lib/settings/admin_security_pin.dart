import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/Auth/api service.dart';

class AdminSecurityPinPage extends StatefulWidget {
  const AdminSecurityPinPage({super.key});

  @override
  State<AdminSecurityPinPage> createState() => _AdminSecurityPinPageState();
}

class _AdminSecurityPinPageState extends State<AdminSecurityPinPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Configurations list
  List<Map<String, dynamic>> _pinConfigs = [];
  List<Map<String, dynamic>> _filteredPinConfigs = [];
  List<String> _availableRoles = [];

  // Controllers
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedRole;

  // Visibility states
  bool _obscurePinInput = true;
  final Set<int> _visiblePinIds = {}; // Tracks which row PINs are revealed

  // Edit Mode state
  int? _editingConfigId;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _fetchPinConfigsAndRoles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPinConfigs = _pinConfigs.where((config) {
        final pin = (config['pin'] ?? "").toString().toLowerCase();
        final role = (config['admin'] ?? "").toString().toLowerCase();
        return pin.contains(query) || role.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchPinConfigsAndRoles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        ApiService.getPinAuths(),
        ApiService.getRoles(),
      ]);

      final pinRes = results[0];
      final roleRes = results[1];

      // Parse PIN Configs
      List<Map<String, dynamic>> fetchedConfigs = [];
      final pinData = pinRes['data'] ?? pinRes;
      if (pinData is List) {
        fetchedConfigs = List<Map<String, dynamic>>.from(pinData);
      } else if (pinRes['success'] == true && pinRes['data'] != null) {
        fetchedConfigs = List<Map<String, dynamic>>.from(pinRes['data']);
      }

      // Parse Roles
      List<String> fetchedRoles = [];
      final roleData = roleRes['data'] ?? roleRes;
      if (roleData is List) {
        for (var item in roleData) {
          final rName = item['Role Name'] ?? item['role_name'] ?? item['name'] ?? "";
          if (rName.toString().isNotEmpty) {
            fetchedRoles.add(rName.toString());
          }
        }
      }

      // Fallback default roles if empty
      if (fetchedRoles.isEmpty) {
        fetchedRoles = ["manage admin", "Admin", "Super Admin", "Employee", "Manager"];
      }

      // De-duplicate roles
      fetchedRoles = fetchedRoles.toSet().toList();

      setState(() {
        _pinConfigs = fetchedConfigs;
        _availableRoles = fetchedRoles;
        _isLoading = false;
      });
      _onSearchChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load configurations: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submitConfig() async {
    final pin = _pinController.text.trim();
    final role = _selectedRole;

    if (pin.length != 4 || int.tryParse(pin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Security PIN must be exactly 4 digits."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (role == null || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please associate an admin role."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final payload = {
      "pin": pin,
      "admin": role,
    };

    try {
      if (_isEditMode && _editingConfigId != null) {
        await ApiService.updatePinAuth(_editingConfigId!, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Configuration updated successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await ApiService.createPinAuth(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Configuration created successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _resetForm();
      await _fetchPinConfigsAndRoles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Operation failed: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteConfig(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Configuration",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to permanently delete this PIN configuration?",
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Delete",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.deletePinAuth(id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Configuration deleted successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _resetForm();
        await _fetchPinConfigsAndRoles();
      } else {
        throw Exception("Delete API returned false");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delete failed: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editConfig(Map<String, dynamic> config) {
    setState(() {
      _isEditMode = true;
      _editingConfigId = config['id'];
      _pinController.text = config['pin']?.toString() ?? "";
      final roleVal = config['admin']?.toString() ?? "";
      if (roleVal.isNotEmpty && !_availableRoles.contains(roleVal)) {
        _availableRoles.add(roleVal);
      }
      _selectedRole = roleVal.isNotEmpty ? roleVal : null;
    });
  }

  void _resetForm() {
    setState(() {
      _isEditMode = false;
      _editingConfigId = null;
      _pinController.clear();
      _selectedRole = null;
    });
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dt.month - 1];
      final day = dt.day;
      int hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return "$month $day, $hour:$minute $period";
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchPinConfigsAndRoles,
              color: const Color(0xFF4F46E5),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Refresh Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Security PIN Settings",
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Configure system authentication PINs and associate them with administrator privileges.",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _fetchPinConfigsAndRoles,
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF475569)),
                          label: Text(
                            "Refresh",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Layout split or stacked
                    if (isWideScreen)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _buildFormCard(isDark)),
                          const SizedBox(width: 24),
                          Expanded(flex: 6, child: _buildTableCard(isDark)),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFormCard(isDark),
                          const SizedBox(height: 24),
                          _buildTableCard(isDark),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Purple Indicator Line
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    _isEditMode ? "Edit PIN Configuration" : "Configure New PIN",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Define a 4-digit PIN access credentials and set the corresponding admin role.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // PIN Input Field
                Row(
                  children: [
                    Text(
                      "Security PIN (4 Digits)",
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
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pinController,
                  obscureText: _obscurePinInput,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(4),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "e.g. 2580",
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF94A3B8), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePinInput ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePinInput = !_obscurePinInput;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Only numeric characters allowed.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 20),

                // Role Selector Field
                Row(
                  children: [
                    Text(
                      "Associated Admin Role",
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
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  items: _availableRoles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(
                        role,
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Select an admin role...",
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF94A3B8), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Button Actions
                Row(
                  children: [
                    if (_isEditMode) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetForm,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                                _isEditMode ? "Save Configuration" : "Create Configuration",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideHeader = constraints.maxWidth > 550;
              final searchWidget = SizedBox(
                width: isWideHeader ? 240 : double.infinity,
                height: 38,
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search PINs or roles...",
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 16),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                  ),
                ),
              );

              return isWideHeader
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Active PIN Configurations",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        searchWidget,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active PIN Configurations",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        searchWidget,
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Custom responsive table layout
          _buildTableHeader(isDark),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          if (_filteredPinConfigs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Column(
                  children: [
                    Icon(Icons.shield_moon_outlined, size: 48, color: const Color(0xFF94A3B8).withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      "No active PINs found",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Try refining your search or add a new PIN",
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
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredPinConfigs.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final config = _filteredPinConfigs[index];
                final id = config['id'] ?? index;
                final pin = config['pin']?.toString() ?? "";
                final admin = config['admin']?.toString() ?? "";
                final dateStr = _formatDate(config['updated_at'] ?? config['created_at']);
                final isPinVisible = _visiblePinIds.contains(id);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      // Security PIN
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Text(
                              isPinVisible ? pin : "••••",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: isPinVisible ? 0.0 : 2.0,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isPinVisible) {
                                    _visiblePinIds.remove(id);
                                  } else {
                                    _visiblePinIds.add(id);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  isPinVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 16,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Admin Role
                      Expanded(
                        flex: 3,
                        child: Text(
                          admin,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Last Updated
                      Expanded(
                        flex: 3,
                        child: Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),

                      // Actions
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Edit
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF4F46E5)),
                              onPressed: () => _editConfig(config),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              style: IconButton.styleFrom(
                                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                              onPressed: () => _deleteConfig(id),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              style: IconButton.styleFrom(
                                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "SECURITY PIN",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "ADMIN ROLE",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "LAST UPDATED",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "ACTIONS",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
