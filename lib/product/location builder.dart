import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:billingapp/utils/app_logger.dart';

class LocationBuilderPage extends StatefulWidget {
  final String? token;
  final int? storageTypeId;

  const LocationBuilderPage({
    super.key,
    required this.token,
    this.storageTypeId,
  });

  @override
  State<LocationBuilderPage> createState() => _LocationBuilderPageState();
}

class _LocationBuilderPageState extends State<LocationBuilderPage> {
  List<dynamic> hierarchy = [];
  List<dynamic> levels = [];
  bool isLoading = true;
  Set<int> expandedIds = {};

  final String baseUrlAction = "https://billing.srivagroups.in/api/storage/location";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await fetchStructure();
    await fetchLocations();
  }

  Future<void> fetchStructure() async {
    try {
      final String structureUrl = "https://billing.srivagroups.in/api/storage/structure/${widget.storageTypeId}";
      final res = await http.get(Uri.parse(structureUrl), headers: headers);
      final decoded = json.decode(res.body);
      if (decoded['success'] == true) {
        final List data = decoded['data'] ?? [];
        data.sort((a, b) => (a['level_order'] ?? 0).compareTo(b['level_order'] ?? 0));
        setState(() {
          levels = data;
        });
      }
    } catch (e) {
      AppLogger.error("fetchStructure error", e);
    }
  }

  Map<String, String> get headers => {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
      };

  Future<void> fetchLocations() async {
    setState(() => isLoading = true);
    try {
      final String fetchUrl = "https://billing.srivagroups.in/api/storage/locations/${widget.storageTypeId}";
      final res = await http.get(Uri.parse(fetchUrl), headers: headers);
      AppLogger.api("GET", fetchUrl, res.statusCode);
      final decoded = json.decode(res.body);
      List<dynamic> fetchedData = [];
      if (decoded is Map) {
        fetchedData = decoded['data'] ?? decoded['locations'] ?? decoded['hierarchy'] ?? [];
      } else if (decoded is List) {
        fetchedData = decoded;
      }
      bool isNested = fetchedData.any((item) => item is Map && item['children'] != null && (item['children'] as List).isNotEmpty);
      if (isNested) {
        setState(() => hierarchy = fetchedData);
      } else {
        _buildHierarchy(fetchedData);
      }
    } catch (e) {
      AppLogger.error("fetchLocations error", e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _buildHierarchy(List<dynamic> flatList) {
    Map<int, List<dynamic>> childrenMap = {};
    List<dynamic> roots = [];
    for (var loc in flatList) {
      int? pid = loc['parent_id'];
      if (pid == null) roots.add(loc);
      else childrenMap.putIfAbsent(pid, () => []).add(loc);
    }
    void assignChildren(List<dynamic> nodes) {
      for (var node in nodes) {
        node['children'] = childrenMap[node['id']] ?? [];
        assignChildren(node['children']);
      }
    }
    assignChildren(roots);
    setState(() => hierarchy = roots);
  }

  String getLevelName(int level) {
    if (levels.isNotEmpty && level >= 1 && level <= levels.length) {
      return levels[level - 1]['name'].toString().toUpperCase();
    }
    const names = ["Building", "Floor", "Room", "Shelf", "Rack", "Container", "Box"];
    if (level >= 1 && level <= names.length) return names[level - 1];
    return "Item";
  }

  Future<void> _handleAction(String type, {int? id, int? parentId, int? level, String? initialName}) async {
    final controller = TextEditingController(text: initialName);
    final String levelName = getLevelName(level ?? 1);
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("$type $levelName"),
        content: type == "Delete"
            ? Text("Are you sure you want to delete this $levelName and all its contents?")
            : TextField(
                controller: controller,
                decoration: InputDecoration(labelText: "$levelName Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                autofocus: true,
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: type == "Delete" ? Colors.red : Colors.blue, foregroundColor: Colors.white),
            child: Text(type),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => isLoading = true);
    try {
      http.Response res;
      final String actionUrl = type == "Add" ? baseUrlAction : "$baseUrlAction/$id";
      AppLogger.info("Location action: $type ($actionUrl)");

      if (type == "Add") {
        final int? levelRecordId = (levels.isNotEmpty && level! >= 1 && level <= levels.length) ? levels[level - 1]['id'] : null;
        final body = {
          "storage_type_id": widget.storageTypeId,
          "parent_id": parentId,
          "name": controller.text.trim(),
          "level_id": levelRecordId
        };
        res = await http.post(Uri.parse(actionUrl), headers: headers, body: jsonEncode(body));
      } else if (type == "Update") {
        final body = {"name": controller.text.trim()};
        res = await http.put(Uri.parse(actionUrl), headers: headers, body: jsonEncode(body));
      } else {
        res = await http.delete(Uri.parse(actionUrl), headers: headers);
      }

      AppLogger.api(type == "Add" ? "POST" : (type == "Update" ? "PUT" : "DELETE"), actionUrl, res.statusCode);

      if (res.statusCode == 200 || res.statusCode == 201) {
        AppLogger.success("Location $type successful");
        fetchLocations();
      }
    } catch (e) {
      AppLogger.error("Location action error", e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _getDisplayName(dynamic item) {
    if (item == null || item is! Map) return "Unnamed";
    final List<String> potentialKeys = ["name", "location_name", "storage_location_name", "storage_name", "label", "title", "text", "item_name", "location"];
    for (var key in potentialKeys) {
      if (item.containsKey(key) && item[key] != null) {
        var value = item[key];
        if (value is Map && value.isNotEmpty) {
          var firstVal = value.values.first;
          if (firstVal != null && firstVal.toString().trim().isNotEmpty) return firstVal.toString();
        }
        if (value.toString().trim().isNotEmpty) return value.toString();
      }
    }
    if (item['id'] != null) return "Item #${item['id']}";
    return "No Name Specified";
  }

  Widget _buildEmptyState(int? parentId, int level) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Text("No ${getLevelName(level)} items added yet", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _handleAction("Add", parentId: parentId, level: level),
            icon: const Icon(Icons.add, size: 16),
            label: Text("Add First ${getLevelName(level)}"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue.shade700, elevation: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(Map<String, dynamic> item, int level) {
    bool isExpanded = expandedIds.contains(item['id']);
    List children = item['children'] ?? [];
    String levelName = getLevelName(level);
    return Container(
      key: ValueKey(item['id']),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => isExpanded ? expandedIds.remove(item['id']) : expandedIds.add(item['id'])),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Container(
                    height: 28, width: 28,
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                    child: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF64748B), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getDisplayName(item), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis, maxLines: 1),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                          child: Text("${levelName[0]}${item['id']} • $levelName", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionIcon(Icons.edit_outlined, const Color(0xFF64748B), const Color(0xFFF1F5F9), () => _handleAction("Update", id: item['id'], level: level, initialName: _getDisplayName(item))),
                      const SizedBox(width: 6),
                      if (levels.isEmpty || level < levels.length) ...[
                        _actionIcon(Icons.add, Colors.white, Colors.blue, () => _handleAction("Add", parentId: item['id'], level: level + 1)),
                        const SizedBox(width: 6),
                      ],
                      _actionIcon(Icons.delete_outline, const Color(0xFFEF4444), const Color(0xFFFEF2F2), () => _handleAction("Delete", id: item['id'], level: level)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 0, 4, 10),
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFF1F5F9), width: 1.5))),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  if (children.isEmpty) _buildEmptyState(item['id'], level + 1) else ...children.map((c) => _buildNode(Map<String, dynamic>.from(c), level + 1)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        title: const Text("Location Builder", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)), onPressed: fetchLocations)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchLocations,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Hierarchy List", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ElevatedButton.icon(
                        onPressed: () => _handleAction("Add", parentId: null, level: 1),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add Building"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (hierarchy.isEmpty) _buildEmptyState(null, 1) else ...hierarchy.map((node) => _buildNode(Map<String, dynamic>.from(node), 1)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}