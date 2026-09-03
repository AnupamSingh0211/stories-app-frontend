import 'package:flutter_test/flutter_test.dart';

import 'package:boopi_app/core/notifications/notification_analytics.dart';
import 'package:boopi_app/core/notifications/notification_payload.dart';

void main() {
  test('firebase parameters keep only supported safe values', () {
    final parameters = NotificationAnalytics.firebaseSafeParameters({
      'platform': 'android',
      'backend_synced': true,
      'attempt_count': 2,
      'opened_at': DateTime.utc(2026, 9, 2, 10, 30),
      'deeplink_uri': Uri.parse('boopi://membership'),
      'payload_type': NotificationPayloadType.membership,
      'unsupported_list': const ['ignored'],
      'unsupported_map': const {'ignored': true},
      'empty_value': null,
    });

    expect(parameters, {
      'platform': 'android',
      'backend_synced': 'true',
      'attempt_count': 2,
      'opened_at': '2026-09-02T10:30:00.000Z',
      'deeplink_uri': 'boopi://membership',
      'payload_type': 'membership',
    });
  });

  test('analytics properties redact raw push tokens', () {
    final source = {
      'token': 'raw-token',
      'fcm_token': 'raw-fcm-token',
      'apnsToken': 'raw-apns-token',
      'registration_token_value': 'raw-registration-token',
      'message_id': 'message-1',
    };

    expect(NotificationAnalytics.postHogSafeProperties(source), {
      'message_id': 'message-1',
    });
    expect(NotificationAnalytics.firebaseSafeParameters(source), {
      'message_id': 'message-1',
    });
  });
}
