import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations and system UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services in parallel for faster startup
  await Future.wait([
    SettingsService.instance.initialize(),
    ApiService.instance.initialize(),
    NotificationService.instance.initialize(),
  ]);

  runApp(const FlameApp());
}

class FlameApp extends StatelessWidget {
  const FlameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F.L.A.M.E',
      debugShowCheckedModeBanner: false,

      // Material 3 theme with smooth animations
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),

        // Smooth page transitions for all platforms
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),

        // Optimized for 120Hz displays
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Smooth animations
        splashFactory: InkRipple.splashFactory,
      ),

      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
