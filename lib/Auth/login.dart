import 'dart:convert';
import 'package:billingapp/Auth/select.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

import 'package:get/get.dart';
import 'api service.dart';
import 'billing dashboardc.dart';
import 'secret_image_verification_page.dart';

class LoginPage extends StatefulWidget {
  final Function onLogin;
  const LoginPage({required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '';
  String password = '';
  bool isLoading = false;

  void handleSubmit() {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      showError("Please enter both email and password");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecretImageVerificationPage(
          email: email.trim(),
          password: password.trim(),
          onVerified: (verificationContext, captchaImageId) async {
            final scaffoldMessenger = ScaffoldMessenger.of(verificationContext);
            final navigator = Navigator.of(verificationContext);

            try {
              final response = await ApiService.loginUser({
                "email": email.trim(),
                "password": password.trim(),
                "captcha_image_id": captchaImageId,
              });

              final token = response["token"] ??
                  response["data"]?["token"] ??
                  response["access_token"] ??
                  response["data"]?["access_token"];

              final userData = response["user"] ??
                  response["data"]?["user"] ??
                  (response["data"] != null && response["data"]["token"] == null
                      ? response["data"]
                      : null);

              if (token != null) {
                final prefs = await SharedPreferences.getInstance();

                // Clear previous session selections so user starts fresh
                await prefs.remove("selected_business_id");
                await prefs.remove("business_id");
                await prefs.remove("business_name");
                await prefs.remove("selected_platform_id");
                await prefs.remove("platform_id");
                await prefs.remove("selected_store_id");
                await prefs.remove("store_id");
                await prefs.remove("store_name");
                await prefs.remove("selected_store_name");

                final tokenStr = token.toString();
                await prefs.setString("auth_token", tokenStr);
                await prefs.setString("billing_auth_token", tokenStr);
                await prefs.setString("token", tokenStr);
                await prefs.setString("cached_email", email.trim());
                await prefs.setString("cached_password", password.trim());

                if (userData != null) {
                  await prefs.setString("user", jsonEncode(userData));
                  if (userData["id"] != null) await prefs.setString("user_id", userData["id"].toString());
                  if (userData["user_main_id"] != null) await prefs.setString("user_main_id", userData["user_main_id"].toString());
                  if (userData["name"] != null) await prefs.setString("user_name", userData["name"].toString());
                  if (userData["email"] != null) await prefs.setString("user_email", userData["email"].toString());
                  if (userData["phone"] != null) await prefs.setString("user_phone", userData["phone"].toString());
                  if (userData["role"] != null) await prefs.setString("user_role", userData["role"].toString());
                }

                if (Get.isRegistered<DashboardController>()) {
                  try {
                    Get.delete<DashboardController>(force: true);
                  } catch (_) {}
                }

                AppLogger.success("User logged in successfully");

                widget.onLogin();

                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => BusinessSelectionPage(),
                  ),
                  (route) => false,
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text("Token not received"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              AppLogger.error("Login failed", e);
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst("Exception: ", "")),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void showError(String msg) {
    String cleanMsg = msg.replaceFirst("Exception: ", "");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(cleanMsg),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Header area
                  Icon(Icons.account_balance_wallet, size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    "Welcome Back",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to access your dashboard",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Form Area
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          onChanged: (v) => email = v,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email Address",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          obscureText: true,
                          onChanged: (v) => password = v,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : handleSubmit,
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Sign In", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => Navigator.pushNamed(context, "/register"),
                        child: const Text("Create Account"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}