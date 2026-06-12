import 'package:flutter/widgets.dart';

typedef FpsCallback = void Function(double fps);

class FpsMonitor {
  FpsMonitor({this.sampleDuration = const Duration(seconds: 1)});

  final Duration sampleDuration;

  FpsCallback? _onFpsUpdated;
  bool _isListening = false;
  bool _hasRegisteredCallback = false;
  int _lastTimestamp = 0;
  int _frameCount = 0;

  void start(FpsCallback onFpsUpdated) {
    _onFpsUpdated = onFpsUpdated;
    _lastTimestamp = DateTime.now().millisecondsSinceEpoch;
    _frameCount = 0;

    if (_isListening) return;
    _isListening = true;

    if (!_hasRegisteredCallback) {
      _hasRegisteredCallback = true;
      WidgetsBinding.instance.addPersistentFrameCallback(_onFrame);
    }
  }

  void stop() {
    _isListening = false;
    _onFpsUpdated = null;
  }

  void _onFrame(Duration timeStamp) {
    if (!_isListening) return;

    _frameCount++;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int delta = now - _lastTimestamp;

    if (delta >= sampleDuration.inMilliseconds) {
      final double fps = (_frameCount * 1000.0) / delta;
      final double clampedFps = fps.clamp(0.0, 60.0);

      _onFpsUpdated?.call(clampedFps);

      _lastTimestamp = now;
      _frameCount = 0;
    }

    if (_isListening) {
      WidgetsBinding.instance.scheduleFrame();
    }
  }
}
