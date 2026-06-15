import 'dart:ui';
import 'package:flame_barrage/flame_barrage.dart';

class BarrageItem {
  const BarrageItem({
    required this.content,
    this.type = BarrageType.scroll,
    this.userId,
    this.userName,
    this.priority = 0,

    this.cachedFragments,
    this.cachedLayout,
    this.cachedPicture,
    this.onTapDown,
    this.onLongTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  final String content;
  final BarrageType type;
  final String? userId;
  final String? userName;
  final int priority;

  final List<Fragment>? cachedFragments;

  final LayoutResult? cachedLayout;

  final Picture? cachedPicture;
  final void Function()? onTapDown;
  final void Function()? onLongTapDown;
  final void Function()? onTapUp;
  final void Function()? onTapCancel;
}
