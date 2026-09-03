import 'package:boopi_app/core/performance/story_performance_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records structured durations and Supabase request counts', () {
    final logs = <String>[];
    final metrics = StoryPerformanceMetrics(enabled: true, logSink: logs.add);

    metrics.beginStorySession('story-1');
    metrics.recordSupabaseRequest('story_pages.select');
    metrics.recordDuration(
      metric: 'story_load',
      duration: const Duration(milliseconds: 125),
    );

    expect(metrics.supabaseRequestCount, 1);
    expect(metrics.samples.last.metric, 'story_load');
    expect(metrics.samples.last.value, 125);
    expect(logs.last, contains('"metric":"story_load"'));
  });

  test('keeps only the configured number of recent samples', () {
    final metrics = StoryPerformanceMetrics(
      enabled: true,
      logSink: (_) {},
      maximumSamples: 2,
    );

    for (var index = 0; index < 3; index++) {
      metrics.record(metric: 'sample', value: index, unit: 'count');
    }

    expect(metrics.samples.map((sample) => sample.value), [1, 2]);
  });

  test('does not collect or log data when instrumentation is disabled', () {
    final logs = <String>[];
    final metrics = StoryPerformanceMetrics(enabled: false, logSink: logs.add);

    metrics.record(metric: 'sample', value: 1, unit: 'count');

    expect(metrics.samples, isEmpty);
    expect(logs, isEmpty);
  });
}
