import 'overlap_detector.dart';
import 'package:flame_barrage/src/model/barrage/barrage_track.dart';
import 'package:flame_barrage/src/model/barrage/barrage_entry.dart';

class TrackAllocator {
  const TrackAllocator({this.detector = const OverlapDetector()});

  final OverlapDetector detector;

  int allocate({
    required List<BarrageTrack> tracks,
    required BarrageEntry current,
    required double screenWidth,
    required bool massiveMode,
  }) {
    int bestIndex = -1;
    double bestScore = double.infinity;

    final len = tracks.length;
    for (int i = 0; i < len; i++) {
      final track = tracks[i];

      if (track.locked) {
        continue;
      }

      if (!massiveMode && track.activeCount >= 10) {
        continue;
      }

      final last = track.lastEntry;
      if (last != null) {
        if (!detector.canEnter(current, last, screenWidth)) {
          continue;
        }
      }

      final lastRight = last != null ? (last.x + last.width) : 0.0;
      final safeGap = screenWidth - lastRight;

      final densityPenalty = track.density * 100.0;
      final speedPenalty = (1.0 / (track.avgSpeed + 1.0)) * 50.0;
      final score = densityPenalty + speedPenalty - safeGap;

      if (score < bestScore) {
        bestScore = score;
        bestIndex = track.index;
      }
    }

    return bestIndex;
  }
}
