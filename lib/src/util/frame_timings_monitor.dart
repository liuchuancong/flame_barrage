import 'dart:async';

import 'package:flutter/scheduler.dart';

/// One window of aggregated frame timings.
class FrameTimingsStats {
  /// Creates a stats window.
  const FrameTimingsStats({
    required this.samples,
    required this.budgetMs,
    required this.buildMs,
    required this.rasterMs,
    required this.vsyncMs,
    required this.totalMs,
    required this.jankFrames,
  });

  /// Frames aggregated into this window.
  final int samples;

  /// One display frame's budget, in milliseconds.
  final double budgetMs;

  /// Mean UI-thread build time.
  final double buildMs;

  /// Mean raster-thread time.
  final double rasterMs;

  /// Mean vsync wait.
  final double vsyncMs;

  /// Mean end-to-end span.
  final double totalMs;

  /// Frames whose total span exceeded [budgetMs].
  final int jankFrames;

  /// Whether this window missed any display frame.
  bool get hasJank => jankFrames > 0;
}

/// Samples Flutter's [FrameTiming] callbacks and reports one window per
/// second, so a host can tell whether a drop belongs to the UI thread, the
/// raster thread or the display cadence instead of guessing from FPS alone.
class FrameTimingsMonitor {
  /// Samples for [window] before reporting.
  FrameTimingsMonitor({this.window = const Duration(seconds: 1)});

  /// How often a window is reported.
  final Duration window;

  void Function(FrameTimingsStats stats)? _onStats;
  Timer? _timer;
  bool _listening = false;
  int _samples = 0;
  int _jank = 0;
  double _buildUs = 0;
  double _rasterUs = 0;
  double _vsyncUs = 0;
  double _totalUs = 0;

  /// Starts sampling; [onStats] receives one window per [window].
  void start(void Function(FrameTimingsStats stats) onStats) {
    stop();
    _onStats = onStats;
    _reset();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _listening = true;
    _timer = Timer.periodic(window, (_) => _emit());
  }

  /// Stops sampling and releases the callback.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _onStats = null;
    if (_listening) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      _listening = false;
    }
  }

  void _onTimings(List<FrameTiming> timings) {
    final budgetUs = _budgetMicroseconds();
    for (final timing in timings) {
      _samples++;
      _buildUs += timing.buildDuration.inMicroseconds;
      _rasterUs += timing.rasterDuration.inMicroseconds;
      _vsyncUs += timing.vsyncOverhead.inMicroseconds;
      final totalUs = timing.totalSpan.inMicroseconds;
      _totalUs += totalUs;
      if (totalUs > budgetUs) _jank++;
    }
  }

  void _emit() {
    final callback = _onStats;
    if (callback == null || _samples == 0) return;
    final samples = _samples;
    final stats = FrameTimingsStats(
      samples: samples,
      budgetMs: _budgetMicroseconds() / 1000,
      buildMs: _buildUs / samples / 1000,
      rasterMs: _rasterUs / samples / 1000,
      vsyncMs: _vsyncUs / samples / 1000,
      totalMs: _totalUs / samples / 1000,
      jankFrames: _jank,
    );
    _reset();
    callback(stats);
  }

  void _reset() {
    _samples = 0;
    _jank = 0;
    _buildUs = 0;
    _rasterUs = 0;
    _vsyncUs = 0;
    _totalUs = 0;
  }

  double _budgetMicroseconds() {
    final views = SchedulerBinding.instance.platformDispatcher.views;
    final refreshRate = views.isEmpty ? 0.0 : views.first.display.refreshRate;
    return refreshRate > 0
        ? Duration.microsecondsPerSecond / refreshRate
        : 16666.7;
  }
}
