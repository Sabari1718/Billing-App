import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/Auth/api service.dart';

class ManageDashboardPage extends StatefulWidget {
  const ManageDashboardPage({super.key});

  @override
  State<ManageDashboardPage> createState() => _ManageDashboardPageState();
}

class _ManageDashboardPageState extends State<ManageDashboardPage> {
  bool _isLoading = true;
  String _billingEntries = "0";
  String _productEntries = "0";
  String _customerEntries = "0";
  String _totalEntries = "0";
  List<dynamic> _submissions = [];

  @override
  void initState() {
    super.initState();
    _fetchCountData();
  }

  Future<void> _fetchCountData() async {
    try {
      final response = await ApiService.getEmployeeCountData();
      
      // Parse response safely handling nested 'data' or direct keys
      final data = response['data'] ?? response;
      
      setState(() {
        _billingEntries = (data['billing_entries'] ?? data['billing_count'] ?? data['billings'] ?? "0").toString();
        _productEntries = (data['product_entries'] ?? data['product_count'] ?? data['products'] ?? "0").toString();
        _customerEntries = (data['customer_entries'] ?? data['customer_count'] ?? data['customers'] ?? "0").toString();
        _totalEntries = (data['total_entries'] ?? data['total_count'] ?? data['total'] ?? "0").toString();
        
        if (data['submissions'] != null && data['submissions'] is List) {
          _submissions = data['submissions'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          )
        : RefreshIndicator(
            onRefresh: _fetchCountData,
            color: const Color(0xFF4F46E5),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dashboard",
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Welcome back, Admin — here's your overview.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grid of 4 Stat Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _buildStatCard(
                        title: "BILLING ENTRIES",
                        value: _billingEntries,
                        icon: Icons.circle_outlined,
                        iconColor: const Color(0xFFEC4899),
                        bgColor: const Color(0xFFFDF2F8),
                      ),
                      _buildStatCard(
                        title: "PRODUCT ENTRIES",
                        value: _productEntries,
                        icon: Icons.outlined_flag_rounded,
                        iconColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFECFDF5),
                      ),
                      _buildStatCard(
                        title: "CUSTOMER ENTRIES",
                        value: _customerEntries,
                        icon: Icons.circle_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFFEF3C7),
                      ),
                      _buildStatCard(
                        title: "TOTAL ENTRIES",
                        value: _totalEntries,
                        icon: Icons.bar_chart_rounded,
                        iconColor: const Color(0xFF6366F1),
                        bgColor: const Color(0xFFEEF2FF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bottom card: ALL EMPLOYEE ENTRY SUBMISSIONS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ALL EMPLOYEE ENTRY SUBMISSIONS",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_submissions.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.inbox_outlined,
                                    size: 32,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No entry submissions found",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Submissions will appear here in real-time.",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _submissions.length,
                            separatorBuilder: (_, __) => const Divider(height: 20),
                            itemBuilder: (context, idx) {
                              final item = _submissions[idx];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  child: Text(
                                    (item['name'] ?? "E").toString().substring(0, 1).toUpperCase(),
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
                                  ),
                                ),
                                title: Text(
                                  (item['name'] ?? "Employee").toString(),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  (item['description'] ?? "Submitted entry").toString(),
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                ),
                                trailing: Text(
                                  (item['value'] ?? "").toString(),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "Live stats",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
