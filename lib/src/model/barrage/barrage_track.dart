import 'package:flame_barrage/src/model/barrage/barrage_entry.dart';

class BarrageTrack {
  BarrageTrack({required this.index});

  final int index;

  /// Right edge of the youngest (rightmost) entry in this lane, in screen
  /// coordinates. Lane allocation uses it to decide whether the next message
  /// can enter without rear-ending the previous one.
  double lastRight = 0;

  /// Number of live entries currently assigned to this lane.
  int activeCount = 0;

  /// Set while a fixed (pinned) message occupies the lane; scroll messages
  /// must not enter a locked lane.
  bool locked = false;

  /// Monotonic engine time at which a fixed item releases this lane.
  int lockedUntil = 0;

  /// Engine time of the most recent launch into this lane.
  int lastLaunchTime = 0;

  /// Live entries in this lane, in dispatch order. Kept in sync by the data
  /// and motion systems so allocation never reads a recycled entry.
  final List<BarrageEntry> entries = [];

  BarrageEntry? lastEntry;

  /// Adds [entry] and refreshes the lane's right-edge metrics immediately.
  /// The metrics pass still aggregates means, but allocation no longer waits
  /// for its next 32 ms tick to see a newly launched message.
  void attach(BarrageEntry entry) {
    entries.add(entry);
    activeCount = entries.length;
    final current = lastEntry;
    if (current == null || entry.x >= current.x) {
      lastEntry = entry;
      lastRight = entry.x + entry.width;
    }
  }

  /// Removes [entry] and recomputes the rightmost survivor. A non-rightmost
  /// removal leaves [lastEntry] untouched; the rightmost one promotes the
  /// next entry instead of leaving a stale (possibly recycled) pointer.
  void detach(BarrageEntry entry) {
    if (!entries.remove(entry)) return;
    activeCount = entries.length;
    BarrageEntry? rightmost;
    for (final candidate in entries) {
      if (rightmost == null || candidate.x > rightmost.x) rightmost = candidate;
    }
    lastEntry = rightmost;
    lastRight = rightmost == null ? 0.0 : rightmost.x + rightmost.width;
  }

  /// Drops every entry reference without touching their objects.
  void clearEntries() {
    entries.clear();
    activeCount = 0;
    lastEntry = null;
    lastRight = 0.0;
  }

  /// Mean scroll speed of this lane's live entries, updated by the metrics
  /// system a few times per second. Feeds the lane-penalty heuristic.
  double avgSpeed = 0;

  /// Rough occupancy ratio of this lane relative to the screen width.
  double density = 0;
}
