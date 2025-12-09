import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

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
class UserManagementService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<SystemUser> _users = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _filterRole;
  String? _filterStatus;
  String? _filterDepartment;
  
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  bool _isListening = false;

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
  int get analystCount => _users.where((u) => u.role == 'Analyst/Viewer' && u.status == 'Active').length;

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
      filtered = filtered.where((u) => u.role == _filterRole).toList();
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
            
            _isLoading = false;
            _error = null;
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

  /// Fetch users once
  Future<void> fetchUsers() async {
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

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new user
  /// Hash a password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
  Future<bool> updateUser(SystemUser user) async {
    try {
      await _firestore.collection('system_users').doc(user.id).update({
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'department': user.department,
        'status': user.status,
      });

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
  Future<bool> setUserStatus(String userId, String status) async {
    try {
      await _firestore.collection('system_users').doc(userId).update({
        'status': status,
      });

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
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('system_users').doc(userId).delete();
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
}
