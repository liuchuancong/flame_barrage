import '../core/barrage_config.dart';
import '../model/barrage/barrage_entry.dart';
import '../model/barrage/barrage_track.dart';

class SpeedStrategy {
  const SpeedStrategy();

  double calculate(
    BarrageEntry entry,
    double screenWidth,
    BarrageConfig config, {
    BarrageTrack? targetTrack,
    bool massiveMode = false,
  }) {
    final distance = screenWidth + entry.width;
    double calculatedSpeed = (distance / config.scrollDuration.inMilliseconds) * 1000.0;

    if (massiveMode) {
      calculatedSpeed *= 1.3;
    }

    if (targetTrack != null) {
      final last = targetTrack.lastEntry;
      if (last != null && last.item.type == entry.item.type) {
        if (calculatedSpeed > last.speed) {
          calculatedSpeed = last.speed;
        }
      }
    }

    if (calculatedSpeed < config.baseSpeed) {
      calculatedSpeed = config.baseSpeed;
    }

    return calculatedSpeed;
  }
}
