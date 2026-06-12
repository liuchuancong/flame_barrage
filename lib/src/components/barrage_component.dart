import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_barrage/flame_barrage.dart';
import 'package:flame_barrage/src/model/barrage/barrage_entry.dart';

class BarrageComponent extends PositionComponent {
  BarrageComponent({required this.entry, required this.picture, required this.fixedDuration}) {
    size = Vector2(entry.width, entry.height);
    position = Vector2(entry.x, entry.y);
  }

  BarrageEntry entry;
  Picture picture;
  Duration fixedDuration;
  double _lifeTimer = 0.0;

  void reset({required BarrageEntry newEntry, required Picture newPicture, required Duration newFixedDuration}) {
    entry = newEntry;
    picture = newPicture;
    fixedDuration = newFixedDuration;
    _lifeTimer = 0.0;

    size.setValues(newEntry.width, newEntry.height);
    position.setValues(newEntry.x, newEntry.y);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (entry.item.type == BarrageType.scroll) {
      position.x -= entry.speed * dt;
      entry.x = position.x;

      if (position.x + size.x < 0) {
        removeFromParent();
      }
    } else {
      _lifeTimer += dt;
      if (_lifeTimer >= fixedDuration.inMilliseconds / 1000.0) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPicture(picture);
  }
}
