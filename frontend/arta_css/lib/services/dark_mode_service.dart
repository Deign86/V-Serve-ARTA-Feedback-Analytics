import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dark mode preference options
enum DarkModePreference {
  /// Follow system theme
  system,
  /// Always light mode
  light,
  /// Always dark mode
  dark,
}

/// Service to manage dark mode state with persistence and system theme detection.
/// 
/// This service provides:
/// - Real-time toggle (no hot reload needed)
/// - Auto-detect system dark mode via MediaQuery.platformBrightness
/// - Manual override with three options: system, light, dark
/// - Persistence via SharedPreferences (localStorage on web)
/// - Smooth transition support
class DarkModeService extends ChangeNotifier {
  static const String _prefKey = 'dark_mode_preference';
  
  DarkModePreference _preference = DarkModePreference.system;
  Brightness _systemBrightness = Brightness.light;
  bool _isInitialized = false;
  
  /// Current user preference for dark mode
  DarkModePreference get preference => _preference;
  
  /// Whether dark mode is currently enabled (considering system brightness)
  bool get isDarkMode {
    switch (_preference) {
      case DarkModePreference.system:
        return _systemBrightness == Brightness.dark;
      case DarkModePreference.light:
        return false;
      case DarkModePreference.dark:
        return true;
    }
  }
  
  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;
  
  /// Current system brightness
  Brightness get systemBrightness => _systemBrightness;
  
  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPref = prefs.getString(_prefKey);
      
      if (savedPref != null) {
        switch (savedPref) {
          case 'system':
            _preference = DarkModePreference.system;
            break;
          case 'light':
            _preference = DarkModePreference.light;
            break;
          case 'dark':
            _preference = DarkModePreference.dark;
            break;
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load dark mode preference: $e');
      _isInitialized = true;
    }
  }
  
  /// Update system brightness (should be called from a widget that has access to MediaQuery)
  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness != brightness) {
      _systemBrightness = brightness;
      if (_preference == DarkModePreference.system) {
        notifyListeners();
      }
    }
  }
  
  /// Set dark mode preference and persist it
  Future<void> setPreference(DarkModePreference preference) async {
    if (_preference == preference) return;
    
    _preference = preference;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String prefString;
      switch (preference) {
        case DarkModePreference.system:
          prefString = 'system';
          break;
        case DarkModePreference.light:
          prefString = 'light';
          break;
        case DarkModePreference.dark:
          prefString = 'dark';
          break;
      }
      await prefs.setString(_prefKey, prefString);
    } catch (e) {
      debugPrint('Failed to save dark mode preference: $e');
    }
  }
  
  /// Toggle between light and dark mode (ignores system)
  Future<void> toggleDarkMode() async {
    if (_preference == DarkModePreference.dark || 
        (_preference == DarkModePreference.system && isDarkMode)) {
      await setPreference(DarkModePreference.light);
    } else {
      await setPreference(DarkModePreference.dark);
    }
  }
  
  /// Get a human-readable label for the current preference
  String get preferenceLabel {
    switch (_preference) {
      case DarkModePreference.system:
        return 'System';
      case DarkModePreference.light:
        return 'Light';
      case DarkModePreference.dark:
        return 'Dark';
    }
  }
}
