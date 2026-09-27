import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_barrage/flame_barrage.dart';

ui.Picture _picture() {
  final recorder = ui.PictureRecorder();
  Canvas(recorder, const Rect.fromLTWH(0, 0, 64, 32)).drawRect(
    const Rect.fromLTWH(0, 0, 64, 32),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  return recorder.endRecording();
}

Future<ui.Image> _image() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder, const Rect.fromLTWH(0, 0, 64, 32)).drawRect(
    const Rect.fromLTWH(0, 0, 64, 32),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 32);
  picture.dispose();
  return image;
}

void main() {
  test('an evicted entry stays alive while a barrage still draws it', () async {
    final cache = RenderCache(maxSize: 1, maxBytes: 1 << 20);
    final first = CachedRender(picture: _picture())..image = await _image();
    final dispatched = cache.put('a', first);

    // A second visible message with the same content takes its own reference.
    final acquired = cache.acquire('a');
    expect(acquired, same(first));

    // A third message pushes the cache over its entry budget.
    cache.put('b', CachedRender(picture: _picture()));
    expect(cache.size, 1);

    // The evicted entry is no longer cached but must remain usable, otherwise
    // every later frame throws while drawing it.
    cache.release(dispatched);
    expect(first.isDisposed, isFalse);
    expect(first.image, isNotNull);
    final image = first.image!;
    expect(image.debugDisposed, isFalse);

    cache.release(acquired);
    expect(first.isDisposed, isTrue);
    expect(image.debugDisposed, isTrue);
  });

  test('a render handed out by put survives eviction of its own key', () async {
    final cache = RenderCache(maxSize: 1, maxBytes: 1 << 20);
    // The reference put returns is what a freshly dispatched barrage draws.
    final render = cache.put('a', CachedRender(picture: _picture())..image = await _image());

    cache.put('b', CachedRender(picture: _picture()));
    expect(render.isDisposed, isFalse);
    expect(render.image!.debugDisposed, isFalse);

    cache.release(render);
    expect(render.isDisposed, isTrue);
  });

  test('put and acquire each hand back one owned reference', () async {
    final cache = RenderCache(maxSize: 4, maxBytes: 1 << 20);
    final render = CachedRender(picture: _picture());
    final fromPut = cache.put('a', render);
    final fromAcquire = cache.acquire('a');
    expect(fromPut, same(fromAcquire));

    // Two callers plus the cache: dropping one leaves it usable.
    cache.release(fromPut);
    expect(render.isDisposed, isFalse);
    // Clearing drops the cache's own reference; the last caller still draws it.
    cache.clear();
    expect(render.isDisposed, isFalse);
    cache.release(fromAcquire);
    expect(render.isDisposed, isTrue);
  });

  test('clear keeps entries that are still in use and disposes the rest', () async {
    final cache = RenderCache(maxSize: 8, maxBytes: 1 << 20);
    final held = CachedRender(picture: _picture());
    final dropped = CachedRender(picture: _picture());
    final heldByBarrage = cache.put('held', held);
    cache.put('dropped', dropped);
    final acquired = cache.acquire('held');

    cache.clear();
    expect(cache.size, 0);
    expect(dropped.isDisposed, isFalse, reason: 'the reference put returned is still owned');
    cache.release(dropped);
    expect(dropped.isDisposed, isTrue);
    expect(held.isDisposed, isFalse);
    // Does not throw: the engine still draws what the cache dropped.
    expect(held.picture.approximateBytesUsed, greaterThan(0));

    cache.release(heldByBarrage);
    cache.release(acquired);
    expect(held.isDisposed, isTrue);
  });

  test('the byte budget evicts least recently used entries first', () async {
    final image = await _image();
    final bytes = image.width * image.height * 4;

    final cache = RenderCache(maxSize: 32, maxBytes: bytes * 2);
    final a = CachedRender(picture: _picture())..image = image;
    final b = CachedRender(picture: _picture())..image = await _image();
    final aRef = cache.put('a', a);
    final bRef = cache.put('b', b);
    expect(cache.byteSize, bytes * 2);

    // Touching 'a' makes 'b' the eviction candidate.
    cache.release(cache.acquire('a'));
    final c = CachedRender(picture: _picture())..image = await _image();
    cache.put('c', c);

    expect(a.isDisposed, isFalse);
    // 'b' left the cache; its own owner (the barrage, here the test) still holds
    // it, so it is dropped only when that owner releases it.
    cache.release(bRef);
    expect(b.isDisposed, isTrue);
    expect(cache.acquire('a'), isNotNull);
    expect(cache.acquire('b'), isNull);
    expect(cache.byteSize, lessThanOrEqualTo(bytes * 2));
    cache.release(aRef);
  });

  test('reports approximate GPU memory of the cached bitmaps', () async {
    final cache = RenderCache(maxSize: 8, maxBytes: 1 << 20);
    expect(cache.byteSize, 0);
    final render = CachedRender(picture: _picture())..image = await _image();
    final ref = cache.put('a', render);
    expect(cache.byteSize, 64 * 32 * 4);
    cache.clear();
    expect(cache.byteSize, 0);
    cache.release(ref);
  });
}
