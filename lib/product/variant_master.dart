import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'variant_master_controller.dart';
part 'variant_master_widgets.dart';

class VariantMasterPage extends StatelessWidget {
  const VariantMasterPage({super.key});

  void _showVariantDialog(BuildContext context, VariantMasterController controller, {Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? existing?['variant_name']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Edit Variant Type' : 'Add New Variant Type', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Variant Name',
            hintText: 'e.g. Original, Imported',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              if (isEdit) {
                controller.updateVariant(existing['id'] as int, name);
              } else {
                controller.createVariant(name);
              }
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          )
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String title, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete $title?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantListTab(BuildContext context, VariantMasterController controller) {
    if (controller.isLoadingVariants.value) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    if (controller.variantTypes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(children: [
          Icon(Icons.label_off_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No variant types found', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ]),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.8,
          ),
          itemCount: controller.variantTypes.length,
          itemBuilder: (context, index) {
            final item = controller.variantTypes[index];
            final name = (item['name'] ?? item['variant_name'] ?? '').toString();
            final id = item['id'] as int;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                  onPressed: () => _showVariantDialog(context, controller, existing: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                  onPressed: () => _showDeleteDialog(context, 'Variant', () => controller.deleteVariant(id)),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _buildProductVariantsTab(BuildContext context, VariantMasterController controller) {
    if (controller.isLoadingAllocations.value || controller.isLoadingProducts.value || controller.isLoadingVariants.value) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    final selectedProductId = controller.selectedProductIdForVariants.value;
    final matchProd = controller.products.firstWhereOrNull((p) => p['id']?.toString() == selectedProductId);
    final selectedProductName = matchProd != null ? (matchProd['name']?.toString() ?? '') : '';

    // Filter allocations for table at the bottom
    final filtered = selectedProductId == null
        ? controller.allocations
        : controller.allocations.where((a) => a['product_id']?.toString() == selectedProductId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Product selector + Add Variant Button
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedProductId,
                    hint: const Text('Choose Product'),
                    items: controller.products.map<DropdownMenuItem<String>>((p) {
                      return DropdownMenuItem<String>(
                        value: p['id']?.toString(),
                        child: Text(p['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        controller.selectedProductIdForVariants.value = val;
                        controller.updateConfigMapping(val);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showVariantDialog(context, controller),
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF4F46E5)),
              label: const Text('Add Variant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEEF2FF),
                foregroundColor: const Color(0xFF4F46E5),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (selectedProductId == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Please choose a product to manage variant allocations',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Select Variants Heading
          Row(
            children: [
              const Text(
                'Select Variants',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Check a variant to set its stock range',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Variants Grid
          if (controller.variantTypes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('No variants found. Please add a variant first.', style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 800 ? 3 : (width > 480 ? 2 : 1);
                final childAspectRatio = width > 800 ? 3.0 : (width > 480 ? 3.5 : 4.5);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: controller.variantTypes.length,
                  itemBuilder: (context, index) {
                    final v = controller.variantTypes[index];
                    final vName = (v['name'] ?? v['variant_name'] ?? '').toString();
                    final vId = v['id'] as int;

                    final config = controller.selectedVariantConfigs[vName] ?? {
                      'checked': false,
                      'minStock': '0',
                      'maxStock': '999',
                      'warrantyEnabled': false,
                      'warrantyDuration': '1',
                      'warrantyUnit': 'Months',
                      'guaranteeEnabled': false,
                      'guaranteeDuration': '1',
                      'guaranteeUnit': 'Months',
                    };

                    final isChecked = config['checked'] == true;
                    final isActive = controller.activeConfigVariant.value == vName;

                    return GestureDetector(
                      onTap: () {
                        if (!isChecked) {
                          config['checked'] = true;
                          controller.selectedVariantConfigs[vName] = Map<String, dynamic>.from(config);
                        }
                        controller.activeConfigVariant.value = vName;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF2563EB)
                                : isChecked
                                    ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                                    : Colors.grey.shade200,
                            width: isActive ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (val) {
                                config['checked'] = val == true;
                                controller.selectedVariantConfigs[vName] = Map<String, dynamic>.from(config);
                                if (val == true) {
                                  controller.activeConfigVariant.value = vName;
                                } else {
                                  if (controller.activeConfigVariant.value == vName) {
                                    controller.activeConfigVariant.value = null;
                                  }
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                vName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isChecked ? const Color(0xFF1E293B) : Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 16),
                              onPressed: () => _showVariantDialog(context, controller, existing: v),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                              onPressed: () => _showDeleteDialog(context, 'Variant', () => controller.deleteVariant(vId)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

          // Active variant settings panel
          Obx(() {
            final activeName = controller.activeConfigVariant.value;
            if (activeName == null) return const SizedBox.shrink();

            final config = controller.selectedVariantConfigs[activeName];
            if (config == null || config['checked'] != true) return const SizedBox.shrink();

            return VariantConfigPanel(
              activeName: activeName,
              config: config,
              onConfigChanged: (updated) {
                controller.selectedVariantConfigs[activeName] = updated;
              },
            );
          }),
          const SizedBox(height: 20),

          // Save Allocations Green Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                controller.saveAllocations();
              },
              icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
              label: const Text('Save Allocations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Saved Variants Table header
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedProductName.isNotEmpty ? 'Saved Variants – $selectedProductName' : 'Saved Variants',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Saved Variants Table
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text('No allocations found for this product', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    DataColumn(label: Text('PRODUCT NAME', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    DataColumn(label: Text('VARIANT', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    DataColumn(label: Text('MIN STOCK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    DataColumn(label: Text('MAX STOCK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    DataColumn(label: Text('WARRANTY', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    DataColumn(label: Text('GUARANTEE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                    DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                  ],
                  rows: filtered.asMap().entries.map<DataRow>((entry) {
                    final idx = entry.key + 1;
                    final item = entry.value;
                    final pId = (item['product_id'] ?? item['productId'])?.toString() ?? '';
                    final matchP = controller.products.firstWhereOrNull((p) => p['id']?.toString() == pId);
                    final pName = matchP != null ? (matchP['name']?.toString() ?? '') : (item['product_name'] ?? item['productName'] ?? '').toString();
                    final variant = (item['variant'] ?? item['variant_name'] ?? '').toString();
                    final minStock = (item['min_qty'] ?? item['min_stock'] ?? item['minStock'] ?? '-').toString();
                    final maxStock = (item['max_qty'] ?? item['max_stock'] ?? item['maxStock'] ?? '-').toString();

                    String warranty = (item['warranty'] ?? '').toString();
                    if (warranty.isEmpty && item['warranty_duration'] != null) {
                      warranty = '${item['warranty_duration']} ${item['warranty_duration_type'] ?? ''}'.trim();
                    }
                    if (warranty.isEmpty) warranty = '-';

                    String guarantee = (item['guarantee'] ?? '').toString();
                    if (guarantee.isEmpty && item['guarantee_duration'] != null) {
                      guarantee = '${item['guarantee_duration']} ${item['guarantee_duration_type'] ?? ''}'.trim();
                    }
                    if (guarantee.isEmpty) guarantee = '-';

                    final id = item['id'] as int;

                    return DataRow(cells: [
                      DataCell(Text(idx.toString())),
                      DataCell(Text(pName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                          child: Text(variant, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                          child: Text(minStock, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
                          child: Text(maxStock, style: const TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      DataCell(
                        warranty != '-'
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                                child: Text(warranty, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 11)),
                              )
                            : const Text('-'),
                      ),
                      DataCell(
                        guarantee != '-'
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFDF2F8), borderRadius: BorderRadius.circular(8)),
                                child: Text(guarantee, style: const TextStyle(color: Color(0xFFDB2777), fontWeight: FontWeight.w600, fontSize: 11)),
                              )
                            : const Text('-'),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                              onPressed: () {
                                controller.selectedProductIdForVariants.value = pId;
                                controller.updateConfigMapping(pId);
                                controller.activeConfigVariant.value = variant;
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                              onPressed: () => _showDeleteDialog(context, 'Allocation', () => controller.deleteAllocation(id)),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VariantMasterController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Variant Master', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100)),
      ),
      body: Obx(() {
        return Stack(children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header & Add button
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Variant Master', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text('Manage product variant types like Original, Import, etc.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ])),
                if (controller.selectedTabIndex.value == 0)
                  ElevatedButton.icon(
                    onPressed: () => _showVariantDialog(context, controller),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'Add New Variant',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ]),
              const SizedBox(height: 20),

              // Tab selector bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectedTabIndex.value = 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: controller.selectedTabIndex.value == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: controller.selectedTabIndex.value == 0
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.label_outline, size: 18, color: controller.selectedTabIndex.value == 0 ? const Color(0xFF4F46E5) : Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text('Variant List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: controller.selectedTabIndex.value == 0 ? const Color(0xFF4F46E5) : Colors.grey.shade600)),
                        ]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectedTabIndex.value = 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: controller.selectedTabIndex.value == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: controller.selectedTabIndex.value == 1
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.inventory_2_outlined, size: 18, color: controller.selectedTabIndex.value == 1 ? const Color(0xFF4F46E5) : Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text('Product Variants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: controller.selectedTabIndex.value == 1 ? const Color(0xFF4F46E5) : Colors.grey.shade600)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // Tab Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: controller.selectedTabIndex.value == 0
                    ? _buildVariantListTab(context, controller)
                    : _buildProductVariantsTab(context, controller),
              ),
            ],
          ),

          // Toast Banner
          if (controller.showBanner.value)
            Positioned(
              top: 16, left: 16, right: 16,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(controller.bannerText.value, style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13))),
                  ]),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}
