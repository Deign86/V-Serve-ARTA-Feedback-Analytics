import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// HTTP services for cross-platform compatibility (no Firebase dependency)
import '../../services/feedback_service_http.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_screens.dart';
import '../../services/auth_services_http.dart';
import '../../services/user_management_service_http.dart';
import '../../services/audit_log_service_http.dart';
import '../../widgets/global_offline_indicator.dart';
import '../../widgets/export_filter_dialog.dart';
import '../../utils/admin_theme.dart';

// NOTE: This file provides screens (DashboardScreen, etc.)
// and no longer contains its own `main()` or a top-level `MaterialApp`.
// The app should use the single top-level `MaterialApp` defined in `main.dart`.
// Login is handled by RoleBasedLoginScreen at '/admin/login'.

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  /// Menu item configuration with role-based access
  /// Each item contains: icon, label, screen widget, and required permission (null = all access)
  static const List<Map<String, dynamic>> _menuConfig = [
    {'icon': Icons.dashboard, 'label': 'Dashboard', 'permission': null},
    {'icon': Icons.settings_applications, 'label': 'ARTA Configuration', 'permission': 'configuration'},
    {'icon': Icons.people, 'label': 'User Management', 'permission': 'manage_users'},
    {'icon': Icons.analytics, 'label': 'Detailed Analytics', 'permission': 'detailed_analytics'},
    {'icon': Icons.download, 'label': 'Data Exports', 'permission': null},
    {'icon': Icons.history, 'label': 'Audit Log', 'permission': 'manage_users'},
    {'icon': Icons.settings, 'label': 'Settings', 'permission': 'manage_users'},
  ];

  @override
  void initState() {
    super.initState();
    // Log initial dashboard view after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logScreenView('Dashboard');
    });
  }

  /// Get the list of accessible menu items for the current user
  List<Map<String, dynamic>> _getAccessibleMenuItems(AuthServiceHttp authService) {
    return _menuConfig.where((item) {
      final permission = item['permission'] as String?;
      return permission == null || authService.hasPermission(permission);
    }).toList();
  }

  /// Get the screen widget for the given menu index
  Widget _getScreenForIndex(int index, List<Map<String, dynamic>> accessibleItems) {
    if (index < 0 || index >= accessibleItems.length) {
      return const DashboardOverview();
    }
    
    final label = accessibleItems[index]['label'] as String;
    switch (label) {
      case 'Dashboard':
        return const DashboardOverview();
      case 'ARTA Configuration':
        return const ArtaConfigurationScreen();
      case 'User Management':
        return const UserManagementScreen();
      case 'Detailed Analytics':
        return const DetailedAnalyticsScreen();
      case 'Data Exports':
        return const DataExportsScreen();
      case 'Audit Log':
        return const AuditLogScreen();
      case 'Settings':
        return const SettingsScreen();
      default:
        return const DashboardOverview();
    }
  }

  /// Log screen view to audit log
  void _logScreenView(String label) {
    try {
      final auditService = Provider.of<AuditLogServiceHttp>(context, listen: false);
      final authService = Provider.of<AuthServiceHttp>(context, listen: false);
      final actor = authService.currentUser;
      
      switch (label) {
        case 'Dashboard':
          auditService.logDashboardViewed(actor: actor);
          break;
        case 'Detailed Analytics':
          auditService.logAnalyticsViewed(actor: actor);
          break;
        case 'User Management':
          auditService.logUserListViewed(actor: actor);
          break;
        case 'Audit Log':
          auditService.logAuditLogViewed(actor: actor);
          break;
        case 'Data Exports':
          auditService.logDataExportsViewed(actor: actor);
          break;
        case 'ARTA Configuration':
          auditService.logArtaConfigViewed(actor: actor);
          break;
        case 'Settings':
          auditService.logSettingsViewed(actor: actor);
          break;
      }
    } catch (_) {
      // Silent fail - audit logging is non-critical
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final authService = context.watch<AuthServiceHttp>();
    final accessibleMenuItems = _getAccessibleMenuItems(authService);
    
    // Ensure selected index is within bounds
    if (_selectedIndex >= accessibleMenuItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: Stack(
        children: [
          // background image with overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/city_bg2.png'),
                  fit: BoxFit.cover,
                  // Removed heavy color filter to let the image show through more naturally as requested
                  // but kept a very slight tint for text readability if needed, or removed entirely.
                  // User asked for "white background should be remove... so they are like bricks and the background should be the city_bg2"
                ),
              ),
              child: Container(
                color: Colors.black.withValues(alpha: 0.1), // Very subtle overlay
              ),
            ),
          ),
          // content row
          Row(
            children: [
          // Sidebar
        Container(
          width: isDesktop ? 250 : 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                brandRed,
                Colors.red.shade900,
              ],
              ),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance,
                          color: brandRed,
                          size: 24,
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CITY GOVERNMENT OF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'VALENZUELA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 20),
                // Menu items - dynamically generated based on user permissions
                ...List.generate(accessibleMenuItems.length, (index) {
                  final item = accessibleMenuItems[index];
                  return _buildMenuItem(
                    index,
                    item['icon'] as IconData,
                    item['label'] as String,
                    isDesktop,
                    accessibleMenuItems.length,
                  );
                }),
                const Spacer(),
                // Bottom menu - Sign out (always visible)
                _buildMenuItem(-1, Icons.exit_to_app, 'Sign Out', isDesktop, accessibleMenuItems.length),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
               color: Colors.transparent, // Transparent to show background
               child: _getScreenForIndex(_selectedIndex, accessibleMenuItems),
            ),
          ),
            ], // end Row children
          ), // end Row
        ], // end Stack children
      ), // end Stack (body)
    ); // end Scaffold
  }

  Widget _buildMenuItem(int index, IconData icon, String label, bool isDesktop, int totalItems) {
    // index == -1 is used for Sign Out button
    final isSignOut = index == -1;
    final isSelected = !isSignOut && _selectedIndex == index;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.white.withValues(alpha: 0.1),
            splashColor: Colors.white.withValues(alpha: 0.2),
            onTap: () {
              if (isSignOut) {
                // Sign out - logout and navigate to admin login
                context.read<AuthServiceHttp>().logout();
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/admin/login',
                  (route) => false, // Clear all routes for security
                );
              } else if (index >= 0 && index < totalItems) {
                // Log screen view to audit log
                _logScreenView(label);
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 8,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dashboard Overview
class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    
    // Start real-time listener when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackService = context.read<FeedbackServiceHttp>();
      // Start real-time updates if not already listening
      if (!feedbackService.isListening) {
        feedbackService.startRealtimeUpdates();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedbackServiceHttp>(
      builder: (context, feedbackService, child) {
        final stats = feedbackService.dashboardStats;
        
        return Container(
      color: Colors.transparent, // Transparent to show background
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                final isMediumScreen = constraints.maxWidth < 900;
                
                return Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           RichText(
                            text: TextSpan(
                              style: AdminTheme.headingXL(
                                color: Colors.white,
                              ).copyWith(fontSize: isSmallScreen ? 24 : 32),
                              children: const <TextSpan>[
                                TextSpan(
                                  text: 'ARTA ',
                                  style: TextStyle(color: Colors.amber),
                                ),
                                TextSpan(
                                  text: 'DASHBOARD',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Client Satisfaction Measurement Overview',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Real-time status indicator
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Connection status indicator
                          const ConnectionStatusIndicator(showWhenOnline: false),
                          // Real-time indicator
                          if (feedbackService.isListening)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isMediumScreen ? 'Live' : 'Live Updates',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            // Stats Cards with staggered animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: LayoutBuilder(
                  builder: (context, outerConstraints) {
                    final isSmallScreen = outerConstraints.maxWidth < 600;
                    final horizontalPadding = isSmallScreen ? 16.0 : 32.0;
                    
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 1200
                              ? 4
                              : constraints.maxWidth > 800
                                  ? 2
                                  : 1;
                          
                          // Calculate aspect ratio based on available width and column count
                          final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
                          // Target card height of ~140px for good proportions
                          final targetHeight = 140.0;
                          final aspectRatio = cardWidth / targetHeight;
                          
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: aspectRatio.clamp(1.5, 3.5),
                        children: [
                          _buildAnimatedStatCard(
                            'TOTAL RESPONSES',
                            stats?.totalResponsesFormatted ?? '0',
                            'Real-time data from Firestore',
                            Icons.people,
                            Colors.blue.shade50,
                            brandBlue,
                            0,
                          ),
                          _buildAnimatedStatCard(
                            'AVG. SATISFACTION',
                            stats?.avgSatisfactionFormatted ?? '0/5',
                            'Based on SQD0 ratings',
                            Icons.star,
                            Colors.amber.shade50,
                            Colors.amber.shade800,
                            1,
                          ),
                          _buildAnimatedStatCard(
                            'COMPLETION RATE',
                            stats?.completionRateFormatted ?? '0%',
                            'Surveys with all required fields',
                            Icons.check_circle,
                            Colors.green.shade50,
                            Colors.green,
                            2,
                          ),
                          _buildAnimatedStatCard(
                            'NEGATIVE FEEDBACK',
                            stats?.negativeRateFormatted ?? '0%',
                            'Rating ≤ 2 out of 5',
                            Icons.warning,
                            Colors.red.shade50,
                            brandRed,
                            3,
                          ),
                          ],
                        );
                      },
                    ),
                  );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Charts - responsive layout
            LayoutBuilder(
              builder: (context, outerConstraints) {
                final isSmallScreen = outerConstraints.maxWidth < 600;
                final horizontalPadding = isSmallScreen ? 16.0 : 32.0;
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildWeeklyTrendsCard(stats?.weeklyTrends ?? {}),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildSatisfactionDistribution(stats?.satisfactionDistribution ?? {}),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Column(
                          children: [
                            _buildWeeklyTrendsCard(stats?.weeklyTrends ?? {}),
                            const SizedBox(height: 16),
                            _buildSatisfactionDistribution(stats?.satisfactionDistribution ?? {}),
                          ],
                        );
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildAnimatedStatCard(String title, String value, String change, IconData icon, Color bgColor, Color iconColor, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: _buildStatCard(title, value, change, icon, bgColor, iconColor),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String change, IconData icon, Color bgColor, Color iconColor) {
    return _HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: brandBlue,
              ),
            ),
            Text(
              change,
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendsCard(Map<String, int> weeklyTrends) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxY = weeklyTrends.values.isEmpty 
        ? 10.0 
        : (weeklyTrends.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble();
    
    return _HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WEEKLY RESPONSE TRENDS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: brandBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Survey responses over the last 7 days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: weeklyTrends.isEmpty
                  ? Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${days[group.x]}: ${rod.toY.toInt()} responses',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: days.asMap().entries.map((entry) {
                    final count = weeklyTrends[entry.value] ?? 0;
                    return BarChartGroupData(
                      x: entry.key, 
                      barRods: [BarChartRodData(toY: count.toDouble(), color: brandBlue, width: 16, borderRadius: BorderRadius.circular(4))],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSatisfactionDistribution(Map<String, double> distribution) {
    final verySatisfied = distribution['Very Satisfied'] ?? 0;
    final satisfied = distribution['Satisfied'] ?? 0;
    final neutral = distribution['Neutral'] ?? 0;
    final dissatisfied = distribution['Dissatisfied'] ?? 0;
    
    final hasData = verySatisfied > 0 || satisfied > 0 || neutral > 0 || dissatisfied > 0;
    
    return _HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SATISFACTION DISTRIBUTION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: brandBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Overall client satisfaction ratings',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: !hasData
                  ? Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                  sections: [
                    if (verySatisfied > 0)
                    PieChartSectionData(
                      value: verySatisfied,
                      title: '${verySatisfied.toStringAsFixed(0)}%',
                      color: Colors.green,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      titlePositionPercentageOffset: 0.55,
                    ),
                    if (satisfied > 0)
                    PieChartSectionData(
                      value: satisfied,
                      title: '${satisfied.toStringAsFixed(0)}%',
                      color: Colors.blue,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      titlePositionPercentageOffset: 0.55,
                    ),
                    if (neutral > 0)
                    PieChartSectionData(
                      value: neutral,
                      title: '${neutral.toStringAsFixed(0)}%',
                      color: Colors.orange,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      titlePositionPercentageOffset: 0.55,
                    ),
                    if (dissatisfied > 0)
                    PieChartSectionData(
                      value: dissatisfied,
                      title: '${dissatisfied.toStringAsFixed(0)}%',
                      color: Colors.red,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      titlePositionPercentageOffset: 0.55,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (verySatisfied > 0) _buildLegendItem('Very Satisfied', Colors.green),
                if (satisfied > 0) _buildLegendItem('Satisfied', Colors.blue),
                if (neutral > 0) _buildLegendItem('Neutral', Colors.orange),
                if (dissatisfied > 0) _buildLegendItem('Dissatisfied', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

// Hover Card Widget with elevation and scale animation
class _HoverCard extends StatefulWidget {
  final Widget child;
  
  const _HoverCard({required this.child});
  
  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? Colors.blue.shade200 : Colors.grey.shade200,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

// User Management Screen - Now fully functional with Firestore
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userService = context.read<UserManagementServiceHttp>();
      if (!userService.isListening) {
        userService.startRealtimeUpdates();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Administrator':
        return Colors.red;
      case 'Editor':
        return Colors.purple;
      case 'Analyst/Viewer':
      case 'Viewer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Inactive':
        return Colors.grey;
      case 'Suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserManagementServiceHttp>(
      builder: (context, userService, child) {
        final users = userService.users;
        final isLoading = userService.isLoading;

        return Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;
                  final isMediumScreen = constraints.maxWidth < 900;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AdminTheme.headingXL(
                            color: Colors.white,
                          ).copyWith(fontSize: isSmallScreen ? 24 : 32),
                          children: const <TextSpan>[
                            TextSpan(text: 'USER ', style: TextStyle(color: Colors.amber)),
                            TextSpan(text: 'MANAGEMENT', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage system access and permissions',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
                      ),
                      const SizedBox(height: 32),
                  
                  // Users table
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SYSTEM USERS',
                                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.bold, color: brandBlue),
                                    ),
                                    if (!isSmallScreen)
                                      Text(
                                        'Manage admin users and their access permissions',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showAddUserDialog(context, userService),
                                icon: Icon(Icons.add, size: isSmallScreen ? 16 : 20),
                                label: Text(isSmallScreen ? 'Add' : 'Add User'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandBlue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Search and filter
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search users...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  onChanged: (value) {
                                    userService.setSearchQuery(value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: () => _showUserFilterDialog(context, userService),
                                icon: const Icon(Icons.filter_list),
                                label: Text(userService.filterRole != null || userService.filterStatus != null 
                                    ? 'Filtered' : 'Filter'),
                              ),
                              if (userService.filterRole != null || userService.filterStatus != null || userService.searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.red),
                                  tooltip: 'Clear filters',
                                  onPressed: () {
                                    _searchController.clear();
                                    userService.clearFilters();
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // User list
                          if (isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (users.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text(
                                      userService.searchQuery.isNotEmpty || userService.filterRole != null
                                          ? 'No users match your search/filter'
                                          : 'No users found',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...users.map((user) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: isMediumScreen 
                                  ? _buildUserItemCompact(context, user, userService)
                                  : _buildUserItem(context, user, userService),
                            )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Role cards - use LayoutBuilder from parent constraints
                  LayoutBuilder(
                    builder: (context, roleConstraints) {
                      final crossAxisCount = roleConstraints.maxWidth > 600 ? 2 : 1;
                      // Calculate aspect ratio dynamically
                      final cardWidth = (roleConstraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
                      final targetHeight = 100.0;
                      final aspectRatio = (cardWidth / targetHeight).clamp(2.0, 4.0);
                      
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                        children: [
                          _buildRoleCard('ADMINISTRATOR', '${userService.administratorCount} Active', 'Full System Access', Icons.admin_panel_settings, Colors.red),
                          _buildRoleCard('VIEWER', '${userService.analystCount} Active', 'View Reports & Analytics', Icons.analytics, Colors.green),
                        ],
                      );
                    },
                  ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCard(String title, String value, String sub, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 200;
        final iconSize = isCompact ? 20.0 : 24.0;
        final iconPadding = isCompact ? 8.0 : 12.0;
        final titleSize = isCompact ? 10.0 : 12.0;
        final valueSize = isCompact ? 14.0 : 18.0;
        final subSize = isCompact ? 9.0 : 11.0;
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                SizedBox(width: isCompact ? 8 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
                      Text(value, style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.bold, color: brandBlue), overflow: TextOverflow.ellipsis),
                      Text(sub, style: TextStyle(fontSize: subSize, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis, maxLines: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserItem(BuildContext context, SystemUser user, UserManagementServiceHttp userService) {
    final roleColor = _getRoleColor(user.role);
    final statusColor = _getStatusColor(user.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: brandBlue,
            radius: 20,
            child: Text(user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(user.role, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: roleColor)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(user.department, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(user.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleUserAction(context, action, user, userService),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
              PopupMenuItem(
                value: user.status == 'Active' ? 'deactivate' : 'activate',
                child: Row(children: [
                  Icon(user.status == 'Active' ? Icons.block : Icons.check_circle, size: 18),
                  const SizedBox(width: 8),
                  Text(user.status == 'Active' ? 'Deactivate' : 'Activate'),
                ]),
              ),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
    );
  }

  // Compact version of user item for smaller screens
  Widget _buildUserItemCompact(BuildContext context, SystemUser user, UserManagementServiceHttp userService) {
    final roleColor = _getRoleColor(user.role);
    final statusColor = _getStatusColor(user.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar, Name, Menu
          Row(
            children: [
              CircleAvatar(
                backgroundColor: brandBlue,
                radius: 18,
                child: Text(user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(user.email, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) => _handleUserAction(context, action, user, userService),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                  PopupMenuItem(
                    value: user.status == 'Active' ? 'deactivate' : 'activate',
                    child: Row(children: [
                      Icon(user.status == 'Active' ? Icons.block : Icons.check_circle, size: 18),
                      const SizedBox(width: 8),
                      Text(user.status == 'Active' ? 'Deactivate' : 'Activate'),
                    ]),
                  ),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bottom row: Role, Department, Status badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(user.role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: roleColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(user.department, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(user.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleUserAction(BuildContext context, String action, SystemUser user, UserManagementServiceHttp userService) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    switch (action) {
      case 'edit':
        _showEditUserDialog(context, user, userService);
        break;
      case 'activate':
        final success = await userService.setUserStatus(user.id, 'Active');
        if (success) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('${user.name} activated'), backgroundColor: Colors.green));
        }
        break;
      case 'deactivate':
        final success = await userService.setUserStatus(user.id, 'Inactive');
        if (success) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('${user.name} deactivated'), backgroundColor: Colors.orange));
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete User?'),
            content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final success = await userService.deleteUser(user.id, userName: user.name, userEmail: user.email);
          if (success) {
            scaffoldMessenger.showSnackBar(SnackBar(content: Text('${user.name} deleted'), backgroundColor: Colors.red));
          } else {
            scaffoldMessenger.showSnackBar(SnackBar(
              content: Text(userService.error ?? 'Failed to delete user'),
              backgroundColor: Colors.red,
            ));
          }
        }
        break;
    }
  }

  Future<void> _showAddUserDialog(BuildContext context, UserManagementServiceHttp userService) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String department = '';
    String password = '';
    String selectedRole = 'Analyst/Viewer';
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add New User', style: AdminTheme.dialogTitle(color: brandBlue)),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.person)),
                          validator: (value) => value!.isEmpty ? 'Please enter name' : null,
                          onSaved: (val) => name = val!,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.email)),
                          validator: (value) => !value!.contains('@') ? 'Invalid email' : null,
                          onSaved: (val) => email = val!,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter password';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                          onSaved: (val) => password = val!,
                          onChanged: (val) => password = val,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          obscureText: obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please confirm password';
                            if (value != password) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Department', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.business)),
                          validator: (value) => value!.isEmpty ? 'Please enter department' : null,
                          onSaved: (val) => department = val!,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: InputDecoration(labelText: 'User Role', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.security)),
                          items: ['Administrator', 'Editor', 'Analyst/Viewer'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                          onChanged: (val) => setState(() => selectedRole = val!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(dialogContext);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final success = await userService.addUser(name: name, email: email, role: selectedRole, department: department, password: password);
                      if (success) {
                        scaffoldMessenger.showSnackBar(SnackBar(content: Text('User "$name" added as $selectedRole'), backgroundColor: Colors.green));
                      } else {
                        scaffoldMessenger.showSnackBar(SnackBar(content: Text(userService.error ?? 'Failed to add user'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: brandBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Add User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditUserDialog(BuildContext context, SystemUser user, UserManagementServiceHttp userService) async {
    final formKey = GlobalKey<FormState>();
    String name = user.name;
    String email = user.email;
    String department = user.department;
    String selectedRole = user.role;
    String selectedStatus = user.status;

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Edit User', style: AdminTheme.dialogTitle(color: brandBlue)),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.person)),
                        validator: (value) => value!.isEmpty ? 'Please enter name' : null,
                        onSaved: (val) => name = val!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: email,
                        decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.email)),
                        validator: (value) => !value!.contains('@') ? 'Invalid email' : null,
                        onSaved: (val) => email = val!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: department,
                        decoration: InputDecoration(labelText: 'Department', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.business)),
                        validator: (value) => value!.isEmpty ? 'Please enter department' : null,
                        onSaved: (val) => department = val!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: InputDecoration(labelText: 'User Role', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.security)),
                        items: ['Administrator', 'Editor', 'Analyst/Viewer'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                        onChanged: (val) => setState(() => selectedRole = val!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.check_circle)),
                        items: ['Active', 'Inactive', 'Suspended'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => selectedStatus = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(dialogContext);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final updatedUser = user.copyWith(name: name, email: email, role: selectedRole, department: department, status: selectedStatus);
                      final success = await userService.updateUser(updatedUser);
                      if (success) {
                        scaffoldMessenger.showSnackBar(SnackBar(content: Text('User "$name" updated'), backgroundColor: Colors.green));
                      } else {
                        scaffoldMessenger.showSnackBar(SnackBar(content: Text(userService.error ?? 'Failed to update user'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: brandBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showUserFilterDialog(BuildContext context, UserManagementServiceHttp userService) async {
    String? selectedRole = userService.filterRole;
    String? selectedStatus = userService.filterStatus;

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: brandBlue),
                  const SizedBox(width: 12),
                  Text('Filter Users', style: AdminTheme.dialogTitle(color: brandBlue)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(labelText: 'Role', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.security)),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Roles')),
                        DropdownMenuItem(value: 'Administrator', child: Text('Administrator')),
                        DropdownMenuItem(value: 'Analyst/Viewer', child: Text('Viewer')),
                      ],
                      onChanged: (val) => setState(() => selectedRole = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.check_circle_outline)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Statuses')),
                        ...['Active', 'Inactive', 'Suspended'].map((status) => DropdownMenuItem(value: status, child: Text(status))),
                      ],
                      onChanged: (val) => setState(() => selectedStatus = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedRole = null;
                      selectedStatus = null;
                    });
                  },
                  child: Text('Clear All', style: TextStyle(color: Colors.red.shade600)),
                ),
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    userService.setFilters(role: selectedRole, status: selectedStatus);
                    if (selectedRole != null || selectedStatus != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Filter applied'), backgroundColor: Colors.blue.shade600, behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: brandBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Apply Filter'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Data Exports Screen
class DataExportsScreen extends StatefulWidget {
  const DataExportsScreen({super.key});

  @override
  State<DataExportsScreen> createState() => _DataExportsScreenState();
}

class _DataExportsScreenState extends State<DataExportsScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedbackServiceHttp>().fetchAllFeedbacks();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getCCAwareness(int? cc0Rating) {
    if (cc0Rating == null) return 'N/A';
    return cc0Rating >= 3 ? 'Aware' : 'Not Aware';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedbackServiceHttp>(
      builder: (context, feedbackService, child) {
        final stats = feedbackService.dashboardStats;
        final recentFeedbacks = stats?.recentFeedbacks ?? [];
        final isLoading = feedbackService.isLoading;

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;
              final isMediumScreen = constraints.maxWidth < 900;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AdminTheme.headingXL(
                        color: Colors.white,
                      ).copyWith(fontSize: isSmallScreen ? 24 : 32),
                      children: const <TextSpan>[
                        TextSpan(
                          text: 'DATA ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'EXPORTS',
                          style: TextStyle(color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download survey data and reports',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
              
              // Export Cards - responsive grid
              LayoutBuilder(
                builder: (context, cardConstraints) {
                   final crossAxisCount = cardConstraints.maxWidth > 900 ? 3 : cardConstraints.maxWidth > 500 ? 2 : 1;
                   // Calculate dynamic aspect ratio
                   final cardWidth = (cardConstraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
                   final targetHeight = 180.0;
                   final aspectRatio = (cardWidth / targetHeight).clamp(1.2, 2.5);
                   
                   return GridView.count(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     crossAxisCount: crossAxisCount,
                     crossAxisSpacing: 16,
                     mainAxisSpacing: 16,
                     childAspectRatio: aspectRatio,
                     children: [
                       _buildExportCard(context, feedbackService, 'ARTA Compliance Report', 'PDF Format', Icons.picture_as_pdf, Colors.red, isPdf: true),
                       _buildExportCard(context, feedbackService, 'Raw Data Export', 'CSV Format', Icons.table_chart, Colors.green, isCsv: true),
                       _buildExportCard(context, feedbackService, 'JSON Data Export', 'JSON Format', Icons.code, Colors.blue, isJson: true),
                     ],
                   );
                },
              ),
              const SizedBox(height: 32),

              // Recent Respondents Table - responsive
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row - responsive
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECENT RESPONDENTS',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: brandBlue
                                ),
                              ),
                              if (!isSmallScreen)
                                Text(
                                  'Latest survey submissions from Firestore',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: isLoading ? null : () {
                              feedbackService.refresh();
                            },
                            icon: isLoading 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.refresh, size: 16),
                            label: Text(isLoading ? 'Loading...' : 'Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Table - use different layouts based on screen size
                      if (isMediumScreen)
                        // Compact card layout for smaller screens
                        _buildCompactRespondentsList(recentFeedbacks, isLoading)
                      else
                        // Full table layout for larger screens
                        Column(
                          children: [
                            // Table Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('CLIENT TYPE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12))),
                                  Expanded(flex: 3, child: Text('SERVICE AVAILED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('CC AWARENESS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('SATISFACTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12))),
                                ],
                              ),
                            ),
                            const Divider(),
                            // Table Rows
                            if (recentFeedbacks.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    isLoading ? 'Loading data...' : 'No feedback data available',
                                    style: TextStyle(color: Colors.grey.shade400),
                                  ),
                                ),
                              )
                            else
                              ...recentFeedbacks.map((feedback) => _buildRespondentRow(
                                feedback.id?.substring(0, 6) ?? 'N/A',
                                _formatDate(feedback.submittedAt ?? feedback.date),
                                feedback.clientType ?? 'N/A',
                                feedback.serviceAvailed ?? 'N/A',
                                _getCCAwareness(feedback.cc0Rating),
                                feedback.sqd0Rating ?? 0,
                              )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
                ],
              );
            },
          ),
        ),
      ),
    );
      },
    );
  }

  // Compact respondents list for smaller screens
  Widget _buildCompactRespondentsList(List<dynamic> feedbacks, bool isLoading) {
    if (feedbacks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            isLoading ? 'Loading data...' : 'No feedback data available',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      );
    }
    
    return Column(
      children: feedbacks.map((feedback) {
        final score = feedback.sqd0Rating ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: ID, Date, Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${feedback.id?.substring(0, 6) ?? "N/A"}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _formatDate(feedback.submittedAt ?? feedback.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('$score/5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Service availed
              Text(
                feedback.serviceAvailed ?? 'N/A',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Bottom row: Client type, CC Awareness
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      feedback.clientType ?? 'N/A',
                      style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getCCAwareness(feedback.cc0Rating),
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExportCard(BuildContext context, FeedbackServiceHttp feedbackService, String title, String sub, IconData icon, Color color, {bool isPdf = false, bool isCsv = false, bool isJson = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 180;
        final iconSize = isCompact ? 22.0 : 28.0;
        final iconPadding = isCompact ? 8.0 : 12.0;
        final titleSize = isCompact ? 13.0 : 16.0;
        final subSize = isCompact ? 10.0 : 12.0;
        final cardPadding = isCompact ? 16.0 : 24.0;
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                const Spacer(),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 2),
                      const SizedBox(height: 4),
                      Text(sub, style: TextStyle(fontSize: subSize, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      ExportType? preselectedType;
                      if (isPdf) {
                        preselectedType = ExportType.pdfCompliance;
                      } else if (isCsv) {
                        preselectedType = ExportType.csv;
                      } else if (isJson) {
                        preselectedType = ExportType.json;
                      }
                      showExportFilterDialog(
                        context,
                        feedbackService,
                        preselectedType: preselectedType,
                      );
                    },
                    icon: Icon(Icons.download, size: isCompact ? 14 : 16),
                    label: Text(isCompact ? 'Export' : 'Generate', style: TextStyle(fontSize: isCompact ? 12 : 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withValues(alpha: 0.5)),
                      padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 12),
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

  Widget _buildRespondentRow(String id, String date, String type, String service, String cc, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(type, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 3, child: Text(service, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(cc, style: const TextStyle(fontSize: 13))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('$score/5', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
