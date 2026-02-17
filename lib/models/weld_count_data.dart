class WeldCountData {
  final String gunName;
  final int gunIndex;
  final int weldCount;
  final String lastUpdated;

  WeldCountData({
    required this.gunName,
    required this.gunIndex,
    required this.weldCount,
    required this.lastUpdated,
  });

  factory WeldCountData.fromJson(Map<String, dynamic> json) {
    return WeldCountData(
      gunName: json['gunName'] ?? json['gun_name'] ?? 'Gun ${json['gunIndex'] ?? json['gun_index'] ?? 0}',
      gunIndex: json['gunIndex'] ?? json['gun_index'] ?? 0,
      weldCount: json['weldCount'] ?? json['weld_count'] ?? 0,
      lastUpdated: json['lastUpdated'] ?? json['last_updated'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gunName': gunName,
      'gunIndex': gunIndex,
      'weldCount': weldCount,
      'lastUpdated': lastUpdated,
    };
  }

  WeldCountData copyWith({
    String? gunName,
    int? gunIndex,
    int? weldCount,
    String? lastUpdated,
  }) {
    return WeldCountData(
      gunName: gunName ?? this.gunName,
      gunIndex: gunIndex ?? this.gunIndex,
      weldCount: weldCount ?? this.weldCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'WeldCountData(gunName: $gunName, gunIndex: $gunIndex, weldCount: $weldCount, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeldCountData &&
        other.gunName == gunName &&
        other.gunIndex == gunIndex &&
        other.weldCount == weldCount &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return gunName.hashCode ^
        gunIndex.hashCode ^
        weldCount.hashCode ^
        lastUpdated.hashCode;
  }
}

