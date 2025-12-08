import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/feedback_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_screens.dart';
import '../../services/export_service.dart';
import '../../services/dark_mode_service.dart';
import '../../widgets/dark_mode_overlay.dart';

// NOTE: This file provides screens (DashboardScreen, etc.)
// and no longer contains its own `main()` or a top-level `MaterialApp`.
// The app should use the single top-level `MaterialApp` defined in `main.dart`.
// Login is handled by RoleBasedLoginScreen at '/admin/login'.

// Dashboard Screen with Dark Mode Support
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardOverview(),
    const ArtaConfigurationScreen(),
    const UserManagementScreen(),
    const DetailedAnalyticsScreen(),
    const DataExportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    // Update system brightness for dark mode detection
    final brightness = MediaQuery.of(context).platformBrightness;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DarkModeService>().updateSystemBrightness(brightness);
    });

    // Wrap entire dashboard with DarkModeOverlay for admin-only dark mode
    return DarkModeOverlay(
      child: Scaffold(
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
                // Menu items
                _buildMenuItem(0, Icons.dashboard, 'Dashboard', isDesktop),
                _buildMenuItem(1, Icons.settings_applications, 'ARTA Configuration', isDesktop),
                _buildMenuItem(2, Icons.people, 'User Management', isDesktop),
                _buildMenuItem(3, Icons.analytics, 'Detailed Analytics', isDesktop),
                _buildMenuItem(4, Icons.download, 'Data Exports', isDesktop),
                const Spacer(),
                // Bottom menu
                _buildMenuItem(5, Icons.settings, 'Settings', isDesktop),
                _buildMenuItem(6, Icons.exit_to_app, 'Sign Out', isDesktop),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
               color: Colors.transparent, // Transparent to show background
               child: _screens[_selectedIndex],
            ),
          ),
            ], // end Row children
          ), // end Row
        ], // end Stack children
      ), // end Stack (body)
    ), // end Scaffold
    ); // end DarkModeOverlay
  }

  Widget _buildMenuItem(int index, IconData icon, String label, bool isDesktop) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        title: isDesktop
            ? Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        onTap: () {
          if (index == 6) {
            // Sign out - navigate to admin login
            Navigator.pushReplacementNamed(context, '/admin/login');
          } else if (index == 5) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          } else if (index < 5) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        contentPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 8,
          vertical: 4,
        ),
        minLeadingWidth: 0,
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

