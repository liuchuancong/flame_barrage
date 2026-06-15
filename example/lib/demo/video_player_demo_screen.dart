import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class VideoPlayerDemoScreen extends StatefulWidget {
  const VideoPlayerDemoScreen({super.key});

  @override
  State<VideoPlayerDemoScreen> createState() => _VideoPlayerDemoScreenState();
}

class _VideoPlayerDemoScreenState extends State<VideoPlayerDemoScreen> {
  final BarrageController _controller = BarrageController();
  BarrageEngine? _engine;
  bool _engineReady = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('交互式视频手势遮罩')),
      body: Column(
        children: [
          Container(
            height: 240,
            color: Colors.blueGrey,
            child: Stack(
              children: [
                const Center(child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white54)),
                Positioned.fill(
                  child: FlameBarrageWidget(
                    config: const BarrageConfig(trackHeight: 38, maxTrackCount: 5, area: 0.8),
                    emojiAtlas: EmojiAtlas.instance,
                    controller: _controller,
                  ),
                ),
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_engineReady) {
                          try {
                            final dynamic widgetState = context.findAncestorStateOfType<State<FlameBarrageWidget>>();
                            if (widgetState != null) {
                              setState(() {
                                _engine = widgetState.engine as BarrageEngine;
                                _engineReady = true;
                              });
                            }
                          } catch (_) {}
                        }
                      });

                      if (!_engineReady || _engine == null) return const SizedBox.shrink();

                      return BarrageOverlay(
                        engine: _engine!,
                        onBarrageTap: (component) {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.favorite, color: Colors.red),
                                    title: Text('为你点赞: "${component.entry.item.content}"'),
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.report, color: Colors.red),
                                    title: const Text('举报该条违法弹幕'),
                                    onTap: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [ElevatedButton(onPressed: _injectMockBarrages, child: const Text('发射可交互矩阵检测弹幕'))],
            ),
          ),
        ],
      ),
    );
  }
}
