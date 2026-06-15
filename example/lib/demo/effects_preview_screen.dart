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
      maxTrackCount: 10,
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
        ? '尊贵VIP发送了 [$effectTag] 特效弹幕！🚀'
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
      appBar: AppBar(title: const Text('高级视觉特效全景预览')),
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
                            hintText: '输入自定义文本，选择下方特效发射...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _sendNormalBarrage, child: const Text('普通')),
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
                        onPressed: () => _sendEffectBarrage('外描边'),
                        icon: const Icon(Icons.border_color, size: 16),
                        label: const Text('外描边'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        onPressed: () => _sendEffectBarrage('立体阴影'),
                        icon: const Icon(Icons.layers, size: 16),
                        label: const Text('立体阴影'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
                        onPressed: () => _sendEffectBarrage('霓虹发光'),
                        icon: const Icon(Icons.lightbulb, size: 16),
                        label: const Text('霓虹发光'),
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
                          onPressed: () => _sendEffectBarrage('VIP七彩'),
                          icon: const Icon(Icons.stars, size: 16, color: Colors.white),
                          label: const Text('VIP七彩渐变', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _controller.clear(),
                    icon: const Icon(Icons.clear_all, size: 16, color: Colors.grey),
                    label: const Text('清空舞台', style: TextStyle(color: Colors.grey)),
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
  bool shouldIntercept(BarrageItem item, BarrageConfig config) => item.content.startsWith('外描边::');
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
      text: text.replaceFirst('外描边::', ''),
      paragraph: paragraph,
      config: config,
    );
  }
}

class PreviewStrokeSpan extends TextLayoutSpan {
  PreviewStrokeSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.text,
    required super.paragraph,
    required this.config,
  });
  final BarrageConfig config;
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
    super.paint(canvas);
  }
}

class ShadowInterceptor extends BarrageEffectInterceptor {
  const ShadowInterceptor();
  @override
  bool shouldIntercept(BarrageItem item, BarrageConfig config) => item.content.startsWith('立体阴影::');
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
      text: text.replaceFirst('立体阴影::', ''),
      paragraph: paragraph,
      config: config,
    );
  }
}

class PreviewShadowSpan extends TextLayoutSpan {
  PreviewShadowSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.text,
    required super.paragraph,
    required this.config,
  });
  final BarrageConfig config;
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
    canvas.drawParagraph(shadowParagraph, ui.Offset(x, y));
  }
}

class GlowInterceptor extends BarrageEffectInterceptor {
  const GlowInterceptor();
  @override
  bool shouldIntercept(BarrageItem item, BarrageConfig config) => item.content.startsWith('霓虹发光::');
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
      text: text.replaceFirst('霓虹发光::', ''),
      paragraph: paragraph,
      config: config,
    );
  }
}

class PreviewGlowSpan extends TextLayoutSpan {
  PreviewGlowSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.text,
    required super.paragraph,
    required this.config,
  });
  final BarrageConfig config;
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
    super.paint(canvas);
  }
}

class RainbowInterceptor extends BarrageEffectInterceptor {
  const RainbowInterceptor();
  @override
  bool shouldIntercept(BarrageItem item, BarrageConfig config) => item.content.startsWith('VIP七彩::');
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
      text: text.replaceFirst('VIP七彩::', ''),
      paragraph: paragraph,
      config: config,
    );
  }
}

class PreviewRainbowSpan extends TextLayoutSpan {
  PreviewRainbowSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.text,
    required super.paragraph,
    required this.config,
  });
  final BarrageConfig config;
  @override
  void paint(ui.Canvas canvas) {
    final shader = GradientEffect(
      colors: const [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
    ).createGradientPaint(textBounds: ui.Rect.fromLTWH(x, y, width, height));
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize))
      ..pushStyle(ui.TextStyle(foreground: shader, fontSize: config.fontSize, fontWeight: ui.FontWeight.bold))
      ..addText(text);
    final rainbowParagraph = builder.build()..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(rainbowParagraph, ui.Offset(x, y));
  }
}
