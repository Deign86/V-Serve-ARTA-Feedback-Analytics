import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

// Conditional imports for web vs native
import 'export_service_stub.dart'
    if (dart.library.html) 'export_service_web.dart'
    if (dart.library.io) 'export_service_native.dart' as platform;

class ExportService {
  static String _safeFileName(String base, String ext) {
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final name = base.replaceAll(RegExp(r"[^A-Za-z0-9_\- ]"), '').replaceAll(' ', '_');
    return '${name}_$ts.$ext';
  }

  static Future<String> exportCsv(String baseName, List<List<dynamic>> rows) async {
    final filename = _safeFileName(baseName, 'csv');
    final csv = const ListToCsvConverter().convert(rows);
    
    await platform.downloadFile(filename, csv, 'text/csv');
    return filename;
  }

  static Future<String> exportJson(String baseName, List<Map<String, dynamic>> data) async {
    final filename = _safeFileName(baseName, 'json');
    final encoded = const JsonEncoder.withIndent('  ').convert(data);
    
    await platform.downloadFile(filename, encoded, 'application/json');
    return filename;
  }

  static Future<String> exportPdf(String baseName, List<Map<String, dynamic>> rows) async {
    final doc = pw.Document();

    // Make a simple table: header from keys
    final headers = rows.isNotEmpty ? rows.first.keys.toList() : <String>[];
    final data = rows.map((r) => headers.map((h) => r[h]?.toString() ?? '').toList()).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(baseName)),
          if (headers.isNotEmpty)
            // ignore: deprecated_member_use
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
            )
          else
            pw.Paragraph(text: 'No data'),
        ],
      ),
    );

    final bytes = await doc.save();
    final filename = _safeFileName(baseName, 'pdf');
    
    await platform.downloadFileBytes(filename, bytes, 'application/pdf');
    return filename;
  }
}
