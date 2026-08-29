import 'dart:convert';

import 'package:flutter/material.dart';

import '../../shared/theme/app_typography.dart';
import 'design_token.dart';

const _allowedPresetModes = {'solid', 'gradient', 'none'};

abstract final class DesignTokenParser {
  static Color? parseColor(String value) {
    final normalized = value.trim().replaceFirst('#', '');
    final isValidHex = RegExp(
      r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
    ).hasMatch(normalized);
    if (!isValidHex) {
      return null;
    }

    final argbValue = normalized.length == 6 ? 'FF$normalized' : normalized;
    return Color(int.parse(argbValue, radix: 16));
  }

  static TextStyle? parseTypography(
    String value, {
    required TextStyle fallback,
  }) {
    final decoded = _decodeMap(value);
    if (decoded == null) {
      return null;
    }

    return fallback.copyWith(
      fontFamily: fallback.fontFamily ?? AppTypography.fontFamily,
      fontSize: _doubleValue(decoded['size']) ?? fallback.fontSize,
      height: _doubleValue(decoded['lineHeight']) ?? fallback.height,
      letterSpacing:
          _doubleValue(decoded['letterSpacing']) ?? fallback.letterSpacing,
      fontWeight: _fontWeightValue(decoded['weight']) ?? fallback.fontWeight,
    );
  }

  static DesignPreset? parsePreset(
    String value, {
    required DesignPreset fallback,
  }) {
    final decoded = _decodeMap(value);
    if (decoded == null) {
      return null;
    }

    final background = _colorValue(decoded['background']);
    final foreground = _colorValue(decoded['foreground']);
    if (background == null || foreground == null) {
      return null;
    }

    return DesignPreset(
      background: background,
      foreground: foreground,
      track: _colorValue(decoded['track']) ?? fallback.track,
      radius: _doubleValue(decoded['radius']) ?? fallback.radius,
      padding: _doubleValue(decoded['padding']) ?? fallback.padding,
      fillMode: _presetMode(decoded['fillMode']) ?? fallback.fillMode,
      trackMode: _presetMode(decoded['trackMode']) ?? fallback.trackMode,
      applicability:
          _stringListValue(decoded['applicability']) ?? fallback.applicability,
    );
  }

  static FontWeight? parseFontWeight(Object? value) {
    return _fontWeightValue(value);
  }

  static Map<String, dynamic>? _decodeMap(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, entry) => MapEntry(key.toString(), entry));
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static Color? _colorValue(Object? value) {
    final raw = value?.toString();
    if (raw == null) {
      return null;
    }
    return parseColor(raw);
  }

  static double? _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  static FontWeight? _fontWeightValue(Object? value) {
    return switch (int.tryParse(value?.toString() ?? '')) {
      100 => FontWeight.w100,
      200 => FontWeight.w200,
      300 => FontWeight.w300,
      400 => FontWeight.w400,
      500 => FontWeight.w500,
      600 => FontWeight.w600,
      700 => FontWeight.w700,
      800 => FontWeight.w800,
      900 => FontWeight.w900,
      _ => null,
    };
  }

  static String? _presetMode(Object? value) {
    final mode = value?.toString().trim();
    if (mode == null || !_allowedPresetModes.contains(mode)) {
      return null;
    }
    return mode;
  }

  static List<String>? _stringListValue(Object? value) {
    if (value is! List) {
      return null;
    }

    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }
}
