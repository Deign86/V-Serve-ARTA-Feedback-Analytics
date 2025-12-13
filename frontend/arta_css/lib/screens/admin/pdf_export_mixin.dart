import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart'; // Import printing package
import '../../services/feedback_service.dart';
import '../../services/export_service.dart';

// Extension to RoleBasedDashboard to keep main file clean(er) or mixin
// actually I should just add this method to the main file but it's huge.
// I'll add it directly to role_based_dashboard.dart since I can't use extensions for private methods easily without context.
