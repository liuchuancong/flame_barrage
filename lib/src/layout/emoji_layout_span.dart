import 'dart:ui' as ui;
import 'layout_span.dart';
import '../animation/sprite_animation_player.dart';

class EmojiLayoutSpan extends LayoutSpan {
  const EmojiLayoutSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required this.image,
    this.player,
  });

  final ui.Image image;
  final SpriteAnimationPlayer? player;

  @override
  void paint(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.medium;

    final dstRect = ui.Rect.fromLTWH(x, y, width, height);

    if (player != null) {
      player!.paint(canvas, dstRect, paint);
    } else {
      final srcRect = ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      canvas.drawImageRect(image, srcRect, dstRect, paint);
    }
  }
}
