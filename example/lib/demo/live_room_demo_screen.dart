import 'dart:math';
import 'dart:async';
import 'barrage_router.dart';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class LiveRoomDemoScreen extends StatefulWidget {
  const LiveRoomDemoScreen({super.key});

  @override
  State<LiveRoomDemoScreen> createState() => _LiveRoomDemoScreenState();
}

class _LiveRoomDemoScreenState extends State<LiveRoomDemoScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: BarrageLiveBody());
  }
}

class BarrageLiveBody extends StatefulWidget {
  const BarrageLiveBody({super.key});

  @override
  State<BarrageLiveBody> createState() => _BarrageLiveBodyState();
}

class _BarrageLiveBodyState extends State<BarrageLiveBody> {
  final BarrageController _controller = BarrageController();
  final MessageProtocol _messageProtocol = const MessageProtocol();
  final TextEditingController _textController = TextEditingController();
  Timer? _wsMockTimer;
  bool _isConnected = false;
  bool _isEngineReady = false;

  final List<Map<String, dynamic>> _customEmojiJsonRegistry = [
    {"sId": "15", "sName": "", "sEscape": "/{66", "local_file": "15.png"},
    {"sId": "87", "sName": "[打呼]", "sEscape": "/{dhl", "local_file": "87.png"},
    {"sId": "89", "sName": "[滑稽]", "sEscape": "/{hj", "local_file": "89.png"},
    {"sId": "91", "sName": "[难受]", "sEscape": "/{ns", "local_file": "91.png"},
    {"sId": "95", "sName": "[亲亲]", "sEscape": "/{kiss", "local_file": "95.png"},
    {"sId": "97", "sName": "[无辜]", "sEscape": "/{wg", "local_file": "97.png"},
    {"sId": "99", "sName": "[震惊]", "sEscape": "/{zj", "local_file": "99.png"},
    {"sId": "1", "sName": "[大笑]", "sEscape": "/{dx", "local_file": "1.png"},
    {"sId": "3", "sName": "[送花]", "sEscape": "/{sh", "local_file": "3.png"},
    {"sId": "9", "sName": "[偷笑]", "sEscape": "/{tx", "local_file": "9.png"},
    {"sId": "11", "sName": "[大哭]", "sEscape": "/{dk", "local_file": "11.png"},
    {"sId": "13", "sName": "[嘿哈]", "sEscape": "/{hh", "local_file": "13.png"},
    {"sId": "17", "sName": "[感动]", "sEscape": "/{gd", "local_file": "17.png"},
    {"sId": "19", "sName": "[疑问]", "sEscape": "/{yw", "local_file": "19.png"},
    {"sId": "21", "sName": "[喜欢]", "sEscape": "/{xh", "local_file": "21.png"},
    {"sId": "23", "sName": "[奸笑]", "sEscape": "/{jx", "local_file": "23.png"},
    {"sId": "25", "sName": "[赞]", "sEscape": "/{zan", "local_file": "25.png"},
    {"sId": "27", "sName": "[可爱]", "sEscape": "/{ka", "local_file": "27.png"},
    {"sId": "29", "sName": "[傲慢]", "sEscape": "/{am", "local_file": "29.png"},
    {"sId": "31", "sName": "[开心]", "sEscape": "/{kx", "local_file": "31.png"},
    {"sId": "33", "sName": "[拜拜]", "sEscape": "/{88", "local_file": "33.png"},
    {"sId": "35", "sName": "[害羞]", "sEscape": "/{hx", "local_file": "35.png"},
    {"sId": "37", "sName": "[衰]", "sEscape": "/{zs", "local_file": "37.png"},
  ];

  final List<Map<String, dynamic>> _mockWsPackets = [
    {'content': '全屏走一波！！！', 'type': 'scroll', 'vip': true},
    {'content': '主播操作有点迷啊 [滑稽]', 'type': 'scroll', 'vip': false},
    {'content': '看得我直接 [震惊] 了', 'type': 'scroll', 'vip': true},
    {'content': '送上一朵小红花 [送花]', 'type': 'scroll', 'vip': false},
    {'content': '完蛋，又要白给了 [难受]', 'type': 'scroll', 'vip': false},
    {'content': '前方名场面高能预警！', 'type': 'topFixed', 'vip': true},
    {'content': '下播了下播了，大家 [拜拜]', 'type': 'bottomFixed', 'vip': false},
  ];

