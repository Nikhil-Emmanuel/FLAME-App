import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/gun_data.dart';

class PieChartPage extends StatefulWidget {
  const PieChartPage({super.key});

  @override
  State<PieChartPage> createState() => _PieChartPageState();
}

class _PieChartPageState extends State<PieChartPage> {
  List<GunData> gunData = [];
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription<List<GunData>>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _subscribeToRealTimeData();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getAllGuns();
      setState(() {
        if (response.success && response.data != null) {
          gunData = response.data!;
          errorMessage = null;
        } else {
          gunData = ApiService.instance.cachedGunData;
          errorMessage = response.error;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        gunData = ApiService.instance.cachedGunData;
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  void _subscribeToRealTimeData() {
    _dataSubscription = ApiService.instance.gunDataStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            gunData = data;
            errorMessage = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            errorMessage = 'Real-time connection error: $error';
          });
        }
      },
    );
  }

  Map<String, double> _generateChartData() {
    if (gunData.isEmpty) {
      return {"No Data": 100};
    }

    Map<String, double> dataMap = {};
    for (var gun in gunData) {
      // Use flow rate as the value for the pie chart
      dataMap[gun.gunName] = gun.flowRate;
    }
    return dataMap;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> dataMap = _generateChartData();

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: const Text("Gun Flow Rate Overview"),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
            // Connection status indicator
            if (errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ApiService.instance.isConnected ? Colors.orange : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      ApiService.instance.isConnected ? Icons.warning : Icons.offline_bolt,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ApiService.instance.isConnected
                          ? 'Using cached data'
                          : 'Offline - Using cached data',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (gunData.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart_outline, color: Colors.white70, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'No Data Available',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Chart title with total guns
                    Text(
                      'Flow Rate Distribution (${gunData.length} Guns)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pie Chart
                    SizedBox(
                      height: 400, // Fixed height for the chart
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Determine layout based on available width
                          final isWideScreen = constraints.maxWidth > 600;
                          final chartRadius = constraints.maxWidth * (isWideScreen ? 0.25 : 0.35);

                          return PieChart(
                              dataMap: dataMap,
                              animationDuration: const Duration(milliseconds: 800),
                              chartLegendSpacing: isWideScreen ? 32 : 16,
                              chartRadius: chartRadius,
                              colorList: _generateColors(gunData.length),
                              chartType: ChartType.ring,
                              ringStrokeWidth: isWideScreen ? 28 : 20,
                              legendOptions: LegendOptions(
                                showLegends: true,
                                legendPosition: isWideScreen ? LegendPosition.right : LegendPosition.bottom,
                                legendTextStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWideScreen ? 12 : 10,
                                ),
                              ),
                              chartValuesOptions: ChartValuesOptions(
                                showChartValueBackground: true,
                                showChartValues: true,
                                showChartValuesInPercentage: false,
                                showChartValuesOutside: false,
                                decimalPlaces: 1,
                                chartValueStyle: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isWideScreen ? 10 : 8,
                                ),
                              ),
                          );
                        },
                      ),
                    ),

                    // Summary statistics
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Total Guns', '${gunData.length}'),
                          _buildStatItem('Avg Flow', '${_calculateAverageFlow().toStringAsFixed(1)} L/min'),
                          _buildStatItem('Alerts', '${gunData.where((gun) => gun.isAlert).length}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Color> _generateColors(int count) {
    const baseColors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    if (count <= baseColors.length) {
      return baseColors.take(count).toList();
    }

    // Generate additional colors if needed
    List<Color> colors = List.from(baseColors);
    for (int i = baseColors.length; i < count; i++) {
      colors.add(Color.fromARGB(
        255,
        (i * 50) % 255,
        (i * 80) % 255,
        (i * 120) % 255,
      ));
    }
    return colors;
  }

  double _calculateAverageFlow() {
    if (gunData.isEmpty) return 0.0;
    double total = gunData.fold(0.0, (sum, gun) => sum + gun.flowRate);
    return total / gunData.length;
  }
}
