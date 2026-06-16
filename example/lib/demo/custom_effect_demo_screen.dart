import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class CustomEffectDemoScreen extends StatefulWidget {
  const CustomEffectDemoScreen({super.key});

  @override
  State<CustomEffectDemoScreen> createState() => _CustomEffectDemoScreenState();
}

class _CustomEffectDemoScreenState extends State<CustomEffectDemoScreen> {
  final BarrageController _controller = BarrageController();
  final TextEditingController _textController = TextEditingController();
  late final BarrageConfig _config;

  @override
  void initState() {
    super.initState();
    _config = const BarrageConfig(trackHeight: 44, fontSize: 20, effectInterceptors: [VipRainbowInterceptor()]);
  }

  void _sendBarrage() {
    if (_textController.text.trim().isEmpty) return;
    _controller.send(BarrageItem(content: _textController.text.trim(), type: BarrageType.scroll));
    _textController.clear();
  }

  void _quickSendVip() {
    _controller.send(const BarrageItem(content: '[VIP] 恭喜帝王尊贵超级VIP进入直播间！👑🔥', type: BarrageType.scroll));
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
      appBar: AppBar(title: const Text('外部插件化自定义特效演示')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF0F0F0F),
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
                            hintText: '输入普通文字，或包含 [VIP] 触发自定义特效...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _sendBarrage, child: const Text('发射')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: _quickSendVip,
                    icon: const Icon(Icons.workspace_premium, color: Colors.amber),
                    label: const Text('一键测试 [VIP] 自定义特效拦截', style: TextStyle(color: Colors.white)),
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

class VipRainbowInterceptor extends BarrageEffectInterceptor {
  const VipRainbowInterceptor();

  @override
  bool shouldIntercept(BarrageItem item, BarrageConfig config) {
    return item.content.contains('[VIP]');
  }

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
    return VipRainbowTextLayoutSpan(
      x: x,
      y: y,
      width: width,
      height: height,
      text: text,
      paragraph: paragraph,
      config: config,
    );
  }
}

class VipRainbowTextLayoutSpan extends TextLayoutSpan {
  const VipRainbowTextLayoutSpan({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.text,
    required super.paragraph,
    required this.config,
  });

  final BarrageConfig config;

  VipRainbowTextLayoutSpan copyWithY(double newY) {
    return VipRainbowTextLayoutSpan(
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
    final gradientShader = ui.Gradient.linear(
      ui.Offset(x, y),
      ui.Offset(x + width, y),
      const [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.cyan, Colors.purple],
      const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    final textPaint = ui.Paint()
      ..shader = gradientShader
      ..isAntiAlias = true;

    final strokePaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = config.strokeWidth
      ..color = const ui.Color(0xFF000000)
      ..isAntiAlias = true;

    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize))
      ..pushStyle(ui.TextStyle(foreground: strokePaint, fontSize: config.fontSize, fontWeight: config.fontWeight))
      ..addText(text);

    final strokeParagraph = builder.build()..layout(ui.ParagraphConstraints(width: width + 6.0));
    final offsets = const [ui.Offset(-1.0, -1.0), ui.Offset(1.0, -1.0), ui.Offset(-1.0, 1.0), ui.Offset(1.0, 1.0)];
    final origin = ui.Offset(x, y);

    for (int i = 0; i < 4; i++) {
      canvas.drawParagraph(strokeParagraph, origin + offsets[i] * 0.7);
    }

    final fillBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize))
      ..pushStyle(ui.TextStyle(foreground: textPaint, fontSize: config.fontSize, fontWeight: config.fontWeight))
      ..addText(text);

    final fillParagraph = fillBuilder.build()..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(fillParagraph, origin);
  }
}
