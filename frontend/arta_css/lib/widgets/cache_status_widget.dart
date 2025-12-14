import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cache_service.dart';
// HTTP services for cross-platform compatibility (no Firebase dependency)
import '../services/feedback_service_http.dart';
import '../services/user_management_service_http.dart';

/// Widget to display and manage cache status
/// Can be added to admin settings or debug screens
class CacheStatusWidget extends StatelessWidget {
  const CacheStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CacheService>(
      builder: (context, cacheService, _) {
        final stats = cacheService.getStatistics();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.memory, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Cache Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh stats',
                      onPressed: () {
                        cacheService.cleanupExpiredEntries();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache stats refreshed'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  'Memory Entries',
                  '${stats['memoryCacheSize']}',
                  Icons.storage,
                ),
                _buildStatRow(
                  context,
                  'Cache Hits',
                  '${stats['cacheHits']}',
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                _buildStatRow(
                  context,
                  'Cache Misses',
                  '${stats['cacheMisses']}',
                  Icons.cancel_outlined,
                  color: Colors.orange,
                ),
                _buildStatRow(
                  context,
                  'Hit Rate',
                  stats['hitRate'] as String,
                  Icons.speed,
                  color: _getHitRateColor(cacheService.hitRate),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Clear Memory'),
                      onPressed: () {
                        cacheService.clearMemoryCache();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Memory cache cleared'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('Clear All'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                      ),
                      onPressed: () => _showClearAllDialog(context, cacheService),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getHitRateColor(double hitRate) {
    if (hitRate >= 80) return Colors.green;
    if (hitRate >= 50) return Colors.orange;
    return Colors.red;
  }
  
  void _showClearAllDialog(BuildContext context, CacheService cacheService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Caches?'),
        content: const Text(
          'This will clear all cached data including:\n\n'
          '• Memory cache\n'
          '• Persistent storage cache\n'
          '• Cached feedbacks\n'
          '• Cached user data\n\n'
          'Data will be refetched from the server on next access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              
              // Capture services before async gap
              final feedbackService = context.read<FeedbackService>();
              final userService = context.read<UserManagementService>();
              final messenger = ScaffoldMessenger.of(context);
              
              // Clear all caches
              await cacheService.clearAllCaches();
              
              // Also clear service-specific caches
              await feedbackService.clearCache();
              await userService.clearCache();
              
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('All caches cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

/// Compact version for embedding in settings lists
class CacheStatusTile extends StatelessWidget {
  const CacheStatusTile({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<CacheService>(
      builder: (context, cacheService, _) {
        final stats = cacheService.getStatistics();
        
        return ListTile(
          leading: const Icon(Icons.memory),
          title: const Text('Cache Management'),
          subtitle: Text(
            '${stats['memoryCacheSize']} entries • ${stats['hitRate']} hit rate',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CacheStatusWidget(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
