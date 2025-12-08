/// Native implementation using dart:io for file downloads
library export_service_native;

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<Directory> _getSaveDir() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return dir;
  } catch (e) {
    // fallback to temp
    return Directory.systemTemp;
  }
}

Future<void> downloadFile(String filename, String content, String mimeType) async {
  final dir = await _getSaveDir();
  final path = '${dir.path}/$filename';
  final file = File(path);
  await file.writeAsString(content, flush: true);
}

Future<void> downloadFileBytes(String filename, Uint8List bytes, String mimeType) async {
  final dir = await _getSaveDir();
  final path = '${dir.path}/$filename';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
}
