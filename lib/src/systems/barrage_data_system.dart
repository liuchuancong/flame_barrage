import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../cache/render_cache.dart';
import '../effect/motion/barrage_motion_effect.dart';
import '../layout/layout_result.dart';
import '../model/barrage/barrage_entry.dart';
import '../model/barrage/barrage_item.dart';
import '../model/barrage/barrage_track.dart';
import '../model/barrage/barrage_type.dart';
import '../scheduler/speed_strategy.dart';
import '../scheduler/track_allocator.dart';
import '../util/barrage_logger.dart';
import '../core/barrage_config.dart';
import '../core/barrage_context.dart';
import '../core/barrage_timeline.dart';

class _PendingBarrage {
  const _PendingBarrage(this.item, this.enqueuedAtMs, {this.timed = false});

  final BarrageItem item;
  final int enqueuedAtMs;

  /// Whether this message came off a loaded timeline rather than a live send.
  ///
  /// A timed message is due by media time, not by how long it has sat in the
  /// queue: a viewer who pauses for ten seconds and resumes must still get the
  /// comment that belongs at this position, which the wall-clock age limit
  /// would otherwise have discarded.
  final bool timed;
}

/// Owns the waiting queue, dispatch pacing, pre-layout and lane placement.
///
/// Messages flow through a small state machine: pending (queued) → prepared
/// (parse/layout warmed, cache hits) → active (dispatched to a lane). Text
/// shaping is the expensive part of dispatch, so queued messages are laid
/// out ahead of time within a small per-frame budget instead of paying the
/// full shaping cost in the frame the emit timer happens to fire.
class BarrageDataSystem extends Component {
  BarrageDataSystem(this._ctx, {int prepareAhead = 3, int priority = 100})
    : _prepareAhead = prepareAhead.clamp(1, 8),
      super(priority: priority);

  final BarrageContext _ctx;

  /// How many queue-head messages are warmed per frame. A queued message
  /// usually waits several frames before its emit slot arrives; warming the
  /// first few spreads the shaping cost further, and repeat calls after the
  /// first are just hash lookups.
  final int _prepareAhead;

  final Queue<_PendingBarrage> _waiting = Queue<_PendingBarrage>();
  final Queue<_PendingBarrage> _pausedBuffer = Queue<_PendingBarrage>();
  double _emitTimer = 0.0;
  bool _paused = false;

  final TrackAllocator _trackAllocator = const TrackAllocator();
  final SpeedStrategy _speedStrategy = const SpeedStrategy();

  /// Per-dispatch random source for motion-effect seeds (spawn cadence,
  /// gallop cadence, meteor angle...). One shared Random: cheap and enough.
  final math.Random _fxRandom = math.Random();

  /// Upper bound on dispatches per logic frame in realtime mode. Generous
  /// enough that paced traffic never notices it, tight enough that a burst
  /// cannot consume the frame it lands in.
  static const int _realtimeDispatchCap = 8;

  bool get hasPending =>
      _waiting.isNotEmpty || _pausedBuffer.isNotEmpty || _timeline.hasUpcoming;
  int get pendingCount => _waiting.length + _pausedBuffer.length;

  /// Comments of a recorded stream, dispatched by media time.
  final BarrageTimeline _timeline = BarrageTimeline();

  /// Whether a timeline is loaded.
  bool get hasTimeline => !_timeline.isEmpty;

  /// Loads a recorded stream's comments, replacing any previous timeline.
  void loadTimeline(List<BarrageItem> items) => _timeline.load(items);

  /// Moves the timeline's read position to [position].
  ///
  /// Only the queue half happens here; taking the old position's messages off
  /// screen is the engine's job.
  void seekTimeline(Duration position) => _timeline.seekTo(position);

