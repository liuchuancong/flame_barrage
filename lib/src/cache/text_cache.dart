import 'dart:ui' as ui;

class TextCache {
  TextCache({this.maxSize = 1000});

  int maxSize;
  final Map<String, ui.Paragraph> _cache = {};

  int get size => _cache.length;

  /// Adjusts the capacity in place, evicting LRU paragraphs when it shrinks.
  ///
  /// Evicted paragraphs are only dropped from the map, never disposed here:
  /// they may still be referenced by cached layout results, which own their
  /// lifetime and dispose them once the last reference goes away. Rebuilding
  /// the whole cache on a limit change (the previous behavior) discarded
  /// every warm paragraph and forced a full re-shape of the next frame's
  /// messages — visible as a hitch while the budget slider was dragged.
  void setMaxSize(int value) {
    if (value <= 0) return;
    if (value == maxSize) return;
    maxSize = value;
    while (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  bool contains(String key) => _cache.containsKey(key);

  ui.Paragraph? get(String key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  void put(String key, ui.Paragraph paragraph) {
    if (_cache.containsKey(key)) return;

    if (_cache.length >= maxSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }

    _cache[key] = paragraph;
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void removeParagraph(ui.Paragraph paragraph) {
    _cache.removeWhere((_, value) => identical(value, paragraph));
  }

  List<ui.Paragraph> takeAll() {
    final paragraphs = _cache.values.toList(growable: false);
    _cache.clear();
    return paragraphs;
  }

  void clear() {
    _cache.clear();
  }
}
