/// Model to hold complete survey response data across all parts
class SurveyData {
  // Part 1: User Profile
  String? clientType;
  DateTime? date;
  String? sex;
  int? age;
  String? regionOfResidence;
  String? serviceAvailed;

  // Part 2: Citizen Charter (CC0-CC3)
  int? cc0Rating; // Awareness rating
  int? cc1Rating; // Easy to see rating
  int? cc2Rating; // Adequately posted rating
  int? cc3Rating; // Helped understand rating

  // Part 3: Service Quality Dimensions (SQD0-SQD8)
  int? sqd0Rating; // Spent reasonable time
  int? sqd1Rating; // Office followed steps
  int? sqd2Rating; // Steps easy and simple
  int? sqd3Rating; // Info easily found
  int? sqd4Rating; // Paid reasonable fees
  int? sqd5Rating; // Fees clearly displayed
  int? sqd6Rating; // Same fees for all
  int? sqd7Rating; // Reasonable processing time
  int? sqd8Rating; // Easy to get in/out

  // Part 4: Suggestions and feedback
  String? suggestions;
  String? email;

  SurveyData({
    this.clientType,
    this.date,
    this.sex,
    this.age,
    this.regionOfResidence,
    this.serviceAvailed,
    this.cc0Rating,
    this.cc1Rating,
    this.cc2Rating,
    this.cc3Rating,
    this.sqd0Rating,
    this.sqd1Rating,
    this.sqd2Rating,
    this.sqd3Rating,
    this.sqd4Rating,
    this.sqd5Rating,
    this.sqd6Rating,
    this.sqd7Rating,
    this.sqd8Rating,
    this.suggestions,
    this.email,
  });

  /// Convert to JSON for submission to backend/Firestore
  Map<String, dynamic> toJson() {
    return {
      // Part 1
      'clientType': clientType,
      'date': date?.toIso8601String(),
      'sex': sex,
      'age': age,
      'region': regionOfResidence, // Firestore rules expect 'region'
      'serviceAvailed': serviceAvailed,
      // Part 2
      'cc0Rating': cc0Rating,
      'cc1Rating': cc1Rating,
      'cc2Rating': cc2Rating,
      'cc3Rating': cc3Rating,
      // Part 3
      'sqd0Rating': sqd0Rating,
      'sqd1Rating': sqd1Rating,
      'sqd2Rating': sqd2Rating,
      'sqd3Rating': sqd3Rating,
      'sqd4Rating': sqd4Rating,
      'sqd5Rating': sqd5Rating,
      'sqd6Rating': sqd6Rating,
      'sqd7Rating': sqd7Rating,
      'sqd8Rating': sqd8Rating,
      // Part 4
      'suggestions': suggestions,
      'email': email,
      // Metadata
      'submittedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Create from JSON (for potential future retrieval)
  factory SurveyData.fromJson(Map<String, dynamic> json) {
    return SurveyData(
      clientType: json['clientType'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      sex: json['sex'] as String?,
      age: json['age'] as int?,
      regionOfResidence: json['region'] as String?, // Firestore stores as 'region'
      serviceAvailed: json['serviceAvailed'] as String?,
      cc0Rating: json['cc0Rating'] as int?,
      cc1Rating: json['cc1Rating'] as int?,
      cc2Rating: json['cc2Rating'] as int?,
      cc3Rating: json['cc3Rating'] as int?,
      sqd0Rating: json['sqd0Rating'] as int?,
      sqd1Rating: json['sqd1Rating'] as int?,
      sqd2Rating: json['sqd2Rating'] as int?,
      sqd3Rating: json['sqd3Rating'] as int?,
      sqd4Rating: json['sqd4Rating'] as int?,
      sqd5Rating: json['sqd5Rating'] as int?,
      sqd6Rating: json['sqd6Rating'] as int?,
      sqd7Rating: json['sqd7Rating'] as int?,
      sqd8Rating: json['sqd8Rating'] as int?,
      suggestions: json['suggestions'] as String?,
      email: json['email'] as String?,
    );
  }

  /// Create a copy with updated fields
  SurveyData copyWith({
    String? clientType,
    DateTime? date,
    String? sex,
    int? age,
    String? regionOfResidence,
    String? serviceAvailed,
    int? cc0Rating,
    int? cc1Rating,
    int? cc2Rating,
    int? cc3Rating,
    int? sqd0Rating,
    int? sqd1Rating,
    int? sqd2Rating,
    int? sqd3Rating,
    int? sqd4Rating,
    int? sqd5Rating,
    int? sqd6Rating,
    int? sqd7Rating,
    int? sqd8Rating,
    String? suggestions,
    String? email,
  }) {
    return SurveyData(
      clientType: clientType ?? this.clientType,
      date: date ?? this.date,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      regionOfResidence: regionOfResidence ?? this.regionOfResidence,
      serviceAvailed: serviceAvailed ?? this.serviceAvailed,
      cc0Rating: cc0Rating ?? this.cc0Rating,
      cc1Rating: cc1Rating ?? this.cc1Rating,
      cc2Rating: cc2Rating ?? this.cc2Rating,
      cc3Rating: cc3Rating ?? this.cc3Rating,
      sqd0Rating: sqd0Rating ?? this.sqd0Rating,
      sqd1Rating: sqd1Rating ?? this.sqd1Rating,
      sqd2Rating: sqd2Rating ?? this.sqd2Rating,
      sqd3Rating: sqd3Rating ?? this.sqd3Rating,
      sqd4Rating: sqd4Rating ?? this.sqd4Rating,
      sqd5Rating: sqd5Rating ?? this.sqd5Rating,
      sqd6Rating: sqd6Rating ?? this.sqd6Rating,
      sqd7Rating: sqd7Rating ?? this.sqd7Rating,
      sqd8Rating: sqd8Rating ?? this.sqd8Rating,
      suggestions: suggestions ?? this.suggestions,
      email: email ?? this.email,
    );
  }
}
