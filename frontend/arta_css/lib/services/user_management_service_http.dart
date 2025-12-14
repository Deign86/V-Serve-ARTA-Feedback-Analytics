// HTTP-based UserManagementService implementation
// Uses the backend API instead of direct Firebase/Firestore access

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_config.dart';
import 'cache_service.dart';
import 'audit_log_service_http.dart';
import 'user_management_service_stub.dart' show SystemUser;

// Re-export SystemUser for consumers of this HTTP service
export 'user_management_service_stub.dart' show SystemUser;

/// HTTP-based implementation of UserManagementService
/// Uses the backend API for user management instead of direct Firebase access
class UserManagementServiceHttp extends ChangeNotifier with CachingMixin {
  final ApiClient _apiClient = ApiClient();
  
  // Audit log service reference
  AuditLogServiceHttp? _auditLogService;
  UserModel? _currentActor;
  
  List<SystemUser> _users = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _filterRole;
  String? _filterStatus;
  String? _filterDepartment;
  DateTime? _lastFetch;
  
  Timer? _pollingTimer;
  bool _isListening = false;
  
  static const String _usersCacheKey = 'system_users_list';
  static const Duration _pollingInterval = Duration(seconds: 30);
  
  /// Set the audit log service for logging actions
  void setAuditService(AuditLogServiceHttp auditService, UserModel? currentUser) {
    _auditLogService = auditService;
    _currentActor = currentUser;
  }
  
  // Getters
  List<SystemUser> get users => _getFilteredUsers();
  List<SystemUser> get allUsers => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isListening => _isListening;
  String get searchQuery => _searchQuery;
  String? get filterRole => _filterRole;
  String? get filterStatus => _filterStatus;
  String? get filterDepartment => _filterDepartment;
  
  // Role counts
  int get administratorCount => _users.where((u) => u.role == 'Administrator' && u.status == 'Active').length;
  int get editorCount => _users.where((u) => u.role == 'Editor' && u.status == 'Active').length;
  int get analystCount => _users.where((u) => (u.role == 'Analyst/Viewer' || u.role == 'Viewer') && u.status == 'Active').length;
  
  // Available departments
  List<String> get departments => _users.map((u) => u.department).where((d) => d.isNotEmpty).toSet().toList()..sort();
  
  /// Get filtered users based on search and filters
  List<SystemUser> _getFilteredUsers() {
    var filtered = _users.toList();
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((u) =>
          u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.department.toLowerCase().contains(query)
      ).toList();
    }
    
    // Apply role filter
    if (_filterRole != null) {
      if (_filterRole == 'Analyst/Viewer' || _filterRole == 'Viewer') {
        filtered = filtered.where((u) => u.role == 'Analyst/Viewer' || u.role == 'Viewer').toList();
      } else {
        filtered = filtered.where((u) => u.role == _filterRole).toList();
      }
    }
    
    // Apply status filter
    if (_filterStatus != null) {
      filtered = filtered.where((u) => u.status == _filterStatus).toList();
    }
    
    // Apply department filter
    if (_filterDepartment != null) {
      filtered = filtered.where((u) => u.department == _filterDepartment).toList();
    }
    
