import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _login() {
    if (_userController.text.isNotEmpty && _passController.text.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter UserID and Password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            Container(color: const Color.fromARGB(255, 207, 222, 244)),
            Positioned(
              top: 40,
              right: 20,
              child: Image.asset('assets/image.png', height: 80),
            ),
            Center(
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Login",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 75, 192, 21))),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: "User ID"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 118, 169, 220),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12)),
                    child: const Text("Login"),
                  ),
                ],
              ),
            ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
