import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/gun_data.dart';
import 'api_service.dart';
import 'settings_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<List<AlertData>>? _alertSubscription;
  final Set<String> _notifiedAlerts = {}; // Track which alerts we've already notified about
  bool _isInitialized = false;
  
  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );
    
    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permissions for Android 13+ and iOS
    await _requestPermissions();
    
    _isInitialized = true;
    
    // Start listening to alerts
    _subscribeToAlerts();
  }
  
  // Request notification permissions
  Future<void> _requestPermissions() async {
    // Android 13+ permission request
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS/macOS permission request
    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
  
  // Subscribe to alert stream and trigger notifications
  void _subscribeToAlerts() {
    _alertSubscription?.cancel();
    
    _alertSubscription = ApiService.instance.alertStream.listen((alerts) {
      // Only send notifications if enabled in settings
      if (!SettingsService.instance.enableNotifications) {
        return;
      }
      
      // Process each alert
      for (var alert in alerts) {
        final alertKey = '${alert.gunIndex}_${alert.alertType}_${alert.severity}';
        
        // Only notify if this is a new alert we haven't notified about
        if (!_notifiedAlerts.contains(alertKey)) {
          _showAlertNotification(alert);
          _notifiedAlerts.add(alertKey);
          
          // Remove from tracking after 5 minutes to allow re-notification if issue persists
          Future.delayed(const Duration(minutes: 5), () {
            _notifiedAlerts.remove(alertKey);
          });
        }
      }
      
      // Clear notifications for resolved alerts
      if (alerts.isEmpty && _notifiedAlerts.isNotEmpty) {
        _notifiedAlerts.clear();
        _notificationsPlugin.cancelAll();
      }
    });
  }
  
  // Show notification for an alert
  Future<void> _showAlertNotification(AlertData alert) async {
    final String title = _getNotificationTitle(alert);
    final String body = _getNotificationBody(alert);
    
    // Notification details
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'flame_alerts', // Channel ID
      'Gun Alerts', // Channel name
      channelDescription: 'Notifications for gun equipment alerts',
      importance: alert.severity == 'CRITICAL' ? Importance.max : Importance.high,
      priority: alert.severity == 'CRITICAL' ? Priority.max : Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );
    
    // Show the notification
    await _notificationsPlugin.show(
      alert.gunIndex, // Use gun index as notification ID
      title,
      body,
      details,
    );
  }
  
  // Get notification title based on alert
  String _getNotificationTitle(AlertData alert) {
    if (alert.severity == 'CRITICAL') {
      return '🚨 CRITICAL ALERT - Gun ${alert.gunIndex}';
    } else {
      return '⚠️ Warning - Gun ${alert.gunIndex}';
    }
  }

  // Get notification body based on alert
  String _getNotificationBody(AlertData alert) {
    final List<String> issues = [];

    if (alert.alertType.contains('TEMPERATURE') || alert.alertType.contains('HIGH_TEMPERATURE')) {
      issues.add('High Temperature: ${alert.temperature.toStringAsFixed(1)}°C');
    }

    if (alert.alertType.contains('FLOW') || alert.alertType.contains('LOW_FLOW')) {
      issues.add('Low Flow Rate: ${alert.flowRate.toStringAsFixed(1)} L/min');
    }

    if (issues.isEmpty) {
      issues.add('Alert detected - Check gun status');
    }

    return issues.join(' | ');
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // When user taps notification, they'll be taken to the app
    // The app will show the Emergency Alerts page by default
    // No additional action needed here
  }

  // Dispose and cleanup
  void dispose() {
    _alertSubscription?.cancel();
    _notifiedAlerts.clear();
  }

  // Manually trigger a test notification
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'flame_alerts',
      'Gun Alerts',
      channelDescription: 'Notifications for gun equipment alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notificationsPlugin.show(
      999,
      '🔔 Test Notification',
      'FLAME notifications are working correctly!',
      details,
    );
  }
}

