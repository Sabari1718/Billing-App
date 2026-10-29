import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/services/captcha_service.dart';
import 'package:billingapp/mainscreen/services/auth_service.dart';
import 'package:billingapp/mainscreen/services/storage_service.dart';
import 'package:billingapp/Auth/api service.dart' as billing_api;
import 'package:billingapp/Auth/select.dart';

class SecretImageVerificationPage extends StatefulWidget {
  final String email;
  final String password;
  final Future<void> Function(BuildContext context, int captchaImageId)? onVerified;

  const SecretImageVerificationPage({
    super.key,
    required this.email,
    required this.password,
    this.onVerified,
  });

  @override
  State<SecretImageVerificationPage> createState() =>
      _SecretImageVerificationPageState();
}

class _SecretImageVerificationPageState
    extends State<SecretImageVerificationPage> {
  CaptchaCategory? _selectedCategory;
  bool _isVerifying = false;
  bool _isLoadingCategories = true;
  String? _errorMessage;
  List<CaptchaCategory> _categories = [];
  final CaptchaService _captchaService = CaptchaService();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = null;
    });

    try {
      final categories = await _captchaService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load images from API: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildImageWidget(String imagePath, bool isSelected) {
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 28),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your secret image to proceed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      if (widget.onVerified != null) {
        // Custom verification callback provided by caller
        await widget.onVerified!(context, _selectedCategory!.id);
        return;
      }

      // Default standalone verification flow
      final authService = Provider.of<AuthService>(context, listen: false);
      final bool success = await authService.login(
        widget.email,
        widget.password,
        captchaImageId: _selectedCategory!.id,
      );

      if (!mounted) return;

      if (success) {
        // Silent billing login
        try {
          final billingResponse = await billing_api.ApiService.loginUser({
            "email": widget.email,
            "password": widget.password,
            "captcha_image_id": _selectedCategory!.id,
          });
          final billingToken = billingResponse["token"] ?? billingResponse["data"]?["token"];
          if (billingToken != null) {
            final prefs = await SharedPreferences.getInstance();
            final tokenStr = billingToken.toString();
            await prefs.setString("auth_token", tokenStr);
            await prefs.setString("billing_auth_token", tokenStr);
            await prefs.setString("token", tokenStr);
            await prefs.setString("cached_email", widget.email);
            await prefs.setString("cached_password", widget.password);
          }
        } catch (e) {
          debugPrint("Silent billing login error: $e");
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Captcha Verified Successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to Home / Business Selection Screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => BusinessSelectionPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid secret image selected. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } on InvalidCredentialsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Verify Identity",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isLoadingCategories ? null : _fetchCategories,
            tooltip: "Reload Images from API",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Text(
                "Please select your secret image to proceed.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isLoadingCategories
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                "Loading images from API...",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                      : _errorMessage != null && _categories.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.cloud_off,
                                      size: 48,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _fetchCategories,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Retry API"),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _categories.isEmpty
                              ? const Center(child: Text("No images available from API"))
                              : GridView.builder(
                                  padding: EdgeInsets.zero,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                  ),
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    final isSelected =
                                        _selectedCategory?.id == category.id;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = category;
                                        });
                                      },
                                      child: Container(
                                        color: Colors.white,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            AnimatedContainer(
                                              duration:
                                                  const Duration(milliseconds: 200),
                                              padding: EdgeInsets.all(
                                                  isSelected ? 10.0 : 0.0),
                                              child: _buildImageWidget(
                                                category.image,
                                                isSelected,
                                              ),
                                            ),
                                            if (isSelected)
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF6366F1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: const EdgeInsets.all(4),
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isVerifying || _selectedCategory == null ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Verify & Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
