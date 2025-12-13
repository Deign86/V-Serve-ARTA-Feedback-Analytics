import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a queued item with metadata for retry logic
class QueuedItem {
  final String id;
  final Map<String, dynamic> payload;
  final DateTime enqueuedAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? lastError;
  
  QueuedItem({
    required this.id,
    required this.payload,
    required this.enqueuedAt,
    this.retryCount = 0,
    this.lastRetryAt,
    this.lastError,
  });
  
  QueuedItem copyWith({
    int? retryCount,
    DateTime? lastRetryAt,
    String? lastError,
  }) {
    return QueuedItem(
      id: id,
      payload: payload,
      enqueuedAt: enqueuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      lastError: lastError ?? this.lastError,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'payload': payload,
    'enqueuedAt': enqueuedAt.toIso8601String(),
    'retryCount': retryCount,
    'lastRetryAt': lastRetryAt?.toIso8601String(),
    'lastError': lastError,
  };
  
  factory QueuedItem.fromJson(Map<String, dynamic> json) {
    return QueuedItem(
      id: json['id'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      enqueuedAt: DateTime.parse(json['enqueuedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastRetryAt: json['lastRetryAt'] != null 
          ? DateTime.parse(json['lastRetryAt'] as String) 
          : null,
      lastError: json['lastError'] as String?,
    );
  }
}

/// Queue status for UI display
enum QueueStatus {
  idle,
  syncing,
  error,
  offline,
}

/// Configuration for offline queue behavior
class OfflineQueueConfig {
  /// Maximum number of retry attempts before marking as failed
  static const int maxRetries = 5;
  
  /// Base delay for exponential backoff (in seconds)
  static const int baseRetryDelaySeconds = 2;
  
  /// Maximum delay between retries (in seconds)
  static const int maxRetryDelaySeconds = 60;
  
  /// Auto-sync interval when online (in seconds)
  static const int autoSyncIntervalSeconds = 30;
  
  /// Key for storing queue in SharedPreferences
  static const String queueStorageKey = 'offline_queue_v2';
  
  /// Key for storing failed items
  static const String failedItemsKey = 'offline_queue_failed';
}

/// Enhanced offline queue service with connectivity awareness and retry logic
class OfflineQueueService extends ChangeNotifier {
  static OfflineQueueService? _instance;
  
  /// Singleton instance
  static OfflineQueueService get instance {
    _instance ??= OfflineQueueService._();
    return _instance!;
  }
  
  OfflineQueueService._() {
    _initialize();
  }
  
  // Queue state
  final List<QueuedItem> _queue = [];
  final List<QueuedItem> _failedItems = [];
  QueueStatus _status = QueueStatus.idle;
  bool _isOnline = true;
  bool _isSyncing = false;
  Timer? _autoSyncTimer;
  DateTime? _lastSyncAttempt;
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  
  // Getters
  List<QueuedItem> get queue => List.unmodifiable(_queue);
  List<QueuedItem> get failedItems => List.unmodifiable(_failedItems);
  QueueStatus get status => _status;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _queue.length;
  int get failedCount => _failedItems.length;
  bool get hasItems => _queue.isNotEmpty;
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
  int get successfulSyncs => _successfulSyncs;
  int get failedSyncs => _failedSyncs;
  
  /// Initialize the queue service
  Future<void> _initialize() async {
    await _loadQueue();
    _startAutoSync();
  }
  
  /// Load queue from persistent storage
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load pending queue
      final queueJson = prefs.getString(OfflineQueueConfig.queueStorageKey);
      if (queueJson != null) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        _queue.clear();
        _queue.addAll(decoded.map((e) => QueuedItem.fromJson(e as Map<String, dynamic>)));
      }
      
      // Load failed items
      final failedJson = prefs.getString(OfflineQueueConfig.failedItemsKey);
      if (failedJson != null) {
        final List<dynamic> decoded = jsonDecode(failedJson);
        _failedItems.clear();
        _failedItems.addAll(decoded.map((e) => QueuedItem.fromJson(e as Map<String, dynamic>)));
      }
      
      // Migrate from old queue format if exists
      await _migrateFromLegacyQueue(prefs);
      
      debugPrint('OfflineQueue: Loaded ${_queue.length} pending, ${_failedItems.length} failed items');
      notifyListeners();
    } catch (e) {
      debugPrint('OfflineQueue: Error loading queue: $e');
    }
  }
  
  /// Migrate data from legacy queue format (v1)
  Future<void> _migrateFromLegacyQueue(SharedPreferences prefs) async {
    const legacyKey = 'pending_feedbacks';
    final legacyList = prefs.getStringList(legacyKey);
    
    if (legacyList != null && legacyList.isNotEmpty) {
      debugPrint('OfflineQueue: Migrating ${legacyList.length} items from legacy queue');
      
      for (final item in legacyList) {
        try {
          final payload = jsonDecode(item) as Map<String, dynamic>;
          final queuedItem = QueuedItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
            payload: payload,
            enqueuedAt: DateTime.now(),
          );
          _queue.add(queuedItem);
        } catch (e) {
          debugPrint('OfflineQueue: Error migrating item: $e');
        }
      }
      
      // Clear legacy queue after migration
      await prefs.remove(legacyKey);
      await _saveQueue();
      debugPrint('OfflineQueue: Migration complete');
    }
  }
  
