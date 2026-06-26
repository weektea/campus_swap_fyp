import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/main.dart' show navigatorKey;
import 'package:campus_swap/features/notification/presentation/pages/notifications_page.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _pollingTimer;
  final ApiClient _apiClient = ApiClient();
  final List<String> _knownNotificationIds = [];
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);

  Future<void> init({Function(String?)? onNotificationTap}) async {
    if (kIsWeb) return; // No-op on Web to avoid crashes
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
          onNotificationTap?.call(details.payload);
      }
    );
  }

  void startPolling() {
    _pollingTimer?.cancel();
    checkForNotifications(); // Run immediately on start
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      checkForNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> checkForNotifications() async {
    try {
      final response = await _apiClient.get('/notifications');
      
      if (response is List) {
        // Filter for unread and new notifications
        final unread = response.where((n) => n['is_read'] == false).toList();
        unreadCountNotifier.value = unread.length;
        
        for (var note in unread) {
          final id = note['id'].toString();
          if (!_knownNotificationIds.contains(id)) {
            _knownNotificationIds.add(id);
            _showNotification(note);
          }
        }
      }
    } catch (e) {
      // Silent error for polling
    }
  }

  Future<void> _showNotification(Map<String, dynamic> note) async {
    if (kIsWeb) {
      // Display in-app SnackBar notification alert for web browsers
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${note['title'] ?? 'Notification'}: ${note['message'] ?? ''}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'campus_swap_channel', 'Campus Swap Notifications',
            channelDescription: 'Main channel for app notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true);
            
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      note.hashCode, // Simple ID generation
      note['title'] ?? 'New Notification',
      note['message'] ?? '',
      platformChannelSpecifics,
      payload: note['id'].toString(),
    );
  }
}
