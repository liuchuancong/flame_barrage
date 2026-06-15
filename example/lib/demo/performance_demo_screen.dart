import 'barrage_router.dart';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class PerformanceDemoScreen extends StatefulWidget {
  const PerformanceDemoScreen({super.key});

  @override
  State<PerformanceDemoScreen> createState() => _PerformanceDemoScreenState();
}

class _PerformanceDemoScreenState extends State<PerformanceDemoScreen> {
  final BarrageController _controller = BarrageController();
  final FpsMonitor _fpsMonitor = FpsMonitor(sampleDuration: const Duration(milliseconds: 500));
  double _currentFps = 60.0;

  @override
  void initState() {
    super.initState();
    _fpsMonitor.start((fps) {
      setState(() {
        _currentFps = fps;
      });
    });
  }

  @override
  void dispose() {
    _fpsMonitor.stop();
    _controller.detach();
    super.dispose();
  }

  void _triggerPerformanceProfile() {
    Measure.profile('BulkEmissionPipeline', () {
      for (int i = 0; i < 50; i++) {
        _controller.send(const BarrageItem(content: '压测流水线运作中 - 实时监听核心控制台参数变动', type: BarrageType.scroll));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('性能大盘与配置全局同步')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            color: Colors.blueGrey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('引擎内核计算帧率', style: TextStyle(color: Colors.grey)),
                      Text(
                        '${_currentFps.toStringAsFixed(1)} FPS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _currentFps > 55 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    onPressed: _triggerPerformanceProfile,
                    icon: const Icon(Icons.speed),
                    label: const Text('度量高能耗时 (Measure)'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
              child: FlameBarrageWidget(
                config: BarrageRouter.globalConfig,
                emojiAtlas: EmojiAtlas.instance,
                controller: _controller,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '当前全局字体设定: ${BarrageRouter.globalConfig.fontSize}px  |  最大轨道: ${BarrageRouter.globalConfig.maxTrackCount} 轨',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
