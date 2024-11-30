class CacheService {
  static final CacheService instance = CacheService._init();
  final Map<String, dynamic> _cache = {};

  CacheService._init();

  static const int maxCacheSize = 100;
  static const Duration cacheDuration = Duration(minutes: 30);

  void setCache(String key, dynamic value) {
    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = {
      'value': value,
      'timestamp': DateTime.now(),
    };
  }

  dynamic getCache(String key) {
    final data = _cache[key];
    if (data == null) return null;

    final timestamp = data['timestamp'] as DateTime;
    if (DateTime.now().difference(timestamp) > cacheDuration) {
      _cache.remove(key);
      return null;
    }

    return data['value'];
  }

  void clearCache() {
    _cache.clear();
  }
}
