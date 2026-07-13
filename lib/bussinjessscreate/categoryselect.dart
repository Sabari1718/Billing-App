import 'package:flutter/material.dart';
import 'package:billingapp/Auth/api service.dart';
import 'package:billingapp/models/category grou0p.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'brand.dart';

class CategoryGroupPage extends StatefulWidget {
  const CategoryGroupPage({super.key});

  @override
  State<CategoryGroupPage> createState() => _CategoryGroupPageState();
}

class _CategoryGroupPageState extends State<CategoryGroupPage> {
  List<CategoryGroup> categories = [];
  bool isLoading = true;
  List<CategoryGroup> selectedGroups = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  /// ✅ FETCH CATEGORY GROUPS (FINAL FIX)
  Future<void> fetchCategories() async {
    try {
      final res = await ApiService.getCategoryGroups();

      setState(() {
        categories = res;
        isLoading = false;
      });

      AppLogger.success("Loaded ${categories.length} category groups");
    } catch (e) {
      AppLogger.error("fetchCategories error", e);
      setState(() => isLoading = false);
    }
  }

  void selectAll() {
    setState(() {
      selectedGroups = List.from(categories);
    });
  }

  void removeAll() {
    setState(() {
      selectedGroups.clear();
    });
  }

  /// ✅ NAVIGATE TO PRIMARY
  void goToPrimary() async {
    if (selectedGroups.isEmpty) return;

    final categoryIds = selectedGroups.map((e) => e.id).join(',');
    if (categoryIds.isEmpty) return;

    try {
      final res = await ApiService.getBrands(
        categoryGroupId: categoryIds,
      );

      final data = res['data'] ?? [];

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No data found")),
        );
        return;
      }


      final Map<int, Map<String,dynamic>> uniquePrimary = {};
      final Map<int, Map<String,dynamic>> uniqueSecondary = {};

      if (data is List) {
        for (var group in data) {
           if (group is Map<String, dynamic>) {
              final primaries = group['primary_categories'] ?? [];
              for (var p in primaries) {
                 final pType = (p['category_type'] ?? p['type'] ?? p['status'] ?? '').toString().toUpperCase();
                 
                 // If the item itself is primary, add to primary
                 if (pType == 'PRIMARY' || pType == '1' || pType.isEmpty) {
                   if (p['id'] != null) {
                     uniquePrimary[p['id']] = Map<String,dynamic>.from(p);
                   }
                 } else if (pType == 'SECONDARY' || pType == '2') {
                   if (p['id'] != null) {
                     uniqueSecondary[p['id']] = Map<String,dynamic>.from(p);
                   }
                 }

                 final secondaries = p['secondary_categories'] ?? [];
                 for (var s in secondaries) {
                    final sType = (s['category_type'] ?? s['type'] ?? s['status'] ?? '').toString().toUpperCase();
                    
                    if (sType == 'SECONDARY' || sType == '2' || sType.isEmpty) {
                      if (s['id'] != null) {
                        uniqueSecondary[s['id']] = Map<String,dynamic>.from(s);
                      }
                    } else if (sType == 'PRIMARY' || sType == '1') {
                      if (s['id'] != null) {
                        uniquePrimary[s['id']] = Map<String,dynamic>.from(s);
                      }
                    }
                 }
              }
           }
        }
      }

      AppLogger.info("Categorized Data Verification -> Primary: ${uniquePrimary.length}, Secondary: ${uniqueSecondary.length}");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrimaryCategoryPage(
            primaryList: uniquePrimary.values.toList(),
            secondaryList: uniqueSecondary.values.toList(),
            categoryGroupIds: categoryIds,
          ),
        ),
      );
    } catch (e) {
      AppLogger.error("goToPrimary error", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Category Groups"),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? const Center(child: Text("No Categories Found", style: TextStyle(fontSize: 16, color: Colors.grey)))
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectAll,
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
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final item = categories[index];
                final isSelected = selectedGroups.any((e) => e.id == item.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedGroups.removeWhere((e) => e.id == item.id);
                      } else {
                        selectedGroups.add(item);
                      }
                    });
                  },
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
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.category_outlined,
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
          if (selectedGroups.isNotEmpty)
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
                  onPressed: goToPrimary,
                  child: Text("Proceed to Next Step (${selectedGroups.length})", style: const TextStyle(fontSize: 16)),
                ),
              ),
            )
        ],
      ),
    );
  }
}

//// ================= PRIMARY CATEGORY PAGE =================

