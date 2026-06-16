import 'package:flame_barrage/flame_barrage.dart';

class BarrageController {
  BarrageEngine? _engine;
  final List<BarrageItem> _preInitQueue = [];
  int _totalEmittedCount = 0;

  dynamic get engine => _engine;

  void attach(BarrageEngine engine) {
    _engine = engine;
    if (_preInitQueue.isNotEmpty) {
      final len = _preInitQueue.length;
      for (int i = 0; i < len; i++) {
        _engine?.pushMessage(_preInitQueue[i]);
      }
      _preInitQueue.clear();
    }
  }

  void Function(int cacheCount, int poolSize)? onMetricsUpdated;

  void detach() {
    _engine = null;
  }

  void send(BarrageItem item) {
    _totalEmittedCount++;
    if (_engine != null) {
      _engine!.pushMessage(item);
    } else {
      _preInitQueue.add(item);
    }
  }

  void clear() {
    _engine?.clear();
    _preInitQueue.clear();
  }

  int get totalEmitted => _totalEmittedCount;

  int get pictureCacheCount {
    final currentEngine = _engine;
    if (currentEngine != null) {
      return currentEngine.activeCacheSize;
    }
    return 0;
  }

  int get poolObjectCount {
    final currentEngine = _engine;
    if (currentEngine != null) {
      return currentEngine.activePoolSize;
    }
    return 0;
  }
}
