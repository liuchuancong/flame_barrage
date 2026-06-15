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
  late double _fontSize;
  late FontWeight _fontWeight;
  late bool _showStroke;
  late double _area;
  late int _maxTrackCount;
  late double _trackHeight;
  late double _emojiSize;

  late int _maxVisibleCount;
  late int _dangerousQueueSize;
  late int _massiveModeThreshold;
  late double _normalEmitInterval;
  late double _massiveEmitInterval;

  late int _barragePoolMaxSize;
  late int _pictureCacheMaxSize;
  late int _textCacheMaxSize;
  late double _overlapSafeGap;

  late bool _hideTop;
  late bool _hideBottom;
  late bool _hideScroll;

  @override
  void initState() {
    super.initState();
    _loadConfigValues(widget.initialConfig);
  }

  void _loadConfigValues(BarrageConfig config) {
    _fontSize = config.fontSize;
    _fontWeight = config.fontWeight;
    _showStroke = config.showStroke;
    _area = config.area;
    _maxTrackCount = config.maxTrackCount;
    _trackHeight = config.trackHeight;
    _emojiSize = config.emojiSize;
    _maxVisibleCount = config.maxVisibleCount;
    _dangerousQueueSize = config.dangerousQueueSize;
    _massiveModeThreshold = config.massiveModeThreshold;
    _normalEmitInterval = config.normalEmitInterval;
    _massiveEmitInterval = config.massiveEmitInterval;
    _barragePoolMaxSize = config.barragePoolMaxSize;
    _pictureCacheMaxSize = config.pictureCacheMaxSize;
    _textCacheMaxSize = config.textCacheMaxSize;
    _overlapSafeGap = config.overlapSafeGap;
    _hideTop = config.hideTop;
    _hideBottom = config.hideBottom;
    _hideScroll = config.hideScroll;
  }

  void _saveAndApply() {
    final updatedConfig = widget.initialConfig.copyWith(
      fontSize: _fontSize,
      fontWeight: _fontWeight,
      showStroke: _showStroke,
      area: _area,
      maxTrackCount: _maxTrackCount,
      trackHeight: _trackHeight,
      emojiSize: _emojiSize,
      maxVisibleCount: _maxVisibleCount,
      dangerousQueueSize: _dangerousQueueSize,
      massiveModeThreshold: _massiveModeThreshold,
      normalEmitInterval: _normalEmitInterval,
      massiveEmitInterval: _massiveEmitInterval,
      barragePoolMaxSize: _barragePoolMaxSize,
      pictureCacheMaxSize: _pictureCacheMaxSize,
      textCacheMaxSize: _textCacheMaxSize,
      overlapSafeGap: _overlapSafeGap,
      hideTop: _hideTop,
      hideBottom: _hideBottom,
      hideScroll: _hideScroll,
    );
    widget.onConfigChanged(updatedConfig);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('内核配置重载成功，已实时应用到渲染管线！')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('弹幕引擎内核高级配置控制台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: _saveAndApply,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('🎨 视觉样式与图层空间'),
          _buildSliderSetting('字体大小 (fontSize)', _fontSize, 12, 36, 1, (v) => setState(() => _fontSize = v)),
          _buildDropdownFontWeight(),
          _buildSwitchSetting('开启硬核文字描边 (showStroke)', _showStroke, (v) => setState(() => _showStroke = v)),
          _buildSliderSetting('屏幕垂直空间占用比 (area)', _area, 0.1, 1.0, 0.05, (v) => setState(() => _area = v)),
          _buildSliderSetting(
            '最大轨道数量 (maxTrackCount)',
            _maxTrackCount.toDouble(),
            1,
            30,
            1,
            (v) => setState(() => _maxTrackCount = v.toInt()),
          ),
          _buildSliderSetting(
            '单物理轨道高度 (trackHeight)',
            _trackHeight,
            24,
            60,
            1,
            (v) => setState(() => _trackHeight = v),
          ),
          _buildSliderSetting(
            '行内 Emoji 渲染尺寸 (emojiSize)',
            _emojiSize,
            16,
            48,
            1,
            (v) => setState(() => _emojiSize = v),
          ),

          const Divider(height: 32),
          _buildSectionTitle('⚡ 高并发流控与发射频率'),
          _buildSliderSetting(
            '同屏最大可见弹幕数 (maxVisibleCount)',
            _maxVisibleCount.toDouble(),
            10,
            300,
            5,
            (v) => setState(() => _maxVisibleCount = v.toInt()),
          ),
          _buildSliderSetting(
            '高负载危险队列截断上限 (dangerousQueueSize)',
            _dangerousQueueSize.toDouble(),
            50,
            1000,
            25,
            (v) => setState(() => _dangerousQueueSize = v.toInt()),
          ),
          _buildSliderSetting(
            '进入高并发模式阈值 (massiveModeThreshold)',
            _massiveModeThreshold.toDouble(),
            10,
            200,
            5,
            (v) => setState(() => _massiveModeThreshold = v.toInt()),
          ),
          _buildSliderSetting(
            '普通发射间隔 (normalEmitInterval)',
            _normalEmitInterval,
            0.02,
            1.0,
            0.02,
            (v) => setState(() => _normalEmitInterval = v),
          ),
          _buildSliderSetting(
            '高并发发射间隔 (massiveEmitInterval)',
            _massiveEmitInterval,
            0.01,
            0.2,
            0.01,
            (v) => setState(() => _massiveEmitInterval = v),
          ),

          const Divider(height: 32),
          _buildSectionTitle('📦 零开销对象池与物理二级缓存上限'),
          _buildSliderSetting(
            'BarrageComponent 对象池上限',
            _barragePoolMaxSize.toDouble(),
            50,
            500,
            10,
            (v) => setState(() => _barragePoolMaxSize = v.toInt()),
          ),
          _buildSliderSetting(
            'Picture 位图硬件缓存上限',
            _pictureCacheMaxSize.toDouble(),
            50,
            1000,
            25,
            (v) => setState(() => _pictureCacheMaxSize = v.toInt()),
          ),
          _buildSliderSetting(
            'Paragraph 文本渲染缓存上限',
            _textCacheMaxSize.toDouble(),
            100,
            3000,
            50,
            (v) => setState(() => _textCacheMaxSize = v.toInt()),
          ),

          const Divider(height: 32),
          _buildSectionTitle('🛡️ 防追尾安全策略'),
          _buildSliderSetting(
            '防重叠绝对安全间距 (overlapSafeGap)',
            _overlapSafeGap,
            0.0,
            150.0,
            5.0,
            (v) => setState(() => _overlapSafeGap = v),
          ),

          const Divider(height: 32),
          _buildSectionTitle('🚫 视口黑名单智能过滤'),
          _buildSwitchSetting('智能隐藏顶部固定弹幕', _hideTop, (v) => setState(() => _hideTop = v)),
          _buildSwitchSetting('智能隐藏底部固定弹幕', _hideBottom, (v) => setState(() => _hideBottom = v)),
          _buildSwitchSetting('智能隐藏普通滚动弹幕', _hideScroll, (v) => setState(() => _hideScroll = v)),
          const SizedBox(height: 40),
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
        items: weights.map((w) => DropdownMenuItem(value: w, child: Text(w.toString().split('.').last))).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _fontWeight = v);
        },
      ),
    );
  }
}
