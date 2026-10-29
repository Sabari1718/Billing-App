import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

////////////////////////////////////////////////////////////
/// 1. HERO BANNER
////////////////////////////////////////////////////////////
class DashboardHeroBanner extends StatelessWidget {
  final String userName;
  final String storeName;
  final VoidCallback onAnnouncementsTap;

  const DashboardHeroBanner({
    super.key,
    required this.userName,
    required this.storeName,
    required this.onAnnouncementsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D4ED8), // Deep vibrant blue
            Color(0xFF2563EB), // Royal blue
            Color(0xFF3B82F6), // Sky highlight
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello $userName!",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Welcome to your business analytics dashboard.",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAnnouncementsTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.campaign_outlined, color: Colors.white, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          "Updates",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (storeName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white70, size: 13),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
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
                    "Active",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6EE7B7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 2. STAT CARD
////////////////////////////////////////////////////////////
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withOpacity(0.3),
                width: 1.2,
              ),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 3. INTERACTIVE CHART CARD
////////////////////////////////////////////////////////////
class DashboardChartCard extends StatelessWidget {
  final double grossSales;
  final String chartMode; // "Bar", "Line", "Candle"
  final String selectedPeriod;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onPeriodChanged;
  final Map<int, double> monthlySales;
  final Map<int, double> monthlyPurchases;

  const DashboardChartCard({
    super.key,
    required this.grossSales,
    required this.chartMode,
    required this.selectedPeriod,
    required this.onModeChanged,
    required this.onPeriodChanged,
    required this.monthlySales,
    required this.monthlyPurchases,
  });

  String _formatCurrency(double val) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(val);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Sales value & controls
          // Top row: Sales value & Period dropdown (2-Column clean fit)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(grossSales),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Gross Sales",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Period Dropdown
              PopupMenuButton<String>(
                onSelected: onPeriodChanged,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                itemBuilder: (context) => [
                  _buildMenuItem("This Day", isDark),
                  _buildMenuItem("This Week", isDark),
                  _buildMenuItem("This Month", isDark),
                  _buildMenuItem("This Year", isDark),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedPeriod,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Second Row: Mode switcher (Bar | Line | Candle)
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeButton("Bar", Icons.bar_chart_rounded, isDark),
                  _buildModeButton("Line", Icons.show_chart_rounded, isDark),
                  _buildModeButton("Candle", Icons.candlestick_chart_rounded, isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Chart Display Area
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _DashboardChartPainter(
                mode: chartMode,
                monthlySales: monthlySales,
                monthlyPurchases: monthlyPurchases,
                isDark: isDark,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 6,
              children: [
                _buildLegendItem(const Color(0xFF7C3AED), "Income (Sales)", isDark),
                _buildLegendItem(const Color(0xFFEA580C), "Expense (Purchases)", isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, IconData icon, bool isDark) {
    final isSelected = chartMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3B82F6) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF1D4ED8))
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            Text(
              mode,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF1D4ED8))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String text, bool isDark) {
    return PopupMenuItem<String>(
      value: text,
      height: 36,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selectedPeriod == text ? FontWeight.w700 : FontWeight.w500,
          color: selectedPeriod == text
              ? const Color(0xFF2563EB)
              : (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////
/// 4. BOTTOM DUAL METRIC CARDS
////////////////////////////////////////////////////////////
class DashboardBottomCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  const DashboardBottomCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: onPeriodChanged,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                itemBuilder: (context) => [
                  PopupMenuItem(value: "This Day", height: 32, child: Text("Day", style: GoogleFonts.inter(fontSize: 11))),
                  PopupMenuItem(value: "This Week", height: 32, child: Text("Week", style: GoogleFonts.inter(fontSize: 11))),
                  PopupMenuItem(value: "This Month", height: 32, child: Text("Month", style: GoogleFonts.inter(fontSize: 11))),
                  PopupMenuItem(value: "This Year", height: 32, child: Text("Year", style: GoogleFonts.inter(fontSize: 11))),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        period.replaceAll("This ", ""),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down, size: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 5. HIGH PERFORMANCE CHART PAINTER (Bar / Line / Candle)
////////////////////////////////////////////////////////////
class _DashboardChartPainter extends CustomPainter {
  final String mode;
  final Map<int, double> monthlySales;
  final Map<int, double> monthlyPurchases;
  final bool isDark;

  _DashboardChartPainter({
    required this.mode,
    required this.monthlySales,
    required this.monthlyPurchases,
    required this.isDark,
  });

  static const List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomPadding = 24.0;
    final chartHeight = size.height - bottomPadding;
    final width = size.width;

    // Grid baseline
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF334155).withOpacity(0.4) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(width, chartHeight),
      gridPaint,
    );

    // Subtle dashed baseline lines
    final dashPaint = Paint()
      ..color = isDark ? const Color(0xFF334155).withOpacity(0.2) : const Color(0xFFF1F5F9)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, chartHeight * 0.5), Offset(width, chartHeight * 0.5), dashPaint);

    // Compute max value for normalization
    double maxVal = 1000.0;
    for (int i = 1; i <= 12; i++) {
      maxVal = max(maxVal, monthlySales[i] ?? 0.0);
      maxVal = max(maxVal, monthlyPurchases[i] ?? 0.0);
    }
    // High July spike support (ensure minimum visualization if sample numbers)
    if (maxVal < 10000) maxVal = 10000;

    final double stepX = width / 12;

    // Draw Month Labels
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < 12; i++) {
      final x = (i * stepX) + (stepX / 2);
      textPainter.text = TextSpan(
        text: months[i],
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), chartHeight + 8));
    }

