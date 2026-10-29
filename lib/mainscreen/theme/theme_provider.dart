import 'package:flutter/material.dart';
import 'package:billingapp/mainscreen/services/storage_service.dart';
import 'package:get/get.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  late bool _isDarkMode;

  ThemeProvider(this._storageService) {
    _isDarkMode = _storageService.isDarkMode;
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.setDarkMode(_isDarkMode);
    try {
      Get.changeThemeMode(themeMode);
    } catch (_) {}
    notifyListeners();
  }

  void setDarkMode(bool dark) async {
    if (_isDarkMode == dark) return;
    _isDarkMode = dark;
    await _storageService.setDarkMode(_isDarkMode);
    try {
      Get.changeThemeMode(themeMode);
    } catch (_) {}
    notifyListeners();
  }
}
