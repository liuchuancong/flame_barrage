import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../model/barrage/barrage_item.dart';
import '../model/barrage/barrage_type.dart';
import '../model/barrage/engine_state.dart';
import '../atlas/emoji_atlas.dart';
import '../util/barrage_logger.dart';
import '../systems/barrage_data_system.dart';
import '../systems/barrage_metrics_system.dart';
import '../systems/barrage_motion_system.dart';
import '../systems/barrage_render_system.dart';
import 'barrage_config.dart';
import 'barrage_context.dart';
import 'barrage_engine_api.dart';

/// Engine host: assembles the danmaku systems and owns the frame loop.
///
/// Every piece of per-frame work lives in one of four child components that
/// Flame advances in ascending priority order, each taking the state it needs
/// from the shared [BarrageContext]. The host itself only handles three
/// things:
///
/// * Assembly and lifecycle — it builds the context (config, logic clock,
///   lanes, caches, pools, the live entry list) and keeps viewport metrics in
///   sync on load, resize and config changes.
/// * Frame driving — the loop runs on Flame's own game loop, which ticks once
///   per display frame with microsecond-precision deltas. The engine is
///   resumed only while there is visible work and paused when idle, so a
///   silent room produces no frames at all. Logic steps are additionally
///   throttled down to [BarrageConfig.fps] when the display is faster, and
///   each step advances the clock by the real elapsed time. Clamping step
///   durations to anything shorter is what makes scroll speed sag under
///   load, so the only clamp left here guards against gaps after a suspend
///   (>150 ms).
/// * A step-cost watchdog — a step that takes over 20 ms is logged at a
///   throttled rate so sustained overloads show up in the log instead of
///   only in dropped frames.
///
/// Per-frame order (ascending priority):
/// 1. [BarrageDataSystem]   pacing, pre-layout of queued messages, lane
///    allocation on dispatch
/// 2. [BarrageMotionSystem] scroll integration, expiry, immediate recycling
/// 3. [BarrageMetricsSystem] per-lane density/speed/edge aggregation (~30 Hz)
/// 4. [BarrageRenderSystem] blitting through the Flame render tree
class BarrageEngine extends FlameGame with TapCallbacks implements BarrageEngineApi {
  BarrageEngine({required BarrageConfig config, required this.emojiAtlas})
    : _ctx = BarrageContext(config: config, emojiAtlas: emojiAtlas) {
    _dataSystem = BarrageDataSystem(_ctx);
    _motionSystem = BarrageMotionSystem(_ctx);
    _metricsSystem = BarrageMetricsSystem(_ctx);
    _renderSystem = BarrageRenderSystem(_ctx);
    addAll([_dataSystem, _motionSystem, _metricsSystem, _renderSystem]);
    _frameInterval = 1.0 / config.fps.clamp(1, 240);
    // Keep Flame's loop paused until the first message arrives; a mounted
    // game otherwise ticks (and repaints) at the display rate even when the
    // room is silent.
    pauseEngine();
  }

  final EmojiAtlas emojiAtlas;
  final BarrageContext _ctx;

  late final BarrageDataSystem _dataSystem;
  late final BarrageMotionSystem _motionSystem;
  late final BarrageMetricsSystem _metricsSystem;
  late final BarrageRenderSystem _renderSystem;

  bool _initialized = false;
  bool _appActive = true;
  EngineState _state = EngineState.running;
  bool get isPaused => _state == EngineState.paused;

  /// Accumulator for throttling logic steps when the display refreshes
  /// faster than [BarrageConfig.fps].
  double _logicAccum = 0.0;
  int _frameStepCount = 0;

  /// Cached `1 / config.fps`, refreshed only when the config changes so the
  /// frame path avoids the clamp/divide (and its boxed intermediates) per step.
  double _frameInterval = 1.0 / 60;

  // Step-cost watchdog.
  final Stopwatch _stepWatch = Stopwatch();
  int _lastStepCostUs = 0;
  int _peakStepCostUs = 0;
  int _lastOverloadLogAtMs = 0;

  /// A logic step taking longer than this is considered an overload.
  static const int _overloadThresholdUs = 20000;

  /// Shared state of the running engine: config, clock, lanes, caches, pools.
  BarrageContext get context => _ctx;

  // ========================
  // Playback rate
  // ========================

