import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:billingapp/mainscreen/services/storage_service.dart';
import 'package:billingapp/mainscreen/widgets/pin_pad.dart';
import 'package:billingapp/mainscreen/theme/app_theme.dart';
import 'package:billingapp/mainscreen/screens/login_screen.dart';
import 'package:billingapp/mainscreen/services/biometric_service.dart';
import 'package:billingapp/mainscreen/services/api_service.dart';
import 'package:billingapp/mainscreen/services/security_service.dart';
import 'package:billingapp/mainscreen/services/security_manager.dart';
import 'package:billingapp/mainscreen/repositories/lock_repository.dart';
import 'package:billingapp/mainscreen/screens/mfa_verification_screen.dart';

class AppLockScreen extends StatefulWidget {
  final bool isStartupBlocker;

  const AppLockScreen({
    super.key,
    this.isStartupBlocker = false,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  late StorageService _storageService;
  late SecurityManager _securityManager;
  late LockRepository _lockRepository;

  // Active view: 'pin', 'pattern'
  String _activeView = 'pin';
  String _errorMessage = '';
  bool _showBiometricOption = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _storageService = Provider.of<StorageService>(context, listen: false);
    _securityManager = Provider.of<SecurityManager>(context, listen: false);
    _lockRepository = Provider.of<LockRepository>(context, listen: false);

    // Prioritize active lock view dynamically from SecurityManager
    if (_securityManager.isLockEnabled('pincode')) {
      _activeView = 'pin';
    } else if (_securityManager.isLockEnabled('pattern_lock')) {
      _activeView = 'pattern';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkBiometrics();
      }
    });
  }

  void _showDisabledMethodDialog(String method) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 12.w),
              const Text('Method Disabled'),
            ],
          ),
          content: Text(
            'Enable $method inside the active Security Settings Console first before attempting dynamic sync validations.',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _checkBiometrics() async {
    final biometricService = Provider.of<BiometricService>(context, listen: false);
    
    // Check if biometric options are active
    final bool isFingerprintEnabled = _securityManager.isLockEnabled('fingerprint');
    final bool isFaceEnabled = _securityManager.isLockEnabled('face_lock');

    if (isFingerprintEnabled || isFaceEnabled) {
      final isHardwareAvailable = await biometricService.isHardwareSupported();
      if (isHardwareAvailable) {
        setState(() {
          _showBiometricOption = true;
        });
        
        // Auto trigger at launch if enabled in configurations
        if (_securityManager.isLockEnabled('ask_biometrics_on_open')) {
          Future.delayed(const Duration(milliseconds: 800), () {
            _triggerBiometricAuth();
          });
        }
      }
    }
  }

  void _triggerBiometricAuth() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    try {
      final isFingerprintEnabled = _securityManager.isLockEnabled('fingerprint');
      final isFaceEnabled = _securityManager.isLockEnabled('face_lock');

      if (!isFingerprintEnabled && !isFaceEnabled) {
        _showDisabledMethodDialog('Biometrics (Fingerprint/Face Lock)');
        return;
      }

      final biometricService = Provider.of<BiometricService>(context, listen: false);
      final result = await biometricService.authenticate(
        reason: 'Verify identity to unlock Billing App',
      );
      
      if (result.success) {
        final bool isFace = isFaceEnabled && !isFingerprintEnabled;
        SecurityService(ApiService()).saveLoginHistory(
          userId: 1, 
          method: isFace ? 'face_lock' : 'fingerprint',
        ).catchError((err) {
          debugPrint('DEBUG [AppLockScreen]: Failed saving biometric history: $err');
          return <String, dynamic>{};
        });

        _handleUnlockSuccess();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result.message;
          });
          
          Future.delayed(const Duration(milliseconds: 3500), () {
            if (mounted) {
              setState(() {
                _errorMessage = '';
              });
            }
          });
        }
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  void _handleUnlockSuccess() async {
    final isSmsEnabled = _securityManager.isLockEnabled('sms_otp');
    final isWhatsappEnabled = _securityManager.isLockEnabled('whatsapp_otp');
    final isEmailEnabled = _securityManager.isLockEnabled('mail_otp');

    if (isSmsEnabled || isWhatsappEnabled || isEmailEnabled) {
      if (mounted) {
        final bool verified = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MfaVerificationScreen(
              actionDescription: 'unlock your secure vault dashboard',
            ),
          ),
        ) ?? false;

        if (!verified) {
          if (mounted) {
            setState(() {
              _errorMessage = 'MFA Verification Required to unlock vault.';
            });
          }
          return;
        }
      }
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onPinCompleted(String pin) {
    final isPinEnabled = _securityManager.isLockEnabled('pincode');

    if (!isPinEnabled) {
      _showDisabledMethodDialog('PIN Code Protection');
      return;
    }

    final String savedPin = _lockRepository.getLocalValue('pincode');

    if (pin == savedPin) {
      SecurityService(ApiService()).saveLoginHistory(
        userId: 1, 
        method: 'pincode',
      ).catchError((err) {
        debugPrint('DEBUG [AppLockScreen]: Failed saving pin history: $err');
        return <String, dynamic>{};
      });

      _handleUnlockSuccess();
    } else {
      setState(() {
        _errorMessage = 'Incorrect Security PIN';
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _errorMessage = '';
          });
        }
      });
    }
  }

  void _onPatternCompleted(List<int> pattern) {
    final isPatternEnabled = _securityManager.isLockEnabled('pattern_lock');

    if (!isPatternEnabled) {
      _showDisabledMethodDialog('Pattern Lock');
      return;
    }

    final patternString = pattern.join(',');
    final String savedPattern = _lockRepository.getLocalValue('pattern_lock');

    if (patternString == savedPattern) {
      SecurityService(ApiService()).saveLoginHistory(
        userId: 1, 
        method: 'pattern',
      ).catchError((err) {
        debugPrint('DEBUG [AppLockScreen]: Failed saving pattern history: $err');
        return <String, dynamic>{};
      });

      _handleUnlockSuccess();
    } else {
      setState(() {
        _errorMessage = 'Incorrect Security Pattern';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _errorMessage = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userName = _storageService.userName;
    final userPhoto = _storageService.userPhoto;
    
    // Check if multiple locks are enabled so we can offer toggle option dynamically
    final showToggle = _securityManager.isLockEnabled('pincode') && 
                       _securityManager.isLockEnabled('pattern_lock');

    final bool hasPinActive = _securityManager.isLockEnabled('pincode');
    final bool hasPatternActive = _securityManager.isLockEnabled('pattern_lock');

    Widget lockBody;
    if (_activeView == 'pin' && hasPinActive) {
      lockBody = PinPad(
        onPinCompleted: _onPinCompleted,
        showBiometricButton: _showBiometricOption,
        onBiometricPressed: _triggerBiometricAuth,
        errorMessage: _errorMessage,
      );
    } else if (hasPatternActive) {
      // Pattern Lock View
      lockBody = Column(
        children: [
          Container(
            height: 280.h,
            width: 280.w,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                width: 1.5,
              ),
            ),
            child: PatternLock(
              selectedColor: Theme.of(context).colorScheme.primary,
              dimension: 3,
              pointRadius: 8,
              showInput: true,
              onInputComplete: _onPatternCompleted,
            ),
          ),
          if (_errorMessage.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              _errorMessage,
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            SizedBox(height: 16.h),
            Text(
              'Draw pattern to verify your security clearance',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_showBiometricOption) ...[
            SizedBox(height: 24.h),
            IconButton.filledTonal(
              iconSize: 32.r,
              padding: const EdgeInsets.all(16),
              icon: Icon(
                Icons.fingerprint_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _triggerBiometricAuth,
            ),
          ],
        ],
      );
    } else {
      // Default fallback lock fallback body
      lockBody = Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.shield_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Authentication Cleared',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _handleUnlockSuccess,
              child: const Text('Enter Terminal'),
            )
          ],
        ),
      );
    }

    return PopScope(
      canPop: !widget.isStartupBlocker, // Block back navigation at launch
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) => Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode 
                    ? AppTheme.darkBackgroundGradient 
                    : AppTheme.lightBackgroundGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      
                      // Lock Emblem and App Lock header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 16.w,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'BILLING APP SECURE VAULT',
                            style: GoogleFonts.outfit(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 32.h),

                      // User Profile Info
                      Center(
                        child: Column(
                          children: [
                            // Profile Avatar
                            Container(
                              width: 80.r,
                              height: 80.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                    blurRadius: 16,
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: userPhoto.isNotEmpty
                                    ? Image.network(
                                        userPhoto,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
                                      )
                                    : const Icon(Icons.person, size: 40),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            
                            // Name & Instructions
                            Text(
                              'Authorized Access Only',
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Clearance: $userName',
                              style: GoogleFonts.outfit(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // Lock Body (PIN pad or Pattern drawing)
                      lockBody,
                      
                      SizedBox(height: 30.h),
                      
                      // Toggle button if both active
                      if (showToggle)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _activeView = _activeView == 'pin' ? 'pattern' : 'pin';
                              _errorMessage = '';
                            });
                          },
                          icon: Icon(
                            _activeView == 'pin' ? Icons.gesture_rounded : Icons.dialpad_rounded,
                            size: 18.w,
                          ),
                          label: Text(
                            _activeView == 'pin' ? 'Switch to Pattern Lock' : 'Switch to PIN Lock',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      
                      // Startup blocker back button to Login
                      if (widget.isStartupBlocker) ...[
                        SizedBox(height: 10.h),
                        TextButton(
                          onPressed: () async {
                            // Clear auth session so user can log in with different profile
                            await _storageService.clearAuthSession();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                              );
                            }
                          },
                          child: Text(
                            'Log Out / Switch Account',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
