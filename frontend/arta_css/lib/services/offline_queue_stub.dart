// Stub file for offline_queue.dart - used by native platforms
// This re-exports the HTTP-based implementation which doesn't depend on Firebase
//
// The web version uses offline_queue.dart which has cloud_firestore integration.
// Native platforms use this stub which exports the HTTP-based OfflineQueue.

export 'offline_queue_http.dart';
