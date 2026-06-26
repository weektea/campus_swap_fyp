import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider instance = ThemeProvider._internal();

  factory ThemeProvider() {
    return instance;
  }

  ThemeProvider._internal();

  ThemeMode _themeMode = ThemeMode.system;
  bool _isLargeText = false;

  ThemeMode get themeMode => _themeMode;
  bool get isLargeText => _isLargeText;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Accessing window/platformDispatcher directly might strictly need a context for accurate 'system' read
      // typically we just check if themeMode is dark. 
      // For switch status, we mainly care if user FORCED dark.
      return false; // Default assumption if system. 
    }
    return _themeMode == ThemeMode.dark;
  }

  // Helper to get current concrete brightness from context
  bool isDark(BuildContext context) {
       return Theme.of(context).brightness == Brightness.dark;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleLargeText(bool isLarge) {
    _isLargeText = isLarge;
    notifyListeners();
  }
}
