import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:billingapp/Auth/api service.dart';
import 'package:billingapp/main.dart'; // To access themeNotifier
import 'package:billingapp/settings/pin_auth_gate.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:billingapp/mainscreen/theme/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String appName = "Loading...";
  String appVersion = "Loading...";
  String buildNumber = "Loading...";
  String softwareVersion = "Loading...";

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndSendAppInfo();
  }

  Future<void> _loadAndSendAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      String osVersion = "1.3.1";
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        osVersion = "Android ${androidInfo.version.release}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        osVersion = "iOS ${iosInfo.systemVersion}";
      }

      setState(() {
        appName = packageInfo.appName;
        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
        softwareVersion = osVersion;
        _isLoading = false;
      });

      // Send to Backend
      await ApiService.sendDeviceInfo({
        "app_name": appName,
        "app_version": appVersion,
        "build_number": buildNumber,
        "software_version": softwareVersion,
      });
    } catch (e) {
      debugPrint("Error loading app info: $e");
      setState(() {
        softwareVersion = "1.3.1";
        _isLoading = false;
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showLanguageSelectionBottomSheet() {
    final List<Map<String, String>> languages = [
      {"name": "English", "sub": "English (US)", "code": "en", "country": "US"},
      {"name": "தமிழ்", "sub": "Tamil", "code": "ta", "country": "IN"},
      {"name": "മലയാളം", "sub": "Malayalam", "code": "ml", "country": "IN"},
      {"name": "हिन्दी", "sub": "Hindi", "code": "hi", "country": "IN"},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentLocale = Get.locale ?? const Locale('en', 'US');

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "select_lang_title".tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final isSelected = currentLocale.languageCode == lang["code"];
                return ListTile(
                  leading: const Icon(Icons.language_rounded, color: Color(0xFF2563EB)),
                  title: Text(lang["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(lang["sub"]!),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF2563EB))
                      : null,
                  onTap: () async {
                    final locale = Locale(lang["code"]!, lang["country"]!);
                    Get.updateLocale(locale);
                    
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString("selected_language_code", lang["code"]!);
                    await prefs.setString("selected_country_code", lang["country"]!);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text("settings".tr),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader("themes".tr.toUpperCase()),
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: SwitchListTile(
                    title: Text("dark_mode".tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("toggle_theme".tr),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: isDark ? Colors.indigo : Colors.orange,
                    ),
                    value: isDark,
                    onChanged: (val) {
                      setState(() {
                        themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      });
                      try {
                        final themeProv = provider_pkg.Provider.of<ThemeProvider>(context, listen: false);
                        themeProv.setDarkMode(val);
                      } catch (e) {
                        debugPrint("Error setting dark mode: $e");
                      }
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                _buildSectionHeader("about".tr.toUpperCase()),
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.blue),
                        title: Text("app_name_label".tr, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Text(appName, style: const TextStyle(color: Colors.grey)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.verified_outlined, color: Colors.green),
                        title: Text("app_version_label".tr, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Text(appVersion, style: const TextStyle(color: Colors.grey)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.build_circle_outlined, color: Colors.orange),
                        title: Text("build_number_label".tr, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Text(buildNumber, style: const TextStyle(color: Colors.grey)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.system_security_update_good_outlined, color: Colors.purple),
                        title: Text("software_version_label".tr, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Text(softwareVersion, style: const TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                _buildSectionHeader("extra_settings".tr.toUpperCase()),
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined, color: Colors.redAccent),
                        title: Text("notifications".tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text("manage_notification".tr),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Placeholder
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("coming_soon".tr)),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language_outlined, color: Colors.teal),
                        title: Text("language".tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text("select_language".tr),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showLanguageSelectionBottomSheet();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.build_circle_outlined, color: Colors.blueAccent),
                        title: Text("manage".tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text("manage_app_settings".tr),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PinAuthGatePage()));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
