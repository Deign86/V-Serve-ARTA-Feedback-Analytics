import 'package:cloud_firestore/cloud_firestore.dart';

/// Model to hold complete survey response data across all parts
class SurveyData {
  // Document ID from Firestore
  String? id;
  
  // Part 1: User Profile
  String? clientType;
  DateTime? date;
  String? sex;
  int? age;
  String? regionOfResidence;
  String? serviceAvailed;
  
  // Metadata
  DateTime? submittedAt;

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
    this.id,
    this.clientType,
    this.date,
    this.sex,
    this.age,
    this.regionOfResidence,
    this.serviceAvailed,
    this.submittedAt,
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
      // ID (if available)
      if (id != null) 'id': id,
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
      'submittedAt': submittedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// Helper to safely parse int from dynamic
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper to safely parse DateTime from dynamic
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Handle Firestore Timestamp object
    if (value is Timestamp) {
      return value.toDate();
    }
    // Handle Firestore Timestamp as Map (from JSON serialization)
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    return null;
  }

  /// Create from JSON (for potential future retrieval)
  factory SurveyData.fromJson(Map<String, dynamic> json) {
    return SurveyData(
      id: json['id'] as String?,
      clientType: json['clientType'] as String?,
      date: _parseDateTime(json['date']),
      sex: json['sex'] as String?,
      age: _parseInt(json['age']),
      regionOfResidence: json['region'] as String?, // Firestore stores as 'region'
      serviceAvailed: json['serviceAvailed'] as String?,
      submittedAt: _parseDateTime(json['submittedAt']),
      cc0Rating: _parseInt(json['cc0Rating']),
      cc1Rating: _parseInt(json['cc1Rating']),
      cc2Rating: _parseInt(json['cc2Rating']),
      cc3Rating: _parseInt(json['cc3Rating']),
      sqd0Rating: _parseInt(json['sqd0Rating']),
      sqd1Rating: _parseInt(json['sqd1Rating']),
      sqd2Rating: _parseInt(json['sqd2Rating']),
      sqd3Rating: _parseInt(json['sqd3Rating']),
      sqd4Rating: _parseInt(json['sqd4Rating']),
      sqd5Rating: _parseInt(json['sqd5Rating']),
      sqd6Rating: _parseInt(json['sqd6Rating']),
      sqd7Rating: _parseInt(json['sqd7Rating']),
      sqd8Rating: _parseInt(json['sqd8Rating']),
      suggestions: json['suggestions'] as String?,
      email: json['email'] as String?,
    );
  }

  /// Create a copy with updated fields
  SurveyData copyWith({
    String? id,
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
