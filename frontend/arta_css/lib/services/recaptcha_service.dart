import 'package:flutter/foundation.dart';

// Conditional imports for web vs native
import 'recaptcha_js_stub.dart'
    if (dart.library.html) 'recaptcha_js_web.dart' as recaptcha_js;

/// Service for handling Google reCAPTCHA Enterprise verification
/// 
/// SETUP INSTRUCTIONS:
/// 1. Go to Google Cloud Console > reCAPTCHA
/// 2. Create a new site key with reCAPTCHA Enterprise
/// 3. Add your domains: v-serve-arta-feedback.vercel.app, vercel.app, localhost
/// 4. Replace the site key in web/index.html
/// 
/// NOTE: reCAPTCHA is only supported on web platform. On desktop/mobile,
/// the service returns bypass tokens and native protection is used instead.
class RecaptchaService {
  // Minimum score threshold (0.0 - 1.0, higher is more likely human)
  static const double minScore = 0.5;
  
  // Exact domains where reCAPTCHA is enforced (must match Google Cloud Console)
  static const List<String> _enforcedDomains = [
    'v-serve-arta-feedback.vercel.app',  // Production
    'localhost',                          // Local dev
  ];
  
  // Domain suffixes to also enforce (for Vercel previews)
  static const List<String> _enforcedSuffixes = [
    '.vercel.app',  // All Vercel deployments (matches vercel.app in console)
  ];
  
  /// Check if we're on a domain that requires reCAPTCHA
  static bool get shouldEnforceRecaptcha {
    // reCAPTCHA only works on web
    if (!kIsWeb) return false;
    
    try {
      final hostname = recaptcha_js.getCurrentHost();
      
      // Check exact domains
      if (_enforcedDomains.contains(hostname)) {
        return true;
      }
      
      // Check suffixes
      for (final suffix in _enforcedSuffixes) {
        if (hostname.endsWith(suffix)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('RecaptchaService: Error checking hostname: $e');
      return false;
    }
  }

  /// Execute reCAPTCHA and get a token for the specified action
  /// Returns null if not running on web, not on production, or if reCAPTCHA fails
  static Future<String?> execute(String action) async {
    if (!kIsWeb) {
      // reCAPTCHA is only for web platform - native uses BotProtectionService
      debugPrint('RecaptchaService: Not running on web, skipping reCAPTCHA');
      return 'non-web-platform';
    }
    
    if (!shouldEnforceRecaptcha) {
      // Skip reCAPTCHA for non-production environments
      debugPrint('RecaptchaService: Not on enforced domain, skipping reCAPTCHA');
      return 'non-production-environment';
    }

    try {
      // Execute reCAPTCHA via JavaScript interop
      final token = await recaptcha_js.executeRecaptcha(action);
      
      if (token == null || token.isEmpty) {
        debugPrint('RecaptchaService: Failed to get token');
        return null;
      }
      
      if (token == 'recaptcha-not-loaded') {
        debugPrint('RecaptchaService: reCAPTCHA not loaded yet');
        return null;
      }
      
      debugPrint('RecaptchaService: Got token for action: $action');
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
    return execute('LOGIN');
  }

  /// Execute reCAPTCHA for export
  static Future<String?> executeForExport() async {
    return execute('export_data');
  }
  
  /// Show the reCAPTCHA badge (call on login page)
  static void showBadge() {
    if (!kIsWeb) return;
    try {
      recaptcha_js.showRecaptchaBadge();
    } catch (e) {
      debugPrint('RecaptchaService: Error showing badge: $e');
    }
  }
  
  /// Hide the reCAPTCHA badge (call after login or on non-login pages)
  static void hideBadge() {
    if (!kIsWeb) return;
    try {
      recaptcha_js.hideRecaptchaBadge();
    } catch (e) {
      debugPrint('RecaptchaService: Error hiding badge: $e');
    }
  }
}
