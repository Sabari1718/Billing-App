import 'dart:convert';
import 'package:billingapp/Auth/select.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/utils/app_logger.dart';

import 'api service.dart';

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

  void handleSubmit() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.loginUser({
        "email": email,
        "password": password
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

        await prefs.setString("auth_token", token);
        await prefs.remove("token");

        if (userData != null) {
          await prefs.setString("user", jsonEncode(userData));
        }

        AppLogger.success("User logged in successfully");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessSelectionPage(),
          ),
        );
      } else {
        showError("Token not received");
      }
    } catch (e) {
      AppLogger.error("Login failed", e);
      showError(e.toString());
    }

    setState(() => isLoading = false);
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