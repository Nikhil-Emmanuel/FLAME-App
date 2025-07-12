import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DayMinMaxPage extends StatefulWidget {
  const DayMinMaxPage({super.key});

  @override
  State<DayMinMaxPage> createState() => _DayMinMaxPageState();
}

class _DayMinMaxPageState extends State<DayMinMaxPage> {
  String selectedGun = 'G1';

  final Map<String, Map<String, double>> gunData = {
    'G1': {'minFlow': 10, 'maxFlow': 18, 'minTemp': 30, 'maxTemp': 42},
    'G2': {'minFlow': 7, 'maxFlow': 9, 'minTemp': 35, 'maxTemp': 46},
    'G3': {'minFlow': 12, 'maxFlow': 16, 'minTemp': 32, 'maxTemp': 38},
  };

  double safeValue(double? val) {
    if (val == null || val.isNaN || val.isInfinite || val <= 0) {
      return 0.1;
    }
    return val;
  }

  bool isAllZero(List<double> values) {
    return values.every((val) => val <= 0.1);
  }

  Color getStatusColor(String type, double value) {
    if (type == 'flow') {
      if (value < 9) return Colors.red;
      if (value < 12) return Colors.yellow;
      return Colors.green;
    } else {
      if (value > 45) return Colors.red;
      if (value > 40) return Colors.yellow;
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = gunData[selectedGun] ?? {};

    final minFlow = safeValue(data['minFlow']);
    final maxFlow = safeValue(data['maxFlow']);
    final minTemp = safeValue(data['minTemp']);
    final maxTemp = safeValue(data['maxTemp']);

    final allValues = [minFlow, maxFlow, minTemp, maxTemp];
    final showChart = !isAllZero(allValues);

    return Scaffold(
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
                  child: Text(gun),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              "Min & Max Flow/Temperature for $selectedGun",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 30),

            /// ✅ Chart Section
            showChart
                ? BarChart(
                    BarChartData(
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(
                            toY: minFlow,
                            color: getStatusColor('flow', minFlow),
                            width: 18,
                          ),
                          BarChartRodData(
                            toY: maxFlow,
                            color: getStatusColor('flow', maxFlow),
                            width: 18,
                          ),
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(
                            toY: minTemp,
                            color: getStatusColor('temp', minTemp),
                            width: 18,
                          ),
                          BarChartRodData(
                            toY: maxTemp,
                            color: getStatusColor('temp', maxTemp),
                            width: 18,
                          ),
                        ]),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              switch (value.toInt()) {
                                case 0:
                                  return const Text('Flow',
                                      style: TextStyle(color: Colors.white));
                                case 1:
                                  return const Text('Temp',
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
                            getTitlesWidget: (value, _) {
                              return Text(
                                value.toString(),
                                style: const TextStyle(color: Colors.white),
                              );
                            },
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
                  )
                : const Text(
                    "No valid data available to display the chart.",
                    style: TextStyle(color: Colors.white),
                  ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Home", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}