  @override
  void initState() {
    super.initState();
    _asyncRegisterAndDecodePipeline();
  }

  Future<void> _asyncRegisterAndDecodePipeline() async {
    final List<EmojiInfo> autoList = [];
    final len = _customEmojiJsonRegistry.length;

    for (int i = 0; i < len; i++) {
      final node = _customEmojiJsonRegistry[i];
      final String sid = node['sId'] as String;
      final String sname = node['sName'] as String? ?? '';
      final String sescape = node['sEscape'] as String? ?? '';

      final List<String> validKeys = [];
      if (sname.trim().isNotEmpty) validKeys.add(sname.trim());
      if (sescape.trim().isNotEmpty) validKeys.add(sescape.trim());

      if (validKeys.isEmpty) continue;

      autoList.add(
        EmojiInfo(
          id: 'emoji_$sid',
          keys: validKeys,
          asset: 'assets/emoji/$sid.png',
          width: 24.0,
          height: 24.0,
          sourceType: EmojiSourceType.asset,
        ),
      );
    }

    EmojiAtlas.instance.registerAll(autoList);

    await EmojiAtlas.instance.preloadAll();

    if (mounted) {
      setState(() {
        _isEngineReady = true;
      });
    }
  }

  void _toggleWebSocketConnection() {
    if (!_isEngineReady) return;
    setState(() {
      _isConnected = !_isConnected;
    });

    if (_isConnected) {
      final random = Random();
      _wsMockTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
        final rawPacket = _mockWsPackets[random.nextInt(_mockWsPackets.length)];
        final barrageItem = _messageProtocol.fromWebSocketJson(rawPacket);
        if (barrageItem != null) {
          _controller.send(barrageItem);
        }
      });
    } else {
      _wsMockTimer?.cancel();
      _wsMockTimer = null;
    }
  }

  void _sendSingleMessage(BarrageType type) {
    if (!_isEngineReady || _textController.text.trim().isEmpty) return;
    _controller.send(BarrageItem(content: _textController.text.trim(), type: type, priority: 1));
    _textController.clear();
  }

  void _quickSendEmoji(String tag) {
    if (!_isEngineReady) return;
    _controller.send(BarrageItem(content: tag, type: BarrageType.scroll, priority: 1));
  }

  void _togglePauseEngine() {
    if (!_isEngineReady) return;
    if (_controller.running) {
      _controller.pause();
    } else {
      _controller.resume();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _wsMockTimer?.cancel();
    _textController.dispose();
    _controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('高并发直播间模拟')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(color: Colors.black),
                Positioned.fill(
                  child: _isEngineReady
                      ? FlameBarrageWidget(
                          config: BarrageRouter.globalConfig,
                          emojiAtlas: EmojiAtlas.instance,
                          controller: _controller,
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.orangeAccent),
                              SizedBox(height: 12),
                              Text('正在为您原地异步硬解图片纹理...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.sentiment_very_satisfied, size: 16, color: Colors.orangeAccent),
                          label: const Text('滑稽'),
                          onPressed: () => _quickSendEmoji('这波真骚 [滑稽]'),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.bolt, size: 16, color: Colors.cyanAccent),
                          label: const Text('震惊'),
                          onPressed: () => _quickSendEmoji('我的天呐 [震惊]'),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.card_giftcard, size: 16, color: Colors.pinkAccent),
                          label: const Text('送花'),
                          onPressed: () => _quickSendEmoji('给主播点赞 [送花]'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: '输入文本或使用上方快捷表情...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: () => _sendSingleMessage(BarrageType.scroll), child: const Text('发送')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _isConnected ? Colors.red : Colors.green),
                        onPressed: _toggleWebSocketConnection,
                        child: Text(_isConnected ? '断开长连接' : '开启高并发长连接 (WS)'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _controller.running ? Colors.blue : Colors.orange,
                        ),
                        onPressed: _togglePauseEngine,
                        child: Text(_controller.running ? '暂停弹幕' : '恢复弹幕'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        onPressed: () => _controller.clear(),
                        child: const Text('一键清屏'),
                      ),
                    ],
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