  /// Hands the items [position] has reached to the waiting queue.
  void _releaseDueTimelineItems() {
    if (!_timeline.hasUpcoming) return;
    final mediaTime = Duration(
      microseconds: (_ctx.clock.nowPrecise() * 1000).round(),
    );
    for (final item in _timeline.dueBy(mediaTime)) {
      pushMessage(item, timed: true);
    }
  }

  void pause() => _paused = true;

  void resume() {
    if (!_paused) return;
    _paused = false;
    _flushPausedBuffer();
  }

  void _flushPausedBuffer() {
    final maxPendingCount = _ctx.config.maxPendingCount.clamp(1, 10000);
    while (_pausedBuffer.isNotEmpty) {
      while (_waiting.length >= maxPendingCount) {
        _waiting.removeFirst();
      }
      _waiting.add(_pausedBuffer.removeFirst());
    }
  }

  void pushMessage(BarrageItem item, {bool timed = false}) {
    // A hidden type is rejected before it ever queues, so the waiting queue
    // never fills with messages that would only be dropped at dispatch.
    if (_ctx.config.isTypeHidden(item.type)) return;
    final pending = _PendingBarrage(
      item,
      DateTime.now().millisecondsSinceEpoch,
      timed: timed,
    );
    final maxPendingCount = _ctx.config.maxPendingCount.clamp(1, 10000);
    while (_waiting.length + _pausedBuffer.length >= maxPendingCount) {
      if (_waiting.isNotEmpty) {
        _waiting.removeFirst();
      } else {
        _pausedBuffer.removeFirst();
      }
    }
    if (_paused) {
      _pausedBuffer.add(pending);
    } else {
      _waiting.add(pending);
    }
  }

  void clear() {
    _waiting.clear();
    _pausedBuffer.clear();
    _timeline.clear();
    _paused = false;
    _emitTimer = 0.0;
    _relayoutQueue.clear();
    _relayoutIndex = 0;
    for (final render in _bakeQueue) {
      render.bakeQueued = false;
    }
    _bakeQueue.clear();
  }

  /// Drops every message still waiting for a lane (or parked in the pause
  /// buffer, or not yet released by a loaded timeline) whose item matches
  /// [predicate] — the queue half of a host-side retraction. Returns how many
  /// were dropped.
  int retractWhere(bool Function(BarrageItem item) predicate) {
    final before = _waiting.length + _pausedBuffer.length;
    _waiting.removeWhere((pending) => predicate(pending.item));
    _pausedBuffer.removeWhere((pending) => predicate(pending.item));
    return before - (_waiting.length + _pausedBuffer.length) +
        _timeline.retractWhere(predicate);
  }

  @override
  void update(double dt) {
    _drainBakeQueue();
    _releaseDueTimelineItems();
    _runScheduledRelayout();
    if (_ctx.config.realtimeMode) {
      // Unthrottled: flush the waiting queue every logic frame, still bounded
      // by maxVisibleCount and lane availability. Bursts appear the moment
      // they arrive instead of trailing the pacing timer — but no more than
      // [_realtimeDispatchCap] per frame: each dispatch lays out and records
      // a message, and an unbounded flush of a large burst would spend the
      // whole frame budget the moment the burst lands.
      final now = _ctx.clock.nowPrecise();
      int dispatched = 0;
      while (_waiting.isNotEmpty &&
          _ctx.aliveCount < _ctx.config.maxVisibleCount &&
          dispatched < _realtimeDispatchCap) {
        if (!_dispatchOne(now)) break;
        dispatched++;
      }
    } else {
      _emitTimer += dt;
      if (_emitTimer >= _ctx.config.emitInterval) {
        _emitTimer = 0.0;
        _dispatchOne(_ctx.clock.nowPrecise());
      }
    }
    _prepareAheadItems();
  }

