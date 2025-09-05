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

  Future<void> _refreshData() async {
    await _loadInitialData();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text('Gun Status'),
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
          child: ListView(
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

            // Loading indicator
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              Table(
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
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, color: Colors.blue),
                label: const Text('Refresh Data', style: TextStyle(color: Colors.blue)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
