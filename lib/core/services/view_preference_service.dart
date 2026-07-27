import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewPreferenceService extends ValueNotifier<bool> {
  static final ViewPreferenceService _instance = ViewPreferenceService._internal();
  factory ViewPreferenceService() => _instance;

  static const String _prefKey = 'is_grid_view_preference';

  ViewPreferenceService._internal() : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = prefs.getBool(_prefKey) ?? true; // Default to true (Grid View)
    } catch (e) {
      debugPrint('Error loading view preference: $e');
    }
  }

  Future<void> toggleViewMode() async {
    await setViewMode(!value);
  }

  Future<void> setViewMode(bool isGrid) async {
    if (value == isGrid) return;
    value = isGrid;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, isGrid);
    } catch (e) {
      debugPrint('Error saving view preference: $e');
    }
  }

  bool get isGridView => value;
}
