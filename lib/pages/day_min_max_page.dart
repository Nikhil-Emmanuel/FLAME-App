import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DayMinMaxPage extends StatefulWidget {
  const DayMinMaxPage({super.key});

  @override
  State<DayMinMaxPage> createState() => _GunStatsChartState();
}

class _GunStatsChartState extends State<DayMinMaxPage> {
  String selectedGun = 'G1';

  final Map<String, Map<String, double>> gunData = {
    'G1': {'minFlow': 10, 'maxFlow': 18, 'minTemp': 30, 'maxTemp': 42},
    'G2': {'minFlow': 7, 'maxFlow': 9, 'minTemp': 35, 'maxTemp': 46},
    'G3': {'minFlow': 12, 'maxFlow': 16, 'minTemp': 32, 'maxTemp': 38},
  };

  @override
  Widget build(BuildContext context) {
    final data = gunData[selectedGun]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gun Stats"),
        backgroundColor: Colors.blue.shade900,
      ),
      backgroundColor: Colors.blue.shade900,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedGun,
              dropdownColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  selectedGun = value!;
                });
              },
              items: gunData.keys.map((gun) {
                return DropdownMenuItem(
                  value: gun,
                  child: Text(
                    gun,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              "Max & Min Flow and Temp for $selectedGun",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20),

            /// 🚫 Infinite size fix with SizedBox constraint
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: data['minFlow']!,
                          color: Colors.teal,
                          width: 15,
                        ),
                        BarChartRodData(
                          toY: data['maxFlow']!,
                          color: Colors.orange,
                          width: 15,
                        ),
                      ],
                      barsSpace: 4,
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: data['minTemp']!,
                          color: Colors.blue,
                          width: 15,
                        ),
                        BarChartRodData(
                          toY: data['maxTemp']!,
                          color: Colors.redAccent,
                          width: 15,
                        ),
                      ],
                      barsSpace: 4,
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text("Flow",
                                  style: TextStyle(color: Colors.white));
                            case 1:
                              return const Text("Temp",
                                  style: TextStyle(color: Colors.white));
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}