class _DashboardOverviewState extends State<DashboardOverview> {
  @override
  void initState() {
    super.initState();
    // Start real-time listener when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackService = context.read<FeedbackService>();
      // Start real-time updates if not already listening
      if (!feedbackService.isListening) {
        feedbackService.startRealtimeUpdates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedbackService>(
      builder: (context, feedbackService, child) {
        final stats = feedbackService.dashboardStats;
        final isLoading = feedbackService.isLoading;
        
        return Container(
      color: Colors.transparent, // Transparent to show background
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       RichText(
                        text: TextSpan(
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Real-time status indicator
                  Row(
                    children: [
                      // Real-time indicator
                      if (feedbackService.isListening)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(right: 12),
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
                              const Text(
                                'Live Updates',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Refresh button (manual refresh)
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : () {
                          feedbackService.refresh();
                        },
                        icon: isLoading 
                            ? const SizedBox(
                                width: 16, 
                                height: 16, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                              )
                            : const Icon(Icons.refresh),
                        label: Text(isLoading ? 'Loading...' : 'Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200
                      ? 4
                      : constraints.maxWidth > 800
                          ? 2
                          : 1;
                  
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2,
                    children: [
                      _buildStatCard(
                        'TOTAL RESPONSES',
                        stats?.totalResponsesFormatted ?? '0',
                        'Real-time data from Firestore',
                        Icons.people,
                        Colors.blue.shade50,
                        brandBlue
                      ),
                      _buildStatCard(
                        'AVG. SATISFACTION',
                        stats?.avgSatisfactionFormatted ?? '0/5',
                        'Based on SQD0 ratings',
                        Icons.star,
                        Colors.amber.shade50,
                        Colors.amber.shade800
                      ),
                      _buildStatCard(
                        'COMPLETION RATE',
                        stats?.completionRateFormatted ?? '0%',
                        'Surveys with all required fields',
                        Icons.check_circle,
                        Colors.green.shade50,
                        Colors.green
                      ),
                      _buildStatCard(
                        'NEGATIVE FEEDBACK',
                        stats?.negativeRateFormatted ?? '0%',
                        'Rating ≤ 2 out of 5',
                        Icons.warning,
                        Colors.red.shade50,
                        brandRed
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Charts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String change, IconData icon, Color bgColor, Color iconColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
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
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
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
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
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
              height: 200,
              child: !hasData
                  ? Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    if (verySatisfied > 0)
                    PieChartSectionData(
                      value: verySatisfied,
                      title: 'Very Satisfied\n${verySatisfied.toStringAsFixed(0)}%',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (satisfied > 0)
                    PieChartSectionData(
                      value: satisfied,
                      title: 'Satisfied\n${satisfied.toStringAsFixed(0)}%',
                      color: Colors.blue,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (neutral > 0)
                    PieChartSectionData(
                      value: neutral,
                      title: 'Neutral\n${neutral.toStringAsFixed(0)}%',
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (dissatisfied > 0)
                    PieChartSectionData(
                      value: dissatisfied,
                      title: 'Dissatisfied\n${dissatisfied.toStringAsFixed(0)}%',
                      color: Colors.red,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// User Management Screen
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: const <TextSpan>[
                    TextSpan(
                      text: 'USER ',
                      style: TextStyle(color: Colors.amber),
                    ),
                    TextSpan(
                      text: 'MANAGEMENT',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage system access and permissions',
                style: TextStyle(fontSize: 16, color: Colors.white),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SYSTEM USERS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: brandBlue
                                ),
                              ),
                              Text(
                                'Manage admin users and their access permissions',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showAddUserDialog(context);
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add User'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandBlue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Search
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search users...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onChanged: (value) {
                                // Search functionality - in a real app, this would filter the user list
                                // For now, just show a snackbar with search term
                                if (value.length >= 3) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Searching for: "$value"'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              _showUserFilterDialog(context);
                            },
                            icon: const Icon(Icons.filter_list),
                            label: const Text('Filter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // User list
                      _buildUserItem(
                        context,
                        'JD',
                        'John Doe',
                        'john.doe@valenzuela.gov.ph',
                        'Administrator',
                        Colors.red,
                        'IT Administration',
                        'Active',
                        Colors.green,
                        'Jan 22, 2024',
                        'Nov 15, 2023',
                      ),
                      const SizedBox(height: 12),
                      _buildUserItem(
                        context,
                        'MS',
                        'Maria Santos',
                        'maria.santos@valenzuela.gov.ph',
                        'Editor',
                        Colors.purple,
                        'Business Licensing',
                        'Active',
                        Colors.green,
                        'Jan 22, 2024',
                        'Dec 1, 2023',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Role cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200
                      ? 3
                      : constraints.maxWidth > 800
                          ? 2
                          : 1;
                  
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _buildRoleCard('ADMINISTRATOR', '3 Active', 'Full System Access', Icons.admin_panel_settings, Colors.red),
                      _buildRoleCard('EDITOR', '12 Active', 'Manage Surveys & Content', Icons.edit_document, Colors.blue),
                      _buildRoleCard('ANALYST / VIEWER', '25 Active', 'View Reports & Analytics', Icons.analytics, Colors.green),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String value, String sub, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: brandBlue,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(
    BuildContext context,
    String initials,
    String name,
    String email,
    String role,
    Color roleColor,
    String department,
    String status,
    Color statusColor,
    String lastLogin,
    String created,
  ) {
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
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                role,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: roleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              department,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
  Future<void> _showAddUserDialog(BuildContext context) async {
    String selectedRole = 'Analyst/Viewer'; // Default
    final formKey = GlobalKey<FormState>();
    String name = '';
    // ignore: unused_local_variable
    String email = '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Add New User',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: brandBlue,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter name' : null,
                        onSaved: (val) => name = val!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: (value) => !value!.contains('@') ? 'Invalid email' : null,
                        onSaved: (val) => email = val!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'User Role',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.security),
                        ),
                        items: ['Administrator', 'Editor', 'Analyst/Viewer']
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedRole = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User "$name" added as $selectedRole'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showUserFilterDialog(BuildContext context) async {
    String? selectedRole;
    String? selectedStatus;
    String? selectedDepartment;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: brandBlue),
                  const SizedBox(width: 12),
                  Text(
                    'Filter Users',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      color: brandBlue,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.security),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Roles')),
                        ...['Administrator', 'Editor', 'Analyst/Viewer']
                            .map((role) => DropdownMenuItem(value: role, child: Text(role))),
                      ],
                      onChanged: (val) => setState(() => selectedRole = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.check_circle_outline),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Statuses')),
                        ...['Active', 'Inactive', 'Pending']
                            .map((status) => DropdownMenuItem(value: status, child: Text(status))),
                      ],
                      onChanged: (val) => setState(() => selectedStatus = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDepartment,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.business),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Departments')),
                        ...['IT Administration', 'Business Licensing', 'Civil Registry', 'Treasury', 'Assessor']
                            .map((dept) => DropdownMenuItem(value: dept, child: Text(dept))),
                      ],
                      onChanged: (val) => setState(() => selectedDepartment = val),
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
                      selectedDepartment = null;
                    });
                  },
                  child: Text('Clear All', style: TextStyle(color: Colors.red.shade600)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final filters = <String>[];
                    if (selectedRole != null) filters.add(selectedRole!);
                    if (selectedStatus != null) filters.add(selectedStatus!);
                    if (selectedDepartment != null) filters.add(selectedDepartment!);
                    
                    if (filters.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Filter applied: ${filters.join(", ")}'),
                          backgroundColor: Colors.blue.shade600,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
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
      context.read<FeedbackService>().fetchAllFeedbacks();
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
    return Consumer<FeedbackService>(
      builder: (context, feedbackService, child) {
        final stats = feedbackService.dashboardStats;
        final recentFeedbacks = stats?.recentFeedbacks ?? [];
        final isLoading = feedbackService.isLoading;

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 32),
              
              // Export Cards
              LayoutBuilder(
                builder: (context, constraints) {
                   final crossAxisCount = constraints.maxWidth > 1000 ? 3 : 1;
                   return GridView.count(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     crossAxisCount: crossAxisCount,
                     crossAxisSpacing: 16,
                     mainAxisSpacing: 16,
                     childAspectRatio: 1.8,
                     children: [
                       _buildExportCard(context, feedbackService, 'ARTA Compliance Report', 'PDF Format', Icons.picture_as_pdf, Colors.red, isPdf: true),
                       _buildExportCard(context, feedbackService, 'Raw Data Export', 'CSV Format', Icons.table_chart, Colors.green, isCsv: true),
                       _buildExportCard(context, feedbackService, 'JSON Data Export', 'JSON Format', Icons.code, Colors.blue, isJson: true),
                     ],
                   );
                },
              ),
              const SizedBox(height: 32),

              // Recent Respondents Table
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECENT RESPONDENTS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: brandBlue
                                ),
                              ),
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
                                : const Icon(Icons.refresh),
                            label: Text(isLoading ? 'Loading...' : 'Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                      // Table Rows from real data
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

  Widget _buildExportCard(BuildContext context, FeedbackService feedbackService, String title, String sub, IconData icon, Color color, {bool isPdf = false, bool isCsv = false, bool isJson = false}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (isPdf) {
                    _showPdfExportDialog(context, feedbackService);
                  } else if (isCsv) {
                    await _exportCsv(context, feedbackService);
                  } else if (isJson) {
                    await _exportJson(context, feedbackService);
                  }
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Generate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, FeedbackService feedbackService) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Generating CSV export...')),
      );
      
      final data = feedbackService.exportFeedbacks();
      if (data.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No data to export'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      // Build CSV rows
      final headers = data.first.keys.toList();
      final rows = <List<dynamic>>[
        headers,
        ...data.map((item) => headers.map((h) => item[h]?.toString() ?? '').toList()),
      ];
      
      final filename = await ExportService.exportCsv('ARTA_Feedback_Data', rows);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('CSV exported: $filename'), backgroundColor: Colors.green),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportJson(BuildContext context, FeedbackService feedbackService) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Generating JSON export...')),
      );
      
      final data = feedbackService.exportFeedbacks();
      if (data.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No data to export'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      final filename = await ExportService.exportJson('ARTA_Feedback_Data', data);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('JSON exported: $filename'), backgroundColor: Colors.green),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPdfExportDialog(BuildContext context, FeedbackService feedbackService) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export PDF Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description, color: Colors.red),
              title: const Text('ARTA Compliance Report'),
              subtitle: const Text('Standard format for ARTA submission'),
              onTap: () async {
                Navigator.pop(dialogContext);
                try {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Generating PDF report...')),
                  );
                  final data = feedbackService.exportFeedbacks();
                  final filename = await ExportService.exportPdf('ARTA_Compliance_Report', data);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('PDF exported: $filename'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Detailed Analysis'),
              subtitle: const Text('Full breakdown of SQD and comments'),
              onTap: () async {
                Navigator.pop(dialogContext);
                try {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Generating detailed analysis...')),
                  );
                  final data = feedbackService.exportFeedbacks();
                  final filename = await ExportService.exportPdf('ARTA_Detailed_Analysis', data);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('PDF exported: $filename'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
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
