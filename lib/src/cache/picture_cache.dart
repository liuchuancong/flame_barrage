import 'dart:ui';

class PictureCache {
  PictureCache({this.maxSize = 200});

  final int maxSize;
  final Map<String, Picture> _cache = {};

  int get size => _cache.length;

  bool contains(String key) => _cache.containsKey(key);

  Picture? get(String key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  void put(String key, Picture picture) {
    if (_cache.containsKey(key)) {
      return;
    }

    if (_cache.length >= maxSize) {
      final firstKey = _cache.keys.first;
      final oldestPicture = _cache.remove(firstKey);
      oldestPicture?.dispose();
    }

    _cache[key] = picture;
  }

  void remove(String key) {
    final picture = _cache.remove(key);
    picture?.dispose();
  }

  void clear() {
    for (final picture in _cache.values) {
      picture.dispose();
    }
    _cache.clear();
  }
}
