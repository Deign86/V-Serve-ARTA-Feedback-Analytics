import 'package:flutter/widgets.dart';

/// Minimal RoleBasedWidget used by the dashboard.
/// This permissive implementation always renders the child so that
/// UI remains functional until a proper role check is provided.
class RoleBasedWidget extends StatelessWidget {
  final List<String>? allowedRoles; // kept generic to avoid importing the UserModel
  final Widget child;
  const RoleBasedWidget({Key? key, this.allowedRoles, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to actual user role and check allowedRoles
    return child;
  }
}
