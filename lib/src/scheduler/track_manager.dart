import 'package:flame_barrage/flame_barrage.dart';

class TrackManager {
  final List<BarrageTrack> tracks = [];

  void initialize(BarrageConfig config, double height) {
    tracks.clear();

    final availableHeight = height * config.area;
    final count = (availableHeight / config.trackHeight).floor();
    final trackCount = count.clamp(1, config.maxTrackCount);

    for (var i = 0; i < trackCount; i++) {
      tracks.add(BarrageTrack(index: i));
    }
  }

  void clear() {
    tracks.clear();
  }
}
