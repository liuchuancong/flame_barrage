import 'dart:math';
import 'dart:async';
import 'barrage_router.dart';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class MultiScreenBarrageDemoScreen extends StatefulWidget {
  const MultiScreenBarrageDemoScreen({super.key});

  @override
  State<MultiScreenBarrageDemoScreen> createState() => _MultiScreenBarrageDemoScreenState();
}

class _MultiScreenBarrageDemoScreenState extends State<MultiScreenBarrageDemoScreen> {
  late final BarrageController _controller;
  Widget? _currentBarrageScreen;
  Timer? _wsMockTimer;
  bool _wsOpen = false;

  final List<Map<String, dynamic>> mockPackets = [
    {'content': '小窗口弹幕测试 [滑稽]', 'type': 'scroll'},
    {'content': '全屏模式来了！', 'type': 'topFixed'},
    {'content': '底部固定弹幕', 'type': 'bottomFixed'},
    {'content': '666666', 'type': 'scroll'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = BarrageController();
  }

  void openSmallScreen() {
    setState(() {
      _currentBarrageScreen = SmallBarrageScreen(controller: _controller);
    });
  }

  void openFullScreen() {
    setState(() {
      _currentBarrageScreen = FullBarrageScreen(controller: _controller);
    });
  }

  void closeBarrage() {
    setState(() {
      _currentBarrageScreen = null;
    });
  }

  void toggleWs() {
    setState(() {
      _wsOpen = !_wsOpen;
    });
    if (_wsOpen) {
      final random = Random();
      _wsMockTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
        final packet = mockPackets[random.nextInt(mockPackets.length)];
        final item = MessageProtocol().fromWebSocketJson(packet);
        if (item != null) {
          _controller.send(item);
        }
      });
    } else {
      _wsMockTimer?.cancel();
      _wsMockTimer = null;
    }
  }

  @override
  void dispose() {
    _wsMockTimer?.cancel();
    _controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('多屏幕共用单控制器演示'),
        elevation: 2,
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF121212)),
          ?_currentBarrageScreen,
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: openSmallScreen,
                          child: const Text('打开小窗', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: openFullScreen,
                          child: const Text('打开全屏', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: closeBarrage,
                          child: const Text('关闭', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _wsOpen ? Colors.redAccent : Colors.greenAccent[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: toggleWs,
                          child: Text(_wsOpen ? '关闭推送' : '开启推送', style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 130,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _controller.running ? Colors.blueAccent : Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => setState(() => _controller.togglePause()),
                          child: Text(_controller.running ? '暂停弹幕' : '恢复弹幕', style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _controller.clear(),
                          child: const Text('一键清屏', style: TextStyle(fontSize: 13)),
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

class SmallBarrageScreen extends StatefulWidget {
  final BarrageController controller;
  const SmallBarrageScreen({super.key, required this.controller});

  @override
  State<SmallBarrageScreen> createState() => _SmallBarrageScreenState();
}

class _SmallBarrageScreenState extends State<SmallBarrageScreen> {
  @override
  void dispose() {
    widget.controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 20,
      width: 320,
      height: 180,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white30, width: 1.2),
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
        ),
        clipBehavior: Clip.antiAlias,
        child: FlameBarrageWidget(
          config: BarrageRouter.globalConfig.copyWith(area: 0.8),
          emojiAtlas: EmojiAtlas.instance,
          controller: widget.controller,
        ),
      ),
    );
  }
}

class FullBarrageScreen extends StatefulWidget {
  final BarrageController controller;
  const FullBarrageScreen({super.key, required this.controller});

  @override
  State<FullBarrageScreen> createState() => _FullBarrageScreenState();
}

class _FullBarrageScreenState extends State<FullBarrageScreen> {
  @override
  void dispose() {
    widget.controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: FlameBarrageWidget(
          config: BarrageRouter.globalConfig,
          emojiAtlas: EmojiAtlas.instance,
          controller: widget.controller,
        ),
      ),
    );
  }
}
