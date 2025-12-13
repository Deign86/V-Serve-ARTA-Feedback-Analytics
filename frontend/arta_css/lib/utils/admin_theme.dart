import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Admin Dashboard Theme
/// 
/// This file provides consistent typography and colors for the admin dashboard.
/// 
/// Usage:
/// - Headings/Titles: Use [AdminTheme.headingXL], [AdminTheme.headingLarge], etc.
/// - Body text: Use [AdminTheme.bodyLarge], [AdminTheme.bodyMedium], etc.
/// - Colors: Use [AdminTheme.brandBlue], [AdminTheme.brandRed], etc.

class AdminTheme {
  // ============================================
  // BRAND COLORS
  // ============================================
  static final Color brandBlue = Colors.blue.shade900;
  static final Color brandRed = Colors.red.shade900;
  static const Color accentAmber = Colors.amber;
  
  // ============================================
  // HEADING STYLES (Montserrat)
  // Use for: titles, section headers, card headers
  // ============================================
  
  /// Extra large heading - main page titles (32px)
  static TextStyle headingXL({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.montserrat(
      fontSize: 32,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }
  
  /// Large heading - section titles (24px)
  static TextStyle headingLarge({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.montserrat(
      fontSize: 24,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }
  
  /// Medium heading - card headers (18px)
  static TextStyle headingMedium({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.montserrat(
      fontSize: 18,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }
  
  /// Small heading - subsection headers (16px)
  static TextStyle headingSmall({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }
  
  /// Extra small heading - labels (14px)
  static TextStyle headingXS({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }
  
  /// Dialog title style
  static TextStyle dialogTitle({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: color ?? brandBlue,
    );
  }
  
  // ============================================
  // BODY STYLES (Poppins)
  // Use for: paragraphs, descriptions, form labels
  // ============================================
  
  /// Large body text (16px)
  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }
  
  /// Medium body text - default paragraph (14px)
  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }
  
  /// Small body text - secondary info (12px)
  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }
  
  /// Extra small body text - captions (10px)
  static TextStyle bodyXS({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }
  
  /// Caption text - hints and labels (11px)
  static TextStyle caption({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }
  
  // ============================================
  // SPECIALIZED STYLES
  // ============================================
  
  /// Page title with dual color (used for "ARTA DASHBOARD" style headers)
  static TextSpan pageTitle({
    required String primary,
    required String secondary,
    Color primaryColor = Colors.amber,
    Color secondaryColor = Colors.white,
    double fontSize = 32,
  }) {
    return TextSpan(
      style: GoogleFonts.montserrat(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
      children: [
        TextSpan(text: primary, style: TextStyle(color: primaryColor)),
        TextSpan(text: secondary, style: TextStyle(color: secondaryColor)),
      ],
    );
  }
  
  /// Button text style
  static TextStyle buttonText({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    );
  }
  
  /// Stat card value style (large numbers)
  static TextStyle statValue({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: color ?? brandBlue,
    );
  }
  
  /// Stat card label style
  static TextStyle statLabel({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.grey.shade700,
    );
  }
  
  /// Chart title style
  static TextStyle chartTitle({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: color ?? brandBlue,
    );
  }
  
  /// Chart subtitle/description
  static TextStyle chartSubtitle({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: color ?? Colors.grey.shade600,
    );
  }
  
  /// Table header style
  static TextStyle tableHeader({Color? color}) {
    return GoogleFonts.montserrat(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: color ?? Colors.grey.shade700,
    );
  }
  
  /// Table cell style
  static TextStyle tableCell({Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.grey.shade800,
    );
  }
  
  /// Form label style
  static TextStyle formLabel({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color ?? Colors.grey.shade700,
    );
  }
  
  /// Link text style
  static TextStyle linkText({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color ?? Colors.blue,
    );
  }
  
  /// Analysis/report text with better line height
  static TextStyle analysisText({Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.normal,
      color: color ?? Colors.grey.shade800,
      height: 1.5,
    );
  }
}
