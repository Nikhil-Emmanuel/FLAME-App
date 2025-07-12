import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class PieChartPage extends StatelessWidget {
  const PieChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    Map<String, double> dataMap = {
      "G1": 30,
      "G2": 25,
      "G3": 20,
      "G4": 15,
      "G5": 10,
    };

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: const Text("Gun Status Overview"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            PieChart(
              dataMap: dataMap,
              animationDuration: const Duration(milliseconds: 800),
              chartLegendSpacing: 32,
              chartRadius: MediaQuery.of(context).size.width / 2.2,
              colorList: const [
                Colors.green,
                Colors.orange,
                Colors.yellow,
                Colors.red,
                Colors.blue,
              ],
              chartType: ChartType.ring,
              ringStrokeWidth: 28,
              legendOptions: const LegendOptions(
                showLegends: true,
                legendPosition: LegendPosition.right,
                legendTextStyle: TextStyle(color: Colors.white),
              ),
              chartValuesOptions: const ChartValuesOptions(
                showChartValueBackground: false,
                showChartValues: true,
                showChartValuesInPercentage: true,
                decimalPlaces: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
