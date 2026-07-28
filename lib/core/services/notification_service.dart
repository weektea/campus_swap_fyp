import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/main.dart' show navigatorKey;
import 'package:campus_swap/features/notification/presentation/pages/notifications_page.dart';

@pragma('vm:entry-point')
void backgroundNotificationHandler(NotificationResponse response) {
  debugPrint('Background Notification Tapped: ${response.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _pollingTimer;
  final ApiClient _apiClient = ApiClient();
  final Set<String> _poppedNotificationIds = {};
  final Map<String, DateTime> _recentPopUps = {};
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);
  bool _isPoppedIdsLoaded = false;

  Future<void> _loadPoppedIds() async {
    if (_isPoppedIdsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('popped_notification_ids') ?? [];
      _poppedNotificationIds.addAll(savedList);
      _isPoppedIdsLoaded = true;
    } catch (e) {
      debugPrint('Error loading popped notification IDs: $e');
    }
  }

  Future<void> _recordPoppedId(String id) async {
    _poppedNotificationIds.add(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      final listToSave = _poppedNotificationIds.toList();
      if (listToSave.length > 500) {
        listToSave.removeRange(0, listToSave.length - 500);
      }
      await prefs.setStringList('popped_notification_ids', listToSave);
    } catch (e) {
      debugPrint('Error saving popped notification ID: $e');
    }
  }

  Future<void> init({Function(String?)? onNotificationTap}) async {
    await _loadPoppedIds();
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
      },
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationHandler,
    );

    // Create high priority notification channel and request Android 13+ notification permissions
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'campus_swap_channel',
          'Campus Swap Notifications',
          description: 'Main channel for app push notifications and system alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  /// Sends FCM device token to Node.js backend
  Future<void> syncFcmToken(String fcmToken) async {
    try {
      await _apiClient.post('/notifications/fcm-token', {
        'fcm_token': fcmToken,
      });
      debugPrint('FCM Token successfully synced with backend.');
    } catch (e) {
      debugPrint('Failed to sync FCM Token with backend: $e');
    }
  }

  void startPolling() {
    _pollingTimer?.cancel();
    checkForNotifications(); // Run immediately on start
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      checkForNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> checkForNotifications() async {
    try {
      await _loadPoppedIds();
      final response = await _apiClient.get('/notifications');
      
      if (response is List) {
        // Filter for unread and new notifications
        final unread = response.where((n) => n['is_read'] == false).toList();
        unreadCountNotifier.value = unread.length;
        
        for (var note in unread) {
          final id = note['id'].toString();
          if (!_poppedNotificationIds.contains(id)) {
            _recordPoppedId(id);
            showPopUpNotification(
              title: note['title'] ?? 'Campus Swap',
              message: note['message'] ?? '',
              payload: id,
              notificationId: id,
            );
          }
        }
      }
    } catch (e) {
      // Silent error for polling
    }
  }

  Future<void> showPopUpNotification({
    required String title,
    required String message,
    String? payload,
    String? notificationId,
  }) async {
    await _loadPoppedIds();
    if (notificationId != null && notificationId.isNotEmpty) {
      if (_poppedNotificationIds.contains(notificationId)) {
        return; // Suppress duplicate pop-up if already processed
      }
      _recordPoppedId(notificationId);
    }

    // Rate-limiting / Debounce by title+message to prevent rapid duplicate toasts
    final key = '$title|$message';
    final now = DateTime.now();
    if (_recentPopUps.containsKey(key)) {
      if (now.difference(_recentPopUps[key]!).inSeconds < 3) {
        return; // Suppress duplicate toast within 3 seconds
      }
    }
    _recentPopUps[key] = now;

    if (kIsWeb) {
      // Display in-app SnackBar notification alert for web browsers
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title: $message'),
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
            'campus_swap_channel', 
            'Campus Swap Notifications',
            channelDescription: 'Main channel for app push notifications and system alerts',
            importance: Importance.max,
            priority: Priority.max,
            visibility: NotificationVisibility.public,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher');
            
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
