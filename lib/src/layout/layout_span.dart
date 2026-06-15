import 'dart:ui' as ui;

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
