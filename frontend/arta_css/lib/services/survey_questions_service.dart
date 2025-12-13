import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'audit_log_service.dart';
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
class SurveyQuestionsService extends ChangeNotifier {
  static const String _keyCcQuestions = 'survey_cc_questions';
  static const String _keySqdQuestions = 'survey_sqd_questions';

  // Audit log service reference
  AuditLogService? _auditLogService;
  UserModel? _currentActor;
  
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Set the audit log service for logging changes
  void setAuditService(AuditLogService auditService, UserModel? currentUser) {
    _auditLogService = auditService;
    _currentActor = currentUser;
  }

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

  // Getters
  List<SurveyQuestion> get ccQuestions => _ccQuestions;
  List<SurveyQuestion> get sqdQuestions => _sqdQuestions;

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

  /// Load questions from SharedPreferences
  Future<void> loadQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load CC questions
      final ccJson = prefs.getString(_keyCcQuestions);
      if (ccJson != null) {
        final List<dynamic> ccList = jsonDecode(ccJson);
        _ccQuestions = ccList.map((e) => SurveyQuestion.fromJson(e)).toList();
      } else {
        _ccQuestions = defaultCcQuestions.map((q) => q.copyWith()).toList();
      }

      // Load SQD questions
      final sqdJson = prefs.getString(_keySqdQuestions);
      if (sqdJson != null) {
        final List<dynamic> sqdList = jsonDecode(sqdJson);
        _sqdQuestions = sqdList.map((e) => SurveyQuestion.fromJson(e)).toList();
      } else {
        _sqdQuestions = defaultSqdQuestions.map((q) => q.copyWith()).toList();
      }

      _isLoaded = true;
      notifyListeners();
      debugPrint('SurveyQuestionsService: Questions loaded');
    } catch (e) {
      debugPrint('SurveyQuestionsService: Error loading questions: $e');
      // Use defaults on error
      _ccQuestions = defaultCcQuestions.map((q) => q.copyWith()).toList();
      _sqdQuestions = defaultSqdQuestions.map((q) => q.copyWith()).toList();
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Save CC questions to SharedPreferences
  Future<void> _saveCcQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_ccQuestions.map((q) => q.toJson()).toList());
      await prefs.setString(_keyCcQuestions, jsonStr);
      debugPrint('SurveyQuestionsService: CC questions saved');
    } catch (e) {
      debugPrint('SurveyQuestionsService: Error saving CC questions: $e');
    }
  }

  /// Save SQD questions to SharedPreferences
  Future<void> _saveSqdQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_sqdQuestions.map((q) => q.toJson()).toList());
      await prefs.setString(_keySqdQuestions, jsonStr);
      debugPrint('SurveyQuestionsService: SQD questions saved');
    } catch (e) {
      debugPrint('SurveyQuestionsService: Error saving SQD questions: $e');
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

  /// Reset all questions to defaults
  Future<void> resetToDefaults() async {
    _ccQuestions = defaultCcQuestions.map((q) => q.copyWith()).toList();
    _sqdQuestions = defaultSqdQuestions.map((q) => q.copyWith()).toList();

    notifyListeners();
    await _saveCcQuestions();
    await _saveSqdQuestions();

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
  }
}
