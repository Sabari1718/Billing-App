import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:billingapp/mainscreen/services/storage_service.dart';
import 'package:billingapp/mainscreen/services/auth_service.dart';
import 'package:billingapp/mainscreen/services/biometric_service.dart';
import 'package:billingapp/mainscreen/theme/theme_provider.dart';
import 'package:billingapp/mainscreen/theme/app_theme.dart';
import 'package:billingapp/mainscreen/screens/splash_screen.dart';
import 'package:billingapp/mainscreen/screens/login_screen.dart';

import 'package:billingapp/mainscreen/providers/security_auth_provider.dart';
import 'package:billingapp/mainscreen/providers/grid_card_provider.dart';
import 'package:billingapp/mainscreen/providers/security_settings_provider.dart';

import 'package:billingapp/mainscreen/services/secure_storage_service.dart';
import 'package:billingapp/mainscreen/services/api_service.dart';
import 'package:billingapp/mainscreen/repositories/lock_repository.dart';
import 'package:billingapp/mainscreen/services/lock_service.dart';
import 'package:billingapp/mainscreen/services/security_manager.dart';
import 'package:billingapp/mainscreen/appcontroler/appcontroler/mobile_validation_service.dart';
import 'package:billingapp/mainscreen/services/custom_flow_service.dart';

void main() async {
  // Ensure Flutter engine integrations are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load persistence cache storage
  final storageService = await StorageService.getInstance();
  final secureStorage = await SecureStorageService.getInstance();
  final apiService = ApiService();
  final lockRepository = LockRepository(apiService: apiService, secureStorage: secureStorage);
  final lockService = LockService(repo: lockRepository);
  final securityManager = SecurityManager(repository: lockRepository, lockService: lockService);

  // Trigger dynamic live synchronization with Mobile Validation API
  MobileValidationService.syncUserAppData();

  runApp(
    MultiProvider(
      providers: [
        // Singleton local storage database access
        Provider<StorageService>.value(value: storageService),
        Provider<SecureStorageService>.value(value: secureStorage),
        Provider<ApiService>.value(value: apiService),
        Provider<LockRepository>.value(value: lockRepository),
        Provider<LockService>.value(value: lockService),
        ChangeNotifierProvider<SecurityManager>.value(value: securityManager),
        
        // Local authorization services
        Provider<AuthService>(
          create: (context) => AuthService(storageService),
        ),
        
        // Dedicated Biometric Hardware service
        Provider<BiometricService>(
          create: (context) => BiometricService(),
        ),
        
        // Dynamically synced Material 3 Dark/Light themes
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(storageService),
        ),
        
        // Security Tab Authentication Provider
        ChangeNotifierProvider<SecurityAuthProvider>(
          create: (context) => SecurityAuthProvider(),
        ),

        // Grid Card Authentication Provider
        ChangeNotifierProvider<GridCardProvider>(
          create: (context) => GridCardProvider(),
        ),

        // Global Security Settings Provider
        ChangeNotifierProvider<SecuritySettingsProvider>(
          create: (context) => SecuritySettingsProvider()..fetchSettings(),
        ),
      ],
      child: const AntigravityApp(),
    ),
  );
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static void navigateToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}

class AntigravityApp extends StatefulWidget {
  const AntigravityApp({super.key});

  @override
  State<AntigravityApp> createState() => _AntigravityAppState();
}

class _AntigravityAppState extends State<AntigravityApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    CustomFlowService.handleAppLifecycleChange(state);
    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  void _handleAppResume() async {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final securityManager = Provider.of<SecurityManager>(context, listen: false);
      if (storageService.isLoggedIn) {
        await securityManager.handleAppResume(context, 1);
      }
    }
    // Sync User App Data on resume
    await MobileValidationService.syncUserAppData();
  }

  @override
  Widget build(BuildContext context) {
    // Standardize scaling sizes based on premium phone screen sizes
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        
        return MaterialApp(
          title: 'Billing App',
          navigatorKey: NavigationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          
          // Theme configurations
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          
          // Initial Screen routing
          home: const SplashScreen(),
        );
      },
    );
  }
}
