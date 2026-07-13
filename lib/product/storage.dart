import 'dart:convert';
import 'package:billingapp/product/storage%20structure.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  List storageList = [];
  bool isLoading = true;
  String? error;
  int? selectedIndex;

  String token = "";

  @override
  void initState() {
    super.initState();
    loadTokenAndFetch();
  }

  Future<void> loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();

    /// ✅ FIXED TOKEN KEY
    token = prefs.getString("token") ?? "";

    AppLogger.info("Token loaded for storage");

    fetchStorage();
  }

  Future<void> fetchStorage() async {
    try {
      final response = await http.get(
        Uri.parse("https://billing.srivagroups.in/api/storage/types"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      AppLogger.api("GET", "https://billing.srivagroups.in/api/storage/types", response.statusCode);

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded["success"] == true) {
        setState(() {
          storageList = decoded["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = decoded["message"] ?? "Error";
          isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error("fetchStorage error", e);
      setState(() {
        error = "Failed to load data";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Select Storage"),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              "Available Storage Types",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: selectedIndex != null ? 3 : 5,
            child: ListView.builder(
              itemCount: storageList.length,
              itemBuilder: (context, index) {
                final item = storageList[index];
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.storage, color: isSelected ? Colors.white : Colors.grey.shade600),
                        ),
                        title: Text(
                          item["name"] ?? "No Name",
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("Manage storage, levels and items", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (selectedIndex != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          "Selected: ${storageList[selectedIndex!]["name"]}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Setup structure, access levels & parameters.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NextPage(
                                data: storageList[selectedIndex!],
                                token: token, // ✅ PASS TOKEN
                              ),
                            ),
                          );
                        },
                        child: const Text("Open Details", style: TextStyle(fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NextPage extends StatefulWidget {
  final Map data;
  final String token;

  const NextPage({
    super.key,
    required this.data,
    required this.token,
  });

  @override
  State<NextPage> createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  final TextEditingController fieldController = TextEditingController();

  List fields = [];
  List values = [];

  String? selectedInsertAfter;
  Map<String, TextEditingController> valueControllers = {};

  final String baseUrl = "https://billing.srivagroups.in/api";

  @override
  void initState() {
    super.initState();
    fetchFields();
    fetchValues();
  }

  Future<void> fetchFields() async {
    final res = await http.get(
      Uri.parse("$baseUrl/storage/address-fields/${widget.data["id"]}"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
      },
    );

    AppLogger.api("GET", "$baseUrl/storage/address-fields/${widget.data["id"]}", res.statusCode);

    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200 && decoded["success"] == true) {
      final data = decoded["data"];

      setState(() {
        fields = data;

        for (var field in fields) {
          if (!valueControllers.containsKey(field["field_name"])) {
            valueControllers[field["field_name"]] =
                TextEditingController();
          }
        }
      });
    }
  }

  Future<void> addField() async {
    if (fieldController.text.isEmpty) return;

    final res = await http.post(
      Uri.parse("$baseUrl/storage/address-field"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "storage_type_id": widget.data["id"],
        "field_name": fieldController.text,
        "insert_after": selectedInsertAfter ?? "end",
      }),
    );

    AppLogger.api("POST", "$baseUrl/storage/address-field", res.statusCode);

    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200 && decoded["success"] == true) {
      fieldController.clear();
      selectedInsertAfter = null;
      fetchFields();
    }
  }

  Future<void> fetchValues() async {
    final res = await http.get(
      Uri.parse("$baseUrl/storage/address-values/${widget.data["id"]}"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
      },
    );

    AppLogger.api("GET", "$baseUrl/storage/address-values/${widget.data["id"]}", res.statusCode);

    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200 && decoded["success"] == true) {
      setState(() {
        values = decoded["data"];
      });
    }
  }

  Future<void> saveValues() async {
    List<Map<String, String>> fieldsPayload = [];

    valueControllers.forEach((key, controller) {
      fieldsPayload.add({
        "field_name": key,
        "field_value": controller.text,
      });
    });

    final payload = {
      "storage_type_id": widget.data["id"],
      "fields": fieldsPayload,
    };

    final res = await http.post(
      Uri.parse("$baseUrl/storage/address-value"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    AppLogger.api("POST", "$baseUrl/storage/address-value", res.statusCode);

    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200 && decoded["success"] == true) {
      fetchValues();

      valueControllers.forEach((key, controller) {
        controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.data["name"] ?? "Storage Settings"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Fields Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_attributes_outlined, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text("Address Fields",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: fieldController,
                      decoration: const InputDecoration(
                        hintText: "Enter field name (Row, Rack...)",
                        prefixIcon: Icon(Icons.title),
                        labelText: "Field Name",
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: selectedInsertAfter,
                      hint: const Text("Insert Position"),
                      items: [
                        const DropdownMenuItem(
                          value: "end",
                          child: Text("At End"),
                        ),
                        ...fields.map((e) => DropdownMenuItem(
                          value: e["field_name"],
                          child: Text(e["field_name"]),
                        ))
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedInsertAfter = val.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        onPressed: addField,
                        label: const Text("Add Field"),
                      ),
                    ),
                    if (fields.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: fields
                            .map((e) => Chip(
                              label: Text(e["field_name"], style: const TextStyle(fontWeight: FontWeight.w600)),
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              side: BorderSide.none,
                            ))
                            .toList(),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Add Address Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text("Add Address",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (fields.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text("No fields added yet.", style: TextStyle(color: Colors.grey.shade500)),
                        ),
                      )
                    else
                      Column(
                        children: fields.map((field) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: valueControllers[field["field_name"]],
                              decoration: InputDecoration(
                                labelText: field["field_name"],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    
                    if (fields.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: saveValues,
                          child: const Text("Save Address"),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (values.isNotEmpty) ...[
              Text("Saved Addresses",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Column(
                children: values.map((val) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                      title: Text(val.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StructurePage(
                        token: widget.token, // ✅ correct
                        storageTypeId: widget.data["id"], // ✅ correct id
                      ),
                    ),
                  );
                },
                child: Text("Proceed to Structure", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}