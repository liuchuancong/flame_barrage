import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class EffectsPreviewScreen extends StatefulWidget {
  const EffectsPreviewScreen({super.key});

  @override
  State<EffectsPreviewScreen> createState() => _EffectsPreviewScreenState();
}

class _EffectsPreviewScreenState extends State<EffectsPreviewScreen> {
  final BarrageController _controller = BarrageController();
  final TextEditingController _textController = TextEditingController();
  late final BarrageConfig _config;

  @override
  void initState() {
    super.initState();
    _config = const BarrageConfig(
      trackHeight: 44,
      fontSize: 20,
      showStroke: true,
      effectInterceptors: [StrokeInterceptor(), ShadowInterceptor(), GlowInterceptor(), RainbowInterceptor()],
    );
  }

  void _sendNormalBarrage() {
    if (_textController.text.trim().isEmpty) return;
    _controller.send(BarrageItem(content: _textController.text.trim(), type: BarrageType.scroll, priority: 0));
    _textController.clear();
  }

  void _sendEffectBarrage(String effectTag) {
    final String content = _textController.text.trim().isEmpty
        ? 'A VIP sent a [$effectTag] effect barrage! 🚀'
        : _textController.text.trim();

    _controller.send(BarrageItem(content: '$effectTag::$content', type: BarrageType.scroll, priority: 1));
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visual Effects Gallery')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: FlameBarrageWidget(config: _config, emojiAtlas: EmojiAtlas.instance, controller: _controller),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Type custom text, pick an effect below...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _sendNormalBarrage, child: const Text('Plain')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                        onPressed: () => _sendEffectBarrage('Outline'),
                        icon: const Icon(Icons.border_color, size: 16),
                        label: const Text('Outline'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        onPressed: () => _sendEffectBarrage('Shadow'),
                        icon: const Icon(Icons.layers, size: 16),
                        label: const Text('Shadow'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                        onPressed: () => _sendEffectBarrage('Neon'),
                        icon: const Icon(Icons.lightbulb, size: 16),
                        label: const Text('Neon'),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.purple, Colors.orange]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => _sendEffectBarrage('VIP Rainbow'),
                          icon: const Icon(Icons.stars, size: 16, color: Colors.white),
                          label: const Text('VIP Rainbow', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _controller.clear(),
                    icon: const Icon(Icons.clear_all, size: 16, color: Colors.grey),
                    label: const Text('Clear stage', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StrokeInterceptor extends BarrageEffectInterceptor {
  const StrokeInterceptor();
  @override
  bool shouldIntercept(BarrageItem item, BarrageConfig config) => item.content.startsWith('Outline::');
  @override
  LayoutSpan createCustomSpan({
    required BarrageItem item,
    required String text,
    required ui.Paragraph paragraph,
    required double x,
    required double y,
    required double width,
    required double height,
    required BarrageConfig config,
  }) {
    return PreviewStrokeSpan(
      x: x,
      y: y,
      width: width,
      height: height,
      text: text.replaceFirst('Outline::', ''),
      paragraph: paragraph,
      config: config,
    );
  }
}

class PreviewStrokeSpan extends TextLayoutSpan {
  const PreviewStrokeSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.text,
    required super.paragraph,
    required this.config,
  });

  final BarrageConfig config;

  PreviewStrokeSpan copyWithY(double newY) {
    return PreviewStrokeSpan(
      x: x,
      y: newY,
      width: width,
      height: height,
      text: text,
      paragraph: paragraph,
      config: config,
    );
  }

  @override
  void paint(ui.Canvas canvas) {
    final strokePaint = StrokeEffect(strokeColor: config.strokeColor, strokeWidth: 3.0).createStrokePaint();
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize))
      ..pushStyle(ui.TextStyle(foreground: strokePaint, fontSize: config.fontSize, fontWeight: config.fontWeight))
      ..addText(text);
    final strokeParagraph = builder.build()..layout(ui.ParagraphConstraints(width: width + 6.0));
    final offsets = const [ui.Offset(-1, -1), ui.Offset(1, -1), ui.Offset(-1, 1), ui.Offset(1, 1)];
    for (int i = 0; i < 4; i++) {
      canvas.drawParagraph(strokeParagraph, ui.Offset(x, y) + offsets[i] * 0.5);
    }
    final fillBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize))
      ..pushStyle(ui.TextStyle(color: Colors.white, fontSize: config.fontSize, fontWeight: config.fontWeight))
      ..addText(text);
    final fillParagraph = fillBuilder.build()..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(fillParagraph, ui.Offset(x, y));
  }
}

class ShadowInterceptor extends BarrageEffectInterceptor {
  const ShadowInterceptor();
  @override
  bool shouldIntercept(BarrageItem item, BarrageConfig config) => item.content.startsWith('Shadow::');
  @override
  LayoutSpan createCustomSpan({
    required BarrageItem item,
    required String text,
    required ui.Paragraph paragraph,
    required double x,
    required double y,
    required double width,
    required double height,
    required BarrageConfig config,
  }) {
    return PreviewShadowSpan(
      x: x,
      y: y,
      width: width,
      height: height,
      text: text.replaceFirst('Shadow::', ''),
      paragraph: paragraph,
      config: config,
    );
  }
}