    if (mode == "Bar") {
      _paintBarChart(canvas, size, chartHeight, stepX, maxVal);
    } else if (mode == "Line") {
      _paintLineChart(canvas, size, chartHeight, stepX, maxVal);
    } else if (mode == "Candle") {
      _paintCandleChart(canvas, size, chartHeight, stepX, maxVal);
    }
  }

  void _paintBarChart(Canvas canvas, Size size, double chartHeight, double stepX, double maxVal) {
    const double barWidth = 6.0;
    final incomePaint = Paint()..color = const Color(0xFF7C3AED);
    final expensePaint = Paint()..color = const Color(0xFFEA580C);

    for (int i = 0; i < 12; i++) {
      final month = i + 1;
      final income = monthlySales[month] ?? 0.0;
      final expense = monthlyPurchases[month] ?? 0.0;

      // Scaled heights with min visual height
      final hIncome = income > 0 ? max(4.0, (income / maxVal) * (chartHeight * 0.85)) : 3.0;
      final hExpense = expense > 0 ? max(4.0, (expense / maxVal) * (chartHeight * 0.85)) : 3.0;

      final centerX = (i * stepX) + (stepX / 2);

      // Income bar (left)
      final rectIncome = RRect.fromRectAndCorners(
        Rect.fromLTWH(centerX - barWidth - 1, chartHeight - hIncome, barWidth, hIncome),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rectIncome, incomePaint);

      // Expense bar (right)
      final rectExpense = RRect.fromRectAndCorners(
        Rect.fromLTWH(centerX + 1, chartHeight - hExpense, barWidth, hExpense),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rectExpense, expensePaint);
    }
  }

  void _paintLineChart(Canvas canvas, Size size, double chartHeight, double stepX, double maxVal) {
    final Path incomePath = Path();
    final Path fillPath = Path();
    final Path expensePath = Path();

    List<Offset> incomePoints = [];
    List<Offset> expensePoints = [];

    for (int i = 0; i < 12; i++) {
      final month = i + 1;
      final income = monthlySales[month] ?? 0.0;
      final expense = monthlyPurchases[month] ?? 0.0;

      final x = (i * stepX) + (stepX / 2);
      final yIncome = chartHeight - (income > 0 ? max(4.0, (income / maxVal) * (chartHeight * 0.85)) : 4.0);
      final yExpense = chartHeight - (expense > 0 ? max(4.0, (expense / maxVal) * (chartHeight * 0.85)) : 4.0);

      incomePoints.add(Offset(x, yIncome));
      expensePoints.add(Offset(x, yExpense));
    }

    // Build smooth Bezier path for Income
    incomePath.moveTo(incomePoints[0].dx, incomePoints[0].dy);
    fillPath.moveTo(incomePoints[0].dx, chartHeight);
    fillPath.lineTo(incomePoints[0].dx, incomePoints[0].dy);

    for (int i = 0; i < incomePoints.length - 1; i++) {
      final p0 = incomePoints[i];
      final p1 = incomePoints[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      incomePath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(incomePoints.last.dx, chartHeight);
    fillPath.close();

    // Gradient fill under teal curve (as in screenshot 3)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0D9488).withOpacity(0.3),
          const Color(0xFF0D9488).withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF0D9488) // Vibrant teal as shown in web screenshot
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(incomePath, linePaint);

    // Build smooth Bezier path for Expense
    expensePath.moveTo(expensePoints[0].dx, expensePoints[0].dy);
    for (int i = 0; i < expensePoints.length - 1; i++) {
      final p0 = expensePoints[i];
      final p1 = expensePoints[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      expensePath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }
    final expenseLinePaint = Paint()
      ..color = const Color(0xFF3B82F6) // Soft blue line as in screenshot
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(expensePath, expenseLinePaint);
  }

  void _paintCandleChart(Canvas canvas, Size size, double chartHeight, double stepX, double maxVal) {
    const double candleWidth = 14.0;

    for (int i = 0; i < 12; i++) {
      final month = i + 1;
      final income = monthlySales[month] ?? 0.0;
      final expense = monthlyPurchases[month] ?? 0.0;

      final isBullish = income >= expense;
      final candleColor = isBullish ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

      final candlePaint = Paint()
        ..color = candleColor
        ..style = PaintingStyle.fill;

      final wickPaint = Paint()
        ..color = candleColor
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      final centerX = (i * stepX) + (stepX / 2);

      final double high = max(income, expense);
      final double low = min(income, expense);

      // Scaled dimensions
      final double highY = chartHeight - max(6.0, (high / maxVal) * (chartHeight * 0.85));
      final double lowY = chartHeight - max(3.0, (low / maxVal) * (chartHeight * 0.85));

      final double bodyTop = isBullish ? lowY - ((lowY - highY) * 0.8) : highY;
      final double bodyBottom = isBullish ? lowY : highY + max(6.0, (lowY - highY) * 0.8);
      final double bodyHeight = max(4.0, (bodyBottom - bodyTop).abs());

      // Wick
      canvas.drawLine(
        Offset(centerX, highY - 4),
        Offset(centerX, chartHeight - 2),
        wickPaint,
      );

      // Candle body
      final candleRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, (bodyTop + bodyBottom) / 2),
          width: candleWidth,
          height: bodyHeight,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(candleRect, candlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardChartPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.monthlySales != monthlySales ||
        oldDelegate.monthlyPurchases != monthlyPurchases ||
        oldDelegate.isDark != isDark;
  }
}
