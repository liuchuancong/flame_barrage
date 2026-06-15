import 'package:flame_barrage/src/model/barrage/barrage_entry.dart';

class OverlapDetector {
  const OverlapDetector();

  bool canEnter(BarrageEntry current, BarrageEntry last, double screenWidth, {required double safeGap}) {
    final lastTailX = last.x + last.width;

    if (lastTailX + safeGap > screenWidth) {
      return false;
    }

    if (current.speed > last.speed) {
      final lastRemainingTime = lastTailX / last.speed;
      final relativeDistance = screenWidth - lastTailX + safeGap;
      final catchUpTime = relativeDistance / (current.speed - last.speed);

      if (catchUpTime < lastRemainingTime) {
        return false;
      }
    }

    return true;
  }
}
