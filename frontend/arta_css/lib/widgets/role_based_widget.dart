// lib/widgets/role_based_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_services.dart';
import '../models/user_model.dart';

class RoleBasedWidget extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleBasedWidget({
    Key? key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userRole = authService.userRole;

    if (userRole != null && allowedRoles.contains(userRole)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

class PermissionBasedWidget extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionBasedWidget({
    Key? key,
    required this.permission,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.hasPermission(permission)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
