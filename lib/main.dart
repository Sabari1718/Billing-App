import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Auth/login.dart';
import 'Auth/select.dart';
import 'Auth/billing dashboardc.dart';
import 'Auth/role_selection.dart';
import 'mainscreen/screens/login_screen.dart';
import 'package:billingapp/utils/app_logger.dart';

import 'package:billingapp/localization/translations.dart';

import 'package:provider/provider.dart' as provider_pkg;
import 'package:billingapp/mainscreen/services/storage_service.dart';
import 'package:billingapp/mainscreen/services/secure_storage_service.dart';
import 'package:billingapp/mainscreen/services/api_service.dart' as main_api;
import 'package:billingapp/mainscreen/repositories/lock_repository.dart';
import 'package:billingapp/mainscreen/services/lock_service.dart';
import 'package:billingapp/mainscreen/services/security_manager.dart';
import 'package:billingapp/mainscreen/appcontroler/appcontroler/mobile_validation_service.dart';
import 'package:billingapp/mainscreen/services/auth_service.dart' as main_auth;
import 'package:billingapp/mainscreen/services/biometric_service.dart';
import 'package:billingapp/mainscreen/theme/theme_provider.dart';
import 'package:billingapp/mainscreen/providers/security_auth_provider.dart';
import 'package:billingapp/mainscreen/providers/grid_card_provider.dart';
import 'package:billingapp/mainscreen/providers/security_settings_provider.dart';
import 'package:billingapp/mainscreen/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persistence cache storage for lockscreen/mainscreen
  final storageService = await StorageService.getInstance();
  final secureStorage = await SecureStorageService.getInstance();
  final apiService = main_api.ApiService();
  final lockRepository = LockRepository(apiService: apiService, secureStorage: secureStorage);
  final lockService = LockService(repo: lockRepository);
  final securityManager = SecurityManager(repository: lockRepository, lockService: lockService);

  // Trigger dynamic live synchronization with Mobile Validation API
  MobileValidationService.syncUserAppData();

  final prefs = await SharedPreferences.getInstance();
  final langCode = prefs.getString("selected_language_code") ?? "en";
  final countryCode = prefs.getString("selected_country_code") ?? "US";

  runApp(
    provider_pkg.MultiProvider(
      providers: [
        provider_pkg.Provider<StorageService>.value(value: storageService),
        provider_pkg.Provider<SecureStorageService>.value(value: secureStorage),
        provider_pkg.Provider<main_api.ApiService>.value(value: apiService),
        provider_pkg.Provider<LockRepository>.value(value: lockRepository),
        provider_pkg.Provider<LockService>.value(value: lockService),
        provider_pkg.ChangeNotifierProvider<SecurityManager>.value(value: securityManager),
        
        provider_pkg.Provider<main_auth.AuthService>(
          create: (context) => main_auth.AuthService(storageService),
        ),
        
        provider_pkg.Provider<BiometricService>(
          create: (context) => BiometricService(),
        ),
        
        provider_pkg.ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(storageService),
        ),
        
        provider_pkg.ChangeNotifierProvider<SecurityAuthProvider>(
          create: (context) => SecurityAuthProvider(),
        ),

        provider_pkg.ChangeNotifierProvider<GridCardProvider>(
          create: (context) => GridCardProvider(),
        ),

        provider_pkg.ChangeNotifierProvider<SecuritySettingsProvider>(
          create: (context) => SecuritySettingsProvider()..fetchSettings(),
        ),
      ],
      child: MyApp(initialLocale: Locale(langCode, countryCode)),
    ),
  );
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MyApp extends StatelessWidget {
  final Locale initialLocale;
  const MyApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return GetMaterialApp(
          translations: AppTranslations(),
          locale: initialLocale,
          fallbackLocale: const Locale('en', 'US'),
          debugShowCheckedModeBanner: false,
          title: 'Billing App',

      theme: ThemeData(
        useMaterial3: true,

        // ✅ FIXED: Proper ColorScheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),

        scaffoldBackgroundColor: const Color(0xFFF3F4F6),

        // ✅ Font
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),

        // ✅ AppBar
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        // ✅ Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),

          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),

        // ✅ Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ✅ Cards
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),

      // ✅ ROUTES
      routes: {
        '/login': (context) => const LoginScreen(),
      },

      // ✅ AUTH WRAPPER INSTEAD OF DIRECT LOGIN PAGE
      home: const SplashScreen(),
      
      themeMode: currentMode,
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF1F2937), // Dark Gray
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for exactly 3 seconds splash duration
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("auth_token");
    final Object? rawBusinessId = prefs.get("business_id");
    final String? businessId = rawBusinessId?.toString();

    if (token != null && token.isNotEmpty) {
      // Token exists, check if business is also selected to go to Dashboard
      if (businessId != null && businessId.isNotEmpty) {
        setState(() => _startScreen = const RoleSelectionPage());
      } else {
        setState(() => _startScreen = BusinessSelectionPage());
      }
    } else {
      // No token, show login
      setState(() {
        _startScreen = LoginPage(
          onLogin: () {
            AppLogger.success("User logged in successfully");
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startScreen == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset(
            'assets/images.png',
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    return _startScreen!;
  }
}
