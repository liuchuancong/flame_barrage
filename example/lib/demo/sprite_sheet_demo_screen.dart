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
    _loadAndRegisterGridAtlas();
  }

  Future<void> _loadAndRegisterGridAtlas() async {
    try {
      final atlasInfo = const EmojiInfo(
        id: 'css_sprites_atlas',
        keys: ['[表情1]', '[表情2]', '[表情3]', '[表情4]'],
        asset: 'assets/sprites/css_sprites.png',
        width: 24,
        height: 24,
        sourceType: EmojiSourceType.atlas,
      );

      EmojiAtlas.instance.register(atlasInfo);
      final img = await _loader.loadFromAsset(atlasInfo.asset);

      final gridCalculator = SpriteSheet(
        imageWidth: img.width.toDouble(),
        imageHeight: img.height.toDouble(),
        rows: 1,
        columns: 4,
      );

      final Map<String, ui.Rect> subEmojiRects = {};
      final len = atlasInfo.keys.length;
      for (int i = 0; i < len; i++) {
        subEmojiRects[atlasInfo.keys[i]] = gridCalculator.getSpriteRect(i);
      }

      EmojiAtlas.instance.updateAtlasRects(subEmojiRects);
      EmojiAtlas.instance.resolveLoadedImage(atlasInfo, img);

      setState(() {
        _isAtlasReady = true;
      });
    } catch (e, stack) {
      BarrageLogger.e('SpriteSheetDemo', '网格图集对齐裁剪失败', e, stack);
    }
  }

  void _sendMixedBarrage() {
    if (!_isAtlasReady) return;
    _controller.send(const BarrageItem(content: '矩阵对齐弹幕：[表情1][表情2] 顺畅渲染！[表情3][表情4]', type: BarrageType.scroll));
  }

  @override
  void dispose() {
    _controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('大图集网格对齐裁剪')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  if (_isAtlasReady)
                    Positioned.fill(
                      child: FlameBarrageWidget(
                        config: BarrageRouter.globalConfig,
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, minimumSize: const Size.fromHeight(50)),
                onPressed: _isAtlasReady ? _sendMixedBarrage : null,
                icon: const Icon(Icons.grid_on, color: Colors.white),
                label: const Text('发射大图集混排弹幕', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
