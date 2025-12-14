import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'recaptcha_service.dart';

/// Unified bot protection service that works on both web and native platforms
/// 
/// On Web: Uses Google reCAPTCHA Enterprise for spam protection
/// On Native (Windows/macOS/Linux/Android/iOS): Uses device fingerprinting, 
/// rate limiting, behavioral analysis, and proof-of-work challenges
class BotProtectionService {
  static final BotProtectionService _instance = BotProtectionService._internal();
  factory BotProtectionService() => _instance;
  BotProtectionService._internal();
  
  static BotProtectionService get instance => _instance;
  
  // Rate limiting configuration
  static const int _maxSubmissionsPerHour = 10;
  static const int _maxSubmissionsPerDay = 50;
  static const Duration _minTimeBetweenSubmissions = Duration(seconds: 30);
  
  // Proof-of-work difficulty (higher = more CPU time required)
  static const int _powDifficulty = 4; // Number of leading zeros required
  
  // Keys for SharedPreferences
  static const String _prefsKeyDeviceId = 'bot_protection_device_id';
  static const String _prefsKeySubmissionTimes = 'bot_protection_submission_times';
  static const String _prefsKeyLastSubmission = 'bot_protection_last_submission';
  static const String _prefsKeyDeviceFingerprint = 'bot_protection_fingerprint';
  
  String? _deviceFingerprint;
  String? _deviceId;
  bool _isInitialized = false;
  
  // Honeypot tracking (time when form was opened)
  DateTime? _formOpenedAt;
  
  // Interaction tracking for behavioral analysis
  int _interactionCount = 0;
  final List<DateTime> _interactionTimes = [];
  
  /// Initialize the bot protection service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load or generate device ID
      _deviceId = prefs.getString(_prefsKeyDeviceId);
      if (_deviceId == null) {
        _deviceId = const Uuid().v4();
        await prefs.setString(_prefsKeyDeviceId, _deviceId!);
      }
      
