import 'package:flame/game.dart';
import '../atlas/emoji_atlas.dart';
import '../core/barrage_config.dart';
import '../core/barrage_engine.dart';
import 'package:flutter/material.dart';
import '../core/barrage_controller.dart';

class FlameBarrageWidget extends StatefulWidget {
  const FlameBarrageWidget({super.key, required this.config, required this.emojiAtlas, required this.controller});

  final BarrageConfig config;
  final EmojiAtlas emojiAtlas;
  final BarrageController controller;

  @override
  State<FlameBarrageWidget> createState() => _FlameBarrageWidgetState();
}

class _FlameBarrageWidgetState extends State<FlameBarrageWidget> {
  late final BarrageEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = BarrageEngine(config: widget.config, emojiAtlas: widget.emojiAtlas);
    widget.controller.attach(_engine);
  }

  @override
  void didUpdateWidget(covariant FlameBarrageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach();
      widget.controller.attach(_engine);
    }
  }

  @override
  void dispose() {
    widget.controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: GameWidget(game: _engine));
  }
}
