import 'package:flutter/material.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'core/theme/theme_provider.dart';
import 'features/notification/presentation/pages/notifications_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init(onNotificationTap: (payload) {
      navigatorKey.currentState?.push(
         MaterialPageRoute(builder: (_) => const NotificationsPage())
      );
  });
  runApp(const CampusSwapApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class CampusSwapApp extends StatelessWidget {
  const CampusSwapApp({super.key});

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
            final scale = ThemeProvider.instance.isLargeText ? 1.25 : 1.0;
            return MediaQuery(
              data: mediaQueryData.copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            );
          },
          home: const LoginPage(),
        );
      },
    );
  }
}
