import 'dart:async';
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
  Timer? _stressTimer;
  bool _isStressTesting = false;
  int _stressMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fpsMonitor.start((fps) {
      if (mounted) {
        setState(() {
          _currentFps = fps;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < 3; i++) {
        _controller.send(const BarrageItem(content: '🚀 引擎监测总线已激活 - 帧率度量就绪', type: BarrageType.scroll));
      }
    });
  }

  @override
  void dispose() {
    _stressTimer?.cancel();
    _fpsMonitor.stop();
    _controller.detach();
    super.dispose();
  }

  void _toggleStressTest() {
    setState(() {
      _isStressTesting = !_isStressTesting;
    });

    if (_isStressTesting) {
      _stressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        Measure.profile('BulkEmissionPipeline', () {
          for (int i = 0; i < 30; i++) {
            _stressMessageIndex++;
            _controller.send(
              BarrageItem(
                content: '🔥 300发/s极限压测 💥 [流水线No.$_stressMessageIndex] - 实时测试硬件吞吐量线',
                type: BarrageType.scroll,
              ),
            );
          }
        });
      });
    } else {
      _stressTimer?.cancel();
    }
  }

  Future<void> _openConfigPanelAndListen() async {
    await Navigator.pushNamed(context, '/config_panel');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = BarrageRouter.globalConfig;

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          '内核性能度量与全局参数同步',
          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.orangeAccent),
            onPressed: _openConfigPanelAndListen,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('渲染引擎实时帧率 (FPS)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        '${_currentFps.toStringAsFixed(1)} Hz',
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: _currentFps > 55 ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStressTesting ? Colors.redAccent : const Color(0xFF722ED1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _toggleStressTest,
                  icon: Icon(_isStressTesting ? Icons.stop_circle_outlined : Icons.bolt, size: 16),
                  label: Text(
                    _isStressTesting ? '停止压测泵' : '开启300发/s压测',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlameBarrageWidget(
                  key: ValueKey(currentConfig.hashCode),
                  config: currentConfig,
                  emojiAtlas: EmojiAtlas.instance,
                  controller: _controller,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '当前同步内核配置：字号 ${currentConfig.fontSize}px | 轨道高度 ${currentConfig.trackHeight}px',
                      style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
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
