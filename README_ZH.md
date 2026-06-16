<p align="center">
  <a href="./README.md">🇺🇸 English</a> |
  <a href="./README_ZH.md">🇨🇳 简体中文</a>
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/liuchuancong/flame_barrage/refs/heads/main/assets/logo/logo.png" alt="FlameBarrage Engine Logo" width="720">
</p>

<h1 align="center">🔥 FlameBarrage Engine</h1>

<p align="center">
  基于 Flame 图形框架构建的高性能 Flutter 弹幕渲染引擎
</p>

<p align="center">
  <img src="https://img.shields.io/pub/v/flame_barrage.svg" alt="pub version">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Flame-1.37+-orange.svg" alt="Flame">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>
## 🎮 在线体验

无需安装 Flutter 环境，直接在浏览器中体验 FlameBarrage：

👉 **在线 Demo：**
https://liuchuancong.github.io/flame_barrage/

在线演示包含：

- ⚡ 高性能弹幕渲染
- 🎨 实时配置热更新
- 😀 Emoji 混合排版
- 🎁 Sprite Atlas 雪碧图动画
- 👆 弹幕点击与长按交互
- 📈 实时性能压测

> 基于 Flutter Web 与 Flame Engine 构建。
---

## 🚀 项目简介

FlameBarrage Engine 是一个基于 Flame 图形框架打造的高性能、硬件加速弹幕渲染引擎。

专为直播间、高并发互动场景、长视频评论流、电竞赛事以及实时消息展示等业务场景设计，通过绕过传统 Widget 树的大量布局与重建开销，直接利用底层 Canvas 渲染能力，实现更高吞吐量、更低内存压力以及更加稳定的帧率表现。

得益于对象复用池、批量渲染管线以及轻量级组件架构，即使在数百条弹幕持续并发滚动的情况下，依然能够保持流畅稳定的运行状态，充分释放 120Hz+ 高刷新率设备的性能潜力。

---

## 🔥 核心特性

### ⚡ Batch Render 批量渲染管线

传统弹幕方案通常采用「一条弹幕对应一个 Widget」的方式进行渲染，而 FlameBarrage 会将文本、Emoji 以及图像资源拆解为轻量级 Fragment，并直接提交到底层 Canvas 绘制。

**优势**

- 大幅降低 Widget Tree 开销
- 减少 Layout 与 Rebuild 成本
- 提升高并发场景下的可扩展性
- 更适合直播与实时互动业务

---

### 🎨 双通路文本渲染

文字描边与填充颜色采用独立绘制流程，有效规避字体缓存复用导致的渲染异常问题。

**解决的问题**

- 首帧颜色异常
- 描边污染
- 文本闪烁
- 字体缓存干扰

从而获得更加稳定的文字显示效果。

---

### ♻️ 零分配对象池（BarragePool）

内置高性能对象复用机制，对过期组件进行回收和重置，避免频繁创建与销毁对象。

**优势**

- 极低 GC 压力
- 稳定内存曲线
- 更适合长时间运行
- 降低性能抖动

---

### 📐 动态响应式视口

运行过程中可实时调整弹幕参数，无需清空当前弹幕或重建画布。

支持动态更新：

- `fontSize`
- `trackHeight`
- `area`
- `topAreaDistance`
- `safeArea`
- `opacity`

所有配置修改均可即时生效。

---

### 🎯 稳定运动调度算法

内置轨道调度与安全间距控制机制，确保弹幕在高密度场景下依然保持平滑运动。

**特性**

- 固定滚动速度
- 轨道冲突规避
- 防重叠保护
- 平滑视觉流动

---

## 🏆 商业级能力

### 👆 精准弹幕交互

基于 Flame 原生输入事件系统实现弹幕命中检测。

支持：

- 点击（Tap）
- 长按（Long Press）
- 自定义手势事件

即使在同屏数百条高速滚动弹幕的场景下，也能够准确定位用户交互目标。

---

### 🎁 Sprite Atlas 雪碧图动画

支持规则与非规则 Sprite Atlas 动画渲染。

适用于：

- 直播礼物动画
- 动态表情
- 全屏特效
- 活动运营装饰
- 互动奖励展示

在保证视觉效果的同时最大限度降低显存与 CPU 消耗。

---

### 😀 原生 Emoji 混排

支持系统 Emoji 与普通文本混合排版。

特性包括：

- 自动基线对齐
- 正确布局计算
- 无错位显示
- 高性能渲染

---

## 📦 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flame: ^1.37.0
  flame_barrage: ^1.0.0
```

---

## 🛠 快速开始

### 创建控制器

```dart
final controller = BarrageController();
```

### 挂载弹幕视图

```dart
FlameBarrageWidget(
  controller: controller,
  config: config,
  emojiAtlas: EmojiAtlas.instance,
)
```

### 发送弹幕

```dart
controller.send(
  BarrageItem(
    content: 'Hello FlameBarrage!',
    type: BarrageType.scroll,
  ),
);
```

### 动态更新配置

```dart
controller.updateConfig(
  config.copyWith(
    fontSize: 24,
  ),
);
```

配置将实时生效，不会中断当前弹幕渲染。

---

## 💻 完整示例

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

## 🧩 可扩展 Fragment 架构

FlameBarrage 提供开放式 Fragment 渲染体系。

开发者无需修改引擎源码，即可扩展全新的渲染组件类型。

支持但不限于：

- SVG 图标
- 网络图片
- 自定义 Emoji
- Lottie 动画
- 虚拟礼物
- 动态特效
- 业务组件

### 自定义 Fragment 示例

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

## 📈 适用场景

- 直播弹幕系统
- 视频评论流
- 电竞赛事直播
- 社交互动应用
- 虚拟礼物系统
- 实时消息展示
- 活动互动平台
- 游戏内公告系统

---

## 🔬 性能设计理念

FlameBarrage 围绕以下三项原则设计：

1. **减少对象分配**
2. **降低框架开销**
3. **充分利用 GPU 渲染能力**

通过轻量级渲染架构与对象复用机制，实现高吞吐量弹幕场景下的稳定帧率、低 GC 压力以及优秀的长期运行表现。

---

## 📋 开源协议

FlameBarrage Engine 基于 MIT License 开源发布。