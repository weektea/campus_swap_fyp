import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      return false; // Default assumption if system uninitialized
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Helper to check if context is currently dark
  bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Load theme and text accessibility preferences from SharedPreferences on app startup
  Future<void> initFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode');
      if (savedTheme != null) {
        if (savedTheme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (savedTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      }
      _isLargeText = prefs.getBool('is_large_text') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  /// Toggle and persist theme mode (Dark / Light)
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', isDark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Toggle and persist large text accessibility option
  Future<void> toggleLargeText(bool isLarge) async {
    _isLargeText = isLarge;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_large_text', isLarge);
    } catch (e) {
      debugPrint('Error saving large text preference: $e');
    }
  }
}
