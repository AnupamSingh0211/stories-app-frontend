enum NotificationPayloadType { home, story, episode, membership, profile }

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.deeplink,
    this.storyId,
    this.storyCardId,
    this.episodeId,
    this.campaignId,
    this.source,
  });

  final NotificationPayloadType type;
  final Uri deeplink;
  final String? storyId;
  final String? storyCardId;
  final String? episodeId;
  final String? campaignId;
  final String? source;

  String get typeName => type.name;

  static NotificationPayload? fromData(Map<String, dynamic> data) {
    final type = _parseType(_stringValue(data['type']));
    final deeplink = _parseDeeplink(_stringValue(data['deeplink']));
    if (type == null || deeplink == null) {
      return null;
    }

    final storyId = _stringValue(data['story_id']);
    final storyCardId =
        _stringValue(data['story_card_id']) ??
        _stringValue(data['storyCardId']);
    final episodeId = _stringValue(data['episode_id']);

    switch (type) {
      case NotificationPayloadType.story:
        if (storyId == null && storyCardId == null) return null;
      case NotificationPayloadType.episode:
        if (storyId == null || episodeId == null) return null;
      case NotificationPayloadType.home:
      case NotificationPayloadType.membership:
      case NotificationPayloadType.profile:
        break;
    }

    return NotificationPayload(
      type: type,
      deeplink: deeplink,
      storyId: storyId,
      storyCardId: storyCardId,
      episodeId: episodeId,
      campaignId: _stringValue(data['campaign_id']),
      source: _stringValue(data['source']),
    );
  }

  Map<String, Object?> toAnalyticsProperties() {
    return {
      'payload_type': typeName,
      'deeplink': deeplink.toString(),
      'deeplink_present': true,
      'story_id_present': storyId != null,
      'story_card_id_present': storyCardId != null,
      'episode_id_present': episodeId != null,
      'campaign_id': campaignId,
      'payload_source': source,
    };
  }

  static NotificationPayloadType? _parseType(String? value) {
    switch (value) {
      case 'home':
        return NotificationPayloadType.home;
      case 'story':
        return NotificationPayloadType.story;
      case 'episode':
        return NotificationPayloadType.episode;
      case 'membership':
        return NotificationPayloadType.membership;
      case 'profile':
        return NotificationPayloadType.profile;
      default:
        return null;
    }
  }

  static Uri? _parseDeeplink(String? value) {
    if (value == null) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'boopi' || uri.host.isEmpty) {
      return null;
    }

    return uri;
  }

  static String? _stringValue(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
