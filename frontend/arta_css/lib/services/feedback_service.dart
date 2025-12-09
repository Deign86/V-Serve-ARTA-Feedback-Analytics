import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/survey_data.dart';

/// Service for fetching and aggregating feedback data from Firestore
class FeedbackService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cached data
  List<SurveyData> _feedbacks = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;
  
  // Dashboard statistics
  DashboardStats? _dashboardStats;
  
  // Real-time stream subscription
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _feedbackSubscription;
  bool _isListening = false;
  
  // Getters
  List<SurveyData> get feedbacks => _feedbacks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardStats? get dashboardStats => _dashboardStats;
  bool get isListening => _isListening;
  
  /// Fetch all feedbacks from Firestore
  Future<List<SurveyData>> fetchAllFeedbacks({bool forceRefresh = false}) async {
    // Return cached if available and not forcing refresh
    if (!forceRefresh && _feedbacks.isNotEmpty && _lastFetch != null) {
      final diff = DateTime.now().difference(_lastFetch!);
      if (diff.inMinutes < 5) {
        return _feedbacks;
      }
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('=== FETCHING FEEDBACKS FROM FIRESTORE ===');
      
      // First try with createdAt (used by OfflineQueue), fallback to no ordering
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection('feedbacks')
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // If index doesn't exist, fetch without ordering
        debugPrint('Falling back to unordered query: $e');
        snapshot = await _firestore
            .collection('feedbacks')
            .get();
      }
      
      debugPrint('Fetched ${snapshot.docs.length} feedback documents');
      
      _feedbacks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Use createdAt as submittedAt if submittedAt is missing
        if (data['submittedAt'] == null && data['createdAt'] != null) {
          data['submittedAt'] = data['createdAt'];
        }
        return SurveyData.fromJson(data);
      }).toList();
      
      // Sort locally by submittedAt or createdAt
      _feedbacks.sort((a, b) {
        final aDate = a.submittedAt ?? DateTime(1970);
        final bDate = b.submittedAt ?? DateTime(1970);
        return bDate.compareTo(aDate); // descending
      });
      
      _lastFetch = DateTime.now();
      _isLoading = false;
      notifyListeners();
      
      // Calculate stats after fetching
      _calculateDashboardStats();
      
      return _feedbacks;
    } catch (e) {
      debugPrint('Error fetching feedbacks: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
  
  /// Start listening to real-time updates from Firestore
  void startRealtimeUpdates() {
    if (_isListening) return; // Already listening
    
    debugPrint('=== STARTING REAL-TIME FEEDBACK LISTENER ===');
    _isListening = true;
    
    _feedbackSubscription = _firestore
        .collection('feedbacks')
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint('Real-time update: ${snapshot.docs.length} documents');
            
            _feedbacks = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              // Use createdAt as submittedAt if submittedAt is missing
              if (data['submittedAt'] == null && data['createdAt'] != null) {
                data['submittedAt'] = data['createdAt'];
              }
              return SurveyData.fromJson(data);
            }).toList();
            
            // Sort locally by submittedAt or createdAt
            _feedbacks.sort((a, b) {
              final aDate = a.submittedAt ?? DateTime(1970);
              final bDate = b.submittedAt ?? DateTime(1970);
              return bDate.compareTo(aDate); // descending
            });
            
            _lastFetch = DateTime.now();
            _isLoading = false;
            
            // Notify listeners immediately that feedbacks have updated
            // This ensures total count updates right away
            notifyListeners();
            
            // Recalculate stats (this also calls notifyListeners)
            _calculateDashboardStats();
            
            debugPrint('Dashboard stats updated - Total: ${_dashboardStats?.totalResponses}, Avg: ${_dashboardStats?.avgSatisfaction}');
          },
          onError: (error) {
            debugPrint('Real-time listener error: $error');
            _error = error.toString();
            notifyListeners();
          },
        );
  }
  
  /// Stop listening to real-time updates
  void stopRealtimeUpdates() {
    debugPrint('=== STOPPING REAL-TIME FEEDBACK LISTENER ===');
    _feedbackSubscription?.cancel();
    _feedbackSubscription = null;
    _isListening = false;
  }
  
  @override
  void dispose() {
    stopRealtimeUpdates();
    super.dispose();
  }
  
  /// Fetch feedbacks with date range filter
  Future<List<SurveyData>> fetchFeedbacksByDateRange(DateTime start, DateTime end) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('submittedAt', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('submittedAt', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('submittedAt', descending: true)
          .get();
      
      final feedbacks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SurveyData.fromJson(data);
      }).toList();
      
      _isLoading = false;
      notifyListeners();
      
      return feedbacks;
    } catch (e) {
      debugPrint('Error fetching feedbacks by date range: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
  
  /// Calculate dashboard statistics from cached feedbacks
  void _calculateDashboardStats() {
    if (_feedbacks.isEmpty) {
      _dashboardStats = DashboardStats.empty();
      notifyListeners();
      return;
    }
    
    // Total responses
    final totalResponses = _feedbacks.length;
    
    // Calculate average satisfaction (using SQD0 as overall satisfaction)
    final satisfactionRatings = _feedbacks
        .where((f) => f.sqd0Rating != null)
        .map((f) => f.sqd0Rating!)
        .toList();
    
    final avgSatisfaction = satisfactionRatings.isNotEmpty
        ? satisfactionRatings.reduce((a, b) => a + b) / satisfactionRatings.length
        : 0.0;
    
    // Completion rate (surveys with all required fields)
    final completedSurveys = _feedbacks.where((f) => 
        f.sqd0Rating != null && 
        f.cc0Rating != null &&
        f.clientType != null
    ).length;
    final completionRate = totalResponses > 0 
        ? (completedSurveys / totalResponses) * 100 
        : 0.0;
    
    // Negative feedback (satisfaction rating <= 2)
    final negativeFeedbacks = _feedbacks.where((f) => 
        f.sqd0Rating != null && f.sqd0Rating! <= 2
    ).length;
    final negativeRate = totalResponses > 0 
        ? (negativeFeedbacks / totalResponses) * 100 
        : 0.0;
    
    // Weekly trends (last 7 days)
    final weeklyTrends = _calculateWeeklyTrends();
    
    // Satisfaction distribution
    final satisfactionDistribution = _calculateSatisfactionDistribution();
    
    // SQD averages
    final sqdAverages = _calculateSQDAverages();
    
    // Client type distribution
    final clientTypeDistribution = _calculateClientTypeDistribution();
    
    // Service breakdown
    final serviceBreakdown = _calculateServiceBreakdown();
    
    // Recent feedbacks (last 10)
    final recentFeedbacks = _feedbacks.take(10).toList();
    
    _dashboardStats = DashboardStats(
      totalResponses: totalResponses,
      avgSatisfaction: avgSatisfaction,
      completionRate: completionRate,
      negativeRate: negativeRate,
      weeklyTrends: weeklyTrends,
      satisfactionDistribution: satisfactionDistribution,
      sqdAverages: sqdAverages,
      clientTypeDistribution: clientTypeDistribution,
      serviceBreakdown: serviceBreakdown,
      recentFeedbacks: recentFeedbacks,
    );
    
    notifyListeners();
  }
  
  Map<String, int> _calculateWeeklyTrends() {
    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final trends = <String, int>{};
    
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayName = weekDays[day.weekday - 1];
      final count = _feedbacks.where((f) {
        if (f.date == null) return false;
        return f.date!.year == day.year && 
               f.date!.month == day.month && 
               f.date!.day == day.day;
      }).length;
      trends[dayName] = count;
    }
    
    return trends;
  }
  
  Map<String, double> _calculateSatisfactionDistribution() {
    final distribution = <String, int>{
      'Very Satisfied': 0,
      'Satisfied': 0,
      'Neutral': 0,
      'Dissatisfied': 0,
      'Very Dissatisfied': 0,
    };
    
    for (final feedback in _feedbacks) {
      final rating = feedback.sqd0Rating;
      if (rating == null) continue;
      
      if (rating == 5) {
        distribution['Very Satisfied'] = distribution['Very Satisfied']! + 1;
      } else if (rating == 4) {
        distribution['Satisfied'] = distribution['Satisfied']! + 1;
      } else if (rating == 3) {
        distribution['Neutral'] = distribution['Neutral']! + 1;
      } else if (rating == 2) {
        distribution['Dissatisfied'] = distribution['Dissatisfied']! + 1;
      } else {
        distribution['Very Dissatisfied'] = distribution['Very Dissatisfied']! + 1;
      }
    }
    
    final total = distribution.values.reduce((a, b) => a + b);
    if (total == 0) return {'Very Satisfied': 0, 'Satisfied': 0, 'Neutral': 0, 'Dissatisfied': 0};
    
    return distribution.map((key, value) => 
        MapEntry(key, (value / total) * 100));
  }
  
  Map<String, double> _calculateSQDAverages() {
    final sqdFields = {
      'SQD0': (SurveyData f) => f.sqd0Rating,
      'SQD1': (SurveyData f) => f.sqd1Rating,
      'SQD2': (SurveyData f) => f.sqd2Rating,
      'SQD3': (SurveyData f) => f.sqd3Rating,
      'SQD4': (SurveyData f) => f.sqd4Rating,
      'SQD5': (SurveyData f) => f.sqd5Rating,
      'SQD6': (SurveyData f) => f.sqd6Rating,
      'SQD7': (SurveyData f) => f.sqd7Rating,
      'SQD8': (SurveyData f) => f.sqd8Rating,
    };
    
    final averages = <String, double>{};
    
    for (final entry in sqdFields.entries) {
      final values = _feedbacks
          .map((f) => entry.value(f))
          .where((v) => v != null)
          .cast<int>()
          .toList();
      
      if (values.isNotEmpty) {
        averages[entry.key] = values.reduce((a, b) => a + b) / values.length;
      } else {
        averages[entry.key] = 0.0;
      }
    }
    
    return averages;
  }
  
  Map<String, int> _calculateClientTypeDistribution() {
    final distribution = <String, int>{};
    
    for (final feedback in _feedbacks) {
      final clientType = feedback.clientType ?? 'Unknown';
      distribution[clientType] = (distribution[clientType] ?? 0) + 1;
    }
    
    return distribution;
  }
  
  Map<String, double> _calculateServiceBreakdown() {
    final serviceRatings = <String, List<int>>{};
    
    for (final feedback in _feedbacks) {
      final service = feedback.serviceAvailed ?? 'Other';
      final rating = feedback.sqd0Rating;
      
      if (rating != null) {
        serviceRatings.putIfAbsent(service, () => []);
        serviceRatings[service]!.add(rating);
      }
    }
    
    return serviceRatings.map((service, ratings) => 
        MapEntry(service, ratings.reduce((a, b) => a + b) / ratings.length));
  }
  
  /// Stream for real-time updates
  Stream<List<SurveyData>> streamFeedbacks() {
    return _firestore
        .collection('feedbacks')
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final feedbacks = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            // Use createdAt as submittedAt if submittedAt is missing
            if (data['submittedAt'] == null && data['createdAt'] != null) {
              data['submittedAt'] = data['createdAt'];
            }
            return SurveyData.fromJson(data);
          }).toList();
          
          // Sort locally by submittedAt
          feedbacks.sort((a, b) {
            final aDate = a.submittedAt ?? DateTime(1970);
            final bDate = b.submittedAt ?? DateTime(1970);
            return bDate.compareTo(aDate); // descending
          });
          
          return feedbacks;
        });
  }
  
  /// Get feedback by ID
  Future<SurveyData?> getFeedbackById(String id) async {
    try {
      final doc = await _firestore.collection('feedbacks').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return SurveyData.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching feedback by ID: $e');
      return null;
    }
  }
  
  /// Export feedbacks as list of maps (for CSV/JSON export)
  List<Map<String, dynamic>> exportFeedbacks() {
    return _feedbacks.map((f) => f.toJson()).toList();
  }
  
  /// Refresh data
  Future<void> refresh() async {
    await fetchAllFeedbacks(forceRefresh: true);
  }
}