class PrimaryCategoryPage extends StatefulWidget {
  final List primaryList;
  final List secondaryList;
  final dynamic categoryGroupIds;

  const PrimaryCategoryPage({
    super.key,
    required this.primaryList,
    required this.secondaryList,
    required this.categoryGroupIds,
  });

  @override
  State<PrimaryCategoryPage> createState() => _PrimaryCategoryPageState();
}

class _PrimaryCategoryPageState extends State<PrimaryCategoryPage> {
  List selectedPrimaryList = [];
  List selectedSecondaryList = [];

  String activeTab = "primary";
  String search = "";

  void togglePrimary(Map item) {
    setState(() {
      final exists = selectedPrimaryList.any((e) => e['id'] == item['id']);
      if (exists) {
        selectedPrimaryList.removeWhere((e) => e['id'] == item['id']);
      } else {
        selectedPrimaryList.add(item);
      }
    });
  }

  void toggleSecondary(Map item) {
    setState(() {
      final exists = selectedSecondaryList.any((e) => e['id'] == item['id']);
      if (exists) {
        selectedSecondaryList.removeWhere((e) => e['id'] == item['id']);
      } else {
        selectedSecondaryList.add(item);
      }
    });
  }

  void selectAll() {
    setState(() {
      if (activeTab == "primary") {
        final filtered = filterList(widget.primaryList);
        for (var item in filtered) {
           if (!selectedPrimaryList.any((e) => e['id'] == item['id'])) {
             selectedPrimaryList.add(item);
           }
        }
      } else {
        final filtered = filterList(widget.secondaryList);
        for (var item in filtered) {
           if (!selectedSecondaryList.any((e) => e['id'] == item['id'])) {
             selectedSecondaryList.add(item);
           }
        }
      }
    });
  }

  void removeAll() {
    setState(() {
      if (activeTab == "primary") {
        final filtered = filterList(widget.primaryList);
        for (var item in filtered) {
           selectedPrimaryList.removeWhere((e) => e['id'] == item['id']);
        }
      } else {
        final filtered = filterList(widget.secondaryList);
        for (var item in filtered) {
           selectedSecondaryList.removeWhere((e) => e['id'] == item['id']);
        }
      }
    });
  }

  List filterList(List list) {
    if (search.isEmpty) return list;
    return list.where((e) {
      return (e['name'] ?? "").toString().toLowerCase().contains(search.toLowerCase());
    }).toList();
  }

  void goToBrand() {
    if (selectedPrimaryList.isEmpty && selectedSecondaryList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one category")),
      );
      return;
    }

    final primaryIds = selectedPrimaryList
        .map((e) => int.tryParse(e['id'].toString()) ?? 0)
        .toList();

    final secondaryIds = selectedSecondaryList
        .map((e) => int.tryParse(e['id'].toString()) ?? 0)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrandScreen(
          categoryGroupId: widget.categoryGroupIds,
          primaryCategoryIds: primaryIds,
          secondaryCategoryIds: secondaryIds,
        ),
      ),
    );
  }

  Widget tabButton(String type) {
    bool isActive = activeTab == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).colorScheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
            boxShadow: [
              if (isActive)
                BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: Text(
              type == "primary" ? "Primary Categories" : "Secondary Categories",
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List currentList = activeTab == "primary" ? widget.primaryList : widget.secondaryList;
    List filteredList = filterList(currentList);
    List selectedList = activeTab == "primary" ? selectedPrimaryList : selectedSecondaryList;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Select Categories"),
        elevation: 0,
      ),
      body: Column(
        children: [
          /// SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Search categories...",
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          /// TABS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                tabButton("primary"),
                const SizedBox(width: 16),
                tabButton("secondary"),
              ],
            ),
          ),

          /// SELECT ALL / REMOVE ALL
          if (filteredList.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: selectAll,
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

          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text("No Data Found", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isSelected = selectedList.any((e) => e['id'] == item['id']);

                      return GestureDetector(
                        onTap: () {
                          if (activeTab == "primary") {
                            togglePrimary(item);
                          } else {
                            toggleSecondary(item);
                          }
                        },
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
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle : Icons.inventory_2_outlined,
                                  size: 28,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    item['name']?.toString() ?? '',
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

          /// ✅ NEXT BUTTON
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
                onPressed: (selectedPrimaryList.isEmpty && selectedSecondaryList.isEmpty) ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one category")));
                } : goToBrand,
                child: Text("Select Brands (${selectedPrimaryList.length + selectedSecondaryList.length})", style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}