import 'package:flutter/material.dart';

class GunStatusPage extends StatefulWidget {
  const GunStatusPage({super.key});

  @override
  State<GunStatusPage> createState() => _GunStatusPageState();
}

class _GunStatusPageState extends State<GunStatusPage> {
  List<Map<String, dynamic>> gunData = [
    {'name': 'G1', 'flow': '--', 'temp': '--'},
    {'name': 'G2', 'flow': '--', 'temp': '--'},
    {'name': 'G3', 'flow': '--', 'temp': '--'},
  ];

  void _addGun() {
    setState(() {
      int newGunNumber = gunData.length + 1;
      gunData.add({
        'name': 'G$newGunNumber',
        'flow': '--',
        'temp': '--',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text('Gun Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Table(
              border: TableBorder.all(color: Colors.white),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade800),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('Gun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('Flow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('Temperature', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...gunData.map((gun) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(gun['name'], style: const TextStyle(color: Colors.white)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(gun['flow'], style: const TextStyle(color: Colors.white)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(gun['temp'], style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addGun,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('Add Gun', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
