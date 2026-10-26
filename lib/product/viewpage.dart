import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/utils/app_logger.dart';
import 'add product.dart';

part 'viewpage_logic.dart';

class ProductAllocationPage extends StatefulWidget {
  const ProductAllocationPage({super.key});

  @override
  State<ProductAllocationPage> createState() => _ProductAllocationPageState();
}

class _ProductAllocationPageState extends State<ProductAllocationPage> with ProductAllocationLogic {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController pageInputController = TextEditingController(text: "1");

  String searchQuery = "";
  int pageSize = 10;
  int currentPage = 1;
  final List<int> pageSizeOptions = [10, 25, 50, 100, 250, 500, 1000];

  @override
  void dispose() {
    searchController.dispose();
    pageInputController.dispose();
    super.dispose();
  }

  List get filteredProducts {
    if (searchQuery.trim().isEmpty) return products;
    final q = searchQuery.toLowerCase().trim();
    return products.where((p) {
      final name = (p['name'] ?? "").toString().toLowerCase();
      final code = (p['code'] ?? "").toString().toLowerCase();
      final id = (p['id'] ?? "").toString();
      return name.contains(q) || code.contains(q) || id.contains(q);
    }).toList();
  }

  int get totalPages {
    final len = filteredProducts.length;
    if (len == 0) return 1;
    return (len / pageSize).ceil();
  }

  List get pagedProducts {
    final list = filteredProducts;
    final startIndex = (currentPage - 1) * pageSize;
    if (startIndex >= list.length) return [];
    final endIndex = (startIndex + pageSize) > list.length ? list.length : startIndex + pageSize;
    return list.sublist(startIndex, endIndex);
  }

  void goToPage(int page) {
    if (page < 1) page = 1;
    if (page > totalPages) page = totalPages;
    setState(() {
      currentPage = page;
      pageInputController.text = page.toString();
    });
  }

  void confirmDeleteDialog(Map item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Product",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          "Are you sure you want to delete ${item['name'] ?? 'this product'}?",
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteProduct(item['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void editProduct(Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductEntryPage(editItem: Map<String, dynamic>.from(item)),
      ),
    ).then((_) {
      fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalEntries = filteredProducts.length;
    final startEntry = totalEntries == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final endEntry = min(currentPage * pageSize, totalEntries);
    final displayedItems = pagedProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light background like web
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "Product List",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh List",
            onPressed: fetchProducts,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        color: const Color(0xFF2563EB),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main White Card Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Header with Title & Icon
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Row(
                              children: [
                                const Icon(Icons.view_in_ar_rounded, color: Color(0xFF3B82F6), size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  "Product List",
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                          // 2. Search & Show Filter Bar
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isSmall = constraints.maxWidth < 500;
                                if (isSmall) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildSearchField(),
                                      const SizedBox(height: 12),
                                      _buildShowDropdown(),
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(child: _buildSearchField()),
                                    const SizedBox(width: 16),
                                    _buildShowDropdown(),
                                  ],
                                );
                              },
                            ),
                          ),

                          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                          // 3. Data Table (Horizontally scrollable to eliminate any overflow)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 700),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 52,
                                headingRowHeight: 44,
                                horizontalMargin: 20,
                                columnSpacing: 24,
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      "S.NO",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      "PRODUCT CODE",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      "PRODUCT NAME",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      "MIN QTY",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      "MAX QTY",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      "ACTIONS",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: displayedItems.isEmpty
                                    ? [
                                        DataRow(
                                          cells: [
                                            DataCell(Text("-", style: GoogleFonts.inter(color: Colors.grey))),
                                            DataCell(Text("-", style: GoogleFonts.inter(color: Colors.grey))),
                                            DataCell(
                                              Text(
                                                "No products match your search",
                                                style: GoogleFonts.inter(color: Colors.grey.shade500),
                                              ),
                                            ),
                                            DataCell(Text("-", style: GoogleFonts.inter(color: Colors.grey))),
                                            DataCell(Text("-", style: GoogleFonts.inter(color: Colors.grey))),
                                            DataCell(Text("-", style: GoogleFonts.inter(color: Colors.grey))),
                                          ],
                                        )
                                      ]
                                    : List.generate(displayedItems.length, (index) {
                                        final item = displayedItems[index];
                                        final serialNo = ((currentPage - 1) * pageSize) + index + 1;
                                        final code = item['code'] ?? "-";

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                "$serialNo",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: const Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                code,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                item['name'] ?? "No Name",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                "${item['min'] ?? 0}",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: const Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                "${item['max'] ?? 0}",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: const Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Edit Button (Amber)
                                                  InkWell(
                                                    onTap: () => editProduct(item),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFEF3C7),
                                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Icon(
                                                        Icons.edit_outlined,
                                                        size: 16,
                                                        color: Color(0xFFD97706),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Delete Button (Red)
                                                  InkWell(
                                                    onTap: () => confirmDeleteDialog(item),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFEE2E2),
                                                        border: Border.all(color: const Color(0xFFFECACA)),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Icon(
                                                        Icons.delete_outline,
                                                        size: 16,
                                                        color: Color(0xFFDC2626),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                              ),
                            ),
                          ),

                          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                          // 4. Pagination Footer Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isSmall = constraints.maxWidth < 620;
                                final entriesText = Text(
                                  "Showing $startEntry to $endEntry of $totalEntries entries",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                );

                                final paginationControls = SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Go to Page input
                                      Text(
                                        "Go to Page: ",
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                      ),
                                      Container(
                                        width: 44,
                                        height: 32,
                                        margin: const EdgeInsets.only(right: 12),
                                        child: TextField(
                                          controller: pageInputController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                          onSubmitted: (val) {
                                            final p = int.tryParse(val) ?? 1;
                                            goToPage(p);
                                          },
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.zero,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Previous Button
                                      _buildPageNavBtn("«", currentPage > 1 ? () => goToPage(currentPage - 1) : null),

                                      // Page numbers
                                      ..._buildPageNumbersList(),

                                      // Next Button
                                      _buildPageNavBtn("»", currentPage < totalPages ? () => goToPage(currentPage + 1) : null),
                                    ],
                                  ),
                                );

                                if (isSmall) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      entriesText,
                                      const SizedBox(height: 12),
                                      paginationControls,
                                    ],
                                  );
                                }

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    entriesText,
                                    paginationControls,
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PRODUCT SEARCH",
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: TextField(
            controller: searchController,
            onChanged: (val) {
              setState(() {
                searchQuery = val;
                currentPage = 1;
                pageInputController.text = "1";
              });
            },
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: "Type product name or code...",
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShowDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SHOW",
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: pageSize,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
              items: pageSizeOptions.map((size) {
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text("$size"),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    pageSize = val;
                    currentPage = 1;
                    pageInputController.text = "1";
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageNavBtn(String text, VoidCallback? onTap) {
    final bool disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: disabled ? Colors.grey.shade400 : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbersList() {
    List<Widget> list = [];
    final pages = totalPages;
    int start = max(1, currentPage - 2);
    int end = min(pages, start + 4);
    if (end - start < 4) {
      start = max(1, end - 4);
    }

    for (int i = start; i <= end; i++) {
      final isCurrent = i == currentPage;
      list.add(
        InkWell(
          onTap: () => goToPage(i),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFF2563EB) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCurrent ? const Color(0xFF2563EB) : Colors.grey.shade300,
              ),
            ),
            child: Text(
              "$i",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      );
    }
    return list;
  }
}