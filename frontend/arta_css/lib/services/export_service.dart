import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ExportService {
  static Future<Directory> _getSaveDir() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir;
    } catch (e) {
      // fallback to temp
      return Directory.systemTemp;
    }
  }

  static String _safeFileName(String base, String ext) {
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final name = base.replaceAll(RegExp(r"[^A-Za-z0-9_\- ]"), '').replaceAll(' ', '_');
    return '\$name-\$ts.\$ext';
  }

  static Future<String> exportCsv(String baseName, List<List<dynamic>> rows) async {
    final dir = await _getSaveDir();
    final filename = _safeFileName(baseName, 'csv');
    final path = '${dir.path}/$filename';
    final csv = const ListToCsvConverter().convert(rows);
    final file = File(path);
    await file.writeAsString(csv, flush: true);
    return path;
  }

  static Future<String> exportJson(String baseName, List<Map<String, dynamic>> data) async {
    final dir = await _getSaveDir();
    final filename = _safeFileName(baseName, 'json');
    final path = '${dir.path}/$filename';
    final encoded = const JsonEncoder.withIndent('  ').convert(data);
    final file = File(path);
    await file.writeAsString(encoded, flush: true);
    return path;
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
    final dir = await _getSaveDir();
    final filename = _safeFileName(baseName, 'pdf');
    final path = '${dir.path}/$filename';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }
}
