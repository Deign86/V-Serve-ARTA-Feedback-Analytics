import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineQueue {
  static const _prefsKey = 'pending_feedbacks';

  // enqueue a payload (a Map) into local storage
  static Future<void> enqueue(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    list.add(jsonEncode(payload));
    await prefs.setStringList(_prefsKey, list);
  }

  // flush queued items to Firestore; returns number of successful items
  static Future<int> flush() async {
    debugPrint('=== OFFLINE QUEUE FLUSH STARTED ===');
    
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    
    debugPrint('Queue size: ${list.length} items');
    
    if (list.isEmpty) {
      debugPrint('Queue is empty, nothing to flush');
      return 0;
    }

    final firestore = FirebaseFirestore.instance;
    int success = 0;
    final remaining = <String>[];

    for (int i = 0; i < list.length; i++) {
      final s = list[i];
      try {
        debugPrint('Processing item ${i + 1}/${list.length}');
        debugPrint('Data: $s');
        
        final Map<String, dynamic> payload = jsonDecode(s);
        
        debugPrint('Writing to Firestore collection "feedbacks"...');
        final docRef = await firestore.collection('feedbacks').add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('✅ Successfully written! Document ID: ${docRef.id}');
        success++;
      } catch (e, stackTrace) {
        debugPrint('❌ ERROR writing item ${i + 1}: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('Keeping item in queue for retry');
        // keep item for retry later
        remaining.add(s);
      }
    }

    // write back remaining items
    await prefs.setStringList(_prefsKey, remaining);
    
    debugPrint('=== FLUSH COMPLETE ===');
    debugPrint('Success: $success, Failed: ${remaining.length}');
    
    return success;
  }

  // get current pending count
  static Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    return list.length;
  }
}
