// Stub for feedback_service.dart - used on platforms where Firebase is not available
// This allows the code to compile without firebase dependencies

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/survey_data.dart';
import '../models/export_filters.dart';
import 'cache_service.dart';

/// Dashboard statistics summary - mirrors the real DashboardStats
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

/// Stub FeedbackService for native desktop platforms
/// On these platforms, use FeedbackServiceHttp instead
class FeedbackService extends ChangeNotifier with CachingMixin {
  List<SurveyData> _feedbacks = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;
  DashboardStats? _dashboardStats;
  bool _isListening = false;

  // Public getters
  List<SurveyData> get feedbacks => _feedbacks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardStats? get dashboardStats => _dashboardStats;
  bool get isListening => _isListening;
  DateTime? get lastFetch => _lastFetch;

  // Protected setters for subclass access
  @protected
  set feedbacksInternal(List<SurveyData> value) => _feedbacks = value;
  @protected
  set isLoadingInternal(bool value) => _isLoading = value;
  @protected
  set errorInternal(String? value) => _error = value;
  @protected
  set lastFetchInternal(DateTime? value) => _lastFetch = value;
  @protected
  set isListeningInternal(bool value) => _isListening = value;
  @protected
  set dashboardStatsInternal(DashboardStats? value) => _dashboardStats = value;

  FeedbackService();

  /// Calculate dashboard statistics from current feedbacks
  @protected
  void calculateDashboardStatsInternal() {
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

    // Weekly trends
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
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final trends = <String, int>{};

    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = weekdays[date.weekday - 1];
      trends[dayName] = 0;
    }

    for (final feedback in _feedbacks) {
      final date = feedback.submittedAt ?? feedback.date;
      if (date != null) {
        final diff = now.difference(date).inDays;
        if (diff >= 0 && diff < 7) {
          final dayName = weekdays[date.weekday - 1];
          trends[dayName] = (trends[dayName] ?? 0) + 1;
        }
      }
    }