class PreviewShadowSpan extends TextLayoutSpan {
  const PreviewShadowSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.text,
    required super.paragraph,
    required this.config,
  });

  final BarrageConfig config;

  PreviewShadowSpan copyWithY(double newY) {
    return PreviewShadowSpan(
      x: x,
      y: newY,
      width: width,
      height: height,
      text: text,
      paragraph: paragraph,
      config: config,
    );
  }

  @override
  void paint(ui.Canvas canvas) {
    final shadowList = ShadowEffect(
      shadowColor: const ui.Color(0xFF4A148C),
      offset: const ui.Offset(3, 3),
      blurRadius: 4.0,
    ).createMultiShadows();
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize))
      ..pushStyle(
        ui.TextStyle(
          fontSize: config.fontSize,
          fontWeight: config.fontWeight,
          color: config.textColor,
          shadows: shadowList,
        ),
      )
      ..addText(text);
    final shadowParagraph = builder.build()..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(shadowParagraph, ui.Offset(x + 4.0, y + 4.0));
    canvas.drawParagraph(paragraph, ui.Offset(x, y));
  }
}

class GlowInterceptor extends BarrageEffectInterceptor {
  const GlowInterceptor();
  @override
  bool shouldIntercept(BarrageItem item, BarrageConfig config) => item.content.startsWith('Neon::');
  @override
  LayoutSpan createCustomSpan({
    required BarrageItem item,
    required String text,
    required ui.Paragraph paragraph,
    required double x,
    required double y,
    required double width,
    required double height,
    required BarrageConfig config,
  }) {
    return PreviewGlowSpan(
      x: x,
      y: y,
      width: width,
      height: height,
      text: text.replaceFirst('Neon::', ''),
      paragraph: paragraph,
      config: config,
    );
  }
}

class PreviewGlowSpan extends TextLayoutSpan {
  const PreviewGlowSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.text,
    required super.paragraph,
    required this.config,
  });
  final BarrageConfig config;
  PreviewGlowSpan copyWithY(double newY) {
    return PreviewGlowSpan(
      x: x,
      y: newY,
      width: width,
      height: height,
      text: text,
      paragraph: paragraph,
      config: config,
    );
  }

  @override
  void paint(ui.Canvas canvas) {
    final glowPaint = GlowEffect(glowColor: const ui.Color(0xFFFFEA00), blurRadius: 8.0).createGlowPaint();
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize))
      ..pushStyle(ui.TextStyle(foreground: glowPaint, fontSize: config.fontSize, fontWeight: config.fontWeight))
      ..addText(text);
    final glowParagraph = builder.build()..layout(ui.ParagraphConstraints(width: width + 16.0));
    final offsets = const [ui.Offset(-1, 0), ui.Offset(1, 0), ui.Offset(0, -1), ui.Offset(0, 1)];
    for (int i = 0; i < 4; i++) {
      canvas.drawParagraph(glowParagraph, ui.Offset(x, y) + offsets[i] * 0.5);
    }
    final contentBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize))
      ..pushStyle(ui.TextStyle(color: Colors.white, fontSize: config.fontSize, fontWeight: config.fontWeight))
      ..addText(text);
    final contentParagraph = contentBuilder.build()..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(contentParagraph, ui.Offset(x, y));
  }
}

class RainbowInterceptor extends BarrageEffectInterceptor {
  const RainbowInterceptor();
  @override
  bool shouldIntercept(BarrageItem item, BarrageConfig config) => item.content.startsWith('VIP Rainbow::');
  @override
  LayoutSpan createCustomSpan({
    required BarrageItem item,
    required String text,
    required ui.Paragraph paragraph,
    required double x,
    required double y,
    required double width,
    required double height,
    required BarrageConfig config,
  }) {
    return PreviewRainbowSpan(
      x: x,
      y: y,
      width: width,
      height: height,
      text: text.replaceFirst('VIP Rainbow::', ''),
      paragraph: paragraph,
      config: config,
    );
  }
}

class PreviewRainbowSpan extends TextLayoutSpan {
  const PreviewRainbowSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.text,
    required super.paragraph,
    required this.config,
  });
  final BarrageConfig config;
  PreviewRainbowSpan copyWithY(double newY) {
    return PreviewRainbowSpan(
      x: x,
      y: newY,
      width: width,
      height: height,
      text: text,
      paragraph: paragraph,
      config: config,
    );
  }

  @override
  void paint(ui.Canvas canvas) {
    final linearGradientShader = ui.Gradient.linear(
      ui.Offset(x, y),
      ui.Offset(x + width, y),
      const [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
      const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );
    final textPaint = ui.Paint()
      ..shader = linearGradientShader
      ..isAntiAlias = true;
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize))
      ..pushStyle(ui.TextStyle(foreground: textPaint, fontSize: config.fontSize, fontWeight: ui.FontWeight.bold))
      ..addText(text);
    final rainbowParagraph = builder.build()..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(rainbowParagraph, ui.Offset(x, y));
  }
}
