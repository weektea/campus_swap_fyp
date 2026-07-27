import 'package:flutter/material.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'core/theme/theme_provider.dart';
import 'features/notification/presentation/pages/notifications_page.dart';
import 'core/services/socket_service.dart';
import 'core/session/user_session.dart';

import 'features/chat/presentation/pages/chat_detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persistent theme preference (Dark/Light mode) and accessibility settings
  await ThemeProvider.instance.initFromStorage();

  // Load persistent user session from local storage for Auto-Login
  final isLoggedIn = await UserSession().initFromStorage();

  // Initialize notification service with deep linking
  await NotificationService().init(onNotificationTap: (payload) {
      handleNotificationTap(payload);
  });

  if (isLoggedIn) {
    SocketService().init();
    NotificationService().startPolling();
  }

  runApp(const CampusSwapApp());
}

void handleNotificationTap(String? payload) {
  if (payload == null || payload.isEmpty) {
    navigatorKey.currentState?.push(
       MaterialPageRoute(builder: (_) => const NotificationsPage())
    );
    return;
  }

  // Deep Link: Chat Message Notification
  if (payload.startsWith('CHAT|')) {
    final parts = payload.split('|');
    final otherUserId = parts.length > 1 ? parts[1] : '';
    final senderName = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : 'Chat Partner';
    final avatar = parts.length > 3 ? parts[3] : '';

    if (otherUserId.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            otherUserId: otherUserId,
            sellerName: senderName,
            otherUserAvatar: avatar.isNotEmpty ? avatar : null,
          ),
        ),
      );
      return;
    }
  } else if (payload.startsWith('chat_')) {
    final otherUserId = payload.replaceAll('chat_', '');
    if (otherUserId.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            otherUserId: otherUserId,
            sellerName: 'Chat Partner',
          ),
        ),
      );
      return;
    }
  }

  // Fallback: Default Notifications Page
  navigatorKey.currentState?.push(
     MaterialPageRoute(builder: (_) => const NotificationsPage())
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class CampusSwapApp extends StatelessWidget {
  const CampusSwapApp({super.key});

  Widget _getInitialScreen() {
    final session = UserSession();
    if (!session.isLoggedIn) {
      return const LoginPage();
    }
    if (!session.isOnboarded) {
      return const OnboardingPage();
    }
    return const HomePage();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Campus Swap',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeProvider.instance.themeMode,
          builder: (context, child) {
            final mediaQueryData = MediaQuery.of(context);
            // If Large Text is enabled, use 1.20x scale. Otherwise, use normal 1.0x scale.
            final double textScale = ThemeProvider.instance.isLargeText
                ? 1.20
                : mediaQueryData.textScaler.scale(1.0).clamp(0.85, 1.0);

            return MediaQuery(
              data: mediaQueryData.copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            );
          },
          home: _getInitialScreen(),
        );
      },
    );
  }
}
