import 'dart:async';
import 'dart:ui' as ui;
import 'barrage_router.dart';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class SpriteSheetDemoScreen extends StatefulWidget {
  const SpriteSheetDemoScreen({super.key});

  @override
  State<SpriteSheetDemoScreen> createState() => _SpriteSheetDemoScreenState();
}

class _SpriteSheetDemoScreenState extends State<SpriteSheetDemoScreen> {
  final BarrageController _controller = BarrageController();
  final AtlasLoader _loader = const AtlasLoader();
  bool _isAtlasReady = false;

  @override
  void initState() {
    super.initState();
    _loadAndRegisterCssSprites();
  }

  Future<void> _loadAndRegisterCssSprites() async {
    try {
      const String assetPath = 'assets/sprites/css_sprites.png';
      final img = await _loader.loadFromAsset(assetPath);

      final atlasInfo = EmojiInfo(
        id: 'css_sprites_atlas',
        keys: const ['[表面呲牙]', '[表面微笑]', '[闭嘴]', '[不看]', '[不理不想]', '[不是吧]', '[不信谣言]', '[擦汗]'],
        asset: assetPath,
        width: img.width.toDouble(),
        height: img.height.toDouble(),
        sourceType: EmojiSourceType.atlas,
      );

      EmojiAtlas.instance.register(atlasInfo);

      final Map<String, ui.Rect> cssEmojiRects = {
        '[表面呲牙]': const ui.Rect.fromLTWH(0, 0, 96, 96),
        '[表面微笑]': const ui.Rect.fromLTWH(96, 0, 96, 96),
        '[闭嘴]': const ui.Rect.fromLTWH(192, 0, 96, 96),
        '[不看]': const ui.Rect.fromLTWH(288, 0, 96, 96),
        '[不理不想]': const ui.Rect.fromLTWH(384, 0, 96, 96),
        '[不是吧]': const ui.Rect.fromLTWH(480, 0, 96, 96),
        '[不信谣言]': const ui.Rect.fromLTWH(576, 0, 96, 96),
        '[擦汗]': const ui.Rect.fromLTWH(672, 0, 96, 96),
      };

      EmojiAtlas.instance.updateAtlasRects(cssEmojiRects);
      EmojiAtlas.instance.resolveLoadedImage(atlasInfo, img);

      if (mounted) {
        setState(() {
          _isAtlasReady = true;
        });
      }
    } catch (e, stack) {
      BarrageLogger.e('SpriteSheetDemo', 'CSS雪碧图解析分配失败', e, stack);
    }
  }

  void _sendMixedBarrage() {
    if (!_isAtlasReady) return;
    _controller.send(
      const BarrageItem(content: 'CSS雪碧图大满贯：[表面呲牙][表面微笑] 现场直刷！[闭嘴][不看][不理不想][不是吧][不信谣言][擦汗]', type: BarrageType.scroll),
    );
  }

  @override
  void dispose() {
    _controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = BarrageRouter.globalConfig;

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'CSS 规范大图集自适应裁剪',
          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    if (_isAtlasReady)
                      Positioned.fill(
                        child: FlameBarrageWidget(
                          key: ValueKey('css_spritesheet_aligned_${currentConfig.hashCode}'),
                          config: currentConfig,
                          emojiAtlas: EmojiAtlas.instance,
                          controller: _controller,
                        ),
                      )
                    else
                      const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00FFCC), Color(0xFF006666)]),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FFCC).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  onPressed: _isAtlasReady ? _sendMixedBarrage : null,
                  icon: const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    '发射CSS大图集混排弹幕',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
