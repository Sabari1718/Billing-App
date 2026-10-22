part of 'purchase_bill_entry.dart';

class SearchableSupplierDropdown extends StatefulWidget {
  final List<dynamic> suppliers;
  final Map<String, dynamic>? selectedSupplier;
  final ValueChanged<Map<String, dynamic>?> onSelected;
  final bool isLoading;

  const SearchableSupplierDropdown({
    super.key,
    required this.suppliers,
    required this.selectedSupplier,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  State<SearchableSupplierDropdown> createState() => _SearchableSupplierDropdownState();
}

class _SearchableSupplierDropdownState extends State<SearchableSupplierDropdown> {
  bool isExpanded = false;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.suppliers.where((s) {
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase();
      final name = (s['supplier_name'] ?? "").toString().toLowerCase();
      final company = (s['company_name'] ?? "").toString().toLowerCase();
      final phone = (s['primary_phone'] ?? "").toString().toLowerCase();
      final gst = (s['gst_number'] ?? "").toString().toLowerCase();
      return name.contains(q) || company.contains(q) || phone.contains(q) || gst.contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
              if (isExpanded) searchQuery = "";
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: isExpanded 
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
              border: Border.all(
                color: isExpanded ? AppColors.primary : Colors.grey.shade300,
                width: isExpanded ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.business, 
                        color: widget.selectedSupplier != null ? AppColors.primary : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: widget.selectedSupplier != null
                            ? RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                  children: [
                                    TextSpan(
                                      text: (widget.selectedSupplier!['supplier_name'] ?? "").toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if ((widget.selectedSupplier!['company_name'] ?? "").toString().isNotEmpty)
                                      TextSpan(
                                        text: " (${widget.selectedSupplier!['company_name']})",
                                        style: const TextStyle(fontWeight: FontWeight.normal, color: Color(0xFF64748B)),
                                      ),
                                  ],
                                ),
                              )
                            : Text(
                                "-- Search or Select Supplier from list --",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.selectedSupplier != null)
                      GestureDetector(
                        onTap: () {
                          widget.onSelected(null);
                        },
                        child: Icon(Icons.close, color: Colors.grey.shade500, size: 18),
                      ),
                    if (widget.selectedSupplier != null) const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: isExpanded ? AppColors.primary : Colors.grey.shade500,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (isExpanded)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 350),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search supplier by name, company, phone, GST...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: widget.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                "No suppliers found",
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final s = filtered[index];
                                final name = (s['supplier_name'] ?? "").toString().trim();
                                final company = (s['company_name'] ?? "").toString().trim();
                                final phone = (s['primary_phone'] ?? "").toString().trim();
                                final gst = (s['gst_number'] ?? "").toString().trim();

                                return GestureDetector(
                                  onTap: () {
                                    widget.onSelected(s);
                                    setState(() {
                                      isExpanded = false;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.blue.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.blue.shade100,
                                          child: const Icon(Icons.business, color: AppColors.primary, size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name.isEmpty ? "No Name" : name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                              ),
                                              if (company.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  company,
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                ),
                                              ],
                                              const SizedBox(height: 4),
                                              Wrap(
                                                alignment: WrapAlignment.spaceBetween,
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  if (phone.isNotEmpty)
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                                                        const SizedBox(width: 4),
                                                        Text(phone, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                                      ],
                                                    ),
                                                  if (gst.isNotEmpty)
                                                    Text(
                                                      "GST: $gst",
                                                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class DashedDividerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double dashWidth;
  final double dashGap;

  DashedDividerPainter({
    this.color = const Color(0xFFCBD5E1),
    this.thickness = 1.0,
    this.dashWidth = 4.0,
    this.dashGap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
