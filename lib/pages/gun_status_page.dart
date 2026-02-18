import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
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
        title: const Text('Gun Status',
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
                          else
                            RepaintBoundary(
                              child: _GunStatusTable(gunData: gunData),
                            ),

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

// Separate widget for table to optimize repaints
class _GunStatusTable extends StatelessWidget {
  const _GunStatusTable({required this.gunData});

  final List<GunData> gunData;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.white),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blue.shade800),
          children: const [
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('Gun',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('Flow (L/min)',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('Temperature (°C)',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('Status',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...gunData.map((gun) {
          Color statusColor = gun.healthStatus == 'Good'
              ? Colors.green
              : gun.healthStatus == 'Maintenance Needed'
                  ? Colors.orange
                  : Colors.red;

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(gun.gunName,
                    style: const TextStyle(color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(gun.flowDisplay,
                    style: const TextStyle(color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(gun.tempDisplay,
                    style: const TextStyle(color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(gun.healthStatus,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }),
      ],
    );
  }
}
