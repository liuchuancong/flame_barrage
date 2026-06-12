import 'dart:ui';
import 'mixed_renderer.dart';
import '../../layout/rich_parser.dart';
import '../../core/barrage_config.dart';
import '../../layout/mixed_layout.dart';
import '../../model/barrage/barrage_item.dart';
import '../../model/barrage/barrage_type.dart';

/// 弹幕总渲染器
///
/// 负责：
///
/// BarrageItem
/// ↓
/// Fragment
/// ↓
/// Layout
/// ↓
/// Picture
///
/// 根据弹幕类型分发给不同Renderer
class BarrageRenderer {
  BarrageRenderer({required this.parser, required this.layout, required this.mixedRenderer});

  /// 富文本解析器
  final RichParser parser;

  /// 混排布局器
  final MixedLayout layout;

  /// 普通弹幕渲染器
  final MixedRenderer mixedRenderer;

  /// 渲染弹幕
  ///
  /// 返回可直接缓存的 Picture
  Picture render(BarrageItem item, BarrageConfig config) {
    /// 解析文本
    final fragments = parser.parse(item.content);

    /// 计算布局
    final layoutResult = layout.layout(fragments, config: config);

    /// 分发渲染
    switch (item.type) {
      case BarrageType.scroll:
      case BarrageType.topFixed:
      case BarrageType.bottomFixed:
        return mixedRenderer.buildPicture(layoutResult);
    }
  }

  /// 批量预热
  ///
  /// 用于直播开始时提前缓存热门弹幕
  List<Picture> renderBatch(List<BarrageItem> items, BarrageConfig config) {
    return items.map((e) => render(e, config)).toList();
  }

  String buildCacheKey(BarrageItem item, BarrageConfig config) {
    return [
      item.content,
      item.type.name,
      config.fontSize,
      config.fontWeight.toString(),
      config.textColor.toARGB32(),
      config.emojiSize,
    ].join('_');
  }
}
