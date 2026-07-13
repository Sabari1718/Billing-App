import 'dart:convert';
import 'package:billingapp/bussinjessscreate/complete%20setup.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BusinessModePage extends StatefulWidget {
  const BusinessModePage({super.key});

  @override
  State<BusinessModePage> createState() => _BusinessModePageState();
}

class _BusinessModePageState extends State<BusinessModePage> {
  List<int> selectedModeIds = [];
  List<dynamic> modes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchModes();
  }

  Future<void> fetchModes() async {
    const url = "https://billing.srivagroups.in/api/businessModules/modules";
    debugPrint("🚀 [fetchModes] START: $url");

    try {
      // 🔑 GET TOKEN
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      debugPrint("🔑 TOKEN: $token");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("📥 [fetchModes] STATUS: ${response.statusCode}");
      debugPrint("📥 [fetchModes] RAW BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        debugPrint("📥 [fetchModes] DECODED TYPE: ${decoded.runtimeType}");

        List<dynamic> parsedList = [];

        // 🔄 HANDLE DIFFERENT RESPONSE FORMATS (List, {data:[]}, {modules:[]})
        if (decoded is List) {
          parsedList = decoded;
        } else if (decoded is Map) {
          parsedList = decoded['data'] ?? decoded['modules'] ?? decoded['list'] ?? [];
        }

        debugPrint("✅ [fetchModes] FINAL LIST COUNT: ${parsedList.length}");

        if (mounted) {
          setState(() {
            modes = parsedList;
            isLoading = false;
          });
        }
      } else {
        debugPrint("❌ [fetchModes] SERVER ERROR: ${response.statusCode}");
        if (mounted) {
          setState(() {
            modes = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("🚨 [fetchModes] CRITICAL ERROR: $e");
      if (mounted) {
        setState(() {
          modes = [];
          isLoading = false;
        });
      }
    }
  }

  void toggleSelection(int modeId) {
    setState(() {
      if (selectedModeIds.contains(modeId)) {
        selectedModeIds.remove(modeId);
      } else {
        selectedModeIds.add(modeId);
      }
    });
  }

  Widget buildCard(int modeId, String title, IconData icon) {
    final isSelected = selectedModeIds.contains(modeId);

    return GestureDetector(
      onTap: () => toggleSelection(modeId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary, size: 28)
            else
              Icon(Icons.circle_outlined,
                  color: Colors.grey.shade300, size: 28),
          ],
        ),
      ),
    );
  }

  IconData getIcon(String key) {
    switch (key.toLowerCase()) {
      case "sale":
        return Icons.shopping_cart_outlined;
      case "service":
        return Icons.build_outlined;
      default:
        return Icons.business_center_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar:
      AppBar(title: const Text("Select Business Mode"), elevation: 0),
      body: Column(
        children: [
          const SizedBox(height: 24),

          /// 🔥 API DATA RENDER
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (modes.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  "No Data Found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: modes.map((mode) {
                  // 🛡️ SAFE ID/KEY/NAME HANDLING
                  final id = int.tryParse(mode['id']?.toString() ?? "0") ?? 0;
                  final key = (mode is Map && mode['key'] != null)
                      ? mode['key'].toString()
                      : (mode is Map && mode['name'] != null)
                      ? mode['name'].toString()
                      : "unknown";

                  final name = (mode is Map && mode['name'] != null)
                      ? mode['name'].toString()
                      : "Unknown";

                  return buildCard(
                    id,
                    name,
                    getIcon(key),
                  );
                }).toList(),
              ),
            ),

          /// 🔻 BOTTOM BUTTON
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: selectedModeIds.isEmpty
                    ? null
                    : () {
                  debugPrint("🚀 Selected Mode IDs: $selectedModeIds");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ModuleSelectionPage(selectedModeIds: selectedModeIds),
                    ),
                  );
                },
                child: const Text("Next Step",
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}