import 'fragment.dart';
import 'text_fragment.dart';
import 'emoji_fragment.dart';
import '../atlas/emoji_atlas.dart';

/// 富文本解析器
///
/// 负责：
///
/// String
/// ↓
/// Fragment List
///
/// 示例：
///
/// Hello [doge]
///
/// ↓
///
/// [
///   TextFragment("Hello "),
///   EmojiFragment(...)
/// ]
class RichParser {
  RichParser({required this.atlas, this.maxCacheSize = 2000});

  final EmojiAtlas atlas;

  /// 解析缓存
  ///
  /// key:
  ///   原始文本
  ///
  /// value:
  ///   Fragment列表
  final Map<String, List<Fragment>> _cache = {};
  final int maxCacheSize;

  /// 当前缓存数量
  int get cacheCount => _cache.length;

  /// 是否存在缓存
  bool containsCache(String content) {
    return _cache.containsKey(content);
  }

  /// 清空缓存
  void clearCache() {
    _cache.clear();
  }

  /// 删除指定缓存
  void removeCache(String content) {
    _cache.remove(content);
  }

  /// 解析文本
  List<Fragment> parse(String content) {
    if (content.isEmpty) {
      return const [];
    }

    /// 命中缓存
    final cached = _cache[content];

    if (cached != null) {
      return cached;
    }

    final List<Fragment> fragments = List<Fragment>.unmodifiable(_parseInternal(content));

    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[content] = fragments;

    return fragments;
  }

  List<Fragment> _parseInternal(String content) {
    final regex = atlas.regex;

    if (regex == null || !regex.hasMatch(content)) {
      return [TextFragment(content)];
    }

    final result = <Fragment>[];

    int lastIndex = 0;

    for (final match in regex.allMatches(content)) {
      /// 前面的普通文本
      if (match.start > lastIndex) {
        result.add(TextFragment(content.substring(lastIndex, match.start)));
      }

      final key = match.group(0);

      if (key != null) {
        final emoji = atlas.find(key);

        if (emoji != null) {
          result.add(EmojiFragment(emoji));
        } else {
          /// 理论不会进入
          result.add(TextFragment(key));
        }
      }

      lastIndex = match.end;
    }

    /// 尾部文字
    if (lastIndex < content.length) {
      result.add(TextFragment(content.substring(lastIndex)));
    }

    return result;
  }

  /// 预热解析
  ///
  /// 直播场景可提前解析热门弹幕
  void warmUp(Iterable<String> contents) {
    for (final content in contents) {
      parse(content);
    }
  }

  /// 调试信息
  Map<String, dynamic> debugInfo() {
    return {'cacheCount': _cache.length};
  }
}