/// Dashboard statistics model
class DashboardStats {
  final int totalResponses;
  final double avgSatisfaction;
  final double completionRate;
  final double negativeRate;
  final Map<String, int> weeklyTrends;
  final Map<String, double> satisfactionDistribution;
  final Map<String, double> sqdAverages;
  final Map<String, int> clientTypeDistribution;
  final Map<String, double> serviceBreakdown;
  final List<SurveyData> recentFeedbacks;
  
  DashboardStats({
    required this.totalResponses,
    required this.avgSatisfaction,
    required this.completionRate,
    required this.negativeRate,
    required this.weeklyTrends,
    required this.satisfactionDistribution,
    required this.sqdAverages,
    required this.clientTypeDistribution,
    required this.serviceBreakdown,
    required this.recentFeedbacks,
  });
  
  factory DashboardStats.empty() {
    return DashboardStats(
      totalResponses: 0,
      avgSatisfaction: 0.0,
      completionRate: 0.0,
      negativeRate: 0.0,
      weeklyTrends: {},
      satisfactionDistribution: {},
      sqdAverages: {},
      clientTypeDistribution: {},
      serviceBreakdown: {},
      recentFeedbacks: [],
    );
  }
  
  // Formatted getters for display
  String get totalResponsesFormatted => _formatNumber(totalResponses);
  String get avgSatisfactionFormatted => '${avgSatisfaction.toStringAsFixed(1)}/5';
  String get completionRateFormatted => '${completionRate.toStringAsFixed(1)}%';
  String get negativeRateFormatted => '${negativeRate.toStringAsFixed(1)}%';
  
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
  
  // Get top performing service
  String get topPerformingService {
    if (serviceBreakdown.isEmpty) return 'N/A';
    final sorted = serviceBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
  
  double get topPerformingServiceScore {
    if (serviceBreakdown.isEmpty) return 0.0;
    final sorted = serviceBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.value;
  }
  
  // Get needs attention service
  String get needsAttentionService {
    if (serviceBreakdown.isEmpty) return 'N/A';
    final sorted = serviceBreakdown.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.first.key;
  }
  
  double get needsAttentionServiceScore {
    if (serviceBreakdown.isEmpty) return 0.0;
    final sorted = serviceBreakdown.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.first.value;
  }
  
  // Get strongest SQD dimensions
  String get strongestSQD {
    if (sqdAverages.isEmpty) return 'N/A';
    final sorted = sqdAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Get top 2
    if (sorted.length >= 2) {
      return '${sorted[0].key} & ${sorted[1].key}';
    }
    return sorted.first.key;
  }
  
  double get strongestSQDScore {
    if (sqdAverages.isEmpty) return 0.0;
    final sorted = sqdAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.value;
  }
}
