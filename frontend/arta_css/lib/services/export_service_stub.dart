// Stub implementation for unsupported platforms
// This file is used when neither dart:html nor dart:io is available

import 'dart:typed_data';

Future<void> downloadFile(String filename, String content, String mimeType) async {
  throw UnsupportedError('File download is not supported on this platform');
}

Future<void> downloadFileBytes(String filename, Uint8List bytes, String mimeType) async {
  throw UnsupportedError('File download is not supported on this platform');
}
