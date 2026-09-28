import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

/// Tap-to-hold interaction demo: tapping a message freezes it in place and
/// opens an action sheet (like / block user / report). Closing the sheet
/// releases the message and it continues scrolling from the exact spot.
class TapPauseDemoScreen extends StatefulWidget {
  const TapPauseDemoScreen({super.key});

  @override
  State<TapPauseDemoScreen> createState() => _TapPauseDemoScreenState();
}

class _TapPauseDemoScreenState extends State<TapPauseDemoScreen> {
  final BarrageController _controller = BarrageController();
  Timer? _feed;
  final Random _random = Random();
  final Set<String> _blockedUsers = {};

  static const List<(String, String)> _chatter = [
    ('user_1001', 'Neo'),
    ('user_1002', 'Trinity'),
    ('user_1003', 'Morpheus'),
    ('user_1004', 'Cypher'),
    ('user_1005', 'Tank'),
  ];

  static const List<String> _lines = [
    'tap me to hold this message',
    'this one can be reported too',
    'like if you agree [滑稽]',
    'try blocking me',
    'still here, still scrolling',
  ];

  @override
  void initState() {
    super.initState();
    _feed = Timer.periodic(const Duration(milliseconds: 900), (_) {
      final (id, name) = _chatter[_random.nextInt(_chatter.length)];
      if (_blockedUsers.contains(id)) return;
      _controller.send(
        BarrageItem(
          content: _lines[_random.nextInt(_lines.length)],
          userId: id,
          userName: name,
        ),
      );
    });
  }

  @override
  void dispose() {
    _feed?.cancel();
    _controller.clear();
    _controller.detach();
    super.dispose();
  }

  Future<void> _onSurfaceTap(TapUpDetails details) async {
    final item = _controller.pauseItemAt(details.localPosition.dx, details.localPosition.dy);
    if (item == null) return;
    if (!mounted) {
      _controller.resumeAllPaused();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E2430),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => _ActionSheet(
        item: item,
        isBlocked: _blockedUsers.contains(item.userId),
        onLike: () {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
            SnackBar(content: Text('Liked ${item.userName ?? item.userId ?? 'anonymous'}\'s message')),
          );
          Navigator.pop(sheetContext);
        },
        onBlock: () {
          if (item.userId != null) _blockedUsers.add(item.userId!);
          Navigator.pop(sheetContext);
        },
        onReport: () {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
            SnackBar(content: Text('Reported ${item.userName ?? item.userId ?? 'anonymous'}')),
          );
          Navigator.pop(sheetContext);
        },
      ),
    );
    // The sheet is gone (action taken or dismissed): release the held
    // message and let it continue from the exact spot it froze at.
    _controller.resumeAllPaused();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tap-to-Hold Interaction')),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onSurfaceTap,
              child: Container(
                color: const Color(0xFF0F1218),
                child: FlameBarrageWidget(
                  config: const BarrageConfig(
                    trackHeight: 44,
                    fontSize: 18,
                    emitInterval: 0.08,
                    baseSpeed: 90,
                    overlapSafeGap: 24,
                    maxVisibleCount: 60,
                    safeArea: false,
                  ),
                  emojiAtlas: EmojiAtlas.instance,
                  controller: _controller,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tap a message to freeze it; the sheet closes and it keeps scrolling. '
                    'Held: ${_controller.pausedCount}   on-screen: ${_controller.activeItemCount}   '
                    'blocked: ${_blockedUsers.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(_controller.resumeAllPaused),
                    child: const Text('Release all held messages'),
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

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.item,
    required this.isBlocked,
    required this.onLike,
    required this.onBlock,
    required this.onReport,
  });

  final BarrageItem item;
  final bool isBlocked;
  final VoidCallback onLike;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final name = item.userName ?? item.userId ?? 'anonymous';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '"${item.content}"  (held in place while this sheet is open)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.favorite_border, color: Colors.pinkAccent),
              title: const Text('Like', style: TextStyle(color: Colors.white)),
              onTap: onLike,
            ),
            ListTile(
              leading: Icon(Icons.block, color: isBlocked ? Colors.grey : Colors.orangeAccent),
              title: Text(
                isBlocked ? 'Already blocked' : 'Block this user',
                style: TextStyle(color: isBlocked ? Colors.grey : Colors.white),
              ),
              onTap: isBlocked ? null : onBlock,
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: onReport,
            ),
            const Divider(height: 24, color: Colors.white12),
            Text(
              'Closing this sheet releases the message automatically.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
