import 'package:flutter/material.dart';

class EmergencyAlertsPage extends StatelessWidget {
  final List<Map<String, dynamic>> alerts = [
    {'gun': 'G1', 'flow': 8.5, 'temp': 46.2},
    {'gun': 'G3', 'flow': 7.8, 'temp': 45.9},
  ];

  EmergencyAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Emergency Alerts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Alert List
            Expanded(
              child: ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Card(
                    color: Colors.red.shade300,
                    child: ListTile(
                      title: Text(
                        'Gun: ${alert['gun']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Flow: ${alert['flow']} L\nTemperature: ${alert['temp']} °C',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Generate Report Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report generated successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Generate Report', style: TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 20),

            // Back to Home
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Back to Home',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
