import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Conditional imports for web vs native download
import 'export_service_stub.dart'
    if (dart.library.html) 'export_service_web.dart'
    if (dart.library.io) 'export_service_native.dart' as platform;

/// Service for QR code generation, download, and printing
class QrCodeService {
  /// The Vercel deployment URL for the survey
  static const String surveyUrl = 'https://v-serve-arta-feedback-analytics.vercel.app';
  
  /// Survey ID for display
  static const String surveyId = 'ARTA-VAL-2024-Q1';

  /// Capture a widget as PNG bytes using a GlobalKey
  static Future<Uint8List?> captureWidgetAsImage(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// Download QR code as PNG image
  static Future<void> downloadQrCode(Uint8List imageBytes) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'ARTA_QR_Code_$timestamp.png';
    
    await platform.downloadFileBytes(filename, imageBytes, 'image/png');
  }

  /// Print QR code with survey information
  static Future<void> printQrCode(Uint8List qrImageBytes) async {
    final doc = pw.Document();
    
    final qrImage = pw.MemoryImage(qrImageBytes);
    
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'V-Serve ARTA Feedback Survey',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Scan to take the survey',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  width: 200,
                  height: 200,
                  child: pw.Image(qrImage),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'ID: $surveyId',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  surveyUrl,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.blue,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'City Government of Valenzuela',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'ARTA_Survey_QR_Code',
    );
  }
}
