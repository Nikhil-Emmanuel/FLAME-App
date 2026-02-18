import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  
  SettingsService._();
  
  SharedPreferences? _prefs;
  
  // Settings keys
  static const String _serverIpKey = 'server_ip';
  static const String _serverPortKey = 'server_port';
  static const String _apiKeyKey = 'api_key';
  static const String _httpTimeoutKey = 'http_timeout';
  static const String _reconnectIntervalKey = 'reconnect_interval';
  static const String _pollIntervalKey = 'poll_interval';
  static const String _highTempThresholdKey = 'high_temp_threshold';
  static const String _lowFlowThresholdKey = 'low_flow_threshold';
  static const String _criticalTempThresholdKey = 'critical_temp_threshold';
  static const String _criticalFlowThresholdKey = 'critical_flow_threshold';
  static const String _enableNotificationsKey = 'enable_notifications';
  static const String _enableWebSocketKey = 'enable_websocket';
  static const String _enableOfflineModeKey = 'enable_offline_mode';
  
  // Default values (matching current api_config.dart)
  static const String _defaultServerIp = '192.168.1.100';
  static const int _defaultServerPort = 7575;
  static const String _defaultApiKey = 'FlameApp123\$byNevark';
  static const int _defaultHttpTimeout = 10; // seconds
  static const int _defaultReconnectInterval = 10; // seconds
  static const int _defaultPollInterval = 5; // seconds
  static const double _defaultHighTempThreshold = 45.0;
  static const double _defaultLowFlowThreshold = 8.0;
  static const double _defaultCriticalTempThreshold = 50.0;
  static const double _defaultCriticalFlowThreshold = 5.0;
  static const bool _defaultEnableNotifications = false;
  static const bool _defaultEnableWebSocket = true;
  static const bool _defaultEnableOfflineMode = true;
  
  // Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Server Configuration
  String get serverIp => _prefs?.getString(_serverIpKey) ?? _defaultServerIp;
  int get serverPort => _prefs?.getInt(_serverPortKey) ?? _defaultServerPort;
  String get apiKey => _prefs?.getString(_apiKeyKey) ?? _defaultApiKey;
  
  // Computed URLs
  String get baseUrl => 'http://$serverIp:$serverPort';
  String get wsUrl => 'ws://$serverIp:$serverPort';
  
  // Timeout and Interval Settings
  Duration get httpTimeout => Duration(seconds: _prefs?.getInt(_httpTimeoutKey) ?? _defaultHttpTimeout);
  Duration get reconnectInterval => Duration(seconds: _prefs?.getInt(_reconnectIntervalKey) ?? _defaultReconnectInterval);
  Duration get pollInterval => Duration(seconds: _prefs?.getInt(_pollIntervalKey) ?? _defaultPollInterval);
  
  // Alert Thresholds
  double get highTemperatureThreshold => _prefs?.getDouble(_highTempThresholdKey) ?? _defaultHighTempThreshold;
  double get lowFlowThreshold => _prefs?.getDouble(_lowFlowThresholdKey) ?? _defaultLowFlowThreshold;
  double get criticalTemperatureThreshold => _prefs?.getDouble(_criticalTempThresholdKey) ?? _defaultCriticalTempThreshold;
  double get criticalFlowThreshold => _prefs?.getDouble(_criticalFlowThresholdKey) ?? _defaultCriticalFlowThreshold;
  
  // Feature Toggles
  bool get enableNotifications => _prefs?.getBool(_enableNotificationsKey) ?? _defaultEnableNotifications;
  bool get enableWebSocket => _prefs?.getBool(_enableWebSocketKey) ?? _defaultEnableWebSocket;
  bool get enableOfflineMode => _prefs?.getBool(_enableOfflineModeKey) ?? _defaultEnableOfflineMode;
  
  // Setters for updating settings
  Future<void> setServerIp(String ip) async {
    await _prefs?.setString(_serverIpKey, ip);
  }
  
  Future<void> setServerPort(int port) async {
    await _prefs?.setInt(_serverPortKey, port);
  }
  
  Future<void> setApiKey(String key) async {
    await _prefs?.setString(_apiKeyKey, key);
  }
  
  Future<void> setHttpTimeout(int seconds) async {
    await _prefs?.setInt(_httpTimeoutKey, seconds);
  }
  
  Future<void> setReconnectInterval(int seconds) async {
    await _prefs?.setInt(_reconnectIntervalKey, seconds);
  }
  
  Future<void> setPollInterval(int seconds) async {
    await _prefs?.setInt(_pollIntervalKey, seconds);
  }
  
  Future<void> setHighTemperatureThreshold(double threshold) async {
    await _prefs?.setDouble(_highTempThresholdKey, threshold);
  }
  
  Future<void> setLowFlowThreshold(double threshold) async {
    await _prefs?.setDouble(_lowFlowThresholdKey, threshold);
  }
  
  Future<void> setCriticalTemperatureThreshold(double threshold) async {
    await _prefs?.setDouble(_criticalTempThresholdKey, threshold);
  }
  
  Future<void> setCriticalFlowThreshold(double threshold) async {
    await _prefs?.setDouble(_criticalFlowThresholdKey, threshold);
  }
  
  Future<void> setEnableNotifications(bool enabled) async {
    await _prefs?.setBool(_enableNotificationsKey, enabled);
  }
  
  Future<void> setEnableWebSocket(bool enabled) async {
    await _prefs?.setBool(_enableWebSocketKey, enabled);
  }
  
  Future<void> setEnableOfflineMode(bool enabled) async {
    await _prefs?.setBool(_enableOfflineModeKey, enabled);
  }
  
  // Bulk update settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      switch (entry.key) {
        case 'serverIp':
          await setServerIp(entry.value);
          break;
        case 'serverPort':
          await setServerPort(entry.value);
          break;
        case 'apiKey':
          await setApiKey(entry.value);
          break;
        case 'httpTimeout':
          await setHttpTimeout(entry.value);
          break;
        case 'reconnectInterval':
          await setReconnectInterval(entry.value);
          break;
        case 'pollInterval':
          await setPollInterval(entry.value);
          break;
        case 'highTemperatureThreshold':
          await setHighTemperatureThreshold(entry.value);
          break;
        case 'lowFlowThreshold':
          await setLowFlowThreshold(entry.value);
          break;
        case 'criticalTemperatureThreshold':
          await setCriticalTemperatureThreshold(entry.value);
          break;
        case 'criticalFlowThreshold':
          await setCriticalFlowThreshold(entry.value);
          break;
        case 'enableNotifications':
          await setEnableNotifications(entry.value);
          break;
        case 'enableWebSocket':
          await setEnableWebSocket(entry.value);
          break;
        case 'enableOfflineMode':
          await setEnableOfflineMode(entry.value);
          break;
      }
    }
  }
  
  // Reset to defaults
  Future<void> resetToDefaults() async {
    await _prefs?.clear();
  }
  
  // Export settings as JSON
  Map<String, dynamic> exportSettings() {
    return {
      'serverIp': serverIp,
      'serverPort': serverPort,
      'apiKey': apiKey,
      'httpTimeout': httpTimeout.inSeconds,
      'reconnectInterval': reconnectInterval.inSeconds,
      'pollInterval': pollInterval.inSeconds,
      'highTemperatureThreshold': highTemperatureThreshold,
      'lowFlowThreshold': lowFlowThreshold,
      'criticalTemperatureThreshold': criticalTemperatureThreshold,
      'criticalFlowThreshold': criticalFlowThreshold,
      'enableNotifications': enableNotifications,
      'enableWebSocket': enableWebSocket,
      'enableOfflineMode': enableOfflineMode,
    };
  }
  
  // Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> settings) async {
    await updateSettings(settings);
  }
  
  // Validate IP address format
  static bool isValidIpAddress(String ip) {
    final RegExp ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    return ipRegex.hasMatch(ip);
  }
  
  // Validate port number
  static bool isValidPort(int port) {
    return port >= 1 && port <= 65535;
  }
  
  // Validate threshold values
  static bool isValidThreshold(double value) {
    return value >= 0 && value <= 1000; // Reasonable range for temperature/flow
  }
  
  // Validate timeout/interval values
  static bool isValidInterval(int seconds) {
    return seconds >= 1 && seconds <= 300; // 1 second to 5 minutes
  }
}
