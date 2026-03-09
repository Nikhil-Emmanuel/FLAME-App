import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../services/min_max_service.dart';
import '../services/api_service.dart';
import '../models/gun_data.dart';
import '../services/settings_service.dart';

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

  Color getFlowColor(double value) {
    final settings = SettingsService.instance;

    if (value <= settings.criticalFlowThreshold) {
      return Colors.red;
    } else if (value <= settings.lowFlowThreshold) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Color getTempColor(double value) {
    final settings = SettingsService.instance;

    if (value >= settings.criticalTemperatureThreshold) {
      return Colors.red;
    } else if (value >= settings.highTemperatureThreshold) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _buildThresholdLegend() {
    final settings = SettingsService.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Color Legend for Graph",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          // FLOW SECTION
          const Text(
            "Flow Rate (L/min)",
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _legendRow("≤ ${settings.criticalFlowThreshold}  -->  Critical", Colors.red),
          _legendRow("≤ ${settings.lowFlowThreshold}  -->  Marginal", Colors.orange),
          _legendRow("> ${settings.lowFlowThreshold}  -->  Good", Colors.green),

          const SizedBox(height: 14),

          // TEMP SECTION
          const Text(
            "Temperature °C",
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _legendRow("≥ ${settings.criticalTemperatureThreshold}  -->  Critical", Colors.red),
          _legendRow("≥ ${settings.highTemperatureThreshold}  -->  Marginal", Colors.orange),
          _legendRow("< ${settings.highTemperatureThreshold}  -->  Good", Colors.green),
        ],
      ),
    );
  }

  Widget _legendRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

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
        backgroundColor: Colors.blue.shade900,
        appBar: AppBar(
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          title: const Text("Daily Min/Max",
              style: TextStyle(fontWeight: FontWeight.w600)),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (currentGunData.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.blue.shade900,
        appBar: AppBar(
          title: const Text("Daily Min/Max",
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'No gun data available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final selectedMinMax =
        selectedGun != null ? minMaxData[selectedGun!] : null;
    final currentGun = currentGunData.firstWhere(
      (gun) => gun.gunName == selectedGun,
      orElse: () => currentGunData.first,
    );

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: const Text("Daily Min/Max",
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              // Gun selector
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
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
                  _buildDataRow(
                      'Flow Rate',
                      '${currentGun.flowRate.toStringAsFixed(1)} L/min',
                      const Color.fromARGB(255, 5, 213, 255)),
                  _buildDataRow(
                      'Temperature',
                      '${currentGun.temperature.toStringAsFixed(1)} °C',
                      const Color.fromARGB(255, 242, 115, 4)),
                ]),
                const SizedBox(height: 20),

                _buildDataCard('Today\'s Min/Max Values', [
                  _buildDataRow(
                    'Min Flow',
                    '${selectedMinMax.minFlow.toStringAsFixed(1)} L/min',
                    const Color.fromARGB(255, 241, 3, 3),
                  ),
                  _buildDataRow(
                    'Max Flow',
                    '${selectedMinMax.maxFlow.toStringAsFixed(1)} L/min',
                    const Color.fromARGB(255, 96, 239, 19),
                  ),

                  const SizedBox(height: 8),

                  const Divider(
                    color: Colors.white38,
                    thickness: 1,
                  ),

                  const SizedBox(height: 8),

                  _buildDataRow(
                      'Min Temp',
                      '${selectedMinMax.minTemp.toStringAsFixed(1)} °C',
                      const Color.fromARGB(255, 96, 239, 19)),
                  _buildDataRow(
                      'Max Temp',
                      '${selectedMinMax.maxTemp.toStringAsFixed(1)} °C',
                      const Color.fromARGB(255, 236, 27, 12)),
                ]),
                const SizedBox(height: 20),

                _buildThresholdLegend(),
                const SizedBox(height: 30),

                // Chart
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      /// 🔥 TOOLTIP CONFIG (MIN / MAX labels attached to rods)
                      barTouchData: BarTouchData(
                        enabled:
                            true, // static labels (set true if you want interaction)
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = rodIndex == 0 ? "MIN" : "MAX";

                            return BarTooltipItem(
                              '',
                              const TextStyle(),
                              children: [
                                TextSpan(
                                  text: label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    height: 1.7, // controls space above
                                  ),
                                ),
                                TextSpan(
                                  text: "\n${rod.toY.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    height: 0.1, // 🔥 increase this to increase gap
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      barGroups: [
                        /// FLOW GROUP
                        BarChartGroupData(
                          x: 0,
                          //showingTooltipIndicators: const [0, 1],
                          barRods: [
                            BarChartRodData(
                              toY: selectedMinMax.minFlow,
                              color: getFlowColor(selectedMinMax.minFlow),
                              width: 15,
                            ),
                            BarChartRodData(
                              toY: selectedMinMax.maxFlow,
                              color: getFlowColor(selectedMinMax.maxFlow),
                              width: 15,
                            ),
                          ],
                          barsSpace: 4,
                        ),

                        /// TEMP GROUP
                        BarChartGroupData(
                          x: 1,
                          //showingTooltipIndicators: const [0, 1],
                          barRods: [
                            BarChartRodData(
                              toY: selectedMinMax.minTemp,
                              color: getTempColor(selectedMinMax.minTemp),
                              width: 15,
                            ),
                            BarChartRodData(
                              toY: selectedMinMax.maxTemp,
                              color: getTempColor(selectedMinMax.maxTemp),
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
                                  return const Text(
                                    "Flow",
                                    style: TextStyle(color: Colors.white),
                                  );
                                case 1:
                                  return const Text(
                                    "Temp",
                                    style: TextStyle(color: Colors.white),
                                  );
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
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
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
                      const Icon(Icons.info_outline,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'No min/max data available yet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
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
