import 'dart:convert';
import 'dart:math' as math;
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

  /// Export detailed analysis PDF with SQD breakdown, statistics, graphs, and comments
  static Future<String> exportDetailedAnalysisPdf(String baseName, List<Map<String, dynamic>> rows) async {
    final doc = pw.Document();

    // Calculate statistics
    final totalResponses = rows.length;
    
    // SQD labels for display (matching Detailed Analytics screen)
    const sqdLabels = {
      'sqd0Rating': 'SQD0: Satisfaction',
      'sqd1Rating': 'SQD1: Time',
      'sqd2Rating': 'SQD2: Requirements',
      'sqd3Rating': 'SQD3: Procedure',
      'sqd4Rating': 'SQD4: Information',
      'sqd5Rating': 'SQD5: Cost',
      'sqd6Rating': 'SQD6: Fairness',
      'sqd7Rating': 'SQD7: Courtesy',
      'sqd8Rating': 'SQD8: Outcome',
    };
    
    // SQD descriptions for detailed view
    const sqdDescriptions = {
      'sqd0Rating': 'I am satisfied with the service that I availed',
      'sqd1Rating': 'I spent a reasonable amount of time for my transaction',
      'sqd2Rating': 'The office followed the transaction requirements',
      'sqd3Rating': 'The steps were easy and simple',
      'sqd4Rating': 'I easily found information about my transaction',
      'sqd5Rating': 'I paid a reasonable amount of fees',
      'sqd6Rating': 'I feel the office was fair to everyone',
      'sqd7Rating': 'I was treated courteously by the staff',
      'sqd8Rating': 'I got what I needed from the government office',
    };
    
    const ccLabels = {
      'cc0Rating': 'CC1: Awareness of CC',
      'cc1Rating': 'CC2: Visibility',
      'cc2Rating': 'CC3: Posting',
      'cc3Rating': 'CC4: Understanding',
    };

    // Calculate SQD averages
    Map<String, double> sqdAverages = {};
    for (final key in sqdLabels.keys) {
      final values = rows
          .map((r) => r[key])
          .where((v) => v != null)
          .map((v) => v is int ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0))
          .toList();
      if (values.isNotEmpty) {
        sqdAverages[key] = values.reduce((a, b) => a + b) / values.length;
      }
    }

    // Calculate CC averages
    Map<String, double> ccAverages = {};
    for (final key in ccLabels.keys) {
      final values = rows
          .map((r) => r[key])
          .where((v) => v != null)
          .map((v) => v is int ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0))
          .toList();
      if (values.isNotEmpty) {
        ccAverages[key] = values.reduce((a, b) => a + b) / values.length;
      }
    }

    // Calculate overall satisfaction
    final allSqdScores = sqdAverages.values.toList();
    final overallSqd = allSqdScores.isNotEmpty 
        ? allSqdScores.reduce((a, b) => a + b) / allSqdScores.length 
        : 0.0;

    // Client type breakdown
    Map<String, int> clientTypes = {};
    for (final row in rows) {
      final type = row['clientType']?.toString() ?? 'Unknown';
      clientTypes[type] = (clientTypes[type] ?? 0) + 1;
    }

    // Region breakdown
    Map<String, int> regions = {};
    for (final row in rows) {
      final region = row['region']?.toString() ?? 'Unknown';
      regions[region] = (regions[region] ?? 0) + 1;
    }
    
    // Service breakdown with averages (for Satisfaction by Service graph)
    Map<String, List<double>> serviceRatings = {};
    for (final row in rows) {
      final service = row['serviceAvailed']?.toString() ?? 'Other';
      final rating = row['sqd0Rating'];
      if (rating != null) {
        serviceRatings.putIfAbsent(service, () => []);
        final ratingValue = rating is int ? rating.toDouble() : (double.tryParse(rating.toString()) ?? 0.0);
        serviceRatings[service]!.add(ratingValue);
      }
    }
    Map<String, double> serviceBreakdown = serviceRatings.map((service, ratings) => 
        MapEntry(service, ratings.reduce((a, b) => a + b) / ratings.length));
    
    // Sort services by score and get top 5
    final sortedServices = serviceBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topServices = sortedServices.take(5).toList();
    
    // Get top and bottom performing services
    final topService = sortedServices.isNotEmpty ? sortedServices.first : null;
    final needsAttention = sortedServices.isNotEmpty ? sortedServices.last : null;
    
    // Get strongest SQD
    final sortedSqd = sqdAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final strongestSqd = sortedSqd.isNotEmpty ? sortedSqd.first : null;

    // Collect all suggestions/comments
    final suggestions = rows
        .map((r) => r['suggestions']?.toString())
        .where((s) => s != null && s.isNotEmpty && s != 'null')
        .toList();

    // Title page with highlights (matching Detailed Analytics highlight cards)
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'ARTA CLIENT SATISFACTION',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'DETAILED ANALYSIS REPORT',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey600),
            ),
            pw.SizedBox(height: 40),
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey300, width: 2),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Total Responses: $totalResponses',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Overall Satisfaction Score',
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '${overallSqd.toStringAsFixed(2)} / 5.00',
                    style: pw.TextStyle(
                      fontSize: 32, 
                      fontWeight: pw.FontWeight.bold,
                      color: overallSqd >= 4 ? PdfColors.green700 : (overallSqd >= 3 ? PdfColors.orange700 : PdfColors.red700),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            // Performance Highlights (matching Detailed Analytics highlight cards)
            pw.Text(
              'PERFORMANCE HIGHLIGHTS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
            ),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildPdfHighlightBox(
                  'Top Performing Service',
                  topService?.key ?? 'N/A',
                  'Score: ${topService?.value.toStringAsFixed(1) ?? "0.0"}/5.0',
                  PdfColors.green700,
                ),
                _buildPdfHighlightBox(
                  'Needs Attention',
                  needsAttention?.key ?? 'N/A',
                  'Score: ${needsAttention?.value.toStringAsFixed(1) ?? "0.0"}/5.0',
                  PdfColors.orange700,
                ),
                _buildPdfHighlightBox(
                  'Strongest Dimension',
                  strongestSqd != null ? sqdLabels[strongestSqd.key]?.split(':').last.trim() ?? strongestSqd.key : 'N/A',
                  'Score: ${strongestSqd?.value.toStringAsFixed(1) ?? "0.0"}/5.0',
                  PdfColors.blue700,
                ),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              'Generated: ${DateTime.now().toString().substring(0, 19)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'V-Serve ARTA Feedback Analytics',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
      ),
    );

    // SQD Analysis Page with Visual Bars (matching Detailed Analytics SQD Breakdown)
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Service Quality Dimensions (SQD) Breakdown',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 10),
            pw.Text(
              'Score interpretation: 5 - Strongly Agree, 1 - Strongly Disagree. ARTA compliance requires detailed tracking of all 9 dimensions.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 15),
            // SQD cards with visual bars
            ...sqdLabels.entries.map((e) {
              final avg = sqdAverages[e.key] ?? 0.0;
              final desc = sqdDescriptions[e.key] ?? '';
              return _buildPdfSqdRow(e.value, desc, avg);
            }),
            pw.SizedBox(height: 20),
            pw.Text(
              'Citizen\'s Charter (CC) Awareness Analysis',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 15),
            pw.TableHelper.fromTextArray(
              headers: ['Dimension', 'Average Score', 'Rating'],
              data: ccLabels.entries.map((e) {
                final avg = ccAverages[e.key] ?? 0.0;
                String rating;
                if (avg >= 4.5) {
                  rating = 'Excellent';
                } else if (avg >= 4.0) {
                  rating = 'Very Good';
                } else if (avg >= 3.0) {
                  rating = 'Good';
                } else if (avg >= 2.0) {
                  rating = 'Fair';
                } else {
                  rating = 'Poor';
                }
                return [e.value, avg.toStringAsFixed(2), rating];
              }).toList(),
              headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellHeight: 25,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
          ],
        ),
      ),
    );
    
    // Visual Charts Page - Pie Chart and Bar Chart
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Two charts side by side
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Satisfaction by Service - Bar Chart
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 16,
                              height: 16,
                              decoration: const pw.BoxDecoration(color: PdfColors.blue700),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text('Satisfaction by Service', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 15),
                        if (topServices.isEmpty)
                          pw.Text('No data', style: const pw.TextStyle(color: PdfColors.grey400))
                        else
                          ...topServices.map((entry) => _buildPdfServiceBar(entry.key, entry.value)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 15),
                // Respondent Profile - Pie Chart
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 16,
                              height: 16,
                              decoration: const pw.BoxDecoration(color: PdfColors.red700),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text('Respondent Profile', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 15),
                        // Actual Pie Chart
                        pw.Center(
                          child: _buildPdfPieChart(clientTypes, totalResponses),
                        ),
                        pw.SizedBox(height: 15),
                        // Legend
                        pw.Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          children: clientTypes.entries.map((entry) {
                            final color = _getClientTypeColor(entry.key);
                            return pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Container(width: 10, height: 10, color: color),
                                pw.SizedBox(width: 4),
                                pw.Text('${entry.key} (${entry.value})', style: const pw.TextStyle(fontSize: 7)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 25),
            // Radar Chart for SQD Analysis
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Visual SQD Analysis (Radar)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  // Debug: Show calculated values
                  pw.Text(
                    'Values: ${sqdAverages.entries.map((e) => "${e.key.replaceAll("Rating", "")}: ${e.value.toStringAsFixed(2)}").join(", ")}',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Center(
                    child: _buildPdfRadarChart(sqdAverages, sqdLabels),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Demographics Page
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Demographic Breakdown',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 15),
            pw.Text(
              'Client Type Distribution',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Client Type', 'Count', 'Percentage'],
              data: clientTypes.entries.map((e) {
                final pct = totalResponses > 0 ? (e.value / totalResponses * 100) : 0.0;
                return [e.key, e.value.toString(), '${pct.toStringAsFixed(1)}%'];
              }).toList(),
              headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellHeight: 22,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
            pw.SizedBox(height: 25),
            pw.Text(
              'Regional Distribution',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Region', 'Count', 'Percentage'],
              data: regions.entries.take(15).map((e) {
                final pct = totalResponses > 0 ? (e.value / totalResponses * 100) : 0.0;
                return [e.key, e.value.toString(), '${pct.toStringAsFixed(1)}%'];
              }).toList(),
              headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellHeight: 22,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
          ],
        ),
      ),
    );

    // Comments/Suggestions Page
    if (suggestions.isNotEmpty) {
      final suggestionsPerPage = 20;
      final totalPages = (suggestions.length / suggestionsPerPage).ceil();
      
      for (int page = 0; page < totalPages; page++) {
        final startIdx = page * suggestionsPerPage;
        final endIdx = (startIdx + suggestionsPerPage).clamp(0, suggestions.length);
        final pageSuggestions = suggestions.sublist(startIdx, endIdx);
        
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(30),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Suggestions & Comments${totalPages > 1 ? ' (Page ${page + 1} of $totalPages)' : ''}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total Comments: ${suggestions.length}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 15),
                ...pageSuggestions.asMap().entries.map((entry) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                    color: entry.key % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 25,
                        child: pw.Text(
                          '${startIdx + entry.key + 1}.',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey600),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          entry.value ?? '',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      }
    }

    final bytes = await doc.save();
    final filename = _safeFileName(baseName, 'pdf');
    
    await platform.downloadFileBytes(filename, bytes, 'application/pdf');
    return filename;
  }
  
  /// Helper: Build PDF highlight box (matching Detailed Analytics highlight cards)
  static pw.Widget _buildPdfHighlightBox(String label, String value, String sub, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(
            value.length > 18 ? '${value.substring(0, 18)}...' : value, 
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(sub, style: pw.TextStyle(fontSize: 8, color: color, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
  
  /// Helper: Build PDF SQD row with visual bar (matching Detailed Analytics SQD cards)
  static pw.Widget _buildPdfSqdRow(String title, String description, double score) {
    final scoreColor = score >= 4.5 ? PdfColors.green700 : (score >= 4.0 ? PdfColors.amber700 : PdfColors.red700);
    final barWidthPercent = ((score / 5.0) * 100).clamp(0.0, 100.0);
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: scoreColor.shade(50),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  score.toStringAsFixed(2),
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: scoreColor),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(description, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 6),
          // Progress bar using Row with flex
          pw.Row(
            children: [
              if (barWidthPercent > 0)
                pw.Expanded(
                  flex: barWidthPercent.round(),
                  child: pw.Container(height: 6, decoration: pw.BoxDecoration(color: PdfColors.blueGrey700, borderRadius: pw.BorderRadius.circular(3))),
                ),
              if (barWidthPercent < 100)
                pw.Expanded(
                  flex: (100 - barWidthPercent).round(),
                  child: pw.Container(height: 6, decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(3))),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Helper: Build PDF service bar (matching Detailed Analytics Satisfaction by Service chart)
  static pw.Widget _buildPdfServiceBar(String serviceName, double score) {
    final barWidthPercent = ((score / 5.0) * 100).clamp(0.0, 100.0);
    final displayName = serviceName.length > 25 ? '${serviceName.substring(0, 25)}...' : serviceName;
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(displayName, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700), textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Row(
              children: [
                if (barWidthPercent > 0)
                  pw.Expanded(
                    flex: barWidthPercent.round(),
                    child: pw.Container(height: 18, decoration: pw.BoxDecoration(color: PdfColors.blueGrey600, borderRadius: pw.BorderRadius.circular(4))),
                  ),
                if (barWidthPercent < 100)
                  pw.Expanded(
                    flex: (100 - barWidthPercent).round(),
                    child: pw.Container(height: 18, decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4))),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(score.toStringAsFixed(1), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
        ],
      ),
    );
  }
  
  /// Helper: Get color for client type
  static PdfColor _getClientTypeColor(String clientType) {
    final colors = {
      'CITIZEN': PdfColors.blue600,
      'Citizen': PdfColors.blue600,
      'BUSINESS': PdfColors.red600,
      'Business': PdfColors.red600,
      'GOVERNMENT': PdfColors.green600,
      'Government': PdfColors.green600,
      'GOVERNMENT (EMPLOYEE OR ANOTHER AGENCY)': PdfColors.green600,
    };
    return colors[clientType] ?? PdfColors.purple600;
  }
  
  /// Helper: Build actual PDF Pie Chart using custom painting
  static pw.Widget _buildPdfPieChart(Map<String, int> data, int total) {
    if (data.isEmpty || total == 0) {
      return pw.Container(
        width: 120,
        height: 120,
        child: pw.Center(child: pw.Text('No data', style: const pw.TextStyle(color: PdfColors.grey400))),
      );
    }
    
    return pw.CustomPaint(
      size: const PdfPoint(140, 140),
      painter: (canvas, size) {
        final centerX = size.x / 2;
        final centerY = size.y / 2;
        final radius = math.min(centerX, centerY) - 5;
        final innerRadius = radius * 0.5; // Donut chart
        
        double startAngle = -math.pi / 2; // Start from top
        
        final entries = data.entries.toList();
        for (int i = 0; i < entries.length; i++) {
          final entry = entries[i];
          final sweepAngle = (entry.value / total) * 2 * math.pi;
          final color = _getClientTypeColor(entry.key);
          
          // Draw pie slice (donut)
          canvas
            ..setFillColor(color)
            ..moveTo(centerX + innerRadius * math.cos(startAngle), centerY + innerRadius * math.sin(startAngle));
          
          // Outer arc
          for (double a = 0; a <= sweepAngle; a += 0.05) {
            canvas.lineTo(
              centerX + radius * math.cos(startAngle + a),
              centerY + radius * math.sin(startAngle + a),
            );
          }
          
          // Inner arc (reverse)
          for (double a = sweepAngle; a >= 0; a -= 0.05) {
            canvas.lineTo(
              centerX + innerRadius * math.cos(startAngle + a),
              centerY + innerRadius * math.sin(startAngle + a),
            );
          }
          
          canvas
            ..closePath()
            ..fillPath();
          
          startAngle += sweepAngle;
        }
      },
    );
  }
  
  /// Helper: Build actual PDF Radar Chart using custom painting with labels
  static pw.Widget _buildPdfRadarChart(Map<String, double> sqdAverages, Map<String, String> sqdLabels) {
    final entries = sqdLabels.entries.toList();
    final dataPoints = entries.map((e) => sqdAverages[e.key] ?? 0.0).toList();
    
    if (dataPoints.isEmpty || dataPoints.every((v) => v == 0)) {
      return pw.Container(
        width: 300,
        height: 300,
        child: pw.Center(child: pw.Text('No data available', style: const pw.TextStyle(color: PdfColors.grey400))),
      );
    }
    
    const double chartSize = 350;
    const double centerOffset = chartSize / 2;
    const double radius = centerOffset - 55; // Leave room for labels
    final numPoints = dataPoints.length;
    final angleStep = (2 * math.pi) / numPoints;
    
    // Calculate label positions for the Stack
    // Use the same angle calculation as the chart drawing
    // In Stack widget coordinates: origin is top-left, Y increases downward
    final labelWidgets = <pw.Widget>[];
    for (int i = 0; i < numPoints; i++) {
      // Start from top (negative Y in cartesian = positive angle from -pi/2)
      // and go clockwise
      final angle = -math.pi / 2 + i * angleStep;
      // Position labels outside the chart
      final labelRadius = radius + 35;
      
      // For Stack positioning: cos(angle) for X, sin(angle) for Y
      // sin(-pi/2) = -1, so the top point has negative Y offset from center
      // In Stack coordinates, we add to center because top=0 is the top
      final labelX = centerOffset + labelRadius * math.cos(angle);
      final labelY = centerOffset + labelRadius * math.sin(angle);
      
      final label = 'SQD$i';
      
      // Adjust positioning to center the text label
      // Adjust X offset based on position (left/center/right alignment)
      double xAdjust = -15; // Default center
      if (math.cos(angle) < -0.3) {
        xAdjust = -25; // Left side - shift more left
      } else if (math.cos(angle) > 0.3) {
        xAdjust = -5; // Right side - shift less
      }
      
      labelWidgets.add(
        pw.Positioned(
          left: labelX + xAdjust,
          top: labelY - 6, // Center vertically
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
      );
    }
    
    return pw.Column(
      children: [
        pw.SizedBox(
          width: chartSize,
          height: chartSize,
          child: pw.Stack(
            children: [
              // The radar chart graphic
              pw.Positioned.fill(
                child: pw.CustomPaint(
                  size: const PdfPoint(chartSize, chartSize),
                  painter: (canvas, size) {
                    final centerX = size.x / 2;
                    final centerY = size.y / 2;
                    
                    // Draw grid lines (5 levels)
                    // Note: In PDF canvas, Y=0 is at bottom and increases upward
                    // We negate the sin() result to flip the chart so it matches
                    // the widget Stack coordinates (Y increases downward)
                    for (int level = 1; level <= 5; level++) {
                      final levelRadius = (radius / 5) * level;
                      canvas
                        ..setStrokeColor(PdfColors.grey300)
                        ..setLineWidth(0.5);
                      
                      for (int i = 0; i < numPoints; i++) {
                        final angle = -math.pi / 2 + i * angleStep;
                        final nextAngle = -math.pi / 2 + ((i + 1) % numPoints) * angleStep;
                        
                        final x1 = centerX + levelRadius * math.cos(angle);
                        final y1 = centerY - levelRadius * math.sin(angle); // Negate sin for Y
                        final x2 = centerX + levelRadius * math.cos(nextAngle);
                        final y2 = centerY - levelRadius * math.sin(nextAngle); // Negate sin for Y
                        
                        canvas
                          ..moveTo(x1, y1)
                          ..lineTo(x2, y2)
                          ..strokePath();
                      }
                    }
                    
                    // Draw axis lines from center
                    canvas
                      ..setStrokeColor(PdfColors.grey400)
                      ..setLineWidth(0.5);
                    for (int i = 0; i < numPoints; i++) {
                      final angle = -math.pi / 2 + i * angleStep;
                      final x = centerX + radius * math.cos(angle);
                      final y = centerY - radius * math.sin(angle); // Negate sin for Y
                      
                      canvas
                        ..moveTo(centerX, centerY)
                        ..lineTo(x, y)
                        ..strokePath();
                    }
                    
                    // Draw data polygon (filled)
                    final dataPath = <PdfPoint>[];
                    for (int i = 0; i < numPoints; i++) {
                      final angle = -math.pi / 2 + i * angleStep;
                      final value = dataPoints[i].clamp(0, 5);
                      final pointRadius = (radius / 5) * value;
                      dataPath.add(PdfPoint(
                        centerX + pointRadius * math.cos(angle),
                        centerY - pointRadius * math.sin(angle), // Negate sin for Y
                      ));
                    }
                    
                    // Fill polygon
                    canvas.setFillColor(PdfColor.fromInt(0x66C53030)); // Semi-transparent red
                    canvas.moveTo(dataPath[0].x, dataPath[0].y);
                    for (int i = 1; i < dataPath.length; i++) {
                      canvas.lineTo(dataPath[i].x, dataPath[i].y);
                    }
                    canvas
                      ..closePath()
                      ..fillPath();
                    
                    // Stroke polygon
                    canvas.setStrokeColor(PdfColors.red700);
                    canvas.setLineWidth(2);
                    canvas.moveTo(dataPath[0].x, dataPath[0].y);
                    for (int i = 1; i < dataPath.length; i++) {
                      canvas.lineTo(dataPath[i].x, dataPath[i].y);
                    }
                    canvas
                      ..closePath()
                      ..strokePath();
                    
                    // Draw data points
                    canvas.setFillColor(PdfColors.red700);
                    for (final point in dataPath) {
                      canvas
                        ..drawEllipse(point.x, point.y, 3, 3)
                        ..fillPath();
                    }
                  },
                ),
              ),
              // Labels positioned around the chart
              ...labelWidgets,
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        // Legend with scores below the chart
        pw.Wrap(
          spacing: 15,
          runSpacing: 5,
          alignment: pw.WrapAlignment.center,
          children: entries.asMap().entries.map((entry) {
            final idx = entry.key;
            final label = 'SQD$idx';
            final score = dataPoints[idx];
            return pw.Text('$label: ${score.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 8));
          }).toList(),
        ),
      ],
    );
  }
}
