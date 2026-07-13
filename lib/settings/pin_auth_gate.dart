import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billingapp/Auth/api service.dart';
import 'manage_portal.dart';

class PinAuthGatePage extends StatefulWidget {
  const PinAuthGatePage({super.key});

  @override
  State<PinAuthGatePage> createState() => _PinAuthGatePageState();
}

class _PinAuthGatePageState extends State<PinAuthGatePage> {
  String _pin = '';
  bool _isLoading = false;

  void _onKeyPress(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
      });

      // Auto submit when 4 digits are completed
      if (_pin.length == 4) {
        _authenticatePIN();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _authenticatePIN() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bool success = await ApiService.verifyPin(_pin);

      if (success) {
        if (mounted) {
          // Go to Manage Portal Page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ManagePortalPage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Incorrect Security PIN. Access Denied.",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _pin = '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Authentication error occurred. Please try again.",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _pin = '';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Shield Glow Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  color: Color(0xFF4F46E5),
                  size: 48,
                ),
              ),
              const SizedBox(height: 30),

              // Title
              Text(
                "Enter Security PIN",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                "Access to the management panel requires administrative PIN authorization.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 40),

              // Loading Spinner or Dot Indicator
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final hasDigit = index < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: hasDigit ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasDigit ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 50),

              // Custom Pinpad
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((digit) {
                    return _buildPinpadButton(digit, () => _onKeyPress(digit));
                  }),
                  _buildPinpadButton('Clear', () => setState(() => _pin = '')),
                  _buildPinpadButton('0', () => _onKeyPress('0')),
                  _buildBackspaceButton(),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinpadButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: label == 'Clear' ? 14 : 22,
            fontWeight: label == 'Clear' ? FontWeight.w600 : FontWeight.bold,
            color: label == 'Clear' ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onBackspace,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: const Icon(
          Icons.backspace_outlined,
          color: Color(0xFF64748B),
          size: 22,
        ),
      ),
    );
  }
}
