import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pie_chart/pie_chart.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../models/gun_data.dart';

class GunStatusPage extends StatefulWidget {
  const GunStatusPage({super.key});

  @override
  State<GunStatusPage> createState() => _GunStatusPageState();
}

class _GunStatusPageState extends State<GunStatusPage> {
  // Use ValueNotifiers for minimal rebuilds
  final ValueNotifier<List<GunData>> _gunDataNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<String?> _errorNotifier = ValueNotifier(null);

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
    _gunDataNotifier.dispose();
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _isLoadingNotifier.value = true;
    _errorNotifier.value = null;

    try {
      final response = await ApiService.instance.getAllGuns();
      if (response.success && response.data != null) {
        _gunDataNotifier.value = response.data!;
        _errorNotifier.value = null;
      } else {
        _gunDataNotifier.value = ApiService.instance.cachedGunData;
        _errorNotifier.value = response.error;
      }
      _isLoadingNotifier.value = false;
    } catch (e) {
      _gunDataNotifier.value = ApiService.instance.cachedGunData;
      _errorNotifier.value = 'Failed to load data: $e';
      _isLoadingNotifier.value = false;
    }
  }

  void _subscribeToRealTimeData() {
    _dataSubscription = ApiService.instance.gunDataStream.listen(
      (data) {
        _gunDataNotifier.value = data;
        _errorNotifier.value = null;
      },
      onError: (error) {
        _errorNotifier.value = 'Real-time connection error: $error';
      },
    );
  }

  Future<void> _refreshData() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        title: const Text('Gun Overview',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, _) {
              return ValueListenableBuilder<String?>(
                valueListenable: _errorNotifier,
                builder: (context, errorMessage, _) {
                  return ValueListenableBuilder<List<GunData>>(
                    valueListenable: _gunDataNotifier,
                    builder: (context, gunData, _) {
                      return ListView(
                        children: [
                          // Connection status indicator
                          if (errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: ApiService.instance.isConnected
                                    ? Colors.orange
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    ApiService.instance.isConnected
                                        ? Icons.warning
                                        : Icons.offline_bolt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ApiService.instance.isConnected
                                          ? 'Using cached data'
                                          : 'Offline - Using cached data',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Loading indicator
                          if (isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          else ...[
                            // Health Status Pie Chart
                            RepaintBoundary(
                              child: _HealthStatusPieChart(gunData: gunData),
                            ),
                            const SizedBox(height: 24),
                            // Gun Status Table
                            RepaintBoundary(
                              child: _GunStatusTable(gunData: gunData),
                            ),
                          ],

                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon:
                                  const Icon(Icons.refresh, color: Colors.blue),
                              label: const Text('Refresh Data',
                                  style: TextStyle(color: Colors.blue)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Card view for gun status
class _GunStatusTable extends StatelessWidget {
  const _GunStatusTable({required this.gunData});

  final List<GunData> gunData;

  int _getPriority(String status) {
    switch (status) {
      case 'Critical':
        return 0; // Highest priority
      case 'Marginal':
      case 'Needs Maintenance': // handle both variants
        return 1;
      case 'Good':
        return 2; // Lowest priority
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final sortedGuns = List<GunData>.from(gunData)
      ..sort((a, b) =>
          _getPriority(a.healthStatusWithThresholds(settings.highTemperatureThreshold, settings.lowFlowThreshold, settings.criticalTemperatureThreshold, settings.criticalFlowThreshold)).compareTo(_getPriority(b.healthStatusWithThresholds(settings.highTemperatureThreshold, settings.lowFlowThreshold, settings.criticalTemperatureThreshold, settings.criticalFlowThreshold))));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedGuns.length,
      itemBuilder: (context, index) {
        final gun = sortedGuns[index];
        final healthStatus = gun.healthStatusWithThresholds(settings.highTemperatureThreshold, settings.lowFlowThreshold, settings.criticalTemperatureThreshold, settings.criticalFlowThreshold);
        Color statusColor = healthStatus == 'Good'
            ? Colors.green
            : healthStatus == 'Marginal'? Colors.orange: Colors.red;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 FIRST ROW (Main Info)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${gun.gunName}  |  ${gun.flowDisplay}  |  ${gun.tempDisplay}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 SECOND ROW (Status Banner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  healthStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Health Status Pie Chart Widget
class _HealthStatusPieChart extends StatelessWidget {
  const _HealthStatusPieChart({required this.gunData});

  final List<GunData> gunData;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;

    // Calculate health status counts
    int goodCount = 0;
    int maintenanceCount = 0;
    int immediateActionCount = 0;

    for (var gun in gunData) {
      final status = gun.healthStatusWithThresholds(
        settings.highTemperatureThreshold,
        settings.lowFlowThreshold,
        settings.criticalTemperatureThreshold,
        settings.criticalFlowThreshold
      );
      switch (status) {
        case 'Good':
          goodCount++;
          break;
        case 'Marginal':
          maintenanceCount++;
          break;
        case 'Critical':
          immediateActionCount++;
          break;
      }
    }

    // Create data map for pie chart with fixed order
    Map<String, double> dataMap = {};
    if (goodCount > 0) dataMap['Good'] = goodCount.toDouble();
    if (maintenanceCount > 0) dataMap['Marginal'] = maintenanceCount.toDouble();
    if (immediateActionCount > 0) dataMap['Critical'] = immediateActionCount.toDouble();

    // If no data, show placeholder
    if (dataMap.isEmpty) {
      dataMap = {'No Data': 1};
    }

    // Color map matching exact order
    final Map<String, Color> colorMap = {
      'Good': Colors.green,
      'Marginal': Colors.orange,
      'Critical': Colors.red,
      'No Data': Colors.grey,
    };

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Gun Health Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            PieChart(
              dataMap: dataMap,
              animationDuration: const Duration(milliseconds: 900),
              chartLegendSpacing: 32,
              chartRadius: MediaQuery.of(context).size.width / 0.1,
              colorList: dataMap.keys.map((key) => colorMap[key]!).toList(),
              initialAngleInDegree: 0,
              chartType: ChartType.disc,
              legendOptions: const LegendOptions(
                showLegendsInRow: false,
                legendPosition: LegendPosition.right,
                showLegends: true,
                legendTextStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              chartValuesOptions: const ChartValuesOptions(
                showChartValueBackground: false,
                showChartValues: true,
                showChartValuesInPercentage: false,
                showChartValuesOutside: false,
                decimalPlaces: 0,
                chartValueStyle: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Summary text
            Text(
              'Total Guns: ${gunData.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
