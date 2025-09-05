import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/gun_data.dart';

class EmergencyAlertsPage extends StatefulWidget {
  const EmergencyAlertsPage({super.key});

  @override
  State<EmergencyAlertsPage> createState() => _EmergencyAlertsPageState();
}

class _EmergencyAlertsPageState extends State<EmergencyAlertsPage> {
  List<AlertData> alerts = [];
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription<List<AlertData>>? _alertSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialAlerts();
    _subscribeToRealTimeAlerts();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialAlerts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getAlerts();
      setState(() {
        if (response.success && response.data != null) {
          alerts = response.data!;
          errorMessage = null;
        } else {
          alerts = ApiService.instance.cachedAlerts;
          errorMessage = response.error;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        alerts = ApiService.instance.cachedAlerts;
        errorMessage = 'Failed to load alerts: $e';
        isLoading = false;
      });
    }
  }

  void _subscribeToRealTimeAlerts() {
    _alertSubscription = ApiService.instance.alertStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            alerts = data;
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

  Future<void> _refreshAlerts() async {
    await _loadInitialAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text('Emergency Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAlerts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAlerts,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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

            // Alert count header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: alerts.isEmpty ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Loading indicator or alert list
            if (isLoading)
              const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (alerts.isEmpty)
              const SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'No Active Alerts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All guns are operating normally',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    Color cardColor = alert.severity == 'CRITICAL'
                        ? Colors.red.shade400
                        : Colors.orange.shade400;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: cardColor,
                      child: ListTile(
                        leading: Icon(
                          alert.severity == 'CRITICAL' ? Icons.error : Icons.warning,
                          color: Colors.white,
                          size: 32,
                        ),
                        title: Text(
                          'Gun: ${alert.gunName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flow: ${alert.flowDisplay} | Temp: ${alert.tempDisplay}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    alert.alertType.replaceAll('_', ' '),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: alert.severity == 'CRITICAL' ? Colors.red.shade700 : Colors.orange.shade700,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    alert.severity,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshAlerts,
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  label: const Text('Refresh', style: TextStyle(color: Colors.blue)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: alerts.isNotEmpty ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Alert report generated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } : null,
                  icon: const Icon(Icons.report, color: Colors.red),
                  label: const Text('Generate Report', style: TextStyle(color: Colors.red)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}
