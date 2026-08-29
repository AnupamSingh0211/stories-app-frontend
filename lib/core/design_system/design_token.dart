import 'package:flutter/material.dart';

enum DesignTokenType {
  color('color'),
  typography('typography'),
  preset('preset');

  const DesignTokenType(this.value);

  final String value;

  static DesignTokenType? fromValue(String? value) {
    final normalized = value?.trim();
    for (final type in DesignTokenType.values) {
      if (type.value == normalized) {
        return type;
      }
    }
    return null;
  }
}

enum DesignTokenTheme {
  light('light'),
  dark('dark');

  const DesignTokenTheme(this.value);

  final String value;

  static DesignTokenTheme fromValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final theme in DesignTokenTheme.values) {
      if (theme.value == normalized) {
        return theme;
      }
    }
    return DesignTokenTheme.light;
  }
}

class DesignToken {
  const DesignToken({
    required this.tokenKey,
    required this.tokenValue,
    required this.tokenType,
    this.theme = DesignTokenTheme.light,
    required this.groupName,
    this.description,
    required this.sortOrder,
    required this.isActive,
  });

  factory DesignToken.fromJson(Map<String, dynamic> json) {
    return DesignToken(
      tokenKey: json['token_key']?.toString() ?? '',
      tokenValue: json['token_value']?.toString() ?? '',
      tokenType: DesignTokenType.fromValue(json['token_type']?.toString()),
      theme: DesignTokenTheme.fromValue(json['theme']?.toString()),
      groupName: json['group_name']?.toString() ?? 'general',
      description: json['description']?.toString(),
      sortOrder: _intFromJson(json['sort_order']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String tokenKey;
  final String tokenValue;
  final DesignTokenType? tokenType;
  final DesignTokenTheme theme;
  final String groupName;
  final String? description;
  final int sortOrder;
  final bool isActive;

  static int _intFromJson(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DesignPreset {
  const DesignPreset({
    required this.background,
    required this.foreground,
    this.track,
    required this.radius,
    required this.padding,
    required this.fillMode,
    required this.trackMode,
    required this.applicability,
  });

  final Color background;
  final Color foreground;
  final Color? track;
  final double radius;
  final double padding;
  final String fillMode;
  final String trackMode;
  final List<String> applicability;
}
