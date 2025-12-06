import 'package:flutter/services.dart';

class ScreenTimeService {
  static const MethodChannel _channel = MethodChannel(
    'com.focusmate.screentime',
  );

  // Request Screen Time authorization
  static Future<Map<String, dynamic>> requestAuthorization() async {
    try {
      final result = await _channel.invokeMethod('requestAuthorization') as Map;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'error': 'Platform error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Unknown error: $e'};
    }
  }

  // Check authorization status
  static Future<Map<String, dynamic>> checkAuthorizationStatus() async {
    try {
      final result =
          await _channel.invokeMethod('checkAuthorizationStatus') as Map;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'authorized': false, 'status': 'error', 'error': e.message};
    } catch (e) {
      return {'authorized': false, 'status': 'error', 'error': '$e'};
    }
  }

  // Get screen time data
  static Future<Map<String, dynamic>> getScreenTimeData() async {
    try {
      final result = await _channel.invokeMethod('getScreenTimeData') as Map;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': 'Platform error: ${e.message}',
        'apps': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unknown error: $e',
        'apps': <Map<String, dynamic>>[],
      };
    }
  }

  // Start monitoring
  static Future<Map<String, dynamic>> startMonitoring() async {
    try {
      final result = await _channel.invokeMethod('startMonitoring') as Map;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }

  // Format seconds to readable time
  static String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  // Get total usage time from app list
  static int getTotalUsageTime(List<dynamic> apps) {
    int total = 0;
    for (var app in apps) {
      if (app is Map && app.containsKey('usageTime')) {
        total += (app['usageTime'] as int?) ?? 0;
      }
    }
    return total;
  }

  // Sort apps by usage time
  static List<Map<String, dynamic>> sortAppsByUsage(List<dynamic> apps) {
    final List<Map<String, dynamic>> sortedApps = apps
        .map((app) => Map<String, dynamic>.from(app as Map))
        .toList();

    sortedApps.sort((a, b) {
      final aTime = (a['usageTime'] as int?) ?? 0;
      final bTime = (b['usageTime'] as int?) ?? 0;
      return bTime.compareTo(aTime);
    });

    return sortedApps;
  }
}
