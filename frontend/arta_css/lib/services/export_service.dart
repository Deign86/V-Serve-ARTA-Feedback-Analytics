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

  // Human-readable header mapping for ARTA report
  static const Map<String, String> _headerLabels = {
    'id': 'ID',
    'clientType': 'Client Type',
    'date': 'Date',
    'sex': 'Sex',
    'age': 'Age',
    'region': 'Region',
    'serviceAvailed': 'Service Availed',
    'cc0Rating': 'CC1: Awareness',
    'cc1Rating': 'CC2: Visibility',
    'cc2Rating': 'CC3: Posting',
    'cc3Rating': 'CC4: Understanding',
    'sqd0Rating': 'SQD1: Time Spent',
    'sqd1Rating': 'SQD2: Steps Followed',
    'sqd2Rating': 'SQD3: Simplicity',
    'sqd3Rating': 'SQD4: Info Access',
    'sqd4Rating': 'SQD5: Fee Amount',
    'sqd5Rating': 'SQD6: Fee Display',
    'sqd6Rating': 'SQD7: Fee Equity',
    'sqd7Rating': 'SQD8: Processing Time',
    'sqd8Rating': 'SQD9: Accessibility',
    'suggestions': 'Suggestions',
    'email': 'Email',
    'submittedAt': 'Submitted At',
  };

  // Ordered columns for export (consistent across all formats)
  static const List<String> _exportColumns = [
    'id',
    'clientType',
    'date',
    'sex',
    'age',
    'region',
    'serviceAvailed',
    'cc0Rating',
    'cc1Rating',
    'cc2Rating',
    'cc3Rating',
    'sqd0Rating',
    'sqd1Rating',
    'sqd2Rating',
    'sqd3Rating',
    'sqd4Rating',
    'sqd5Rating',
    'sqd6Rating',
    'sqd7Rating',
    'sqd8Rating',
    'suggestions',
    'email',
    'submittedAt',
  ];

  /// Format a value for display (used in CSV and PDF)
  static String _formatValueForExport(String key, dynamic value) {
    if (value == null) return '';
    final strVal = value.toString();
    
    // Format dates to readable format
    if ((key == 'date' || key == 'submittedAt') && strVal.length >= 10) {
      // Return YYYY-MM-DD format
      return strVal.substring(0, 10);
    }
    
    return strVal;
  }

  /// Format value for PDF table (truncated for display)
  static String _formatValueForPdf(String key, dynamic value) {
    if (value == null) return '-';
    final strVal = value.toString();
    
    // Truncate long text fields for table display
    if (key == 'id' && strVal.length > 8) {
      return '${strVal.substring(0, 8)}...';
    }
    if (key == 'suggestions' && strVal.length > 30) {
      return '${strVal.substring(0, 30)}...';
    }
    if (key == 'email' && strVal.length > 20) {
      return '${strVal.substring(0, 20)}...';
    }
    if (key == 'serviceAvailed' && strVal.length > 25) {
      return '${strVal.substring(0, 25)}...';
    }
    if ((key == 'date' || key == 'submittedAt') && strVal.length > 10) {
      return strVal.substring(0, 10);
    }
    
    return strVal;
  }

  /// Export feedback data as CSV with properly formatted headers
  static Future<String> exportFeedbackCsv(String baseName, List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      return exportCsv(baseName, [['No data available']]);
    }

    // Get available columns from data
    final availableColumns = _exportColumns.where((col) => 
      data.first.containsKey(col)
    ).toList();
    
    // Create header row with readable labels
    final headers = availableColumns.map((col) => _headerLabels[col] ?? col).toList();
    
    // Create data rows
    final rows = <List<dynamic>>[
      headers,
      ...data.map((item) => 
        availableColumns.map((col) => _formatValueForExport(col, item[col])).toList()
      ),
    ];
    
    return exportCsv(baseName, rows);
  }

  /// Export feedback data as JSON with properly formatted structure
  static Future<String> exportFeedbackJson(String baseName, List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      return exportJson(baseName, []);
    }

    // Get available columns from data
    final availableColumns = _exportColumns.where((col) => 
      data.first.containsKey(col)
    ).toList();
    
    // Transform data with readable keys
    final formattedData = data.map((item) {
      final formatted = <String, dynamic>{};
      for (final col in availableColumns) {
        final label = _headerLabels[col] ?? col;
        formatted[label] = _formatValueForExport(col, item[col]);
      }
      return formatted;
    }).toList();
    
    return exportJson(baseName, formattedData);
  }

  /// Raw CSV export (for backward compatibility)
  static Future<String> exportCsv(String baseName, List<List<dynamic>> rows) async {
    final filename = _safeFileName(baseName, 'csv');
    final csv = const ListToCsvConverter().convert(rows);
    
    await platform.downloadFile(filename, csv, 'text/csv');
    return filename;
  }

  /// Raw JSON export (for backward compatibility)
  static Future<String> exportJson(String baseName, List<Map<String, dynamic>> data) async {
    final filename = _safeFileName(baseName, 'json');
    final encoded = const JsonEncoder.withIndent('  ').convert(data);
    
    await platform.downloadFile(filename, encoded, 'application/json');
    return filename;
  }

  static Future<String> exportPdf(String baseName, List<Map<String, dynamic>> rows) async {
    final doc = pw.Document();

    // Filter columns that exist in data
    final availableColumns = _exportColumns.where((col) => 
      rows.isEmpty || rows.first.containsKey(col)
    ).toList();
    
    // Create headers with readable labels
    final headers = availableColumns.map((col) => _headerLabels[col] ?? col).toList();
    
    // Create data rows
    final data = rows.map((r) => 
      availableColumns.map((col) => _formatValueForPdf(col, r[col])).toList()
    ).toList();

    // Calculate column widths based on content type
    Map<int, pw.TableColumnWidth> columnWidths = {};
    for (int i = 0; i < availableColumns.length; i++) {
      final col = availableColumns[i];
      if (col == 'id') {
        columnWidths[i] = const pw.FixedColumnWidth(50);
      } else if (col.contains('Rating')) {
        columnWidths[i] = const pw.FixedColumnWidth(28);
      } else if (col == 'sex' || col == 'age') {
        columnWidths[i] = const pw.FixedColumnWidth(25);
      } else if (col == 'date' || col == 'submittedAt') {
        columnWidths[i] = const pw.FixedColumnWidth(55);
      } else if (col == 'region') {
        columnWidths[i] = const pw.FixedColumnWidth(35);
      } else if (col == 'clientType') {
        columnWidths[i] = const pw.FixedColumnWidth(55);
      } else if (col == 'serviceAvailed') {
        columnWidths[i] = const pw.FixedColumnWidth(75);
      } else if (col == 'suggestions') {
        columnWidths[i] = const pw.FixedColumnWidth(90);
      } else if (col == 'email') {
        columnWidths[i] = const pw.FixedColumnWidth(70);
      } else {
        columnWidths[i] = const pw.FlexColumnWidth();
      }
    }

    final headerStyle = pw.TextStyle(
      fontSize: 6,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    
    final cellStyle = const pw.TextStyle(fontSize: 6);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ARTA Compliance Report',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Generated: ${DateTime.now().toString().substring(0, 19)}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Total Records: ${rows.length}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'V-Serve ARTA Feedback Analytics',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          if (headers.isNotEmpty && data.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              columnWidths: columnWidths,
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              headerHeight: 25,
              cellHeight: 18,
              cellAlignments: Map.fromIterables(
                List.generate(headers.length, (i) => i),
                availableColumns.map((col) {
                  if (col.contains('Rating') || col == 'age') {
                    return pw.Alignment.center;
                  }
                  return pw.Alignment.centerLeft;
                }),
              ),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
            )
          else
            pw.Center(
              child: pw.Text(
                'No data available for export',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
        ],
      ),
    );

    final bytes = await doc.save();
    final filename = _safeFileName(baseName, 'pdf');
    
    await platform.downloadFileBytes(filename, bytes, 'application/pdf');
    return filename;
  }
}
