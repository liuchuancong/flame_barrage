import 'package:flame_barrage/src/model/emoji/emogi_source_type.dart';

class EmojiInfo {
  const EmojiInfo({
    required this.id,
    required this.asset,
    required this.keys,
    this.sourceType = EmojiSourceType.asset,
    this.width = 24,
    this.height = 24,
  });

  /// 唯一标识ID (用于全局检索和二级缓存复用)
  final String id;

  /// 图片物理路径或网络 URL
  final String asset;

  /// 匹配关键字数组 (例如：["[打呼]", "/{dhl", "[doge]"])
  final List<String> keys;

  /// 资产来源与渲染类型
  final EmojiSourceType sourceType;

  /// 在弹幕轨道行内渲染的物理宽度
  final double width;

  /// 在弹幕轨道行内渲染的物理高度
  final double height;
}
