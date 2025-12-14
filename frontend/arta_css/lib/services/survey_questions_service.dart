import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'audit_log_service_stub.dart';
import 'api_config.dart';
import '../models/user_model.dart';

/// Model for a single survey question
class SurveyQuestion {
  final String id;
  final String label;
  String question;
  List<String> options;

  SurveyQuestion({
    required this.id,
    required this.label,
    required this.question,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'question': question,
    'options': options,
  };

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) => SurveyQuestion(
    id: json['id'] as String,
    label: json['label'] as String,
    question: json['question'] as String,
    options: List<String>.from(json['options'] as List),
  );

  SurveyQuestion copyWith({
    String? id,
    String? label,
    String? question,
    List<String>? options,
  }) => SurveyQuestion(
    id: id ?? this.id,
    label: label ?? this.label,
    question: question ?? this.question,
    options: options ?? List.from(this.options),
  );
}

/// Service to manage customizable survey questions
/// Allows admin to edit CC and SQD questions which reflect immediately on user side
/// Configuration is stored in centralized backend (Firestore) for global consistency across all platforms
class SurveyQuestionsService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  // Audit log service reference
  AuditLogService? _auditLogService;
  UserModel? _currentActor;
  
  bool _isLoaded = false;
  bool _isSaving = false;
  String? _error;
  
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  String? get error => _error;

  /// Set the audit log service for logging changes
  void setAuditService(AuditLogService auditService, UserModel? currentUser) {
    _auditLogService = auditService;
    _currentActor = currentUser;
  }

  // ========== DEFAULT CC CONFIG ==========
  static Map<String, dynamic> get defaultCcConfig => {
    'sectionTitle': 'CITIZEN\'S CHARTER',
  };

  // ========== DEFAULT SQD CONFIG ==========
  static Map<String, dynamic> get defaultSqdConfig => {
    'sectionTitle': 'SERVICE QUALITY DIMENSIONS',
  };

  // ========== DEFAULT USER PROFILE CONFIG ==========
  static Map<String, dynamic> get defaultProfileConfig => {
    'sectionTitle': 'CLIENT PROFILE',
    'clientTypeLabel': 'Client Type',
    'clientTypes': ['CITIZEN', 'BUSINESS', 'GOVERNMENT'],
    'dateLabel': 'Date of Transaction',
    'sexLabel': 'Sex',
    'sexOptions': ['MALE', 'FEMALE'],
    'ageLabel': 'Age',
    'agePlaceholder': 'Enter your age',
    'regionLabel': 'Region of Residence',
    'regions': [
      'NCR', 'CAR', 'Region I', 'Region II', 'Region III',
      'Region IV-A', 'Region IV-B', 'Region V', 'Region VI',
      'Region VII', 'Region VIII', 'Region IX', 'Region X',
      'Region XI', 'Region XII', 'Region XIII', 'BARMM',
    ],
    'serviceLabel': 'Service Availed',
    'services': [
      'Business Permit', 'Real Property Tax', 'Civil Registry',
      'Health Services', 'Building Official', 'Zoning',
      'Social Welfare', 'Garbage Collection', 'Traffic Management', 'Other',
    ],
  };

  // ========== DEFAULT SUGGESTIONS CONFIG ==========
  static Map<String, dynamic> get defaultSuggestionsConfig => {
    'sectionTitle': 'SUGGESTIONS',
    'suggestionsLabel': 'SUGGESTIONS',
    'suggestionsSubtitle': 'How can we further improve our services?',
    'suggestionsPlaceholder': 'Write your suggestions here...',
    'emailLabel': 'EMAIL ADDRESS',
    'emailSubtitle': 'Optional - for feedback replies',
    'emailPlaceholder': 'Enter your email address...',
    'thankYouTitle': 'THANK YOU',
    'thankYouMessage': 'FOR YOUR FEEDBACK!',
  };

  // Default CC Questions
  static List<SurveyQuestion> get defaultCcQuestions => [
    SurveyQuestion(
      id: 'CC1',
      label: 'CC1',
      question: 'Which of the following best describes your awareness of a CC?',
      options: [
        '1. I know what a CC is and I saw this office\'s CC.',
        '2. I know what a CC is but I did NOT see this office\'s CC.',
        '3. I learned of the CC only when I saw this office\'s CC.',
        '4. I do not know what a CC is and I did not see one in this office.',
      ],
    ),
    SurveyQuestion(
      id: 'CC2',
      label: 'CC2',
      question: 'If aware of CC (answered 1-3 in CC1), would you say that the CC of this office was ...?',
      options: [
        '1. Easy to see',
        '2. Somewhat easy to see',
        '3. Difficult to see',
        '4. Not visible at all',
        '5. Not Applicable',
      ],
    ),
    SurveyQuestion(
      id: 'CC3',
      label: 'CC3',
      question: 'If aware of CC (answered codes 1-3 in CC1), how much did the CC help you in your transaction?',
      options: [
        '1. Helped very much',
        '2. Somewhat helped',
        '3. Did not help',
        '4. Not Applicable',
      ],
    ),
  ];

  // Default SQD Questions
  static List<SurveyQuestion> get defaultSqdQuestions => [
    SurveyQuestion(
      id: 'SQD0',
      label: 'SQD 0',
      question: 'I am satisfied with the service that I availed.',
      options: [], // SQD uses Likert scale, not custom options
    ),
    SurveyQuestion(
      id: 'SQD1',
      label: 'SQD 1',
      question: 'I spent a reasonable amount of time for my transaction.',
      options: [],
    ),
    SurveyQuestion(
      id: 'SQD2',
      label: 'SQD 2',
      question: 'The office followed the transaction\'s requirements and steps based on the information provided.',
      options: [],
    ),
    SurveyQuestion(
      id: 'SQD3',
      label: 'SQD 3',
      question: 'The steps (including payment) I needed to do for my transaction were easy and simple.',
      options: [],
    ),
    SurveyQuestion(
      id: 'SQD4',
      label: 'SQD 4',
      question: 'I easily found information about my transaction from the office or its website.',
      options: [],
    ),
    SurveyQuestion(
      id: 'SQD5',
      label: 'SQD 5',
      question: 'I paid a reasonable amount of fees for my transaction. (If service was free, mark the \'N/A\' column)',
      options: [],
    ),
    SurveyQuestion(
      id: 'SQD6',
      label: 'SQD 6',
      question: 'I feel the office was fair to everyone, or \'walang palakasan\', during my transaction.',
      options: [],
    ),
    SurveyQuestion(
      id: 'SQD7',
      label: 'SQD 7',
      question: 'I was treated courteously by the staff, and (if asked for help) the staff was helpful.',
      options: [],
    ),
    SurveyQuestion(
      id: 'SQD8',
      label: 'SQD 8',
      question: 'I got what I needed from the government office, or (if denied) denial of request was sufficiently explained to me.',
      options: [],
    ),
  ];

  // Current questions (mutable)
  List<SurveyQuestion> _ccQuestions = [];
  List<SurveyQuestion> _sqdQuestions = [];
  Map<String, dynamic> _ccConfig = {};
  Map<String, dynamic> _sqdConfig = {};

  Map<String, dynamic> _profileConfig = {};
  Map<String, dynamic> _suggestionsConfig = {};

  // Getters
  List<SurveyQuestion> get ccQuestions => _ccQuestions;
  List<SurveyQuestion> get sqdQuestions => _sqdQuestions;
  Map<String, dynamic> get ccConfig => _ccConfig;
  Map<String, dynamic> get sqdConfig => _sqdConfig;
  Map<String, dynamic> get profileConfig => _profileConfig;
  Map<String, dynamic> get suggestionsConfig => _suggestionsConfig;

  // CC config convenience getters
  String get ccSectionTitle => _ccConfig['sectionTitle'] ?? defaultCcConfig['sectionTitle'];

  // SQD config convenience getters
  String get sqdSectionTitle => _sqdConfig['sectionTitle'] ?? defaultSqdConfig['sectionTitle'];

  // Profile config convenience getters
  String get profileSectionTitle => _profileConfig['sectionTitle'] ?? defaultProfileConfig['sectionTitle'];
  String get clientTypeLabel => _profileConfig['clientTypeLabel'] ?? defaultProfileConfig['clientTypeLabel'];
  List<String> get clientTypes => List<String>.from(_profileConfig['clientTypes'] ?? defaultProfileConfig['clientTypes']);
  String get dateLabel => _profileConfig['dateLabel'] ?? defaultProfileConfig['dateLabel'];
  String get sexLabel => _profileConfig['sexLabel'] ?? defaultProfileConfig['sexLabel'];
  List<String> get sexOptions => List<String>.from(_profileConfig['sexOptions'] ?? defaultProfileConfig['sexOptions']);
  String get ageLabel => _profileConfig['ageLabel'] ?? defaultProfileConfig['ageLabel'];
  String get agePlaceholder => _profileConfig['agePlaceholder'] ?? defaultProfileConfig['agePlaceholder'];
  String get regionLabel => _profileConfig['regionLabel'] ?? defaultProfileConfig['regionLabel'];
  List<String> get regions => List<String>.from(_profileConfig['regions'] ?? defaultProfileConfig['regions']);
  String get serviceLabel => _profileConfig['serviceLabel'] ?? defaultProfileConfig['serviceLabel'];
  List<String> get services => List<String>.from(_profileConfig['services'] ?? defaultProfileConfig['services']);

  // Suggestions config convenience getters
  String get suggestionsSectionTitle => _suggestionsConfig['sectionTitle'] ?? defaultSuggestionsConfig['sectionTitle'];
  String get suggestionsLabel => _suggestionsConfig['suggestionsLabel'] ?? defaultSuggestionsConfig['suggestionsLabel'];
  String get suggestionsSubtitle => _suggestionsConfig['suggestionsSubtitle'] ?? defaultSuggestionsConfig['suggestionsSubtitle'];
  String get suggestionsPlaceholder => _suggestionsConfig['suggestionsPlaceholder'] ?? defaultSuggestionsConfig['suggestionsPlaceholder'];
  String get emailLabel => _suggestionsConfig['emailLabel'] ?? defaultSuggestionsConfig['emailLabel'];
  String get emailSubtitle => _suggestionsConfig['emailSubtitle'] ?? defaultSuggestionsConfig['emailSubtitle'];
  String get emailPlaceholder => _suggestionsConfig['emailPlaceholder'] ?? defaultSuggestionsConfig['emailPlaceholder'];
  String get thankYouTitle => _suggestionsConfig['thankYouTitle'] ?? defaultSuggestionsConfig['thankYouTitle'];
  String get thankYouMessage => _suggestionsConfig['thankYouMessage'] ?? defaultSuggestionsConfig['thankYouMessage'];

  /// Get a specific CC question by ID
  SurveyQuestion? getCcQuestion(String id) {
    try {
      return _ccQuestions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a specific SQD question by index
  SurveyQuestion? getSqdQuestion(int index) {
    if (index >= 0 && index < _sqdQuestions.length) {
      return _sqdQuestions[index];
    }
    return null;
  }

  /// Load questions from centralized backend
  Future<void> loadQuestions() async {
    try {
      _error = null;
      final response = await _apiClient.get('/survey-questions');
      
      if (response.isSuccess && response.data != null) {
        // Load CC questions
        final ccData = response.data!['ccQuestions'];
        if (ccData != null) {
          final List<dynamic> ccList = ccData is String ? jsonDecode(ccData) : ccData;
          _ccQuestions = ccList.map((e) => SurveyQuestion.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          _ccQuestions = defaultCcQuestions.map((q) => q.copyWith()).toList();
        }

        // Load SQD questions
        final sqdData = response.data!['sqdQuestions'];
        if (sqdData != null) {
          final List<dynamic> sqdList = sqdData is String ? jsonDecode(sqdData) : sqdData;
          _sqdQuestions = sqdList.map((e) => SurveyQuestion.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          _sqdQuestions = defaultSqdQuestions.map((q) => q.copyWith()).toList();
        }

        // Load Profile config
        final profileData = response.data!['profileConfig'];
        if (profileData != null) {
          _profileConfig = Map<String, dynamic>.from(profileData is String ? jsonDecode(profileData) : profileData);
        } else {
          _profileConfig = Map<String, dynamic>.from(defaultProfileConfig);
        }

        // Load Suggestions config
        final suggestionsData = response.data!['suggestionsConfig'];
        if (suggestionsData != null) {
          _suggestionsConfig = Map<String, dynamic>.from(suggestionsData is String ? jsonDecode(suggestionsData) : suggestionsData);
        } else {
          _suggestionsConfig = Map<String, dynamic>.from(defaultSuggestionsConfig);
        }

        // Load CC config
        final ccConfigData = response.data!['ccConfig'];
        if (ccConfigData != null) {
          _ccConfig = Map<String, dynamic>.from(ccConfigData is String ? jsonDecode(ccConfigData) : ccConfigData);
        } else {
          _ccConfig = Map<String, dynamic>.from(defaultCcConfig);
        }

        // Load SQD config
        final sqdConfigData = response.data!['sqdConfig'];
        if (sqdConfigData != null) {
          _sqdConfig = Map<String, dynamic>.from(sqdConfigData is String ? jsonDecode(sqdConfigData) : sqdConfigData);
        } else {
          _sqdConfig = Map<String, dynamic>.from(defaultSqdConfig);
        }

        debugPrint('SurveyQuestionsService: Questions loaded from backend');
      } else {
        _error = response.error;
        debugPrint('SurveyQuestionsService: Error loading from backend: ${response.error}');
        // Use defaults on error
        _useDefaults();
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('SurveyQuestionsService: Error loading questions: $e');
      _error = e.toString();
      _useDefaults();
      _isLoaded = true;
      notifyListeners();
    }
  }
  
  /// Use default values for all config
  void _useDefaults() {
    _ccQuestions = defaultCcQuestions.map((q) => q.copyWith()).toList();
    _sqdQuestions = defaultSqdQuestions.map((q) => q.copyWith()).toList();
    _profileConfig = Map<String, dynamic>.from(defaultProfileConfig);
    _suggestionsConfig = Map<String, dynamic>.from(defaultSuggestionsConfig);
    _ccConfig = Map<String, dynamic>.from(defaultCcConfig);
    _sqdConfig = Map<String, dynamic>.from(defaultSqdConfig);
  }
  
  /// Refresh questions from backend
  Future<void> refreshQuestions() async {
    await loadQuestions();
  }

  /// Save CC questions to centralized backend
  Future<bool> _saveCcQuestions() async {
    try {
      _isSaving = true;
      notifyListeners();
      
      final response = await _apiClient.put('/survey-questions/cc', body: {
        'questions': _ccQuestions.map((q) => q.toJson()).toList(),
      });
      
      _isSaving = false;
      
      if (response.isSuccess) {
        _error = null;
        debugPrint('SurveyQuestionsService: CC questions saved to backend');
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('SurveyQuestionsService: Error saving CC questions: ${response.error}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSaving = false;
      _error = e.toString();
      debugPrint('SurveyQuestionsService: Error saving CC questions: $e');
      notifyListeners();
      return false;
    }
  }

  /// Save SQD questions to centralized backend
  Future<bool> _saveSqdQuestions() async {
    try {
      _isSaving = true;
      notifyListeners();
      
      final response = await _apiClient.put('/survey-questions/sqd', body: {
        'questions': _sqdQuestions.map((q) => q.toJson()).toList(),
      });
      
      _isSaving = false;
      
      if (response.isSuccess) {
        _error = null;
        debugPrint('SurveyQuestionsService: SQD questions saved to backend');
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('SurveyQuestionsService: Error saving SQD questions: ${response.error}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSaving = false;
      _error = e.toString();
      debugPrint('SurveyQuestionsService: Error saving SQD questions: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update a CC question
  Future<void> updateCcQuestion(String id, {String? question, List<String>? options}) async {
    final index = _ccQuestions.indexWhere((q) => q.id == id);
    if (index == -1) return;

    final oldQuestion = _ccQuestions[index];
    final previousText = oldQuestion.question;

    if (question != null) {
      _ccQuestions[index].question = question;
    }
    if (options != null) {
      _ccQuestions[index].options = options;
    }

    notifyListeners();
    await _saveCcQuestions();

    // Log the change
    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'CC Question: ${oldQuestion.label}',
      previousValue: previousText,
      newValue: question ?? previousText,
    );
  }

  /// Save CC config to centralized backend
  Future<bool> _saveCcConfig() async {
    try {
      _isSaving = true;
      notifyListeners();
      
      final response = await _apiClient.put('/survey-questions/cc', body: {
        'config': _ccConfig,
      });
      
      _isSaving = false;
      
      if (response.isSuccess) {
        _error = null;
        debugPrint('SurveyQuestionsService: CC config saved to backend');
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('SurveyQuestionsService: Error saving CC config: ${response.error}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSaving = false;
      _error = e.toString();
      debugPrint('SurveyQuestionsService: Error saving CC config: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update CC Section Title
  Future<void> updateCcSectionTitle(String title) async {
    final previousValue = ccSectionTitle;
    _ccConfig['sectionTitle'] = title;
    notifyListeners();
    await _saveCcConfig();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'CC Section Title',
      previousValue: previousValue,
      newValue: title,
    );
  }

  /// Update a CC question option
  Future<void> updateCcQuestionOption(String questionId, int optionIndex, String newOption) async {
    final qIndex = _ccQuestions.indexWhere((q) => q.id == questionId);
    if (qIndex == -1) return;

    final question = _ccQuestions[qIndex];
    if (optionIndex < 0 || optionIndex >= question.options.length) return;

    final previousOption = question.options[optionIndex];
    question.options[optionIndex] = newOption;

    notifyListeners();
    await _saveCcQuestions();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: '${question.label} Option ${optionIndex + 1}',
      previousValue: previousOption,
      newValue: newOption,
    );
  }

  /// Update an SQD question
  Future<void> updateSqdQuestion(int index, {String? question}) async {
    if (index < 0 || index >= _sqdQuestions.length) return;

    final oldQuestion = _sqdQuestions[index];
    final previousText = oldQuestion.question;

    if (question != null) {
      _sqdQuestions[index].question = question;
    }

    notifyListeners();
    await _saveSqdQuestions();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'SQD Question: ${oldQuestion.label}',
      previousValue: previousText,
      newValue: question ?? previousText,
    );
  }

  /// Save SQD config to centralized backend
  Future<bool> _saveSqdConfig() async {
    try {
      _isSaving = true;
      notifyListeners();
      
      final response = await _apiClient.put('/survey-questions/sqd', body: {
        'config': _sqdConfig,
      });
      
      _isSaving = false;
      
      if (response.isSuccess) {
        _error = null;
        debugPrint('SurveyQuestionsService: SQD config saved to backend');
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('SurveyQuestionsService: Error saving SQD config: ${response.error}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSaving = false;
      _error = e.toString();
      debugPrint('SurveyQuestionsService: Error saving SQD config: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update SQD Section Title
  Future<void> updateSqdSectionTitle(String title) async {
    final previousValue = sqdSectionTitle;
    _sqdConfig['sectionTitle'] = title;
    notifyListeners();
    await _saveSqdConfig();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'SQD Section Title',
      previousValue: previousValue,
      newValue: title,
    );
  }

  /// Reset all questions to defaults
  Future<void> resetToDefaults() async {
    _ccQuestions = defaultCcQuestions.map((q) => q.copyWith()).toList();
    _sqdQuestions = defaultSqdQuestions.map((q) => q.copyWith()).toList();

    notifyListeners();
    await _saveCcQuestions();
    await _saveSqdQuestions();

    // Reset config too
    _ccConfig = Map<String, dynamic>.from(defaultCcConfig);
    _sqdConfig = Map<String, dynamic>.from(defaultSqdConfig);
    await _saveCcConfig();
    await _saveSqdConfig();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'All Survey Questions',
      previousValue: 'Custom',
      newValue: 'Reset to Defaults',
    );
  }

  /// Reset only CC questions to defaults
  Future<void> resetCcToDefaults() async {
    _ccQuestions = defaultCcQuestions.map((q) => q.copyWith()).toList();
    notifyListeners();
    await _saveCcQuestions();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'CC Questions',
      previousValue: 'Custom',
      newValue: 'Reset to Defaults',
    );
    
    // Reset CC config too
    _ccConfig = Map<String, dynamic>.from(defaultCcConfig);
    await _saveCcConfig();
  }

  /// Reset only SQD questions to defaults
  Future<void> resetSqdToDefaults() async {
    _sqdQuestions = defaultSqdQuestions.map((q) => q.copyWith()).toList();
    notifyListeners();
    await _saveSqdQuestions();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'SQD Questions',
      previousValue: 'Custom',
      newValue: 'Reset to Defaults',
    );

    // Reset SQD config too
    _sqdConfig = Map<String, dynamic>.from(defaultSqdConfig);
    await _saveSqdConfig();
  }

  // ========== PROFILE CONFIG METHODS ==========

  /// Save profile config to centralized backend
  Future<bool> _saveProfileConfig() async {
    try {
      _isSaving = true;
      notifyListeners();
      
      final response = await _apiClient.put('/survey-questions/profile', body: {
        'config': _profileConfig,
      });
      
      _isSaving = false;
      
      if (response.isSuccess) {
        _error = null;
        debugPrint('SurveyQuestionsService: Profile config saved to backend');
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('SurveyQuestionsService: Error saving profile config: ${response.error}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSaving = false;
      _error = e.toString();
      debugPrint('SurveyQuestionsService: Error saving profile config: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update a profile config value
  Future<void> updateProfileConfig(String key, dynamic value) async {
    final previousValue = _profileConfig[key];
    _profileConfig[key] = value;
    notifyListeners();
    await _saveProfileConfig();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'Profile: $key',
      previousValue: previousValue?.toString() ?? 'null',
      newValue: value?.toString() ?? 'null',
    );
  }

  /// Add an option to a profile list (e.g., regions, services)
  Future<void> addProfileListOption(String listKey, String option) async {
    final list = List<String>.from(_profileConfig[listKey] ?? []);
    if (!list.contains(option)) {
      list.add(option);
      _profileConfig[listKey] = list;
      notifyListeners();
      await _saveProfileConfig();

      await _auditLogService?.logSurveyConfigChanged(
        actor: _currentActor,
        configKey: 'Profile $listKey',
        previousValue: 'Added',
        newValue: option,
      );
    }
  }

  /// Remove an option from a profile list
  Future<void> removeProfileListOption(String listKey, int index) async {
    final list = List<String>.from(_profileConfig[listKey] ?? []);
    if (index >= 0 && index < list.length) {
      final removed = list.removeAt(index);
      _profileConfig[listKey] = list;
      notifyListeners();
      await _saveProfileConfig();

      await _auditLogService?.logSurveyConfigChanged(
        actor: _currentActor,
        configKey: 'Profile $listKey',
        previousValue: removed,
        newValue: 'Removed',
      );
    }
  }

  /// Update an option in a profile list
  Future<void> updateProfileListOption(String listKey, int index, String newValue) async {
    final list = List<String>.from(_profileConfig[listKey] ?? []);
    if (index >= 0 && index < list.length) {
      final previous = list[index];
      list[index] = newValue;
      _profileConfig[listKey] = list;
      notifyListeners();
      await _saveProfileConfig();

      await _auditLogService?.logSurveyConfigChanged(
        actor: _currentActor,
        configKey: 'Profile $listKey Option',
        previousValue: previous,
        newValue: newValue,
      );
    }
  }

  /// Reset profile config to defaults
  Future<void> resetProfileToDefaults() async {
    _profileConfig = Map<String, dynamic>.from(defaultProfileConfig);
    notifyListeners();
    await _saveProfileConfig();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'Profile Config',
      previousValue: 'Custom',
      newValue: 'Reset to Defaults',
    );
  }

  // ========== SUGGESTIONS CONFIG METHODS ==========

  /// Save suggestions config to centralized backend
  Future<bool> _saveSuggestionsConfig() async {
    try {
      _isSaving = true;
      notifyListeners();
      
      final response = await _apiClient.put('/survey-questions/suggestions', body: {
        'config': _suggestionsConfig,
      });
      
      _isSaving = false;
      
      if (response.isSuccess) {
        _error = null;
        debugPrint('SurveyQuestionsService: Suggestions config saved to backend');
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('SurveyQuestionsService: Error saving suggestions config: ${response.error}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSaving = false;
      _error = e.toString();
      debugPrint('SurveyQuestionsService: Error saving suggestions config: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update a suggestions config value
  Future<void> updateSuggestionsConfig(String key, dynamic value) async {
    final previousValue = _suggestionsConfig[key];
    _suggestionsConfig[key] = value;
    notifyListeners();
    await _saveSuggestionsConfig();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'Suggestions: $key',
      previousValue: previousValue?.toString() ?? 'null',
      newValue: value?.toString() ?? 'null',
    );
  }

  /// Reset suggestions config to defaults
  Future<void> resetSuggestionsToDefaults() async {
    _suggestionsConfig = Map<String, dynamic>.from(defaultSuggestionsConfig);
    notifyListeners();
    await _saveSuggestionsConfig();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'Suggestions Config',
      previousValue: 'Custom',
      newValue: 'Reset to Defaults',
    );
  }

  /// Reset all configurations to defaults
  Future<void> resetAllToDefaults() async {
    _ccQuestions = defaultCcQuestions.map((q) => q.copyWith()).toList();
    _sqdQuestions = defaultSqdQuestions.map((q) => q.copyWith()).toList();
    _profileConfig = Map<String, dynamic>.from(defaultProfileConfig);
    _suggestionsConfig = Map<String, dynamic>.from(defaultSuggestionsConfig);

    notifyListeners();
    
    // Save all to backend
    await _saveAllToBackend();

    // Reset other configs
    _ccConfig = Map<String, dynamic>.from(defaultCcConfig);
    _sqdConfig = Map<String, dynamic>.from(defaultSqdConfig);
    await _saveCcConfig();
    await _saveSqdConfig();

    await _auditLogService?.logSurveyConfigChanged(
      actor: _currentActor,
      configKey: 'All Survey Configuration',
      previousValue: 'Custom',
      newValue: 'Reset to Defaults',
    );
  }
  
  /// Save all questions and configs to backend at once
  Future<bool> _saveAllToBackend() async {
    try {
      _isSaving = true;
      notifyListeners();
      
      final response = await _apiClient.put('/survey-questions', body: {
        'ccQuestions': _ccQuestions.map((q) => q.toJson()).toList(),
        'sqdQuestions': _sqdQuestions.map((q) => q.toJson()).toList(),
        'ccConfig': _ccConfig,
        'sqdConfig': _sqdConfig,
        'profileConfig': _profileConfig,
        'suggestionsConfig': _suggestionsConfig,
      });
      
      _isSaving = false;
      
      if (response.isSuccess) {
        _error = null;
        debugPrint('SurveyQuestionsService: All data saved to backend');
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('SurveyQuestionsService: Error saving all data: ${response.error}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSaving = false;
      _error = e.toString();
      debugPrint('SurveyQuestionsService: Error saving all data: $e');
      notifyListeners();
      return false;
    }
  }
  
  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}
