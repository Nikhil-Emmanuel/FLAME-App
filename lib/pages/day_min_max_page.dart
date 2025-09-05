import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../services/min_max_service.dart';
import '../services/api_service.dart';
import '../models/gun_data.dart';

class DayMinMaxPage extends StatefulWidget {
  const DayMinMaxPage({super.key});

  @override
  State<DayMinMaxPage> createState() => _GunStatsChartState();
}

class _GunStatsChartState extends State<DayMinMaxPage> {
  String? selectedGun;
  Map<String, MinMaxData> minMaxData = {};
  List<GunData> currentGunData = [];
  bool isLoading = true;
  StreamSubscription<List<GunData>>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToRealTimeData();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load current gun data
      final response = await ApiService.instance.getAllGuns();
      if (response.success && response.data != null) {
        currentGunData = response.data!;
      } else {
        currentGunData = ApiService.instance.cachedGunData;
      }

      // Load min/max data
      minMaxData = MinMaxService.instance.getTodayMinMax();

      // Set default selected gun
      if (selectedGun == null && currentGunData.isNotEmpty) {
        selectedGun = currentGunData.first.gunName;
      }
    } catch (e) {
      // Handle error
      currentGunData = ApiService.instance.cachedGunData;
      minMaxData = MinMaxService.instance.getTodayMinMax();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _subscribeToRealTimeData() {
    _dataSubscription = ApiService.instance.gunDataStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            currentGunData = data;
            minMaxData = MinMaxService.instance.getTodayMinMax();

            // Update selected gun if it doesn't exist
            if (selectedGun == null && data.isNotEmpty) {
              selectedGun = data.first.gunName;
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Daily Min/Max"),
          backgroundColor: Colors.blue.shade900,
        ),
        backgroundColor: Colors.blue.shade900,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (currentGunData.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Daily Min/Max"),
          backgroundColor: Colors.blue.shade900,
        ),
        backgroundColor: Colors.blue.shade900,
        body: const Center(
          child: Text(
            'No gun data available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final selectedMinMax = selectedGun != null ? minMaxData[selectedGun!] : null;
    final currentGun = currentGunData.firstWhere(
      (gun) => gun.gunName == selectedGun,
      orElse: () => currentGunData.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Min/Max"),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      backgroundColor: Colors.blue.shade900,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
            // Gun selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedGun,
                dropdownColor: Colors.white,
                isExpanded: true,
                underline: Container(),
                onChanged: (value) {
                  setState(() {
                    selectedGun = value!;
                  });
                },
                items: currentGunData.map((gun) {
                  return DropdownMenuItem(
                    value: gun.gunName,
                    child: Text(
                      gun.gunName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Date info
            Text(
              "Today's Min/Max for $selectedGun",
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              MinMaxService.instance.getTodayDateString(),
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),

            /// 🚫 Infinite size fix with SizedBox constraint
            // Current values display
            if (selectedMinMax != null) ...[
              _buildDataCard('Current Live Values', [
                _buildDataRow('Flow Rate', '${currentGun.flowRate.toStringAsFixed(1)} L/min', Colors.blue),
                _buildDataRow('Temperature', '${currentGun.temperature.toStringAsFixed(1)} °C', Colors.orange),
              ]),
              const SizedBox(height: 20),

              _buildDataCard('Today\'s Min/Max Values', [
                _buildDataRow('Min Flow', '${selectedMinMax.minFlow.toStringAsFixed(1)} L/min', Colors.teal),
                _buildDataRow('Max Flow', '${selectedMinMax.maxFlow.toStringAsFixed(1)} L/min', Colors.teal.shade700),
                _buildDataRow('Min Temp', '${selectedMinMax.minTemp.toStringAsFixed(1)} °C', Colors.blue),
                _buildDataRow('Max Temp', '${selectedMinMax.maxTemp.toStringAsFixed(1)} °C', Colors.red),
              ]),
              const SizedBox(height: 20),

              // Chart
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
                            toY: selectedMinMax.minFlow,
                            color: Colors.teal,
                            width: 15,
                          ),
                          BarChartRodData(
                            toY: selectedMinMax.maxFlow,
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
                            toY: selectedMinMax.minTemp,
                            color: Colors.blue,
                            width: 15,
                          ),
                          BarChartRodData(
                            toY: selectedMinMax.maxTemp,
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
            ] else ...[
              // No min/max data available yet
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'No min/max data available yet',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Data will be collected as live updates are received',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Current: ${currentGun.flowRate.toStringAsFixed(1)} L/min, ${currentGun.temperature.toStringAsFixed(1)} °C',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}