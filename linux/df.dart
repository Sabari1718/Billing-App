import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // ✅ Use local PHP endpoints for email OTP
  final String sendOtpUrl = "http://localhost/smt_mail/send_otp.php";
  final String verifyOtpUrl = "http://localhost/smt_mail/verify_otp.php";

  final emailController = TextEditingController();
  final otpController = TextEditingController();

  String step = "input"; // input / otp
  int resendTimer = 0;
  Timer? timer;
  bool canResend = true;

  String error = "";
  String success = "";
  bool isLoading = false;
  int emailOtpVerified = 0;

  bool isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  void clearMessages() {
    setState(() {
      error = "";
      success = "";
    });
  }

  void startTimer() {
    resendTimer = 30;
    canResend = false;

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (resendTimer <= 1) {
        t.cancel();
        setState(() {
          resendTimer = 0;
          canResend = true;
        });
      } else {
        setState(() {
          resendTimer--;
        });
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> sendEmailOtp() async {
    final email = emailController.text.trim();

    clearMessages();

    if (!isValidEmail(email)) {
      setState(() {
        error = "Enter a valid email address";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print("📧 EMAIL SEND OTP URL: $sendOtpUrl");

      final response = await http.post(
        Uri.parse(sendOtpUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      print("📧 EMAIL SEND OTP STATUS: ${response.statusCode}");
      print("📧 EMAIL SEND OTP BODY: ${response.body}");

      if (response.body.trim().isEmpty) {
        if (mounted) {
          setState(() {
            error = "Empty response from send_otp.php";
            isLoading = false;
          });
        }
        return;
      }

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        if (mounted) {
          setState(() {
            error = "Invalid JSON from send_otp.php";
            isLoading = false;
          });
        }
        return;
      }

      final bool ok = response.statusCode == 200 && data["success"] == true;

      if (mounted) {
        if (ok) {
          setState(() {
            step = "otp";
            success = data["message"]?.toString() ?? "OTP sent successfully";
            error = "";
          });
          startTimer();
        } else {
          setState(() {
            error = data["message"]?.toString() ??
                data["error"]?.toString() ??
                "Failed to send OTP";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Send OTP failed: $e";
        });
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> verifyEmailOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    clearMessages();

    if (!isValidEmail(email)) {
      setState(() {
        error = "Enter a valid email address";
      });
      return;
    }

    if (otp.isEmpty) {
      setState(() {
        error = "Enter OTP";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print("📧 EMAIL VERIFY OTP URL: $verifyOtpUrl");

      final response = await http.post(
        Uri.parse(verifyOtpUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "otp": otp,
        }),
      );

      print("📧 EMAIL VERIFY OTP STATUS: ${response.statusCode}");
      print("📧 EMAIL VERIFY OTP BODY: ${response.body}");

      if (response.body.trim().isEmpty) {
        if (mounted) {
          setState(() {
            error = "Empty response from verify_otp.php";
            isLoading = false;
          });
        }
        return;
      }

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        if (mounted) {
          setState(() {
            error = "Invalid JSON from verify_otp.php";
            isLoading = false;
          });
        }
        return;
      }

      final bool ok = response.statusCode == 200 && data["success"] == true;

      if (mounted) {
        if (ok) {
          setState(() {
            emailOtpVerified = 1;
            success = data["message"]?.toString() ?? "OTP verified successfully";
            error = "";
            otpController.clear();
          });
        } else {
          setState(() {
            error = data["message"]?.toString() ??
                data["error"]?.toString() ??
                "Invalid OTP";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Verify OTP failed: $e";
        });
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email OTP Login"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading && emailOtpVerified == 0,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  hintText: "Enter your email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              if (step == "otp")
                Column(
                  children: [
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      enabled: !isLoading && emailOtpVerified == 0,
                      decoration: const InputDecoration(
                        labelText: "Enter OTP",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : (step == "input"
                    ? sendEmailOtp
                    : (canResend ? sendEmailOtp : null)),
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  step == "input"
                      ? "Send OTP"
                      : (canResend ? "Resend OTP" : "Wait..."),
                ),
              ),

              const SizedBox(height: 12),

              if (step == "otp" && emailOtpVerified == 0)
                ElevatedButton(
                  onPressed: isLoading ? null : verifyEmailOtp,
                  child: const Text("Verify OTP"),
                ),

              const SizedBox(height: 16),

              if (step == "otp" && !canResend)
                Text(
                  "Resend available in $resendTimer sec",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

              if (error.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              if (success.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    success,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text("STEP: $step"),
                      const SizedBox(height: 6),
                      Text("Email Verified: $emailOtpVerified"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
