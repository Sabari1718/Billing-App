import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =========================================================================
// 1. STOCK ORDERS LIST PAGE (PHOTO 4 MATCHING)
// =========================================================================
class StockOrdersPage extends StatefulWidget {
  const StockOrdersPage({super.key});

  @override
  State<StockOrdersPage> createState() => _StockOrdersPageState();
}

class _StockOrdersPageState extends State<StockOrdersPage> {
  List<Map<String, dynamic>> stockOrders = [];
  bool isLoading = false;
  String searchQuery = "";
  bool isTableView = true;

  @override
  void initState() {
    super.initState();
    _loadStockOrders();
  }

  Future<void> _loadStockOrders() async {
    // Initial empty state matching Photo 4
    setState(() {
      isLoading = false;
    });
  }

  void _navigateToAddStockOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddStockOrderPage()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        stockOrders.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          ...result,
        });
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stock order saved successfully"), backgroundColor: Colors.green),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Stock Order", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to delete this stock order for ${order['product']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                stockOrders.removeWhere((e) => e['id'] == order['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Stock order deleted"), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = stockOrders.where((order) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final p = (order['product'] ?? '').toString().toLowerCase();
        final o = (order['order_name'] ?? '').toString().toLowerCase();
        return p.contains(q) || o.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Stock Orders",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Container (Photo 4)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Title Block
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stock Orders",
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Manage and track your stock orders",
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Actions & Search Block
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Search Input
                      SizedBox(
                        width: 200,
                        height: 38,
                        child: TextField(
                          onChanged: (val) => setState(() => searchQuery = val),
                          style: GoogleFonts.inter(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: "Search by Product Name...",
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                        ),
                      ),
                      // View Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isTableView = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isTableView ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.table_rows_outlined, size: 14, color: isTableView ? const Color(0xFF2563EB) : Colors.grey),
                                    const SizedBox(width: 4),
                                    Text("Table", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isTableView ? const Color(0xFF2563EB) : Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => isTableView = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !isTableView ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.grid_view_outlined, size: 14, color: !isTableView ? const Color(0xFF2563EB) : Colors.grey),
                                    const SizedBox(width: 4),
                                    Text("Cards", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: !isTableView ? const Color(0xFF2563EB) : Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Add Stock Order Button (Photo 4)
                      ElevatedButton.icon(
                        onPressed: _navigateToAddStockOrder,
                        icon: const Icon(Icons.add, size: 15, color: Colors.white),
                        label: Text("Add Stock Order", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content Area (Empty state or Orders List)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            // 3D Box Outline Icon (Photo 4)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.all_inbox_outlined, size: 44, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "No Stock Orders Found",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: Text(
                                "You have not added any stock orders yet. Click below to create your first stock order.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // + Create First Stock Order button (Photo 4)
                            ElevatedButton.icon(
                              onPressed: _navigateToAddStockOrder,
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              label: Text(
                                "Create First Stock Order",
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: [
                          DataColumn(label: Text("PRODUCT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("STOCK ORDER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("MIN STOCK", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("MAX STOCK", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("DAYS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("AMOUNT (₹)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("ACTIONS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredOrders.map((order) {
                          return DataRow(
                            cells: [
                              DataCell(Text(order['product'] ?? '-', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                              DataCell(Text(order['order_name'] ?? '-', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text(order['min_stock']?.toString() ?? '0', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text(order['max_stock']?.toString() ?? '10', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text(order['days']?.toString() ?? '1', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text("₹${order['amount'] ?? '0'}", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)))),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                      onPressed: () => _confirmDelete(order),
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
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 2. ADD / CREATE STOCK ORDER PAGE (PHOTO 5 MATCHING)
// =========================================================================
class AddStockOrderPage extends StatefulWidget {
  const AddStockOrderPage({super.key});

  @override
  State<AddStockOrderPage> createState() => _AddStockOrderPageState();
}

class _AddStockOrderPageState extends State<AddStockOrderPage> {
  final List<String> productsList = [
    "Mq-2 Gas Sensor",
    "10D20 MOV Thermistor",
    "10D431 MOV Thermister",
    "3.7V 600mAh Li-ion Rechargeable Battery",
    "3.7V 6000mAh Li-ion Battery",
  ];

  String? selectedProduct;
  final orderNameCtrl = TextEditingController();
  final minStockCtrl = TextEditingController(text: "0");
  final maxStockCtrl = TextEditingController(text: "10");
  final daysCtrl = TextEditingController(text: "1");
  final amountCtrl = TextEditingController();

  @override
  void dispose() {
    orderNameCtrl.dispose();
    minStockCtrl.dispose();
    maxStockCtrl.dispose();
    daysCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  void _saveStockOrder() {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product")),
      );
      return;
    }

    final orderData = {
      'product': selectedProduct,
      'order_name': orderNameCtrl.text.trim().isEmpty ? "Order #1" : orderNameCtrl.text.trim(),
      'min_stock': minStockCtrl.text.trim(),
      'max_stock': maxStockCtrl.text.trim(),
      'days': daysCtrl.text.trim(),
      'amount': amountCtrl.text.trim().isEmpty ? "0" : amountCtrl.text.trim(),
    };

    Navigator.pop(context, orderData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Stock Order Configuration",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Nav Bar (Photo 5: Back to Stock Orders | Toggle)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 14, color: Color(0xFF475569)),
                  label: Text("Back to Stock Orders", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_outlined, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text("Stock Order", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.format_list_bulleted, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text("List", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Configuration Card (Photo 5)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Sliders Icon
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Stock Order Configuration",
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Configure stock thresholds, order quantities, cycle days and amount per product",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Field 1: Product *
                      _buildLabel("Product", true),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedProduct,
                        hint: Text("-- Search / Select Product --", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                        isExpanded: true,
                        decoration: _inputDecoration(),
                        items: productsList.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.inter(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => selectedProduct = val),
                      ),
                      const SizedBox(height: 18),

                      // Field 2: Stock Order * & Min Stock * (Responsive Row/Column)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;

                          final stockOrderField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Stock Order", true),
                              const SizedBox(height: 6),
                              TextField(
                                controller: orderNameCtrl,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: _inputDecoration(hint: "e.g. Weekly Order"),
                              ),
                            ],
                          );

                          final minStockField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Min Stock", true),
                              const SizedBox(height: 6),
                              TextField(
                                controller: minStockCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: _inputDecoration(hint: "0"),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                stockOrderField,
                                const SizedBox(height: 18),
                                minStockField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(flex: 6, child: stockOrderField),
                              const SizedBox(width: 16),
                              Expanded(flex: 4, child: minStockField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Field 3: Max Stock * & Days *
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;

                          final maxStockField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Max Stock", true),
                              const SizedBox(height: 6),
                              TextField(
                                controller: maxStockCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: _inputDecoration(hint: "10"),
                              ),
                            ],
                          );

                          final daysField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Days", true),
                              const SizedBox(height: 6),
                              TextField(
                                controller: daysCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: _inputDecoration(hint: "1"),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                maxStockField,
                                const SizedBox(height: 18),
                                daysField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: maxStockField),
                              const SizedBox(width: 16),
                              Expanded(child: daysField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Field 4: Amount *
                      _buildLabel("Amount", true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: _inputDecoration(
                          hint: "Enter Amount (e.g. 5000)",
                          prefixText: "₹   ",
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Bottom Action Buttons (Photo 5: Cancel & Save Stock Order)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _saveStockOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text("Save Stock Order", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isRequired) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
        ),
        if (isRequired)
          Text(
            " *",
            style: GoogleFonts.inter(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
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
    );
  }
}
