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
  static final BarrageController _singletonController = BarrageController();

  Timer? _burstTimer;
  Timer? _telemetryTimer;
  bool _isFlooding = false;

  int _totalEmitted = 0;
  int _pictureCacheCount = 0;
  int _poolObjectCount = 0;
  int _activeItemCount = 0;
  int _rasterCacheBytes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTelemetryLoop();
    });
  }

  void _startTelemetryLoop() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _fetchEngineMetrics();
    });
  }

  void _fetchEngineMetrics() {
    setState(() {
      _totalEmitted = _singletonController.totalEmitted;
      _pictureCacheCount = _singletonController.pictureCacheCount;
      _poolObjectCount = _singletonController.poolObjectCount;
      _activeItemCount = _singletonController.activeItemCount;
      _rasterCacheBytes = _singletonController.rasterCacheBytes;
    });
  }

  void _toggleFloodStressTest() {
    setState(() {
      _isFlooding = !_isFlooding;
    });

    if (_isFlooding) {
      _burstTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        for (int i = 0; i < 5; i++) {
          _singletonController.send(
            BarrageItem(
              content: 'VRAM stress pipeline #${_singletonController.totalEmitted + 1} [滑稽] code:${DateTime.now().microsecond}',
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
    _singletonController.clear();
    setState(() {
      _pictureCacheCount = 0;
      _poolObjectCount = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viewport and secondary caches force-released; VRAM reclaimed.')));
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _burstTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = BarrageRouter.globalConfig;

    return Scaffold(
      appBar: AppBar(title: const Text('On-device VRAM & Memory Monitor')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                _buildMetricRow('Total dispatched', '$_totalEmitted', Colors.blue),
                const SizedBox(height: 8),
                _buildMetricRow(
                  'Bitmap render cache (LRU)',
                  '$_pictureCacheCount / ${currentConfig.pictureCacheMaxSize}',
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildMetricRow(
                  'Bitmap VRAM / on-screen count',
                  '${(_rasterCacheBytes / 1048576).toStringAsFixed(1)} MB / $_activeItemCount',
                  Colors.purpleAccent,
                ),
                const SizedBox(height: 8),
                _buildMetricRow(
                  'BarragePool pooled entries',
                  '$_poolObjectCount / ${currentConfig.barragePoolMaxSize}',
                  Colors.green,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: FlameBarrageWidget(
                config: currentConfig,
                emojiAtlas: EmojiAtlas.instance,
                controller: _singletonController,
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
                      label: Text(_isFlooding ? 'Pause 300 msg/s flood' : 'Start 300 msg/s flood'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, minimumSize: const Size(100, 48)),
                    onPressed: _executeHardClear,
                    child: const Text('Destroy and release'),
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
