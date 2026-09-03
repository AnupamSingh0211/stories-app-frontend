import 'package:flutter_test/flutter_test.dart';

import 'package:boopi_app/core/notifications/notification_payload.dart';

void main() {
  test('empty data is invalid', () {
    expect(NotificationPayload.fromData(const {}), isNull);
  });

  test('parses home payload', () {
    final payload = NotificationPayload.fromData(const {
      'type': 'home',
      'deeplink': 'boopi://home',
      'source': 'firebase',
    });

    expect(payload?.type, NotificationPayloadType.home);
    expect(payload?.deeplink.toString(), 'boopi://home');
    expect(payload?.source, 'firebase');
  });

  test('parses story payload', () {
    final payload = NotificationPayload.fromData(const {
      'type': 'story',
      'deeplink': 'boopi://story/story-card-1',
      'story_card_id': 'story-card-1',
    });

    expect(payload?.type, NotificationPayloadType.story);
    expect(payload?.storyCardId, 'story-card-1');
  });

  test('parses legacy story payload using story_id as story card id', () {
    final payload = NotificationPayload.fromData(const {
      'type': 'story',
      'deeplink': 'boopi://story/story-card-1',
      'story_id': 'story-card-1',
    });

    expect(payload?.type, NotificationPayloadType.story);
    expect(payload?.storyId, 'story-card-1');
    expect(payload?.storyCardId, isNull);
  });

  test('parses episode payload', () {
    final payload = NotificationPayload.fromData(const {
      'type': 'episode',
      'deeplink': 'boopi://story/story-1/episode/episode-1',
      'story_id': 'story-1',
      'episode_id': 'episode-1',
      'campaign_id': 'campaign-1',
    });

    expect(payload?.type, NotificationPayloadType.episode);
    expect(payload?.storyId, 'story-1');
    expect(payload?.episodeId, 'episode-1');
    expect(payload?.campaignId, 'campaign-1');
  });

  test('parses membership payload', () {
    final payload = NotificationPayload.fromData(const {
      'type': 'membership',
      'deeplink': 'boopi://membership',
    });

    expect(payload?.type, NotificationPayloadType.membership);
  });

  test('parses profile payload', () {
    final payload = NotificationPayload.fromData(const {
      'type': 'profile',
      'deeplink': 'boopi://profile',
    });

    expect(payload?.type, NotificationPayloadType.profile);
  });

  test('unsupported type is invalid', () {
    final payload = NotificationPayload.fromData(const {
      'type': 'unknown',
      'deeplink': 'boopi://home',
    });

    expect(payload, isNull);
  });

  test('missing story id and story card id for story type is invalid', () {
    final payload = NotificationPayload.fromData(const {
      'type': 'story',
      'deeplink': 'boopi://story/story-1',
    });

    expect(payload, isNull);
  });

  test('missing episode_id for episode type is invalid', () {
    final payload = NotificationPayload.fromData(const {
      'type': 'episode',
      'deeplink': 'boopi://story/story-1/episode/episode-1',
      'story_id': 'story-1',
    });

    expect(payload, isNull);
  });
}
