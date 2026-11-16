import '../core/barrage_config.dart';
import '../model/barrage/barrage_track.dart';
import '../model/barrage/barrage_entry.dart';

/// Anti-tailgating speed clamp for scroll messages sharing a lane.
class SpeedStrategy {
  const SpeedStrategy();

  double calculate(
    BarrageEntry current,
    double screenWidth,
    BarrageConfig config, {
    required BarrageTrack targetTrack,
    double? candidateSpeed,
  }) {
    final desired = candidateSpeed ?? config.baseSpeed;
    final last = targetTrack.lastEntry;
    if (last == null) {
      return desired;
    }

    if (desired <= last.speed) {
      return desired;
    }

    // A stationary (or non-positive-speed) predecessor must not take part in
    // the clamp. Dividing by last.speed == 0 yields +Infinity, which makes
    // maxAllowedSpeed collapse to last.speed (0) and clamps every follower
    // to last.speed * 0.95 — also 0. The whole lane then freezes: messages
    // stop moving (retirement only fires once `x + width < 0`), pile up on
    // screen, and every message dispatched into that lane afterwards
    // inherits the frozen speed. A zero-speed seed is easy to hit when a
    // layout width comes back 0 (e.g. web font not ready yet) or when a
    // fixed message briefly shares bookkeeping with the lane, so treat
    // non-positive predecessor speed as "no clamp information" and let the
    // desired speed through.
    if (last.speed <= 0) {
      return desired;
    }

    final double lastRight = targetTrack.lastRight;
    final double catchUpDistance = screenWidth - lastRight;
    final double lastRemainingTime = lastRight / last.speed;

    if (lastRemainingTime <= 0) {
      return desired;
    }

    final double maxAllowedSpeed =
        last.speed + (catchUpDistance / lastRemainingTime);
    if (desired > maxAllowedSpeed) {
      // Never clamp a scrolling message below a positive floor: a follower
      // slower than its predecessor simply trails it, which is fine, but
      // stopping dead is what used to freeze the lane.
      final double floor = last.speed * 0.95;
      return floor > 0 ? floor : desired;
    }

    return desired;
  }
}
