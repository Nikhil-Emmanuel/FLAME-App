import 'package:flutter/material.dart';
import 'gun_status_page.dart';
import 'pie_chart_page.dart';
import 'day_min_max_page.dart';
import 'rate_of_temperature_page.dart';
import 'gun_report_page.dart';
import 'emergency_alerts_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = -1;

  final List<String> _menuTitles = [
    'Gun Status',
    'Pie Chart',
    'Day Min/Max',
    'Rate of Temperature',
    'Gun Report',
    'Emergency Alerts'
  ];

  final List<Widget> _pages = [
    const GunStatusPage(),
    const PieChartPage(),
    const DayMinMaxPage(),
    const RateOfTemperaturePage(),
    const GunReportPage(),
    EmergencyAlertsPage(),
  ];

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // close the drawer
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
        child: ListView.builder(
          itemCount: _menuTitles.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_menuTitles[index]),
              onTap: () => _onSelectPage(index),
            );
          },
        ),
      ),
      body: _selectedIndex == -1
          ? const Center(
              child: Text(
                'Welcome to FLAME',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            )
          : _pages[_selectedIndex],
    );
  }
}