  // The expensive part of dispatching a message is text shaping inside
  // MixedLayout._buildParagraph (and it happens twice per text fragment
  // when showStroke is on — once for fill, once for stroke). Left alone,
  // that cost lands entirely in whichever frame the emit timer fires,
  // stacked on top of track allocation and entry spawn in the same frame —
  // a spike that's easy to miss on a fast device and a dropped frame on a
  // slow one. An item usually sits at the front of _waiting for several
  // frames before it's actually due, so shape it ahead of time here: both
  // RichParser and MixedLayout cache by content/hash, so calling parse()
  // and layout() again at dispatch time is just a cache hit once this has
  // already run for the same head item.
  void _prepareAheadItems() {
    if (_waiting.isEmpty) return;
    var warmed = 0;
    for (final pending in _waiting) {
      if (warmed >= _prepareAhead) break;
      final fragments = _ctx.parser.parse(pending.item.content);
      _ctx.layout.layout(fragments, item: pending.item, config: _resolveConfig(pending.item));
      warmed++;
    }
  }

  /// Tries to dispatch the queue-head message. Returns true on success;
  /// false when the queue is empty, the screen is at capacity, or no lane
  /// fits — in which case the message stays at the head and retries next
  /// frame.
  bool _dispatchOne(double now) {
    final wallNow = DateTime.now().millisecondsSinceEpoch;
    final maxAgeMs = _ctx.config.maxPendingAge.inMilliseconds.clamp(0, 600000);
    // A timed message is exempt: it is due by media time, and a viewer who
    // pauses past maxPendingAge must still get the comment at this position.
    while (_waiting.isNotEmpty &&
        !_waiting.first.timed &&
        wallNow - _waiting.first.enqueuedAtMs > maxAgeMs) {
      _waiting.removeFirst();
    }
    // Drain messages whose type was hidden after they queued, so toggling a
    // visibility filter does not leave a backlog that takes one emit slot
    // each to disappear.
    while (_waiting.isNotEmpty && _ctx.config.isTypeHidden(_waiting.first.item.type)) {
      _waiting.removeFirst();
    }
    if (_waiting.isEmpty) return false;
    if (_ctx.aliveCount >= _ctx.config.maxVisibleCount) return false;
    final item = _waiting.first.item;
    // BarrageMotionEffect owns the motion of effect messages; the uniform
    // scroll strategy does not apply to them.
    final fxEffect = item.effect;
    final config = _resolveConfig(item);
    _ctx.trackManager.initialize(config, _ctx.allowedHeight);
    if (_ctx.trackManager.tracks.isEmpty) return false;
    final fragments = _ctx.parser.parse(item.content);
    final layoutResult = _ctx.layout.layout(fragments, item: item, config: config);
    final entry = _ctx.pool.obtain(item: item, creationTime: now.round())
      ..width = layoutResult.width
      ..height = layoutResult.height
      ..lastUpdateTime = now
      ..spawnTime = now.round()
      ..expireTime = now.round() + config.fixedDurationMs;
    entry.speed = item.type == BarrageType.scroll && fxEffect == null ? config.baseSpeed : 0.0;
    final trackIndex = _trackAllocator.allocate(
      tracks: _ctx.trackManager.tracks,
      current: entry,
      screenWidth: _ctx.viewport.x,
      config: config,
    );
    if (trackIndex == -1) {
      _ctx.pool.recycle(entry);
      return false;
    }
    _waiting.removeFirst();
    final track = _ctx.trackManager.tracks[trackIndex];
    if (item.type == BarrageType.scroll && fxEffect == null) {
      entry.speed = _speedStrategy.calculate(entry, _ctx.viewport.x, config, targetTrack: track);
    }
    track.lastLaunchTime = now.round();
    final cacheKey = buildCacheKey(item);
    final CachedRender render = _renderFor(cacheKey, item, layoutResult);
    double startX = _ctx.viewport.x;
    double startY =
        _ctx.topOffset +
        (trackIndex * config.trackHeight) +
        (config.trackHeight - layoutResult.height) / 2;
    if (item.type != BarrageType.scroll) {
      track.locked = true;
      track.lockedUntil = entry.expireTime;
      startX = (_ctx.viewport.x - layoutResult.width) / 2;
      if (item.type == BarrageType.bottomFixed) {
        startY =
            _ctx.viewport.y -
            _ctx.bottomOffset -
            ((trackIndex + 1) * config.trackHeight) +
            (config.trackHeight - layoutResult.height) / 2;
      }
    }
    entry.track = trackIndex;
    entry.x = startX;
    entry.y = startY;
    entry.render = render;
    entry.picture = render.picture;
    entry.active = true;
    if (fxEffect != null) {
      _spawnEffectShow(entry, fxEffect, startY, track, now);
    }
    track.lastRight = startX + layoutResult.width;
    track.lastEntry = entry;
    track.activeCount++;
    _ctx.activeEntries.add(entry);
    _ctx.aliveCount++;
    return true;
  }

