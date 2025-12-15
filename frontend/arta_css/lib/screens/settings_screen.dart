import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../services/notification_service.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enabled = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _toggle(bool v) async {
    setState(() { _loading = true; });
    if (v) {
      // Request permission and register token
      final ok = await NotificationService.requestPermission();
      if (ok) {
        await NotificationService.init();
        final token = await NotificationService.getToken();
        if (token != null) {
          final platform = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'windows');
          final deviceId = token; // deviceId reuse token for now; can use device_info
          await ApiService.registerDeviceToken(deviceId: deviceId, platform: platform, token: token);
        }
      }
    } else {
      // Disable locally
      // TODO: call backend to unregister if desired
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', v);
    setState(() { _enabled = v; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Allow this app to send push notifications'),
            trailing: _loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
                : Switch(value: _enabled, onChanged: _toggle),
          ),
        ],
      ),
    );
  }
}
