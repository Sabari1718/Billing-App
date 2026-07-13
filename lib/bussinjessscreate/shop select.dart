import 'package:billingapp/Auth/api%20service.dart';
import 'package:billingapp/bussinjessscreate/mode.dart';
import 'package:flutter/material.dart';
import 'package:billingapp/utils/app_logger.dart';


class SelectShopPage extends StatefulWidget {
  @override
  State<SelectShopPage> createState() => _SelectShopPageState();
}

class _SelectShopPageState extends State<SelectShopPage> {
  List<ShopType> shopTypes = [];
  List<int> selectedIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    try {
      final data = await ApiService.getShopTypes(); // ✅ FIXED
      setState(() {
        shopTypes = data.cast<ShopType>();
        isLoading = false;
      });
    } catch (e) {
      AppLogger.error("loadData error", e);
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleSelection(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void goNext() {
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least one shop")),
      );
      return;
    }

    AppLogger.info("Selected ${selectedIds.length} shops");


    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>BusinessModePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: const Text("Select Shop"), elevation: 0),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: shopTypes.length,
              itemBuilder: (context, index) {
                final item = shopTypes[index];
                final isSelected = selectedIds.contains(item.id);

                return GestureDetector(
                  onTap: () => toggleSelection(item.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.store_outlined,
                            size: 28,
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              item.name,
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
                  ),
                );
              },
            ),
          ),

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
                onPressed: goNext,
                child: const Text("Save & Continue", style: TextStyle(fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ShopType {
  final int id;
  final String name;

  ShopType({required this.id, required this.name});

  factory ShopType.fromJson(Map<String, dynamic> json) {
    return ShopType(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? "",
    );
  }
}