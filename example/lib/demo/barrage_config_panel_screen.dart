import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class BarrageConfigPanelScreen extends StatefulWidget {
  const BarrageConfigPanelScreen({super.key, required this.initialConfig, required this.onConfigChanged});

  final BarrageConfig initialConfig;
  final ValueChanged<BarrageConfig> onConfigChanged;

  @override
  State<BarrageConfigPanelScreen> createState() => _BarrageConfigPanelScreenState();
}

class _BarrageConfigPanelScreenState extends State<BarrageConfigPanelScreen> {
  final BarrageController _controller = BarrageController();
  Timer? _floodTimer;
  int _floodIndex = 0;

  // Core tuning parameters
  double _fontSize = 20.0;
  FontWeight _fontWeight = FontWeight.w500;
  bool _showStroke = true;
  double _area = 1.0;
  double _trackHeight = 44.0;
  double _emojiSize = 24.0;
  int _maxVisibleCount = 150;
  double _emitInterval = 0.05;
  bool _realtimeMode = false;
  int _barragePoolMaxSize = 150;
  int _pictureCacheMaxSize = 200;
  bool _rasterizeItems = true;
  int _textCacheMaxSize = 1000;
  double _overlapSafeGap = 40.0;
  bool _noEmojiMode = false;
  bool _hideTop = false;
  bool _hideBottom = false;
  bool _hideScroll = false;

  // Appearance parameters
  Color _textColor = Colors.white;
  Color _strokeColor = Colors.black;
  double _opacity = 1.0;
  double _topAreaDistance = 0;
  double _bottomAreaDistance = 0;
  Duration _fixedDuration = Duration(seconds: 4);
  bool _safeArea = true;
  int _fps = 60;
  double _baseSpeed = 120.0;

  @override
  void initState() {
    super.initState();
    _loadConfigValues(widget.initialConfig);
  }

  void _loadConfigValues(BarrageConfig config) {
    _fontSize = config.fontSize;
    _fontWeight = config.fontWeight;
    _textColor = config.textColor;
    _strokeColor = config.strokeColor;
    _opacity = config.opacity;
    _showStroke = config.showStroke;
    _area = config.area;
    _topAreaDistance = config.topAreaDistance;
    _bottomAreaDistance = config.bottomAreaDistance;
    _fixedDuration = config.fixedDuration;

    _safeArea = config.safeArea;
    _fps = config.fps;
    _trackHeight = config.trackHeight;
    _emojiSize = config.emojiSize;
    _maxVisibleCount = config.maxVisibleCount;
    _emitInterval = config.emitInterval;
    _realtimeMode = config.realtimeMode;
    _baseSpeed = config.baseSpeed;
    _overlapSafeGap = config.overlapSafeGap;
    _noEmojiMode = config.noEmojiMode;
    _barragePoolMaxSize = config.barragePoolMaxSize;
    _pictureCacheMaxSize = config.pictureCacheMaxSize;
    _rasterizeItems = config.rasterizeItems;
    _textCacheMaxSize = config.textCacheMaxSize;
  }

  BarrageConfig _buildCurrentLiveConfig() {
    return widget.initialConfig.copyWith(
      fontSize: _fontSize,
      fontWeight: _fontWeight,
      textColor: _textColor,
      strokeColor: _strokeColor,
      opacity: _opacity,
      showStroke: _showStroke,
      area: _area,
      topAreaDistance: _topAreaDistance,
      bottomAreaDistance: _bottomAreaDistance,
      fixedDuration: _fixedDuration,
      hideTop: _hideTop,
      hideBottom: _hideBottom,
      hideScroll: _hideScroll,
      safeArea: _safeArea,
      fps: _fps,
      trackHeight: _trackHeight,
      emojiSize: _emojiSize,
      maxVisibleCount: _maxVisibleCount,
      emitInterval: _emitInterval,
      realtimeMode: _realtimeMode,
      baseSpeed: _baseSpeed,
      overlapSafeGap: _overlapSafeGap,
      noEmojiMode: _noEmojiMode,
      barragePoolMaxSize: _barragePoolMaxSize,
      pictureCacheMaxSize: _pictureCacheMaxSize,
      rasterizeItems: _rasterizeItems,
      textCacheMaxSize: _textCacheMaxSize,
    );
  }

  void _pushLiveUpdate() {
    final nextConfig = _buildCurrentLiveConfig();

    _controller.updateConfig(nextConfig);
    widget.onConfigChanged(nextConfig);
  }

