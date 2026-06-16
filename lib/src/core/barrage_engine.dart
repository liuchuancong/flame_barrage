import 'dart:ui';
import 'dart:collection';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
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

class BarrageEngine extends FlameGame with TapCallbacks {
  BarrageEngine({required BarrageConfig config, required this.emojiAtlas})
    : _config = config,
      _pictureCache = PictureCache(maxSize: config.pictureCacheMaxSize),
      _pool = BarragePool(maxSize: config.barragePoolMaxSize) {
    _parser = RichParser(atlas: emojiAtlas);
    _layout = MixedLayout(atlas: emojiAtlas, maxTextCacheSize: config.textCacheMaxSize);
    _renderer = const MixedRenderer();
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

  // 巅峰优化：双常驻数组指针原地互换，终结任何 List.from() 的堆申请和 GC 海啸
  List<BarrageEntry> _activeEntries = [];
  List<BarrageEntry> _backbufferEntries = [];

  double _emitTimer = 0.0;
  double _metricTimer = 0.0;
  double _cleanupTimer = 0.0;
  bool _initialized = false;

  @override
  void onTapDown(TapDownEvent event) {
    final clickPos = event.localPosition;
    final int len = _activeEntries.length;

    for (int i = len - 1; i >= 0; i--) {
      final entry = _activeEntries[i];
      if (!entry.active) continue;

      final double left = entry.x;
      final double top = entry.y;
      final double right = left + entry.width;
      final double bottom = top + entry.height;

      if (clickPos.x >= left && clickPos.x <= right && clickPos.y >= top && clickPos.y <= bottom) {
        event.handled = true;
        entry.item.onTapDown?.call();
        break;
      }
    }
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    final clickPos = event.localPosition;
    final int len = _activeEntries.length;
    for (int i = len - 1; i >= 0; i--) {
      final entry = _activeEntries[i];
      if (!entry.active) continue;
      if (clickPos.x >= entry.x &&
          clickPos.x <= entry.x + entry.width &&
          clickPos.y >= entry.y &&
          clickPos.y <= entry.y + entry.height) {
        event.handled = true;
        entry.item.onLongTapDown?.call();
        break;
      }
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    final clickPos = event.localPosition;
    final int len = _activeEntries.length;
    for (int i = len - 1; i >= 0; i--) {
      final entry = _activeEntries[i];
      if (!entry.active) continue;
      if (clickPos.x >= entry.x &&
          clickPos.x <= entry.x + entry.width &&
          clickPos.y >= entry.y &&
          clickPos.y <= entry.y + entry.height) {
        event.handled = true;
        entry.item.onTapUp?.call();
        break;
      }
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    final int len = _activeEntries.length;
    for (int i = 0; i < len; i++) {
      if (_activeEntries[i].active) {
        _activeEntries[i].item.onTapCancel?.call();
      }
    }
  }

  @override
  Color backgroundColor() => Colors.transparent;

  void updateConfig(BarrageConfig newConfig) {
    _config = newConfig;
    _layout.updateMaxTextCacheSize(newConfig.textCacheMaxSize);
    _pictureCache.updateMaxSize(newConfig.pictureCacheMaxSize);
    _pool.updateMaxSize(newConfig.barragePoolMaxSize);
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
    _waiting.add(item);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_initialized) return;

    _emitTimer += dt;
    if (_emitTimer >= _config.emitInterval) {
      _emitTimer = 0.0;
      _dispatchWaiting();
    }

    final int len = _activeEntries.length;
    final double fixedDurationSec = _config.fixedDurationMs / 1000.0;

    for (int i = 0; i < len; i++) {
      final entry = _activeEntries[i];
      if (!entry.active) continue;

      if (entry.item.type == BarrageType.scroll) {
        entry.x -= entry.speed * dt;
        if (entry.x + entry.width < 0) {
          entry.active = false;
        }
      } else {
        entry.lifeTime += dt;
        if (entry.lifeTime >= fixedDurationSec) {
          entry.active = false;
        }
      }
    }

    _cleanupTimer += dt;
    if (_cleanupTimer >= 0.5) {
      _cleanupTimer = 0.0;

      _backbufferEntries.clear();
      final int currentLen = _activeEntries.length;

      for (int i = 0; i < currentLen; i++) {
        final entry = _activeEntries[i];
        if (entry.active) {
          _backbufferEntries.add(entry);
        } else {
          _pool.recycle(entry);
        }
      }

      // 0 开销原地互换指针：完全避免了重新 new 数组的开销，GC 抖动彻底归 0，闪烁彻底死锁解决！
      final List<BarrageEntry> temp = _activeEntries;
      _activeEntries = _backbufferEntries;
      _backbufferEntries = temp;
    }

    _metricTimer += dt;
    if (_metricTimer >= 0.032) {
      _metricTimer = 0.0;
      _updateTrackMetrics();
    }
  }

  void _dispatchWaiting() {
    if (_waiting.isEmpty) return;

    int aliveCount = 0;
    final int currentLen = _activeEntries.length;
    for (int i = 0; i < currentLen; i++) {
      if (_activeEntries[i].active) aliveCount++;
    }
    if (aliveCount >= _config.maxVisibleCount) return;

    _trackManager.initialize(_config, size.y);
    if (_trackManager.tracks.isEmpty) return;

    final item = _waiting.first;
    final fragments = _parser.parse(item.content);
    final layoutResult = _layout.layout(fragments, item: item, config: _config);

    final mockEntry = _pool.obtain(item: item, creationTime: DateTime.now().millisecondsSinceEpoch)
      ..width = layoutResult.width
      ..height = layoutResult.height
      ..speed = item.type == BarrageType.scroll ? 100.0 : 0.0;

    final trackIndex = _trackAllocator.allocate(
      tracks: _trackManager.tracks,
      current: mockEntry,
      screenWidth: size.x,
      config: _config,
    );

    if (trackIndex == -1) {
      _pool.recycle(mockEntry);
      return;
    }

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
    mockEntry.picture = picture;
    mockEntry.active = true;

    mockEntry.speed = item.type == BarrageType.scroll
        ? _speedStrategy.calculate(mockEntry, size.x, _config, targetTrack: track)
        : 0.0;

    track.lastRight = startX + layoutResult.width;
    track.lastEntry = mockEntry;
    track.activeCount++;

    _activeEntries.add(mockEntry);
  }

  void _updateTrackMetrics() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final entryLen = _activeEntries.length;

    for (final track in _trackManager.tracks) {
      double totalSpeed = 0.0;
      int count = 0;
      BarrageEntry? youngestEntry;

      for (int i = 0; i < entryLen; i++) {
        final entry = _activeEntries[i];
        if (!entry.active) continue;
        if (entry.track == track.index) {
          totalSpeed += entry.speed;
          count++;
          if (youngestEntry == null || entry.x > youngestEntry.x) {
            youngestEntry = entry;
          }
        }
      }

      track.activeCount = count;
      track.avgSpeed = count == 0 ? 0.0 : totalSpeed / count;
      track.density = size.x > 0 ? (count * 150.0) / size.x : 0.0;

      if (youngestEntry != null) {
        track.lastRight = youngestEntry.x + youngestEntry.width;
        track.lastEntry = youngestEntry;
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

  void recycleComponent(BarrageEntry entry) {
    _pool.recycle(entry);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_initialized) return;

    final int len = _activeEntries.length;
    for (int i = 0; i < len; i++) {
      final entry = _activeEntries[i];
      if (!entry.active || entry.picture == null) continue;
      canvas.save();
      canvas.translate(entry.x, entry.y);
      canvas.drawPicture(entry.picture!);
      canvas.restore();
    }
  }

  void clear() {
    _waiting.clear();
    _pictureCache.clear();
    for (var e in _activeEntries) {
      _pool.recycle(e);
    }
    _activeEntries.clear();
    _backbufferEntries.clear();
    _pool.clear();
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
      config.emojiSize,
    ].join('');
  }

  @override
  void onRemove() {
    _waiting.clear();
    _pictureCache.clear();
    _trackManager.tracks.clear();
    for (var e in _activeEntries) {
      _pool.recycle(e);
    }
    _activeEntries.clear();
    _backbufferEntries.clear();
    _pool.clear();
    super.onRemove();
  }
}
