import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ModuleSelectionPage extends StatefulWidget {
  final List<int> selectedModeIds;

  const ModuleSelectionPage({super.key, required this.selectedModeIds});

  @override
  _ModuleSelectionPageState createState() => _ModuleSelectionPageState();
}

class _ModuleSelectionPageState extends State<ModuleSelectionPage> {
  List<ModuleItem> modules = [];
  Set<int> selectedModuleIds = {}; // Use Set for multi-select
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 [ModuleSelectionPage] Received IDs: ${widget.selectedModeIds}");
    fetchModulesForAllModes();
  }

  /// ✅ 1. CALL API FOR ALL SELECTED MODE IDs & MERGE
  Future<void> fetchModulesForAllModes() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      };

      List<ModuleItem> mergedModules = [];
      Set<int> uniqueModuleIds = {};

      for (int modeId in widget.selectedModeIds) {
        final url = "https://billing.srivagroups.in/api/businessModules/modules/$modeId/items";
        debugPrint("🌐 FETCHING: $url");

        final response = await http.get(Uri.parse(url), headers: headers);
        debugPrint("📥 STATUS [$modeId]: ${response.statusCode}");
        // debugPrint("📥 BODY [$modeId]: ${response.body}");

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          final List<dynamic> data = decoded['data'] ?? [];

          for (var item in data) {
            final m = ModuleItem.fromJson(item);
            // 🛡️ 3. REMOVE DUPLICATE MODULES
            if (!uniqueModuleIds.contains(m.id)) {
              uniqueModuleIds.add(m.id);
              mergedModules.add(m);
            }
          }
        }
      }

      debugPrint("✅ MERGED MODULE COUNT: ${mergedModules.length}");

      setState(() {
        modules = mergedModules;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("🚨 FETCH ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  /// ✅ TOGGLE MULTIPLE SELECTION
  void toggleSelection(int id) {
    setState(() {
      if (selectedModuleIds.contains(id)) {
        selectedModuleIds.remove(id);
      } else {
        selectedModuleIds.add(id);
      }
    });
    debugPrint("📍 CURRENT SELECTED MODULES: $selectedModuleIds");
  }

  /// ✅ 2. SAVE API CALL
  Future<void> saveSetup() async {
    if (selectedModuleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one module")),
      );
      return;
    }

    setState(() => isLoading = true);

    const url = "https://billing.srivagroups.in/api/setup/full";
    debugPrint("🚀 [SAVE] START: $url");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      
      final payload = {
        "shopTypeIds": [5], // Static as requested
        "moduleIds": selectedModuleIds.toList(), // Dynamic
        "categoryGroupIds": [14], // Static
        "categoryIds": [279], // Static
        "brandIds": [228, 230] // Static
      };

      debugPrint("📤 PAYLOAD: ${json.encode(payload)}");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode(payload),
      );

      debugPrint("📥 SAVE STATUS: ${response.statusCode}");
      debugPrint("📥 SAVE RESPONSE: ${response.body}");

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Setup Completed Successfully"), backgroundColor: Colors.green),
        );
        // Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${response.body}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("🚨 SAVE ERROR: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Critical Error occurred"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Select Modules"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (modules.isEmpty)
                  const Expanded(
                    child: Center(child: Text("No Modules Found", style: TextStyle(fontSize: 16, color: Colors.grey))),
                  )
                else
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: modules.length,
                      itemBuilder: (_, index) {
                        final item = modules[index];
                        final isSelected = selectedModuleIds.contains(item.id);

                        return GestureDetector(
                          onTap: () => toggleSelection(item.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                if (!isSelected)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle : Icons.dashboard_customize_outlined,
                                  size: 32,
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    item.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 14,
                                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                // 🔘 BOTTOM ACTION
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: selectedModuleIds.isEmpty ? null : saveSetup,
                      child: const Text(
                        "Complete Setup",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class ModuleItem {
  final int id;
  final String name;

  ModuleItem({required this.id, required this.name});

  factory ModuleItem.fromJson(Map<String, dynamic> json) {
    return ModuleItem(
      id: int.tryParse(json['module_id']?.toString() ?? json['id']?.toString() ?? "0") ?? 0,
      name: json['name'] ?? json['module_name'] ?? 'Unknown',
    );
  }
}