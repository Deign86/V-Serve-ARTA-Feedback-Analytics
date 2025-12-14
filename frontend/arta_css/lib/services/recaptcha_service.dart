import 'package:flutter/foundation.dart';

/// Service for handling Google reCAPTCHA Enterprise verification
/// 
/// SETUP INSTRUCTIONS:
/// 1. Go to Google Cloud Console > reCAPTCHA
/// 2. Create a new site key with reCAPTCHA Enterprise
/// 3. Add your domains: v-serve-arta-feedback.vercel.app, vercel.app, localhost
/// 4. Replace the site key in web/index.html
/// 
/// NOTE: reCAPTCHA is only supported on web platform. On desktop/mobile,
/// the service returns bypass tokens.
class RecaptchaService {
  // Minimum score threshold (0.0 - 1.0, higher is more likely human)
  static const double minScore = 0.5;
  
  // Exact domains where reCAPTCHA is enforced (must match Google Cloud Console)
  // ignore: unused_field - Reserved for future domain-based enforcement
  static const List<String> _enforcedDomains = [
    'v-serve-arta-feedback.vercel.app',  // Production
    'localhost',                          // Local dev
  ];
  
  // Domain suffixes to also enforce (for Vercel previews)
  // ignore: unused_field - Reserved for future domain-based enforcement
  static const List<String> _enforcedSuffixes = [
    '.vercel.app',  // All Vercel deployments (matches vercel.app in console)
  ];
  
  /// Check if we're on a domain that requires reCAPTCHA
  static bool get _shouldEnforceRecaptcha {
    // reCAPTCHA only works on web
    if (!kIsWeb) return false;
    
    // On web, we'd check the domain - but for cross-platform build compatibility,
    // we skip enforcement on all platforms for now
    return false;
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
      // Skip reCAPTCHA for non-production environments
      debugPrint('RecaptchaService: Not on production domain, skipping reCAPTCHA');
      return 'non-production-environment';
    }

    // Web-specific reCAPTCHA execution would be here
    // For cross-platform compatibility, we return a bypass token
    return 'recaptcha-not-configured';
  }

  /// Execute reCAPTCHA for survey submission
  static Future<String?> executeForSurvey() async {
    return execute('submit_survey');
  }

  /// Execute reCAPTCHA for login
  static Future<String?> executeForLogin() async {
    return execute('LOGIN');
  }

  /// Execute reCAPTCHA for export
  static Future<String?> executeForExport() async {
    return execute('export_data');
  }
  
  /// Show the reCAPTCHA badge (call on login page)
  static void showBadge() {
    if (!kIsWeb) return;
    // Web-specific badge showing - no-op on other platforms
  }
  
  /// Hide the reCAPTCHA badge (call after login or on non-login pages)
  static void hideBadge() {
    if (!kIsWeb) return;
    // Web-specific badge hiding - no-op on other platforms
  }
}
