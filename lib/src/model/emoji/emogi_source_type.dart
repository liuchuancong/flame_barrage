/// 表情包资产的来源与渲染类型
enum EmojiSourceType {
  /// 本地独立静态图片 (单个文件，如 assets/doge.png)
  asset,

  /// 大图集裁剪 (从整张大贴图中通过指定区域坐标获取 不等宽不等高、不规则紧凑排布)
  atlas,

  /// 网络下载 (通过 URL 异步下载并缓存于本地的单图)
  network,

  ///  动态序列帧雪碧图 (多帧合一的横图，等宽等高、规则排列)
  animated,
}
