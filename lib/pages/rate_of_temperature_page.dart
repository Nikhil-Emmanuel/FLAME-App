import 'package:flutter/material.dart';

class RateOfTemperaturePage extends StatelessWidget {
  const RateOfTemperaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text('Rate of Temperature'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.thermostat, color: Colors.white, size: 60),
            SizedBox(height: 20),
            Text(
              'Rate of Temperature Page\n(Coming Soon)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
