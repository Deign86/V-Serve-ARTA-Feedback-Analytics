import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// Service for handling Google reCAPTCHA v3 verification
/// 
/// SETUP INSTRUCTIONS:
/// 1. Go to https://www.google.com/recaptcha/admin
/// 2. Create a new site with reCAPTCHA v3
/// 3. Add your domains: v-serve-arta-feedback.vercel.app, localhost, 127.0.0.1
/// 4. Replace 'YOUR_RECAPTCHA_SITE_KEY' in web/index.html with your Site Key
/// 5. Replace 'YOUR_RECAPTCHA_SECRET_KEY' in backend verification with your Secret Key
class RecaptchaService {
  // Minimum score threshold (0.0 - 1.0, higher is more likely human)
  static const double minScore = 0.5;
  
  // Exact domains where reCAPTCHA is enforced
  static const List<String> _enforcedDomains = [
    'v-serve-arta-feedback.vercel.app',  // Production
    'localhost',                          // Local dev
    '127.0.0.1',                         // Local dev
  ];
  
  // Domain suffixes to also enforce (for Vercel previews)
  static const List<String> _enforcedSuffixes = [
    '.vercel.app',  // All Vercel deployments
  ];
  
  /// Check if we're on a domain that requires reCAPTCHA
  static bool get _shouldEnforceRecaptcha {
    if (!kIsWeb) return false;
    
    try {
      final currentHost = _getCurrentHost();
      
      // Check exact domain match
      if (_enforcedDomains.contains(currentHost)) {
        return true;
      }
      
      // Check suffix match (e.g., *.vercel.app)
      for (final suffix in _enforcedSuffixes) {
        if (currentHost.endsWith(suffix)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('RecaptchaService: Could not determine host: $e');
      return false;
    }
  }

  /// Execute reCAPTCHA and get a token for the specified action
  /// Returns null if not running on web, not on production, or if reCAPTCHA fails
  static Future<String?> execute(String action) async {
    if (!kIsWeb) {
      // reCAPTCHA is only for web platform
      debugPrint('RecaptchaService: Not running on web, skipping reCAPTCHA');
      return 'non-web-platform';
    }
    
    if (!_shouldEnforceRecaptcha) {
      // Skip reCAPTCHA for non-production environments (localhost, preview deployments)
      debugPrint('RecaptchaService: Not on production domain, skipping reCAPTCHA');
      return 'non-production-environment';
    }

    try {
      final token = await _executeRecaptcha(action);
      return token;
    } catch (e) {
      debugPrint('RecaptchaService: Error executing reCAPTCHA: $e');
      return null;
    }
  }

  /// Execute reCAPTCHA for survey submission
  static Future<String?> executeForSurvey() async {
    return execute('submit_survey');
  }

  /// Execute reCAPTCHA for login
  static Future<String?> executeForLogin() async {
    return execute('login');
  }

  /// Execute reCAPTCHA for export
  static Future<String?> executeForExport() async {
    return execute('export_data');
  }
}

/// JavaScript interop to get current hostname
@JS('window.location.hostname')
external String get _jsHostname;

String _getCurrentHost() {
  return _jsHostname;
}

/// JavaScript interop to call the executeRecaptcha function defined in index.html
@JS('executeRecaptcha')
external JSPromise<JSString> _jsExecuteRecaptcha(JSString action);

Future<String?> _executeRecaptcha(String action) async {
  try {
    final result = await _jsExecuteRecaptcha(action.toJS).toDart;
    return result.toDart;
  } catch (e) {
    debugPrint('RecaptchaService: JS interop error: $e');
    return null;
  }
}
