import 'dart:ui' as ui;

class TextCache {
  TextCache({this.maxSize = 1000});

  final int maxSize;
  final Map<String, ui.Paragraph> _cache = {};
  final List<String> _keys = [];

  int get size => _cache.length;

  bool contains(String key) => _cache.containsKey(key);

  ui.Paragraph? get(String key) => _cache[key];

  void put(String key, ui.Paragraph paragraph) {
    if (_cache.containsKey(key)) return;

    if (_cache.length >= maxSize) {
      final oldKey = _keys.removeAt(0);
      _cache.remove(oldKey);
    }

    _cache[key] = paragraph;
    _keys.add(key);
  }

  void remove(String key) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      _keys.remove(key);
    }
  }

  void clear() {
    _cache.clear();
    _keys.clear();
  }
}
