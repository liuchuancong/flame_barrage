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

  // 纯默认样式，不自定义任何字段
  void sendDefaultDanmaku() {
    final item = BarrageItem(content: "全局默认样式弹幕测试");
    _controller.send(item);
  }

  // 单独自定义 fontFamily、字号、文字颜色
  void sendFontStyleDanmaku() {
    final item = BarrageItem(
      content: "自定义字体+字号+文字颜色",
      fontFamily: "PingFang SC Medium",
      fontSize: 28,
      textColor: Color(0xFF40E0FF),
    );
    _controller.send(item);
  }

  // 开启描边、自定义描边颜色宽度
  void sendStrokeDanmaku() {
    final item = BarrageItem(
      content: "开启描边自定义粗细颜色 [滑稽]",
      type: BarrageType.topFixed,
      fontSize: 26,
      textColor: Color(0xFFFF4444),
      showStroke: true,
      strokeColor: Color(0xFF000000),
      strokeWidth: 3,
    );
    _controller.send(item);
  }

  // 底部弹幕，自定义字重、基础滚动速度
  void sendBottomWeightDanmaku() {
    final item = BarrageItem(
      content: "底部弹幕 粗字重+慢速滚动",
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

  // 随机混合全部可自定义样式
  void sendRandomMixDanmaku() {
    final random = Random();
    final textPool = ["单条独立样式覆盖全局配置", "fontFamily/字号/描边分开控制", "不同字重、速度、安全间距测试", "顶部/底部/滚动弹幕差异化展示"];
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
        title: const Text("BarrageItem 单条独立样式测试"),
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
                          child: const Text("默认样式", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 125,
                        child: ElevatedButton(
                          style: baseBtnStyle(),
                          onPressed: sendFontStyleDanmaku,
                          child: const Text("字体/字号/颜色", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 115,
                        child: ElevatedButton(
                          style: baseBtnStyle(),
                          onPressed: sendStrokeDanmaku,
                          child: const Text("描边样式弹幕", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        child: ElevatedButton(
                          style: baseBtnStyle(),
                          onPressed: sendBottomWeightDanmaku,
                          child: const Text("底部粗字慢速", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: ElevatedButton(
                          style: baseBtnStyle(),
                          onPressed: sendRandomMixDanmaku,
                          child: const Text("随机混合样式", style: TextStyle(fontSize: 12)),
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
                          child: Text(_autoSend ? "停止自动发" : "开启自动发", style: const TextStyle(fontSize: 12)),
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
                          child: Text(_controller.running ? "暂停" : "恢复", style: const TextStyle(fontSize: 12)),
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
                          child: const Text("清屏", style: TextStyle(fontSize: 12)),
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
