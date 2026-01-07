import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:campus_swap/core/session/user_session.dart';

class ApiClient {
  // Determine Base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api'; // Browsers access localhost directly
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api'; // Android Emulator
    } else {
      return 'http://localhost:3000/api'; // iOS Simulator & others
    }
  } 

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> postMultipart(String endpoint, XFile file) async {
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final token = UserSession().token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
