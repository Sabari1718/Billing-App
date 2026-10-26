import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RestockRequestsPage extends StatefulWidget {
  const RestockRequestsPage({super.key});

  @override
  State<RestockRequestsPage> createState() => _RestockRequestsPageState();
}

class _RestockRequestsPageState extends State<RestockRequestsPage> {
  // Toggle: Photo 2 Auto Stock vs Photo 3 Manual Stock
  bool isAutoStockMode = true;

  // Filter State
  String searchQuery = "";
  String selectedStatusFilter = "All Statuses";

  final List<String> statusFilterOptions = [
    "All Statuses",
    "Pending",
    "Accepted / PO",
    "Completed",
    "Rejected",
  ];

  // Requests Data matching Photo 2 & 3
  List<Map<String, dynamic>> restockRequests = [
    {
      "id": 1,
      "s_no": 1,
      "req_id": "REQ-2026-0610",
      "product": "Product - Imported",
      "code": "PRO-1167",
      "supplier": "Supplier #73",
      "req_qty": 1,
      "supplier_qty": "—",
      "type": "AUTO",
      "status": "Pending",
      "po_number": "",
      "date": "10/15/2026",
    },
    {
      "id": 2,
      "s_no": 2,
      "req_id": "REQ-2026-0582",
      "product": "Product - Imported",
      "code": "PRO-3367",
      "supplier": "Sai TV Smart LED Pvt.Ltd",
      "req_qty": 5,
      "supplier_qty": "1",
      "type": "AUTO",
      "status": "PO",
      "po_number": "PO-1791953793028-267",
      "date": "10/8/2026",
    },
    {
      "id": 3,
      "s_no": 3,
      "req_id": "AUTO-217857-223",
      "product": "2Ch 12V Relay Module (2CH-MOD-03516)",
      "code": "2CH-MOD-03516",
      "supplier": "Sai TV Smart LED Pvt.Ltd",
      "req_qty": 5,
      "supplier_qty": "5",
      "type": "AUTO",
      "status": "PO",
      "po_number": "PO-1791954117287-977",
      "date": "9/5/2026",
    },
    {
      "id": 4,
      "s_no": 4,
      "req_id": "AUTO-217853-693",
      "product": "Product",
      "code": "PRO-3367",
      "supplier": "Sai TV Smart LED Pvt.Ltd",
      "req_qty": 10,
      "supplier_qty": "—",
      "type": "AUTO",
      "status": "Rejected",
      "po_number": "",
      "date": "9/5/2026",
    },
  ];

