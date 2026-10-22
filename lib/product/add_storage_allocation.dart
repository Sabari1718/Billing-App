import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

part 'add_storage_allocation_logic.dart';

class AddStorageAllocationPage extends StatefulWidget {
  final int storageTypeId;
  final String storageTypeName;

  const AddStorageAllocationPage({
    super.key,
    required this.storageTypeId,
    required this.storageTypeName,
  });

  @override
  State<AddStorageAllocationPage> createState() => _AddStorageAllocationPageState();
}

class _AddStorageAllocationPageState extends State<AddStorageAllocationPage> with AddStorageAllocationLogic {
  @override
  Widget build(BuildContext context) {
    // Dynamic matching of selected stock ID
    final int? selectedStockId = _selectedStock != null 
        ? (_selectedStock!['id'] ?? _selectedStock!['product_id']) as int?
        : null;

    // Dynamic matching of selected variant ID
    final int? selectedVariantId = _selectedVariant != null 
        ? (_selectedVariant!['id']) as int?
        : null;

    // Retrieve active leaf box and generate partitions
    final leafBox = _getSelectedLeafBox();
    final int rows = leafBox != null ? int.tryParse(leafBox['partition_rows']?.toString() ?? '') ?? 0 : 0;
    final int cols = leafBox != null ? int.tryParse(leafBox['partition_columns']?.toString() ?? '') ?? 0 : 0;
    final hasPartitions = rows > 0 || cols > 0;
    final partitionList = hasPartitions ? _generatePartitions(rows, cols) : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                "Back to Storages",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 16,
              width: 1.5,
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: "Allocating in: ",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                  children: [
                    TextSpan(
                      text: widget.storageTypeName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // CARD 1: SELECT STOCK COMPONENT
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.widgets_outlined, color: Color(0xFF4F46E5), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Select Stock Component",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "CHOOSE PRODUCT / STOCK ENTRY",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // STOCK NAME DROPDOWN
                              Text(
                                "STOCK NAME",
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  color: const Color(0xFFF8FAFC),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedStockId,
                                    hint: Text("Select Product", style: GoogleFonts.inter(fontSize: 14)),
                                    isExpanded: true,
                                    items: () {
                                      final seenIds = <int>{};
                                      final list = <DropdownMenuItem<int>>[];
                                      for (var item in _stocksList) {
                                        if (item is! Map) continue;
                                        final id = item['id'] ?? item['product_id'];
                                        if (id == null || id is! int) continue;
                                        if (seenIds.contains(id)) continue;
                                        seenIds.add(id);
                                        
                                        final name = (item['product_name'] ?? item['name'] ?? 'Unnamed Product').toString();
                                        list.add(DropdownMenuItem<int>(
                                          value: id,
                                          child: Text(name, style: GoogleFonts.inter(fontSize: 14)),
                                        ));
                                      }
                                      return list;
                                    }(),
                                    onChanged: (val) {
                                      setState(() {
                                        Map<String, dynamic>? foundStock;
                                        for (var item in _stocksList) {
                                          if (item is Map && (item['id'] == val || item['product_id'] == val)) {
                                            foundStock = Map<String, dynamic>.from(item);
                                            break;
                                          }
                                        }
                                        _selectedStock = foundStock;
                                        _selectedVariant = null;
                                        _selectedDist = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Row for Variant and Stock Dist
                              Row(
                                children: [
                                  // VARIANT DROPDOWN
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "VARIANT",
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFCBD5E1)),
                                            color: const Color(0xFFF8FAFC),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              value: selectedVariantId,
                                              hint: Text("Select Variant", style: GoogleFonts.inter(fontSize: 14)),
                                              isExpanded: true,
                                              items: () {
                                                final seenIds = <int>{};
                                                final list = <DropdownMenuItem<int>>[];
                                                final variants = _getAvailableVariants();
                                                for (var item in variants) {
                                                  if (item is! Map) continue;
                                                  final id = item['id'] ?? item['variant_id'];
                                                  if (id == null || id is! int) continue;
                                                  if (seenIds.contains(id)) continue;
                                                  seenIds.add(id);
                                                  
                                                  final name = (item['name'] ?? item['variant_name'] ?? 'Unnamed').toString();
                                                  
                                                  // Read total quantity from stock entry variant
                                                  final totalQty = item['qty'] ?? item['quantity'] ?? 0;
                                                  list.add(DropdownMenuItem<int>(
                                                    value: id,
                                                    child: Text("$name ($totalQty)", style: GoogleFonts.inter(fontSize: 14)),
                                                  ));
                                                }
                                                return list;
                                              }(),
                                              onChanged: _selectedStock == null
                                                  ? null
                                                  : (val) {
                                                      setState(() {
                                                        final variants = _getAvailableVariants();
                                                        Map<String, dynamic>? foundVariant;
                                                        for (var item in variants) {
                                                          if (item is Map && (item['id'] == val || item['variant_id'] == val)) {
                                                            foundVariant = Map<String, dynamic>.from(item);
                                                            break;
                                                          }
                                                        }
                                                        _selectedVariant = foundVariant;
                                                        _selectedDist = null;
                                                      });
                                                    },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // STOCK DIST DROPDOWN
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "STOCK DIST",
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFCBD5E1)),
                                            color: const Color(0xFFF8FAFC),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedDist,
                                              hint: Text("Select Location", style: GoogleFonts.inter(fontSize: 14)),
                                              isExpanded: true,
                                              items: _getDistOptions().map((opt) {
                                                return DropdownMenuItem<String>(
                                                  value: opt['name'],
                                                  child: Text(opt['label']!, style: GoogleFonts.inter(fontSize: 14)),
                                                );
                                              }).toList(),
                                              onChanged: _selectedVariant == null
                                                  ? null
                                                  : (val) {
                                                      setState(() {
                                                        _selectedDist = val;
                                                      });
                                                    },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // CARD 2: DEFINE LOCATION PATH
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.account_tree_outlined, color: Color(0xFF7C3AED), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Define Location Path",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              if (_structureLevels.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Center(
                                    child: Text(
                                      "No structures defined for this storage type.",
                                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                                    ),
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 2.1,
                                  ),
                                  itemCount: _structureLevels.length,
                                  itemBuilder: (context, idx) {
                                    final level = _structureLevels[idx];
                                    final String name = (level['name'] ?? 'Level').toString();
                                    final int order = level['level_order'] ?? (idx + 1);
                                    final int? levelId = level['id'];

                                    final selectedVal = _selectedLocations[order];
                                    final options = _getLocationDropdownOptions(order, levelId);

                                    // Capitalize level name
                                    final String formattedLabel = name.isNotEmpty
                                        ? '${name[0].toUpperCase()}${name.substring(1)}'
                                        : 'Level';

                                    // Check if previous dropdown has selection (except for level 1)
                                    final bool isEnabled = order == 1 || _selectedLocations[order - 1] != null;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formattedLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isEnabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isEnabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                                            ),
                                            color: isEnabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              value: selectedVal != null ? selectedVal['id'] as int? : null,
                                              disabledHint: Text("Select $formattedLabel", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                                              hint: Text("Select $formattedLabel", style: GoogleFonts.inter(fontSize: 13)),
                                              isExpanded: true,
                                              items: isEnabled
                                                  ? () {
                                                      final seenIds = <int>{};
                                                      final list = <DropdownMenuItem<int>>[];
                                                      for (var opt in options) {
                                                        final id = opt['id'];
                                                        if (id == null || id is! int) continue;
                                                        if (seenIds.contains(id)) continue;
                                                        seenIds.add(id);
                                                        
                                                        list.add(DropdownMenuItem<int>(
                                                          value: id,
                                                          child: Text(opt['name'].toString(), style: GoogleFonts.inter(fontSize: 13)),
                                                        ));
                                                      }
                                                      return list;
                                                    }()
                                                  : [],
                                              onChanged: isEnabled
                                                  ? (val) {
                                                      setState(() {
                                                        Map<String, dynamic>? foundLoc;
                                                        for (var opt in options) {
                                                          if (opt['id'] == val) {
                                                            foundLoc = opt;
                                                            break;
                                                          }
                                                        }
                                                        _selectedLocations[order] = foundLoc;
                                                        // Clear selected partition when location changes
                                                        _selectedPartition = null;
                                                        // Clear all cascading lower levels
                                                        for (int o = order + 1; o <= _structureLevels.length; o++) {
                                                          _selectedLocations[o] = null;
                                                        }
                                                      });
                                                    }
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // DYNAMIC SELECTED BOX DETAILS (PARTITIONS SECTION)
                        if (hasPartitions && leafBox != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.grid_view_rounded, color: Color(0xFF16A34A), size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Selected Box Details - ${leafBox['name']}",
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: partitionList.map((part) {
                                    final bool isSelected = _selectedPartition == part;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedPartition = part;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                                            width: isSelected ? 2.0 : 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          part,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // CANCEL & SAVE BUTTONS ROW
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                ),
                                onPressed: _saveAllocation,
                                child: Text(
                                  "Save Allocation",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }
}
