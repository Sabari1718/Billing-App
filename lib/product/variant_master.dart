import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'variant_master_controller.dart';
part 'variant_master_widgets.dart';

class VariantMasterPage extends StatelessWidget {
  const VariantMasterPage({super.key});

  void _showAddVariantDialog(BuildContext context, VariantMasterController controller) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Add New Variant",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Variant Name",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: "e.g. Original, Imported (HK), Chinese",
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx);
                        controller.createVariant(name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        "Create Variant",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditVariantDialog(
      BuildContext context, VariantMasterController controller, Map<String, dynamic> existing) {
    final nameCtrl = TextEditingController(
      text: existing['name']?.toString() ?? existing['variant_name']?.toString() ?? '',
    );
    final id = existing['id'];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Edit Variant",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Variant Name",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx);
                        controller.updateVariant(id, name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        "Update Variant",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, VariantMasterController controller, Map<String, dynamic> item) {
    final id = item['id'];
    final name = (item['name'] ?? item['variant_name'] ?? 'this variant').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "billing.srivagroups.in says",
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF334155),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteVariant(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5E3A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text(
              "OK",
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E5E3A),
              side: const BorderSide(color: Color(0xFFA7F3D0)),
              backgroundColor: const Color(0xFFDCFCE7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSearchSheet(BuildContext context, VariantMasterController controller) {
    final searchCtrl = TextEditingController();
    final searchFilter = ''.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Choose Product",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  onChanged: (val) => searchFilter.value = val.trim().toLowerCase(),
                  decoration: InputDecoration(
                    hintText: "Search by product name...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    final query = searchFilter.value;
                    final filtered = controller.products.where((p) {
                      final name = (p['name'] ?? '').toString().toLowerCase();
                      return name.contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          "No products found",
                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final p = filtered[idx];
                        final pId = p['id']?.toString() ?? '';
                        final pName = p['name']?.toString() ?? '';
                        final brand = p['brand_name']?.toString() ?? '';
                        final mrp = p['mrp']?.toString() ?? '';
                        final isSelected = controller.selectedProductIdForVariants.value == pId;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFEFF6FF),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDBEAFE),
                            child: Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 18),
                          ),
                          title: Text(
                            pName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: brand.isNotEmpty
                              ? Text(brand, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600))
                              : null,
                          trailing: mrp.isNotEmpty
                              ? Text(
                                  "₹$mrp",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF16A34A),
                                  ),
                                )
                              : null,
                          onTap: () {
                            controller.selectedProductIdForVariants.value = pId;
                            controller.updateConfigMapping(pId);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorfulGridIcon() {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
              decoration:
                  BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(2))),
          Container(
              decoration:
                  BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(2))),
          Container(
              decoration:
                  BoxDecoration(color: const Color(0xFFEC4899), borderRadius: BorderRadius.circular(2))),
          Container(
              decoration:
                  BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildVariantListTab(BuildContext context, VariantMasterController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Variant List Tag Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_offer_outlined, size: 14, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(
                "Variant List",
                style: GoogleFonts.inter(
                  color: const Color(0xFF2563EB),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Main Card Container with Live Variant Chips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: controller.isLoadingVariants.value
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  ),
                )
              : controller.variantTypes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(Icons.style_outlined, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              "No variants available. Click '+ Add New Variant' to add.",
                              style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: controller.variantTypes.map<Widget>((item) {
                        final name = (item['name'] ?? item['variant_name'] ?? '').toString();

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Blue dot
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Variant name
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Edit button (Pencil icon)
                              InkWell(
                                onTap: () => _showEditVariantDialog(context, controller, item),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Delete button (Trash icon)
                              InkWell(
                                onTap: () => _showDeleteConfirmDialog(context, controller, item),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }

  Widget _buildProductVariantsTab(BuildContext context, VariantMasterController controller) {
    if (controller.isLoadingProducts.value || controller.isLoadingVariants.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    final selectedProductId = controller.selectedProductIdForVariants.value;
    final matchProd =
        controller.products.firstWhereOrNull((p) => p['id']?.toString() == selectedProductId);
    final selectedProductName =
        matchProd != null ? (matchProd['name']?.toString() ?? '') : '';

    final filteredAllocations = selectedProductId == null
        ? controller.allocations
        : controller.allocations
            .where((a) => a['product_id']?.toString() == selectedProductId)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Selector Button / Card
        InkWell(
          onTap: () => _showProductSearchSheet(context, controller),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CHOOSE PRODUCT",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedProductName.isNotEmpty
                            ? selectedProductName
                            : "Click to select allocated product...",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selectedProductName.isNotEmpty
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (selectedProductId == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.touch_app_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    "Please select a product to configure variant allocations",
                    style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Product Details Card
          if (matchProd != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matchProd['name']?.toString() ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if ((matchProd['brand_name'] ?? '').toString().isNotEmpty)
                              Text(
                                "Brand: ${matchProd['brand_name']}",
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                              ),
                            if ((matchProd['mrp'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Text(
                                "MRP: ₹${matchProd['mrp']}",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Select Variants Title
          Text(
            "Select Available Variants",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Check the variants applicable to this product to configure their stock and policies.",
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Variant Checkboxes Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: controller.variantTypes.map<Widget>((v) {
              final vName = (v['name'] ?? v['variant_name'] ?? '').toString();
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

              return InkWell(
                onTap: () {
                  if (!isChecked) {
                    config['checked'] = true;
                    controller.selectedVariantConfigs[vName] = Map<String, dynamic>.from(config);
                  }
                  controller.activeConfigVariant.value = vName;
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF2563EB)
                          : isChecked
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFFE2E8F0),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isChecked,
                        activeColor: const Color(0xFF2563EB),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          config['checked'] = val == true;
                          controller.selectedVariantConfigs[vName] =
                              Map<String, dynamic>.from(config);
                          if (val == true) {
                            controller.activeConfigVariant.value = vName;
                          } else {
                            if (controller.activeConfigVariant.value == vName) {
                              controller.activeConfigVariant.value = null;
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isChecked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Active Variant Settings Panel
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

          // Save Allocations Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => controller.saveAllocations(),
              icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
              label: Text(
                'Save Allocations',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Saved Allocations Table Header
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedProductName.isNotEmpty
                      ? 'Saved Variants – $selectedProductName'
                      : 'Saved Variants',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${filteredAllocations.length} allocated',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Saved Allocations List
          if (filteredAllocations.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'No variant allocations saved yet for this product',
                    style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columnSpacing: 20,
                  columns: [
                    DataColumn(
                        label: Text('#',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(
                        label: Text('VARIANT',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(
                        label: Text('MIN STOCK',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(
                        label: Text('MAX STOCK',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(
                        label: Text('WARRANTY',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(
                        label: Text('GUARANTEE',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(
                        label: Text('ACTIONS',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                  ],
                  rows: filteredAllocations.asMap().entries.map<DataRow>((entry) {
                    final idx = entry.key + 1;
                    final item = entry.value;
                    final variant = (item['variant'] ?? item['variant_name'] ?? '').toString();
                    final minStock =
                        (item['min_qty'] ?? item['min_stock'] ?? item['minStock'] ?? '-').toString();
                    final maxStock =
                        (item['max_qty'] ?? item['max_stock'] ?? item['maxStock'] ?? '-').toString();

                    String warranty = (item['warranty'] ?? '').toString();
                    if (warranty.isEmpty && item['warranty_duration'] != null) {
                      warranty =
                          '${item['warranty_duration']} ${item['warranty_duration_type'] ?? ''}'.trim();
                    }
                    if (warranty.isEmpty) warranty = '-';

                    String guarantee = (item['guarantee'] ?? '').toString();
                    if (guarantee.isEmpty && item['guarantee_duration'] != null) {
                      guarantee =
                          '${item['guarantee_duration']} ${item['guarantee_duration_type'] ?? ''}'.trim();
                    }
                    if (guarantee.isEmpty) guarantee = '-';

                    final allocId = item['id'];

                    return DataRow(cells: [
                      DataCell(Text(idx.toString())),
                      DataCell(Text(variant, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(minStock)),
                      DataCell(Text(maxStock)),
                      DataCell(Text(warranty)),
                      DataCell(Text(guarantee)),
                      DataCell(
                        allocId != null
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red, size: 18),
                                onPressed: () {
                                  if (allocId is int) {
                                    controller.deleteAllocation(allocId);
                                  }
                                },
                              )
                            : const Text('-'),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VariantMasterController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchVariants();
      controller.fetchAllocations();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Variant Master',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Obx(() {
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await controller.fetchVariants();
                await controller.fetchAllocations();
                await controller.fetchProducts();
              },
              color: const Color(0xFF2563EB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row (Icon + Title + Add Button)
                    LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 420;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildColorfulGridIcon(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Variant Master',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Manage product variant types like Original, Import, etc.',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddVariantDialog(context, controller),
                                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                label: Text(
                                  'Add New Variant',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          _buildColorfulGridIcon(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Variant Master',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage product variant types like Original, Import, etc.',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showAddVariantDialog(context, controller),
                            icon: const Icon(Icons.add, size: 16, color: Colors.white),
                            label: Text(
                              'Add New Variant',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tab Selector Segmented Bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => controller.selectedTabIndex.value = 0,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: controller.selectedTabIndex.value == 0
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: controller.selectedTabIndex.value == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_offer_outlined,
                                    size: 15,
                                    color: controller.selectedTabIndex.value == 0
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Variant Types',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: controller.selectedTabIndex.value == 0
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => controller.selectedTabIndex.value = 1,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: controller.selectedTabIndex.value == 1
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: controller.selectedTabIndex.value == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 15,
                                    color: controller.selectedTabIndex.value == 1
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Product Allocation',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: controller.selectedTabIndex.value == 1
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Content
                  controller.selectedTabIndex.value == 0
                      ? _buildVariantListTab(context, controller)
                      : _buildProductVariantsTab(context, controller),
                ],
              ),
            ),
          ),

            // Toast Banner
            if (controller.showBanner.value)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.bannerText.value,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
