import 'dart:ui' as ui;
import 'package:flame_barrage/flame_barrage.dart';

class MixedLayout {
  MixedLayout({required this.atlas, int maxTextCacheSize = 1000}) : _textCache = TextCache(maxSize: maxTextCacheSize);

  final EmojiAtlas atlas;
  TextCache _textCache;
  final Map<int, LayoutResult> _cache = {};
  final List<LayoutSpan> _reusableSpans = [];

  int get cacheCount => _cache.length;

  void updateMaxTextCacheSize(int newSize) {
    if (_textCache.maxSize == newSize) return;
    final newCache = TextCache(maxSize: newSize);
    _textCache.clear();
    _textCache = newCache;
    _cache.clear();
  }

  void clearCache() {
    _cache.clear();
    _textCache.clear();
  }

  LayoutResult layout(List<Fragment> fragments, {required BarrageItem item, required BarrageConfig config}) {
    final int combinedHash = _buildNumericCacheKey(fragments, config, item.priority);

    final cached = _cache[combinedHash];
    if (cached != null) {
      return cached;
    }

    final result = _layoutInternal(fragments, item, config, combinedHash);
    _cache[combinedHash] = result;

    return result;
  }

  LayoutResult _layoutInternal(List<Fragment> fragments, BarrageItem item, BarrageConfig config, int combinedHash) {
    _reusableSpans.clear();
    double currentX = 0.0;
    double maxHeight = 0.0;

    final int colorValue = config.textColor.toARGB32();
    final double fontSize = config.fontSize;
    final bool showStroke = config.showStroke;
    final List<BarrageEffectInterceptor> interceptors = config.effectInterceptors;
    final int intceptorLen = interceptors.length;

    final int len = fragments.length;
    for (int i = 0; i < len; i++) {
      final fragment = fragments[i];

      if (fragment is TextFragment) {
        final textCacheKey = '${fragment.text}|$fontSize|$colorValue|$showStroke';
        final paragraph = _buildParagraph(fragment.text, config, textCacheKey);

        final width = paragraph.maxIntrinsicWidth;
        final height = paragraph.height;

        if (height > maxHeight) maxHeight = height;

        dynamic matchedInterceptor;
        for (int j = 0; j < intceptorLen; j++) {
          if (interceptors[j].shouldIntercept(item, config)) {
            matchedInterceptor = interceptors[j];
            break;
          }
        }

        if (matchedInterceptor != null) {
          final customSpan = matchedInterceptor.createCustomSpan(
            item: item,
            text: fragment.text,
            paragraph: paragraph,
            x: currentX,
            y: 0.0,
            width: width,
            height: height,
            config: config,
          );
          _reusableSpans.add(customSpan);
        } else {
          _reusableSpans.add(
            TextLayoutSpan(
              x: currentX,
              y: 0.0,
              width: width,
              height: height,
              text: fragment.text,
              paragraph: paragraph,
            ),
          );
        }
        currentX += width;
      } else if (fragment is EmojiFragment) {
        if (config.noEmojiMode) continue;

        final image = atlas.image(fragment.emoji.id);
        if (image == null) continue;

        final double width = config.emojiSize;
        final double height = config.emojiSize;

        if (height > maxHeight) maxHeight = height;

        final animation = atlas.getAnimation(fragment.emoji.id);
        final player = animation != null ? SpriteAnimationPlayer(animation: animation) : null;

        _reusableSpans.add(
          EmojiLayoutSpan(x: currentX, y: 0.0, width: width, height: height, image: image, player: player),
        );
        currentX += width;
      }
    }

    final spanLen = _reusableSpans.length;
    final finalSpans = List<LayoutSpan>.generate(spanLen, (index) {
      final span = _reusableSpans[index];
      final centeredY = (maxHeight - span.height) / 2.0;

      if (span is TextLayoutSpan) {
        return TextLayoutSpan(
          x: span.x,
          y: centeredY,
          width: span.width,
          height: span.height,
          text: span.text,
          paragraph: span.paragraph,
        );
      } else {
        final emojiSpan = span as EmojiLayoutSpan;
        return EmojiLayoutSpan(
          x: emojiSpan.x,
          y: centeredY,
          width: emojiSpan.width,
          height: emojiSpan.height,
          image: emojiSpan.image,
          player: emojiSpan.player,
        );
      }
    });

    return LayoutResult(width: currentX, height: maxHeight, spans: finalSpans, cacheKey: combinedHash.toString());
  }

  ui.Paragraph _buildParagraph(String text, BarrageConfig config, String textCacheKey) {
    final cached = _textCache.get(textCacheKey);
    if (cached != null) {
      return cached;
    }

    // 终极优化：强制注入 height: 1.0 固定物理单行度量，暴砍 C++ 矢量字符探边开销
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize, height: 1.0));
    final textStyle = ui.TextStyle(fontSize: config.fontSize, fontWeight: config.fontWeight, color: config.textColor);

    builder.pushStyle(textStyle);
    builder.addText(text);

    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: double.infinity));

    _textCache.put(textCacheKey, paragraph);
    return paragraph;
  }

  int _buildNumericCacheKey(List<Fragment> fragments, BarrageConfig config, int priority) {
    int hash = 17;
    hash = 37 * hash + config.fontSize.hashCode;
    hash = 37 * hash + config.fontWeight.hashCode;
    hash = 37 * hash + config.textColor.toARGB32().hashCode;
    hash = 37 * hash + config.emojiSize.hashCode;
    hash = 37 * hash + priority.hashCode;

    final len = fragments.length;
    for (int i = 0; i < len; i++) {
      final fragment = fragments[i];
      if (fragment is TextFragment) {
        hash = 37 * hash + fragment.text.hashCode;
      } else if (fragment is EmojiFragment) {
        hash = 37 * hash + fragment.emoji.id.hashCode;
      }
    }
    return hash;
  }
}