  /// Hands the entry over to a [BarrageMotionEffect] for its whole show.
  ///
  /// The lane is locked until the show ends (like a fixed barrage), so the
  /// effect can fly anywhere without colliding with other messages: spawn
  /// position, path and pose all come from the effect. expireTime is the
  /// fallback expiry the motion system retires against, and doubles as the
  /// lane-lock deadline.
  void _spawnEffectShow(
    BarrageEntry entry,
    BarrageMotionEffect effect,
    double startY,
    BarrageTrack track,
    double now,
  ) {
    final fx = BarrageFxState()
      ..effect = effect
      ..entryWidth = entry.width
      ..entryHeight = entry.height
      ..laneTop = startY + (entry.height - _ctx.config.trackHeight) / 2
      ..laneHeight = _ctx.config.trackHeight
      ..viewportWidth = _ctx.viewport.x
      ..viewportHeight = _ctx.viewport.y
      ..seed = _fxRandom.nextDouble()
      ..particles = _ctx.fxParticles;
    effect.onSpawn(fx);
    entry.fx = fx;
    entry.x = fx.x;
    entry.y = fx.y;
    entry.expireTime = now.round() + (effect.duration * 1000).ceil();
    track.locked = true;
    track.lockedUntil = entry.expireTime + 50;
  }

  /// Entries still waiting for a scheduled relayout pass, snapshotted when the
  /// pass was scheduled. Entries dispatched afterwards are laid out with the
  /// current config already and never enter the queue.
  final List<BarrageEntry> _relayoutQueue = <BarrageEntry>[];
  int _relayoutIndex = 0;

  /// How many queued entries one frame may re-lay out. A full-screen relayout
  /// (shaping + picture recording per entry) done in a single frame overruns
  /// the frame budget on low-end hardware — which is exactly when a host is
  /// likely to be tuning the config live. The batch keeps the per-frame cost
  /// bounded while the whole screen still restyles within a few frames.
  static const int _relayoutBatchSize = 8;

  /// Queues every on-screen message for a relayout against the current config,
  /// spread across frames in [_relayoutBatchSize] chunks.
  ///
  /// Called from `updateConfig` for style/geometry changes; dragging a slider
  /// then costs one bounded batch per frame instead of a full re-bake per
  /// slider tick.
  void scheduleRelayout() {
    // A pass already in flight will cover the screen; restarting the snapshot
    // mid-drag would keep re-doing the same head entries and never reach the
    // tail.
    if (_relayoutQueue.isNotEmpty) return;
    _relayoutQueue.addAll(_ctx.activeEntries);
    _relayoutIndex = 0;
  }

  void _runScheduledRelayout() {
    if (_relayoutQueue.isEmpty) return;
    int processed = 0;
    while (_relayoutIndex < _relayoutQueue.length && processed < _relayoutBatchSize) {
      final entry = _relayoutQueue[_relayoutIndex];
      _relayoutIndex++;
      // A null render means the entry was recycled since the snapshot: it is
      // back in the pool (skip) or already re-dispatched with the new config
      // (skip). Live entries always hold a render claim.
      if (entry.render == null) continue;
      _relayoutEntry(entry);
      processed++;
    }
    if (_relayoutIndex >= _relayoutQueue.length) {
      _relayoutQueue.clear();
      _relayoutIndex = 0;
    }
  }

