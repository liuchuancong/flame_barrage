import 'package:flutter/material.dart';
import 'package:flame_barrage/flame_barrage.dart';

class BarrageConfig {
  const BarrageConfig({
    this.fontSize = 18,
    this.fontWeight = FontWeight.w500,
    this.textColor = Colors.white,
    this.strokeColor = Colors.black,
    this.opacity = 1.0,
    this.showStroke = true,
    this.area = 1.0,
    this.topAreaDistance = 0,
    this.bottomAreaDistance = 0,
    this.scrollDuration = const Duration(seconds: 8),
    this.fixedDuration = const Duration(seconds: 4),
    this.hideTop = false,
    this.hideBottom = false,
    this.hideScroll = false,
    this.hideRainbow = false,
    this.massiveMode = false,
    this.safeArea = true,
    this.fps = 60,
    this.trackSpacing = 4,
    this.trackHeight = 36,
    this.emojiSize = 24,
    this.maxTrackCount = 12,
    this.maxTextLength = 40,
    this.maxVisibleCount = 80,
    this.dangerousQueueSize = 300,
    this.massiveModeThreshold = 50,
    this.normalEmitInterval = 0.15,
    this.massiveEmitInterval = 0.05,
    this.baseSpeed = 120.0,
    this.barragePoolMaxSize = 150,
    this.pictureCacheMaxSize = 200,
    this.textCacheMaxSize = 1000,
    this.overlapSafeGap = 40.0,
    this.effectInterceptors = const [],
  });

  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final Color strokeColor;
  final double opacity;
  final bool showStroke;
  final double area;
  final double topAreaDistance;
  final double bottomAreaDistance;
  final Duration scrollDuration;
  final Duration fixedDuration;
  final bool hideTop;
  final bool hideBottom;
  final bool hideScroll;
  final bool hideRainbow;
  final bool massiveMode;
  final bool safeArea;
  final int fps;
  final double trackSpacing;
  final double trackHeight;
  final double emojiSize;
  final int maxTrackCount;
  final int maxTextLength;
  final int maxVisibleCount;
  final int dangerousQueueSize;
  final int massiveModeThreshold;
  final double normalEmitInterval;
  final double massiveEmitInterval;
  final double baseSpeed;
  final int barragePoolMaxSize;
  final int pictureCacheMaxSize;
  final int textCacheMaxSize;
  final double overlapSafeGap;
  final List<BarrageEffectInterceptor> effectInterceptors;

  int get fixedDurationMs => fixedDuration.inMilliseconds;

  BarrageConfig copyWith({
    double? fontSize,
    FontWeight? fontWeight,
    Color? textColor,
    Color? strokeColor,
    double? opacity,
    bool? showStroke,
    double? area,
    double? topAreaDistance,
    double? bottomAreaDistance,
    Duration? scrollDuration,
    Duration? fixedDuration,
    bool? hideTop,
    bool? hideBottom,
    bool? hideScroll,
    bool? hideRainbow,
    bool? massiveMode,
    bool? safeArea,
    int? fps,
    double? trackSpacing,
    double? trackHeight,
    double? emojiSize,
    int? maxTrackCount,
    int? maxTextLength,
    int? maxVisibleCount,
    int? dangerousQueueSize,
    int? massiveModeThreshold,
    double? normalEmitInterval,
    double? massiveEmitInterval,
    double? baseSpeed,
    int? barragePoolMaxSize,
    int? pictureCacheMaxSize,
    int? textCacheMaxSize,
    double? overlapSafeGap,
    List<BarrageEffectInterceptor>? effectInterceptors,
  }) {
    return BarrageConfig(
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textColor: textColor ?? this.textColor,
      strokeColor: strokeColor ?? this.strokeColor,
      opacity: opacity ?? this.opacity,
      showStroke: showStroke ?? this.showStroke,
      area: area ?? this.area,
      topAreaDistance: topAreaDistance ?? this.topAreaDistance,
      bottomAreaDistance: bottomAreaDistance ?? this.bottomAreaDistance,
      scrollDuration: scrollDuration ?? this.scrollDuration,
      fixedDuration: fixedDuration ?? this.fixedDuration,
      hideTop: hideTop ?? this.hideTop,
      hideBottom: hideBottom ?? this.hideBottom,
      hideScroll: hideScroll ?? this.hideScroll,
      hideRainbow: hideRainbow ?? this.hideRainbow,
      massiveMode: massiveMode ?? this.massiveMode,
      safeArea: safeArea ?? this.safeArea,
      fps: fps ?? this.fps,
      trackSpacing: trackSpacing ?? this.trackSpacing,
      trackHeight: trackHeight ?? this.trackHeight,
      emojiSize: emojiSize ?? this.emojiSize,
      maxTrackCount: maxTrackCount ?? this.maxTrackCount,
      maxTextLength: maxTextLength ?? this.maxTextLength,
      maxVisibleCount: maxVisibleCount ?? this.maxVisibleCount,
      dangerousQueueSize: dangerousQueueSize ?? this.dangerousQueueSize,
      massiveModeThreshold: massiveModeThreshold ?? this.massiveModeThreshold,
      normalEmitInterval: normalEmitInterval ?? this.normalEmitInterval,
      massiveEmitInterval: massiveEmitInterval ?? this.massiveEmitInterval,
      baseSpeed: baseSpeed ?? this.baseSpeed,
      barragePoolMaxSize: barragePoolMaxSize ?? this.barragePoolMaxSize,
      pictureCacheMaxSize: pictureCacheMaxSize ?? this.pictureCacheMaxSize,
      textCacheMaxSize: textCacheMaxSize ?? this.textCacheMaxSize,
      overlapSafeGap: overlapSafeGap ?? this.overlapSafeGap,
      effectInterceptors: effectInterceptors ?? this.effectInterceptors,
    );
  }
}