  // Open Supplier Stock Request Modal (Photo 4)
  void _openSupplierStockRequestModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _SupplierStockRequestDialog(),
    );
  }

  void _showViewDetailsModal(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Request Details - ${req['req_id']}",
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Product", req['product']),
            _buildDetailRow("Code", req['code']),
            _buildDetailRow("Supplier", req['supplier']),
            _buildDetailRow("Requested Qty", req['req_qty'].toString()),
            _buildDetailRow("Supplier Qty", req['supplier_qty'].toString()),
            _buildDetailRow("Status", req['status']),
            _buildDetailRow("Date", req['date']),
            if ((req['po_number'] ?? '').isNotEmpty)
              _buildDetailRow("PO #", req['po_number']),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = restockRequests.where((req) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final r = req['req_id'].toString().toLowerCase();
        final p = req['product'].toString().toLowerCase();
        final s = req['supplier'].toString().toLowerCase();
        final c = req['code'].toString().toLowerCase();
        if (!r.contains(q) && !p.contains(q) && !s.contains(q) && !c.contains(q)) return false;
      }
      if (selectedStatusFilter != "All Statuses") {
        if (selectedStatusFilter == "Pending" && req['status'] != "Pending") return false;
        if (selectedStatusFilter == "Accepted / PO" && req['status'] != "PO") return false;
        if (selectedStatusFilter == "Rejected" && req['status'] != "Rejected") return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Restock Requests",
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
            // Top Header: Title, Description, and + Supplier Stock Request Button (Photo 2 & 3)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stock Restock Requests",
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Manage and monitor automatic and manual inventory restock requests",
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                // + Supplier Stock Request button (Visible in Manual Stock mode - Photo 3)
                if (!isAutoStockMode)
                  ElevatedButton.icon(
                    onPressed: _openSupplierStockRequestModal,
                    icon: const Icon(Icons.add, size: 15, color: Colors.white),
                    label: Text("+ Supplier Stock Request", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5), // Indigo/purple as in Photo 3
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode Toggle in center: Manual Stock | Auto Stock (Photo 2 & 3)
            Center(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => isAutoStockMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: !isAutoStockMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: !isAutoStockMode
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, size: 14, color: !isAutoStockMode ? const Color(0xFF2563EB) : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              "Manual Stock",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: !isAutoStockMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => isAutoStockMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAutoStockMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isAutoStockMode
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bolt_outlined, size: 14, color: isAutoStockMode ? const Color(0xFF2563EB) : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              "Auto Stock",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isAutoStockMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4 Stat Cards Row (Photo 2 & 3)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final cardWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard(
                      title: "PENDING REQUESTS",
                      count: "527",
                      subtitle: "Awaiting supplier response",
                      icon: Icons.access_time_rounded,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      width: cardWidth,
                    ),
                    _buildMetricCard(
                      title: "ACCEPTED / ORDERS",
                      count: "2",
                      subtitle: "Purchase orders placed",
                      icon: Icons.shopping_cart_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      width: cardWidth,
                    ),
                    _buildMetricCard(
                      title: "COMPLETED REQUESTS",
                      count: "0",
                      subtitle: "Goods received & stock added",
                      icon: Icons.verified_user_outlined,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      width: cardWidth,
                    ),
                    _buildMetricCard(
                      title: "REJECTED REQUESTS",
                      count: "2",
                      subtitle: "Declined by supplier",
                      icon: Icons.highlight_off_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      width: cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Filter Bar (Photo 2 & 3)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;

                  final searchField = SizedBox(
                    height: 40,
                    child: TextField(
                      onChanged: (val) => setState(() => searchQuery = val),
                      style: GoogleFonts.inter(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Search by request code, order ID, product, supplier...",
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                      ),
                    ),
                  );

                  final statusField = SizedBox(
                    height: 40,
                    child: DropdownButtonFormField<String>(
                      value: selectedStatusFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                      items: statusFilterOptions.map((st) => DropdownMenuItem(value: st, child: Text(st, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                      onChanged: (val) => setState(() => selectedStatusFilter = val ?? "All Statuses"),
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        searchField,
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: statusField),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.grey),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 7, child: searchField),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: statusField),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Requests Table (Photo 2 & 3)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 64,
                  columnSpacing: 18,
                  horizontalMargin: 16,
                  columns: [
                    DataColumn(label: Text("S.NO", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("REQUEST ID", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("PRODUCT", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("CODE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("SUPPLIER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("REQ QTY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("SUPPLIER QTY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("REQUEST TYPE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("STATUS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("REQUEST DATE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                    DataColumn(label: Text("ACTION", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)))),
                  ],
                  rows: filtered.map((req) {
                    return DataRow(
                      cells: [
                        DataCell(Text(req['s_no'].toString(), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155)))),
                        // Request ID
                        DataCell(
                          Text(
                            req['req_id'].toString(),
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                          ),
                        ),
                        // Product
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              req['product'].toString(),
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Code Badge
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              req['code'].toString(),
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                            ),
                          ),
                        ),
                        // Supplier
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              req['supplier'].toString(),
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Req Qty
                        DataCell(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                              child: Text(req['req_qty'].toString(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                            ),
                          ),
                        ),
                        // Supplier Qty
                        DataCell(
                          Center(
                            child: Text(
                              req['supplier_qty'].toString(),
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        // Request Type
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt, size: 12, color: Color(0xFF16A34A)),
                                const SizedBox(width: 2),
                                Text(
                                  req['type'].toString(),
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Status Badge (Photo 2)
                        DataCell(_buildStatusBadge(req)),
                        // Request Date
                        DataCell(Text(req['date'].toString(), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)))),
                        // Action Buttons (Photo 2)
                        DataCell(_buildActionButtons(req)),
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

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> req) {
    final status = req['status'];
    if (status == "Pending") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text("Pending", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
          ],
        ),
      );
    } else if (status == "PO") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 12, color: Color(0xFF2563EB)),
            const SizedBox(width: 4),
            Text(req['po_number'] ?? "PO", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
          ],
        ),
      );
    } else if (status == "Rejected") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.highlight_off_rounded, size: 12, color: Color(0xFFDC2626)),
            const SizedBox(width: 4),
            Text("Rejected", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
          ],
        ),
      );
    }
    return Text(status.toString());
  }

  // Exact action buttons from Photo 2:
  // Pending row: [Accept] [Partial] [Reject] [View]
  // PO row: [Goods Received] [View] (clock icon)
  // Rejected row: [View] (clock icon)
  Widget _buildActionButtons(Map<String, dynamic> req) {
    final status = req['status'];

    if (status == "Pending") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Accept Button (Blue)
          _buildSmallBtn("Accept", const Color(0xFF2563EB), Colors.white, () {
            setState(() {
              req['status'] = "PO";
              req['po_number'] = "PO-${DateTime.now().millisecondsSinceEpoch}";
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Request accepted. Purchase order generated!"), backgroundColor: Colors.green),
            );
          }),
          const SizedBox(width: 4),
          // Partial Button (Indigo)
          _buildSmallBtn("Partial", const Color(0xFF4F46E5), Colors.white, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Marked as Partial fulfillment")),
            );
          }),
          const SizedBox(width: 4),
          // Reject Button (Red)
          _buildSmallBtn("Reject", const Color(0xFFEF4444), Colors.white, () {
            setState(() => req['status'] = "Rejected");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Request rejected"), backgroundColor: Colors.red),
            );
          }),
          const SizedBox(width: 4),
          // View Button (Outlined Blue)
          _buildOutlinedSmallBtn("View", Icons.visibility_outlined, () => _showViewDetailsModal(req)),
        ],
      );
    } else if (status == "PO") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Goods Received Button (Green)
          _buildSmallBtn("Goods Received", const Color(0xFF10B981), Colors.white, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Goods received and added to inventory!"), backgroundColor: Colors.green),
            );
          }),
          const SizedBox(width: 4),
          // View Button
          _buildOutlinedSmallBtn("View", Icons.visibility_outlined, () => _showViewDetailsModal(req)),
          const SizedBox(width: 4),
          // History clock icon
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF64748B)),
            onPressed: () => _showViewDetailsModal(req),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      );
    } else {
      // Rejected
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOutlinedSmallBtn("View", Icons.visibility_outlined, () => _showViewDetailsModal(req)),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF64748B)),
            onPressed: () => _showViewDetailsModal(req),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      );
    }
  }

  Widget _buildSmallBtn(String text, Color bg, Color fg, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOutlinedSmallBtn(String text, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 11, color: const Color(0xFF2563EB)),
      label: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFF93C5FD)),
        backgroundColor: const Color(0xFFEFF6FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// =========================================================================
// Photo 4: Supplier Stock Request Dialog
// =========================================================================
class _SupplierStockRequestDialog extends StatefulWidget {
  const _SupplierStockRequestDialog();

  @override
  State<_SupplierStockRequestDialog> createState() => _SupplierStockRequestDialogState();
}

class _SupplierStockRequestDialogState extends State<_SupplierStockRequestDialog> {
  final List<String> suppliers = [
    "Saravana Electronics",
    "Sai TV Smart LED Pvt.Ltd",
    "Circuitpointcare",
    "Supplier #73",
  ];

  String? selectedSupplier;
  final TextEditingController searchSupplierCtrl = TextEditingController();

  // Mock low stock items for selected supplier
  final List<Map<String, dynamic>> lowStockProducts = [
    {
      "name": "3.7V 6000mAh Li-ion Battery",
      "code": "BAT-6000",
      "current_stock": 5,
      "order_qty": 20,
      "price": 180.0,
      "selected": true,
    },
    {
      "name": "3.6V 2000 mAh battery",
      "code": "BAT-2000",
      "current_stock": 5,
      "order_qty": 15,
      "price": 95.0,
      "selected": true,
    },
    {
      "name": "BNC Female to Female Connector Pin",
      "code": "CONN-BNC",
      "current_stock": 3,
      "order_qty": 50,
      "price": 12.0,
      "selected": false,
    },
  ];

  int get selectedCount => lowStockProducts.where((p) => p['selected'] == true).length;

  @override
  void dispose() {
    searchSupplierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: 3D cube icon, title, subtitle & close button (Photo 4)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Icon(Icons.all_inbox_rounded, size: 20, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Supplier Stock Request",
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Select a supplier and choose low-stock items to order",
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Step 1: Select Supplier * (Photo 4)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                          child: const Center(
                            child: Text("1", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Select Supplier",
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        Text(" *", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 450;
                        final searchInput = SizedBox(
                          height: 40,
                          child: TextField(
                            controller: searchSupplierCtrl,
                            style: GoogleFonts.inter(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: "Search supplier by name, company, or phone...",
                              hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
                              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                          ),
                        );

                        final dropdown = SizedBox(
                          height: 40,
                          child: DropdownButtonFormField<String>(
                            value: selectedSupplier,
                            hint: Text("-- Choose Supplier --", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400)),
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            items: suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                            onChanged: (val) => setState(() => selectedSupplier = val),
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              searchInput,
                              const SizedBox(height: 10),
                              dropdown,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: searchInput),
                            const SizedBox(width: 12),
                            Expanded(child: dropdown),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Step 2: Select Low Stock Products, Quantities & Prices (Photo 4)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                          child: const Center(
                            child: Text("2", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Select Low Stock Products, Quantities & Prices",
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // When no supplier selected: Photo 4 exact empty state
                    if (selectedSupplier == null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                "Please Select a Supplier Above",
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Low stock products associated with that supplier will be listed here.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: lowStockProducts.map((p) {
                          final isChecked = p['selected'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isChecked ? const Color(0xFFF8FAFC) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isChecked ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  onChanged: (val) => setState(() => p['selected'] = val ?? false),
                                  activeColor: const Color(0xFF2563EB),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['name'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                      Text("Code: ${p['code']} | Cur. Stock: ${p['current_stock']}", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                  child: Text("Qty: ${p['order_qty']}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer Buttons (Photo 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    ),
                    child: Text("Cancel", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (selectedSupplier == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a supplier")));
                        return;
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Stock Request sent to $selectedSupplier successfully!"), backgroundColor: Colors.green),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                    label: Text("Send Stock Request ($selectedCount items)", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5), // Indigo matching Photo 4
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
