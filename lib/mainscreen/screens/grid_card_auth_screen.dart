import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:billingapp/mainscreen/utils/constants.dart';
import 'package:billingapp/mainscreen/providers/grid_card_provider.dart';
import 'package:billingapp/mainscreen/services/storage_service.dart';
import 'package:billingapp/mainscreen/utils/ui_helpers.dart';

class GridCardAuthScreen extends StatefulWidget {
  const GridCardAuthScreen({super.key});

  @override
  State<GridCardAuthScreen> createState() => _GridCardAuthScreenState();
}

class _GridCardAuthScreenState extends State<GridCardAuthScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Screen mode: 'view' (shows physical grid card), 'verify' (shows coordinates challenge inputs)
  String _currentMode = 'view'; 

  // Decodes dynamic JWT payload user_main_id
  String _getUserMainId(BuildContext context) {
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = storage.authToken;
      if (token.isEmpty) return storage.userId;

      final parts = token.split('.');
      if (parts.length >= 2) {
        final payload = parts[1];
        final normalized = Uri.decodeComponent(
          List.generate(
            (4 - payload.length % 4) % 4,
            (index) => '=',
          ).join(''),
        );
        final base64String = payload + normalized;
        final decoded = String.fromCharCodes(
          base64.decode(base64String.replaceAll('-', '+').replaceAll('_', '/')),
        );
        final dynamic map = jsonDecode(decoded);
        return (map['user_main_id'] ?? storage.userId).toString();
      }
    } catch (_) {}
    final storage = Provider.of<StorageService>(context, listen: false);
    return storage.userId.isNotEmpty ? storage.userId : "4883898579";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // WillPopScope protects against system pop when in active verification mode and unfocuses
    return WillPopScope(
      onWillPop: () async {
        FocusScope.of(context).unfocus();
        if (_currentMode == 'verify') {
          setState(() {
            _currentMode = 'view';
          });
          return false;
        }
        context.read<GridCardProvider>().logBackNavigation();
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () {
                FocusScope.of(context).unfocus();
                if (_currentMode == 'verify') {
                  context.read<GridCardProvider>().logBackNavigation();
                  setState(() {
                    _currentMode = 'view';
                  });
                } else {
                  context.read<GridCardProvider>().logBackNavigation();
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              'Multi-Factor Grid',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: RepaintBoundary(
            child: Selector<GridCardProvider, bool>(
              selector: (_, p) => p.isLoading,
              builder: (context, isLoading, _) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppConstants.accentColor));
                }

                return Selector<GridCardProvider, bool>(
                  selector: (_, p) => p.isCardGenerated,
                  builder: (context, isCardGenerated, _) {
                    // SCREEN 1 — Activate Grid Card
                    if (!isCardGenerated) {
                      return _buildActivationScreen(context);
                    }

                    // SCREEN 2 & SCREEN 3
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_currentMode == 'view') ...[
                              _buildGridCardWidget(context),
                              SizedBox(height: 32.h),
                              _buildActionButtons(context),
                            ] else ...[
                              GridVerificationWidget(
                                userMainId: _getUserMainId(context),
                                onCancel: () {
                                  FocusScope.of(context).unfocus();
                                  context.read<GridCardProvider>().logBackNavigation();
                                  setState(() {
                                    _currentMode = 'view';
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- SCREEN 1: Activate Grid Card ---
  Widget _buildActivationScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<GridCardProvider>();

    return Padding(
      padding: EdgeInsets.all(28.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF161B22) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.accentColor.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
            child: Icon(
              Icons.grid_view_rounded,
              size: 80.r,
              color: AppConstants.accentColor,
            ),
          ),
          SizedBox(height: 40.h),
          Text(
            "Activate Multi-Factor Grid Card",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "Enhance your terminal vault with geometric coordinate keys. Generate a unique grid of security codes synchronized with the server to protect transactions.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 18.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: () async {
                final dynamic userId = _getUserMainId(context);
                final bool success = await provider.generateGridCard(userId);
                if (success) {
                  UiHelpers.showSuccessMessage(context, "Saved Successfully");
                } else {
                  UiHelpers.showErrorMessage(context, "Activation failed. Please check network connection.");
                }
              },
              child: Text(
                "Generate My Grid Card",
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // --- SCREEN 2: Premium Physical Grid Card UI ---
  Widget _buildGridCardWidget(BuildContext context) {
    final provider = context.read<GridCardProvider>();
    final card = provider.gridCard!;
    
    final List<String> cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    final List<String> rows = ['1', '2', '3', '4', '5'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of physical card
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_rounded, color: AppConstants.accentColor, size: 24.r),
                    SizedBox(width: 8.w),
                    Text(
                      "ANTIGRAVITY SHIELD",
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                Text(
                  "SECURE MATRIX",
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Chip & Wi-Fi Icon style
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(Icons.wifi_tethering_rounded, color: Colors.white.withOpacity(0.2), size: 20.r),
              ],
            ),
          ),
          
          SizedBox(height: 16.h),

          // The Dynamic Responsive Table Grid A-G
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Table(
                defaultColumnWidth: FixedColumnWidth(44.w),
                border: TableBorder.all(color: Colors.white.withOpacity(0.04), width: 1),
                children: [
                  TableRow(
                    children: [
                      const TableCell(child: SizedBox()),
                      for (var c in cols)
                        TableCell(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 6.h),
                              child: Text(
                                c,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color: AppConstants.accentColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Data Rows: 1-5
                  for (var r in rows)
                    TableRow(
                      children: [
                        // Row index label
                        TableCell(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Text(
                                r,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Dynamic values matching coordinates
                        for (var c in cols)
                          TableCell(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Text(
                                  card.gridData['$c$r'] ?? '---',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // Serial Number section below grid
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28.r),
                bottomRight: Radius.circular(28.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CARD SERIAL NUMBER",
                      style: GoogleFonts.outfit(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      card.cardSerialNumber.replaceAllMapped(
                        RegExp(r".{4}"),
                        (match) => "${match.group(0)} ",
                      ),
                      style: GoogleFonts.shareTechMono(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.qr_code_2_rounded, color: Colors.white.withOpacity(0.4), size: 28.r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Grid display action buttons ---
  Widget _buildActionButtons(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<GridCardProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 18.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            onPressed: () {
              // Ensure coordinates exist on initial challenge load
              if (provider.currentChallenge.isEmpty || provider.controllers.isEmpty) {
                provider.generateChallenge();
              }
              
              setState(() {
                _currentMode = 'verify';
              });
            },
            child: Text(
              "Launch Verification Challenge",
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          onPressed: () => provider.deleteGridCard(),
          child: Text(
            "Deactivate and Clear Card",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }
}

// --- OPTIMIZED ISOLATED VERIFICATION WIDGET ---
class GridVerificationWidget extends StatefulWidget {
  final String userMainId;
  final VoidCallback onCancel;

  const GridVerificationWidget({
    super.key,
    required this.userMainId,
    required this.onCancel,
  });

  @override
  State<GridVerificationWidget> createState() => _GridVerificationWidgetState();
}

class _GridVerificationWidgetState extends State<GridVerificationWidget> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<GridCardProvider>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Security Coordinates Required",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Selector<GridCardProvider, String>(
                      selector: (_, p) => p.gridCard?.cardSerialNumber ?? '',
                      builder: (_, serialNumber, _) {
                        return Text(
                          "Serial: $serialNumber",
                          style: GoogleFonts.shareTechMono(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // New Challenge button: ONLY this scrambles and resets state
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, color: AppConstants.accentColor),
                label: Text(
                  "New Challenge",
                  style: GoogleFonts.outfit(
                    color: AppConstants.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                onPressed: () {
                  context.read<GridCardProvider>().generateChallenge();
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Coordinate label indicators
          Center(
            child: Selector<GridCardProvider, List<String>>(
              selector: (_, p) => p.currentChallenge,
              builder: (_, challenge, _) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: challenge.map((coord) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppConstants.accentColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.accentColor.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Text(
                        coord,
                        style: GoogleFonts.shareTechMono(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.accentColor,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 36),

          // Input boxes corresponding to coordinates
          Selector<GridCardProvider, List<String>>(
            selector: (_, p) => p.currentChallenge,
            builder: (context, challenge, _) {
              return Column(
                children: challenge.map((coord) {
                  final controller = provider.controllers[coord];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 3,
                      textInputAction: TextInputAction.next,
                      enableSuggestions: false,
                      autocorrect: false,
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            "$coord →",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        hintText: "Enter value",
                        hintStyle: GoogleFonts.outfit(fontSize: 14.sp, color: Colors.grey[500]),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF161B22) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppConstants.accentColor, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Required";
                        }
                        return null;
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 32),

          // Submit and Verify button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final List<String> challenges = List.from(provider.currentChallenge);
                  final List<String> answers = challenges.map((coord) {
                    return provider.controllers[coord]?.text.trim() ?? "";
                  }).toList();

                  // Validate all fields are filled
                  final bool anyEmpty = answers.any((a) => a.isEmpty);
                  if (anyEmpty) {
                    UiHelpers.showErrorMessage(context, "Please fill all coordinate values");
                    return;
                  }

                  final bool correct = await provider.verifyGrid(
                    userMainId: widget.userMainId,
                    challenges: challenges,
                    answers: answers,
                  );

                  if (correct) {
                    UiHelpers.showSuccessMessage(context, "Saved Successfully");
                    
                    final storage = Provider.of<StorageService>(context, listen: false);
                    await storage.setGridLockEnabled(false); // Do not auto-enable on setup!

                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  } else {
                    UiHelpers.showErrorMessage(context, "Grid Authentication verification failed.");
                  }
                }
              },
              child: Text(
                "Submit and Verify",
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Cancel Verification Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: widget.onCancel,
            child: Text(
              "Cancel",
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
