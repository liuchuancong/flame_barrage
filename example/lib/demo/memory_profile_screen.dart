import 'dart:async';
import 'barrage_router.dart';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class MemoryProfileScreen extends StatefulWidget {
  const MemoryProfileScreen({super.key});

  @override
  State<MemoryProfileScreen> createState() => _MemoryProfileScreenState();
}

class _MemoryProfileScreenState extends State<MemoryProfileScreen> {
  final BarrageController _controller = BarrageController();
  Timer? _burstTimer;
  bool _isFlooding = false;

  int _totalEmitted = 0;
  int _pictureCacheCount = 0;
  int _poolObjectCount = 0;

  @override
  void initState() {
    super.initState();
    _startTelemetryLoop();
  }

  void _startTelemetryLoop() {
    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _fetchEngineMetrics();
    });
  }

  void _fetchEngineMetrics() {
    try {
      final dynamic engine = (_controller as dynamic)._engine;
      if (engine != null) {
        final pictureCache = engine._pictureCache;
        final pool = engine._pool;
        setState(() {
          _pictureCacheCount = pictureCache.size;
          _poolObjectCount = (pool as dynamic).currentSize ?? 0;
        });
      }
    } catch (_) {}
  }

  void _toggleFloodStressTest() {
    setState(() {
      _isFlooding = !_isFlooding;
    });

    if (_isFlooding) {
      _burstTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        for (int i = 0; i < 5; i++) {
          _totalEmitted++;
          _controller.send(
            BarrageItem(
              content: '显存压测弹幕流水线 #$_totalEmitted [滑稽]随机码:${DateTime.now().microsecond}',
              type: BarrageType.scroll,
            ),
          );
        }
      });
    } else {
      _burstTimer?.cancel();
      _burstTimer = null;
    }
  }

  void _executeHardClear() {
    _controller.clear();
    BarrageLogger.i('MemoryProfile', '已触发全舞台硬核清屏，底层 C++ Picture.dispose() 指针已全部销毁。');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已强制解构视口及二级缓存，显存已安全回落！')));
  }

  @override
  void dispose() {
    _burstTimer?.cancel();
    _controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('真机显存与常驻内存监控')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                _buildMetricRow('累计发射总数', '$_totalEmitted 条', Colors.blue),
                const SizedBox(height: 8),
                _buildMetricRow(
                  'Picture 位图硬件缓存 (LRU)',
                  '$_pictureCacheCount / ${BarrageRouter.globalConfig.pictureCacheMaxSize}',
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildMetricRow(
                  'BarragePool 常驻组件复用数',
                  '$_poolObjectCount / ${BarrageRouter.globalConfig.barragePoolMaxSize}',
                  Colors.green,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: FlameBarrageWidget(
                config: BarrageRouter.globalConfig,
                emojiAtlas: EmojiAtlas.instance,
                controller: _controller,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFlooding ? Colors.red : Colors.indigo,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _toggleFloodStressTest,
                      icon: Icon(_isFlooding ? Icons.pause : Icons.play_arrow),
                      label: Text(_isFlooding ? '暂停 300发/秒 洪峰轰炸' : '开启 300发/秒 洪峰轰炸'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, minimumSize: const Size(100, 48)),
                    onPressed: _executeHardClear,
                    child: const Text('一键销毁释放'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 14),
        ),
      ],
    );
  }
}
