class CacheService {
  static final CacheService instance = CacheService._init();
  final Map<String, dynamic> _cache = {};

  CacheService._init();

  static const int MAX_CACHE_SIZE = 100;
  static const Duration CACHE_DURATION = Duration(minutes: 30);

  void setCache(String key, dynamic value) {
    if (_cache.length >= MAX_CACHE_SIZE) {
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
    if (DateTime.now().difference(timestamp) > CACHE_DURATION) {
      _cache.remove(key);
      return null;
    }

    return data['value'];
  }

  void clearCache() {
    _cache.clear();
  }
}
