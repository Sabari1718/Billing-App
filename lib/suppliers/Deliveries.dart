import 'package:flutter/material.dart';

class DeliveriesPage extends StatefulWidget {
  const DeliveriesPage({super.key});

  @override
  State<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends State<DeliveriesPage> {
  final Color primaryColor = const Color(0xFF2563EB);
  final Color backgroundColor = const Color(0xFFF1F5F9);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color borderColor = const Color(0xFFE2E8F0);
  final Color textSecondary = const Color(0xFF64748B);
  final Color textPrimary = const Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Text(
          "Deliveries Mobile",
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.notifications_none, color: primaryColor, size: 22),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH & FILTERS
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: surfaceColor,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search Delivery ID or Supplier",
                        hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),

          /// 📋 LIST CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _deliveryCard("DEL-8820", "2024-04-12", "Techtronics Solutions", "ORD-2024-001", "12 Units", "Received", Colors.green),
                _deliveryCard("DEL-8825", "2024-04-13", "Global Parts Inc.", "ORD-2024-002", "5 Units", "In Transit", Colors.blue),
                _deliveryCard("DEL-8831", "2024-04-13", "Unity Manufacturing", "ORD-2024-003", "28 Units", "Pending", Colors.orange),
                _deliveryCard("DEL-8835", "2024-04-14", "Vertex Supplies", "ORD-2024-005", "15 Units", "In Transit", Colors.blue),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReceiveShipmentPage()),
          );
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Receive Shipment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _deliveryCard(String id, String date, String supplier, String orderId, String items, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 14)),
              Text(date, style: TextStyle(color: textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(supplier, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Flexible(child: Text(orderId, style: TextStyle(color: textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 16),
              Icon(Icons.inventory_2_outlined, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Flexible(child: Text(items, style: TextStyle(color: textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(status, statusColor),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionButton(Icons.visibility_outlined, "View"),
                    const SizedBox(width: 8),
                    _actionButton(Icons.edit_outlined, "Edit"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textPrimary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == "In Transit" ? Icons.local_shipping : (label == "Received" ? Icons.check_circle : Icons.timer),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiveShipmentPage extends StatefulWidget {
  const ReceiveShipmentPage({super.key});

  @override
  State<ReceiveShipmentPage> createState() => _ReceiveShipmentPageState();
}

class _ReceiveShipmentPageState extends State<ReceiveShipmentPage> {
  final Color primaryColor = const Color(0xFF2563EB);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color borderColor = const Color(0xFFE2E8F0);
  final Color textSecondary = const Color(0xFF64748B);
  final Color textPrimary = const Color(0xFF1E293B);

  List<Map<String, dynamic>> items = [
    {"name": "Steel Girders - 12m", "ordered": "50", "received": "50", "damaged": "0", "unit": "Units"},
    {"name": "Concrete Mix (Pre-mix)", "ordered": "100", "received": "95", "damaged": "5", "unit": "Bags"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Receive Shipment", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 18)),
            Text("SHP-114826", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 📝 GENERAL INFORMATION SECTION
                _buildSectionHeader(Icons.info_outline, "General Information"),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildMobileField("Supplier", "Select Supplier", isDropdown: true),
                      const SizedBox(height: 16),
                      _buildMobileField("Purchase Order (Optional)", "Select Order #", isDropdown: true),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildMobileField("Delivery Date", "05/08/2026", icon: Icons.calendar_today)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMobileField("Status", "Pending", isStatus: true)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMobileField("Reference / Invoice #", "INV-2024-00X"),
                      const SizedBox(height: 16),
                      _buildMobileField("Received By", "Employee Name"),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// 📦 ITEMS RECEIVED SECTION
                _buildSectionHeader(Icons.inventory_2_outlined, "Items Received (${items.length})"),
                const SizedBox(height: 12),
                ...items.asMap().entries.map((entry) {
                  return _buildProductCard(entry.value, entry.key);
                }),

                const SizedBox(height: 12),

                /// ADD PRODUCT BUTTON
                GestureDetector(
                  onTap: () {
                    setState(() {
                      items.add({"name": "", "ordered": "0", "received": "0", "damaged": "0", "unit": "Units"});
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.2), style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text("Add New Product", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 15)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// 📝 ADDITIONAL NOTES
                _buildSectionHeader(Icons.notes_outlined, "Additional Notes"),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: const TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Add delivery notes, inspector comments, or issues found during receiving...",
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 🔘 STICKY BOTTOM BUTTONS
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              decoration: BoxDecoration(
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Complete Reception", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text("Discard", style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textPrimary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary)),
      ],
    );
  }

  Widget _buildMobileField(String label, String value, {bool isDropdown = false, bool isStatus = false, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isStatus)
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(value, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                )
              else
                Expanded(child: Text(value, style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              if (isDropdown)
                Icon(Icons.keyboard_arrow_down, color: textSecondary, size: 18)
              else if (icon != null)
                Icon(icon, color: textSecondary, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, int index) {
    bool isNew = item['name'].isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(isNew ? "New Product" : item['name'], style: TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              IconButton(
                onPressed: () => setState(() => items.removeAt(index)),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMobileField("Product Name", isNew ? "Product name..." : item['name']),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildQtyField("Ordered", item['ordered'], Colors.grey.shade100, textPrimary)),
              const SizedBox(width: 8),
              Expanded(child: _buildQtyField("Received", item['received'], const Color(0xFFF0FDF4), const Color(0xFF166534))),
              const SizedBox(width: 8),
              Expanded(child: _buildQtyField("Damaged", item['damaged'], const Color(0xFFFEF2F2), const Color(0xFF991B1B))),
            ],
          ),
          const SizedBox(height: 12),
          _buildMobileField("Unit", item['unit'], isDropdown: true),
        ],
      ),
    );
  }

  Widget _buildQtyField(String label, String value, Color bg, Color text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(value, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}