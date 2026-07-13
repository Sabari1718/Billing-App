import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:billingapp/mainscreen/utils/api_debug_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:billingapp/mainscreen/services/storage_service.dart';
import 'package:billingapp/mainscreen/theme/theme_provider.dart';
import 'package:billingapp/mainscreen/theme/app_theme.dart';
import 'package:billingapp/mainscreen/utils/constants.dart';
import 'package:billingapp/mainscreen/screens/login_screen.dart';
import 'package:billingapp/mainscreen/screens/settings_screen.dart';
import 'package:billingapp/mainscreen/screens/security_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late StorageService _storageService;
  
  // Field values dynamically fetched or cached
  String _userName = 'Loading...';
  String _phoneNumber = 'Loading...';
  String _email = 'Loading...';
  String _userMainId = 'Loading...';
  String _address = 'Loading...';
  String _userType = 'Loading...';
  
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _storageService = Provider.of<StorageService>(context, listen: false);
    _fetchUserProfile();
  }

  /// Instantly renders offline cached values and performs a single background sync from backend
  Future<void> _fetchUserProfile() async {


    final prefs = await SharedPreferences.getInstance();

    // 1. Instantly load cache values from local storage (0s latency screen load)
    setState(() {
      _userName = _storageService.userName.isEmpty ? 'Sentinel Officer' : _storageService.userName;
      _email = _storageService.userEmail.isEmpty ? 'sentinel@antigravity.com' : _storageService.userEmail;
      _phoneNumber = _storageService.userPhone.isEmpty ? '+1 (555) 019-2831' : _storageService.userPhone;
      _userType = _storageService.userRole.isEmpty ? 'Administrator' : _storageService.userRole;
      _userMainId = prefs.getString('sec_cache_user_main_id') ?? '4883898579';
      _address = prefs.getString('sec_cache_address') ?? 'Antigravity Core Subsector 4';
      _localAvatarPath = prefs.getString('persistent_profile_photo_path');
    });

    // 2. Query dynamic user data from server silently in background
    try {
      final token = prefs.getString('auth_token');
      final cookies = prefs.getString('stored_cookies');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (cookies != null && cookies.isNotEmpty) 'Cookie': cookies,
      };

      final response = await ApiDebugLogger.httpClient.get(
        Uri.parse("https://user.jobes24x7.com/api/login/4883898579"),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final dynamic rawData = json['data'];
        
        Map<String, dynamic> userDetails = {};
        if (rawData is Map) {
          if (rawData.containsKey('data') && rawData['data'] is Map) {
            userDetails = Map<String, dynamic>.from(rawData['data']);
          } else {
            userDetails = Map<String, dynamic>.from(rawData);
          }
        } else if (json['user'] is Map) {
          userDetails = Map<String, dynamic>.from(json['user']);
        }

        if (userDetails.isNotEmpty) {
          setState(() {
            _userName = userDetails['user_name']?.toString() ?? userDetails['name']?.toString() ?? _userName;
            _phoneNumber = userDetails['phone_number']?.toString() ?? userDetails['phone']?.toString() ?? _phoneNumber;
            _email = userDetails['email']?.toString() ?? _email;
            _userMainId = userDetails['user_main_id']?.toString() ?? userDetails['id']?.toString() ?? _userMainId;
            _address = userDetails['address']?.toString() ?? _address;
            _userType = userDetails['user_type']?.toString() ?? userDetails['role']?.toString() ?? _userType;
          });

          // Save fetched details persistently to local storage
          await _storageService.setUserName(_userName);
          await _storageService.setUserEmail(_email);
          await _storageService.setUserPhone(_phoneNumber);
          await _storageService.setUserRole(_userType);
          await prefs.setString('sec_cache_user_main_id', _userMainId);
          await prefs.setString('sec_cache_address', _address);
        }
      }
    } catch (e) {
      debugPrint("Profile background fetch failed (offline fallback active): $e");
    } finally {

    }
  }

  /// Triggers standard image picker, clones the file permanently into the local sandbox, and persists path key
  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String ext = image.path.split('.').last;
        final String fileName = 'persistent_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final String savedPath = '${directory.path}/$fileName';
        
        final File localFile = await File(image.path).copy(savedPath);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('persistent_profile_photo_path', localFile.path);
        
        setState(() {
          _localAvatarPath = localFile.path;
        });
        
        await _storageService.setUserPhoto(localFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile photo updated permanently!'),
              backgroundColor: AppConstants.accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking profile avatar: $e");
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await _storageService.clearAuthSession();
    await ApiDebugLogger.logSessionInfo(
      eventName: 'LOGOUT_EVENT',
      sessionStatus: 'INVALID',
    );

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20.w,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20.h),
                
                // Title Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personnel Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Authorized System clearance parameters',
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: Theme.of(context).colorScheme.primary),
                      onPressed: _fetchUserProfile,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Premium Photo Profile & User Main Identification Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.r),
                    child: Column(
                      children: [
                        // Persistent Profile Photo Update option
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 94.r,
                                height: 94.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: ClipOval(
                                  child: _localAvatarPath != null && File(_localAvatarPath!).existsSync()
                                      ? Image.file(
                                          File(_localAvatarPath!),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          AppConstants.avatarOptions[0],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(5.r),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14.r,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                        
                        Text(
                          _userName,
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        
                        // Clearance Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppConstants.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppConstants.accentColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _userType.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppConstants.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // Spacing and Detail Tiles
                Text(
                  'VAULT CREDENTIAL METADATA',
                  style: GoogleFonts.outfit(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8.h),

                _buildDetailTile(Icons.fingerprint_rounded, 'Clearance Main ID', _userMainId),
                _buildDetailTile(Icons.person_outline_rounded, 'Account Full Name', _userName),
                _buildDetailTile(Icons.alternate_email_rounded, 'Authorized Email Address', _email),
                _buildDetailTile(Icons.phone_iphone_rounded, 'Secured Contact Mobile', _phoneNumber),
                _buildDetailTile(Icons.location_on_outlined, 'Secure Operations Address', _address),
                _buildDetailTile(Icons.security_rounded, 'Clearance Personnel Type', _userType),

                SizedBox(height: 18.h),

                // Settings Console Actions
                Text(
                  'SYSTEM CONSOLE CONFIG',
                  style: GoogleFonts.outfit(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8.h),

                // Password & Security Link Card
                Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SecurityScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.all(14.r),
                      child: Row(
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.indigoAccent, size: 22.w),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Password & Security', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                Text('Manage hardware PIN, Pattern, or Biometrics', style: GoogleFonts.outfit(fontSize: 10.sp, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14.w, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                // System Settings Link Card
                Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.all(14.r),
                      child: Row(
                        children: [
                          Icon(Icons.settings_suggest_rounded, color: Colors.amber, size: 22.w),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('System Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                Text('Adjust session timeouts and device scan logs', style: GoogleFonts.outfit(fontSize: 10.sp, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14.w, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                // Theme Mode Inline Toggle Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Row(
                      children: [
                        Icon(Icons.style_rounded, color: Colors.teal, size: 22.w),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Themes Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                              Text('Toggle light and dark dynamic UI looks', style: GoogleFonts.outfit(fontSize: 10.sp, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Switch(
                          value: Theme.of(context).brightness == Brightness.dark,
                          onChanged: (val) {
                            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                            themeProvider.toggleTheme();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Red Outlined Logout Card
                Card(
                  color: Colors.redAccent.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.redAccent, width: 0.8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: Text(
                      "Terminate Clearance Session",
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    onTap: () {
                      logout(context);
                    },
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
