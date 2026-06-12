import 'dart:ui';
import 'barrage_item.dart';

class BarrageEntry {
  BarrageEntry({required this.item, required this.creationTime});

  /// 原始弹幕
  final BarrageItem item;

  /// 创建时间(ms)
  final int creationTime;

  /// X坐标
  double x = 0;

  /// Y坐标
  double y = 0;

  /// 宽度
  double width = 0;

  /// 高度
  double height = 0;

  /// 所属轨道
  int track = -1;

  /// 新增
  double speed = 0;

  /// 是否激活
  bool active = true;

  /// 生命周期
  double lifeTime = 0;

  /// 上次绘制时间
  int? lastDrawTick;

  /// 文本布局缓存
  Paragraph? paragraph;

  /// 描边缓存
  Paragraph? strokeParagraph;

  /// Picture缓存
  Picture? picture;

  String? pictureCacheKey;

  /// 宽度缓存
  double? cachedWidth;
}
