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
          'Flame 弹幕引擎全功能演示',
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
            title: '高并发直播间模拟',
            subtitle: '网络长连接协议清洗与密集流高负载实时劣化降级',
            route: '/live',
            color: const Color(0xFFFF4D4F),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.touch_app_rounded,
            title: '交互式视频遮罩层',
            subtitle: '全视口手势层级拦截与 Canvas 反向矩阵碰撞精密检测',
            route: '/video',
            color: const Color(0xFF1890FF),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.analytics_rounded,
            title: '实时性能度量看板',
            subtitle: '120Hz高刷流帧率精密监控与多级核配置动态热重载',
            route: '/performance',
            color: const Color(0xFF722ED1),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.grid_view_rounded,
            title: '大图集网格对齐裁剪',
            subtitle: 'CSS雪碧大图物理网格自动无损切片，高性能纹理映射',
            route: '/spritesheet',
            color: const Color(0xFF13C2C2),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.card_giftcard_rounded,
            title: '高能礼物连击动效',
            subtitle: '高频多段物理复合缩放弹射 Combo 与生命周期衰减重置',
            route: '/combo',
            color: const Color(0xFFFA8C16),
          ),
          _buildMenuListRow(
            context,
            icon: Icons.tune_rounded,
            title: '配置主控制中心',
            subtitle: '运行时多维度内核池化限额、流控及防追尾间距深度调节',
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
