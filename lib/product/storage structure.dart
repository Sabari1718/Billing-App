import 'dart:convert';
import 'package:billingapp/product/location%20builder.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StructurePage extends StatefulWidget {
  final String token;
  final int storageTypeId;

  const StructurePage({
    super.key,
    required this.token,
    required this.storageTypeId,
  });

  @override
  State<StructurePage> createState() => _StructurePageState();
}

class _StructurePageState extends State<StructurePage> {
  final TextEditingController controller = TextEditingController();

  List structures = [];
  bool isLoading = false;

  String partitionType = "rows";

  @override
  void initState() {
    super.initState();
    fetchStructures();
  }

  @override
  void dispose() {
    controller.dispose(); // ✅ memory leak fix
    super.dispose();
  }

  void log(String msg) {
    debugPrint("🧩 StructurePage => $msg");
  }

  Map<String, String> get headers => {
    "Authorization": "Bearer ${widget.token}",
    "Accept": "application/json",
    "Content-Type": "application/json",
  };

  Future<void> fetchStructures() async {
    log("Fetching structures...");

    setState(() => isLoading = true);

    try {
      final url =
          "https://billing.srivagroups.in/api/storage/structure/${widget.storageTypeId}";
      log("GET URL: $url");

      final res = await http.get(Uri.parse(url), headers: headers);

      log("STATUS: ${res.statusCode}");
      log("BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        
        // Handle both direct list and {data: []} patterns
        List fetchedData = [];
        if (decoded is List) {
          fetchedData = decoded;
        } else if (decoded is Map) {
          fetchedData = decoded['data'] ?? [];
        }

        log("Total structures: ${fetchedData.length}");

        fetchedData.sort((a, b) =>
            (a['level_order'] ?? 0).compareTo(b['level_order'] ?? 0));

        setState(() {
          structures = fetchedData;
          isLoading = false;
        });
      } else {
        log("❌ FETCH FAILED");
        setState(() => isLoading = false);
      }
    } catch (e) {
      log("❌ FETCH ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> addStructure() async {
    if (controller.text.trim().isEmpty) {
      log("⚠️ Empty input");
      return;
    }

    final body = {
      "storage_type_id": widget.storageTypeId,
      "name": controller.text.trim(),
      "level_order": structures.length + 1,
      "parent_id": null,
      "is_partitionable": partitionType == "columns",
    };

    log("POST BODY: ${jsonEncode(body)}");

    try {
      final res = await http.post(
        Uri.parse("https://billing.srivagroups.in/api/storage/structure"),
        headers: headers,
        body: jsonEncode(body),
      );

      log("POST STATUS: ${res.statusCode}");
      log("POST RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['success'] == true) {
          log("✅ Structure added success");

          controller.clear();

          setState(() {
            partitionType = "rows";
          });

          fetchStructures();
        } else {
          log("❌ API ERROR: ${data['message']}");
        }
      }
    } catch (e) {
      log("❌ ADD ERROR: $e");
    }
  }
  Future<void> deleteStructure(int id) async {
    log("Deleting ID: $id");

    try {
      final res = await http.delete(
        Uri.parse("https://billing.srivagroups.in/api/storage/structure/$id"),
        headers: headers,
      );

      log("DELETE STATUS: ${res.statusCode}");

      fetchStructures();
    } catch (e) {
      log("❌ DELETE ERROR: $e");
    }
  }

  Widget buildCard(dynamic item, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "LEVEL ${index + 1}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.edit_outlined,
                        size: 20, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => deleteStructure(item["id"]),
                    child: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item["name"].toString().toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLayout() {
    if (structures.isEmpty) {
      return const Center(child: Text("No Structure Added"));
    }

    if (partitionType == "rows") {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(structures.length, (index) {
          final item = structures[index];

          return SizedBox(
            width: (MediaQuery.of(context).size.width - 48) / 2, // ✅ FIXED
            child: buildCard(item, index),
          );
        }),
      );
    } else {
      return Column(
        children: List.generate(structures.length, (index) {
          final item = structures[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: buildCard(item, index),
          );
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Structure Design"),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Design Hierarchy",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Define levels and partitions for this storage.",
                    style:
                    TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText:
                            "Enter level name (e.g., Rack)",
                            labelText: "Level Name",
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text("Rows"),
                                Switch(
                                  value:
                                  partitionType == "columns",
                                  onChanged: (val) {
                                    setState(() {
                                      partitionType = val
                                          ? "columns"
                                          : "rows";
                                    });
                                  },
                                ),
                                const Text("Columns"),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: addStructure,
                              icon: const Icon(Icons.add),
                              label: const Text("Add Level"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  buildLayout(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Previous Step"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                      onPressed: structures.isEmpty
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationBuilderPage(
                            token: widget.token,
                            storageTypeId: widget.storageTypeId,
                          ),
                        ),
                      );
                    },
                    child: const Text("Next Step"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}