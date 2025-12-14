import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/survey_data.dart';
import 'api_config.dart';
import 'feedback_service_stub.dart';

/// HTTP-based implementation of FeedbackService
/// Uses the backend API instead of direct Firebase/Firestore access
class FeedbackServiceHttp extends FeedbackService {
  final ApiClient _apiClient = ApiClient();
  
  // Polling timer for simulated real-time updates
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 30);
  
  @override
  Future<List<SurveyData>> fetchAllFeedbacks({bool forceRefresh = false}) async {
    // Check cache first (inherited behavior)
    if (!forceRefresh && feedbacks.isNotEmpty) {
      return feedbacks;
    }
    
    isLoadingInternal = true;
    errorInternal = null;
    notifyListeners();
    
    try {
      debugPrint('=== FETCHING FEEDBACKS FROM API ===');
      
      final response = await _apiClient.get('/feedback', queryParams: {'limit': '1000'});
      
      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to fetch feedbacks');
      }
      
      final items = response.data?['items'] as List<dynamic>? ?? [];
      debugPrint('Fetched ${items.length} feedback documents from API');
      
      final feedbackList = items.map((item) {
        final data = Map<String, dynamic>.from(item['data'] as Map);
        data['id'] = item['id'];
        
        // Handle createdAt/submittedAt conversion
        if (data['submittedAt'] == null && data['createdAt'] != null) {
          data['submittedAt'] = data['createdAt'];
        }
        
        return SurveyData.fromJson(data);
      }).toList();
      
      // Sort by submittedAt descending
      feedbackList.sort((a, b) {
        final aDate = a.submittedAt ?? DateTime(1970);
        final bDate = b.submittedAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
      
      feedbacksInternal = feedbackList;
      lastFetchInternal = DateTime.now();
      isLoadingInternal = false;
      
      notifyListeners();
      
      // Calculate stats
      calculateDashboardStatsInternal();
      
      return feedbackList;
    } catch (e) {
      debugPrint('Error fetching feedbacks from API: $e');
      errorInternal = e.toString();
      isLoadingInternal = false;
      notifyListeners();
      return [];
    }
  }
  
  @override
  void startRealtimeUpdates() {
    if (isListening) return;
    
    debugPrint('=== STARTING POLLING FOR FEEDBACK UPDATES ===');
    isListeningInternal = true;
    
    // Initial fetch
    fetchAllFeedbacks(forceRefresh: true);
    
    // Start polling
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      fetchAllFeedbacks(forceRefresh: true);
    });
  }
  
  @override
  void stopRealtimeUpdates() {
    debugPrint('=== STOPPING FEEDBACK POLLING ===');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    isListeningInternal = false;
  }
  
  @override
  Future<List<SurveyData>> fetchFeedbacksByDateRange(DateTime start, DateTime end) async {
    isLoadingInternal = true;
    errorInternal = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.get('/feedback', queryParams: {
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      });
      
      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to fetch feedbacks');
      }
      
      final items = response.data?['items'] as List<dynamic>? ?? [];
      
      final feedbackList = items.map((item) {
        final data = Map<String, dynamic>.from(item['data'] as Map);
        data['id'] = item['id'];
        return SurveyData.fromJson(data);
      }).toList();
      
      isLoadingInternal = false;
      notifyListeners();
      
      return feedbackList;
    } catch (e) {
      debugPrint('Error fetching feedbacks by date range: $e');
      errorInternal = e.toString();
      isLoadingInternal = false;
      notifyListeners();
      return [];
    }
  }
  
  @override
  Stream<List<SurveyData>> streamFeedbacks() {
    // For HTTP, we simulate streaming with periodic polling
    final controller = StreamController<List<SurveyData>>();
    
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      try {
        final feedbackList = await fetchAllFeedbacks();
        if (!controller.isClosed) {
          controller.add(feedbackList);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    });
    
    // Initial fetch
    fetchAllFeedbacks().then((list) {
      if (!controller.isClosed) {
        controller.add(list);
      }
    });
    
    return controller.stream;
  }
  
  @override
  Future<SurveyData?> getFeedbackById(String id) async {
    // Check local cache first
    final local = feedbacks.where((f) => f.id == id).firstOrNull;
    if (local != null) {
      return local;
    }
    
    try {
      final response = await _apiClient.get('/feedback/$id');
      
      if (!response.isSuccess) {
        if (response.statusCode == 404) return null;
        throw Exception(response.error ?? 'Failed to fetch feedback');
      }
      
      final data = Map<String, dynamic>.from(response.data?['data'] as Map);
      data['id'] = response.data?['id'];
      
      return SurveyData.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching feedback by ID: $e');
      return null;
    }
  }
  
  /// Submit a new feedback via API
  Future<String?> submitFeedback(Map<String, dynamic> feedbackData) async {
    try {
      final response = await _apiClient.post('/feedback', body: feedbackData);
      
      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to submit feedback');
      }
      
      final id = response.data?['id'] as String?;
      debugPrint('Feedback submitted successfully: $id');
      
      // Refresh local cache
      await fetchAllFeedbacks(forceRefresh: true);
      
      return id;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return null;
    }
  }
  
  /// Check if the API is reachable
  Future<bool> isApiAvailable() async {
    return await _apiClient.ping();
  }
  
  @override
  void dispose() {
    stopRealtimeUpdates();
    _apiClient.dispose();
    super.dispose();
  }
}
