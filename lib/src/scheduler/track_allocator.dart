import '../core/barrage_config.dart';
import '../model/barrage/barrage_track.dart';
import '../model/barrage/barrage_entry.dart';

class TrackAllocator {
  const TrackAllocator();

  int allocate({
    required List<BarrageTrack> tracks,
    required BarrageEntry current,
    required double screenWidth,
    required BarrageConfig config,
  }) {
    if (tracks.isEmpty) return -1;

    // An empty lane is always usable: pick the one that has waited longest
    // since its last launch, not simply the topmost, so a cold start and a
    // draining screen spread launches across the lane stack.
    int emptyTrack = -1;
    // A busy lane is usable once its youngest message has cleared the right
    // edge by the safe gap. Among those, the largest clearance wins: that
    // keeps launches flowing to the emptiest row instead of clumping on the
    // first row that happens to fit.
    int bestTrack = -1;
    double bestClearance = -1.0;

    final int len = tracks.length;
    for (int i = 0; i < len; i++) {
      final track = tracks[i];
      if (track.locked) continue;

      if (track.entries.isEmpty) {
        if (emptyTrack == -1 ||
            track.lastLaunchTime < tracks[emptyTrack].lastLaunchTime ||
            (track.lastLaunchTime == tracks[emptyTrack].lastLaunchTime &&
                track.index < tracks[emptyTrack].index)) {
          emptyTrack = i;
        }
        continue;
      }

      final last = track.lastEntry;
      if (last == null) continue;
      final lastRight = last.x + last.width;
      final clearance = screenWidth - lastRight;
      if (clearance < config.overlapSafeGap) continue;

      if (clearance > bestClearance) {
        bestClearance = clearance;
        bestTrack = i;
      }
    }

    return emptyTrack != -1 ? emptyTrack : bestTrack;
  }
}
