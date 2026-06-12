import 'dart:ui' as ui;
import 'fragment.dart';
import 'layout_span.dart';
import 'layout_result.dart';
import 'text_fragment.dart';
import 'emoji_fragment.dart';
import '../cache/text_cache.dart';
import '../atlas/emoji_atlas.dart';
import '../core/barrage_config.dart';
import '../effect/stroke_effect.dart';
import '../effect/shadow_effect.dart';
import '../animation/sprite_animation_player.dart';

class MixedLayout {
  MixedLayout({required this.atlas}) : _textCache = TextCache(maxSize: 1000);

  final EmojiAtlas atlas;
  final TextCache _textCache;
  final Map<String, LayoutResult> _cache = {};

  int get cacheCount => _cache.length;

  void clearCache() {
    _cache.clear();
    _textCache.clear();
  }

  LayoutResult layout(List<Fragment> fragments, {required BarrageConfig config}) {
    final cacheKey = _buildCacheKey(fragments, config);

    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final result = _layoutInternal(fragments, config, cacheKey);
    _cache[cacheKey] = result;

    return result;
  }

  LayoutResult _layoutInternal(List<Fragment> fragments, BarrageConfig config, String cacheKey) {
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
        currentX += width;
      } else if (fragment is EmojiFragment) {
        final image = atlas.image(fragment.emoji.id);
        if (image == null) continue;

        final width = fragment.emoji.width <= 0 ? config.emojiSize : fragment.emoji.width;
        final height = fragment.emoji.height <= 0 ? config.emojiSize : fragment.emoji.height;

        if (height > maxHeight) maxHeight = height;

        final animation = atlas.getAnimation(fragment.emoji.id);
        final player = animation != null ? SpriteAnimationPlayer(animation: animation) : null;

        spans.add(
          EmojiLayoutSpan(
            x: currentX,
            y: 0.0,
            width: width,
            height: height,
            image: image,
            player: player,
          ),
        );
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
    final multiShadows = const ShadowEffect().createMultiShadows();

    final textStyle = ui.TextStyle(
      fontSize: config.fontSize,
      fontWeight: config.fontWeight,
      color: config.textColor,
      shadows: multiShadows,
    );

    builder.pushStyle(textStyle);
    builder.addText(text);

    if (config.showStroke) {
      final strokePaint = StrokeEffect(strokeColor: config.strokeColor, strokeWidth: 2.0).createStrokePaint();
      final strokeStyle = ui.TextStyle(
        foreground: strokePaint,
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      );
      builder.pushStyle(strokeStyle);
      builder.addText(text);
    }

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