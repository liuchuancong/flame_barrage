import 'dart:ui' as ui;
import 'package:flame_barrage/flame_barrage.dart';

class MixedLayout {
  MixedLayout({required this.atlas, int maxTextCacheSize = 1000}) : _textCache = TextCache(maxSize: maxTextCacheSize);

  final EmojiAtlas atlas;
  TextCache _textCache;
  final Map<String, LayoutResult> _cache = {};

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
    final cacheKey = '${_buildCacheKey(fragments, config)}|${item.priority}';

    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final result = _layoutInternal(fragments, item, config, cacheKey);
    _cache[cacheKey] = result;

    return result;
  }

  LayoutResult _layoutInternal(List<Fragment> fragments, BarrageItem item, BarrageConfig config, String cacheKey) {
    final spans = <LayoutSpan>[];
    double currentX = 0.0;
    double maxHeight = 0.0;

    final len = fragments.length;
    for (int i = 0; i < len; i++) {
      final fragment = fragments[i];

      if (fragment is TextFragment) {
        final textCacheKey = '${fragment.text}|${config.fontSize}|${config.textColor.toARGB32()}|${config.showStroke}';
        final paragraph = _buildParagraph(fragment.text, config, textCacheKey);

        final width = paragraph.maxIntrinsicWidth;
        final height = paragraph.height;

        if (height > maxHeight) maxHeight = height;

        final interceptors = config.effectInterceptors;
        final intceptorLen = interceptors.length;
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
          spans.add(customSpan);
        } else {
          spans.add(
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
        final image = atlas.image(fragment.emoji.id);
        if (image == null) continue;

        final double width = config.emojiSize;
        final double height = config.emojiSize;

        if (height > maxHeight) maxHeight = height;

        final animation = atlas.getAnimation(fragment.emoji.id);
        final player = animation != null ? SpriteAnimationPlayer(animation: animation) : null;

        spans.add(EmojiLayoutSpan(x: currentX, y: 0.0, width: width, height: height, image: image, player: player));
        currentX += width;
      }
    }

    final spanLen = spans.length;
    for (int i = 0; i < spanLen; i++) {
      final span = spans[i];
      final centeredY = (maxHeight - span.height) / 2.0;

      if (span is TextLayoutSpan) {
        spans[i] = TextLayoutSpan(
          x: span.x,
          y: centeredY,
          width: span.width,
          height: span.height,
          text: span.text,
          paragraph: span.paragraph,
        );
      } else if (span is EmojiLayoutSpan) {
        spans[i] = EmojiLayoutSpan(
          x: span.x,
          y: centeredY,
          width: span.width,
          height: span.height,
          image: span.image,
          player: span.player,
        );
      }
    }

    return LayoutResult(width: currentX, height: maxHeight, spans: spans, cacheKey: cacheKey);
  }

  ui.Paragraph _buildParagraph(String text, BarrageConfig config, String textCacheKey) {
    final cached = _textCache.get(textCacheKey);
    if (cached != null) {
      return cached;
    }

    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: config.fontSize));
    final textStyle = ui.TextStyle(fontSize: config.fontSize, fontWeight: config.fontWeight, color: config.textColor);

    builder.pushStyle(textStyle);
    builder.addText(text);

    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: double.infinity));

    _textCache.put(textCacheKey, paragraph);
    return paragraph;
  }

  String _buildCacheKey(List<Fragment> fragments, BarrageConfig config) {
    final buffer = StringBuffer();

    buffer.write(config.fontSize);
    buffer.write('|');
    buffer.write(config.fontWeight.toString());
    buffer.write('|');
    buffer.write(config.textColor.toARGB32());
    buffer.write('|');
    buffer.write(config.emojiSize);

    final len = fragments.length;
    for (int i = 0; i < len; i++) {
      final fragment = fragments[i];
      if (fragment is TextFragment) {
        buffer.write(fragment.text);
      } else if (fragment is EmojiFragment) {
        buffer.write(fragment.emoji.id);
      }
    }

    return buffer.toString();
  }
}
