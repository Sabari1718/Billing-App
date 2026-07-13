import 'package:billingapp/Auth/api service.dart';
import 'package:billingapp/bussinjessscreate/shop%20select.dart';
import 'package:flutter/material.dart';
import 'package:billingapp/utils/app_logger.dart';

class StorageTypePage extends StatefulWidget {
  final int brandId;
  final String brandName; // ✅ FIX ADDED

  const StorageTypePage({
    super.key,
    required this.brandId,
    required this.brandName, // ✅ FIX
  });

  @override
  State<StorageTypePage> createState() => _StorageTypePageState();
}

class _StorageTypePageState extends State<StorageTypePage> {
  late Future<List<Map<String, dynamic>>> storageFuture;

  List<int> selectedIds = [];

  @override
  void initState() {
    super.initState();

    AppLogger.info("Loading storage types for brand");

    storageFuture = ApiService.getStorageTypes();
  }

  void toggleSelect(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void selectAll(List data) {
    setState(() {
      selectedIds =
          data.map<int>((e) => (e['id'] ?? e['storage_id'] ?? 0) as int).toList();
    });
  }

  void removeAll() {
    setState(() {
      selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text("Storage - ${widget.brandName}"), // ✅ SHOW NAME
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: storageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storage, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("No storage types found", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => selectAll(data),
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text("Select All"),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: removeAll,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text("Remove All"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// GRID
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: data.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final id = (item['id'] ?? item['storage_id'] ?? 0) as int;
                    final name = (item['name'] ?? item['storage_name'] ?? "No Name").toString();
                    final isSelected = selectedIds.contains(id);

                    return GestureDetector(
                      onTap: () => toggleSelect(id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.inventory_2_outlined,
                              size: 32,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
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

              /// SAVE BUTTON
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: selectedIds.isEmpty
                        ? null
                        : () {
                            AppLogger.info("Selected ${selectedIds.length} storage types");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SelectShopPage(), // 👈 navigate here
                              ),
                            );
                          },
                    child: Text("Select Shops (${selectedIds.length})", style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}