import '../core/barrage_config.dart';
import '../model/barrage/barrage_track.dart';
import '../model/barrage/barrage_entry.dart';

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

    final double lastRight = targetTrack.lastRight;
    final double catchUpDistance = screenWidth - lastRight;
    final double lastRemainingTime = lastRight / last.speed;

    if (lastRemainingTime <= 0) {
      return desired;
    }

    final double maxAllowedSpeed =
        last.speed + (catchUpDistance / lastRemainingTime);
    if (desired > maxAllowedSpeed) {
      return last.speed * 0.95;
    }

    return desired;
  }
}
