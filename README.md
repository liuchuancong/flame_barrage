<p align="center">
  <img src="assets/logo.png" alt="FlameBarrage Engine Logo" width="720">
</p>

<h1 align="center">🔥 FlameBarrage Engine</h1>

<p align="center">
  A High-Performance, Hardware-Accelerated Barrage Rendering Engine for Flutter
</p>

<p align="center">
  <img src="https://img.shields.io/pub/v/flame_barrage.svg" alt="pub version">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Flame-1.37+-orange.svg" alt="Flame">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

---

## 🚀 Overview

FlameBarrage Engine is a high-performance, hardware-accelerated barrage (danmaku) rendering engine built on top of the Flame graphics framework.

Designed for demanding real-time scenarios such as live streaming platforms, video comment overlays, esports broadcasts, and large-scale interactive applications, FlameBarrage bypasses the traditional widget-heavy rendering approach and leverages Flame's rendering pipeline to achieve exceptional performance under heavy concurrency.

With optimized memory management, object reuse, and a lightweight rendering architecture, the engine maintains stable frame rates and predictable memory behavior even when handling hundreds of simultaneous barrage items on modern high-refresh-rate devices (120Hz+).

---

## 🔥 Core Features

### ⚡ Batch Rendering Pipeline

Instead of creating a widget for every barrage item, FlameBarrage decomposes text, emoji, and graphic assets into lightweight rendering fragments and submits them directly to the low-level canvas rendering layer.

**Benefits**

- Reduced Widget Tree overhead
- Minimal layout cost
- Lower rebuild frequency
- Better scalability under high message throughput

---

### 🎨 Dual-Pass Typography Rendering

Text outlines and fill colors are rendered independently to ensure visual consistency and eliminate common font cache issues.

**Advantages**

- No first-frame dark rendering artifacts
- No outline bleeding
- Reduced text flickering
- Improved rendering stability

---

### ♻️ Zero-Allocation Object Pool

The built-in `BarragePool` reuses rendering components instead of continuously allocating and disposing objects.

**Benefits**

- Extremely low GC pressure
- Stable memory footprint
- Long-session reliability
- Predictable runtime performance

---

### 📐 Dynamic Responsive Viewports

Runtime configuration changes can be applied without clearing active barrages or rebuilding the rendering surface.

Supported dynamic properties:

- `fontSize`
- `trackHeight`
- `area`
- `topAreaDistance`
- `safeArea`
- `opacity`

Changes take effect immediately and seamlessly.

---

### 🎯 Stable Motion Scheduling

A dedicated scheduler ensures smooth and predictable movement for all barrage items.

**Features**

- Constant scrolling speed
- Collision avoidance
- Safe spacing control
- Smooth visual flow

---

## 🏆 Enterprise-Grade Capabilities

### 👆 Precise Barrage Interaction

Built on Flame's native input event system, every barrage item can participate in interaction handling.

Supported events:

- `onTapDown`
- `onTapUp`
- `onLongTapDown`
- Custom gesture callbacks

Accurate interaction detection remains reliable even under hundreds of simultaneously moving barrage items.

---

### 🎁 Sprite Atlas Animation Support

Supports both regular and irregular sprite atlases for efficient animated rendering.

Ideal for:

- Live-stream gifts
- Animated reactions
- Full-screen visual effects
- Event decorations
- Interactive rewards

---

### 😀 Native Emoji Rendering

Supports seamless inline rendering of system emojis together with normal text while preserving alignment and layout consistency.

---

## 📦 Installation

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flame: ^1.37.0
  flame_barrage: ^1.0.0
```

---

## 🛠 Quick Start

### Create a Controller

```dart
final controller = BarrageController();
```

### Mount the Barrage View

```dart
FlameBarrageWidget(
  controller: controller,
  config: config,
  emojiAtlas: EmojiAtlas.instance,
)
```

### Send a Barrage

```dart
controller.send(
  BarrageItem(
    content: 'Hello FlameBarrage!',
    type: BarrageType.scroll,
  ),
);
```

### Dynamic Configuration Updates

```dart
controller.updateConfig(
  config.copyWith(
    fontSize: 24,
  ),
);
```

Configuration changes are applied instantly without interrupting active barrage rendering.

---

## 💻 Example

```dart
import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  final BarrageController _controller = BarrageController();

  final BarrageConfig _config = const BarrageConfig(
    fontSize: 20,
    baseSpeed: 150,
    trackHeight: 44,
    showStroke: true,
    safeArea: true,
    opacity: 0.8,
  );

  @override
  void dispose() {
    _controller.clear();
    _controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FlameBarrageWidget(
            controller: _controller,
            config: _config,
            emojiAtlas: EmojiAtlas.instance,
          ),
        ),
      ],
    );
  }
}
```

---

## 🧩 Extensible Fragment Architecture

FlameBarrage exposes a fully extensible `Fragment` abstraction layer.

Developers can introduce custom rendering strategies without modifying the engine source code.

Examples include:

- SVG assets
- Network images
- Animated stickers
- Custom emoji packs
- Lottie animations
- Virtual gifts
- Business-specific visual components

### Custom Fragment Example

```dart
class CustomFragment extends Fragment {
  @override
  ui.Size computeSize(BarrageConfig config) {
    return const ui.Size(40, 40);
  }

  @override
  void paint(
    ui.Canvas canvas,
    ui.Offset offset,
    ui.Size size,
    BarrageConfig config,
  ) {
    // custom rendering logic
  }
}
```

---

## 📈 Ideal Use Cases

- Live Streaming Platforms
- Video Comment Overlays
- Esports Broadcasting
- Social Media Applications
- Virtual Gift Systems
- Real-Time Message Feeds
- Interactive Event Platforms
- In-Game Announcement Systems

---

## 🔬 Performance Philosophy

FlameBarrage is engineered around three core principles:

1. **Minimize allocations**
2. **Reduce framework overhead**
3. **Maximize GPU utilization**

The result is a barrage engine capable of sustaining extremely high message throughput while maintaining smooth animations, stable frame pacing, and low memory pressure.

---

## 📋 License

Released under the MIT License.
