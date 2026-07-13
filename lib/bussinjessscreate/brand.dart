import 'package:billingapp/bussinjessscreate/storage.dart';
import 'package:flutter/material.dart';
import 'package:billingapp/Auth/api service.dart';
import 'package:billingapp/utils/app_logger.dart';

class BrandScreen extends StatefulWidget {
  final dynamic categoryGroupId;
  final List<int> primaryCategoryIds;
  final List<int> secondaryCategoryIds;

  const BrandScreen({
    super.key,
    required this.categoryGroupId,
    required this.primaryCategoryIds,
    this.secondaryCategoryIds = const [],
  });

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  Map<String, List<Map<String, dynamic>>> primaryGrouped = {};
  Map<String, Map<String, List<Map<String, dynamic>>>> secondaryGrouped = {};

  List<int> selectedBrandIds = []; // ✅ SELECT

  String search = "";
  String activeTab = "primary";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final res = await ApiService.getBrands(
        categoryGroupId: widget.categoryGroupId,
      );

      final data = res['data'];

      if (data == null || data.isEmpty) {
        setState(() => loading = false);
        return;
      }

      final primaryList = data[0]['primary_categories'] ?? [];

      Map<String, List<Map<String, dynamic>>> tempPrimary = {};
      Map<String, Map<String, List<Map<String, dynamic>>>> tempSecondary = {};

      for (var primary in primaryList) {
        final primaryId = primary['id'];

        bool primarySelected = widget.primaryCategoryIds.contains(primaryId);
        bool hasSelectedSecondary = false;

        if (widget.secondaryCategoryIds.isNotEmpty) {
           for (var sec in (primary['secondary_categories'] ?? [])) {
              if (widget.secondaryCategoryIds.contains(sec['id'])) {
                 hasSelectedSecondary = true;
                 break;
              }
           }
        }

        if (!primarySelected && !hasSelectedSecondary) continue;

        final primaryName = primary['name'] ?? "Unknown";

        if (primarySelected) {
          tempPrimary[primaryName] = List<Map<String, dynamic>>.from(
            (primary['brands'] ?? []).map((e) => Map<String, dynamic>.from(e)),
          );
        }

        Map<String, List<Map<String, dynamic>>> secMap = {};

        for (var sec in (primary['secondary_categories'] ?? [])) {
          final secId = sec['id'];
          if (primarySelected || widget.secondaryCategoryIds.contains(secId)) {
            final secName = sec['name'] ?? "Unknown";

            secMap[secName] = List<Map<String, dynamic>>.from(
              (sec['brands'] ?? []).map((e) => Map<String, dynamic>.from(e)),
            );
          }
        }

        if (secMap.isNotEmpty) {
           tempSecondary[primaryName] = secMap;
        }
      }

      setState(() {
        primaryGrouped = tempPrimary;
        secondaryGrouped = tempSecondary;
        loading = false;
      });

      AppLogger.success("Brands loaded successfully");
    } catch (e) {
      AppLogger.error("loadData error", e);
      setState(() => loading = false);
    }
  }

  /// ✅ SELECT / REMOVE
  void toggleBrand(int id) {
    setState(() {
      if (selectedBrandIds.contains(id)) {
        selectedBrandIds.remove(id);
      } else {
        selectedBrandIds.add(id);
      }
    });
  }

  /// ✅ NEXT
  void goToStorage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StorageTypePage(
          brandId: selectedBrandIds.first,
          brandName: "Selected Brands",
        ),
      ),
    );
  }

  List<Map<String, dynamic>> filter(List<Map<String, dynamic>> list) {
    if (search.isEmpty) return list;

    return list.where((e) {
      return (e['name'] ?? "")
          .toString()
          .toLowerCase()
          .contains(search.toLowerCase());
    }).toList();
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
              type == "primary" ? "Primary Brands" : "Secondary Brands",
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: const Text("Select Brands"), elevation: 0),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          /// SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Search brands...",
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

          /// LIST
          Expanded(
            child: activeTab == "primary"
                ? buildPrimaryUI()
                : buildSecondaryUI(),
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
                onPressed: selectedBrandIds.isEmpty ? null : goToStorage,
                child: Text("Select Storage Type (${selectedBrandIds.length})", style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandGrid(List<Map<String, dynamic>> brands) {
    if (brands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text("No brands found", style: TextStyle(color: Colors.grey.shade500))),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: brands.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final item = brands[index];
        final id = item['id'] ?? 0;
        final isSelected = selectedBrandIds.contains(id);

        return GestureDetector(
          onTap: () => toggleBrand(id),
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
                    isSelected ? Icons.check_circle : Icons.branding_watermark_outlined,
                    size: 28,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      (item['name'] ?? "No Name").toString(),
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
    );
  }

  Widget buildPrimaryUI() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: primaryGrouped.entries.map((entry) {
        final brands = filter(entry.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (brands.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              ),
            _buildBrandGrid(brands)
          ],
        );
      }).toList(),
    );
  }

  Widget buildSecondaryUI() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: secondaryGrouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entry.value.entries.map((sec) {
            final brands = filter(sec.value);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 if (brands.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text("${entry.key} > ${sec.key}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                  ),
                 _buildBrandGrid(brands),
              ],
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}