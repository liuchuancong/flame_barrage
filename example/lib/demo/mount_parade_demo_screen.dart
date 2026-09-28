import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

/// Mount parade demo: eight entrance/exit effect danmaku (horse, airplane,
/// rocket, UFO, meteor, dragon, ghost, magic carpet). Each performance owns
/// one lane end to end (enter, cruise, exit); mounts are drawn entirely with
class MountParadeDemoScreen extends StatefulWidget {
  const MountParadeDemoScreen({super.key});

  @override
  State<MountParadeDemoScreen> createState() => _MountParadeDemoScreenState();
}

class _MountCard {
  const _MountCard(this.emoji, this.label, this.effect, this.defaultText, this.color);

  final String emoji;
  final String label;
  final BarrageMotionEffect effect;
  final String defaultText;
  final Color color;
}

class _MountParadeDemoScreenState extends State<MountParadeDemoScreen> {
  final BarrageController _controller = BarrageController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _chipScroll = ScrollController();

  late final List<_MountCard> _mounts = const [
    _MountCard('🐎', 'Horse riding', HorseRidingEffect(), 'Giddy up! Coming through 🐎', Color(0xFF8D6E63)),
    _MountCard('✈️', 'Jet airliner', AirplaneEffect(), 'Cleared for takeoff ✈️', Color(0xFF546E7A)),
    _MountCard('🚀', 'Rocket launch', RocketLaunchEffect(), '3, 2, 1, ignition! 🚀', Color(0xFFE53935)),
    _MountCard('🛸', 'UFO cruise', UfoCruiseEffect(), 'Alien visitors scanning your barrages 🛸', Color(0xFF26A69A)),
    _MountCard('🌠', 'Meteor streak', MeteorStreakEffect(), 'Make a wish! 🌠', Color(0xFFFF7043)),
    _MountCard('🐉', 'Dragon swim', DragonSwimEffect(), 'Fortune and prosperity 🐉', Color(0xFFFFB300)),
    _MountCard('👻', 'Ghost drift', GhostDriftEffect(), 'Who am I... where am I... 👻', Color(0xFF90A4AE)),
    _MountCard('🧞', 'Magic carpet', MagicCarpetEffect(), 'Open sesame — anywhere you like 🧞', Color(0xFF8E24AA)),
  ];

  int _selected = 0;
  bool _autoParade = false;
  Timer? _autoTimer;
  int _autoIndex = 0;

  @override
  void initState() {
    super.initState();
    _textController.text = _mounts.first.defaultText;
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _textController.dispose();
    _chipScroll.dispose();
    _controller.detach();
    super.dispose();
  }

  void _selectMount(int index) {
    setState(() {
      _selected = index;
      if (_textController.text.isEmpty ||
          _mounts.any((m) => m.defaultText == _textController.text)) {
        _textController.text = _mounts[index].defaultText;
      }
    });
    _scrollChipIntoView(index);
  }

  void _scrollChipIntoView(int index) {
    if (!_chipScroll.hasClients) return;
    const chipExtent = 112.0;
    final target = (index * chipExtent - _chipScroll.position.viewportDimension / 2 + chipExtent / 2)
        .clamp(0.0, _chipScroll.position.maxScrollExtent);
    _chipScroll.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  void _sendSelected() {
    final mount = _mounts[_selected];
    final content = _textController.text.trim().isEmpty ? mount.defaultText : _textController.text.trim();
    _controller.send(
      BarrageItem(
        content: '${mount.emoji} $content',
        type: BarrageType.scroll,
        priority: 1,
        effect: mount.effect,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _toggleAutoParade() {
    setState(() {
      _autoParade = !_autoParade;
      _autoTimer?.cancel();
      if (_autoParade) {
        // Stage one mount performance per tick; the interval is slightly shorter than a
      // performance so two or three overlap on screen.
        _autoTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
          final mount = _mounts[_autoIndex % _mounts.length];
          _autoIndex++;
          _controller.send(
            BarrageItem(
              content: '${mount.emoji} ${mount.defaultText}',
              type: BarrageType.scroll,
              priority: 1,
              effect: mount.effect,
              fontWeight: FontWeight.w700,
            ),
          );
          _selectMount((_autoIndex - 1) % _mounts.length);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mount Parade · Entrance/Exit Effects')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1026), Color(0xFF141B34), Color(0xFF1C2340)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: FlameBarrageWidget(
                config: const BarrageConfig(
                  trackHeight: 46,
                  fontSize: 19,
                  textColor: Colors.white,
                  showStroke: true,
                  maxVisibleCount: 60,
                ),
                emojiAtlas: EmojiAtlas.instance,
                controller: _controller,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        controller: _chipScroll,
                        scrollDirection: Axis.horizontal,
                        itemCount: _mounts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final mount = _mounts[i];
                          final selected = i == _selected;
                          return _MountChip(
                            emoji: mount.emoji,
                            label: mount.label,
                            color: mount.color,
                            selected: selected,
                            onTap: () => _selectMount(i),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'A line for the mount to carry…',
                              hintStyle: const TextStyle(color: Colors.white38),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mounts[_selected].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          ),
                          onPressed: _sendSelected,
                          child: Text(_mounts[_selected].emoji),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _autoParade ? Colors.amberAccent : Colors.white70,
                              side: BorderSide(color: _autoParade ? Colors.amberAccent : Colors.white24),
                            ),
                            onPressed: _toggleAutoParade,
                            icon: Icon(_autoParade ? Icons.pause_rounded : Icons.auto_mode_rounded, size: 18),
                            label: Text(_autoParade ? 'Parading… tap to pause' : 'Auto parade (8 mounts)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Colors.white24),
                          ),
                          onPressed: () => _controller.clear(),
                          icon: const Icon(Icons.clear_all_rounded, size: 18),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MountChip extends StatelessWidget {
  const _MountChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 104,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : Colors.white12, width: selected ? 1.6 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
