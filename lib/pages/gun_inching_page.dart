import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/weld_count_data.dart';

class GunInchingPage extends StatefulWidget {
  const GunInchingPage({super.key});

  @override
  State<GunInchingPage> createState() => _GunInchingPageState();
}

class _GunInchingPageState extends State<GunInchingPage> {
  List<WeldCountData> weldCountData = [];
  WeldCountData? selectedGun;
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription<List<WeldCountData>>? _weldCountSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _subscribeToRealTimeData();
  }

  @override
  void dispose() {
    _weldCountSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getAllWeldCounts();
      setState(() {
        if (response.success && response.data != null) {
          weldCountData = response.data!;
          if (weldCountData.isNotEmpty && selectedGun == null) {
            selectedGun = weldCountData.first;
          }
          errorMessage = null;
        } else {
          weldCountData = ApiService.instance.cachedWeldCounts;
          if (weldCountData.isNotEmpty && selectedGun == null) {
            selectedGun = weldCountData.first;
          }
          errorMessage = response.error;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        weldCountData = ApiService.instance.cachedWeldCounts;
        if (weldCountData.isNotEmpty && selectedGun == null) {
          selectedGun = weldCountData.first;
        }
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  void _subscribeToRealTimeData() {
    _weldCountSubscription = ApiService.instance.weldCountStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            weldCountData = data;
            // Update selected gun with new data
            if (selectedGun != null) {
              final updatedGun = data.firstWhere(
                (gun) => gun.gunIndex == selectedGun!.gunIndex,
                orElse: () => selectedGun!,
              );
              selectedGun = updatedGun;
            } else if (data.isNotEmpty) {
              selectedGun = data.first;
            }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        title: const Text("Gun Inching",
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Gun selector dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  : weldCountData.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No guns available',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        )
                      : DropdownButton<WeldCountData>(
                          value: selectedGun,
                          isExpanded: true,
                          dropdownColor: Colors.blue.shade800,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                          underline: Container(),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                          items: weldCountData.map((gun) {
                            return DropdownMenuItem<WeldCountData>(
                              value: gun,
                              child: Text(
                                gun.gunName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (WeldCountData? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedGun = newValue;
                              });
                            }
                          },
                        ),
            ),

            const SizedBox(height: 32),

            // Weld count display
            if (selectedGun != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gun icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.build,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Gun name
                      Text(
                        selectedGun!.gunName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Weld count label
                      const Text(
                        'Total Welds',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Weld count value
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade800,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          '${selectedGun!.weldCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Last updated
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last updated: ${_formatTimestamp(selectedGun!.lastUpdated)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 80,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No gun selected',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
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

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
