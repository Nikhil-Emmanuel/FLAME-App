import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/gun_data.dart';
import '../config/api_config.dart';
import 'settings_service.dart';
import 'min_max_service.dart';

class ApiService {
  
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  
  ApiService._();
  
  WebSocketChannel? _channel;
  StreamController<List<GunData>>? _dataStreamController;
  StreamController<List<AlertData>>? _alertStreamController;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  bool _isConnected = false;
  
  // Cached data for offline mode
  List<GunData> _cachedGunData = [];
  List<AlertData> _cachedAlerts = [];
  
  // Getters for streams
  Stream<List<GunData>> get gunDataStream => _dataStreamController?.stream ?? const Stream.empty();
  Stream<List<AlertData>> get alertStream => _alertStreamController?.stream ?? const Stream.empty();
  
  bool get isConnected => _isConnected;
  List<GunData> get cachedGunData => _cachedGunData;
  List<AlertData> get cachedAlerts => _cachedAlerts;

  // Initialize the service
  Future<void> initialize() async {
    // Initialize settings service first
    await SettingsService.instance.initialize();

    // Initialize min/max service
    await MinMaxService.instance.initialize();

    _dataStreamController = StreamController<List<GunData>>.broadcast();
    _alertStreamController = StreamController<List<AlertData>>.broadcast();

    // Load cached data
    await _loadCachedData();

    // Check if we need to reset min/max for a new day
    await MinMaxService.instance.checkAndResetIfNewDay();

    // Start with HTTP polling, then try WebSocket
    await _startPolling();
    if (SettingsService.instance.enableWebSocket) {
      _connectWebSocket();
    }
  }

