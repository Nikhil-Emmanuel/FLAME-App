import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gun_data.dart';

class MinMaxData {
  final String gunName;
  final double minFlow;
  final double maxFlow;
  final double minTemp;
  final double maxTemp;
  final DateTime date;
  final DateTime lastUpdated;

  MinMaxData({
    required this.gunName,
    required this.minFlow,
    required this.maxFlow,
    required this.minTemp,
    required this.maxTemp,
    required this.date,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'gunName': gunName,
      'minFlow': minFlow,
      'maxFlow': maxFlow,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'date': date.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory MinMaxData.fromJson(Map<String, dynamic> json) {
    return MinMaxData(
      gunName: json['gunName'],
      minFlow: json['minFlow'].toDouble(),
      maxFlow: json['maxFlow'].toDouble(),
      minTemp: json['minTemp'].toDouble(),
      maxTemp: json['maxTemp'].toDouble(),
      date: DateTime.parse(json['date']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  MinMaxData copyWith({
    String? gunName,
    double? minFlow,
    double? maxFlow,
    double? minTemp,
    double? maxTemp,
    DateTime? date,
    DateTime? lastUpdated,
  }) {
    return MinMaxData(
      gunName: gunName ?? this.gunName,
      minFlow: minFlow ?? this.minFlow,
      maxFlow: maxFlow ?? this.maxFlow,
      minTemp: minTemp ?? this.minTemp,
      maxTemp: maxTemp ?? this.maxTemp,
      date: date ?? this.date,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class MinMaxService {
  static MinMaxService? _instance;
  static MinMaxService get instance => _instance ??= MinMaxService._();
  
  MinMaxService._();
  
  SharedPreferences? _prefs;
  Map<String, MinMaxData> _todayMinMax = {};
  
  static const String _minMaxKey = 'daily_min_max_data';
  
  // Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTodayData();
  }
  
  // Load today's min/max data from storage
  Future<void> _loadTodayData() async {
    try {
      final String? storedData = _prefs?.getString(_minMaxKey);
      if (storedData != null) {
        final Map<String, dynamic> jsonData = json.decode(storedData);
        final Map<String, MinMaxData> loadedData = {};
        
        for (final entry in jsonData.entries) {
          final minMaxData = MinMaxData.fromJson(entry.value);
          
          // Only keep today's data
          if (_isSameDay(minMaxData.date, DateTime.now())) {
            loadedData[entry.key] = minMaxData;
          }
        }
        
        _todayMinMax = loadedData;
      }
    } catch (e) {
      // If there's an error loading data, start fresh
      _todayMinMax = {};
    }
  }
  
  // Save current min/max data to storage
  Future<void> _saveData() async {
    try {
      final Map<String, dynamic> jsonData = {};
      for (final entry in _todayMinMax.entries) {
        jsonData[entry.key] = entry.value.toJson();
      }
      await _prefs?.setString(_minMaxKey, json.encode(jsonData));
    } catch (e) {
      // Handle save error silently
    }
  }
  
  // Update min/max values with new gun data
  Future<void> updateWithGunData(List<GunData> gunDataList) async {
    final now = DateTime.now();
    bool hasUpdates = false;
    
    for (final gunData in gunDataList) {
      final existing = _todayMinMax[gunData.gunName];
      
      if (existing == null) {
        // First data point for this gun today
        _todayMinMax[gunData.gunName] = MinMaxData(
          gunName: gunData.gunName,
          minFlow: gunData.flowRate,
          maxFlow: gunData.flowRate,
          minTemp: gunData.temperature,
          maxTemp: gunData.temperature,
          date: now,
          lastUpdated: now,
        );
        hasUpdates = true;
      } else {
        // Update existing min/max values
        final updated = existing.copyWith(
          minFlow: gunData.flowRate < existing.minFlow ? gunData.flowRate : existing.minFlow,
          maxFlow: gunData.flowRate > existing.maxFlow ? gunData.flowRate : existing.maxFlow,
          minTemp: gunData.temperature < existing.minTemp ? gunData.temperature : existing.minTemp,
          maxTemp: gunData.temperature > existing.maxTemp ? gunData.temperature : existing.maxTemp,
          lastUpdated: now,
        );
        
        // Only update if values actually changed
        if (updated.minFlow != existing.minFlow ||
            updated.maxFlow != existing.maxFlow ||
            updated.minTemp != existing.minTemp ||
            updated.maxTemp != existing.maxTemp) {
          _todayMinMax[gunData.gunName] = updated;
          hasUpdates = true;
        }
      }
    }
    
    if (hasUpdates) {
      await _saveData();
    }
  }
  
  // Get today's min/max data for all guns
  Map<String, MinMaxData> getTodayMinMax() {
    return Map.from(_todayMinMax);
  }
  
  // Get today's min/max data for a specific gun
  MinMaxData? getTodayMinMaxForGun(String gunName) {
    return _todayMinMax[gunName];
  }
  
  // Check if we have data for today
  bool hasDataForToday() {
    return _todayMinMax.isNotEmpty;
  }
  
  // Get the number of guns with data today
  int getGunsWithDataCount() {
    return _todayMinMax.length;
  }
  
  // Clear all data (useful for testing or manual reset)
  Future<void> clearAllData() async {
    _todayMinMax.clear();
    await _prefs?.remove(_minMaxKey);
  }
  
  // Reset data for a new day (called automatically when date changes)
  Future<void> resetForNewDay() async {
    _todayMinMax.clear();
    await _saveData();
  }
  
  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  // Get formatted date string for today
  String getTodayDateString() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
  
  // Check if we need to reset for a new day
  bool shouldResetForNewDay() {
    if (_todayMinMax.isEmpty) return false;
    
    final now = DateTime.now();
    final firstEntry = _todayMinMax.values.first;
    return !_isSameDay(firstEntry.date, now);
  }
  
  // Auto-reset if it's a new day
  Future<void> checkAndResetIfNewDay() async {
    if (shouldResetForNewDay()) {
      await resetForNewDay();
    }
  }
}
