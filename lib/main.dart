import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const FlameApp());
}
class FlameApp extends StatelessWidget 
{
  const FlameApp({super.key});

  @override
  Widget build(BuildContext context) 
  {
    return MaterialApp(
      title: 'Flame App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}
