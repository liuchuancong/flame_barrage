import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class ComboAnimationDemoScreen extends StatefulWidget {
  const ComboAnimationDemoScreen({super.key});

  @override
  State<ComboAnimationDemoScreen> createState() => _ComboAnimationDemoScreenState();
}

class _ComboAnimationDemoScreenState extends State<ComboAnimationDemoScreen> {
  late final ComboTestGame _game;
  int _comboCount = 0;
  ComboAnimation? _activeComboAnimation;

  @override
  void initState() {
    super.initState();
    _game = ComboTestGame();
  }

  void _triggerGiftCombo() {
    setState(() {
      _comboCount++;
    });

    if (_activeComboAnimation != null && !_activeComboAnimation!.isRemoving && _activeComboAnimation!.isMounted) {
      _activeComboAnimation!.updateCount(_comboCount);
    } else {
      _activeComboAnimation = ComboAnimation(count: _comboCount, startPosition: Vector2(40, 100));
      _game.add(_activeComboAnimation!);
    }
  }

  void _resetComboStream() {
    setState(() {
      _comboCount = 0;
    });
    _activeComboAnimation?.removeFromParent();
    _activeComboAnimation = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('礼物连击 Combo 特效测试')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: const Color(0xFF1A1A1A),
                  child: Center(
                    child: Text('当前连续送礼次数: $_comboCount', style: const TextStyle(color: Colors.white24, fontSize: 18)),
                  ),
                ),
                Positioned.fill(child: GameWidget(game: _game)),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _triggerGiftCombo,
                      icon: const Icon(Icons.card_giftcard, color: Colors.black87),
                      label: const Text(
                        '送出小电视 (Combo!)',
                        style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.white10),
                    onPressed: _resetComboStream,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ComboTestGame extends FlameGame {
  @override
  Color backgroundColor() => Colors.transparent;
}
