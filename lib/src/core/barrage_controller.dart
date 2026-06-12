import 'barrage_engine.dart';
import 'package:flame_barrage/flame_barrage.dart';

class BarrageController {
  BarrageEngine? _engine;
  final List<BarrageItem> _preInitQueue = [];

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

  void detach() {
    _engine = null;
  }

  void send(BarrageItem item) {
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
}
