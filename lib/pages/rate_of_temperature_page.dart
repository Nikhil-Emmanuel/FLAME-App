import 'package:flutter/material.dart';

class RateOfTemperaturePage extends StatefulWidget {
  const RateOfTemperaturePage({super.key});

  @override
  State<RateOfTemperaturePage> createState() => _RateOfTemperaturePageState();
}

class _RateOfTemperaturePageState extends State<RateOfTemperaturePage> {
  bool isLoading = false;

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Temperature data refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text('Temperature Trends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else ...[
                    const Icon(Icons.thermostat, color: Colors.white, size: 60),
                    const SizedBox(height: 20),
                    const Text(
                      'Temperature Trends Analysis',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Real-time temperature monitoring and trend analysis\nwill be displayed here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '📈 Temperature trend analysis',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '🌡️ Real-time temperature monitoring',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '📊 Historical data visualization',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Pull down to refresh data',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
