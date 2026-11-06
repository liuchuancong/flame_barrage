import 'package:flutter_test/flutter_test.dart';

import 'package:flame_barrage/src/core/barrage_config.dart';
import 'package:flame_barrage/src/model/barrage/barrage_entry.dart';
import 'package:flame_barrage/src/model/barrage/barrage_item.dart';
import 'package:flame_barrage/src/model/barrage/barrage_track.dart';
import 'package:flame_barrage/src/scheduler/scroll_timing.dart';
import 'package:flame_barrage/src/scheduler/speed_strategy.dart';
import 'package:flame_barrage/src/scheduler/track_allocator.dart';

BarrageEntry _entry(
  String content, {
  double x = 0,
  double width = 100,
  double speed = 0,
}) {
  return BarrageEntry(item: BarrageItem(content: content), creationTime: 0)
    ..x = x
    ..width = width
    ..speed = speed;
}

void main() {
  group('ScrollTiming', () {
    test('a 1080p viewport uses the 13–18 s band for ordinary messages', () {
      final duration = ScrollTiming.durationFor(
        viewportWidth: 1920,
        textWidth: 300,
      );

      expect(duration, closeTo(13.1, 0.2));
      expect(
        ScrollTiming.speedFor(
          viewportWidth: 1920,
          textWidth: 300,
          duration: duration,
        ),
        closeTo(169.5, 2.0),
      );
    });

    test('a 720p viewport is faster than the old 120 px/s constant', () {
      final duration = ScrollTiming.durationFor(
        viewportWidth: 1280,
        textWidth: 300,
      );

      expect(duration, closeTo(10.1, 0.2));
      expect(
        ScrollTiming.speedFor(
          viewportWidth: 1280,
          textWidth: 300,
          duration: duration,
        ),
        closeTo(156.4, 2.0),
      );
    });

    test('a phone-width viewport keeps the 4.5 s fallback', () {
      expect(ScrollTiming.durationFor(viewportWidth: 375, textWidth: 150), 4.5);
      expect(
        ScrollTiming.speedFor(
          viewportWidth: 375,
          textWidth: 150,
          duration: 4.5,
        ),
        closeTo(116.7, 0.2),
      );
    });

    test('a wider message stays longer in the same viewport', () {
      final narrow = ScrollTiming.durationFor(
        viewportWidth: 1920,
        textWidth: 100,
      );
      final wide = ScrollTiming.durationFor(
        viewportWidth: 1920,
        textWidth: 1800,
      );

      expect(wide, greaterThan(narrow));
    });

    test('an invalid width falls back instead of dividing by zero', () {
      expect(ScrollTiming.durationFor(viewportWidth: 0, textWidth: 100), 4.5);
      expect(ScrollTiming.durationFor(viewportWidth: 1920, textWidth: 0), 4.5);
    });

    test('speedPlus scales the adaptive speed uniformly', () {
      final base = ScrollTiming.speedFor(
        viewportWidth: 1920,
        textWidth: 300,
        duration: 13.1,
      );
      final fast = ScrollTiming.speedFor(
        viewportWidth: 1920,
        textWidth: 300,
        duration: 13.1,
        speedPlus: 1.5,
      );

      expect(fast, closeTo(base * 1.5, 0.001));
    });
  });

  group('SpeedStrategy', () {
    const strategy = SpeedStrategy();
    const config = BarrageConfig();

    test('an empty lane keeps the candidate speed', () {
      final track = BarrageTrack(index: 0);
      expect(
        strategy.calculate(
          _entry('a'),
          1000,
          config,
          targetTrack: track,
          candidateSpeed: 180,
        ),
        180,
      );
    });

    test('a candidate that cannot catch the leader keeps its speed', () {
      final track = BarrageTrack(index: 0);
      final leader = _entry('leader', x: 200, width: 300, speed: 100);
      track.attach(leader);

      // 500 px of clearance and 5 s until the leader's tail exits allow up to
      // 200 px/s; 150 is safe.
      expect(
        strategy.calculate(
          _entry('follower'),
          1000,
          config,
          targetTrack: track,
          candidateSpeed: 150,
        ),
        150,
      );
    });

    test('a candidate that would rear-end the leader is capped', () {
      final track = BarrageTrack(index: 0);
      final leader = _entry('leader', x: 200, width: 300, speed: 100);
      track.attach(leader);

      expect(
        strategy.calculate(
          _entry('follower'),
          1000,
          config,
          targetTrack: track,
          candidateSpeed: 260,
        ),
        closeTo(95, 0.001),
      );
    });

    test('a candidate no faster than the leader keeps its speed', () {
      final track = BarrageTrack(index: 0);
      final leader = _entry('leader', x: 200, width: 300, speed: 180);
      track.attach(leader);

      expect(
        strategy.calculate(
          _entry('follower'),
          1000,
          config,
          targetTrack: track,
          candidateSpeed: 120,
        ),
        120,
      );
    });
  });

  group('TrackAllocator with live lane entries', () {
    const allocator = TrackAllocator();
    const config = BarrageConfig();

    test('empty lanes are chosen by least-recent launch, not topmost', () {
      final tracks = [
        BarrageTrack(index: 0)..lastLaunchTime = 50,
        BarrageTrack(index: 1)..lastLaunchTime = 10,
        BarrageTrack(index: 2)..lastLaunchTime = 30,
      ];

      expect(
        allocator.allocate(
          tracks: tracks,
          current: _entry('new'),
          screenWidth: 1000,
          config: config,
        ),
        1,
      );
    });

    test('locked lanes are skipped', () {
      final tracks = [
        BarrageTrack(index: 0)..locked = true,
        BarrageTrack(index: 1),
      ];

      expect(
        allocator.allocate(
          tracks: tracks,
          current: _entry('new'),
          screenWidth: 1000,
          config: config,
        ),
        1,
      );
    });

    test(
      'a lane whose youngest tail is still on the right edge is skipped',
      () {
        final blocked = BarrageTrack(index: 0);
        blocked.attach(_entry('blocked', x: 900, width: 200));
        final open = BarrageTrack(index: 1);
        open.attach(_entry('open', x: 100, width: 200));

        expect(
          allocator.allocate(
            tracks: [blocked, open],
            current: _entry('new'),
            screenWidth: 1000,
            config: config,
          ),
          1,
        );
      },
    );

    test(
      'the busiest lane is not preferred when a quieter one has more room',
      () {
        final roomy = BarrageTrack(index: 0);
        roomy.attach(_entry('roomy', x: 100, width: 200));
        final tight = BarrageTrack(index: 1);
        tight.attach(_entry('tight', x: 600, width: 200));

        expect(
          allocator.allocate(
            tracks: [roomy, tight],
            current: _entry('new'),
            screenWidth: 1000,
            config: config,
          ),
          0,
        );
      },
    );

    test('no eligible lane answers -1', () {
      final tracks = [
        BarrageTrack(index: 0)..locked = true,
        BarrageTrack(index: 1),
      ];
      tracks[1].attach(_entry('jam', x: 900, width: 200));

      expect(
        allocator.allocate(
          tracks: tracks,
          current: _entry('new'),
          screenWidth: 1000,
          config: config,
        ),
        -1,
      );
    });
  });

  group('BarrageTrack entries', () {
    test('detaching the rightmost promotes the next survivor', () {
      final track = BarrageTrack(index: 0);
      final left = _entry('left', x: 100, width: 80);
      final right = _entry('right', x: 400, width: 80);
      track
        ..attach(left)
        ..attach(right);

      expect(track.lastEntry, same(right));
      expect(track.activeCount, 2);

      track.detach(right);

      expect(track.lastEntry, same(left));
      expect(track.lastRight, 180);
      expect(track.activeCount, 1);
    });

    test('detaching a non-rightmost entry keeps the right edge', () {
      final track = BarrageTrack(index: 0);
      final left = _entry('left', x: 100, width: 80);
      final right = _entry('right', x: 400, width: 80);
      track
        ..attach(left)
        ..attach(right);

      track.detach(left);

      expect(track.lastEntry, same(right));
      expect(track.lastRight, 480);
      expect(track.activeCount, 1);
    });

    test('clearEntries drops every reference', () {
      final track = BarrageTrack(index: 0)..attach(_entry('a'));
      track.clearEntries();

      expect(track.entries, isEmpty);
      expect(track.lastEntry, isNull);
      expect(track.lastRight, 0);
      expect(track.activeCount, 0);
    });
  });
}