      if (!kIsWeb) {
        _deviceFingerprint = await _generateDeviceFingerprint();
      }
      
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('BotProtectionService: Initialized (platform: ${kIsWeb ? "web" : "native"})');
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
    _interactionCount = 0;
    _interactionTimes.clear();
    if (kDebugMode) {
      debugPrint('BotProtectionService: Form opened at $_formOpenedAt');
    }
  }
  
  /// Call this when user interacts with the form (typing, clicking, etc.)
  void recordInteraction() {
    _interactionCount++;
    _interactionTimes.add(DateTime.now());
    // Keep only last 100 interactions
    if (_interactionTimes.length > 100) {
      _interactionTimes.removeAt(0);
    }
  }
  
  /// Validate submission and get a protection token
  /// Returns a validation result with token and any issues
  Future<BotProtectionResult> validateSubmission(String action) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // On web, use reCAPTCHA if available
    if (kIsWeb) {
      return _validateWithRecaptcha(action);
    }
    
    // On native, use multi-layer protection
    return _validateNative(action);
  }
  
  /// Web validation using reCAPTCHA
  Future<BotProtectionResult> _validateWithRecaptcha(String action) async {
    final token = await RecaptchaService.execute(action);
    
    if (token == null) {
      return BotProtectionResult(
        isValid: false,
        token: null,
        reason: 'reCAPTCHA verification failed. Please try again.',
        platform: 'web',
      );
    }
    
    // Bypass tokens are valid but indicate reCAPTCHA wasn't enforced
    final isBypass = token == 'non-web-platform' || 
                     token == 'non-production-environment' ||
                     token == 'recaptcha-not-loaded';
    
    return BotProtectionResult(
      isValid: true,
      token: token,
      reason: isBypass ? 'reCAPTCHA bypassed (development mode)' : null,
      platform: 'web',
      isFlagged: isBypass,
    );
  }
  
  /// Native validation using multiple factors
  Future<BotProtectionResult> _validateNative(String action) async {
    final issues = <String>[];
    double trustScore = 100.0;
    
    // 1. Check form timing (honeypot - forms filled too fast are likely bots)
    if (_formOpenedAt != null) {
      final fillDuration = DateTime.now().difference(_formOpenedAt!);
      if (fillDuration.inSeconds < 3) {
        issues.add('Form completed too quickly (${fillDuration.inSeconds}s)');
        trustScore -= 40;
      } else if (fillDuration.inSeconds < 10) {
        trustScore -= 20;
      }
    } else {
      // Form timing not tracked - suspicious
      trustScore -= 15;
    }
    
    // 2. Check interaction count (bots typically don't generate realistic interactions)
    if (_interactionCount < 3) {
      issues.add('Too few interactions detected');
      trustScore -= 25;
    } else if (_interactionCount > 5) {
      trustScore += 10; // Bonus for realistic interaction
    }
    
    // 3. Check interaction timing patterns (bots have uniform timing)
    if (_interactionTimes.length >= 3) {
      final isNaturalTiming = _checkNaturalTiming();
      if (!isNaturalTiming) {
        issues.add('Interaction timing appears automated');
        trustScore -= 20;
      }
    }
    
    // 4. Check rate limiting
    final rateLimitResult = await _checkRateLimit();
    if (!rateLimitResult.passed) {
      return BotProtectionResult(
        isValid: false,
        token: null,
        reason: rateLimitResult.reason,
        platform: 'native',
      );
    }
    
    // 5. Generate proof-of-work challenge for low trust scores
    String token;
    if (trustScore < 50) {
      // Require proof-of-work for suspicious submissions
      token = await _generateProofOfWork(action);
      issues.add('Proof-of-work challenge completed');
    } else {
      token = await _generateProtectionToken(action);
    }
    
    // Determine if submission should be allowed
    final isValid = trustScore >= 30; // Allow with low trust but flag
    final isFlagged = trustScore < 70 || issues.isNotEmpty;
    
    if (kDebugMode && issues.isNotEmpty) {
      debugPrint('BotProtectionService: Issues: $issues, Trust: $trustScore');
    }
    
    // Record this submission for rate limiting (only if valid)
    if (isValid) {
      await _recordSubmission();
    }
    
    return BotProtectionResult(
      isValid: isValid,
      token: token,
      reason: issues.isNotEmpty ? issues.join('; ') : null,
      platform: 'native',
      isFlagged: isFlagged,
      trustScore: trustScore,
    );
  }
  
  /// Check if interaction timing appears natural (human-like variance)
  bool _checkNaturalTiming() {
    if (_interactionTimes.length < 3) return true;
    
    final intervals = <int>[];
    for (int i = 1; i < _interactionTimes.length; i++) {
      intervals.add(_interactionTimes[i].difference(_interactionTimes[i - 1]).inMilliseconds);
    }
    
    // Calculate variance - bots have very low variance
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((i) => (i - mean) * (i - mean)).reduce((a, b) => a + b) / intervals.length;
    final stdDev = variance > 0 ? variance / mean : 0;
    
    // Human typing typically has high variance (stdDev > 0.3)
    return stdDev > 0.2;
  }
  
  /// Generate a device fingerprint for native platforms
  Future<String> _generateDeviceFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check cache first
      String? fingerprint = prefs.getString(_prefsKeyDeviceFingerprint);
      if (fingerprint != null) {
        return fingerprint;
      }
      
      // Generate new fingerprint from device info
      final deviceInfo = DeviceInfoPlugin();
      String deviceData = '';
      
      if (defaultTargetPlatform == TargetPlatform.windows) {
        final info = await deviceInfo.windowsInfo;
        deviceData = '${info.computerName}|${info.numberOfCores}|${info.systemMemoryInMegabytes}';
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final info = await deviceInfo.macOsInfo;
        deviceData = '${info.computerName}|${info.model}|${info.memorySize}';
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final info = await deviceInfo.linuxInfo;
        deviceData = '${info.name}|${info.machineId}|${info.prettyName}';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await deviceInfo.androidInfo;
        deviceData = '${info.brand}|${info.model}|${info.id}|${info.fingerprint}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await deviceInfo.iosInfo;
        deviceData = '${info.name}|${info.model}|${info.identifierForVendor}';
      }
      
      // Hash the device data
      fingerprint = sha256.convert(utf8.encode(deviceData + (_deviceId ?? ''))).toString();
      
      // Cache for future use
      await prefs.setString(_prefsKeyDeviceFingerprint, fingerprint);
      
      return fingerprint;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BotProtectionService: Error generating fingerprint: $e');
      }
      // Fallback to device ID
      return _deviceId ?? const Uuid().v4();
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
  
  /// Generate a protection token for native
  Future<String> _generateProtectionToken(String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deviceId = _deviceFingerprint ?? _deviceId ?? 'unknown';
    final platform = defaultTargetPlatform.name;
    
    // Create a signed token
    final payload = '$action:$timestamp:$deviceId:$platform';
    final signature = sha256.convert(utf8.encode(payload)).toString().substring(0, 16);
    
    return 'native-$signature-$timestamp';
  }
  
  /// Generate a proof-of-work token (computationally expensive for bots)
  Future<String> _generateProofOfWork(String action) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final challenge = '$action:$timestamp:${_deviceId ?? 'unknown'}';
    
    int nonce = 0;
    String hash;
    final prefix = '0' * _powDifficulty;
    
    // Find a nonce that produces a hash with the required leading zeros
    do {
      nonce++;
      hash = sha256.convert(utf8.encode('$challenge:$nonce')).toString();
    } while (!hash.startsWith(prefix) && nonce < 1000000);
    
    if (kDebugMode) {
      debugPrint('BotProtectionService: PoW completed with nonce=$nonce');
    }
    
    return 'pow-$nonce-${hash.substring(0, 16)}-$timestamp';
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
  final double? trustScore;
  
  BotProtectionResult({
    required this.isValid,
    required this.token,
    required this.reason,
    required this.platform,
    this.isFlagged = false,
    this.trustScore,
  });
  
  @override
  String toString() {
    return 'BotProtectionResult(isValid: $isValid, platform: $platform, flagged: $isFlagged, trust: $trustScore, reason: $reason)';
  }
}
