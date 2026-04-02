import 'dart:async';
import 'dart:math';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/gun_data.dart';

enum TimeRange {
  oneHour('1H', Duration(hours: 1)),
  sixHours('6H', Duration(hours: 6)),
  twelveHours('12H', Duration(hours: 12)),
  twentyFourHours('24H', Duration(hours: 24)),
  sevenDays('7D', Duration(days: 7)),
  thirtyDays('30D', Duration(days: 30));

  final String label;
  final Duration duration;
  const TimeRange(this.label, this.duration);
}

// Helper class to store data points with timestamp
class StoredDataPoint {
  final double timestamp;
  final double flowRate;
  final double temperature;

  StoredDataPoint({
    required this.timestamp,
    required this.flowRate,
    required this.temperature,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'flowRate': flowRate,
        'temperature': temperature,
      };

  factory StoredDataPoint.fromJson(Map<String, dynamic> json) =>
      StoredDataPoint(
        timestamp: (json['timestamp'] as num).toDouble(),
        flowRate: json['flowRate'] as double,
        temperature: json['temperature'] as double,
      );
}

class PerformanceTrendsPage extends StatefulWidget {
  const PerformanceTrendsPage({super.key});

  @override
  State<PerformanceTrendsPage> createState() => _PerformanceTrendsPageState();
}

class _PerformanceTrendsPageState extends State<PerformanceTrendsPage> {
  // PERFORMANCE OPTIMIZATIONS:
  // 1. Batched UI updates (500ms intervals) - prevents "Skipped frames" errors
  // 2. Batched storage saves (5s intervals) - avoids blocking main thread
  // 3. downsampling - handles 10k+ points smoothly
  // 4. RepaintBoundary - isolates chart repaints
  // 5. Zero-duration animations - faster rendering
  // 6. Timestamp sorting - prevents backward lines and circle knots
  // 7. Gap detection - breaks lines at data gaps, prevents misleading connections

  //final Random _random = Random();
  final Map<String, List<FlSpot>> _gunFlowHistory = {};
  final Map<String, List<FlSpot>> _gunTempHistory = {};
  final Map<String, Color> _gunColors = {};

  // Full datasets cached in memory
  final Map<String, List<FlSpot>> _fullFlowData = {};
  final Map<String, List<FlSpot>> _fullTempData = {};

  // Pending data to be saved (batch operations)
  final Map<String, List<StoredDataPoint>> _pendingSaveData = {};

  StreamSubscription<List<GunData>>? _dataSubscription;
  String? _expandedGun;
  bool _isLoading = true;
  TimeRange _selectedTimeRange = TimeRange.twentyFourHours;
  Timer? _refreshTimer;
  Timer? _uiUpdateTimer;
  bool _needsUIUpdate = false;
  bool _retriedHistoryLoadFromLive = false;

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await _loadHistoricalDataFromServer();
    _startBatchedUIUpdates();
    _subscribeToRealTimeData();
    _startPeriodicRefresh();
  }

