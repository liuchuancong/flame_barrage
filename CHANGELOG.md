# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project adheres to Semantic Versioning.

## 0.0.7

### Performance — TV / low-end device rendering (弹幕位图化渲染)

- **Barrage bitmaps.** Each message is now baked once into a GPU-resident bitmap at device resolution (`BarrageConfig.rasterizeItems`, default `true`) and drawn as a single textured quad per frame, instead of replaying its text, stroke, shadow and emoji display list on every display frame. Stroked glyph runs were being re-tessellated by the raster thread on every one of those replays, which is what made a full screen of danmaku drop frames on TV-class hardware. Measured on a 1080p scene with ~74 messages on screen (Windows/Impeller): raster time per frame p50 **1.99 ms → 0.82 ms**, p90 **2.19 ms → 1.04 ms**, at a cost of 8.3 MB of bitmap memory.
- Added `BarrageConfig.rasterizeItems` and `BarrageConfig.rasterCacheMaxBytes` (default 24 MB) for bitmap baking and its GPU memory budget.
- Only messages up to 4096 device pixels per side are baked; longer messages and platforms without picture rasterization fall back to the vector path automatically.
- **Fixed a latent crash/stutter source.** LRU eviction used to dispose pictures that visible messages were still drawing, so a stream with more distinct messages than the cache holds threw on every following frame. The new `RenderCache` is reference counted: an evicted artifact survives until the last barrage using it is recycled, and `clear()` / `updateConfig()` follow the same rule.
- Added `RenderCache` / `CachedRender` (exported). `PictureCache` is kept for compatibility but is no longer used by the engine.
- Added `BarrageEngine.activeCount` / `rasterCacheBytes` and `BarrageController.activeItemCount` / `rasterCacheBytes` to observe on-screen load and bitmap memory.

#### 中文说明

- **弹幕位图化。** 每条弹幕只按设备像素比烘焙一次成常驻显存的位图，每个显示帧只画一个纹理四边形，而不再逐帧重放它的文字、描边、阴影与 Emoji 绘制指令；描边字形在每次重放时都被光栅线程重新细分，这正是 TV 上满屏弹幕掉帧的根因。1080p、同屏约 74 条实测：每帧光栅耗时 p50 **1.99 ms → 0.82 ms**、p90 **2.19 ms → 1.04 ms**，位图显存占用 8.3 MB。
- 新增 `rasterizeItems`（默认开启）与 `rasterCacheMaxBytes`（默认 24 MB）；超长弹幕与不支持位图光栅化的平台自动回退矢量路径。
- **修复潜在崩溃源。** 原先 LRU 淘汰会直接 dispose 仍被在屏弹幕引用的 Picture；新的 `RenderCache` 采用引用计数，被淘汰的资源会存活到最后一个引用它的弹幕被回收。

### Example

- Config panel: new `rasterizeItems` switch; memory screen reports bitmap VRAM usage and the on-screen message count.
- 配置面板新增 `rasterizeItems` 开关；显存监控页新增位图显存占用与同屏弹幕数。

### Tests

- `test/render_cache_test.dart` — eviction / reference counting / byte budget semantics.
- `test/barrage_raster_test.dart` — the bitmap path lands within 2 px of the vector path with a comparable pixel count, repeated content shares one bitmap, high-density baking, bitmap survival while its cache entry is evicted, and a safe mid-flight fallback.

## 0.0.6
- Cleaned up formatting and removed unnecessary whitespace in object_pool.dart, picture_pool.dart, emoji_protocol.dart, message_protocol.dart, barrage_renderer.dart, emoji_renderer.dart, mixed_renderer.dart, base_renderer.dart, overlap_detector.dart, speed_strategy.dart, track_allocator.dart, track_manager.dart, barrage_logger.dart, color_util.dart, fps_monitor.dart, measure.dart, barrage_overlay.dart, and flame_barrage_widget.dart.
- Updated the version in pubspec.yaml from 0.0.5 to 0.0.6.
- Enhanced the performance of the speed calculation logic in speed_strategy.dart.
- Improved the track allocation logic in track_allocator.dart to ensure better performance under load.
- Added proper disposal of resources in flame_barrage_widget.dart to prevent memory leaks.

## 0.0.5

- Added per‑track differentiated scroll speed for scrolling barrages.
- Speed is calculated based on track position and current track barrage count, applied on barrage creation.
- Added `useUniformSpeed` flag to `BarrageConfig`, toggle uniform speed mode, default `true` for backward compatibility.
- Added `dynamicSpeedWhileFlying` flag to `BarrageConfig`. When enabled, already flying scroll barrages adjust speed in real‑time according to track status; may cause barrage overlap, default `false`.
- Fixed scroll barrage movement using hard‑coded baseSpeed value, now uses entry.speed.
- Fixed track speed factor not working when track already has barrages.
- Retained original single‑track anti‑overtake logic.

> Note: Differentiated speed only affects newly spawned barrages by default. Already flying barrages retain their initial speed to prevent overlap. Enable `dynamicSpeedWhileFlying` to turn on real‑time speed adjustment.




## 0.0.4

- Added optional pointer event handling for `FlameBarrageWidget`.
- Added `enablePointerEvents` property to control whether the barrage widget responds to mouse and touch events.
- Improved barrage rendering isolation and prevented unnecessary pointer event processing when interaction is disabled.
- Fixed potential rendering artifacts caused by pointer events.

## 0.0.3

- New demo page for multiple screens sharing single BarrageController, support mutual exclusive switch between full screen and small window
- New BarrageItem independent style test demo to verify per-danmaku custom style override
- Add `fontFamily` property to BarrageConfig, BarrageEngine, MixedLayout and BarrageItem, support global and single danmaku custom font configuration
- Complete pause & resume freeze mechanism for barrage engine

## 0.0.2

- Added GitHub Pages online demo.
- Added English / Chinese README navigation.
- Improved documentation.
- Updated project branding and logo.

## 0.0.1

* Initial public release.
* High-performance barrage rendering engine powered by Flame.
* Batch rendering pipeline for reduced Widget Tree overhead.
* Dual-pass text rendering with independent outline and fill passes.
* Zero-allocation object pooling system (`BarragePool`).
* Dynamic runtime configuration updates.
* Native emoji rendering support.
* Sprite atlas animation support.
* Precise barrage interaction callbacks.
* Extensible Fragment architecture for custom rendering components.
* MIT License.