    return trends;
  }

  Map<String, double> _calculateSatisfactionDistribution() {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final feedback in _feedbacks) {
      if (feedback.sqd0Rating != null) {
        final rating = feedback.sqd0Rating!;
        if (rating >= 1 && rating <= 5) {
          distribution[rating] = (distribution[rating] ?? 0) + 1;
        }
      }
    }

    final total = distribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return {};

    return {
      '1': (distribution[1]! / total) * 100,
      '2': (distribution[2]! / total) * 100,
      '3': (distribution[3]! / total) * 100,
      '4': (distribution[4]! / total) * 100,
      '5': (distribution[5]! / total) * 100,
    };
  }

  Map<String, double> _calculateSQDAverages() {
    final sqdLabels = [
      'SQD0', 'SQD1', 'SQD2', 'SQD3', 'SQD4', 'SQD5', 'SQD6', 'SQD7', 'SQD8'
    ];
    final averages = <String, double>{};

    for (var i = 0; i < sqdLabels.length; i++) {
      final ratings = _feedbacks.map((f) {
        switch (i) {
          case 0: return f.sqd0Rating;
          case 1: return f.sqd1Rating;
          case 2: return f.sqd2Rating;
          case 3: return f.sqd3Rating;
          case 4: return f.sqd4Rating;
          case 5: return f.sqd5Rating;
          case 6: return f.sqd6Rating;
          case 7: return f.sqd7Rating;
          case 8: return f.sqd8Rating;
          default: return null;
        }
      }).where((r) => r != null).map((r) => r!).toList();

      if (ratings.isNotEmpty) {
        averages[sqdLabels[i]] = ratings.reduce((a, b) => a + b) / ratings.length;
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
    final serviceTotals = <String, List<int>>{};

    for (final feedback in _feedbacks) {
      final service = feedback.serviceAvailed ?? 'Unknown';
      if (feedback.sqd0Rating != null) {
        serviceTotals.putIfAbsent(service, () => []);
        serviceTotals[service]!.add(feedback.sqd0Rating!);
      }
    }

    final breakdown = <String, double>{};
    for (final entry in serviceTotals.entries) {
      if (entry.value.isNotEmpty) {
        breakdown[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    return breakdown;
  }

  Future<List<SurveyData>> fetchAllFeedbacks({bool forceRefresh = false}) async {
    throw UnimplementedError('Use FeedbackServiceHttp on native desktop platforms');
  }

  Future<void> fetchFeedbacks({bool forceRefresh = false}) async {
    await fetchAllFeedbacks(forceRefresh: forceRefresh);
  }

  Future<void> startListening() async {
    startRealtimeUpdates();
  }

  void stopListening() {
    stopRealtimeUpdates();
  }

  void startRealtimeUpdates() {
    throw UnimplementedError('Use FeedbackServiceHttp on native desktop platforms');
  }

  void stopRealtimeUpdates() {
    _isListening = false;
  }

  void refresh() {
    // Trigger a refresh of the data
    fetchAllFeedbacks(forceRefresh: true);
  }

  /// Clear the cache and reset state
  Future<void> clearCache() async {
    _feedbacks = [];
    _dashboardStats = null;
    _lastFetch = null;
    _error = null;
    notifyListeners();
  }

  Future<List<SurveyData>> fetchFeedbacksByDateRange(DateTime start, DateTime end) async {
    throw UnimplementedError('Use FeedbackServiceHttp on native desktop platforms');
  }

  Stream<List<SurveyData>> streamFeedbacks() {
    throw UnimplementedError('Use FeedbackServiceHttp on native desktop platforms');
  }

  Future<SurveyData?> getFeedbackById(String id) async {
    throw UnimplementedError('Use FeedbackServiceHttp on native desktop platforms');
  }

  Future<String?> submitFeedback(Map<String, dynamic> feedbackData) async {
    throw UnimplementedError('Use FeedbackServiceHttp on native desktop platforms');
  }

  /// Get unique client types from feedbacks
  List<String> getUniqueClientTypes() {
    return _feedbacks
        .map((f) => f.clientType)
        .where((t) => t != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  /// Get unique regions from feedbacks
  List<String> getUniqueRegions() {
    return _feedbacks
        .map((f) => f.regionOfResidence)
        .where((r) => r != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  /// Get unique services from feedbacks
  List<String> getUniqueServices() {
    return _feedbacks
        .map((f) => f.serviceAvailed)
        .where((s) => s != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  /// Get date range of feedbacks
  (DateTime?, DateTime?) getFeedbackDateRange() {
    if (_feedbacks.isEmpty) return (null, null);

    DateTime? earliest;
    DateTime? latest;

    for (final feedback in _feedbacks) {
      final date = feedback.submittedAt ?? feedback.date;
      if (date != null) {
        if (earliest == null || date.isBefore(earliest)) {
          earliest = date;
        }
        if (latest == null || date.isAfter(latest)) {
          latest = date;
        }
      }
    }

    return (earliest, latest);
  }

  /// Export feedbacks as list of maps (for CSV/JSON export)
  List<Map<String, dynamic>> exportFeedbacks() {
    return _feedbacks.map((f) => f.toJson()).toList();
  }

  /// Export filtered feedbacks based on filters
  List<Map<String, dynamic>> exportFilteredFeedbacks(ExportFilters filters) {
    if (!filters.hasActiveFilters) {
      return exportFeedbacks();
    }
    
    final filtered = _feedbacks.where((f) {
      // Date range filter
      if (filters.startDate != null || filters.endDate != null) {
        final feedbackDate = f.submittedAt ?? f.date;
        if (feedbackDate == null) return false;
        
        if (filters.startDate != null) {
          final startOfDay = DateTime(
            filters.startDate!.year,
            filters.startDate!.month,
            filters.startDate!.day,
          );
          if (feedbackDate.isBefore(startOfDay)) return false;
        }
        
        if (filters.endDate != null) {
          final endOfDay = DateTime(
            filters.endDate!.year,
            filters.endDate!.month,
            filters.endDate!.day,
            23, 59, 59,
          );
          if (feedbackDate.isAfter(endOfDay)) return false;
        }
      }
      
      // Client type filter
      if (filters.clientType != null && 
          f.clientType?.toLowerCase() != filters.clientType!.toLowerCase()) {
        return false;
      }

      // Region filter
      if (filters.region != null && 
          f.regionOfResidence?.toLowerCase() != filters.region!.toLowerCase()) {
        return false;
      }

      // Service filter
      if (filters.serviceAvailed != null && 
          f.serviceAvailed?.toLowerCase() != filters.serviceAvailed!.toLowerCase()) {
        return false;
      }

      // Satisfaction rating filter - support both individual selection and range
      if (filters.selectedRatings != null && filters.selectedRatings!.isNotEmpty) {
        // Individual rating selection
        if (f.sqd0Rating == null || !filters.selectedRatings!.contains(f.sqd0Rating!)) {
          return false;
        }
      } else {
        // Range-based filter (legacy support)
        if (filters.minSatisfaction != null && 
            (f.sqd0Rating == null || f.sqd0Rating! < filters.minSatisfaction!)) {
          return false;
        }
        if (filters.maxSatisfaction != null && 
            (f.sqd0Rating == null || f.sqd0Rating! > filters.maxSatisfaction!)) {
          return false;
        }
      }
      
      // CC Awareness filter
      if (filters.ccAware != null) {
        final isAware = (f.cc0Rating ?? 0) >= 3;
        if (filters.ccAware! != isAware) {
          return false;
        }
      }

      return true;
    }).toList();
    
    return filtered.map((f) => f.toJson()).toList();
  }

}
