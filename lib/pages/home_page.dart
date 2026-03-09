import 'package:flutter/material.dart';
import 'gun_status_page.dart';
import 'performance_trends_page.dart';
import 'day_min_max_page.dart';
import 'emergency_alerts_page.dart';
import 'gun_inching_page.dart';
import 'settings_page.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Use ValueNotifier for minimal rebuilds
  final ValueNotifier<int> _selectedIndexNotifier = ValueNotifier(-1);
  late AnimationController _animationController;
  // ignore: unused_field
  late Animation<double> _fadeAnimation;

  static const List<String> _menuTitles = [
    'Gun Overview',
    'Performance Trends',
    'Daily Min/Max',
    'Gun Inching',
    'Emergency Alerts'
  ];

  // Lazy-load pages for better performance
  static const List<Widget> _pages = [
    GunStatusPage(),
    PerformanceTrendsPage(),
    DayMinMaxPage(),
    GunInchingPage(),
    EmergencyAlertsPage()
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _selectedIndexNotifier.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSelectPage(int index) {
    _selectedIndexNotifier.value = index;
    _animationController.forward(from: 0.0);
    Navigator.pop(context); // close the drawer
  }

  Icon _getMenuIcon(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.monitor_heart);
      case 1:
        return const Icon(Icons.analytics);
      case 2:
        return const Icon(Icons.trending_up);
      case 3:
        return const Icon(Icons.local_fire_department);
      case 4:
        return const Icon(Icons.warning);
      default:
        return const Icon(Icons.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('F.L.A.M.E - Dashboard'),
        backgroundColor: Colors.blue.shade800,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 21, 101, 192),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'F.L.A.M.E',
                    style: GoogleFonts.orbitron(
                      color: const Color.fromARGB(255, 147, 0, 0),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5,
                    ),
                  ),
                  const Text(
                    'One Dashboard  •  Total Control',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_menuTitles.length, (index) {
              return ValueListenableBuilder<int>(
                valueListenable: _selectedIndexNotifier,
                builder: (context, selectedIndex, _) {
                  return ListTile(
                    leading: _getMenuIcon(index),
                    title: Text(_menuTitles[index]),
                    onTap: () => _onSelectPage(index),
                    selected: selectedIndex == index,
                  );
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: _selectedIndexNotifier,
        builder: (context, selectedIndex, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.02, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: selectedIndex == -1
                ? const _WelcomeScreen(key: ValueKey('welcome'))
                : RepaintBoundary(
                    key: ValueKey(selectedIndex),
                    child: _pages[selectedIndex],
                  ),
          );
        },
      ),
    );
  }
}

// Separate welcome screen widget for optimization
class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              GlowImage(
                assetPath: 'assets/icon/flame.png',
                size: 100,
              ),
              const SizedBox(height: 20),
              /*RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: 'Welcome to '),
                    TextSpan(
                      text: 'FLAME',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              )*/
              const TypewriterWelcomeText(),
              const SizedBox(height: 8),
              Text(
                'Live Data Monitoring Ecosystem',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 35),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: AnimatedBorderGlow(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(218, 33, 149, 243)
                              .withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '📊 Real-time Gun Metric Monitoring',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '📈 Daily Min & Max Value Tracking',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '🚨 Custom Live Emergency Alerts',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a Menu Option To Get Started',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TypewriterWelcomeText extends StatefulWidget {
  const TypewriterWelcomeText({super.key});

  @override
  State<TypewriterWelcomeText> createState() => _TypewriterWelcomeTextState();
}

class _TypewriterWelcomeTextState extends State<TypewriterWelcomeText> {
  final String fullText = "Welcome to F.L.A.M.E";
  String visibleText = "";
  int index = 0;
  bool forward = true;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (forward) {
          index++;
          if (index >= fullText.length) {
            forward = false;

            // ✅ Pause before deleting
            timer.cancel();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _startTyping();
              }
            });
          }
        } else {
          index--;
          if (index <= 0) {
            forward = true;

            // ✅ Pause before typing again
            timer.cancel();
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                _startTyping();
              }
            });
          }
        }

        visibleText = fullText.substring(0, index);
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.orbitron(
          fontSize: 26,
          fontWeight: FontWeight.normal,
          color: Colors.black,
        ),
        children: [
          TextSpan(
            text: visibleText.contains("F.L.A.M.E")
                ? visibleText.split("F.L.A.M.E")[0]
                : visibleText,
          ),
          if (visibleText.contains("F.L.A.M.E"))
            TextSpan(
              text: "F.L.A.M.E",
              style: GoogleFonts.orbitron(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedBorderGlow extends StatefulWidget {
  final Widget child;

  const AnimatedBorderGlow({super.key, required this.child});

  @override
  State<AnimatedBorderGlow> createState() => _AnimatedBorderGlowState();
}

class _AnimatedBorderGlowState extends State<AnimatedBorderGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 2,
              color: Colors.transparent,
            ),
            gradient: SweepGradient(
              startAngle: 0,
              endAngle: 6.28,
              transform: GradientRotation(_controller.value * 6.28),
              colors: [
                Colors.transparent,
                Colors.blueAccent.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class GlowImage extends StatefulWidget {
  final String assetPath;
  final double size;

  const GlowImage({super.key, required this.assetPath, required this.size});

  @override
  State<GlowImage> createState() => _GlowImageState();
}

class _GlowImageState extends State<GlowImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3 * _controller.value),
                blurRadius: 40 * _controller.value,
                spreadRadius: 4 * _controller.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Image.asset(
        widget.assetPath,
        height: widget.size,
      ),
    );
  }
}
