import 'dart:ui';

class PictureCache {
  final Map<String, Picture> _cache = {};

  Picture? get(String key) {
    return _cache[key];
  }

  void put(String key, Picture picture) {
    _cache[key] = picture;
  }

  bool contains(String key) {
    return _cache.containsKey(key);
  }

  void remove(String key) {
    _cache.remove(key)?.dispose();
  }

  void clear() {
    for (final picture in _cache.values) {
      picture.dispose();
    }

    _cache.clear();
  }

  int get size => _cache.length;
}
