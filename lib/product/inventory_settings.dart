import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventorySettingsPage extends StatefulWidget {
  const InventorySettingsPage({super.key});

  @override
  State<InventorySettingsPage> createState() => _InventorySettingsPageState();
}

class _InventorySettingsPageState extends State<InventorySettingsPage> {
  // Stock entry mode: 'automatic', 'manual', 'auto_confirmation'
  String selectedMode = 'automatic';
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedMode = prefs.getString("stock_entry_mode") ?? 'automatic';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("stock_entry_mode", selectedMode);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Inventory settings saved successfully!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Inventory Settings",
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Photo 5)
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Inventory Settings",
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Configure how inventory stock entries and restock requests are processed.",
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Settings Card (Photo 5)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stock Entry Mode",
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Select how stock updates should be handled when restock requests are approved by suppliers.",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),

                  // 3 Option Cards (Photo 5: Automatic, Manual, Auto + Confirmation)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 750;

                      final autoCard = _buildOptionCard(
                        id: 'automatic',
                        title: 'Automatic',
                        icon: Icons.bolt,
                        description: 'When a supplier accepts stock request, automatically create stock entry, update inventory quantity, and mark request as Completed.',
                        isSelected: selectedMode == 'automatic',
                        onTap: () => setState(() => selectedMode = 'automatic'),
                      );

                      final manualCard = _buildOptionCard(
                        id: 'manual',
                        title: 'Manual',
                        icon: Icons.edit_outlined,
                        description: 'When supplier accepts request, do not update stock immediately. Show a Receive Stock form to specify actual received quantities, batch numbers, and prices.',
                        isSelected: selectedMode == 'manual',
                        onTap: () => setState(() => selectedMode = 'manual'),
                      );

                      final autoConfirmCard = _buildOptionCard(
                        id: 'auto_confirmation',
                        title: 'Auto + Confirmation',
                        icon: Icons.help_outline_rounded,
                        description: 'When supplier accepts request, prompt with \'Receive Stock Now?\' offering instant auto-update or receiving stock manually later.',
                        isSelected: selectedMode == 'auto_confirmation',
                        badgeText: 'RECOMMENDED',
                        onTap: () => setState(() => selectedMode = 'auto_confirmation'),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            autoCard,
                            const SizedBox(height: 14),
                            manualCard,
                            const SizedBox(height: 14),
                            autoConfirmCard,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: autoCard),
                          const SizedBox(width: 14),
                          Expanded(child: manualCard),
                          const SizedBox(width: 14),
                          Expanded(child: autoConfirmCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Save Settings Button (Photo 5)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isSaving ? null : _saveSettings,
                        icon: isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                        label: Text(
                          isSaving ? "Saving..." : "Save Settings",
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        ),
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
  }

  Widget _buildOptionCard({
    required String id,
    required String title,
    required IconData icon,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                width: isSelected ? 1.8 : 1.0,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          title,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 20)
                    else
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
          if (badgeText != null)
            Positioned(
              top: -8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
