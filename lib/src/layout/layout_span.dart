import 'dart:ui' as ui;
import 'package:flame_barrage/src/animation/sprite_animation_player.dart';

abstract class LayoutSpan {
  const LayoutSpan({required this.x, required this.y, required this.width, required this.height});

  final double x;
  final double y;
  final double width;
  final double height;

  void paint(ui.Canvas canvas);
}

class TextLayoutSpan extends LayoutSpan {
  const TextLayoutSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required this.text,
    required this.paragraph,
  });

  final String text;
  final ui.Paragraph paragraph;

  @override
  void paint(ui.Canvas canvas) {
    canvas.drawParagraph(paragraph, ui.Offset(x, y));
  }
}

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
