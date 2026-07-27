import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  
  factory UserSession() {
    return _instance;
  }
  
  UserSession._internal();

  String? userId;
  String? email;
  String? username;
  String? fullName;
  String? token;
  String? avatarUrl;
  String? role;
  bool isOnboarded = false;
  String primaryIntent = 'browse';
  List<String> preferenceTags = [];

  final List<String> sessionInteractions = [];

  bool get isLoggedIn => userId != null && token != null && token!.isNotEmpty;

  void addSessionInteraction(String productId) {
    if (!sessionInteractions.contains(productId)) {
      sessionInteractions.add(productId);
    }
  }

  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) await prefs.setString('jwt_token', token!);
      if (userId != null) await prefs.setString('user_id', userId!);
      if (email != null) await prefs.setString('user_email', email!);
      if (username != null) await prefs.setString('user_name', username!);
      if (fullName != null) await prefs.setString('user_fullname', fullName!);
      if (avatarUrl != null) await prefs.setString('user_avatar', avatarUrl!);
      if (role != null) await prefs.setString('user_role', role!);
      await prefs.setBool('user_is_onboarded', isOnboarded);
      await prefs.setString('user_primary_intent', primaryIntent);
      await prefs.setStringList('user_preference_tags', preferenceTags);
      await prefs.setBool('auto_login', true);
    } catch (e) {
      debugPrint('Error saving session to storage: $e');
    }
  }

  Future<bool> initFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt_token');
      final savedUserId = prefs.getString('user_id');
      final autoLogin = prefs.getBool('auto_login') ?? true;

      if (autoLogin && savedToken != null && savedToken.isNotEmpty && savedUserId != null && savedUserId.isNotEmpty) {
        token = savedToken;
        userId = savedUserId;
        email = prefs.getString('user_email');
        username = prefs.getString('user_name');
        fullName = prefs.getString('user_fullname');
        avatarUrl = prefs.getString('user_avatar');
        role = prefs.getString('user_role');
        isOnboarded = prefs.getBool('user_is_onboarded') ?? false;
        primaryIntent = prefs.getString('user_primary_intent') ?? 'browse';
        preferenceTags = prefs.getStringList('user_preference_tags') ?? [];
        return true;
      }
    } catch (e) {
      debugPrint('Error initializing session from storage: $e');
    }
    return false;
  }

  Future<void> clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_fullname');
      await prefs.remove('user_avatar');
      await prefs.remove('user_role');
      await prefs.remove('user_is_onboarded');
      await prefs.remove('user_primary_intent');
      await prefs.remove('user_preference_tags');
      await prefs.setBool('auto_login', false);
    } catch (e) {
      debugPrint('Error clearing session storage: $e');
    }
    clear();
  }

  void clear() {
    userId = null;
    email = null;
    username = null;
    fullName = null;
    token = null;
    avatarUrl = null;
    role = null;
    isOnboarded = false;
    primaryIntent = 'browse';
    preferenceTags.clear();
    sessionInteractions.clear();
  }
}
