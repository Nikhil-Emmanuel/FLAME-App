import 'package:flutter/material.dart';

class GunReportPage extends StatefulWidget {
  const GunReportPage({super.key});

  @override
  State<GunReportPage> createState() => _GunReportPageState();
}

class _GunReportPageState extends State<GunReportPage> {
  String selectedGun = 'G1';

  final Map<String, Map<String, dynamic>> gunData = {
    'G1': {'flow': 12.0, 'temp': 40.0, 'minFlow': 10.5, 'maxTemp': 42.0},
    'G2': {'flow': 9.5, 'temp': 46.0, 'minFlow': 8.5, 'maxTemp': 48.0},
    'G3': {'flow': 11.0, 'temp': 39.5, 'minFlow': 10.0, 'maxTemp': 41.0},
  };

  String getHealthStatus(double flow, double temp) {
    if (flow >= 10 && temp <= 45) return 'Good';
    if (flow < 10 && temp <= 45) return 'Maintenance Needed';
    return 'Immediate Action';
  }

  @override
  Widget build(BuildContext context) {
    final gun = gunData[selectedGun]!;
    final health = getHealthStatus(gun['flow'], gun['temp']);

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: const Text("Gun Report"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Gun:",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedGun,
              dropdownColor: Colors.blue.shade800,
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: gunData.keys.map((gun) {
                return DropdownMenuItem(
                  value: gun,
                  child: Text(gun),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGun = value!;
                });
              },
            ),
            const SizedBox(height: 30),
            infoRow("Flow:", "${gun['flow']} L/min"),
            infoRow("Temperature:", "${gun['temp']} °C"),
            infoRow("Min Flow (Day):", "${gun['minFlow']} L/min"),
            infoRow("Max Temp (Day):", "${gun['maxTemp']} °C"),
            const SizedBox(height: 30),
            Row(
              children: [
                const Text("Health Status: ",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Text(
                  health,
                  style: TextStyle(
                    fontSize: 18,
                    color: health == 'Good'
                        ? Colors.green
                        : health == 'Maintenance Needed'
                            ? Colors.yellow
                            : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          )
        ],
      ),
    );
  }
}
