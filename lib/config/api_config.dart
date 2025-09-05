class ApiConfig {
  // Server configuration
  static const String serverIp = '192.168.1.100'; // Change this to your server IP
  static const int serverPort = 7575;
  static const String apiKey = 'FlameApp123\$byNevark';
  
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
  
  // Alert thresholds (should match server-side)
  static const double highTemperatureThreshold = 45.0;
  static const double lowFlowThreshold = 8.0;
  static const double criticalTemperatureThreshold = 50.0;
  static const double criticalFlowThreshold = 5.0;
}
