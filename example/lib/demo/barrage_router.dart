import 'main_menu_screen.dart';
import 'miti_screen_barrage.dart';
import 'asset_loading_screen.dart';
import 'live_room_demo_screen.dart';
import 'memory_profile_screen.dart';
import 'effects_preview_screen.dart';
import 'performance_demo_screen.dart';
import 'package:flutter/material.dart';
import 'video_player_demo_screen.dart';
import 'sprite_sheet_demo_screen.dart';
import 'custom_effect_demo_screen.dart';
import 'combo_animation_demo_screen.dart';
import 'barrage_config_panel_screen.dart';
import 'barrage_item_style_demo_screen.dart';
import 'package:flame_barrage/flame_barrage.dart';

class BarrageRouter {
  static BarrageConfig globalConfig = const BarrageConfig(trackHeight: 40, maxVisibleCount: 150);

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) => const MainMenuScreen(),
      '/live': (context) => const LiveRoomDemoScreen(),
      '/video': (context) => const VideoPlayerDemoScreen(),
      '/performance': (context) => const PerformanceDemoScreen(),
      '/loading': (context) => const AssetLoadingScreen(),
      '/spritesheet': (context) => const SpriteSheetDemoScreen(),
      '/combo': (context) => const ComboAnimationDemoScreen(),
      '/custom_effect': (context) => const CustomEffectDemoScreen(),
      '/memory': (context) => const MemoryProfileScreen(),
      '/effects_preview': (context) => const EffectsPreviewScreen(),
      '/config_panel': (context) => BarrageConfigPanelScreen(
        initialConfig: globalConfig,
        onConfigChanged: (newConfig) {
          globalConfig = newConfig;
        },
      ),
      '/multi_screen_barrage': (context) => const MultiScreenBarrageDemoScreen(),
      '/item_style_demo': (context) => const BarrageItemStyleDemoScreen(),
    };
  }
}
