import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Server configuration
  static String? _serverIp;
  static const int serverPort = 7575;
  static const String apiKey = 'FlameApp123\$byNevark';

  // Shared Preferences keys
  static const String _serverIpKey = 'server_ip';

  // Getter and setter for serverIp
  static String get serverIp => _serverIp ?? '192.168.1.100'; // Default fallback
  static set serverIp(String value) {
    _serverIp = value;
    // Dart setters cannot be async, so this is fire-and-forget
    _saveServerIp(value);
  }

  // API endpoints
  static String get baseUrl => 'http://$serverIp:$serverPort';
  static String get wsUrl => 'ws://$serverIp:$serverPort';

  // Timeouts and intervals
  static const Duration httpTimeout = Duration(seconds: 10);
  static const Duration reconnectInterval = Duration(seconds: 10);
  static const Duration pollInterval = Duration(seconds: 5);

  // Cache keys
  static const String cachedGunsKey = 'cached_guns';
  static const String cachedAlertsKey = 'cached_alerts';

  // Load saved server IP
  static Future<void> loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString(_serverIpKey);
  }

  // Save server IP
  static Future<void> _saveServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverIpKey, ip);
  }

  // Alert thresholds (should match server-side)
  static double highTemperatureThreshold = 45.0;
  static double lowFlowThreshold = 8.0;
  static double criticalTemperatureThreshold = 50.0;
  static double criticalFlowThreshold = 5.0;
}
