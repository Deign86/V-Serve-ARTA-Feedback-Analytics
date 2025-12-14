import 'package:flutter/material.dart'; // For Icons
import 'package:arta_css/widgets/survey_progress_bar.dart'; // For ProgressBarStep
import 'package:shared_preferences/shared_preferences.dart';
import 'audit_log_service_stub.dart';
import '../models/user_model.dart';

/// Service to manage survey configuration settings
/// These settings control which sections are shown in the survey flow
class SurveyConfigService extends ChangeNotifier {
  static const String _keyCcEnabled = 'survey_cc_enabled';
  static const String _keySqdEnabled = 'survey_sqd_enabled';
  static const String _keyDemographicsEnabled = 'survey_demographics_enabled';
  static const String _keySuggestionsEnabled = 'survey_suggestions_enabled';
  static const String _keyKioskMode = 'survey_kiosk_mode';

  // Audit log service reference (set externally)
  AuditLogService? _auditLogService;
  UserModel? _currentActor;
  
  /// Set the audit log service for logging configuration changes
  void setAuditService(AuditLogService auditService, UserModel? currentUser) {
    _auditLogService = auditService;
    _currentActor = currentUser;
  }

  // Default values - all sections enabled by default
  bool _ccEnabled = true;
  bool _sqdEnabled = true;
  bool _demographicsEnabled = true;
  bool _suggestionsEnabled = true;
  bool _kioskMode = false;

  bool _isLoaded = false;

  // Getters
  bool get ccEnabled => _ccEnabled;
  bool get sqdEnabled => _sqdEnabled;
  bool get demographicsEnabled => _demographicsEnabled;
  bool get suggestionsEnabled => _suggestionsEnabled;
  bool get kioskMode => _kioskMode;
  bool get isLoaded => _isLoaded;

  /// Load configuration from SharedPreferences
  Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _ccEnabled = prefs.getBool(_keyCcEnabled) ?? true;
      _sqdEnabled = prefs.getBool(_keySqdEnabled) ?? true;
      _demographicsEnabled = prefs.getBool(_keyDemographicsEnabled) ?? true;
      _suggestionsEnabled = prefs.getBool(_keySuggestionsEnabled) ?? true;
      _kioskMode = prefs.getBool(_keyKioskMode) ?? false;

      _isLoaded = true;
      notifyListeners();
      debugPrint('SurveyConfigService: Configuration loaded');
    } catch (e) {
      debugPrint('SurveyConfigService: Error loading config: $e');
      _isLoaded = true; // Mark as loaded even on error, use defaults
      notifyListeners();
    }
  }

  /// Save a single configuration value
  Future<void> _saveValue(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      debugPrint('SurveyConfigService: Saved $key = $value');
    } catch (e) {
      debugPrint('SurveyConfigService: Error saving $key: $e');
    }
  }

  // Setters with persistence and audit logging
  Future<void> setCcEnabled(bool value) async {
    final previousValue = _ccEnabled;
    _ccEnabled = value;
    notifyListeners();
    await _saveValue(_keyCcEnabled, value);
    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'Citizen\'s Charter Section',
      previousValue: previousValue,
      newValue: value,
    );
  }

  Future<void> setSqdEnabled(bool value) async {
    final previousValue = _sqdEnabled;
    _sqdEnabled = value;
    notifyListeners();
    await _saveValue(_keySqdEnabled, value);
    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'SQD Section',
      previousValue: previousValue,
      newValue: value,
    );
  }

  Future<void> setDemographicsEnabled(bool value) async {
    final previousValue = _demographicsEnabled;
    _demographicsEnabled = value;
    notifyListeners();
    await _saveValue(_keyDemographicsEnabled, value);
    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'Demographics Section',
      previousValue: previousValue,
      newValue: value,
    );
  }

  Future<void> setSuggestionsEnabled(bool value) async {
    final previousValue = _suggestionsEnabled;
    _suggestionsEnabled = value;
    notifyListeners();
    await _saveValue(_keySuggestionsEnabled, value);
    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'Suggestions Section',
      previousValue: previousValue,
      newValue: value,
    );
  }

  Future<void> setKioskMode(bool value) async {
    final previousValue = _kioskMode;
    _kioskMode = value;
    notifyListeners();
    await _saveValue(_keyKioskMode, value);
    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'Kiosk Mode',
      previousValue: previousValue,
      newValue: value,
    );
  }

  /// Get the number of survey steps based on current configuration
  int get totalSteps {
    int steps = 0;
    if (_demographicsEnabled) steps++; // User Profile
    if (_ccEnabled) steps++;
    if (_sqdEnabled) steps++;
    if (_suggestionsEnabled) steps++;
    return steps > 0 ? steps : 1; // Ensure at least 1 step for safety
  }

  /// Get list of visible steps for ProgressBar
  List<ProgressBarStep> getVisibleProgressBarSteps() {
    final List<ProgressBarStep> steps = [];
    
    if (_demographicsEnabled) {
      steps.add(const ProgressBarStep(icon: Icons.person_outline, label: 'Profile'));
    }
    
    if (_ccEnabled) {
      steps.add(const ProgressBarStep(icon: Icons.article_outlined, label: 'Charter'));
    }
    
    if (_sqdEnabled) {
      steps.add(const ProgressBarStep(icon: Icons.star_outline, label: 'Ratings'));
    }
    
    if (_suggestionsEnabled) {
      steps.add(const ProgressBarStep(icon: Icons.chat_bubble_outline, label: 'Feedback'));
    }
    
    // Fallback if all disabled (shouldn't happen in normal flow but good for safety)
    if (steps.isEmpty) {
      steps.add(const ProgressBarStep(icon: Icons.check_circle_outline, label: 'Done'));
    }
    
    return steps;
  }

  /// Calculate dynamic step number for a given screen
  int calculateStepNumber(SurveyStep step) {
    int stepNum = 0;

    // Profile is step 1 if enabled
    if (step == SurveyStep.profile) {
      return _demographicsEnabled ? 1 : -1;
    }
    
    if (_demographicsEnabled) stepNum++;

    // CC comes after profile if enabled
    if (step == SurveyStep.citizenCharter) {
      return _ccEnabled ? stepNum + 1 : -1;
    }
    if (_ccEnabled) stepNum++;

    // SQD comes after CC if enabled
    if (step == SurveyStep.sqd) {
      return _sqdEnabled ? stepNum + 1 : -1;
    }
    if (_sqdEnabled) stepNum++;

    // Suggestions comes last if enabled
    if (step == SurveyStep.suggestions) {
      return _suggestionsEnabled ? stepNum + 1 : -1;
    }

    return stepNum;
  }
}

enum SurveyStep { profile, citizenCharter, sqd, suggestions }