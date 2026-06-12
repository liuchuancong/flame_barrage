import 'barrage_type.dart';

/// 用户发送的弹幕数据
///
/// 不包含任何渲染缓存
/// 不包含位置状态
class BarrageItem {
  const BarrageItem({
    required this.content,
    this.type = BarrageType.scroll,
    this.userId,
    this.userName,
    this.priority = 0,
  });

  /// 弹幕内容
  final String content;

  /// 弹幕类型
  final BarrageType type;

  /// 用户ID
  final String? userId;

  /// 用户昵称
  final String? userName;

  /// 优先级
  final int priority;
}
