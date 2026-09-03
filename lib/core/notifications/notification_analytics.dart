import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../analytics_service.dart';

const _sensitiveAnalyticsKeys = {
  'token',
  'fcm_token',
  'fcmToken',
  'apns_token',
  'apnsToken',
  'registration_token',
  'registrationToken',
};

class NotificationAnalytics {
  NotificationAnalytics._();

  static final instance = NotificationAnalytics._();

  Future<void> capture(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    final postHogProperties = postHogSafeProperties(properties);
    await PostHogAnalytics.instance.capture(
      eventName,
      properties: postHogProperties,
    );

    try {
      await FirebaseAnalytics.instance.logEvent(
        name: eventName,
        parameters: firebaseSafeParameters(properties),
      );
    } catch (error) {
      debugPrint('FirebaseAnalytics event "$eventName" failed. $error');
    }
  }

  static Map<String, Object> postHogSafeProperties(
    Map<String, Object?> properties,
  ) {
    final clean = <String, Object>{};
    for (final entry in properties.entries) {
      if (_isSensitiveKey(entry.key)) {
        continue;
      }

      final value = entry.value;
      if (value != null) {
        clean[entry.key] = value;
      }
    }
    return clean;
  }

  static Map<String, Object> firebaseSafeParameters(
    Map<String, Object?> properties,
  ) {
    final clean = <String, Object>{};
    for (final entry in properties.entries) {
      if (_isSensitiveKey(entry.key)) {
        continue;
      }

      final value = entry.value;
      if (value is String) {
        clean[entry.key] = value;
      } else if (value is num) {
        clean[entry.key] = value;
      } else if (value is bool) {
        clean[entry.key] = value ? 'true' : 'false';
      } else if (value is DateTime) {
        clean[entry.key] = value.toIso8601String();
      } else if (value is Uri) {
        clean[entry.key] = value.toString();
      } else if (value is Enum) {
        clean[entry.key] = value.name;
      }
    }
    return clean;
  }

  static bool _isSensitiveKey(String key) {
    if (_sensitiveAnalyticsKeys.contains(key)) {
      return true;
    }

    final normalized = key.toLowerCase();
    return normalized.contains('fcm_token') ||
        normalized.contains('apns_token') ||
        normalized.contains('registration_token');
  }
}