  /// Re-lays out and re-bakes every on-screen message against the current
  /// config in one synchronous pass.
  ///
  /// Called when a config change alters what on-screen messages look like or
  /// where they sit (font, colors, stroke, shadow, opacity, emoji size,
  /// rasterization, lane geometry) while the loop is paused — a running loop
  /// uses [scheduleRelayout] instead. Scrolling entries keep their x and keep
  /// travelling; pinned entries re-center under the new geometry. If the
  /// lane count shrank, entries are clamped onto the last available lane.
  /// The previous render artifact is handed back to the cache afterwards, so
  /// artifacts shared with other entries are never disposed out from under
  /// them.
  void relayoutActive() {
    _relayoutQueue.clear();
    _relayoutIndex = 0;
    final entries = _ctx.activeEntries;
    if (entries.isEmpty) return;
    for (int i = 0; i < entries.length; i++) {
      _relayoutEntry(entries[i]);
    }
  }

  /// Rebuilds one entry against the current config in place.
  void _relayoutEntry(BarrageEntry entry) {
    // Motion-effect shows keep their own choreography; re-centering them
    // here would fight the effect's path. They are short-lived, so simply
    // leaving them untouched is fine.
    if (entry.fx != null) return;
    final trackCount = _ctx.trackManager.tracks.length;
    final config = _resolveConfig(entry.item);
    final fragments = _ctx.parser.parse(entry.item.content);
    final layoutResult = _ctx.layout.layout(fragments, item: entry.item, config: config);
    if (entry.track >= trackCount) entry.track = trackCount - 1;
    final trackIndex = entry.track.clamp(0, trackCount - 1);

    final oldRender = entry.render;
    final cacheKey = buildCacheKey(entry.item);
    final render = _renderFor(cacheKey, entry.item, layoutResult);
    entry
      ..width = layoutResult.width
      ..height = layoutResult.height
      ..render = render
      ..picture = render.picture;
    if (oldRender != null) {
      _ctx.renderCache.release(oldRender);
    }

    final double centerY = (config.trackHeight - layoutResult.height) / 2;
    switch (entry.item.type) {
      case BarrageType.bottomFixed:
        entry.y = _ctx.viewport.y - _ctx.bottomOffset - ((trackIndex + 1) * config.trackHeight) + centerY;
        entry.x = (_ctx.viewport.x - layoutResult.width) / 2;
        break;
      case BarrageType.topFixed:
        entry.y = _ctx.topOffset + (trackIndex * config.trackHeight) + centerY;
        entry.x = (_ctx.viewport.x - layoutResult.width) / 2;
        break;
      case BarrageType.scroll:
        entry.y = _ctx.topOffset + (trackIndex * config.trackHeight) + centerY;
        break;
    }
  }

  BarrageConfig _resolveConfig(BarrageItem item) {
    if (!_itemHasConfigOverrides(item)) return _ctx.config;
    // copyWith allocates a whole new BarrageConfig (20+ fields). Most items
    // in a real stream don't set any per-item style override, so skip the
    // clone entirely and reuse the shared config in the common case.
    final base = _ctx.config;
    return base.copyWith(
      textColor: item.textColor,
      fontSize: item.fontSize,
      fontWeight: item.fontWeight,
      fontStyle: item.fontStyle,
      fontFamily: item.fontFamily,
      letterSpacing: item.letterSpacing,
      opacity: item.opacity,
      showStroke: item.showStroke,
      strokeColor: item.strokeColor,
      strokeWidth: item.strokeWidth,
      showShadow: item.showShadow,
      shadowColor: item.shadowColor,
      shadowBlur: item.shadowBlur,
      shadowOffset: item.shadowOffset,
      fixedDuration: item.fixedDuration,
      emojiSize: item.emojiSize,
      baseSpeed: item.baseSpeed,
      overlapSafeGap: item.overlapSafeGap,
    );
  }

