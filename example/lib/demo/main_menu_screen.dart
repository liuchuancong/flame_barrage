import 'package:flutter/material.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'FlameBarrage Engine Full-Feature Demo',
          style: TextStyle(color: Color(0xFF1F2328), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          _buildMenuListRow(
            context,
            icon: Icons.live_tv_rounded,
            title: 'High-concurrency live room',
            subtitle: 'Wire protocol parsing under a dense, high-load message stream',
            route: '/live',
            color: const Color(0xFFFF4D4F),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.format_size_rounded,
            title: 'Per-item BarrageItem styles',
            subtitle: 'Per-message fontFamily, size, weight, stroke and speed overrides',
            route: '/item_style_demo',
            color: const Color(0xFF722ED1),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.crop_landscape_rounded,
            title: 'Multi-surface, single controller',
            subtitle: 'Fullscreen and PiP surfaces sharing one BarrageController',
            route: '/multi_screen_barrage',
            color: const Color(0xFF1890FF),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.touch_app_rounded,
            title: 'Interactive video overlay',
            subtitle: 'Gesture layering over the viewport with precise hit testing',
            route: '/video',
            color: const Color(0xFF1890FF),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.analytics_rounded,
            title: 'Live performance dashboard',
            subtitle: 'FPS monitoring at high refresh rates with live config hot-reload',
            route: '/performance',
            color: const Color(0xFF722ED1),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.grid_view_rounded,
            title: 'Sprite sheet slicing',
            subtitle: 'Automatic lossless slicing of a CSS sprite sheet into textures',
            route: '/spritesheet',
            color: const Color(0xFF13C2C2),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.card_giftcard_rounded,
            title: 'Gift combo animation',
            subtitle: 'Combo pop animation with scale bounce and lifetime decay',
            route: '/combo',
            color: const Color(0xFFFA8C16),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.auto_awesome_motion_rounded,
            title: 'Visual effects gallery',
            subtitle: 'Stage-level composite effects: outline, shadow, neon and gradients',
            route: '/effects_preview',
            color: const Color.fromARGB(255, 155, 32, 42),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.emoji_transportation_rounded,
            title: 'Mount parade effects',
            subtitle: 'Eight hand-drawn Canvas mounts with particles and choreographed entrances',
            route: '/mount_parade',
            color: const Color(0xFF00BFA5),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.extension_rounded,
            title: 'Pluggable custom effects',
            subtitle: 'Drop in your own interceptors and LayoutSpans to render custom visuals',
            route: '/custom_effect',
            color: const Color(0xFF9254DE),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.developer_board_rounded,
            title: 'On-device memory monitor',
            subtitle: '300 msg/s flood with quantified Picture/VRAM release observability',
            route: '/memory',
            color: const Color(0xFF001529),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.tune_rounded,
            title: 'Configuration console',
            subtitle: 'Runtime tuning of pools, caches, flow control and safe spacing',
            route: '/config_panel',
            color: const Color(0xFF52C41A),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuListRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2328)),
                      ),
                      const SizedBox(height: 3),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF57606A), height: 1.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF8C95A0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