  void _saveAndApply() {
    final updatedConfig = _buildCurrentLiveConfig();

    _controller.updateConfig(updatedConfig);
    widget.onConfigChanged(updatedConfig);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config reloaded and applied to the render pipeline!')));
  }

  @override
  void dispose() {
    _floodTimer?.cancel();
    _controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLiveConfig = _buildCurrentLiveConfig();

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text('Engine Advanced Configuration Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: _saveAndApply,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 180,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlameBarrageWidget(
                config: currentLiveConfig,
                emojiAtlas: EmojiAtlas.instance,
                controller: _controller,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.rocket_launch_rounded, size: 20),
              label: Text('Send a verification barrage (fontSize: ${_fontSize.toInt()}px)'),
              onPressed: () {
                _floodIndex++;
                _controller.send(
                  BarrageItem(
                    content:
                        '⚙️ Pipeline burst #$_floodIndex -> fontSize: ${_fontSize.toInt()}px | trackHeight: ${_trackHeight.toInt()}px | speed: ${_baseSpeed.toInt()}px/s',
                    type: BarrageType.scroll,
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle('🎨 Visual style & layout'),
                _buildSliderSetting(
                  'Font size (fontSize)',
                  _fontSize,
                  12,
                  36,
                  1,
                  (v) => setState(() {
                    _fontSize = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildDropdownFontWeight(),
                _buildColorPickerSetting(
                  'Text color (textColor)',
                  _textColor,
                  (v) => setState(() {
                    _textColor = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildColorPickerSetting(
                  'Stroke color (strokeColor)',
                  _strokeColor,
                  (v) => setState(() {
                    _strokeColor = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Opacity (opacity)',
                  _opacity,
                  0.0,
                  1.0,
                  0.05,
                  (v) => setState(() {
                    _opacity = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSwitchSetting(
                  'Text stroke (showStroke)',
                  _showStroke,
                  (v) => setState(() {
                    _showStroke = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Vertical area ratio (area)',
                  _area,
                  0.1,
                  1.0,
                  0.05,
                  (v) => setState(() {
                    _area = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Top inset (topAreaDistance)',
                  _topAreaDistance,
                  0,
                  100,
                  1,
                  (v) => setState(() {
                    _topAreaDistance = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Bottom inset (bottomAreaDistance)',
                  _bottomAreaDistance,
                  0,
                  100,
                  1,
                  (v) => setState(() {
                    _bottomAreaDistance = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Lane height (trackHeight)',
                  _trackHeight,
                  24,
                  60,
                  1,
                  (v) => setState(() {
                    _trackHeight = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Inline emoji size (emojiSize)',
                  _emojiSize,
                  16,
                  48,
                  1,
                  (v) => setState(() {
                    _emojiSize = v;
                    _pushLiveUpdate();
                  }),
                ),

                const Divider(height: 32),
                _buildSectionTitle('⏱️ Timing & speed'),
                _buildDurationSetting(
                  'Pinned duration (fixedDuration)',
                  _fixedDuration,
                  (v) => setState(() {
                    _fixedDuration = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Base speed (baseSpeed)',
                  _baseSpeed,
                  10.0,
                  500.0,
                  10.0,
                  (v) => setState(() {
                    _baseSpeed = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Frame rate (fps)',
                  _fps.toDouble(),
                  30,
                  120,
                  1,
                  (v) => setState(() {
                    _fps = v.toInt();
                    _pushLiveUpdate();
                  }),
                ),

                const Divider(height: 32),
                _buildSectionTitle('⚡ Flow control & dispatch'),
                _buildSliderSetting(
                  'Max on-screen messages (maxVisibleCount)',
                  _maxVisibleCount.toDouble(),
                  10,
                  300,
                  5,
                  (v) => setState(() {
                    _maxVisibleCount = v.toInt();
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Emit interval (emitInterval)',
                  _emitInterval,
                  0.01,
                  0.5,
                  0.01,
                  (v) => setState(() {
                    _emitInterval = v;
                    _pushLiveUpdate();
                  }),
                ),

                const Divider(height: 32),
                _buildSectionTitle('🚀 Dispatch strategy'),
                _buildSwitchSetting(
                  'Realtime mode (realtimeMode · dispatch on arrival, no pacing)',
                  _realtimeMode,
                  (v) => setState(() {
                    _realtimeMode = v;
                    _pushLiveUpdate();
                  }),
                ),

                const Divider(height: 32),
                _buildSectionTitle('📦 Object pool & cache budgets'),
                _buildSwitchSetting(
                  'Rasterize bitmaps (rasterizeItems · recommended on TV/low-end)',
                  _rasterizeItems,
                  (v) => setState(() {
                    _rasterizeItems = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Entry pool size (barragePoolMaxSize)',
                  _barragePoolMaxSize.toDouble(),
                  50,
                  500,
                  10,
                  (v) => setState(() {
                    _barragePoolMaxSize = v.toInt();
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Bitmap cache entries (pictureCacheMaxSize)',
                  _pictureCacheMaxSize.toDouble(),
                  50,
                  1500,
                  25,
                  (v) => setState(() {
                    _pictureCacheMaxSize = v.toInt();
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  'Paragraph cache size (textCacheMaxSize)',
                  _textCacheMaxSize.toDouble(),
                  100,
                  3000,
                  50,
                  (v) => setState(() {
                    _textCacheMaxSize = v.toInt();
                    _pushLiveUpdate();
                  }),
                ),

                const Divider(height: 32),
                _buildSectionTitle('🛡️ Anti-overlap policy'),
                _buildSliderSetting(
                  'Safe gap (overlapSafeGap)',
                  _overlapSafeGap,
                  0.0,
                  150.0,
                  5.0,
                  (v) => setState(() {
                    _overlapSafeGap = v;
                    _pushLiveUpdate();
                  }),
                ),

                const Divider(height: 32),
                _buildSectionTitle('🚫 Visibility filters'),
                _buildSwitchSetting(
                  'Hide top-pinned barrages',
                  _hideTop,
                  (v) => setState(() {
                    _hideTop = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSwitchSetting(
                  'Hide bottom-pinned barrages',
                  _hideBottom,
                  (v) => setState(() {
                    _hideBottom = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSwitchSetting(
                  'Hide scrolling barrages',
                  _hideScroll,
                  (v) => setState(() {
                    _hideScroll = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSwitchSetting(
                  'Respect safe area (safeArea)',
                  _safeArea,
                  (v) => setState(() {
                    _safeArea = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSwitchSetting(
                  'Plain text only (noEmojiMode)',
                  _noEmojiMode,
                  (v) => setState(() {
                    _noEmojiMode = v;
                    _pushLiveUpdate();
                  }),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double current,
    double min,
    double max,
    double step,
    ValueChanged<double> onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13)),
      subtitle: Slider(
        value: current.clamp(min, max),
        min: min,
        max: max,
        divisions: ((max - min) / step).round(),
        label: current.toStringAsFixed(current % 1 == 0 ? 0 : 2),
        onChanged: onChanged,
      ),
      trailing: Text(
        current.toStringAsFixed(current % 1 == 0 ? 0 : 2),
        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildSwitchSetting(String title, bool current, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: current,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownFontWeight() {
    final weights = [FontWeight.w300, FontWeight.w400, FontWeight.w500, FontWeight.w700];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Font weight (fontWeight)', style: TextStyle(fontSize: 13)),
      trailing: DropdownButton<FontWeight>(
        value: _fontWeight,
        dropdownColor: const Color(0xFF1F1F1F),
        items: weights.map((w) => DropdownMenuItem(value: w, child: Text(w.toString().split('.').last))).toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() {
              _fontWeight = v;
              _pushLiveUpdate();
            });
          }
        },
      ),
    );
  }

  Widget _buildColorPickerSetting(String title, Color current, ValueChanged<Color> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13)),
      trailing: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: current,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showColorPickerDialog(current, onChanged);
            },
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Future<void> _showColorPickerDialog(Color initialColor, ValueChanged<Color> onColorChanged) async {
    Color selectedColor = initialColor;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPickerGrid(
              selectedColor: selectedColor,
              onColorSelected: (color) {
                selectedColor = color;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                onColorChanged(selectedColor);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDurationSetting(String title, Duration current, ValueChanged<Duration> onChanged) {
    int seconds = current.inSeconds;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13)),
      subtitle: Slider(
        value: seconds.toDouble(),
        min: 1,
        max: 20,
        divisions: 19,
        label: '${seconds}s',
        onChanged: (v) {
          setState(() {
            seconds = v.toInt();
            onChanged(Duration(seconds: seconds));
          });
        },
      ),
      trailing: Text('${seconds}s', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// Minimal grid-based color picker
class ColorPickerGrid extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorPickerGrid({super.key, required this.selectedColor, required this.onColorSelected});

  static const List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _colors.map((color) {
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: selectedColor == color ? Colors.black : Colors.transparent, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }
}
