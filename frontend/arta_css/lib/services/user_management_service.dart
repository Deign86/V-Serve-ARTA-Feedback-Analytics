import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'cache_service.dart';
import 'audit_log_service.dart';
import '../models/user_model.dart';

/// Model representing an admin/system user
class SystemUser {
  final String id;
  final String name;
  final String email;
  final String role; // Administrator, Editor, Analyst/Viewer
  final String department;
  final String status; // Active, Inactive, Suspended
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  SystemUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Create from Firestore document
  factory SystemUser.fromJson(Map<String, dynamic> json) {
    return SystemUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Analyst/Viewer',
      department: json['department'] ?? '',
      status: json['status'] ?? 'Active',
      createdAt: json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastLoginAt: json['lastLoginAt'] is Timestamp
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : json['lastLoginAt'] != null 
              ? DateTime.tryParse(json['lastLoginAt'].toString())
              : null,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  /// Get initials from name
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '??';
  }

  /// Copy with modifications
  SystemUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? department,
    String? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return SystemUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// Service for managing system users
class UserManagementService extends ChangeNotifier with CachingMixin {
  // Lazy initialization of Firestore to avoid accessing before Firebase is ready
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  // Audit log service reference (set via setAuditService)
  AuditLogService? _auditLogService;
  UserModel? _currentActor;
  
  /// Set the audit log service for logging actions
  void setAuditService(AuditLogService auditService, UserModel? currentUser) {
    _auditLogService = auditService;
    _currentActor = currentUser;
  }
  
  List<SystemUser> _users = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _filterRole;
  String? _filterStatus;
  String? _filterDepartment;
  DateTime? _lastFetch;
  
  static const String _usersCacheKey = 'system_users_list';
  
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  bool _isListening = false;
  
  /// Constructor - load from persistent cache on startup
  UserManagementService() {
    _loadFromPersistentCache();
  }
  
