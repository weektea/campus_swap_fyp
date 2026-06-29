import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? socket;

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
    socket = IO.io(socketUrl, IO.OptionBuilder()
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