  /// Save queue to persistent storage
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save pending queue
      final queueJson = jsonEncode(_queue.map((e) => e.toJson()).toList());
      await prefs.setString(OfflineQueueConfig.queueStorageKey, queueJson);
      
      // Save failed items
      final failedJson = jsonEncode(_failedItems.map((e) => e.toJson()).toList());
      await prefs.setString(OfflineQueueConfig.failedItemsKey, failedJson);
      
    } catch (e) {
      debugPrint('OfflineQueue: Error saving queue: $e');
    }
  }
  
  /// Start auto-sync timer
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: OfflineQueueConfig.autoSyncIntervalSeconds),
      (_) => _tryAutoSync(),
    );
  }
  
  /// Stop auto-sync timer
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }
  
  /// Attempt auto-sync if conditions are met
  Future<void> _tryAutoSync() async {
    if (_queue.isEmpty || _isSyncing || !_isOnline) return;
    await flush();
  }
  
  /// Update online status
  void setOnlineStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _status = online ? QueueStatus.idle : QueueStatus.offline;
      debugPrint('OfflineQueue: Online status changed to $online');
      notifyListeners();
      
      // Try to sync when coming back online
      if (online && _queue.isNotEmpty) {
        Future.delayed(const Duration(seconds: 2), () => flush());
      }
    }
  }
  
  /// Enqueue a payload for submission
  Future<void> enqueue(Map<String, dynamic> payload) async {
    final item = QueuedItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      payload: payload,
      enqueuedAt: DateTime.now(),
    );
    
    _queue.add(item);
    await _saveQueue();
    
    debugPrint('OfflineQueue: Enqueued item ${item.id}, queue size: ${_queue.length}');
    notifyListeners();
  }
  
  /// Calculate delay for retry with exponential backoff
  Duration _getRetryDelay(int retryCount) {
    final seconds = (OfflineQueueConfig.baseRetryDelaySeconds * (1 << retryCount))
        .clamp(0, OfflineQueueConfig.maxRetryDelaySeconds);
    return Duration(seconds: seconds);
  }
  
  /// Flush queued items to Firestore
  Future<int> flush() async {
    if (_isSyncing) {
      debugPrint('OfflineQueue: Already syncing, skipping flush');
      return 0;
    }
    
    if (_queue.isEmpty) {
      debugPrint('OfflineQueue: Queue is empty, nothing to flush');
      return 0;
    }
    
    _isSyncing = true;
    _status = QueueStatus.syncing;
    _lastSyncAttempt = DateTime.now();
    notifyListeners();
    
    debugPrint('=== OFFLINE QUEUE FLUSH STARTED ===');
    debugPrint('Queue size: ${_queue.length} items');
    
    final firestore = FirebaseFirestore.instance;
    int success = 0;
    final itemsToProcess = List<QueuedItem>.from(_queue);
    
    for (final item in itemsToProcess) {
      try {
        debugPrint('Processing item ${item.id} (retry ${item.retryCount})');
        
        // Check if max retries exceeded
        if (item.retryCount >= OfflineQueueConfig.maxRetries) {
          debugPrint('❌ Max retries exceeded for item ${item.id}, moving to failed');
          _queue.remove(item);
          _failedItems.add(item.copyWith(
            lastError: 'Max retries (${OfflineQueueConfig.maxRetries}) exceeded',
          ));
          _failedSyncs++;
          continue;
        }
        
        // Apply exponential backoff for retries
        if (item.retryCount > 0 && item.lastRetryAt != null) {
          final delay = _getRetryDelay(item.retryCount);
          final timeSinceLastRetry = DateTime.now().difference(item.lastRetryAt!);
          if (timeSinceLastRetry < delay) {
            debugPrint('Skipping item ${item.id}, waiting for backoff (${delay.inSeconds}s)');
            continue;
          }
        }
        
        // Submit to Firestore
        final docRef = await firestore.collection('feedbacks').add({
          ...item.payload,
          'createdAt': FieldValue.serverTimestamp(),
          'queuedAt': item.enqueuedAt.toIso8601String(),
          'syncedAt': DateTime.now().toIso8601String(),
        });
        
        debugPrint('✅ Successfully written! Document ID: ${docRef.id}');
        _queue.remove(item);
        success++;
        _successfulSyncs++;
        
      } catch (e) {
        debugPrint('❌ ERROR writing item ${item.id}: $e');
        
        // Update retry count
        final index = _queue.indexOf(item);
        if (index >= 0) {
          _queue[index] = item.copyWith(
            retryCount: item.retryCount + 1,
            lastRetryAt: DateTime.now(),
            lastError: e.toString(),
          );
        }
        
        // Check if we should mark as offline
        if (e.toString().contains('network') || 
            e.toString().contains('unavailable') ||
            e.toString().contains('offline')) {
          _isOnline = false;
          _status = QueueStatus.offline;
        }
      }
    }
    
    await _saveQueue();
    
    _isSyncing = false;
    _status = _queue.isEmpty 
        ? QueueStatus.idle 
        : (_isOnline ? QueueStatus.error : QueueStatus.offline);
    
    debugPrint('=== FLUSH COMPLETE ===');
    debugPrint('Success: $success, Remaining: ${_queue.length}, Failed: ${_failedItems.length}');
    
    notifyListeners();
    return success;
  }
  
  /// Retry a specific failed item
  Future<bool> retryFailedItem(String itemId) async {
    final index = _failedItems.indexWhere((item) => item.id == itemId);
    if (index < 0) return false;
    
    final item = _failedItems.removeAt(index);
    _queue.add(item.copyWith(retryCount: 0, lastRetryAt: null, lastError: null));
    await _saveQueue();
    notifyListeners();
    
    // Try to flush immediately
    await flush();
    return true;
  }
  
  /// Retry all failed items
  Future<int> retryAllFailed() async {
    if (_failedItems.isEmpty) return 0;
    
    final count = _failedItems.length;
    for (final item in _failedItems) {
      _queue.add(item.copyWith(retryCount: 0, lastRetryAt: null, lastError: null));
    }
    _failedItems.clear();
    await _saveQueue();
    notifyListeners();
    
    await flush();
    return count;
  }
  
  /// Remove a specific item from the queue
  Future<void> removeItem(String itemId) async {
    _queue.removeWhere((item) => item.id == itemId);
    await _saveQueue();
    notifyListeners();
  }
  
  /// Remove a failed item permanently
  Future<void> removeFailedItem(String itemId) async {
    _failedItems.removeWhere((item) => item.id == itemId);
    await _saveQueue();
    notifyListeners();
  }
  
  /// Clear all pending items
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
    notifyListeners();
  }
  
  /// Clear all failed items
  Future<void> clearFailed() async {
    _failedItems.clear();
    await _saveQueue();
    notifyListeners();
  }
  
  /// Clear everything
  Future<void> clearAll() async {
    _queue.clear();
    _failedItems.clear();
    _successfulSyncs = 0;
    _failedSyncs = 0;
    await _saveQueue();
    notifyListeners();
  }
  
  /// Get queue statistics
  Map<String, dynamic> getStatistics() {
    return {
      'pendingCount': _queue.length,
      'failedCount': _failedItems.length,
      'successfulSyncs': _successfulSyncs,
      'failedSyncs': _failedSyncs,
      'status': _status.name,
      'isOnline': _isOnline,
      'lastSyncAttempt': _lastSyncAttempt?.toIso8601String(),
    };
  }
  
  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}

/// Static wrapper for backward compatibility
/// Use OfflineQueueService.instance for new code
class OfflineQueue {
  // enqueue a payload (a Map) into local storage
  static Future<void> enqueue(Map<String, dynamic> payload) async {
    await OfflineQueueService.instance.enqueue(payload);
  }

  // flush queued items to Firestore; returns number of successful items
  static Future<int> flush() async {
    return await OfflineQueueService.instance.flush();
  }

  // get current pending count
  static Future<int> pendingCount() async {
    return OfflineQueueService.instance.pendingCount;
  }
}