    return filtered;
  }
  
  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  /// Set filters
  void setFilters({String? role, String? status, String? department}) {
    _filterRole = role;
    _filterStatus = status;
    _filterDepartment = department;
    notifyListeners();
  }
  
  /// Clear all filters
  void clearFilters() {
    _filterRole = null;
    _filterStatus = null;
    _filterDepartment = null;
    _searchQuery = '';
    notifyListeners();
  }
  
  /// Start polling for updates
  void startRealtimeUpdates() {
    if (_isListening) return;
    
    debugPrint('=== STARTING USER MANAGEMENT POLLING ===');
    _isListening = true;
    
    // Initial fetch
    fetchUsers(forceRefresh: true);
    
    // Start polling
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      fetchUsers(forceRefresh: true);
    });
  }
  
  /// Stop polling
  void stopRealtimeUpdates() {
    debugPrint('=== STOPPING USER MANAGEMENT POLLING ===');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isListening = false;
  }
  
  /// Fetch users from API
  Future<void> fetchUsers({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _users.isNotEmpty && _lastFetch != null) {
      final diff = DateTime.now().difference(_lastFetch!);
      if (diff.inMinutes < 5) {
        return;
      }
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.get('/auth/users');
      
      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to fetch users');
      }
      
      final usersData = response.data?['users'] as List<dynamic>? ?? [];
      
      _users = usersData.map((userData) {
        final data = Map<String, dynamic>.from(userData);
        return SystemUser(
          id: data['id'] ?? '',
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? 'Analyst/Viewer',
          department: data['department'] ?? '',
          status: data['isActive'] == true ? 'Active' : 'Inactive',
          createdAt: data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
          lastLoginAt: data['lastLoginAt'] != null
              ? DateTime.tryParse(data['lastLoginAt'].toString())
              : null,
        );
      }).toList();
      
      _lastFetch = DateTime.now();
      _isLoading = false;
      
      // Cache in memory
      cacheService.setInMemory(_usersCacheKey, _users, ttl: CacheConfig.defaultTTL);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching users from API: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Add a new user
  Future<bool> addUser({
    required String name,
    required String email,
    required String role,
    required String department,
    required String password,
  }) async {
    try {
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        notifyListeners();
        return false;
      }
      
      final response = await _apiClient.post('/auth/users', body: {
        'name': name,
        'email': email,
        'role': role,
        'password': password,
        'isActive': true,
      });
      
      if (!response.isSuccess) {
        _error = response.error ?? 'Failed to create user';
        notifyListeners();
        return false;
      }
      
      final userData = response.data?['user'] as Map<String, dynamic>?;
      
      // Log the user creation
      await _auditLogService?.logUserCreated(
        actor: _currentActor,
        newUserId: userData?['id'] ?? '',
        newUserName: name,
        newUserEmail: email,
        newUserRole: role,
        newUserDepartment: department,
      );
      
      // Refresh user list
      await fetchUsers(forceRefresh: true);
      
      debugPrint('User added successfully');
      return true;
    } catch (e) {
      debugPrint('Error adding user: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Update an existing user
  Future<bool> updateUser(SystemUser user, {SystemUser? previousUser}) async {
    try {
      final updates = <String, dynamic>{
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'isActive': user.status == 'Active',
      };
      
      final response = await _apiClient.patch('/auth/users/${user.id}', body: updates);
      
      if (!response.isSuccess) {
        _error = response.error ?? 'Failed to update user';
        notifyListeners();
        return false;
      }
      
      // Log role change if applicable
      if (previousUser != null && previousUser.role != user.role) {
        await _auditLogService?.logUserRoleChanged(
          actor: _currentActor,
          targetUserId: user.id,
          targetUserName: user.name,
          previousRole: previousUser.role,
          newRole: user.role,
        );
      }
      
      // Log general update
      await _auditLogService?.logUserUpdated(
        actor: _currentActor,
        targetUserId: user.id,
        targetUserName: user.name,
        previousValues: {
          'name': previousUser?.name ?? '',
          'email': previousUser?.email ?? '',
          'role': previousUser?.role ?? '',
          'status': previousUser?.status ?? '',
        },
        newValues: {
          'name': user.name,
          'email': user.email,
          'role': user.role,
          'status': user.status,
        },
      );
      
      // Refresh user list
      await fetchUsers(forceRefresh: true);
      
      debugPrint('User updated: ${user.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Change user status
  Future<bool> setUserStatus(String userId, String status, {String? userName, String? previousStatus}) async {
    try {
      final response = await _apiClient.patch('/auth/users/$userId', body: {
        'isActive': status == 'Active',
      });
      
      if (!response.isSuccess) {
        _error = response.error ?? 'Failed to change user status';
        notifyListeners();
        return false;
      }
      
      // Log status change
      await _auditLogService?.logUserStatusChanged(
        actor: _currentActor,
        targetUserId: userId,
        targetUserName: userName ?? userId,
        previousStatus: previousStatus ?? 'Unknown',
        newStatus: status,
      );
      
      // Refresh user list
      await fetchUsers(forceRefresh: true);
      
      debugPrint('User $userId status changed to $status');
      return true;
    } catch (e) {
      debugPrint('Error changing user status: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Delete a user
  /// Set [hardDelete] to true to permanently delete from database (default: true)
  /// Set [hardDelete] to false to only disable/deactivate the account
  Future<bool> deleteUser(String userId, {String? userName, String? userEmail, bool hardDelete = true}) async {
    try {
      // Pass hardDelete query parameter to actually remove from database
      final response = await _apiClient.delete('/auth/users/$userId?hardDelete=$hardDelete');
      
      if (!response.isSuccess) {
        _error = response.error ?? 'Failed to delete user';
        notifyListeners();
        return false;
      }
      
      // Log deletion
      await _auditLogService?.logUserDeleted(
        actor: _currentActor,
        deletedUserId: userId,
        deletedUserName: userName ?? userId,
        deletedUserEmail: userEmail ?? '',
      );
      
      // Refresh user list
      await fetchUsers(forceRefresh: true);
      
      debugPrint('User deleted: $userId');
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Clear all cached user data
  void clearCache() {
    cacheService.removeFromMemory(_usersCacheKey);
    _users = [];
    _lastFetch = null;
    notifyListeners();
    debugPrint('UserManagementServiceHttp: Cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'usersCount': _users.length,
      'lastFetch': _lastFetch?.toIso8601String(),
      'isListening': _isListening,
    };
  }
  
  @override
  void dispose() {
    stopRealtimeUpdates();
    _apiClient.dispose();
    super.dispose();
  }
}
