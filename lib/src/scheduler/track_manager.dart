import 'overlap_detector.dart';
import 'package:flame_barrage/flame_barrage.dart';
import 'package:flame_barrage/src/model/barrage/barrage_entry.dart';

class TrackManager {
  final List<BarrageTrack> tracks = [];
  final OverlapDetector _detector = const OverlapDetector();

  void initialize(BarrageConfig config, double height) {
    tracks.clear();

    final availableHeight = height * config.area;

    final count = (availableHeight / config.trackHeight).floor();

    final trackCount = count.clamp(1, config.maxTrackCount);

    for (var i = 0; i < trackCount; i++) {
      tracks.add(BarrageTrack(index: i));
    }
  }

  int allocateTrack(BarrageEntry current, double screenWidth) {
    if (tracks.isEmpty) {
      return -1;
    }

    int bestTrackIndex = -1;
    double maxDistance = -1.0;

    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      final lastEntry = track.lastEntry;

      if (lastEntry == null) {
        return i;
      }

      if (_detector.canEnter(current, lastEntry, screenWidth)) {
        final distance = screenWidth - (lastEntry.x + lastEntry.width);
        if (distance > maxDistance) {
          maxDistance = distance;
          bestTrackIndex = i;
        }
      }
    }

    if (bestTrackIndex != -1) {
      tracks[bestTrackIndex].lastEntry = current;
    }

    return bestTrackIndex;
  }

  void updateTrackStates(double screenWidth) {
    final len = tracks.length;
    for (int i = 0; i < len; i++) {
      final track = tracks[i];
      final last = track.lastEntry;
      if (last != null && last.x + last.width < 0) {
        track.lastEntry = null;
      }
    }
  }
}
