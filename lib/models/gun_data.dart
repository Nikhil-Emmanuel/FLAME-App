class GunData {
  final int gunIndex;
  final String timestamp;
  final double flowRate;
  final double temperature;

  GunData({
    required this.gunIndex,
    required this.timestamp,
    required this.flowRate,
    required this.temperature,
  });

  factory GunData.fromJson(Map<String, dynamic> json) {
    return GunData(
      gunIndex: json['gunIndex'] as int,
      timestamp: json['timestamp'] as String,
      flowRate: (json['flowRate'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gunIndex': gunIndex,
      'timestamp': timestamp,
      'flowRate': flowRate,
      'temperature': temperature,
    };
  }

  // Helper getters for display
  String get gunName => 'G$gunIndex';
  String get flowDisplay => '${flowRate.toStringAsFixed(1)} L/min';
  String get tempDisplay => '${temperature.toStringAsFixed(1)} °C';
  
  // Health status based on thresholds
  String get healthStatus {
    if (flowRate >= 10 && temperature <= 45) return 'Good';
    if (flowRate < 10 && temperature <= 45) return 'Maintenance Needed';
    return 'Immediate Action';
  }
  
  // Alert status
  bool get isAlert {
    return temperature > 45.0 || flowRate < 8.0;
  }
  
  String get alertType {
    if (temperature > 45.0) return 'HIGH_TEMPERATURE';
    if (flowRate < 8.0) return 'LOW_FLOW';
    return 'NONE';
  }
  
  String get severity {
    if (temperature > 50.0 || flowRate < 5.0) return 'CRITICAL';
    if (temperature > 45.0 || flowRate < 8.0) return 'WARNING';
    return 'NORMAL';
  }

  @override
  String toString() {
    return 'GunData(gunIndex: $gunIndex, timestamp: $timestamp, flowRate: $flowRate, temperature: $temperature)';
  }
}

class ApiResponse<T> {
  final bool success;
  final String timestamp;
  final T? data;
  final String? error;
  final int? totalGuns;
  final int? alertCount;

  ApiResponse({
    required this.success,
    required this.timestamp,
    this.data,
    this.error,
    this.totalGuns,
    this.alertCount,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      timestamp: json['timestamp'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
      error: json['error'] as String?,
      totalGuns: json['totalGuns'] as int?,
      alertCount: json['alertCount'] as int?,
    );
  }
}

class AlertData extends GunData {
  @override
  final String alertType;
  @override
  final String severity;

  AlertData({
    required super.gunIndex,
    required super.timestamp,
    required super.flowRate,
    required super.temperature,
    required this.alertType,
    required this.severity,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      gunIndex: json['gunIndex'] as int,
      timestamp: json['timestamp'] as String,
      flowRate: (json['flowRate'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      alertType: json['alertType'] as String,
      severity: json['severity'] as String,
    );
  }
}
