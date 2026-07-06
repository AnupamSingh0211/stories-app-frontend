import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

typedef StoryPerformanceLogSink = void Function(String message);

class StoryPerformanceSample {
  const StoryPerformanceSample({
    required this.metric,
    required this.value,
    required this.unit,
    required this.attributes,
  });

  final String metric;
  final num value;
  final String unit;
  final Map<String, Object?> attributes;
}

class StoryPerformanceMetrics {
  StoryPerformanceMetrics({
    bool? enabled,
    StoryPerformanceLogSink? logSink,
    this.maximumSamples = 200,
  }) : assert(maximumSamples > 0),
       enabled =
           enabled ??
           const bool.fromEnvironment(
             'STORY_PERFORMANCE_METRICS',
             defaultValue: false,
           ),
       _logSink = logSink ?? debugPrint;

  static final StoryPerformanceMetrics instance = StoryPerformanceMetrics();

  final bool enabled;
  final int maximumSamples;
  final StoryPerformanceLogSink _logSink;
  final Queue<StoryPerformanceSample> _samples = Queue();
  int _supabaseRequestCount = 0;

  List<StoryPerformanceSample> get samples =>
      List<StoryPerformanceSample>.unmodifiable(_samples);

  int get supabaseRequestCount => _supabaseRequestCount;

  void beginStorySession(String storyId) {
    if (!enabled) {
      return;
    }
    _supabaseRequestCount = 0;
    record(
      metric: 'story_session',
      value: 1,
      unit: 'count',
      attributes: {'story_id': storyId},
    );
  }

  void recordDuration({
    required String metric,
    required Duration duration,
    Map<String, Object?> attributes = const {},
  }) {
    record(
      metric: metric,
      value: duration.inMicroseconds / Duration.microsecondsPerMillisecond,
      unit: 'ms',
      attributes: attributes,
    );
  }

  void recordSupabaseRequest(String operation) {
    if (!enabled) {
      return;
    }
    _supabaseRequestCount++;
    record(
      metric: 'supabase_request_count',
      value: _supabaseRequestCount,
      unit: 'count',
      attributes: {'operation': operation},
    );
  }

  void recordImageCacheSnapshot({required String reason}) {
    if (!enabled) {
      return;
    }
    final cache = PaintingBinding.instance.imageCache;
    record(
      metric: 'image_cache_memory',
      value: cache.currentSizeBytes,
      unit: 'bytes',
      attributes: {
        'reason': reason,
        'live_images': cache.liveImageCount,
        'cached_images': cache.currentSize,
      },
    );
  }

  void record({
    required String metric,
    required num value,
    required String unit,
    Map<String, Object?> attributes = const {},
  }) {
    if (!enabled) {
      return;
    }

    final immutableAttributes = Map<String, Object?>.unmodifiable(attributes);
    final sample = StoryPerformanceSample(
      metric: metric,
      value: value,
      unit: unit,
      attributes: immutableAttributes,
    );
    _samples.addLast(sample);
    while (_samples.length > maximumSamples) {
      _samples.removeFirst();
    }

    _logSink(
      'STORY_PERF ${jsonEncode({...immutableAttributes, 'metric': metric, 'value': value, 'unit': unit})}',
    );
  }
}
