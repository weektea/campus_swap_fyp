import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/core/services/socket_service.dart';
import 'package:campus_swap/core/services/notification_service.dart';
import 'package:campus_swap/main.dart' show navigatorKey;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:campus_swap/features/auth/presentation/pages/login_page.dart';

class ApiClient {
  static const String _envHost = String.fromEnvironment('API_HOST', defaultValue: '');

  static String get baseUrl {
    // 1. If explicit API_HOST is passed via --dart-define, use it for all platforms (Mobile & Web)
    if (_envHost.isNotEmpty) {
      return 'http://$_envHost:3000/api';
    }

    // 2. Default platform fallbacks
    if (kIsWeb) {
      return 'http://localhost:3000/api'; // Browsers access localhost directly
    } 

    if (Platform.isAndroid) {
      return 'http://127.0.0.1:3000/api'; // Android (Physical or Emulator via adb reverse)
    } else {
      return 'http://localhost:3000/api'; // iOS Simulator or others
    }
  } 

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Connection timed out. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Connection error: ${e.toString()}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Connection timed out. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Connection error: ${e.toString()}');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Connection timed out. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Connection error: ${e.toString()}');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Connection timed out. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Connection error: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Connection timed out. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Connection error: ${e.toString()}');
    }
  }

  Future<dynamic> postMultipart(String endpoint, XFile file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      
      if (kIsWeb) {
        // Web: Use bytes
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: file.name
        ));
      } else {
        // Mobile/Desktop: Use path (if available, otherwise fallback to bytes)
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }
      
      // Add Authorization header
      final token = UserSession().token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Upload timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Upload connection error: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'API Error: ${response.statusCode}';
      Map<String, dynamic>? errorData;
      try {
        final errorBody = jsonDecode(response.body);
        errorData = errorBody;
        if (errorBody['error'] != null) {
          errorMessage = errorBody['error'];
        }
      } catch (_) {}

      // Intercept active session suspension / revocation
      if (response.statusCode == 403 && (errorMessage.toLowerCase().contains('suspended') || errorMessage.toLowerCase().contains('revoked'))) {
        _handleSessionSuspended(errorMessage);
      }

      throw ApiException(errorMessage, responseData: errorData);
    }
  }

  void _handleSessionSuspended(String message) async {
    // Prevent multiple concurrent redirects
    if (!UserSession().isLoggedIn) return;

    // Disconnect socket & stop polling
    SocketService().disconnect();
    NotificationService().stopPolling();
    UserSession().clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_login', false);
    } catch (_) {}

    // Show a dialog on the current UI navigator context and redirect to login screen
    final context = navigatorKey.currentContext;
    if (context != null) {
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.gavel, color: Colors.red),
                SizedBox(width: 8),
                Text('Account Suspended'),
              ],
            ),
            content: const Text('Your account has been suspended due to policy violations. You have been logged out.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text('OK', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      });
    } else {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final token = UserSession().token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final sessionInteractions = UserSession().sessionInteractions;
    if (sessionInteractions.isNotEmpty) {
      headers['X-Session-Interactions'] = sessionInteractions.join(',');
    }
    return headers;
  }
}

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? responseData;
  ApiException(this.message, {this.responseData});

  @override
  String toString() => message;
}
