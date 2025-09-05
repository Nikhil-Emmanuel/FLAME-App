import 'package:flutter/material.dart';
import 'gun_status_page.dart';
import 'pie_chart_page.dart';
import 'day_min_max_page.dart';
import 'rate_of_temperature_page.dart';
import 'emergency_alerts_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = -1;

  final List<String> _menuTitles = [
    'Live Gun Status',
    'Status Overview',
    'Daily Min/Max',
    'Temperature Trends',
    'Emergency Alerts'
  ];

  final List<Widget> _pages = [
    const GunStatusPage(),
    const PieChartPage(),
    const DayMinMaxPage(),
    const RateOfTemperaturePage(),
    const EmergencyAlertsPage(),
  ];

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // close the drawer
  }

  Icon _getMenuIcon(int index) {
    switch (index) {
      case 0: return const Icon(Icons.monitor_heart); // Live Gun Status
      case 1: return const Icon(Icons.pie_chart); // Status Overview
      case 2: return const Icon(Icons.trending_up); // Daily Min/Max
      case 3: return const Icon(Icons.thermostat); // Temperature Trends
      case 4: return const Icon(Icons.warning); // Emergency Alerts
      default: return const Icon(Icons.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flame - Dashboard'),
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
                color: Colors.blue.shade800,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'FLAME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_menuTitles.length, (index) {
              return ListTile(
                leading: _getMenuIcon(index),
                title: Text(_menuTitles[index]),
                onTap: () => _onSelectPage(index),
                selected: _selectedIndex == index,
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close drawer
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
                Navigator.pop(context); // Close drawer
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _selectedIndex == -1
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 80,
                    color: Colors.blue.shade800,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to FLAME',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Live Data Monitoring System',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '📊 Real-time gun status monitoring',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '📈 Daily min/max value tracking',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '🚨 Live emergency alerts',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a menu option to get started',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : _pages[_selectedIndex],
    );
  }
}
