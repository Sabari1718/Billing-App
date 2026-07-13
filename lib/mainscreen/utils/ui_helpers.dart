import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UiHelpers {
  UiHelpers._();

  /// Displays a modern, emerald-green success floating snackbar with a check icon
  static void showSuccessMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    // Clear any active/queued snackbars immediately to prevent duplicates
    scaffoldMessenger.removeCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981), // Emerald Green
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
      ),
    );
  }

  /// Displays a modern, crimson-red error floating snackbar with an error icon
  static void showErrorMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    // Clear any active/queued snackbars immediately to prevent duplicates
    scaffoldMessenger.removeCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444), // Crimson Red
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
      ),
    );
  }
}