  bool _itemHasConfigOverrides(BarrageItem item) {
    return item.textColor != null ||
        item.fontSize != null ||
        item.fontWeight != null ||
        item.fontStyle != null ||
        item.fontFamily != null ||
        item.letterSpacing != null ||
        item.opacity != null ||
        item.showStroke != null ||
        item.strokeColor != null ||
        item.strokeWidth != null ||
        item.showShadow != null ||
        item.shadowColor != null ||
        item.shadowBlur != null ||
        item.shadowOffset != null ||
        item.fixedDuration != null ||
        item.emojiSize != null ||
        item.baseSpeed != null ||
        item.overlapSafeGap != null;
  }

  /// Transparent margin baked around every message. Strokes, glows and shadows
  /// reach past the text bounds and must not be clipped by the bitmap edge;
  /// this mirrors the allowance MixedRenderer keeps in its recording cull rect.
  static const double _rasterPadding = 8.0;

  /// Several TV GPUs refuse textures beyond this edge length. Longer messages
  /// keep using the vector recording instead of vanishing.
  static const double _maxRasterDimension = 4096.0;

  /// How many deferred bitmaps one frame may bake. Baking a message records a
  /// device-scaled copy of its picture and rasterizes it (`toImageSync`) —
  /// raster-thread work that lands inside the frame that first draws it. A
  /// burst or a config-drag restyle used to bake dozens of bitmaps in one
  /// frame; with the budget the same work spreads over a few frames while the
  /// not-yet-baked messages draw through their (already styled) vector
  /// recording.
  static const int _bakeBudgetPerFrame = 8;

  /// Renders waiting to be baked, oldest first.
  final Queue<CachedRender> _bakeQueue = Queue<CachedRender>();

  /// Acquires (or builds and stores) the render for a message, and queues it
  /// for baking when it has no bitmap yet. The returned reference is owned by
  /// the caller and must be handed to the motion system's release with its
  /// barrage.
  CachedRender _renderFor(String cacheKey, BarrageItem item, LayoutResult layoutResult) {
    final cached = _ctx.renderCache.acquire(cacheKey);
    if (cached != null) {
      _enqueueBake(cached);
      return cached;
    }
    final render = CachedRender(picture: _ctx.renderer.buildPicture(layoutResult))
      ..contentWidth = layoutResult.width
      ..contentHeight = layoutResult.height;
    final stored = _ctx.renderCache.put(cacheKey, render);
    _enqueueBake(stored);
    return stored;
  }

  void _enqueueBake(CachedRender render) {
    if (!_ctx.config.rasterizeItems || !_ctx.renderCache.rasterizationSupported) return;
    if (render.bakeQueued || render.isDisposed || render.hasImage) return;
    render.bakeQueued = true;
    _bakeQueue.add(render);
  }

  /// Bakes up to [_bakeBudgetPerFrame] queued renders. Runs before dispatch
  /// each frame so freshly baked bitmaps are blitted the same frame.
  void _drainBakeQueue() {
    if (_bakeQueue.isEmpty) return;
    if (!_ctx.config.rasterizeItems || !_ctx.renderCache.rasterizationSupported) {
      for (final render in _bakeQueue) {
        render.bakeQueued = false;
      }
      _bakeQueue.clear();
      return;
    }
    int budget = _bakeBudgetPerFrame;
    while (budget > 0 && _bakeQueue.isNotEmpty) {
      final render = _bakeQueue.removeFirst();
      render.bakeQueued = false;
      // The render may have been evicted and disposed while queued (message
      // scrolled off, cache trimmed); there is nothing left to bake.
      if (render.isDisposed || render.hasImage) continue;
      _bakeRender(render, render.contentWidth, render.contentHeight);
      _ctx.renderCache.accountBytes(render);
      budget--;
    }
  }

