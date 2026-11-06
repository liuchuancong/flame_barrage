import 'dart:math' as math;

/// Viewport-based scroll timing.
///
/// A message's crossing time is not a constant: the viewport width selects a
/// window of min/max seconds and the message's width relative to the viewport
/// blends within it. The resulting speed is `(viewport + textWidth) /
/// duration`, so a wide message and a narrow one take visibly different times
/// to cross while their on-screen speed stays in the same band.
abstract final class ScrollTiming {
  /// Width boundaries with the duration range used below that boundary.
  static const List<({double boundary, double maxTime, double minTime})>
  _stops = [
    (boundary: 558, maxTime: 13, minTime: 7),
    (boundary: 888, maxTime: 14, minTime: 8),
    (boundary: 1082, maxTime: 14, minTime: 9),
    (boundary: 1246, maxTime: 15, minTime: 10),
    (boundary: 1452, maxTime: 16, minTime: 11),
    (boundary: 1744, maxTime: 18, minTime: 13),
    (boundary: 2314, maxTime: 20, minTime: 14),
    (boundary: 2560, maxTime: 22, minTime: 16),
  ];

  /// The fallback for containers narrower than the table's first stop.
  static const double fallbackDuration = 4.5;

  /// How many seconds a message of [textWidth] needs to cross
  /// [viewportWidth] in the adaptive live-style rhythm.
  static double durationFor({
    required double viewportWidth,
    required double textWidth,
  }) {
    if (viewportWidth <= 0 || textWidth <= 0) return fallbackDuration;
    if (viewportWidth < _stops.first.boundary) return fallbackDuration;

    double minTime;
    double maxTime;
    if (viewportWidth > _stops.last.boundary) {
      final extra = ((viewportWidth - _stops.last.boundary) / 500)
          .floorToDouble();
      minTime = _stops.last.minTime + extra;
      maxTime = _stops.last.maxTime + extra;
    } else {
      minTime = _stops.last.minTime;
      maxTime = _stops.last.maxTime;
      for (var index = 1; index < _stops.length; index++) {
        if (viewportWidth <= _stops[index].boundary) {
          minTime = _stops[index - 1].minTime;
          maxTime = _stops[index - 1].maxTime;
          break;
        }
      }
    }

    // A smooth blend: the ratio picks a point between the stop's min and max
    // times. For ordinary message widths it sits close to the minimum; very
    // wide messages approach the maximum.
    final ratio = textWidth / viewportWidth;
    final curve = (maxTime - minTime) / 0.1 - 1;
    if (curve <= 0) return minTime;
    final midpoint = math.log(curve) / 0.2 + 0.2;
    final value =
        minTime +
        (maxTime - minTime) / (1 + math.exp(-0.2 * (ratio - midpoint)));
    return value.isFinite && value > 0 ? value : fallbackDuration;
  }

  /// The pixels-per-second speed that crosses the screen and the message in
  /// [duration], scaled by [speedPlus].
  static double speedFor({
    required double viewportWidth,
    required double textWidth,
    required double duration,
    double speedPlus = 1.0,
  }) {
    final seconds = duration > 0 ? duration : fallbackDuration;
    return (viewportWidth + textWidth) / seconds * speedPlus;
  }
}