  /// Global speed multiplier applied to the logic clock. 1.0 runs at the
  /// configured speeds; 0.5 slow motion, 2.0 fast forward. Affects scroll
  /// travel and how long fixed messages stay pinned, together.
  @override
  double get playbackRate => _ctx.clock.scale;
  @override
  set playbackRate(double rate) => _ctx.clock.scale = rate.clamp(0.05, 8.0).toDouble();

  // ========================
  // Viewport metrics
  // ========================

  double _calculateAllowedHeight(double rawHeight) {
    final BuildContext? ctx = buildContext;
    double topInset = 0.0;
    double bottomInset = 0.0;
    if (ctx != null && _ctx.config.safeArea) {
      topInset = MediaQuery.paddingOf(ctx).top;
      bottomInset = MediaQuery.paddingOf(ctx).bottom;
    }
    final double finalTop = topInset + _ctx.config.topAreaDistance;
    final double finalBottom = bottomInset + _ctx.config.bottomAreaDistance;
    // TrackManager applies the configured area percentage. Returning an
    // already-scaled value here applied the percentage twice (20% became 4%)
    // and made lane availability change unexpectedly after rotation.
    return (rawHeight - finalTop - finalBottom).clamp(0.0, rawHeight).toDouble();
  }

  /// Pushes viewport size, safe-area offsets, usable height and lane layout
  /// into the shared context. Called on load, resize and config change.
  void _syncViewportMetrics() {
    _ctx.viewport.setFrom(size);
    final BuildContext? ctx = buildContext;
    double topInset = 0.0;
    double bottomInset = 0.0;
    if (ctx != null && _ctx.config.safeArea) {
      topInset = MediaQuery.paddingOf(ctx).top;
      bottomInset = MediaQuery.paddingOf(ctx).bottom;
    }
    _ctx.topOffset = topInset + _ctx.config.topAreaDistance;
    _ctx.bottomOffset = bottomInset + _ctx.config.bottomAreaDistance;
    _ctx.allowedHeight = _calculateAllowedHeight(size.y);
    _ctx.trackManager.initialize(_ctx.config, _ctx.allowedHeight);
  }

  /// Keeps [_ctx.rasterScale] in sync with the display density so baked
  /// bitmaps are rasterized at device resolution instead of being upscaled
  /// by the GPU.
  void _syncRasterScale() {
    double scale = 1.0;
    final BuildContext? ctx = buildContext;
    if (ctx != null) {
      try {
        final double? ratio = MediaQuery.maybeDevicePixelRatioOf(ctx);
        if (ratio != null && ratio > 0) {
          scale = ratio.clamp(1.0, 4.0).toDouble();
        }
      } catch (_) {
        scale = 1.0;
      }
    }
    if ((scale - _ctx.rasterScale).abs() < 0.01) return;
    // Bitmaps baked for a different density would be resampled at the wrong
    // size; messages still on screen keep theirs until they are recycled.
    if (_initialized) _ctx.renderCache.clear();
    _ctx.rasterScale = scale;
  }

