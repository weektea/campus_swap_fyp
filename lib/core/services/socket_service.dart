import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  socket_io.Socket? socket;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void init() {
    final session = UserSession();
    if (!session.isLoggedIn) {
      debugPrint('SocketService: Init skipped, user not logged in.');
      return;
    }

    // Disconnect existing socket first
    disconnect();

    final httpUrl = ApiClient.baseUrl;
    final socketUrl = httpUrl.replaceAll('/api', '');

    debugPrint('SocketService: Connecting to $socketUrl');
    socket = socket_io.io(socketUrl, socket_io.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({
        'token': session.token ?? '',
      })
      .setQuery({
        'userId': session.userId ?? '',
        'role': session.role ?? '',
      })
      .build()
    );

    socket?.connect();

    socket?.onConnect((_) {
      debugPrint('SocketService: Connected successfully');
      
      // Real-time Chat message instant system pop-up notification
      socket?.on('receive_new_message', (data) {
        if (data != null) {
          final currentUserId = session.userId;
          final senderId = data['sender_id']?.toString() ?? data['sender']?['id']?.toString() ?? '';
          final receiverId = data['receiver_id']?.toString();

          // 1. Do NOT pop up a toast notification for messages sent by the user themselves
          if (senderId.isNotEmpty && senderId == currentUserId) {
            return;
          }

          // 2. Privacy & Isolation check: If message targets a specific receiver, ignore if it doesn't match current user
          if (receiverId != null && receiverId.isNotEmpty && receiverId != currentUserId) {
            return;
          }

          final senderName = data['sender']?['full_name'] ?? data['sender']?['username'] ?? 'Chat Partner';
          final content = data['content']?.toString() ?? 'New message received';
          final avatar = data['sender']?['profile_image_url']?.toString() ?? '';
          NotificationService().showPopUpNotification(
            title: 'Message from $senderName',
            message: content,
            payload: 'CHAT|$senderId|$senderName|$avatar',
          );
        }
      });

      // Real-time System notification instant pop-up (0ms latency for order updates)
      socket?.on('new_notification', (data) {
        if (data != null) {
          final noteId = data['id']?.toString();
          NotificationService().showPopUpNotification(
            title: data['title'] ?? 'Campus Swap',
            message: data['message'] ?? '',
            payload: noteId,
            notificationId: noteId,
          );
        }
      });
    });

    socket?.onDisconnect((_) {
      debugPrint('SocketService: Disconnected');
    });

    socket?.onConnectError((err) {
      debugPrint('SocketService: Connection error: $err');
    });
  }

  void disconnect() {
    if (socket != null) {
      socket?.disconnect();
      socket?.dispose();
      socket = null;
      debugPrint('SocketService: Disconnected and socket disposed');
    }
  }
}
