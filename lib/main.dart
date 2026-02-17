import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings service first
  await SettingsService.instance.initialize();

  // Initialize API service
  await ApiService.instance.initialize();

  // Initialize notification service
  await NotificationService.instance.initialize();

  runApp(const FlameApp());
}
class FlameApp extends StatelessWidget 
{
  const FlameApp({super.key});

  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
      title: 'F.L.A.M.E',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
