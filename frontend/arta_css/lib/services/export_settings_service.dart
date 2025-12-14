// Export Settings Service - Manages platform-specific export directory settings

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing export directory settings across platforms
class ExportSettingsService extends ChangeNotifier {
  static final ExportSettingsService _instance = ExportSettingsService._internal();
  static ExportSettingsService get instance => _instance;
  
  ExportSettingsService._internal();
  
  static const String _exportPathKey = 'export_directory_path';
  
  String? _customExportPath;
  String? _defaultExportPath;
  bool _isInitialized = false;
  
  /// The currently configured export path (custom or default)
  String get exportPath => _customExportPath ?? _defaultExportPath ?? '';
  
  /// Whether a custom export path is set
  bool get hasCustomPath => _customExportPath != null && _customExportPath!.isNotEmpty;
  
  /// The default platform-specific export path
  String get defaultPath => _defaultExportPath ?? '';
  
  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether the current platform supports custom export paths
  /// (Only desktop platforms - Windows, macOS, Linux)
  bool get supportsCustomPath {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  /// Whether the current platform is mobile (Android/iOS)
  bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  /// Get platform name for display
  String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }
  
  /// Initialize the service and load saved settings
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load default path based on platform
      _defaultExportPath = await _getDefaultExportPath();
      
      // Load custom path from preferences (if any)
      final prefs = await SharedPreferences.getInstance();
      _customExportPath = prefs.getString(_exportPathKey);
      
      // Validate custom path still exists
      if (_customExportPath != null && !kIsWeb) {
        final dir = Directory(_customExportPath!);
        if (!await dir.exists()) {
          // Custom path no longer exists, clear it
          _customExportPath = null;
          await prefs.remove(_exportPathKey);
        }
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ExportSettingsService: $e');
      _isInitialized = true;
    }
  }
  
  /// Get the default export path for the current platform
  Future<String> _getDefaultExportPath() async {
    if (kIsWeb) {
      return 'Downloads (Browser Default)';
    }
    
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop: Use Documents folder
        final dir = await getApplicationDocumentsDirectory();
        final exportDir = Directory('${dir.path}/V-Serve Exports');
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        return exportDir.path;
      } else if (Platform.isAndroid) {
        // Android: Use app-specific external storage or Downloads
        try {
          final dir = await getExternalStorageDirectory();
          if (dir != null) {
            final exportDir = Directory('${dir.path}/V-Serve Exports');
            if (!await exportDir.exists()) {
              await exportDir.create(recursive: true);
            }
            return exportDir.path;
          }
        } catch (_) {}
        // Fallback to app documents
        final fallback = await getApplicationDocumentsDirectory();
        return fallback.path;
      } else if (Platform.isIOS) {
        // iOS: Use Documents directory (accessible via Files app)
        final dir = await getApplicationDocumentsDirectory();
        return dir.path;
      }
    } catch (e) {
      debugPrint('Error getting default export path: $e');
    }
    
    // Final fallback
    return Directory.systemTemp.path;
  }
  
  /// Set a custom export path (desktop only)
  Future<bool> setCustomExportPath(String path) async {
    if (!supportsCustomPath) return false;
    
    try {
      // Validate the path exists and is a directory
      final dir = Directory(path);
      if (!await dir.exists()) {
        return false;
      }
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_exportPathKey, path);
      
      _customExportPath = path;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting custom export path: $e');
      return false;
    }
  }
  
  /// Clear custom export path and use default
  Future<void> clearCustomExportPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_exportPathKey);
      
      _customExportPath = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing custom export path: $e');
    }
  }
  
  /// Get the full file path for a given filename
  Future<String> getExportFilePath(String filename) async {
    await initialize();
    
    if (kIsWeb) {
      // Web handles downloads differently
      return filename;
    }
    
    final basePath = _customExportPath ?? _defaultExportPath ?? (await _getDefaultExportPath());
    
    // Ensure directory exists
    final dir = Directory(basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return '$basePath${Platform.pathSeparator}$filename';
  }
  
  /// Open the export directory in the system file explorer
  Future<bool> openExportDirectory() async {
    if (kIsWeb) return false;
    
    try {
      final path = exportPath;
      if (path.isEmpty) return false;
      
      if (Platform.isWindows) {
        await Process.run('explorer', [path]);
        return true;
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
        return true;
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
        return true;
      }
    } catch (e) {
      debugPrint('Error opening export directory: $e');
    }
    return false;
  }
}
