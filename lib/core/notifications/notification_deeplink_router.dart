import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/membership/membership_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/storytime/models/story_model.dart';
import '../../features/storytime/repositories/story_repository.dart';
import '../../features/storytime/screens/episodes_screen.dart';
import '../../features/storytime/screens/story_player_screen.dart';
import 'notification_analytics.dart';
import 'notification_payload.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

enum NotificationDeepLinkStatus { opened, pending, failed }

class NotificationDeepLinkResult {
  const NotificationDeepLinkResult(this.status, {this.reason});

  final NotificationDeepLinkStatus status;
  final String? reason;
}

class NotificationDeepLinkRouter {
  NotificationDeepLinkRouter._();

  static final instance = NotificationDeepLinkRouter._();

  NotificationPayload? _pendingPayload;
  String _pendingSource = 'unknown';
  bool _isFlushingPending = false;
  StoryRepository? _storyRepository;

  void setStoryRepository(StoryRepository repository) {
    _storyRepository = repository;
  }

  Future<NotificationDeepLinkResult> open(
    NotificationPayload? payload, {
    required String source,
  }) async {
    if (payload == null) {
      return _fail(null, source: source, reason: 'invalid_payload');
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      _pendingPayload = payload;
      _pendingSource = source;
      debugPrint(
        'Notification deeplink pending until navigator is ready: '
        '${payload.deeplink}',
      );
      return const NotificationDeepLinkResult(
        NotificationDeepLinkStatus.pending,
        reason: 'navigator_not_ready',
      );
    }

    return _navigate(navigator, payload, source: source);
  }

  Future<NotificationDeepLinkResult?> flushPending() async {
    if (_isFlushingPending || _pendingPayload == null) {
      return null;
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return null;
    }

    _isFlushingPending = true;
    final payload = _pendingPayload;
    final source = _pendingSource;
    _pendingPayload = null;
    _pendingSource = 'unknown';

    try {
      return await _navigate(navigator, payload!, source: source);
    } finally {
      _isFlushingPending = false;
    }
  }

  Future<NotificationDeepLinkResult> _navigate(
    NavigatorState navigator,
    NotificationPayload payload, {
    required String source,
  }) async {
    try {
      switch (payload.type) {
        case NotificationPayloadType.home:
          navigator.popUntil((route) => route.isFirst);
        case NotificationPayloadType.story:
          final storyCard = await _resolveStoryCard(payload);
          if (storyCard == null) {
            return _fail(
              payload,
              source: source,
              reason: 'story_card_not_found',
            );
          }
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => EpisodesScreen(storyCard: storyCard),
            ),
          );
        case NotificationPayloadType.episode:
          final storyId = payload.storyId;
          if (storyId == null) {
            return _fail(payload, source: source, reason: 'missing_story_id');
          }
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  StoryPlayerScreen(storyId: storyId, openDirectly: true),
            ),
          );
        case NotificationPayloadType.membership:
          navigator.push(
            MaterialPageRoute<void>(builder: (_) => const MembershipScreen()),
          );
        case NotificationPayloadType.profile:
          navigator.push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          );
      }

      debugPrint('Notification deeplink opened: ${payload.deeplink}');
      await _track(
        'notification_deeplink_opened',
        properties: {...payload.toAnalyticsProperties(), 'source': source},
      );
      return const NotificationDeepLinkResult(
        NotificationDeepLinkStatus.opened,
      );
    } catch (error) {
      return _fail(payload, source: source, reason: error.toString());
    }
  }

  Future<NotificationDeepLinkResult> _fail(
    NotificationPayload? payload, {
    required String source,
    required String reason,
  }) async {
    debugPrint('Notification deeplink failed: $reason');
    await _track(
      'notification_deeplink_failed',
      properties: {
        'failure_reason': reason,
        'source': source,
        if (payload != null) ...payload.toAnalyticsProperties(),
      },
    );
    return NotificationDeepLinkResult(
      NotificationDeepLinkStatus.failed,
      reason: reason,
    );
  }

  Future<StoryCardModel?> _resolveStoryCard(NotificationPayload payload) async {
    final storyCardId = payload.storyCardId ?? payload.storyId;
    if (storyCardId == null || storyCardId.trim().isEmpty) {
      return null;
    }

    final repository = _storyRepository;
    if (repository == null) {
      debugPrint('Notification deeplink story repository is not ready.');
      return null;
    }

    try {
      final cards = await repository.fetchStoryCards();
      for (final card in cards) {
        if (card.id == storyCardId) {
          return card;
        }
      }
    } catch (error) {
      debugPrint('Notification deeplink story card lookup failed. $error');
    }

    return null;
  }

  Future<void> _track(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    await NotificationAnalytics.instance.capture(
      eventName,
      properties: properties,
    );
  }
}
