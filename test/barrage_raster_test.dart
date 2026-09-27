import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_barrage/flame_barrage.dart';

const BarrageConfig _baseConfig = BarrageConfig(
  fontSize: 20,
  trackHeight: 44,
  showStroke: true,
  emitInterval: 0.01,
  safeArea: false,
);

/// Captures whatever the engine draws for the current frame.
Future<ui.Image> _captureFrame(BarrageEngine engine) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 800, 600));
  engine.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(800, 600);
  picture.dispose();
  return image;
}

class _Stats {
  _Stats(this.opaque, this.bounds);

  final int opaque;
  final Rect? bounds;
}

Future<_Stats> _statsOf(ui.Image image) async {
  final data = await image.toByteData();
  var opaque = 0;
  double minX = double.infinity, minY = double.infinity, maxX = -1, maxY = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (data!.getUint8((y * image.width + x) * 4 + 3) < 8) continue;
      opaque++;
      if (x < minX) minX = x.toDouble();
      if (y < minY) minY = y.toDouble();
      if (x > maxX) maxX = x.toDouble();
      if (y > maxY) maxY = y.toDouble();
    }
  }
  return _Stats(opaque, maxX < 0 ? null : Rect.fromLTRB(minX, minY, maxX, maxY));
}

/// Rasterizing and reading pixels back is real asynchronous engine work, which
/// a widget test's fake clock never advances on its own.
Future<_Stats> _statsOfFrame(WidgetTester tester, BarrageEngine engine) async {
  final stats = await tester.runAsync(() async => _statsOf(await _captureFrame(engine)));
  return stats!;
}

Future<BarrageEngine> _pumpEngine(WidgetTester tester, BarrageConfig config, List<BarrageItem> items) async {
  final engine = BarrageEngine(config: config, emojiAtlas: EmojiAtlas.instance);
  await tester.pumpWidget(MaterialApp(home: GameWidget(game: engine)));
  await tester.pump();
  for (final item in items) {
    engine.pushMessage(item);
  }

  // The engine drives itself with its own Ticker: the first pulse only records
  // the vsync timestamp and the emit timer fires on a later one.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (items.isEmpty && engine.frameStepCount > 1) break;
    if (items.isNotEmpty && engine.activeCacheSize > 0) break;
  }
  if (items.isNotEmpty) {
    expect(engine.activeCacheSize, greaterThan(0), reason: 'messages were never dispatched');
  }
  return engine;
}

void main() {
  testWidgets('rasterized messages land where the vector fallback does', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    const content = '弹幕性能优化 ScrollingDanmaku 12345';

    final vectorEngine = await _pumpEngine(
      tester,
      _baseConfig.copyWith(rasterizeItems: false),
      const [BarrageItem(content: content, type: BarrageType.topFixed)],
    );
    expect(vectorEngine.rasterizationActive, isFalse);
    expect(vectorEngine.activeCacheSize, 1);
    expect(vectorEngine.rasterCacheBytes, 0);
    final vectorStats = await _statsOfFrame(tester, vectorEngine);
    expect(vectorStats.bounds, isNotNull);

    final rasterEngine = await _pumpEngine(
      tester,
      _baseConfig,
      const [BarrageItem(content: content, type: BarrageType.topFixed)],
    );
    expect(rasterEngine.rasterizationActive, isTrue);
    expect(rasterEngine.activeCacheSize, 1);
    expect(rasterEngine.rasterCacheBytes, greaterThan(0));
    final rasterStats = await _statsOfFrame(tester, rasterEngine);
    expect(rasterStats.bounds, isNotNull);

    // Same message, same lane: the bitmap path must place the text where the
    // vector path does, not merely draw something.
    final vectorBounds = vectorStats.bounds!;
    final rasterBounds = rasterStats.bounds!;
    expect((rasterBounds.left - vectorBounds.left).abs(), lessThan(2.0));
    expect((rasterBounds.top - vectorBounds.top).abs(), lessThan(2.0));
    expect((rasterBounds.width - vectorBounds.width).abs(), lessThan(2.0));
    expect((rasterBounds.height - vectorBounds.height).abs(), lessThan(2.0));
    expect(rasterStats.opaque, greaterThan(vectorStats.opaque * 0.7));
    expect(rasterStats.opaque, lessThan(vectorStats.opaque * 1.3));
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('repeated content shares one bitmap and is never evicted while visible', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    final engine = await _pumpEngine(tester, _baseConfig, const []);
    for (var i = 0; i < 6; i++) {
      engine.pushMessage(const BarrageItem(content: '666666 打卡', type: BarrageType.scroll));
    }
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (engine.activeCacheSize > 0) break;
    }

    // Six identical messages, one cached bitmap.
    expect(engine.activeCacheSize, 1);
    final bytes = engine.rasterCacheBytes;
    expect(bytes, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 500));
    expect(engine.rasterCacheBytes, bytes);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('bitmaps survive eviction while their messages are still on screen', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    // A cache far smaller than the on-screen message count: every dispatch has
    // to evict a bitmap that a visible message is still drawing.
    final engine = BarrageEngine(
      config: _baseConfig.copyWith(pictureCacheMaxSize: 2, emitInterval: 0.005),
      emojiAtlas: EmojiAtlas.instance,
    );
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: engine)));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      engine.pushMessage(BarrageItem(content: '互不相同的弹幕内容 #$i', type: BarrageType.topFixed));
    }
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (engine.activeCount >= 6) break;
    }

    expect(engine.activeCount, 6);
    expect(engine.activeCacheSize, lessThanOrEqualTo(2));
    // Default maxVisibleCount leaves room for all six; drawing them must not
    // touch a disposed Picture or Image.
    await tester.pump(const Duration(milliseconds: 33));
    expect(tester.takeException(), isNull);
    final stats = await _statsOfFrame(tester, engine);
    expect(stats.opaque, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('high density bakes at device resolution', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(1600, 1200);
    addTearDown(tester.view.reset);

    final engine = await _pumpEngine(
      tester,
      _baseConfig,
      const [BarrageItem(content: '高密度下也要清晰', type: BarrageType.topFixed)],
    );
    // Two device pixels per logical pixel: the bitmap covers twice the area per
    // side a 1x bake would.
    expect(engine.rasterCacheBytes, greaterThan(0));

    final lowDensity = await _pumpEngine(
      tester,
      _baseConfig,
      const [BarrageItem(content: '高密度下也要清晰', type: BarrageType.topFixed)],
    );
    expect(lowDensity.rasterCacheBytes, greaterThan(0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('disabling rasterization mid-flight keeps visible messages drawable', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    final engine = await _pumpEngine(
      tester,
      _baseConfig,
      const [BarrageItem(content: '先烘焙', type: BarrageType.topFixed)],
    );
    expect(engine.rasterCacheBytes, greaterThan(0));

    engine.updateConfig(_baseConfig.copyWith(rasterizeItems: false));
    engine.pushMessage(const BarrageItem(content: '再回退', type: BarrageType.topFixed));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(engine.rasterizationActive, isFalse);
    // The message that was already on screen keeps its bitmap: dropping it
    // mid-frame would throw on the next paint.
    expect(engine.rasterCacheBytes, greaterThan(0));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
