import 'dart:ui';
import 'dart:collection';
import 'package:flame/game.dart';
import '../atlas/emoji_atlas.dart';
import '../pool/barrage_pool.dart';
import '../layout/rich_parser.dart';
import '../cache/picture_cache.dart';
import '../core/barrage_config.dart';
import '../layout/mixed_layout.dart';
import '../scheduler/track_manager.dart';
import '../scheduler/speed_strategy.dart';
import '../scheduler/track_allocator.dart';
import '../model/barrage/barrage_item.dart';
import '../model/barrage/barrage_type.dart';
import '../model/barrage/barrage_entry.dart';
import '../render/barrage/mixed_renderer.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flame_barrage/src/components/barrage_component.dart';

class BarrageEngine extends FlameGame {
  BarrageEngine({required BarrageConfig config, required this.emojiAtlas})
    : _config = config,
      _pictureCache = PictureCache(maxSize: config.pictureCacheMaxSize),
      _pool = BarragePool(maxSize: config.barragePoolMaxSize) {
    _parser = RichParser(atlas: emojiAtlas);
    _layout = MixedLayout(atlas: emojiAtlas, maxTextCacheSize: config.textCacheMaxSize);
    _renderer = MixedRenderer();
  }

  BarrageConfig _config;
  BarrageConfig get config => _config;
  final EmojiAtlas emojiAtlas;

  late final RichParser _parser;
  late final MixedLayout _layout;
  late final MixedRenderer _renderer;

  final PictureCache _pictureCache;
  final TrackManager _trackManager = TrackManager();
  final TrackAllocator _trackAllocator = const TrackAllocator();
  final SpeedStrategy _speedStrategy = const SpeedStrategy();
  final BarragePool _pool;

  final Queue<BarrageItem> _waiting = Queue<BarrageItem>();
  final List<BarrageComponent> _activeComponentCache = [];

  double _emitTimer = 0.0;
  double _metricTimer = 0.0;
  bool _massiveMode = false;
  bool _initialized = false;

  @override
  Color backgroundColor() => Colors.transparent;

  void updateConfig(BarrageConfig newConfig) {
    _config = newConfig;
    _layout.updateMaxTextCacheSize(newConfig.textCacheMaxSize);
    if (_initialized) {
      _trackManager.initialize(_config, size.y);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _trackManager.initialize(_config, size.y);
    _initialized = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _trackManager.initialize(_config, size.y);
    _initialized = true;
  }

  void pushMessage(BarrageItem item) {
    if (item.content.length > _config.maxTextLength) return;

    if (_waiting.length > _config.dangerousQueueSize) {
      if (item.priority < 1) return;
      _waiting.removeFirst();
    }
    _waiting.add(item);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_initialized) return;

    _massiveMode = _waiting.length > _config.massiveModeThreshold;

    _emitTimer += dt;
    final interval = _massiveMode ? _config.massiveEmitInterval : _config.normalEmitInterval;

    if (_emitTimer >= interval) {
      _emitTimer = 0.0;
      _dispatchWaiting();
    }

    _metricTimer += dt;
    if (_metricTimer >= 0.032) {
      _metricTimer = 0.0;
      _updateTrackMetrics();
    }
  }

