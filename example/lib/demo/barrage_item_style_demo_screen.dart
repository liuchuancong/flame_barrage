import 'dart:math';
import 'dart:async';
import 'barrage_router.dart';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class BarrageItemStyleDemoScreen extends StatefulWidget {
  const BarrageItemStyleDemoScreen({super.key});

  @override
  State<BarrageItemStyleDemoScreen> createState() => _BarrageItemStyleDemoScreenState();
}

class _BarrageItemStyleDemoScreenState extends State<BarrageItemStyleDemoScreen> {
  late final BarrageController _controller;
  Timer? _autoSendTimer;
  bool _autoSend = false;

  @override
  void initState() {
    super.initState();
    _controller = BarrageController();
  }

  // Pure default style: no per-item overrides
  void sendDefaultDanmaku() {
    final item = BarrageItem(content: "Global default style barrage");
    _controller.send(item);
  }

  // Per-item fontFamily, size and color overrides
  void sendFontStyleDanmaku() {
    final item = BarrageItem(
      content: "Custom fontFamily + size + color",
      fontFamily: "PingFang SC Medium",
      fontSize: 28,
      textColor: Color(0xFF40E0FF),
    );
    _controller.send(item);
  }

  // Custom stroke color and width
  void sendStrokeDanmaku() {
    final item = BarrageItem(
      content: "Custom stroke color and width [滑稽]",
      type: BarrageType.topFixed,
      fontSize: 26,
      textColor: Color(0xFFFF4444),
      showStroke: true,
      strokeColor: Color(0xFF000000),
      strokeWidth: 3,
    );
    _controller.send(item);
  }

  // Bottom-pinned item with a heavier weight and slow scroll
  void sendBottomWeightDanmaku() {
    final item = BarrageItem(
      content: "Bottom pinned, bold weight, slow scroll",
      type: BarrageType.bottomFixed,
      fontSize: 30,
      fontWeight: FontWeight.bold,
      baseSpeed: 40,
      textColor: Color(0xFFFFDD00),
      showStroke: true,
      strokeWidth: 2,
    );
    _controller.send(item);
  }

  // Random mix of every overridable style field
  void sendRandomMixDanmaku() {
    final random = Random();
    final textPool = ["Per-item style overrides global config", "fontFamily / size / stroke controlled separately", "Mixed weights, speeds and safe gaps", "Top / bottom / scroll variants"];
    final colorPool = [Color(0xFFff4d4f), Color(0xFF1890ff), Color(0xFF52c41a), Color(0xFFfa8c16)];
    final fontList = ["PingFang SC", "Heiti TC", "Songti SC"];
    final weightList = FontWeight.values;

    final item = BarrageItem(
      content: textPool[random.nextInt(textPool.length)],
      type: [BarrageType.scroll, BarrageType.topFixed, BarrageType.bottomFixed][random.nextInt(3)],
      fontSize: (16 + random.nextInt(14)).toDouble(),
      fontFamily: fontList[random.nextInt(fontList.length)],
      fontWeight: weightList[random.nextInt(weightList.length)],
      textColor: colorPool[random.nextInt(colorPool.length)],
      showStroke: random.nextBool(),
      strokeWidth: random.nextBool() ? 2.5 : 1,
      strokeColor: Colors.black,
      baseSpeed: (30 + random.nextInt(30)).toDouble(),
      overlapSafeGap: random.nextDouble() * 12,
    );
    _controller.send(item);
  }

  void toggleAutoSend() {
    setState(() => _autoSend = !_autoSend);
    if (_autoSend) {
      _autoSendTimer = Timer.periodic(const Duration(milliseconds: 1300), (_) {
        sendRandomMixDanmaku();
      });
    } else {
      _autoSendTimer?.cancel();
      _autoSendTimer = null;
    }
  }

  @override
  void dispose() {
    _autoSendTimer?.cancel();
    _controller.detach();
    super.dispose();
  }

  ButtonStyle baseBtnStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Per-item BarrageItem styles"),
        elevation: 2,
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF0A0A0A)),
          Positioned.fill(
            child: FlameBarrageWidget(
              config: BarrageRouter.globalConfig,
              emojiAtlas: EmojiAtlas.instance,
              controller: _controller,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          style: baseBtnStyle(),
                          onPressed: sendDefaultDanmaku,
                          child: const Text("Default", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 125,
                        child: ElevatedButton(
                          style: baseBtnStyle(),
                          onPressed: sendFontStyleDanmaku,
                          child: const Text("Font / size / color", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 115,
                        child: ElevatedButton(
                          style: baseBtnStyle(),
                          onPressed: sendStrokeDanmaku,
                          child: const Text("Stroked", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        child: ElevatedButton(
                          style: baseBtnStyle(),
                          onPressed: sendBottomWeightDanmaku,
                          child: const Text("Bottom bold slow", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: ElevatedButton(
                          style: baseBtnStyle(),
                          onPressed: sendRandomMixDanmaku,
                          child: const Text("Random mix", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _autoSend ? Colors.redAccent : Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: toggleAutoSend,
                          child: Text(_autoSend ? "Stop auto-send" : "Auto-send", style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 95,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _controller.running ? Colors.blueAccent : Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => setState(() => _controller.togglePause()),
                          child: Text(_controller.running ? "Pause" : "Resume", style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _controller.clear(),
                          child: const Text("Clear", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
