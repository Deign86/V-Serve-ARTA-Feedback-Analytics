import 'package:flutter/foundation.dart';
import '../models/survey_data.dart';

/// Provider to handle the current survey session state across all screens
class SurveyProvider extends ChangeNotifier {
  // Use static to ensure persistence across any potential provider recreation
  static SurveyData _surveyData = SurveyData();

  SurveyData get surveyData => _surveyData;

  /// Update Part 1: User Profile
  void updateProfile({
    required String clientType,
    required DateTime? date,
    required String? sex,
    required int? age,
    required String? region,
    required String? serviceAvailed,
  }) {
    _surveyData = _surveyData.copyWith(
      clientType: clientType,
      date: date,
      sex: sex,
      age: age,
      regionOfResidence: region,
      serviceAvailed: serviceAvailed,
    );
    notifyListeners();
  }

  /// Update Part 2: Citizen Charter
  void updateCC({
    required int? cc0,
    required int? cc1,
    required int? cc2,
  }) {
    print("DEBUG: updateCC called with cc0=$cc0, cc1=$cc1, cc2=$cc2");
    _surveyData = _surveyData.copyWith(
      cc0Rating: cc0,
      cc1Rating: cc1,
      cc2Rating: cc2,
    );
    print("DEBUG: _surveyData updated. cc0Rating is now ${_surveyData.cc0Rating}");
    notifyListeners();
  }

  /// Update Part 3: SQD
  void updateSQD({
    required int? sqd0,
    required int? sqd1,
    required int? sqd2,
    required int? sqd3,
    required int? sqd4,
    required int? sqd5,
    required int? sqd6,
    required int? sqd7,
    required int? sqd8,
  }) {
    _surveyData = _surveyData.copyWith(
      sqd0Rating: sqd0,
      sqd1Rating: sqd1,
      sqd2Rating: sqd2,
      sqd3Rating: sqd3,
      sqd4Rating: sqd4,
      sqd5Rating: sqd5,
      sqd6Rating: sqd6,
      sqd7Rating: sqd7,
      sqd8Rating: sqd8,
    );
    notifyListeners();
  }

  /// Update Part 4: Suggestions
  void updateSuggestions({
    required String? suggestions,
    required String? email,
  }) {
    _surveyData = _surveyData.copyWith(
      suggestions: suggestions,
      email: email,
    );
    notifyListeners();
  }

  /// Reset the survey to initial state (for new survey)
  void resetSurvey() {
    _surveyData = SurveyData();
    notifyListeners();
  }
}
