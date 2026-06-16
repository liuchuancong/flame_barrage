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

  // 原有参数
  double _fontSize = 20.0;
  FontWeight _fontWeight = FontWeight.w500;
  bool _showStroke = true;
  double _area = 1.0;
  double _trackHeight = 44.0;
  double _emojiSize = 24.0;
  int _maxVisibleCount = 150;
  double _emitInterval = 0.05;
  int _barragePoolMaxSize = 150;
  int _pictureCacheMaxSize = 200;
  int _textCacheMaxSize = 1000;
  double _overlapSafeGap = 40.0;
  bool _noEmojiMode = false;
  bool _hideTop = false;
  bool _hideBottom = false;
  bool _hideScroll = false;

  // 补充的新参数
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
    _startLiveFloodPump();
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
    _baseSpeed = config.baseSpeed;
    _overlapSafeGap = config.overlapSafeGap;
    _noEmojiMode = config.noEmojiMode;
    _barragePoolMaxSize = config.barragePoolMaxSize;
    _pictureCacheMaxSize = config.pictureCacheMaxSize;
    _textCacheMaxSize = config.textCacheMaxSize;
  }

  void _startLiveFloodPump() {
    _floodTimer?.cancel();
    _floodTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _floodIndex++;

      final currentFontSize = _fontSize;
      final currentTrackHeight = _trackHeight;
      BarrageLogger.w(
        'BarrageConfigPanelScreen',
        '⚙️ 物理管线实时热更新 #$_floodIndex -> 当前字号:${currentFontSize.toInt()}px | 物理轨道:${currentTrackHeight.toInt()}px',
      );
      _controller.send(
        BarrageItem(
          content:
              '⚙️ 物理管线实时热更新 #$_floodIndex -> 当前字号:${currentFontSize.toInt()}px | 物理轨道:${currentTrackHeight.toInt()}px',
          type: BarrageType.scroll,
        ),
      );
    });
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
      baseSpeed: _baseSpeed,
      overlapSafeGap: _overlapSafeGap,
      noEmojiMode: _noEmojiMode,
      barragePoolMaxSize: _barragePoolMaxSize,
      pictureCacheMaxSize: _pictureCacheMaxSize,
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('内核配置重载成功，已实时应用到渲染管线！')));
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
        title: const Text('弹幕引擎内核高级配置控制台'),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle('🎨 视觉样式与图层空间'),
                _buildSliderSetting(
                  '字体大小 (fontSize)',
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
                  '文字颜色 (textColor)',
                  _textColor,
                  (v) => setState(() {
                    _textColor = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildColorPickerSetting(
                  '描边颜色 (strokeColor)',
                  _strokeColor,
                  (v) => setState(() {
                    _strokeColor = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  '透明度 (opacity)',
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
                  '开启硬核文字描边 (showStroke)',
                  _showStroke,
                  (v) => setState(() {
                    _showStroke = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  '屏幕垂直空间占用比 (area)',
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
                  '顶部距离 (topAreaDistance)',
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
                  '底部距离 (bottomAreaDistance)',
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
                  '单物理轨道高度 (trackHeight)',
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
                  '行内 Emoji 渲染尺寸 (emojiSize)',
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
                _buildSectionTitle('⏱️ 时间与速度控制'),
                _buildDurationSetting(
                  '固定弹幕持续时间 (fixedDuration)',
                  _fixedDuration,
                  (v) => setState(() {
                    _fixedDuration = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSliderSetting(
                  '基础移动速度 (baseSpeed)',
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
                  '帧率 (fps)',
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
                _buildSectionTitle('⚡ 高并发流控与发射频率'),
                _buildSliderSetting(
                  '同屏最大可见弹幕数 (maxVisibleCount)',
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
                  '高频发射泵间隔时间 (emitInterval)',
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
                _buildSectionTitle('📦 零开销对象池与物理二级缓存上限'),
                _buildSliderSetting(
                  'BarrageComponent 对象池上限',
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
                  'Picture 位图硬件缓存上限',
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
                  'Paragraph 文本渲染缓存上限',
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
                _buildSectionTitle('🛡️ 防追尾安全策略'),
                _buildSliderSetting(
                  '防重叠绝对安全间距 (overlapSafeGap)',
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
                _buildSectionTitle('🚫 视口黑名单智能过滤'),
                _buildSwitchSetting(
                  '智能隐藏顶部固定弹幕',
                  _hideTop,
                  (v) => setState(() {
                    _hideTop = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSwitchSetting(
                  '智能隐藏底部固定弹幕',
                  _hideBottom,
                  (v) => setState(() {
                    _hideBottom = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSwitchSetting(
                  '智能隐藏普通滚动弹幕',
                  _hideScroll,
                  (v) => setState(() {
                    _hideScroll = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSwitchSetting(
                  '自动适配安全区域 (safeArea)',
                  _safeArea,
                  (v) => setState(() {
                    _safeArea = v;
                    _pushLiveUpdate();
                  }),
                ),
                _buildSwitchSetting(
                  '开启纯文本无Emoji模式 (noEmojiMode)',
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
      title: const Text('字体字重 (fontWeight)', style: TextStyle(fontSize: 13)),
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
          title: const Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPickerGrid(
              selectedColor: selectedColor,
              onColorSelected: (color) {
                selectedColor = color;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
            TextButton(
              onPressed: () {
                onColorChanged(selectedColor);
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
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

// 简单的颜色选择器网格组件
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
