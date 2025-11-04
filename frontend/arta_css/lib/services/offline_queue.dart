import 'dart:convert';

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
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    if (list.isEmpty) return 0;

    final firestore = FirebaseFirestore.instance;
    int success = 0;
    final remaining = <String>[];

    for (final s in list) {
      try {
        final Map<String, dynamic> payload = jsonDecode(s);
        await firestore.collection('feedbacks').add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
        success++;
      } catch (e) {
        // keep item for retry later
        remaining.add(s);
      }
    }

    // write back remaining items
    await prefs.setStringList(_prefsKey, remaining);
    return success;
  }

  // get current pending count
  static Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    return list.length;
  }
}
