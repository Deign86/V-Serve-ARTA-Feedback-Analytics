// Native implementation using dart:io for file downloads
// Supports custom export directory via ExportSettingsService

import 'dart:io';
import 'dart:typed_data';
import 'export_settings_service.dart';

/// Get the export directory from settings, creating it if needed
Future<String> _getExportPath(String filename) async {
  final settings = ExportSettingsService.instance;
  await settings.initialize();
  return settings.getExportFilePath(filename);
}

/// Download/save a text file to the configured export directory
Future<void> downloadFile(String filename, String content, String mimeType) async {
  final path = await _getExportPath(filename);
  final file = File(path);
  await file.writeAsString(content, flush: true);
}

/// Download/save a binary file to the configured export directory
Future<void> downloadFileBytes(String filename, Uint8List bytes, String mimeType) async {
  final path = await _getExportPath(filename);
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
}

/// Get the last saved file path (for display to user)
Future<String> getLastExportPath() async {
  final settings = ExportSettingsService.instance;
  return settings.exportPath;
}
