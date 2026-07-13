import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageListPage extends StatefulWidget {
  const ManageListPage({super.key});

  @override
  State<ManageListPage> createState() => _ManageListPageState();
}

class _ManageListPageState extends State<ManageListPage> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _mockEntries = [
    {
      "id": 1,
      "title": "Initial Store Inventory setup",
      "category": "Product",
      "value": "1 item",
      "status": "Approved",
      "date": "2026-06-17",
    },
    {
      "id": 2,
      "title": "Customer invoice #1021",
      "category": "Billing",
      "value": "Rs. 4,500",
      "status": "Pending",
      "date": "2026-06-18",
    },
    {
      "id": 3,
      "title": "New Supplier signup: Sriva Tech",
      "category": "Customer",
      "value": "Partner",
      "status": "Approved",
      "date": "2026-06-18",
    }
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _mockEntries.where((entry) {
      final matchesSearch = entry['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || entry['category'] == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Manage Entries",
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "View, search and edit registered entries in the system.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Search and Filter Row
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
              hintText: "Search entries...",
              hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Categories horizontal chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Billing', 'Product', 'Customer'].map((cat) {
                final isSelected = _selectedFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedFilter = cat);
                      }
                    },
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Entries List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text("No entries match the criteria.", style: GoogleFonts.inter(color: Colors.grey)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, idx) {
                final entry = filtered[idx];
                final String status = entry['status'];
                final isApproved = status == 'Approved';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: entry['category'] == 'Billing'
                                ? const Color(0xFFFDF2F8)
                                : entry['category'] == 'Product'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry['category'].toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: entry['category'] == 'Billing'
                                  ? const Color(0xFFEC4899)
                                  : entry['category'] == 'Product'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                        Text(
                          entry['date'],
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          entry['title'],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Value: ${entry['value']}",
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isApproved ? const Color(0xFF15803D) : const Color(0xFF854D0E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
