import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A cache entry with value and expiration time
class CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  final DateTime createdAt;

  CacheEntry({
    required this.value,
    required this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get age => DateTime.now().difference(createdAt);
  
  Duration get timeToLive => expiresAt.difference(DateTime.now());
}

/// Cache configuration options
class CacheConfig {
  /// Default TTL for cache entries (5 minutes)
  static const Duration defaultTTL = Duration(minutes: 5);
  
  /// Short TTL for frequently changing data (1 minute)
  static const Duration shortTTL = Duration(minutes: 1);
  
  /// Long TTL for rarely changing data (30 minutes)
  static const Duration longTTL = Duration(minutes: 30);
  
  /// Very long TTL for static data (2 hours)
  static const Duration veryLongTTL = Duration(hours: 2);
  
  /// Maximum number of entries in memory cache
  static const int maxMemoryCacheEntries = 100;
  
  /// Keys for persistent cache
  static const String feedbacksCacheKey = 'cached_feedbacks';
  static const String feedbacksTimestampKey = 'feedbacks_cache_timestamp';
  static const String usersCacheKey = 'cached_users';
  static const String usersTimestampKey = 'users_cache_timestamp';
  static const String dashboardStatsCacheKey = 'cached_dashboard_stats';
  static const String dashboardStatsTimestampKey = 'dashboard_stats_cache_timestamp';
}

/// Centralized cache service for managing application-wide caching
class CacheService extends ChangeNotifier {
  static CacheService? _instance;
  
  /// Singleton instance
  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }
  
  CacheService._();
  
  /// In-memory cache storage
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  
  /// Cache hit/miss statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  
  /// Getters for statistics
  int get cacheHits => _cacheHits;
  int get cacheMisses => _cacheMisses;
  double get hitRate => (_cacheHits + _cacheMisses) > 0 
      ? _cacheHits / (_cacheHits + _cacheMisses) * 100 
      : 0.0;
  int get memoryCacheSize => _memoryCache.length;
  
  // ==================== MEMORY CACHE ====================
  
  /// Get a value from memory cache
  T? getFromMemory<T>(String key) {
    final entry = _memoryCache[key];
    
    if (entry == null) {
      _cacheMisses++;
      debugPrint('CacheService: Memory MISS for key "$key"');
      return null;
    }
    
    if (entry.isExpired) {
      _memoryCache.remove(key);
      _cacheMisses++;
      debugPrint('CacheService: Memory EXPIRED for key "$key"');
      return null;
    }
    
    _cacheHits++;
    debugPrint('CacheService: Memory HIT for key "$key" (age: ${entry.age.inSeconds}s)');
    return entry.value as T;
  }
  
  /// Set a value in memory cache
  void setInMemory<T>(String key, T value, {Duration ttl = CacheConfig.defaultTTL}) {
    // Enforce max entries limit using LRU-like eviction
    if (_memoryCache.length >= CacheConfig.maxMemoryCacheEntries) {
      _evictOldestEntry();
    }
    
    _memoryCache[key] = CacheEntry<T>(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
    debugPrint('CacheService: Cached "$key" in memory (TTL: ${ttl.inSeconds}s)');
  }
  
  /// Remove a specific key from memory cache
  void removeFromMemory(String key) {
    _memoryCache.remove(key);
    debugPrint('CacheService: Removed "$key" from memory cache');
  }
  
  /// Clear all memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
    debugPrint('CacheService: Memory cache cleared');
    notifyListeners();
  }
  
  /// Evict the oldest entry from memory cache
  void _evictOldestEntry() {
    if (_memoryCache.isEmpty) return;
    
    String? oldestKey;
    DateTime? oldestTime;
    
    for (final entry in _memoryCache.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.createdAt;
      }
    }
    
    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
      debugPrint('CacheService: Evicted oldest entry "$oldestKey"');
    }
  }
  
  /// Remove all expired entries from memory cache
  void cleanupExpiredEntries() {
    final expiredKeys = <String>[];
    
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('CacheService: Cleaned up ${expiredKeys.length} expired entries');
    }
  }
  
  // ==================== PERSISTENT CACHE ====================
  
  /// Save data to persistent storage (SharedPreferences)
  Future<void> saveToPersistent(String key, dynamic data, {String? timestampKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String jsonString;
      if (data is String) {
        jsonString = data;
      } else if (data is List || data is Map) {
        jsonString = jsonEncode(data);
      } else {
        debugPrint('CacheService: Cannot persist data of type ${data.runtimeType}');
        return;
      }
      
      await prefs.setString(key, jsonString);
      
      if (timestampKey != null) {
        await prefs.setString(timestampKey, DateTime.now().toIso8601String());
      }
      
      debugPrint('CacheService: Saved to persistent cache "$key"');
    } catch (e) {
      debugPrint('CacheService: Error saving to persistent cache: $e');
    }
  }
  
  /// Load data from persistent storage
  Future<T?> loadFromPersistent<T>(String key, {
    String? timestampKey,
    Duration maxAge = CacheConfig.longTTL,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check timestamp if provided
      if (timestampKey != null) {
        final timestampStr = prefs.getString(timestampKey);
        if (timestampStr != null) {
          final timestamp = DateTime.parse(timestampStr);
          if (DateTime.now().difference(timestamp) > maxAge) {
            debugPrint('CacheService: Persistent cache expired for "$key"');
            return null;
          }
        }
      }
      
      final jsonString = prefs.getString(key);
      if (jsonString == null) {
        debugPrint('CacheService: No persistent cache for "$key"');
        return null;
      }
      
      final decoded = jsonDecode(jsonString);
      debugPrint('CacheService: Loaded from persistent cache "$key"');
      return decoded as T;
    } catch (e) {
      debugPrint('CacheService: Error loading from persistent cache: $e');
      return null;
    }
  }
  
  /// Remove from persistent storage
  Future<void> removeFromPersistent(String key, {String? timestampKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      if (timestampKey != null) {
        await prefs.remove(timestampKey);
      }
      debugPrint('CacheService: Removed from persistent cache "$key"');
    } catch (e) {
      debugPrint('CacheService: Error removing from persistent cache: $e');
    }
  }
  
  /// Clear all persistent cache
  Future<void> clearPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_')).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('CacheService: Cleared ${keys.length} persistent cache entries');
    } catch (e) {
      debugPrint('CacheService: Error clearing persistent cache: $e');
    }
  }
  
  // ==================== UTILITY METHODS ====================
  
  /// Check if a cached value exists and is valid
  bool hasValidCache(String key) {
    final entry = _memoryCache[key];
    return entry != null && !entry.isExpired;
  }
  
  /// Get cache entry metadata
  Map<String, dynamic>? getCacheInfo(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;
    
    return {
      'key': key,
      'createdAt': entry.createdAt.toIso8601String(),
      'expiresAt': entry.expiresAt.toIso8601String(),
      'age': entry.age.inSeconds,
      'timeToLive': entry.timeToLive.inSeconds,
      'isExpired': entry.isExpired,
    };
  }
  
  /// Get all cache statistics
  Map<String, dynamic> getStatistics() {
    cleanupExpiredEntries();
    
    return {
      'memoryCacheSize': _memoryCache.length,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': '${hitRate.toStringAsFixed(1)}%',
      'entries': _memoryCache.keys.toList(),
    };
  }
  
  /// Reset statistics
  void resetStatistics() {
    _cacheHits = 0;
    _cacheMisses = 0;
    debugPrint('CacheService: Statistics reset');
  }
  
  /// Clear all caches (memory and persistent)
  Future<void> clearAllCaches() async {
    clearMemoryCache();
    await clearPersistentCache();
    resetStatistics();
    notifyListeners();
  }
  
  /// Preload commonly accessed data into cache
  Future<void> warmupCache() async {
    debugPrint('CacheService: Starting cache warmup...');
    // This method can be extended to preload data
    // For now, just cleanup expired entries
    cleanupExpiredEntries();
    debugPrint('CacheService: Cache warmup complete');
  }
}

/// Mixin to add caching capabilities to services
mixin CachingMixin {
  CacheService get cacheService => CacheService.instance;
  
  /// Get or fetch data with caching
  Future<T> getOrFetch<T>({
    required String cacheKey,
    required Future<T> Function() fetchFunction,
    Duration ttl = CacheConfig.defaultTTL,
    bool forceRefresh = false,
  }) async {
    // Check memory cache first
    if (!forceRefresh) {
      final cached = cacheService.getFromMemory<T>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }
    
    // Fetch fresh data
    final data = await fetchFunction();
    
    // Cache the result
    cacheService.setInMemory(cacheKey, data, ttl: ttl);
    
    return data;
  }
}
