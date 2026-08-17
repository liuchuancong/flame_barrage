import '../core/barrage_config.dart';
import '../model/barrage/barrage_track.dart';
import '../model/barrage/barrage_entry.dart';

class SpeedStrategy {
  const SpeedStrategy();

  double positionFactor(int trackIndex, int totalTrackCount) {
    if (totalTrackCount <= 1) return 1.0;
    final step = 0.4 / (totalTrackCount - 1);
    return 0.8 + trackIndex * step;
  }

  double crowdPenalty(int activeCount) {
    if (activeCount <= 0) return 1.0;
    if (activeCount == 1) return 0.98;
    if (activeCount == 2) return 0.92;
    if (activeCount >= 3) return 0.82;
    return 1.0;
  }

  double calculate(
    BarrageEntry current,
    double screenWidth,
    BarrageConfig config, {
    required BarrageTrack targetTrack,
    required int totalTrackCount,
  }) {
    final last = targetTrack.lastEntry;
    double rawSpeed;

    if (last == null) {
      rawSpeed = config.baseSpeed;
    } else if (config.baseSpeed <= last.speed) {
      rawSpeed = config.baseSpeed;
    } else {
      final double lastRight = targetTrack.lastRight;
      final double catchUpDistance = screenWidth - lastRight;
      final double lastRemainingTime = lastRight / last.speed;

      if (lastRemainingTime <= 0) {
        rawSpeed = config.baseSpeed;
      } else {
        final double maxAllowedSpeed = last.speed + (catchUpDistance / lastRemainingTime);
        if (config.baseSpeed > maxAllowedSpeed) {
          rawSpeed = last.speed * 0.95;
        } else {
          rawSpeed = config.baseSpeed;
        }
      }
    }

    if (config.useUniformSpeed) {
      return rawSpeed;
    }
    final posFactor = positionFactor(targetTrack.index, totalTrackCount);
    final crowdFactor = crowdPenalty(targetTrack.activeCount);
    final finalFactor = posFactor * crowdFactor;

    return rawSpeed * finalFactor;
  }
}
