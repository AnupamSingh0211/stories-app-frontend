import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'notification_analytics.dart';
import 'notification_deeplink_router.dart';
import 'notification_payload.dart';
import 'notification_token_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  debugPrint('FCM background message received: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const _androidChannel = AndroidNotificationChannel(
    'boopi_default_notifications',
    'Boopi notifications',
    description: 'General Boopi app notifications',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _handlersInitialized = false;
  bool _localNotificationsInitialized = false;
  String? _registeredUserId;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initializeMessageHandlers() async {
    if (!_isAndroid || _handlersInitialized) {
      return;
    }

    _handlersInitialized = true;
    await _initializeLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_handleNotificationOpened(message, source: 'background'));
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(
        _handleNotificationOpened(initialMessage, source: 'terminated'),
      );
    }
  }

  Future<void> registerDeviceForUser(
    String userId, {
    required NotificationTokenRepository tokenRepository,
  }) async {
    if (!_isAndroid || userId.trim().isEmpty) {
      return;
    }

    final alreadyRegisteredForUser = _registeredUserId == userId;
    _registeredUserId = userId;
    if (!alreadyRegisteredForUser) {
      await _requestPermission();
    }

    await _syncCurrentToken(
      userId,
      eventName: 'push_token_registered',
      tokenRepository: tokenRepository,
    );

    if (alreadyRegisteredForUser && _tokenRefreshSubscription != null) {
      return;
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(
        _handleTokenRefresh(
          userId: userId,
          token: token,
          tokenRepository: tokenRepository,
        ),
      );
    });
  }

  Future<void> resetUser() async {
    _registeredUserId = null;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _requestPermission() async {
    await _trackNotificationEvent('notification_permission_requested');

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final status = settings.authorizationStatus.name;
    debugPrint('FCM notification permission status: $status');

    await _trackNotificationEvent(
      settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional
          ? 'notification_permission_granted'
          : 'notification_permission_denied',
      properties: {'authorization_status': status},
    );
  }

  Future<void> _syncCurrentToken(
    String userId, {
    required String eventName,
    required NotificationTokenRepository tokenRepository,
  }) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('FCM token is not available yet.');
      return;
    }

    debugPrint('FCM token for user $userId: $token');
    final backendSynced = await syncAndroidNotificationToken(
      repository: tokenRepository,
      token: token,
    );

    await _trackNotificationEvent(
      eventName,
      properties: {
        'platform': 'android',
        'user_id': userId,
        'backend_synced': backendSynced,
      },
    );
  }

  Future<void> _handleTokenRefresh({
    required String userId,
    required String token,
    required NotificationTokenRepository tokenRepository,
  }) async {
    debugPrint('FCM token refreshed for user $userId: $token');
    final backendSynced = await syncAndroidNotificationToken(
      repository: tokenRepository,
      token: token,
    );

    await _trackNotificationEvent(
      'push_token_refreshed',
      properties: {
        'platform': 'android',
        'user_id': userId,
        'backend_synced': backendSynced,
      },
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final payload = NotificationPayload.fromData(message.data);
    debugPrint('FCM foreground message received: ${message.messageId}');
    debugPrint(
      'FCM foreground payload: type=${payload?.typeName}, deeplink=${payload?.deeplink}',
    );
    await _trackNotificationEvent(
      'notification_received_foreground',
      properties: _messageProperties(message, payload),
    );

    final notification = message.notification;
    final android = notification?.android;
    if (notification == null || android == null) {
      return;
    }

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: android.smallIcon,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _handleNotificationOpened(
    RemoteMessage message, {
    required String source,
  }) async {
    final payload = NotificationPayload.fromData(message.data);
    debugPrint(
      'FCM notification opened from $source: '
      'type=${payload?.typeName}, deeplink=${payload?.deeplink}, '
      'data=${message.data}',
    );
    await _trackNotificationEvent(
      'notification_opened',
      properties: {..._messageProperties(message, payload), 'source': source},
    );

    final result = await NotificationDeepLinkRouter.instance.open(
      payload,
      source: source,
    );
    debugPrint(
      'Notification deeplink result from $source: '
      '${result.status.name}${result.reason == null ? '' : ' (${result.reason})'}',
    );
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (response) {
        unawaited(_handleLocalNotificationTap(response.payload));
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    _localNotificationsInitialized = true;
  }

  Future<void> _handleLocalNotificationTap(String? rawPayload) async {
    debugPrint('Local notification tapped: $rawPayload');

    final data = _decodeLocalNotificationPayload(rawPayload);
    final payload = NotificationPayload.fromData(data);
    await _trackNotificationEvent(
      'notification_opened',
      properties: {
        'source': 'foreground',
        'payload_valid': payload != null,
        'deeplink_present': payload != null,
        if (payload == null && data['deeplink'] != null)
          'raw_deeplink_present': true,
        if (payload != null) ...payload.toAnalyticsProperties(),
      },
    );

    final result = await NotificationDeepLinkRouter.instance.open(
      payload,
      source: 'foreground',
    );
    debugPrint(
      'Notification deeplink result from foreground: '
      '${result.status.name}${result.reason == null ? '' : ' (${result.reason})'}',
    );
  }

  Map<String, dynamic> _decodeLocalNotificationPayload(String? rawPayload) {
    if (rawPayload == null || rawPayload.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (error) {
      debugPrint('Local notification payload decode failed. $error');
    }

    return const {};
  }

  Map<String, Object?> _messageProperties(
    RemoteMessage message,
    NotificationPayload? payload,
  ) {
    return {
      'message_id': message.messageId,
      'message_type': message.messageType,
      'collapse_key': message.collapseKey,
      'sent_time': message.sentTime?.toIso8601String(),
      'data_type': message.data['type'],
      'payload_valid': payload != null,
      'deeplink_present': payload != null,
      if (payload == null)
        'raw_deeplink_present': message.data['deeplink'] != null,
      if (payload != null) ...payload.toAnalyticsProperties(),
    };
  }

  Future<void> _trackNotificationEvent(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    await NotificationAnalytics.instance.capture(
      eventName,
      properties: properties,
    );
  }
}
