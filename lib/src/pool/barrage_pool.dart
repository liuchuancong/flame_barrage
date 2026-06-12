import 'dart:ui';
import '../model/barrage/barrage_entry.dart';
import 'package:flame_barrage/src/components/barrage_component.dart';

class BarragePool {
  BarragePool({this.maxSize = 100});

  final int maxSize;
  final List<BarrageComponent> _pool = [];

  int get size => _pool.length;

  BarrageComponent obtain({required BarrageEntry entry, required Picture picture, required Duration fixedDuration}) {
    if (_pool.isNotEmpty) {
      final comp = _pool.removeLast();
      comp.reset(newEntry: entry, newPicture: picture, newFixedDuration: fixedDuration);
      return comp;
    }

    return BarrageComponent(entry: entry, picture: picture, fixedDuration: fixedDuration);
  }

  void recycle(BarrageComponent component) {
    if (_pool.length < maxSize) {
      _pool.add(component);
    }
  }

  void clear() {
    _pool.clear();
  }
}
