import 'barrage_router.dart';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class VideoPlayerDemoScreen extends StatefulWidget {
  const VideoPlayerDemoScreen({super.key});

  @override
  State<VideoPlayerDemoScreen> createState() => _VideoPlayerDemoScreenState();
}

class _VideoPlayerDemoScreenState extends State<VideoPlayerDemoScreen> {
  final BarrageController _controller = BarrageController();
  final List<String> _gestureConsoleLogs = [];
  final ScrollController _consoleScrollController = ScrollController();

  @override
  void dispose() {
    _controller.detach();
    _consoleScrollController.dispose();
    super.dispose();
  }

  void _logGestureEvent(String message) {
    setState(() {
      _gestureConsoleLogs.add('[${DateTime.now().toString().split(' ').last}] $message');
      if (_gestureConsoleLogs.length > 50) {
        _gestureConsoleLogs.removeAt(0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.jumpTo(_consoleScrollController.position.maxScrollExtent);
      }
    });
  }

  void _injectStressTestBarrages() {
    final items = [
      BarrageItem(
        content: '⚡ 点击按下测试弹幕 ⚡',
        type: BarrageType.scroll,
        priority: 1,
        onTapDown: () => _logGestureEvent('【onTapDown】击中目标文字！'),
        onTapUp: () => _logGestureEvent('【onTapUp】鼠标顺利抬起释放'),
        onLongTapDown: () => _logGestureEvent('【onLongTapDown】触发高能长按！'),
        onTapCancel: () => _logGestureEvent('【onTapCancel】触控判定移出被取消'),
      ),
      BarrageItem(
        content: '🔥 连续多手势联合并发轰炸 🔥',
        type: BarrageType.scroll,
        priority: 1,
        onTapDown: () => _logGestureEvent('【onTapDown】高并发触发'),
        onTapUp: () => _logGestureEvent('【onTapUp】释放总线'),
        onLongTapDown: () => _logGestureEvent('【onLongTapDown】长按蓄力中...'),
        onTapCancel: () => _logGestureEvent('【onTapCancel】判定拦截撤销'),
      ),
      const BarrageItem(content: '背景杂音普通不响应点击弹幕 666', type: BarrageType.scroll, priority: 0),
    ];

    for (int i = 0; i < 4; i++) {
      for (var item in items) {
        _controller.send(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          '4大底层手势流联合压测',
          style: TextStyle(color: Color(0xFF1F2328), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2328), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.play_circle_filled_rounded, size: 54, color: Colors.white60)),
                  Positioned.fill(
                    child: FlameBarrageWidget(
                      config: BarrageRouter.globalConfig.copyWith(area: 0.7),
                      emojiAtlas: EmojiAtlas.instance,
                      controller: _controller,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.pause_rounded, color: Colors.white, size: 20),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: LinearProgressIndicator(
                                value: 0.45,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          Text(
                            '04:20 / 11:15',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF722ED1), Color(0xFF391085)]),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF722ED1).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _injectStressTestBarrages,
                icon: const Icon(Icons.bolt, color: Colors.white, size: 18),
                label: const Text(
                  '注入4重手势高频测试弹幕',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.terminal_rounded, color: Colors.greenAccent, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '手势总线实时捕获控制台',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => setState(() => _gestureConsoleLogs.clear()),
                        child: const Text('清空日志', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  Expanded(
                    child: _gestureConsoleLogs.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无手势触发，请用鼠标点击或长按上方滑出的【⚡】或【🔥】弹幕文字',
                              style: TextStyle(color: Colors.white30, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            controller: _consoleScrollController,
                            itemCount: _gestureConsoleLogs.length,
                            itemBuilder: (context, index) {
                              final log = _gestureConsoleLogs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  log,
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
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