  void _startBatchedUIUpdates() {
    // Update UI every 500ms instead of on every data point
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_needsUIUpdate && mounted) {
        setState(() {
          _downsampleData();
          _needsUIUpdate = false;
        });
      }
    });
  }

  void _startPeriodicRefresh() {
    // Periodically refresh the display (re-filter data for selected time range)
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _loadHistoricalDataFromServer();
      }
    });
  }

  bool _hasAnyHistoryData() {
    return _fullFlowData.values.any((spots) => spots.isNotEmpty) ||
        _fullTempData.values.any((spots) => spots.isNotEmpty);
  }

  Future<void> _loadHistoricalDataFromServer() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final gunsResponse = await ApiService.instance.getAllGuns();
      final guns = gunsResponse.data ?? ApiService.instance.cachedGunData;

      if (guns.isEmpty) {
        debugPrint('History load skipped: no guns available yet');
        return;
      }

      final nextFlowData = <String, List<FlSpot>>{};
      final nextTempData = <String, List<FlSpot>>{};

      for (var gun in guns) {
        final gunName = gun.gunName;

        try {
          final flowFuture = ApiService.instance.getFlowHistory(
            gunName,
            _selectedTimeRange.label,
          );

          final tempFuture = ApiService.instance.getTempHistory(
            gunName,
            _selectedTimeRange.label,
          );

          final results = await Future.wait([flowFuture, tempFuture]);

          nextFlowData[gunName] = _sortAndDeduplicateSpots(results[0]);
          nextTempData[gunName] = _sortAndDeduplicateSpots(results[1]);
        } catch (e) {
          debugPrint('History load failed for $gunName: $e');

          if (_fullFlowData.containsKey(gunName)) {
            nextFlowData[gunName] = List<FlSpot>.from(_fullFlowData[gunName]!);
          }
          if (_fullTempData.containsKey(gunName)) {
            nextTempData[gunName] = List<FlSpot>.from(_fullTempData[gunName]!);
          }
        }

        if (!_gunColors.containsKey(gunName)) {
          _gunColors[gunName] = _generateDistinctColor();
        }
      }

      if (nextFlowData.isNotEmpty || nextTempData.isNotEmpty) {
        _fullFlowData
          ..clear()
          ..addAll(nextFlowData);
        _fullTempData
          ..clear()
          ..addAll(nextTempData);
        _downsampleData();
      }
    } catch (e) {
      debugPrint("History API error: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// CRITICAL FIX: Sort spots by X (timestamp) and remove duplicates
  /// This prevents backward lines and circle knots in charts
  List<FlSpot> _sortAndDeduplicateSpots(List<FlSpot> spots) {
    if (spots.isEmpty) return spots;

    // Sort by X coordinate (timestamp) - ascending order
    spots.sort((a, b) => a.x.compareTo(b.x));

    // Remove duplicates - keep latest value for same timestamp
    final uniqueSpots = <double, FlSpot>{};
    for (var spot in spots) {
      uniqueSpots[spot.x] = spot; // Latest value wins if duplicate timestamp
    }

    // Convert back to list and sort again to ensure order
    final result = uniqueSpots.values.toList();
    result.sort((a, b) => a.x.compareTo(b.x));

    return result;
  }

  /// Detects gaps in data and inserts null spots to break lines
  /// Prevents straight lines across missing data periods
  List<FlSpot> _insertGapBreaks(List<FlSpot> spots) {
    if (spots.length < 2) return spots;

    final expectedInterval = _getExpectedDataInterval();
    final gapThreshold = expectedInterval * 3;

    final List<FlSpot> result = [];

    for (int i = 0; i < spots.length; i++) {
      result.add(spots[i]);

      if (i < spots.length - 1) {
        final timeDiff = spots[i + 1].x - spots[i].x;

        if (timeDiff > gapThreshold) {
          result.add(FlSpot.nullSpot); // correct gap break
        }
      }
    }

    return result;
  }

  /// Gets expected data interval in milliseconds based on selected time range
  double _getExpectedDataInterval() {
    switch (_selectedTimeRange) {
      case TimeRange.oneHour:
        return 10000; // 10 seconds
      case TimeRange.sixHours:
        return 30000; // 30 seconds
      case TimeRange.twelveHours:
      case TimeRange.twentyFourHours:
        return 60000; // 1 minute
      case TimeRange.sevenDays:
        return 300000; // 5 minutes
      case TimeRange.thirtyDays:
        return 900000; // 15 minutes
    }
  }

  void _queueDataPointForSave(
      String gunName, double timestamp, double flowRate, double temperature) {
    // Queue data point for batched save instead of saving immediately
    if (!_pendingSaveData.containsKey(gunName)) {
      _pendingSaveData[gunName] = [];
    }

    _pendingSaveData[gunName]!.add(StoredDataPoint(
      timestamp: timestamp,
      flowRate: flowRate,
      temperature: temperature,
    ));
  }

  void _downsampleData() {
    // Downsample data for efficient rendering
    // Keep maximum 500 points for display to ensure smooth rendering
    const maxDisplayPoints = 500;

    _gunFlowHistory.clear();
    _gunTempHistory.clear();

    for (var gunName in _fullFlowData.keys) {
      // Sort and deduplicate before downsampling
      final sortedFlowData = _sortAndDeduplicateSpots(_fullFlowData[gunName]!);
      final sortedTempData = _sortAndDeduplicateSpots(_fullTempData[gunName]!);

      _gunFlowHistory[gunName] =
          _downsampleSpots(sortedFlowData, maxDisplayPoints);
      _gunTempHistory[gunName] =
          _downsampleSpots(sortedTempData, maxDisplayPoints);
    }
  }

  List<FlSpot> _downsampleSpots(List<FlSpot> spots, int maxPoints) {
    if (spots.length <= maxPoints) {
      return spots;
    }

    // (Largest Triangle Three Buckets) algorithm for downsampling
    // Input must be sorted by X - which is guaranteed by _sortAndDeduplicateSpots
    final sampledSpots = <FlSpot>[];
    final bucketSize = (spots.length - 2) / (maxPoints - 2);

    // Always keep first point
    sampledSpots.add(spots.first);

    int a = 0;
    for (int i = 0; i < maxPoints - 2; i++) {
      final avgRangeStart = ((i + 1) * bucketSize).floor() + 1;
      final avgRangeEnd = ((i + 2) * bucketSize).floor() + 1;
      final endIndex = avgRangeEnd < spots.length ? avgRangeEnd : spots.length;

      double avgX = 0;
      double avgY = 0;
      int avgRangeLength = 0;

      for (int j = avgRangeStart; j < endIndex; j++) {
        avgX += spots[j].x;
        avgY += spots[j].y;
        avgRangeLength++;
      }

      if (avgRangeLength > 0) {
        avgX /= avgRangeLength;
        avgY /= avgRangeLength;
      }

      final rangeOffs = (i * bucketSize).floor() + 1;
      final rangeTo = ((i + 1) * bucketSize).floor() + 1;

      final pointAX = spots[a].x;
      final pointAY = spots[a].y;

      double maxArea = -1;
      int maxAreaPoint = rangeOffs;

      for (int j = rangeOffs; j < rangeTo && j < spots.length; j++) {
        final area = ((pointAX - avgX) * (spots[j].y - pointAY) -
                    (pointAX - spots[j].x) * (avgY - pointAY))
                .abs() *
            0.5;

        if (area > maxArea) {
          maxArea = area;
          maxAreaPoint = j;
        }
      }

      if (maxAreaPoint < spots.length) {
        sampledSpots.add(spots[maxAreaPoint]);
        a = maxAreaPoint;
      }
    }

    // Always keep last point
    sampledSpots.add(spots.last);

    return sampledSpots;
  }

  void _subscribeToRealTimeData() {
    // Subscribe to real-time updates and queue for batched processing
    _dataSubscription = ApiService.instance.gunDataStream.listen(
      (data) {
        if (!mounted) return;

        final hadHistoryBeforeUpdate = _hasAnyHistoryData();

        final now = DateTime.now();
        final timeValue = now.millisecondsSinceEpoch.toDouble();
        final rangeStartTime = now.subtract(_selectedTimeRange.duration);
        final oldestAllowedTime =
            rangeStartTime.millisecondsSinceEpoch.toDouble();

        // Process data WITHOUT calling setState (batched update will handle it)
        for (var gun in data) {
          if (!_fullFlowData.containsKey(gun.gunName)) {
            _fullFlowData[gun.gunName] = [];
            _fullTempData[gun.gunName] = [];
            _gunColors[gun.gunName] = _generateDistinctColor();
          }

          // Validate data
          final flowValue = gun.flowRate;
          final tempValue = gun.temperature;

          if (flowValue >= 0 &&
              flowValue <= 100 &&
              tempValue >= 0 &&
              tempValue <= 100) {
            // Add new data points to memory
            _fullFlowData[gun.gunName]!.add(FlSpot(timeValue, flowValue));
            _fullTempData[gun.gunName]!.add(FlSpot(timeValue, tempValue));

            // CRITICAL FIX: Sort and deduplicate after adding new point
            // This ensures chronological order and prevents backward lines
            _fullFlowData[gun.gunName] =
                _sortAndDeduplicateSpots(_fullFlowData[gun.gunName]!);
            _fullTempData[gun.gunName] =
                _sortAndDeduplicateSpots(_fullTempData[gun.gunName]!);

            // Queue for batched save (non-blocking)
            _queueDataPointForSave(
                gun.gunName, timeValue, flowValue, tempValue);

            // Remove old data points outside time range from memory
            _fullFlowData[gun.gunName]!
                .removeWhere((spot) => spot.x < oldestAllowedTime);
            _fullTempData[gun.gunName]!
                .removeWhere((spot) => spot.x < oldestAllowedTime);
          }
        }

        // Mark that UI needs update (will be processed by timer)
        _needsUIUpdate = true;

        if (!hadHistoryBeforeUpdate &&
            data.isNotEmpty &&
            !_retriedHistoryLoadFromLive) {
          _retriedHistoryLoadFromLive = true;
          unawaited(_loadHistoricalDataFromServer());
        }
      },
      onError: (error) {
        debugPrint("Performance trends stream error: $error");
      },
    );
  }

  Color _generateDistinctColor() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
      Colors.red,
    ];
    return colors[_gunColors.length % colors.length];
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _refreshTimer?.cancel();
    _uiUpdateTimer?.cancel();

    // Flush any pending data before disposing

    super.dispose();
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TimeRange.values.map((range) {
            final isSelected = range == _selectedTimeRange;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  range.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blue.shade300,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTimeRange = range;
                    });
                    _loadHistoricalDataFromServer();
                  }
                },
                backgroundColor: Colors.blue.shade800,
                selectedColor: Colors.blue.shade600,
                elevation: isSelected ? 4 : 0,
                pressElevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDualChart(String gun, {bool expanded = false}) {
    final flowSpots = _gunFlowHistory[gun] ?? [];
    final tempSpots = _gunTempHistory[gun] ?? [];
    final color = _gunColors[gun] ?? Colors.blue;

    if (flowSpots.isEmpty && tempSpots.isEmpty) {
      return _buildEmptyState(gun, expanded);
    }

    return GestureDetector(
      onTap: expanded
          ? null
          : () {
              setState(() {
                _expandedGun = gun;
              });
            },
      child: RepaintBoundary(
        child: Card(
          elevation: expanded ? 8 : 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(expanded ? 20 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        gun,
                        style: TextStyle(
                          fontSize: expanded ? 20 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    if (flowSpots.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${flowSpots.length} pts',
                          style: TextStyle(
                            fontSize: expanded ? 12 : 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Flow Rate Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Flow Rate (L/min)',
                            style: TextStyle(
                              fontSize: expanded ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                          if (flowSpots.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Current: ${flowSpots.last.y.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: expanded ? 12 : 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                          child: _buildFlowChart(flowSpots, color, expanded)),
                    ],
                  ),
                ),
                SizedBox(height: expanded ? 16 : 8),
                // Temperature Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Temperature (°C)',
                            style: TextStyle(
                              fontSize: expanded ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                          if (tempSpots.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Current: ${tempSpots.last.y.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: expanded ? 12 : 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                          child: _buildTempChart(tempSpots, color, expanded)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(double timestamp, TimeRange range) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());

    switch (range) {
      case TimeRange.oneHour:
      case TimeRange.sixHours:
      case TimeRange.twelveHours:
      case TimeRange.twentyFourHours:
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      case TimeRange.sevenDays:
      case TimeRange.thirtyDays:
        return '${dateTime.day}/${dateTime.month}';
    }
  }

  Widget _buildFlowChart(List<FlSpot> spots, Color color, bool expanded) {
    if (spots.isEmpty) return const SizedBox();

    // Insert gap breaks to prevent straight lines across missing data
    final spotsWithGaps = _insertGapBreaks(spots);

    spots.sort((a, b) => a.x.compareTo(b.x));

    double minX = spots.first.x;
    double maxX = spots.last.x;

    // Prevent identical X values (single datapoint case)
    if (minX == maxX) {
      maxX = minX + 1;
    }

    final double minY = spots.map((s) => s.y).reduce(min) - 5;
    final double maxY = spots.map((s) => s.y).reduce(max) + 5;
    final double actualMinY = max(0, minY);
    final double actualMaxY = max(actualMinY + 10, maxY);

    // Prevent interval = 0
    final double xInterval = max((maxX - minX) / 5, 1);

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: actualMinY,
        maxY: actualMaxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final timeStr = _formatTimestamp(spot.x, _selectedTimeRange);
                return LineTooltipItem(
                  '$timeStr\n${spot.y.toStringAsFixed(1)} L/min',
                  TextStyle(
                    color: Colors.blue[700]!,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (actualMaxY - actualMinY) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: expanded ? 40 : 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: expanded ? 12 : 10,
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: expanded,
              reservedSize: 40,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                // Skip labels too close to edges to prevent overlap
                final range = maxX - minX;
                final distanceFromStart = value - minX;
                final distanceFromEnd = maxX - value;

                if (distanceFromStart < range * 0.05 ||
                    distanceFromEnd < range * 0.05) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatTimestamp(value, _selectedTimeRange),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spotsWithGaps,
            isCurved: true,
            curveSmoothness: 0.15,
            color: Colors.blue[600],
            barWidth: expanded ? 1.5 : 1,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue[600]!.withValues(alpha: 0.3),
                  Colors.blue[600]!.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }

  Widget _buildTempChart(List<FlSpot> spots, Color color, bool expanded) {
    if (spots.isEmpty) return const SizedBox();

    // Insert gap breaks to prevent straight lines across missing data
    final spotsWithGaps = _insertGapBreaks(spots);

    spots.sort((a, b) => a.x.compareTo(b.x));

    double minX = spots.first.x;
    double maxX = spots.last.x;

    // Prevent identical X values (happens when only 1 datapoint)
    if (minX == maxX) {
      maxX = minX + 1;
    }

    final double minY = spots.map((s) => s.y).reduce(min) - 5;
    final double maxY = spots.map((s) => s.y).reduce(max) + 5;
    final double actualMinY = max(0, minY);
    final double actualMaxY = max(actualMinY + 10, maxY);

    // Prevent interval = 0
    final double xInterval = max((maxX - minX) / 5, 1);

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: actualMinY,
        maxY: actualMaxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final timeStr = _formatTimestamp(spot.x, _selectedTimeRange);
                return LineTooltipItem(
                  '$timeStr\n${spot.y.toStringAsFixed(1)}°C',
                  TextStyle(
                    color: Colors.red[700]!,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (actualMaxY - actualMinY) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: expanded ? 40 : 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: expanded ? 12 : 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: expanded,
              reservedSize: 40,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final range = maxX - minX;
                final distanceFromStart = value - minX;
                final distanceFromEnd = maxX - value;

                if (distanceFromStart < range * 0.05 ||
                    distanceFromEnd < range * 0.05) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatTimestamp(value, _selectedTimeRange),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spotsWithGaps,
            isCurved: true,
            curveSmoothness: 0.15,
            color: Colors.red[600],
            barWidth: expanded ? 1.5 : 1,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.red[600]!.withValues(alpha: 0.3),
                  Colors.red[600]!.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }

  Widget _buildEmptyState(String gun, bool expanded) {
    return Card(
      elevation: expanded ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(expanded ? 20 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              gun,
              style: TextStyle(
                fontSize: expanded ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: expanded ? 48 : 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No performance data",
                      style: TextStyle(
                        fontSize: expanded ? 16 : 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedChart(String gun) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () {
                      setState(() {
                        _expandedGun = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Performance Trends - $gun',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildTimeRangeSelector(),
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 900,
                    maxHeight: 700,
                  ),
                  margin: const EdgeInsets.all(16),
                  child: _buildDualChart(gun, expanded: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadHistoricalDataFromServer();
  }

  @override
  Widget build(BuildContext context) {
    if (_expandedGun != null) {
      return _buildExpandedChart(_expandedGun!);
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        title: const Text(
          "Performance Trends",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimeRangeSelector(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _gunFlowHistory.isEmpty && _gunTempHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No performance data available",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Data will appear as it becomes available",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount;
                          double childAspectRatio;

                          if (constraints.maxWidth > 1200) {
                            crossAxisCount = 3;
                            childAspectRatio = 0.9;
                          } else if (constraints.maxWidth > 800) {
                            crossAxisCount = 2;
                            childAspectRatio = 0.85;
                          } else {
                            crossAxisCount = 1;
                            childAspectRatio = 0.8;
                          }

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: childAspectRatio,
                            padding: const EdgeInsets.all(8),
                            children: _gunFlowHistory.keys
                                .map((gun) => _buildDualChart(gun))
                                .toList(),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
