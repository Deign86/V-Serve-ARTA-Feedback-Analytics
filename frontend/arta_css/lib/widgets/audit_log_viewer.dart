import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/audit_log_model.dart';
// HTTP services for cross-platform compatibility (no Firebase dependency)
import '../services/audit_log_service_http.dart';
import 'package:intl/intl.dart';

/// Widget for displaying audit logs in the admin dashboard
class AuditLogViewer extends StatefulWidget {
  const AuditLogViewer({super.key});

  @override
  State<AuditLogViewer> createState() => _AuditLogViewerState();
}

class _AuditLogViewerState extends State<AuditLogViewer> {
  @override
  void initState() {
    super.initState();
    // Start fetching audit logs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auditService = context.read<AuditLogServiceHttp>();
      auditService.fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditLogServiceHttp>(
      builder: (context, auditService, child) {
        if (auditService.isLoading && auditService.logs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (auditService.error != null && auditService.logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading audit logs',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  auditService.error!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => auditService.fetchLogs(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filters
            _buildHeader(auditService),
            const SizedBox(height: 16),
            
            // Stats cards
            _buildStatsRow(auditService),
            const SizedBox(height: 16),
            
            // Logs list
            Expanded(
              child: auditService.logs.isEmpty
                  ? _buildEmptyState()
                  : _buildLogsList(auditService.logs),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(AuditLogServiceHttp auditService) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;
        final titleFontSize = isNarrow ? 18.0 : 24.0;
        final iconSize = isNarrow ? 22.0 : 28.0;
        
        return Row(
          children: [
            Icon(
              Icons.history,
              color: const Color(0xFF003366),
              size: iconSize,
            ),
            SizedBox(width: isNarrow ? 8 : 12),
            Expanded(
              child: Text(
                'Audit Log',
                style: GoogleFonts.montserrat(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003366),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Filter dropdown
            PopupMenuButton<AuditActionType?>(
              tooltip: 'Filter by action type',
              icon: Badge(
                isLabelVisible: auditService.filterActionType != null,
                child: Icon(Icons.filter_list, size: isNarrow ? 20 : 24),
              ),
              onSelected: (value) {
                auditService.setFilters(actionType: value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem<AuditActionType?>(
                  value: null,
                  child: Text('All Actions'),
                ),
                const PopupMenuDivider(),
                ...AuditActionType.values.map((type) => PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getIconForActionType(type), size: 20),
                      const SizedBox(width: 8),
                      Text(_getDisplayName(type)),
                    ],
                  ),
                )),
              ],
            ),
            SizedBox(width: isNarrow ? 4 : 8),
            // Refresh button
            IconButton(
              onPressed: () => auditService.fetchLogs(forceRefresh: true),
              icon: auditService.isLoading
                  ? SizedBox(
                      width: isNarrow ? 20 : 24,
                      height: isNarrow ? 20 : 24,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.refresh, size: isNarrow ? 20 : 24),
              tooltip: 'Refresh logs',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(AuditLogServiceHttp auditService) {
    final stats = auditService.getAuditStats();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final isVeryNarrow = constraints.maxWidth < 400;
        
        final statCards = [
          _buildStatCard(
            'Total Logs',
            stats['totalLogs'].toString(),
            Icons.list_alt,
            Colors.blue,
            isCompact: isNarrow,
          ),
          _buildStatCard(
            'Today',
            stats['logsToday'].toString(),
            Icons.today,
            Colors.green,
            isCompact: isNarrow,
          ),
          _buildStatCard(
            'This Week',
            stats['logsThisWeek'].toString(),
            Icons.date_range,
            Colors.orange,
            isCompact: isNarrow,
          ),
          _buildStatCard(
            'Failed Logins',
            stats['failedLogins'].toString(),
            Icons.warning,
            Colors.red,
            isCompact: isNarrow,
          ),
        ];
        
        if (isVeryNarrow) {
          // 2x2 grid for very small screens
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: statCards[0]),
                  const SizedBox(width: 8),
                  Expanded(child: statCards[1]),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: statCards[2]),
                  const SizedBox(width: 8),
                  Expanded(child: statCards[3]),
                ],
              ),
            ],
          );
        } else if (isNarrow) {
          // 2x2 grid for narrow screens
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: statCards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: statCards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: statCards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: statCards[3]),
                ],
              ),
            ],
          );
        }
        
        // Full row for wider screens
        return Row(
          children: [
            Expanded(child: statCards[0]),
            const SizedBox(width: 12),
            Expanded(child: statCards[1]),
            const SizedBox(width: 12),
            Expanded(child: statCards[2]),
            const SizedBox(width: 12),
            Expanded(child: statCards[3]),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No audit logs found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actions performed by administrators will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<AuditLogEntry> logs) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(AuditLogEntry log) {
    final severityColor = _getSeverityColor(log.severity);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        final iconPadding = isNarrow ? 8.0 : 10.0;
        final iconSize = isNarrow ? 20.0 : 24.0;
        final cardPadding = isNarrow ? 12.0 : 16.0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: severityColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showLogDetails(log),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with severity indicator
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForActionType(log.actionType),
                      color: severityColor,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: isNarrow ? 10 : 16),
                  
                  // Log details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row - wrap on narrow screens
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              log.actionTypeDisplayName,
                              style: GoogleFonts.poppins(
                                fontSize: isNarrow ? 12 : 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF003366),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: severityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                log.severity.name.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: isNarrow ? 9 : 10,
                                  fontWeight: FontWeight.w600,
                                  color: severityColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log.actionDescription,
                          style: GoogleFonts.poppins(
                            fontSize: isNarrow ? 11 : 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Actor and time info - wrap on narrow screens
                        isNarrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${log.actorName} (${log.actorRole})',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${dateFormat.format(log.timestamp)} at ${timeFormat.format(log.timestamp)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${log.actorName} (${log.actorRole})',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${dateFormat.format(log.timestamp)} at ${timeFormat.format(log.timestamp)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                  
                  // View details button
                  IconButton(
                    onPressed: () => _showLogDetails(log),
                    icon: Icon(Icons.chevron_right, size: isNarrow ? 20 : 24),
                    color: Colors.grey[400],
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isNarrow ? 32 : 48,
                      minHeight: isNarrow ? 32 : 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogDetails(AuditLogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconForActionType(log.actionType),
              color: _getSeverityColor(log.severity),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                log.actionTypeDisplayName,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Description', log.actionDescription),
                _buildDetailRow('Actor', '${log.actorName} (${log.actorEmail})'),
                _buildDetailRow('Role', log.actorRole),
                _buildDetailRow('Timestamp', DateFormat('MMM dd, yyyy HH:mm:ss').format(log.timestamp)),
                if (log.targetName != null)
                  _buildDetailRow('Target', '${log.targetName} (${log.targetType})'),
                if (log.previousValues != null && log.previousValues!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Previous Values:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: log.previousValues!.entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: GoogleFonts.robotoMono(fontSize: 12),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                if (log.newValues != null && log.newValues!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'New Values:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: log.newValues!.entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: GoogleFonts.robotoMono(fontSize: 12),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForActionType(AuditActionType type) {
    switch (type) {
      case AuditActionType.userCreated:
        return Icons.person_add;
      case AuditActionType.userUpdated:
        return Icons.edit;
      case AuditActionType.userDeleted:
        return Icons.person_remove;
      case AuditActionType.userStatusChanged:
        return Icons.toggle_on;
      case AuditActionType.userRoleChanged:
        return Icons.admin_panel_settings;
      case AuditActionType.loginSuccess:
        return Icons.login;
      case AuditActionType.loginFailed:
        return Icons.block;
      case AuditActionType.logout:
        return Icons.logout;
      case AuditActionType.surveyConfigChanged:
        return Icons.settings;
      case AuditActionType.artaConfigViewed:
        return Icons.settings_applications;
      case AuditActionType.feedbackDeleted:
        return Icons.delete;
      case AuditActionType.feedbackExported:
        return Icons.download;
      case AuditActionType.surveySubmitted:
        return Icons.send;
      case AuditActionType.surveyStarted:
        return Icons.play_arrow;
      case AuditActionType.dashboardViewed:
        return Icons.dashboard;
      case AuditActionType.analyticsViewed:
        return Icons.analytics;
      case AuditActionType.feedbackBrowserViewed:
        return Icons.list_alt;
      case AuditActionType.userListViewed:
        return Icons.people;
      case AuditActionType.auditLogViewed:
        return Icons.history;
      case AuditActionType.dataExportsViewed:
        return Icons.download;
      case AuditActionType.settingsChanged:
        return Icons.tune;
    }
  }

  String _getDisplayName(AuditActionType type) {
    switch (type) {
      case AuditActionType.userCreated:
        return 'User Created';
      case AuditActionType.userUpdated:
        return 'User Updated';
      case AuditActionType.userDeleted:
        return 'User Deleted';
      case AuditActionType.userStatusChanged:
        return 'Status Changed';
      case AuditActionType.userRoleChanged:
        return 'Role Changed';
      case AuditActionType.loginSuccess:
        return 'Login Success';
      case AuditActionType.loginFailed:
        return 'Login Failed';
      case AuditActionType.logout:
        return 'Logout';
      case AuditActionType.surveyConfigChanged:
        return 'Config Changed';
      case AuditActionType.artaConfigViewed:
        return 'ARTA Config Viewed';
      case AuditActionType.feedbackDeleted:
        return 'Feedback Deleted';
      case AuditActionType.feedbackExported:
        return 'Data Exported';
      case AuditActionType.surveySubmitted:
        return 'Survey Submitted';
      case AuditActionType.surveyStarted:
        return 'Survey Started';
      case AuditActionType.dashboardViewed:
        return 'Dashboard Viewed';
      case AuditActionType.analyticsViewed:
        return 'Analytics Viewed';
      case AuditActionType.feedbackBrowserViewed:
        return 'Feedback Viewed';
      case AuditActionType.userListViewed:
        return 'User List Viewed';
      case AuditActionType.auditLogViewed:
        return 'Audit Log Viewed';
      case AuditActionType.dataExportsViewed:
        return 'Exports Viewed';
      case AuditActionType.settingsChanged:
        return 'Settings Changed';
    }
  }

  Color _getSeverityColor(AuditSeverity severity) {
    switch (severity) {
      case AuditSeverity.low:
        return Colors.blue;
      case AuditSeverity.medium:
        return Colors.orange;
      case AuditSeverity.high:
        return Colors.red;
    }
  }
}
