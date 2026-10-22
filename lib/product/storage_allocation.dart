import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_storage_allocation.dart';

part 'storage_allocation_logic.dart';

class StorageAllocationPage extends StatefulWidget {
  const StorageAllocationPage({super.key});

  @override
  State<StorageAllocationPage> createState() => _StorageAllocationPageState();
}

class _StorageAllocationPageState extends State<StorageAllocationPage> with StorageAllocationLogic {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Storage Setup",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            _loadStorageTypes();
            await _fetchAllocatedStockReview();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. STORAGE ALLOCATION HEADER BANNER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      "Storage Allocation",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),

                // 2. STORAGE TYPES GRID
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _storageFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text("Failed to load storage", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadStorageTypes,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data ?? [];

                    if (data.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text("No storage allocations found", style: GoogleFonts.inter(color: Colors.grey)),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final id = item['id'] ?? item['storage_id'] ?? 0;
                        final name = (item['name'] ?? item['storage_name'] ?? "Storage").toString();

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Edit Icon
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Edit '\$name' functionality coming soon"),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0).withOpacity(0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Card Content
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2563EB).withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.dns_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Manage storage, levels and items",
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 34,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2563EB),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddStorageAllocationPage(
                                                storageTypeId: id,
                                                storageTypeName: name,
                                              ),
                                            ),
                                          ).then((value) {
                                            _fetchAllocatedStockReview();
                                          });
                                        },
                                        child: Text(
                                          "Select",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 3. ALLOCATED STOCK REVIEW BANNER CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Allocated Stock Review",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _fetchAllocatedStockReview,
                          icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF2563EB)),
                          label: Text(
                            "Refresh Data",
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 4. ALLOCATED STOCKS DATA TABLE
                _buildAllocatedStockTable(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocatedStockTable() {
    if (_isLoadingAllocated) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (_allocatedError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            children: [
              Text(
                _allocatedError,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchAllocatedStockReview,
                child: const Text("Retry Load"),
              )
            ],
          ),
        ),
      );
    }

    if (_allocatedStocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                "No allocated stocks found.",
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 68,
              headingRowHeight: 52,
              horizontalMargin: 20,
              columnSpacing: 28,
              columns: [
                DataColumn(
                  label: Text(
                    "LOCATION PATH",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "PRODUCT",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "TYPE / DIST",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "ALLOCATED QTY",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "ACTION",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              rows: _allocatedStocks.map((item) {
                final id = item['id'] as int;
                final path = item['location_path'].toString();
                final productName = item['product_name'].toString();
                final typeDist = item['type_dist'].toString();
                final qty = item['qty'].toString();

                return DataRow(
                  cells: [
                    // 1. LOCATION PATH
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          path,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                    // 2. PRODUCT
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          productName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    // 3. TYPE/DIST
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Text(
                          typeDist,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                    // 4. ALLOCATED QTY
                    DataCell(
                      Text(
                        qty,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    // 5. ACTION
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF7C3AED)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Edit allocation for '\$path' coming soon"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE11D48)),
                            onPressed: () => _confirmDeleteAllocation(id, path),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
