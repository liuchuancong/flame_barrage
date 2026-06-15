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
  final GlobalKey _barrageWidgetKey = GlobalKey();

  @override
  void dispose() {
    _controller.detach();
    super.dispose();
  }

  void _injectMockBarrages() {
    final items = [
      const BarrageItem(content: '这是一条可以点击的弹幕 👍', type: BarrageType.scroll, priority: 1),
      const BarrageItem(content: '点击我可以触发弹窗互动 🌟', type: BarrageType.scroll, priority: 1),
      const BarrageItem(content: '哈哈哈哈红红火火恍恍惚惚', type: BarrageType.scroll, priority: 0),
    ];
    for (var item in items) {
      _controller.send(item);
    }
  }

  void _handleCanvasTap(TapDownDetails details) {
    final dynamic dynamicController = _controller;

    dynamic engine;
    try {
      if (dynamicController.engine != null) {
        engine = dynamicController.engine;
      }
    } catch (_) {
      try {
        if (dynamicController.context?.engine != null) {
          engine = dynamicController.context.engine;
        }
      } catch (_) {}
    }

    if (engine == null) return;

    final RenderBox? renderBox = _barrageWidgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    try {
      final List<dynamic> activeEntries = engine._activeEntries as List<dynamic>;
      final int len = activeEntries.length;

      for (int i = len - 1; i >= 0; i--) {
        final dynamic entry = activeEntries[i];

        final double left = entry.x as double;
        final double top = entry.y as double;
        final double right = left + (entry.width as double);
        final double bottom = top + (entry.height as double);

        if (localPosition.dx >= left &&
            localPosition.dx <= right &&
            localPosition.dy >= top &&
            localPosition.dy <= bottom) {
          final String content = entry.item.content as String;
          _showInteractionSheet(content);
          break;
        }
      }
    } catch (e) {
      debugPrint('手势撞击矩阵计算异常: $e');
    }
  }

  void _showInteractionSheet(String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '已命中弹幕: "$content"',
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                title: const Text('为该弹幕点赞'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.orangeAccent),
                title: const Text('举报不良内容'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          '交互式视频手势遮罩',
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
                    child: GestureDetector(
                      key: _barrageWidgetKey,
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _handleCanvasTap,
                      child: FlameBarrageWidget(
                        config: BarrageRouter.globalConfig.copyWith(area: 0.7),
                        emojiAtlas: EmojiAtlas.instance,
                        controller: _controller,
                      ),
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
                                value: 0.35,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          Text(
                            '03:15 / 09:42',
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1890FF), Color(0xFF0050B3)]),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1890FF).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                onPressed: _injectMockBarrages,
                icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                label: const Text(
                  '发射可交互矩阵检测弹幕',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ads_click_rounded, color: Color(0xFF8C95A0), size: 36),
                  SizedBox(height: 12),
                  Text(
                    '点击说明: 发射弹幕后，请直接在黑色播放器画面内，用鼠标精准点击正在从右向左滑动的文字。基于纯数据级反向矩阵转换，弹窗将即刻弹出。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF57606A), fontSize: 12, height: 1.4),
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