  /// Rasterizes [render] once so display frames only have to blit it.
  ///
  /// The picture is recorded into a device-pixel sized bitmap here, on the UI
  /// thread, but `toImageSync` only creates a handle: the actual rasterization
  /// happens on the raster thread, off the frame's critical path. Every message
  /// that appears more than once — a repeated "666", a welcome template — then
  /// costs one textured quad per frame instead of re-running its text, stroke,
  /// shadow and emoji operations.
  void _bakeRender(CachedRender render, double width, double height) {
    if (!_ctx.config.rasterizeItems || !_ctx.renderCache.rasterizationSupported) return;
    if (width <= 0 || height <= 0) return;

    final double scale = _ctx.rasterScale;
    final double paddedWidth = (width + _rasterPadding * 2) * scale;
    final double paddedHeight = (height + _rasterPadding * 2) * scale;
    if (paddedWidth > _maxRasterDimension || paddedHeight > _maxRasterDimension) return;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, paddedWidth, paddedHeight));
      canvas.scale(scale);
      canvas.translate(_rasterPadding, _rasterPadding);
      canvas.drawPicture(render.picture);
      final source = recorder.endRecording();
      render.image = source.toImageSync(paddedWidth.ceil(), paddedHeight.ceil());
      render.rasterSource = source;
      render.padding = _rasterPadding;
      render.rasterWidth = width + _rasterPadding * 2;
      render.rasterHeight = height + _rasterPadding * 2;
      render.rasterSrc = ui.Rect.fromLTWH(0, 0, paddedWidth, paddedHeight);
      render.oneToOne = scale == 1.0;
    } catch (error) {
      // Renderers without picture rasterization support (the HTML renderer, a
      // few embedders) throw here. Stop attempting it entirely rather than
      // paying for a failed try on every dispatched message.
      _ctx.renderCache.rasterizationSupported = false;
      render.image?.dispose();
      render.image = null;
      render.rasterSource?.dispose();
      render.rasterSource = null;
      BarrageLogger.w('Performance', 'bitmap baking unavailable, falling back to vector drawing: $error');
    }
  }

  String buildCacheKey(BarrageItem item) {
    // Runs once per dispatched item. A StringBuffer avoids allocating the
    // intermediate List<Object> (with its boxed doubles/bools) that
    // List.join would otherwise build just to throw away.
    final config = _ctx.config;
    final buffer = StringBuffer()
      ..write(item.content)
      ..write('|')
      ..write(item.type.name)
      ..write('|')
      ..write(item.fontSize ?? config.fontSize)
      ..write('|')
      ..write(item.fontWeight ?? config.fontWeight)
      ..write('|')
      ..write((item.fontStyle ?? config.fontStyle).name)
      ..write('|')
      ..write((item.textColor ?? config.textColor).toARGB32())
      ..write('|')
      ..write(item.emojiSize ?? config.emojiSize)
      ..write('|')
      ..write(item.fontFamily ?? config.fontFamily ?? '')
      ..write('|')
      ..write(item.letterSpacing ?? config.letterSpacing)
      ..write('|')
      ..write(item.showStroke ?? config.showStroke)
      ..write('|')
      ..write(item.strokeWidth ?? config.strokeWidth)
      ..write('|')
      ..write((item.strokeColor ?? config.strokeColor).toARGB32())
      ..write('|')
      ..write(item.showShadow ?? config.showShadow)
      ..write('|')
      ..write((item.shadowColor ?? config.shadowColor).toARGB32())
      ..write('|')
      ..write(item.shadowBlur ?? config.shadowBlur)
      ..write('|')
      ..write(item.shadowOffset ?? config.shadowOffset)
      ..write('|')
      ..write(item.opacity ?? config.opacity)
      ..write('|')
      ..write(item.fixedDuration ?? config.fixedDuration)
      ..write('|')
      ..write(config.noEmojiMode);
    return buffer.toString();
  }
}
