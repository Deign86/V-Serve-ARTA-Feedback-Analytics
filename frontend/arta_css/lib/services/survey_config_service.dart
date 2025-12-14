import 'package:flutter/material.dart'; // For Icons
import 'package:arta_css/widgets/survey_progress_bar.dart'; // For ProgressBarStep
import 'audit_log_service_stub.dart';
import 'api_config.dart';
import '../models/user_model.dart';

/// Service to manage survey configuration settings
/// These settings control which sections are shown in the survey flow
/// Configuration is stored in centralized backend (Firestore) for global consistency
class SurveyConfigService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
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
  bool _isSaving = false;
  String? _error;

  // Getters
  bool get ccEnabled => _ccEnabled;
  bool get sqdEnabled => _sqdEnabled;
  bool get demographicsEnabled => _demographicsEnabled;
  bool get suggestionsEnabled => _suggestionsEnabled;
  bool get kioskMode => _kioskMode;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  String? get error => _error;

  /// Load configuration from centralized backend
  Future<void> loadConfig() async {
    try {
      _error = null;
      final response = await _apiClient.get('/survey-config');
      
      if (response.isSuccess && response.data != null) {
        _ccEnabled = response.data!['ccEnabled'] ?? true;
        _sqdEnabled = response.data!['sqdEnabled'] ?? true;
        _demographicsEnabled = response.data!['demographicsEnabled'] ?? true;
        _suggestionsEnabled = response.data!['suggestionsEnabled'] ?? true;
        _kioskMode = response.data!['kioskMode'] ?? false;
        
        debugPrint('SurveyConfigService: Configuration loaded from backend');
      } else {
        _error = response.error;
        debugPrint('SurveyConfigService: Error loading config from backend: ${response.error}');
        // Use defaults on error
      }
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('SurveyConfigService: Error loading config: $e');
      _error = e.toString();
      _isLoaded = true; // Mark as loaded even on error, use defaults
      notifyListeners();
    }
  }

  /// Save all configuration to centralized backend
  Future<bool> _saveConfigToBackend() async {
    try {
      _isSaving = true;
      notifyListeners();
      
      final response = await _apiClient.put('/survey-config', body: {
        'ccEnabled': _ccEnabled,
        'sqdEnabled': _sqdEnabled,
        'demographicsEnabled': _demographicsEnabled,
        'suggestionsEnabled': _suggestionsEnabled,
        'kioskMode': _kioskMode,
      });
      
      _isSaving = false;
      
      if (response.isSuccess) {
        _error = null;
        debugPrint('SurveyConfigService: Configuration saved to backend');
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('SurveyConfigService: Error saving config: ${response.error}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSaving = false;
      _error = e.toString();
      debugPrint('SurveyConfigService: Error saving config: $e');
      notifyListeners();
      return false;
    }
  }

  // Setters with persistence to centralized backend and audit logging
  Future<void> setCcEnabled(bool value) async {
    final previousValue = _ccEnabled;
    _ccEnabled = value;
    notifyListeners();
    await _saveConfigToBackend();
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
    await _saveConfigToBackend();
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
    await _saveConfigToBackend();
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
    await _saveConfigToBackend();
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
    await _saveConfigToBackend();
    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'Kiosk Mode',
      previousValue: previousValue,
      newValue: value,
    );
  }
  
  /// Reload configuration from backend (useful for syncing across platforms)
  Future<void> refreshConfig() async {
    await loadConfig();
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
  
  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}

enum SurveyStep { profile, citizenCharter, sqd, suggestions }