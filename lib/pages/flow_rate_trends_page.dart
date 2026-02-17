// ignore_for_file: unused_field

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/gun_data.dart';

class FlowRateTrendsPage extends StatefulWidget {
  const FlowRateTrendsPage({super.key});

  @override
  State<FlowRateTrendsPage> createState() => _FlowRateTrendsPageState();
}

class _FlowRateTrendsPageState extends State<FlowRateTrendsPage> {
  final Random _random = Random();
  final Map<String, List<FlSpot>> _gunFlowHistory = {};
  final Map<String, Color> _gunColors = {};
  StreamSubscription<List<GunData>>? _dataSubscription;
  double _time = 0;
  String? _expandedGun;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeToRealTimeData();
  }

  void _subscribeToRealTimeData() {
    _dataSubscription = ApiService.instance.gunDataStream.listen(
      (data) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _time += 1;
          
          for (var gun in data) {
            // Initialize storage if first time
            if (!_gunFlowHistory.containsKey(gun.gunName)) {
              _gunFlowHistory[gun.gunName] = [];
              _gunColors[gun.gunName] = _generateDistinctColor();
            }
            
            // Use flow rate directly
            final flowValue = gun.flowRate;
            
            if (flowValue >= 0 && flowValue <= 100) { // Reasonable flow rate range
              // Normalize X values to prevent gaps when data points are missing
              final double normalizedTime = _gunFlowHistory[gun.gunName]!.isEmpty 
                  ? 0 
                  : _gunFlowHistory[gun.gunName]!.last.x + 1;
              
              _gunFlowHistory[gun.gunName]!.add(FlSpot(normalizedTime, flowValue));
              
              // Keep only last 50 points for performance
              if (_gunFlowHistory[gun.gunName]!.length > 50) {
                _gunFlowHistory[gun.gunName]!.removeAt(0);
                // Shift all remaining points to maintain continuity
                _gunFlowHistory[gun.gunName] = _gunFlowHistory[gun.gunName]!
                    .asMap()
                    .entries
                    .map((entry) => FlSpot(entry.key.toDouble(), entry.value.y))
                    .toList();
              }
            }
          }
        });
      },
      onError: (error) {
        debugPrint("Flow rate stream error: $error");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  Color _generateDistinctColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[_gunColors.length % colors.length];
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  Widget _buildChart(String gun, {bool expanded = false}) {
    final spots = _gunFlowHistory[gun] ?? [];
    final color = _gunColors[gun] ?? Colors.blue;

    // Calculate proper axis bounds
    final double minX = 0;
    final double maxX = spots.length > 1 ? spots.last.x : 10;
    final double minY = spots.map((s) => s.y).reduce(min) - 5;
    final double maxY = spots.map((s) => s.y).reduce(max) + 5;
    
    // Ensure reasonable bounds
    final double actualMinY = max(0, minY);
    final double actualMaxY = max(actualMinY + 10, maxY);

    return GestureDetector(
      onTap: expanded ? null : () {
        setState(() {
          _expandedGun = gun;
        });
      },
      child: Card(
        color: Colors.white,
        elevation: expanded ? 12 : 6,
        margin: EdgeInsets.all(expanded ? 16 : 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(expanded ? 20 : 12),
        ),
        child: Container(
          padding: EdgeInsets.all(expanded ? 20 : 12),
          height: expanded ? null : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      gun,
                      style: TextStyle(
                        fontSize: expanded ? 20 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (spots.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${spots.last.y.toStringAsFixed(1)} L/min',
                        style: TextStyle(
                          fontSize: expanded ? 16 : 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: expanded ? 16 : 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: minX,
                    maxX: maxX,
                    minY: actualMinY,
                    maxY: actualMaxY,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.white,

                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)} L/min',
                              TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: (actualMaxY - actualMinY) / 4,
                      verticalInterval: maxX > 5 ? maxX / 5 : 1,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: expanded ? 30 : 24,
                          interval: max(1, (maxX / 5).ceilToDouble()),
                          getTitlesWidget: (value, meta) {
                            if (value == minX || value == maxX ||
                                value % max(1, (maxX / 3).ceilToDouble()) == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: expanded ? 12 : 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: expanded ? 40 : 32,
                          interval: 10, // Show labels at 0, 10, 20, 30, 40, 50
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: expanded ? 12 : 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: color,
                        barWidth: expanded ? 3 : 2.5,
                        dotData: FlDotData(
                          show: expanded || spots.length <= 10,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: expanded ? 4 : 3,
                              color: color,
                              strokeColor: Colors.white,
                              strokeWidth: 2,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: expanded,
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.3),
                              color.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String gun, bool expanded) {
    return Card(
      color: Colors.white,
      elevation: expanded ? 12 : 6,
      margin: EdgeInsets.all(expanded ? 16 : 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(expanded ? 20 : 12),
      ),
      child: Container(
        padding: EdgeInsets.all(expanded ? 20 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              gun,
              style: TextStyle(
                fontSize: expanded ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: expanded ? 48 : 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No flow rate data",
                      style: TextStyle(
                        fontSize: expanded ? 16 : 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedChart(String gun) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () {
                      setState(() {
                        _expandedGun = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Flow Rate Trend - $gun',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 800,
                    maxHeight: 600,
                  ),
                  margin: const EdgeInsets.all(16),
                  child: _buildChart(gun, expanded: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_expandedGun != null) {
      return _buildExpandedChart(_expandedGun!);
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        title: const Text(
          "Flow Rate Trends",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading flow rate data...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _gunFlowHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No flow rate data available",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Waiting for live data from sensors...",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount;
                    double childAspectRatio;

                    if (constraints.maxWidth > 1200) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.2;
                    } else if (constraints.maxWidth > 800) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.1;
                    } else if (constraints.maxWidth > 500) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.0;
                    } else {
                      crossAxisCount = 1;
                      childAspectRatio = 1.5;
                    }

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      padding: const EdgeInsets.all(8),
                      children: _gunFlowHistory.keys
                          .map((gun) => _buildChart(gun))
                          .toList(),
                    );
                  },
                ),
    );
  }
}
