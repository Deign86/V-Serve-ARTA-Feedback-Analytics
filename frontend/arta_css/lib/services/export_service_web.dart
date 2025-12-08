/// Web implementation using dart:html for file downloads
library export_service_web;

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadFile(String filename, String content, String mimeType) async {
  final blob = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  
  html.document.body?.children.add(anchor);
  anchor.click();
  
  // Clean up
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

Future<void> downloadFileBytes(String filename, Uint8List bytes, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  
  html.document.body?.children.add(anchor);
  anchor.click();
  
  // Clean up
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