  /// Load cached users from persistent storage
  Future<void> _loadFromPersistentCache() async {
    try {
      final cachedData = await cacheService.loadFromPersistent<List<dynamic>>(
        CacheConfig.usersCacheKey,
        timestampKey: CacheConfig.usersTimestampKey,
        maxAge: CacheConfig.longTTL,
      );
      
      if (cachedData != null && cachedData.isNotEmpty) {
        _users = cachedData
            .map((json) => SystemUser.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        _lastFetch = DateTime.now();
        debugPrint('UserManagementService: Loaded ${_users.length} users from persistent cache');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('UserManagementService: Error loading from persistent cache: $e');
    }
  }
  
  /// Save users to persistent cache
  Future<void> _saveToPersistentCache() async {
    try {
      final jsonList = _users.map((u) => u.toJson()).toList();
      await cacheService.saveToPersistent(
        CacheConfig.usersCacheKey,
        jsonList,
        timestampKey: CacheConfig.usersTimestampKey,
      );
      debugPrint('UserManagementService: Saved ${_users.length} users to persistent cache');
    } catch (e) {
      debugPrint('UserManagementService: Error saving to persistent cache: $e');
    }
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

  /// Start listening to real-time updates
  void startRealtimeUpdates() {
    if (_isListening) return;
    
    debugPrint('=== STARTING USER MANAGEMENT LISTENER ===');
    _isListening = true;
    _isLoading = true;
    notifyListeners();

    _usersSubscription = _firestore
        .collection('system_users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint('User update: ${snapshot.docs.length} users');
            
            _users = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return SystemUser.fromJson(data);
            }).toList();
            
            _lastFetch = DateTime.now();
            _isLoading = false;
            _error = null;
            
            // Cache in memory and persist
            cacheService.setInMemory(_usersCacheKey, _users, ttl: CacheConfig.defaultTTL);
            _saveToPersistentCache();
            
            notifyListeners();
          },
          onError: (error) {
            debugPrint('User listener error: $error');
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Stop listening
  void stopRealtimeUpdates() {
    debugPrint('=== STOPPING USER MANAGEMENT LISTENER ===');
    _usersSubscription?.cancel();
    _usersSubscription = null;
    _isListening = false;
  }

  /// Fetch users once with caching
  Future<void> fetchUsers({bool forceRefresh = false}) async {
    // Check memory cache first
    if (!forceRefresh) {
      final cachedUsers = cacheService.getFromMemory<List<SystemUser>>(_usersCacheKey);
      if (cachedUsers != null) {
        _users = cachedUsers;
        notifyListeners();
        return;
      }
      
      // Fallback to instance cache with time check
      if (_users.isNotEmpty && _lastFetch != null) {
        final diff = DateTime.now().difference(_lastFetch!);
        if (diff.inMinutes < 5) {
          return;
        }
      }
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('system_users')
          .orderBy('createdAt', descending: true)
          .get();

      _users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SystemUser.fromJson(data);
      }).toList();
      
      _lastFetch = DateTime.now();
      _isLoading = false;
      
      // Cache in memory and persist
      cacheService.setInMemory(_usersCacheKey, _users, ttl: CacheConfig.defaultTTL);
      _saveToPersistentCache();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new user
  /// Hash a password using bcrypt (secure, memory-hard algorithm)
  static String _hashPassword(String password) {
    // Generate a salt with work factor 12 (good balance of security and performance)
    final salt = BCrypt.gensalt(logRounds: 12);
    return BCrypt.hashpw(password, salt);
  }

  /// Add a new user to Firestore
  Future<bool> addUser({
    required String name,
    required String email,
    required String role,
    required String department,
    required String password,
  }) async {
    try {
      // Validate password
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        notifyListeners();
        return false;
      }

      // Check if email already exists
      final existing = await _firestore
          .collection('system_users')
          .where('email', isEqualTo: email)
          .get();

      if (existing.docs.isNotEmpty) {
        _error = 'A user with this email already exists';
        notifyListeners();
        return false;
      }

      // Hash the password before storing
      final passwordHash = _hashPassword(password);

      final docRef = await _firestore.collection('system_users').add({
        'name': name,
        'email': email,
        'role': role,
        'department': department,
        'passwordHash': passwordHash,
        'status': 'Active',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
      });

      // Log the user creation to audit log
      await _auditLogService?.logUserCreated(
        actor: _currentActor,
        newUserId: docRef.id,
        newUserName: name,
        newUserEmail: email,
        newUserRole: role,
        newUserDepartment: department,
      );

      debugPrint('User added with ID: ${docRef.id}');
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
      // Get previous values if not provided
      SystemUser? oldUser = previousUser;
      if (oldUser == null) {
        final existingDoc = await _firestore.collection('system_users').doc(user.id).get();
        if (existingDoc.exists) {
          final data = existingDoc.data()!;
          data['id'] = existingDoc.id;
          oldUser = SystemUser.fromJson(data);
        }
      }
      
      await _firestore.collection('system_users').doc(user.id).update({
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'department': user.department,
        'status': user.status,
      });

      // Log to audit - check if role changed specifically
      if (oldUser != null && oldUser.role != user.role) {
        await _auditLogService?.logUserRoleChanged(
          actor: _currentActor,
          targetUserId: user.id,
          targetUserName: user.name,
          previousRole: oldUser.role,
          newRole: user.role,
        );
      }
      
      // Log general update
      await _auditLogService?.logUserUpdated(
        actor: _currentActor,
        targetUserId: user.id,
        targetUserName: user.name,
        previousValues: {
          'name': oldUser?.name ?? '',
          'email': oldUser?.email ?? '',
          'role': oldUser?.role ?? '',
          'department': oldUser?.department ?? '',
          'status': oldUser?.status ?? '',
        },
        newValues: {
          'name': user.name,
          'email': user.email,
          'role': user.role,
          'department': user.department,
          'status': user.status,
        },
      );

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
      // Get previous status if not provided
      String oldStatus = previousStatus ?? 'Unknown';
      String userDisplayName = userName ?? userId;
      
      if (previousStatus == null || userName == null) {
        final existingDoc = await _firestore.collection('system_users').doc(userId).get();
        if (existingDoc.exists) {
          final data = existingDoc.data()!;
          oldStatus = data['status'] ?? 'Unknown';
          userDisplayName = data['name'] ?? userId;
        }
      }
      
      await _firestore.collection('system_users').doc(userId).update({
        'status': status,
      });

      // Log status change to audit
      await _auditLogService?.logUserStatusChanged(
        actor: _currentActor,
        targetUserId: userId,
        targetUserName: userDisplayName,
        previousStatus: oldStatus,
        newStatus: status,
      );

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
  Future<bool> deleteUser(String userId, {String? userName, String? userEmail}) async {
    try {
      // Get user info before deletion for audit log
      String deletedName = userName ?? userId;
      String deletedEmail = userEmail ?? '';
      
      if (userName == null || userEmail == null) {
        final existingDoc = await _firestore.collection('system_users').doc(userId).get();
        if (existingDoc.exists) {
          final data = existingDoc.data()!;
          deletedName = data['name'] ?? userId;
          deletedEmail = data['email'] ?? '';
        }
      }
      
      await _firestore.collection('system_users').doc(userId).delete();
      
      // Log deletion to audit
      await _auditLogService?.logUserDeleted(
        actor: _currentActor,
        deletedUserId: userId,
        deletedUserName: deletedName,
        deletedUserEmail: deletedEmail,
      );
      
      debugPrint('User deleted: $userId');
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Record user login
  Future<void> recordLogin(String userId) async {
    try {
      await _firestore.collection('system_users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error recording login: $e');
    }
  }

  @override
  void dispose() {
    stopRealtimeUpdates();
    super.dispose();
  }
  
  /// Clear all cached user data
  Future<void> clearCache() async {
    cacheService.removeFromMemory(_usersCacheKey);
    await cacheService.removeFromPersistent(
      CacheConfig.usersCacheKey,
      timestampKey: CacheConfig.usersTimestampKey,
    );
    _users = [];
    _lastFetch = null;
    notifyListeners();
    debugPrint('UserManagementService: Cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'usersCount': _users.length,
      'lastFetch': _lastFetch?.toIso8601String(),
      'isListening': _isListening,
    };
  }
}
