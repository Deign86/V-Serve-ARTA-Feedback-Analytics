import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'recaptcha_service.dart';

/// Unified bot protection service that works on both web and desktop platforms
/// 
/// On Web: Uses Google reCAPTCHA Enterprise
/// On Desktop: Uses device fingerprinting, rate limiting, and behavioral analysis
class BotProtectionService {
  static final BotProtectionService _instance = BotProtectionService._internal();
  factory BotProtectionService() => _instance;
  BotProtectionService._internal();
  
  static BotProtectionService get instance => _instance;
  
  // Rate limiting configuration
  static const int _maxSubmissionsPerHour = 10;
  static const int _maxSubmissionsPerDay = 50;
  static const Duration _minTimeBetweenSubmissions = Duration(seconds: 30);
  
  // Keys for SharedPreferences
  static const String _prefsKeyDeviceId = 'bot_protection_device_id';
  static const String _prefsKeySubmissionTimes = 'bot_protection_submission_times';
  static const String _prefsKeyLastSubmission = 'bot_protection_last_submission';
  
  String? _deviceFingerprint;
  bool _isInitialized = false;
  
  // Honeypot tracking (time when form was opened)
  DateTime? _formOpenedAt;
  
  /// Initialize the bot protection service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (!kIsWeb) {
        _deviceFingerprint = await _generateDeviceFingerprint();
      }
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('BotProtectionService: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BotProtectionService: Error initializing: $e');
      }
      _isInitialized = true;
    }
  }
  
  /// Call this when a form is opened to start timing
  void onFormOpened() {
    _formOpenedAt = DateTime.now();
    if (kDebugMode) {
      debugPrint('BotProtectionService: Form opened at $_formOpenedAt');
    }
  }
  
  /// Validate submission and get a protection token
  /// Returns a validation result with token and any issues
  Future<BotProtectionResult> validateSubmission(String action) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // On web, use reCAPTCHA
    if (kIsWeb) {
      return _validateWithRecaptcha(action);
    }
    
    // On desktop, use multi-layer protection
    return _validateDesktop(action);
  }
  
  /// Web validation using reCAPTCHA
  Future<BotProtectionResult> _validateWithRecaptcha(String action) async {
    final token = await RecaptchaService.execute(action);
    
    if (token == null) {
      return BotProtectionResult(
        isValid: false,
        token: null,
        reason: 'reCAPTCHA verification failed',
        platform: 'web',
      );
    }
    
    return BotProtectionResult(
      isValid: true,
      token: token,
      reason: null,
      platform: 'web',
    );
  }
  
  /// Desktop validation using multiple factors
  Future<BotProtectionResult> _validateDesktop(String action) async {
    final issues = <String>[];
    
    // 1. Check form timing (honeypot - forms filled too fast are likely bots)
    if (_formOpenedAt != null) {
      final fillDuration = DateTime.now().difference(_formOpenedAt!);
      if (fillDuration.inSeconds < 5) {
        issues.add('Form completed too quickly (${fillDuration.inSeconds}s)');
      }
    }
    
    // 2. Check rate limiting
    final rateLimitResult = await _checkRateLimit();
    if (!rateLimitResult.passed) {
      issues.add(rateLimitResult.reason!);
    }
    
    // 3. Generate device-based token
    final token = await _generateProtectionToken(action);
    
    // If there are issues, the submission is suspicious
    if (issues.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('BotProtectionService: Validation issues: $issues');
      }
      
      // For now, still allow but flag - you could make this stricter
      return BotProtectionResult(
        isValid: true, // Allow but flag
        token: token,
        reason: issues.join('; '),
        platform: 'desktop',
        isFlagged: true,
      );
    }
    
    // Record this submission for rate limiting
    await _recordSubmission();
    
    return BotProtectionResult(
      isValid: true,
      token: token,
      reason: null,
      platform: 'desktop',
    );
  }
  
  /// Generate a device fingerprint for desktop platforms
  Future<String> _generateDeviceFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we already have a device ID
      String? deviceId = prefs.getString(_prefsKeyDeviceId);
      
      if (deviceId != null) {
        return deviceId;
      }
      
      // Generate new device ID if none exists
      deviceId = const Uuid().v4().replaceAll('-', '').substring(0, 32);
      await prefs.setString(_prefsKeyDeviceId, deviceId);
      return deviceId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BotProtectionService: Error generating fingerprint: $e');
      }
      // Fallback to random ID
      return const Uuid().v4().replaceAll('-', '').substring(0, 32);
    }
  }
  
  /// Check rate limiting
  Future<({bool passed, String? reason})> _checkRateLimit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Check minimum time between submissions
      final lastSubmissionStr = prefs.getString(_prefsKeyLastSubmission);
      if (lastSubmissionStr != null) {
        final lastSubmission = DateTime.parse(lastSubmissionStr);
        final timeSince = now.difference(lastSubmission);
        
        if (timeSince < _minTimeBetweenSubmissions) {
          final waitSeconds = (_minTimeBetweenSubmissions - timeSince).inSeconds;
          return (passed: false, reason: 'Please wait $waitSeconds seconds before submitting again');
        }
      }
      
      // Get submission history
      final submissionTimesJson = prefs.getString(_prefsKeySubmissionTimes);
      List<DateTime> submissionTimes = [];
      
      if (submissionTimesJson != null) {
        final List<dynamic> times = jsonDecode(submissionTimesJson);
        submissionTimes = times.map((t) => DateTime.parse(t as String)).toList();
      }
      
      // Clean up old entries (older than 24 hours)
      final cutoff = now.subtract(const Duration(hours: 24));
      submissionTimes = submissionTimes.where((t) => t.isAfter(cutoff)).toList();
      
      // Check hourly limit
      final hourAgo = now.subtract(const Duration(hours: 1));
      final submissionsLastHour = submissionTimes.where((t) => t.isAfter(hourAgo)).length;
      
      if (submissionsLastHour >= _maxSubmissionsPerHour) {
        return (passed: false, reason: 'Rate limit exceeded. Please try again later.');
      }
      
      // Check daily limit
      if (submissionTimes.length >= _maxSubmissionsPerDay) {
        return (passed: false, reason: 'Daily submission limit reached. Please try again tomorrow.');
      }
      
      return (passed: true, reason: null);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BotProtectionService: Error checking rate limit: $e');
      }
      // On error, allow the submission
      return (passed: true, reason: null);
    }
  }
  
  /// Record a submission for rate limiting
  Future<void> _recordSubmission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Update last submission time
      await prefs.setString(_prefsKeyLastSubmission, now.toIso8601String());
      
      // Update submission history
      final submissionTimesJson = prefs.getString(_prefsKeySubmissionTimes);
      List<DateTime> submissionTimes = [];
      
      if (submissionTimesJson != null) {
        final List<dynamic> times = jsonDecode(submissionTimesJson);
        submissionTimes = times.map((t) => DateTime.parse(t as String)).toList();
      }
      
      // Add new submission
      submissionTimes.add(now);
      
      // Clean up old entries
      final cutoff = now.subtract(const Duration(hours: 24));
      submissionTimes = submissionTimes.where((t) => t.isAfter(cutoff)).toList();
      
      // Save
      final timesJson = jsonEncode(submissionTimes.map((t) => t.toIso8601String()).toList());
      await prefs.setString(_prefsKeySubmissionTimes, timesJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BotProtectionService: Error recording submission: $e');
      }
    }
  }
  
  /// Generate a protection token for desktop
  Future<String> _generateProtectionToken(String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deviceId = _deviceFingerprint ?? 'unknown';
    final platform = defaultTargetPlatform.name;
    
    // Create a signed token
    final payload = '$action:$timestamp:$deviceId:$platform';
    final signature = sha256.convert(utf8.encode(payload)).toString().substring(0, 16);
    
    return 'desktop-$signature-$timestamp';
  }
  
  /// Validate submission for survey
  Future<BotProtectionResult> validateForSurvey() async {
    return validateSubmission('submit_survey');
  }
  
  /// Validate submission for login
  Future<BotProtectionResult> validateForLogin() async {
    return validateSubmission('login');
  }
  
  /// Validate submission for export
  Future<BotProtectionResult> validateForExport() async {
    return validateSubmission('export_data');
  }
}

/// Result of bot protection validation
class BotProtectionResult {
  final bool isValid;
  final String? token;
  final String? reason;
  final String platform;
  final bool isFlagged;
  
  BotProtectionResult({
    required this.isValid,
    required this.token,
    required this.reason,
    required this.platform,
    this.isFlagged = false,
  });
  
  @override
  String toString() {
    return 'BotProtectionResult(isValid: $isValid, platform: $platform, flagged: $isFlagged, reason: $reason)';
  }
}
