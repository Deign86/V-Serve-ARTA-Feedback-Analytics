import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
// HTTP services for cross-platform compatibility (no Firebase dependency)
import '../services/offline_queue_http.dart';

/// Compact banner widget to show queue status in survey screens
/// This is the primary widget for user-side survey screens
class OfflineQueueBanner extends StatelessWidget {
  const OfflineQueueBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineQueueService>(
      builder: (context, queueService, _) {
        // Don't show anything if queue is empty and online
        if (queueService.pendingCount == 0 && 
            queueService.failedCount == 0 && 
            queueService.isOnline) {
          return const SizedBox.shrink();
        }
        
        Color bgColor;
        IconData icon;
        String message;
        
        if (!queueService.isOnline) {
          bgColor = Colors.grey.shade700;
          icon = Icons.cloud_off;
          message = 'You are offline. Your submission will sync when online.';
        } else if (queueService.isSyncing) {
          bgColor = Colors.blue;
          icon = Icons.sync;
          message = 'Syncing your submission...';
        } else if (queueService.failedCount > 0) {
          bgColor = Colors.orange.shade700;
          icon = Icons.warning_amber;
          message = 'Submission pending. Will retry automatically.';
        } else if (queueService.pendingCount > 0) {
          bgColor = Colors.orange;
          icon = Icons.pending;
          message = 'Submission pending...';
        } else {
          return const SizedBox.shrink();
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (queueService.isOnline && !queueService.isSyncing && queueService.pendingCount > 0)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => queueService.flush(),
                    child: Text(
                      'Sync Now',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Floating indicator for showing sync status during form submission
class OfflineQueueIndicator extends StatelessWidget {
  const OfflineQueueIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineQueueService>(
      builder: (context, queueService, _) {
        // Only show when there's activity
        if (queueService.pendingCount == 0 && queueService.isOnline) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(queueService),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (queueService.isSyncing)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      _getStatusIcon(queueService),
                      color: Colors.white,
                      size: 14,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusText(queueService),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
  
  Color _getStatusColor(OfflineQueueService queueService) {
    if (!queueService.isOnline) return Colors.grey.shade600;
    if (queueService.isSyncing) return Colors.blue;
    if (queueService.failedCount > 0) return Colors.orange;
    return Colors.green;
  }
  
  IconData _getStatusIcon(OfflineQueueService queueService) {
    if (!queueService.isOnline) return Icons.cloud_off;
    if (queueService.failedCount > 0) return Icons.warning_amber;
    return Icons.cloud_done;
  }
  
  String _getStatusText(OfflineQueueService queueService) {
    if (!queueService.isOnline) return 'Offline';
    if (queueService.isSyncing) return 'Syncing';
    if (queueService.failedCount > 0) return '${queueService.failedCount} pending';
    if (queueService.pendingCount > 0) return '${queueService.pendingCount} queued';
    return 'Synced';
  }
}