  // ========================
  // Lifecycle
  // ========================

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _syncViewportMetrics();
    _initialized = true;
    _syncRasterScale();
    _resumeLoopIfNeeded();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _syncViewportMetrics();
    _initialized = true;
    _syncRasterScale();
    _resumeLoopIfNeeded();
  }

  /// Hot-applies configuration. Style and lane-geometry changes rebuild every
  /// on-screen message (spread across frames so a live-tuned slider does not
  /// overrun the frame budget); speed and dwell-time changes are re-applied
  /// to what is already on screen; visibility filters retire hidden messages
  /// immediately. Everything else (cache budgets, pacing, frame rate) takes
  /// effect on the following frames naturally.
  @override
  void updateConfig(BarrageConfig newConfig) {
    final old = _ctx.config;
    _ctx.config = newConfig;
    _frameInterval = 1.0 / newConfig.fps.clamp(1, 240);
    _ctx.parser.updateMaxCacheSize(newConfig.textCacheMaxSize);
    _ctx.layout.updateMaxTextCacheSize(newConfig.textCacheMaxSize);
    _ctx.renderCache.updateLimits(
      maxSize: newConfig.pictureCacheMaxSize,
      maxBytes: newConfig.rasterCacheMaxBytes,
    );
    _ctx.pool.updateMaxSize(newConfig.barragePoolMaxSize);
    _syncRasterScale();
    if (_initialized) {
      _syncViewportMetrics();
      final geometryChanged = _configAffectsTrackGeometry(old, newConfig);
      if (geometryChanged) {
        _ctx.trackManager.forceRefresh(newConfig, _ctx.allowedHeight);
      }
      if (geometryChanged || _configAffectsOnScreenStyle(old, newConfig)) {
        // A running loop restyles in bounded batches; with the loop paused
        // there is no frame to drain the queue through, so do it now.
        if (isPaused) {
          _dataSystem.relayoutActive();
        } else {
          _dataSystem.scheduleRelayout();
        }
      }
      if (old.baseSpeed != newConfig.baseSpeed) {
        _rescaleScrollSpeeds(old.baseSpeed, newConfig.baseSpeed);
      }
      if (old.fixedDuration != newConfig.fixedDuration) {
        _reexpireFixedEntries(newConfig.fixedDurationMs);
      }
      if (old.hideTop != newConfig.hideTop ||
          old.hideBottom != newConfig.hideBottom ||
          old.hideScroll != newConfig.hideScroll) {
        _motionSystem.retireWhere((entry) => newConfig.isTypeHidden(entry.item.type));
      }
    }
  }

  /// Re-applies a base-speed change to the entries already scrolling.
  ///
  /// A uniform factor keeps every relative gap intact: entries ahead stay
  /// ahead, and a follower that was capped below its leader (the speed
  /// strategy's no-catch-up rule) remains capped after scaling, so no pair
  /// starts overlapping. Entries with a per-item speed keep their own value.
  void _rescaleScrollSpeeds(double oldBaseSpeed, double newBaseSpeed) {
    if (oldBaseSpeed <= 0 || newBaseSpeed <= 0) return;
    final factor = newBaseSpeed / oldBaseSpeed;
    if (factor == 1.0) return;
    final entries = _ctx.activeEntries;
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.fx != null) continue;
      if (entry.item.type != BarrageType.scroll) continue;
      if (entry.item.baseSpeed != null) continue;
      entry.speed *= factor;
    }
  }

  /// Re-applies a dwell-time change to the pinned entries already on screen:
  /// expiry restarts from the entry's own spawn, and the lane lock deadline
  /// follows so a shortened duration frees the lane the moment the message
  /// leaves. Entries with a per-item duration keep their own value.
  void _reexpireFixedEntries(int newDurationMs) {
    final entries = _ctx.activeEntries;
    final tracks = _ctx.trackManager.tracks;
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.item.type == BarrageType.scroll) continue;
      if (entry.fx != null) continue;
      if (entry.item.fixedDuration != null) continue;
      final newExpire = entry.spawnTime + newDurationMs;
      final trackIndex = entry.track;
      if (trackIndex >= 0 && trackIndex < tracks.length) {
        final track = tracks[trackIndex];
        if (track.locked && track.lockedUntil == entry.expireTime) {
          track.lockedUntil = newExpire;
        }
      }
      entry.expireTime = newExpire;
    }
  }

  /// Fields whose change alters what on-screen messages look like.
  static bool _configAffectsOnScreenStyle(BarrageConfig a, BarrageConfig b) {
    return a.fontSize != b.fontSize ||
        a.fontWeight != b.fontWeight ||
        a.fontStyle != b.fontStyle ||
        a.fontFamily != b.fontFamily ||
        a.letterSpacing != b.letterSpacing ||
        a.textColor != b.textColor ||
        a.strokeColor != b.strokeColor ||
        a.strokeWidth != b.strokeWidth ||
        a.showStroke != b.showStroke ||
        a.showShadow != b.showShadow ||
        a.shadowColor != b.shadowColor ||
        a.shadowBlur != b.shadowBlur ||
        a.shadowOffset != b.shadowOffset ||
        a.opacity != b.opacity ||
        a.emojiSize != b.emojiSize ||
        a.noEmojiMode != b.noEmojiMode ||
        a.rasterizeItems != b.rasterizeItems ||
        !identical(a.effectInterceptors, b.effectInterceptors);
  }

  /// Fields whose change alters lane layout.
  static bool _configAffectsTrackGeometry(BarrageConfig a, BarrageConfig b) {
    return a.trackHeight != b.trackHeight ||
        a.area != b.area ||
        a.topAreaDistance != b.topAreaDistance ||
        a.bottomAreaDistance != b.bottomAreaDistance ||
        a.safeArea != b.safeArea;
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    pauseEngine();
    _appActive = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
    if (_appActive) {
      _resumeLoopIfNeeded();
    }
  }

  // ========================
  // Frame driving
  // ========================

  @override
  void pause() {
    if (isPaused) return;
    _state = EngineState.paused;
    _dataSystem.pause();
    _ctx.clock.pause();
    _logicAccum = 0.0;
    pauseEngine();
  }

  @override
  void resume() {
    if (!isPaused) return;
    _dataSystem.resume();
    _ctx.clock.resume();
    _state = EngineState.running;
    _resumeLoopIfNeeded();
  }

  void _resumeLoopIfNeeded() {
    if (!isPaused &&
        _appActive &&
        _initialized &&
        isAttached &&
        (_dataSystem.hasPending || _ctx.aliveCount > 0 || _ctx.fxParticles.hasAlive)) {
      resumeEngine();
    }
  }

  @override
  void update(double dt) {
    if (!_initialized || isPaused) return;

    // dt is the real display-frame duration handed over by Flame's game loop.
    // When the display refreshes faster than the configured fps, logic steps
    // are throttled via the accumulator below; otherwise every frame steps.
    // A step always advances the clock by the real elapsed time — clamping it
    // to anything shorter makes scroll velocity depend on frame load, which
    // reads as jerky, uneven motion. The 150 ms guard only absorbs the gap
    // left by a suspend/resume.
    //
    // The gate carries a 10% tolerance: on a display matching the configured
    // fps, per-frame dt sits a few hundred microseconds on either side of the
    // interval, and a strict comparison would skip the short frames only to
    // step double on the next one — motion updating at half the display rate
    // while the canvas repaints at full rate, i.e. the classic stutter. With
    // the tolerance, display ≈ fps steps every frame and only a genuinely
    // faster display (>= ~1.1x) starts skipping.
    _logicAccum += dt;
    if (_logicAccum < _frameInterval * 0.9) return;
    final elapsed = _logicAccum.clamp(0.0, 0.15).toDouble();
    _logicAccum = 0.0;
    _frameStepCount++;

    // Advance the logic clock before the systems run so their reads of
    // clock.now() include this frame's increment.
    _ctx.clock.tick(elapsed);

    _stepWatch
      ..reset()
      ..start();
    super.update(elapsed);
    _stepWatch.stop();

    _lastStepCostUs = _stepWatch.elapsedMicroseconds;
    if (_lastStepCostUs > _peakStepCostUs) _peakStepCostUs = _lastStepCostUs;
    _maybeLogOverload();

    if (!_dataSystem.hasPending && _ctx.aliveCount == 0 && !_ctx.fxParticles.hasAlive) {
      pauseEngine();
    }
  }

  void _maybeLogOverload() {
    if (_lastStepCostUs < _overloadThresholdUs) return;
    final wallNow = DateTime.now().millisecondsSinceEpoch;
    if (wallNow - _lastOverloadLogAtMs < 2000) return;
    _lastOverloadLogAtMs = wallNow;
    BarrageLogger.w(
      'Engine',
      'logic step overload: ${(_lastStepCostUs / 1000).toStringAsFixed(1)}ms (2s peak ${(_peakStepCostUs / 1000).toStringAsFixed(1)}ms)',
    );
    _peakStepCostUs = 0;
  }

  // ========================
  // BarrageEngineApi
  // ========================

  @override
  void pushMessage(BarrageItem item) {
    _dataSystem.pushMessage(item);
    _resumeLoopIfNeeded();
  }

  @override
  void loadTimeline(List<BarrageItem> items) {
    _dataSystem.loadTimeline(items);
    // A loaded timeline is pending work even though the dispatch queue is
    // empty, and an idle-paused loop never advances the clock that would
    // release its first message.
    _resumeLoopIfNeeded();
  }

  @override
  void seekTo(Duration position) {
    final ms = position.inMicroseconds / 1000.0;
    _ctx.clock.seekToMs(ms);
    _dataSystem.seekTimeline(position);
    // What is on screen belongs to the position being left. Retracting rather
    // than clearing keeps the loaded timeline, the caches and the lane state.
    _motionSystem.retractWhere((_) => true);
    _resumeLoopIfNeeded();
  }

  @override
  int retractWhere(bool Function(BarrageItem item) predicate) {
    final pending = _dataSystem.retractWhere(predicate);
    final onScreen = _motionSystem.retractWhere(predicate);
    return pending + onScreen;
  }

  @override
  void clear() {
    pauseEngine();
    _logicAccum = 0.0;
    _dataSystem.clear();
    _metricsSystem.clear();
    _ctx.parser.clearCache();
    _ctx.layout.clearCache();
    final entries = _ctx.activeEntries;
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final render = entry.render;
      if (render != null) {
        entry.render = null;
        _ctx.renderCache.release(render);
      }
    }
    _ctx.renderCache.clear();
    entries.length = 0;
    _ctx.aliveCount = 0;
    _ctx.pool.clear();
    _ctx.fxParticles.clear();
    _ctx.clock.reset();
    for (final track in _ctx.trackManager.tracks) {
      track.lastRight = 0.0;
      track.lastEntry = null;
      track.activeCount = 0;
      track.locked = false;
      track.lockedUntil = 0;
    }
  }

  // ========================
  // Pointer events
  // ========================

  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.localPosition;
    final entry = _renderSystem.entryAt(pos.x, pos.y);
    if (entry != null) {
      event.handled = true;
      entry.item.onTapDown?.call();
    }
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    final pos = event.localPosition;
    final entry = _renderSystem.entryAt(pos.x, pos.y);
    if (entry != null) {
      event.handled = true;
      entry.item.onLongTapDown?.call();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    final pos = event.localPosition;
    final entry = _renderSystem.entryAt(pos.x, pos.y);
    if (entry != null) {
      event.handled = true;
      entry.item.onTapUp?.call();
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    // Preserved behavior: a cancelled gesture notifies every visible entry.
    final entries = _ctx.activeEntries;
    for (int i = 0; i < entries.length; i++) {
      entries[i].item.onTapCancel?.call();
    }
  }

  /// Dispatches a Flutter-layer pointer to the top-most visible barrage item.
  /// This lets the video gesture surface keep swipe/double-tap handling while
  /// still supporting precise danmaku actions.
  @override
  bool triggerItemAt(double x, double y, {required bool longPress}) {
    final entry = _renderSystem.entryAt(x, y);
    if (entry == null) return false;
    final callback = longPress ? entry.item.onLongTapDown : entry.item.onTapUp;
    if (callback == null) return false;
    callback();
    return true;
  }

  /// Holds the top-most message at the point in place. While held it neither
  /// scrolls nor expires, so the host can present an action sheet on it and
  /// resume it afterwards via [resumeAllPaused].
  @override
  BarrageItem? pauseItemAt(double x, double y) {
    final entry = _renderSystem.entryAt(x, y);
    if (entry == null) return null;
    entry.paused = true;
    return entry.item;
  }

  @override
  void resumeAllPaused() {
    final entries = _ctx.activeEntries;
    for (int i = 0; i < entries.length; i++) {
      entries[i].paused = false;
    }
  }

  @override
  int get pausedCount {
    final entries = _ctx.activeEntries;
    int count = 0;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].paused) count++;
    }
    return count;
  }

  @override
  Color backgroundColor() => Colors.transparent;

  // ========================
  // Observability
  // ========================

  @override
  int get activeCacheSize => _ctx.renderCache.size;

  @override
  int get activeCount => _ctx.aliveCount;

  @override
  int get rasterCacheBytes => _ctx.renderCache.byteSize;

  @override
  int get activePoolSize => _ctx.pool.currentSize;

  @override
  int get pendingMessageCount => _dataSystem.pendingCount;

  @override
  bool get rasterizationActive => _ctx.config.rasterizeItems && _ctx.renderCache.rasterizationSupported;

  int get parserCacheSize => _ctx.parser.cacheCount;
  int get layoutCacheSize => _ctx.layout.cacheCount;

  /// Whether the game loop is running (not paused and there is visible work).
  bool get framePulseActive => !paused;
  int get frameStepCount => _frameStepCount;

  /// Total cost of the last logic step across all systems, in microseconds.
  int get lastStepCostUs => _lastStepCostUs;

  /// Peak step cost since the last overload warning, in microseconds.
  int get peakStepCostUs => _peakStepCostUs;

  BarrageMotionSystem get motionSystem => _motionSystem;
  BarrageDataSystem get dataSystem => _dataSystem;
  BarrageRenderSystem get renderSystem => _renderSystem;
  BarrageMetricsSystem get metricsSystem => _metricsSystem;
}
