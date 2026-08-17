import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'posthog_config.dart';

class PostHogAnalytics {
  PostHogAnalytics._();

  static final instance = PostHogAnalytics._();

  bool _isReady = false;
  String? _identifiedUserId;

  Future<void> setup() async {
    if (_isReady) {
      return;
    }

    if (!AppPostHogConfig.hasProjectToken) {
      debugPrint('PostHogAnalytics: POSTHOG_PROJECT_TOKEN is not configured.');
      return;
    }

    try {
      final config = PostHogConfig(AppPostHogConfig.projectToken)
        ..host = AppPostHogConfig.host
        ..debug = AppPostHogConfig.debug
        ..sessionReplay = false
        ..captureApplicationLifecycleEvents = true;

      await Posthog().setup(config).timeout(const Duration(seconds: 5));
      _isReady = true;
    } on TimeoutException {
      debugPrint('PostHogAnalytics: setup timed out. Analytics disabled.');
    } catch (error) {
      debugPrint('PostHogAnalytics: setup failed. $error');
    }
  }

  Future<void> capture(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!_isReady) {
      return;
    }

    try {
      await Posthog().capture(
        eventName: eventName,
        properties: _cleanProperties(properties),
      );
    } catch (error) {
      debugPrint('PostHogAnalytics: capture "$eventName" failed. $error');
    }
  }

  Future<void> screenOpened(
    String screenName, {
    Map<String, Object?> properties = const {},
  }) {
    return capture(
      'screen_opened',
      properties: {
        'screen_name': screenName,
        ...properties,
      },
    );
  }

  Future<void> buttonClicked({
    required String buttonName,
    required String screenName,
    Map<String, Object?> properties = const {},
  }) {
    return capture(
      'button_clicked',
      properties: {
        'button_name': buttonName,
        'screen_name': screenName,
        ...properties,
      },
    );
  }

  Future<void> screen(
    String screenName, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!_isReady) {
      return;
    }

    try {
      await Posthog().screen(
        screenName: screenName,
        properties: _cleanProperties(properties),
      );
    } catch (error) {
      debugPrint('PostHogAnalytics: screen "$screenName" failed. $error');
    }
  }

  Future<void> identifyUser(
    String userId, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!_isReady || userId.trim().isEmpty || _identifiedUserId == userId) {
      return;
    }

    try {
      await Posthog().identify(
        userId: userId,
        userProperties: _cleanProperties(properties),
      );
      _identifiedUserId = userId;
    } catch (error) {
      debugPrint('PostHogAnalytics: identify failed. $error');
    }
  }

  Future<void> resetUser() async {
    if (!_isReady || _identifiedUserId == null) {
      return;
    }

    try {
      await Posthog().reset();
      _identifiedUserId = null;
    } catch (error) {
      debugPrint('PostHogAnalytics: reset failed. $error');
    }
  }

  Map<String, Object> _cleanProperties(Map<String, Object?> properties) {
    final clean = <String, Object>{};
    for (final entry in properties.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      clean[entry.key] = value;
    }
    return clean;
  }
}
