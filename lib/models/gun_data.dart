class GunData {
  final int gunIndex;
  final String gunName_;
  final String timestamp;
  final double flowRate;
  final double temperature;

  GunData({
    required this.gunIndex,
    required this.gunName_,
    required this.timestamp,
    required this.flowRate,
    required this.temperature,
  });

  factory GunData.fromJson(Map<String, dynamic> json) {
    return GunData(
      gunIndex: json['gunIndex'] as int,
      gunName_: json['gunName'] as String,
      timestamp: json['timestamp'] as String,
      flowRate: (json['flowRate'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gunIndex': gunIndex,
      'gunName_': gunName,
      'timestamp': timestamp,
      'flowRate': flowRate,
      'temperature': temperature,
    };
  }

  // Helper getters for display
  String get gunName => gunName_;
  String get flowDisplay => '${flowRate.toStringAsFixed(1)} L/min';
  String get tempDisplay => '${temperature.toStringAsFixed(1)} °C';

  // Health status based on thresholds from settings
  String healthStatusWithThresholds(double highTemp, double lowFlow, double criticalTemp, double criticalFlow) {
    if (temperature > criticalTemp || flowRate < criticalFlow) return 'Critical';
    if (temperature > highTemp || flowRate < lowFlow) return 'Marginal';
    return 'Good';
  }

  // Alert status - uses dynamic thresholds from settings
  bool isAlertWithThresholds(double highTemp, double lowFlow) {
    return temperature > highTemp || flowRate < lowFlow;
  }

  String alertTypeWithThresholds(double highTemp, double lowFlow) {
    if (temperature > highTemp) return 'HIGH_TEMPERATURE';
    if (flowRate < lowFlow) return 'LOW_FLOW';
    return 'NONE';
  }

  String severityWithThresholds(double criticalTemp, double criticalFlow,
      double highTemp, double lowFlow) {
    if (temperature > criticalTemp || flowRate < criticalFlow) {
      return 'CRITICAL';
    }
    if (temperature > highTemp || flowRate < lowFlow) return 'WARNING';
    return 'NORMAL';
  }

  // Legacy getters for backward compatibility
  bool get isAlert => temperature > 45.0 || flowRate < 8.0;
  String get alertType => temperature > 45.0
      ? 'HIGH_TEMPERATURE'
      : flowRate < 8.0
          ? 'LOW_FLOW'
          : 'NONE';
  String get severity => temperature > 50.0 || flowRate < 5.0
      ? 'CRITICAL'
      : temperature > 45.0 || flowRate < 8.0
          ? 'WARNING'
          : 'NORMAL';

  @override
  String toString() {
    return 'GunData(gunIndex: $gunIndex,gunName: $gunName, timestamp: $timestamp, flowRate: $flowRate, temperature: $temperature)';
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

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      timestamp: json['timestamp'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
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
    required super.gunName_,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      gunIndex: json['gunIndex'] as int,
      timestamp: json['timestamp'] as String,
      flowRate: (json['flowRate'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      alertType: json['alertType'] as String,
      severity: json['severity'] as String,
      gunName_: json['gunName'] as String,
    );
  }
}
