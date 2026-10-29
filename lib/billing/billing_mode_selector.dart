import 'package:flutter/material.dart';
import 'package:billingapp/billing/Generate Bill.dart';
import 'package:billingapp/billing/purchase_bill_entry.dart';

class BillingModeSelector extends StatelessWidget {
  final String currentMode; // "Sale" or "Purchase"
  final bool? isDark;

  const BillingModeSelector({super.key, required this.currentMode, this.isDark});

  @override
  Widget build(BuildContext context) {
    final bool effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: PopupMenuButton<String>(
          tooltip: "Switch Transaction Mode",
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: effectiveDark ? Colors.white12 : Colors.grey.shade200),
          ),
          color: effectiveDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 8,
          onSelected: (mode) {
            if (mode == currentMode) return;
            if (mode == "Purchase") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseBillEntryPage()),
              );
            } else if (mode == "Sale") {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerScreen()),
                );
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              enabled: false,
              height: 28,
              child: Text(
                "BILLING TRANSACTION MODE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: "Sale",
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFF059669)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Sale",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: effectiveDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            "Sales bills, invoices & customer returns",
                            style: TextStyle(
                              fontSize: 10,
                              color: effectiveDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (currentMode == "Sale")
                      const Icon(Icons.check, size: 18, color: Color(0xFF0D6EFD)),
                  ],
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: "Purchase",
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: effectiveDark ? const Color(0xFF312E81) : const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: effectiveDark ? const Color(0xFF4338CA) : const Color(0xFFDDD6FE)),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF818CF8)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Purchase",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: effectiveDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            "Purchase bills, vendor invoices & returns",
                            style: TextStyle(
                              fontSize: 10,
                              color: effectiveDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (currentMode == "Purchase")
                      const Icon(Icons.check, size: 18, color: Color(0xFF0D6EFD)),
                  ],
                ),
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: effectiveDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: effectiveDark ? Colors.white12 : Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentMode == "Sale" ? const Color(0xFF10B981) : const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currentMode,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: effectiveDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: effectiveDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