  void _dispatchWaiting() {
    if (_waiting.isEmpty) return;
    if (_activeComponentCache.length >= _config.maxVisibleCount) return;

    final item = _waiting.first;
    final fragments = _parser.parse(item.content);
    final layoutResult = _layout.layout(fragments, item: item, config: _config);

    final mockEntry = BarrageEntry(item: item, creationTime: DateTime.now().millisecondsSinceEpoch)
      ..width = layoutResult.width
      ..height = layoutResult.height
      ..speed = item.type == BarrageType.scroll ? 100.0 : 0.0;

    final trackIndex = _trackAllocator.allocate(
      tracks: _trackManager.tracks,
      current: mockEntry,
      screenWidth: size.x,
      massiveMode: _massiveMode,
      config: _config,
    );

    if (trackIndex == -1) return;

    _waiting.removeFirst();

    final track = _trackManager.tracks[trackIndex];
    final now = DateTime.now().millisecondsSinceEpoch;
    track.lastLaunchTime = now;

    final cacheKey = _buildCacheKey(item);
    Picture? picture = _pictureCache.get(cacheKey);
    if (picture == null) {
      picture = _renderer.buildPicture(layoutResult);
      _pictureCache.put(cacheKey, picture);
    }

    double startX = size.x;
    double startY = trackIndex * _config.trackHeight + (_config.trackHeight - layoutResult.height) / 2;

    if (item.type != BarrageType.scroll) {
      track.locked = true;
      startX = (size.x - layoutResult.width) / 2;
      if (item.type == BarrageType.bottomFixed) {
        startY = size.y - (trackIndex + 1) * _config.trackHeight + (_config.trackHeight - layoutResult.height) / 2;
      }
    }

    mockEntry.track = trackIndex;
    mockEntry.x = startX;
    mockEntry.y = startY;

    mockEntry.speed = item.type == BarrageType.scroll
        ? _speedStrategy.calculate(mockEntry, size.x, _config, targetTrack: track, massiveMode: _massiveMode)
        : 0.0;

    final component = _pool.obtain(
      entry: mockEntry,
      picture: picture,
      fixedDuration: Duration(milliseconds: _config.fixedDurationMs),
    );

    component.opacity = _config.opacity;

    track.lastRight = startX + layoutResult.width;
    track.lastEntry = mockEntry;
    track.activeCount++;

    _activeComponentCache.add(component);
    add(component);
  }

  void _updateTrackMetrics() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final compLen = _activeComponentCache.length;

    for (final track in _trackManager.tracks) {
      double totalSpeed = 0.0;
      int count = 0;
      BarrageComponent? youngestComp;

      for (int i = 0; i < compLen; i++) {
        final comp = _activeComponentCache[i];
        if (comp.isRemoving) continue;
        if (comp.entry.track == track.index) {
          totalSpeed += comp.entry.speed;
          count++;
          if (youngestComp == null || comp.position.x > youngestComp.position.x) {
            youngestComp = comp;
          }
        }
      }

      track.activeCount = count;
      track.avgSpeed = count == 0 ? 0.0 : totalSpeed / count;
      track.density = size.x > 0 ? (count * 150.0) / size.x : 0.0;

      if (youngestComp != null) {
        track.lastRight = youngestComp.position.x + youngestComp.size.x;
        track.lastEntry = youngestComp.entry;
      } else {
        if (!track.locked) {
          track.lastRight = 0.0;
          track.lastEntry = null;
        }
        if (track.locked && now > track.lastLaunchTime + _config.fixedDurationMs) {
          track.locked = false;
          track.lastRight = 0.0;
          track.lastEntry = null;
        }
      }
    }
  }

  void recycleComponent(BarrageComponent component) {
    _activeComponentCache.remove(component);
    _pool.recycle(component);
  }

  void clear() {
    _waiting.clear();
    _pictureCache.clear();
    final activeComponents = List<BarrageComponent>.from(_activeComponentCache);
    _activeComponentCache.clear();
    removeAll(activeComponents);
    for (final track in _trackManager.tracks) {
      track.lastRight = 0.0;
      track.lastEntry = null;
      track.activeCount = 0;
      track.locked = false;
    }
  }

  String _buildCacheKey(BarrageItem item) {
    return [
      item.content,
      item.type.name,
      _config.fontSize,
      _config.fontWeight.toString(),
      _config.textColor.toARGB32(),
      _config.emojiSize,
    ].join('_');
  }

  @override
  void onRemove() {
    _waiting.clear();
    _pictureCache.clear();
    _trackManager.tracks.clear();
    _activeComponentCache.clear();
    _pool.clear();
    super.onRemove();
  }
}
