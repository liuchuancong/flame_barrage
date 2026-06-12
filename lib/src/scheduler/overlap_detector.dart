import 'package:flame_barrage/src/model/barrage/barrage_entry.dart';

class OverlapDetector {
  const OverlapDetector({this.safeGap = 40.0});

  final double safeGap;

  bool canEnter(BarrageEntry current, BarrageEntry last, double screenWidth) {
    final lastTailX = last.x + last.width;

    if (lastTailX + safeGap > screenWidth) {
      return false;
    }

    if (current.speed > last.speed) {
      final lastRemainingTime = (last.x + last.width) / last.speed;
      final catchUpTime = last.x / (current.speed - last.speed);

      if (catchUpTime < lastRemainingTime) {
        return false;
      }
    }

    return true;
  }
}