  // HTTP Headers with API key
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': SettingsService.instance.apiKey,
  };

  // Check network connectivity
  Future<bool> _hasNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // HTTP API calls with error handling
  Future<ApiResponse<List<GunData>>> getAllGuns() async {
    try {
      if (!await _hasNetworkConnection()) {
        return ApiResponse<List<GunData>>(
          success: false,
          timestamp: DateTime.now().toIso8601String(),
          error: 'No network connection',
          data: _cachedGunData,
        );
      }

      final response = await http.get(
        Uri.parse('${SettingsService.instance.baseUrl}/api/guns'),
        headers: _headers,
      ).timeout(SettingsService.instance.httpTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> gunList = jsonData['data'] as List<dynamic>;
        final guns = gunList.map((gun) => GunData.fromJson(gun)).toList();
        
        // Cache the data
        _cachedGunData = guns;
        await _saveCachedData();

        // Update min/max tracking
        await MinMaxService.instance.updateWithGunData(guns);

        _isConnected = true;
        return ApiResponse<List<GunData>>(
          success: true,
          timestamp: jsonData['timestamp'],
          data: guns,
          totalGuns: jsonData['totalGuns'],
        );
      } else {
        _isConnected = false;
        return ApiResponse<List<GunData>>(
          success: false,
          timestamp: DateTime.now().toIso8601String(),
          error: 'Server error: ${response.statusCode}',
          data: _cachedGunData,
        );
      }
    } catch (e) {
      _isConnected = false;
      return ApiResponse<List<GunData>>(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        error: 'Network error: $e',
        data: _cachedGunData,
      );
    }
  }

  Future<ApiResponse<List<AlertData>>> getAlerts() async {
    try {
      if (!await _hasNetworkConnection()) {
        return ApiResponse<List<AlertData>>(
          success: false,
          timestamp: DateTime.now().toIso8601String(),
          error: 'No network connection',
          data: _cachedAlerts,
        );
      }

      final response = await http.get(
        Uri.parse('${SettingsService.instance.baseUrl}/api/alerts'),
        headers: _headers,
      ).timeout(SettingsService.instance.httpTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> alertList = jsonData['alerts'] as List<dynamic>;
        final alerts = alertList.map((alert) => AlertData.fromJson(alert)).toList();
        
        // Cache the alerts
        _cachedAlerts = alerts;
        await _saveCachedData();
        
        return ApiResponse<List<AlertData>>(
          success: true,
          timestamp: jsonData['timestamp'],
          data: alerts,
          alertCount: jsonData['alertCount'],
        );
      } else {
        return ApiResponse<List<AlertData>>(
          success: false,
          timestamp: DateTime.now().toIso8601String(),
          error: 'Server error: ${response.statusCode}',
          data: _cachedAlerts,
        );
      }
    } catch (e) {
      return ApiResponse<List<AlertData>>(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        error: 'Network error: $e',
        data: _cachedAlerts,
      );
    }
  }

  Future<ApiResponse<GunData>> getGunById(int gunIndex) async {
    try {
      if (!await _hasNetworkConnection()) {
        final cachedGun = _cachedGunData.firstWhere(
          (gun) => gun.gunIndex == gunIndex,
          orElse: () => throw Exception('Gun not found in cache'),
        );
        return ApiResponse<GunData>(
          success: false,
          timestamp: DateTime.now().toIso8601String(),
          error: 'No network connection',
          data: cachedGun,
        );
      }

      final response = await http.get(
        Uri.parse('${SettingsService.instance.baseUrl}/api/guns/$gunIndex'),
        headers: _headers,
      ).timeout(SettingsService.instance.httpTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final gun = GunData.fromJson(jsonData['data']);
        
        return ApiResponse<GunData>(
          success: true,
          timestamp: jsonData['timestamp'],
          data: gun,
        );
      } else {
        return ApiResponse<GunData>(
          success: false,
          timestamp: DateTime.now().toIso8601String(),
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<GunData>(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        error: 'Network error: $e',
      );
    }
  }

  // WebSocket connection for real-time updates
  void _connectWebSocket() async {
    try {
      if (!await _hasNetworkConnection()) return;
      
      _channel = WebSocketChannel.connect(Uri.parse(SettingsService.instance.wsUrl));
      
      _channel!.stream.listen(
        (data) async {
          try {
            final jsonData = json.decode(data);
            if (jsonData['type'] == 'sensor_update' || jsonData['type'] == 'initial_data') {
              final List<dynamic> gunList = jsonData['data'] as List<dynamic>;
              final guns = gunList.map((gun) => GunData.fromJson(gun)).toList();

              _cachedGunData = guns;
              _dataStreamController?.add(guns);

              // Update min/max tracking
              await MinMaxService.instance.updateWithGunData(guns);

              // Extract alerts from gun data
              final alerts = guns.where((gun) => gun.isAlert).map((gun) =>
                AlertData(
                  gunIndex: gun.gunIndex,
                  timestamp: gun.timestamp,
                  flowRate: gun.flowRate,
                  temperature: gun.temperature,
                  alertType: gun.alertType,
                  severity: gun.severity,
                )
              ).toList();

              _cachedAlerts = alerts;
              _alertStreamController?.add(alerts);

              _saveCachedData();
            }
          } catch (e) {
            print('Error parsing WebSocket data: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _scheduleReconnect();
        },
      );
      
      print('WebSocket connected successfully');
    } catch (e) {
      print('WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(SettingsService.instance.reconnectInterval, () {
      if (SettingsService.instance.enableWebSocket) {
        _connectWebSocket();
      }
    });
  }

  // HTTP polling as fallback
  Future<void> _startPolling() async {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(SettingsService.instance.pollInterval, (timer) async {
      if (!SettingsService.instance.enableWebSocket || _channel == null || _channel!.closeCode != null) {
        // WebSocket not connected or disabled, use HTTP polling
        final gunsResponse = await getAllGuns();
        if (gunsResponse.success && gunsResponse.data != null) {
          _dataStreamController?.add(gunsResponse.data!);
          // Min/max tracking is already handled in getAllGuns method
        }

        final alertsResponse = await getAlerts();
        if (alertsResponse.success && alertsResponse.data != null) {
          _alertStreamController?.add(alertsResponse.data!);
        }
      }
    });
  }

  // Cache management
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedGunsJson = prefs.getString(ApiConfig.cachedGunsKey);
      final cachedAlertsJson = prefs.getString(ApiConfig.cachedAlertsKey);
      
      if (cachedGunsJson != null) {
        final List<dynamic> gunList = json.decode(cachedGunsJson);
        _cachedGunData = gunList.map((gun) => GunData.fromJson(gun)).toList();
      }
      
      if (cachedAlertsJson != null) {
        final List<dynamic> alertList = json.decode(cachedAlertsJson);
        _cachedAlerts = alertList.map((alert) => AlertData.fromJson(alert)).toList();
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConfig.cachedGunsKey, json.encode(_cachedGunData.map((gun) => gun.toJson()).toList()));
      await prefs.setString(ApiConfig.cachedAlertsKey, json.encode(_cachedAlerts.map((alert) => alert.toJson()).toList()));
    } catch (e) {
      print('Error saving cached data: $e');
    }
  }

  // Cleanup
  void dispose() {
    _channel?.sink.close();
    _dataStreamController?.close();
    _alertStreamController?.close();
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
  }
}
