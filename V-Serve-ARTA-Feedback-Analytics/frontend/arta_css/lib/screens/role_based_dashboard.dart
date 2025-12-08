import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_services.dart';
import '../../widgets/role_based_widget.dart';
import '../../models/user_model.dart'; // adjust if different

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const SurveyManagementApp());
}

class SurveyManagementApp extends StatelessWidget {
  const SurveyManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Survey Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const LoginScreen(),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              margin: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      const Text(
                        'CITY GOVERNMENT OF VALENZUELA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        'HELP US SERVE YOU BETTER!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      RichText(
                        text: const TextSpan(
                          text: 'Welcome back, ',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: 'Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            TextSpan(text: '!'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Username field
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your username here',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter your password here',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardOverview(),
    const SurveyManagementScreen(),
    const UserManagementScreen(),
    const AnalyticsScreen(),
    const DataExportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: isDesktop ? 250 : 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade700,
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
                        child: const Icon(
                          Icons.account_balance,
                          color: Colors.red,
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
                _buildMenuItem(1, Icons.poll, 'Survey Management', isDesktop),
                _buildMenuItem(2, Icons.people, 'User Management', isDesktop),
                _buildMenuItem(3, Icons.analytics, 'Analytics', isDesktop),
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
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label, bool isDesktop) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
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
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade600,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(32),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADMIN DASHBOARD',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Client Satisfaction Survey Management System',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
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
                        '2,847',
                        '+12.5% from last month',
                        Icons.people,
                        Colors.blue.shade50,
                      ),
                      _buildStatCard(
                        'ACTIVE SURVEYS',
                        '12',
                        '3 published this week',
                        Icons.description,
                        Colors.blue.shade50,
                      ),
                      _buildStatCard(
                        'COMPLETION RATE',
                        '87.3%',
                        '+2.1% from last month',
                        Icons.trending_up,
                        Colors.blue.shade50,
                      ),
                      _buildStatCard(
                        'AVG. SATISFACTION',
                        '4.2/5',
                        '+0.3 from last month',
                        Icons.star,
                        Colors.blue.shade50,
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
                          child: _buildWeeklyTrendsCard(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildSatisfactionDistribution(),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildWeeklyTrendsCard(),
                        const SizedBox(height: 16),
                        _buildSatisfactionDistribution(),
                      ],
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            // Recent Surveys
            Padding(
              padding: const EdgeInsets.all(32),
              child: _buildRecentSurveys(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String change, IconData icon, Color bgColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                Icon(icon, color: Colors.blue, size: 20),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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

  Widget _buildWeeklyTrendsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WEEKLY RESPONSE TRENDS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Survey responses and completion rates over the last 7 days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
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
                    horizontalInterval: 25,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 65, color: const Color(0xFF003366))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 78, color: const Color(0xFF003366))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 52, color: const Color(0xFF003366))]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 90, color: const Color(0xFF003366))]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 85, color: const Color(0xFF003366))]),
                    BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 45, color: const Color(0xFF003366))]),
                    BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 38, color: const Color(0xFF003366))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSatisfactionDistribution() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SATISFACTION DISTRIBUTION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: 45,
                      title: 'Very Satisfied\n45%',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 35,
                      title: 'Satisfied\n35%',
                      color: Colors.blue,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 12,
                      title: 'Neutral\n12%',
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 5,
                      title: 'Dissatisfied\n5%',
                      color: Colors.pink,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 3,
                      title: 'Very\nDissatisfied\n3%',
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

  Widget _buildRecentSurveys() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RECENT SURVEYS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview of recently created and active surveys',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            _buildSurveyItem(
              'Q4 2024 Client Satisfaction',
              '234 responses • 87% completion rate',
              'active',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyItem(String title, String subtitle, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: statusColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
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
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// Survey Management Screen
class SurveyManagementScreen extends StatelessWidget {
  const SurveyManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade300, Colors.blue.shade600],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADMIN DASHBOARD',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Client Satisfaction Survey Management System',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              const Text(
                                'SURVEY LIBRARY',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Manage all your surveys from one central location',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                            label: const Text('Create Survey'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
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
                              decoration: InputDecoration(
                                hintText: 'Search surveys...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.filter_list),
                            label: const Text('Filter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Survey list
                      _buildSurveyListItem(
                        'Q4 2024 Client Satisfaction Survey',
                        'Quarterly assessment of client satisfaction across all departments',
                        'Active',
                        Colors.green,
                        234,
                        87,
                        15,
                        '1/20/2024',
                      ),
                      const SizedBox(height: 12),
                      _buildSurveyListItem(
                        'Department Feedback Survey',
                        'Service feedback collection for service improvement',
                        'Active',
                        Colors.green,
                        156,
                        92,
                        8,
                        '1/18/2024',
                      ),
                      const SizedBox(height: 12),
                      _buildSurveyListItem(
                        'Service Quality Assessment',
                        'Detailed assessment of service quality metrics',
                        'Paused',
                        Colors.orange,
                        89,
                        74,
                        22,
                        '1/12/2024',
                      ),
                      const SizedBox(height: 12),
                      _buildSurveyListItem(
                        'Annual Client Review',
                        'Comprehensive annual review of client experience',
                        'Completed',
                        Colors.blue,
                        445,
                        95,
                        35,
                        '12/31/2023',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyListItem(
    String title,
    String description,
    String status,
    Color statusColor,
    int responses,
    int completion,
    int questions,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
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
          _buildSurveyMetric(Icons.people, responses.toString()),
          const SizedBox(width: 16),
          _buildSurveyMetric(Icons.bar_chart, '$completion%'),
          const SizedBox(width: 16),
          _buildSurveyMetric(Icons.quiz, '$questions (${questions ~/ 3} branches)'),
          const SizedBox(width: 16),
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// User Management Screen
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade300, Colors.blue.shade600],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADMIN DASHBOARD',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Client Satisfaction Survey Management System',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              // Role cards
              LayoutBuilder(
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
                      _buildRoleCard('ADMINISTRATOR', '2,847', '+12.5% from last month'),
                      _buildRoleCard('EDITOR', '12', '3 published this week'),
                      _buildRoleCard('ANALYST', '87.3%', '+2.1% from last month'),
                      _buildRoleCard('VIEWER', '4.2/5', '+0.3 from last month'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Users table
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              const Text(
                                'SYSTEM USERS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Manage admin users and their access permissions',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                            label: const Text('Add User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
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
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.filter_list),
                            label: const Text('Filter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // User list
                      _buildUserItem(
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
                      const SizedBox(height: 12),
                      _buildUserItem(
                        'CR',
                        'Carlos Rodriguez',
                        'carlos.rodriguez@valenzuela.gov.ph',
                        'Analyst',
                        Colors.green,
                        'Data Analytics',
                        'Active',
                        Colors.green,
                        'Jan 22, 2024',
                        'Jan 5, 2024',
                      ),
                      const SizedBox(height: 12),
                      _buildUserItem(
                        'AG',
                        'Anna Garcia',
                        'anna.garcia@valenzuela.gov.ph',
                        'Viewer',
                        Colors.grey,
                        'Building Permits',
                        'Active',
                        Colors.green,
                        'Jan 20, 2024',
                        'Jan 10, 2024',
                      ),
                      const SizedBox(height: 12),
                      _buildUserItem(
                        'MT',
                        'Miguel Torres',
                        'miguel.torres@valenzuela.gov.ph',
                        'Editor',
                        Colors.purple,
                        'Civil Registry',
                        'Suspended',
                        Colors.red,
                        'Jan 15, 2024',
                        'Oct 20, 2023',
                      ),
                      const SizedBox(height: 24),
                      // Permissions matrix
                      const Text(
                        'Role Permissions Matrix',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overview of permissions assigned to each role',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      _buildPermissionsTable(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, String value, String change) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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

  Widget _buildUserItem(
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
            backgroundColor: Colors.blue.shade700,
            radius: 24,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
                color: roleColor.withOpacity(0.1),
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
              color: statusColor.withOpacity(0.1),
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
          Text(
            lastLogin,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Text(
            created,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {},
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _buildTableHeader('Permission'),
            _buildTableHeader('Admin'),
            _buildTableHeader('Editor'),
            _buildTableHeader('Analyst'),
            _buildTableHeader('Viewer'),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('Create Surveys'),
            _buildTableCheck(true),
            _buildTableCheck(true),
            _buildTableCheck(false),
            _buildTableCheck(false),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('Edit Surveys'),
            _buildTableCheck(true),
            _buildTableCheck(true),
            _buildTableCheck(false),
            _buildTableCheck(false),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('View Analytics'),
            _buildTableCheck(true),
            _buildTableCheck(true),
            _buildTableCheck(true),
            _buildTableCheck(true),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('Export Data'),
            _buildTableCheck(true),
            _buildTableCheck(true),
            _buildTableCheck(true),
            _buildTableCheck(false),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('Manage Users'),
            _buildTableCheck(true),
            _buildTableCheck(false),
            _buildTableCheck(false),
            _buildTableCheck(false),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildTableCheck(bool allowed) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Icon(
          allowed ? Icons.check : Icons.close,
          color: allowed ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
    );
  }
}

// Analytics Screen
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade300, Colors.blue.shade600],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADMIN DASHBOARD',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Client Satisfaction Survey Management System',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              // Stats
              LayoutBuilder(
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
                      _buildStatCard('TOTAL RESPONSES', '2,847', '+12.5% from last month'),
                      _buildStatCard('ACTIVE SURVEYS', '12', '3 published this week'),
                      _buildStatCard('COMPLETION RATE', '87.3%', '+2.1% from last month'),
                      _buildStatCard('AVG. SATISFACTION', '4.2/5', '+0.3 from last month'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Charts
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Response Trends',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Daily response volume over time',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 2 == 0) {
                                      return Text(
                                        '${value.toInt()}/1/2024',
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 30,
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
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  const FlSpot(0, 50),
                                  const FlSpot(1, 40),
                                  const FlSpot(2, 30),
                                  const FlSpot(3, 75),
                                  const FlSpot(4, 30),
                                  const FlSpot(5, 80),
                                  const FlSpot(6, 90),
                                ],
                                isCurved: true,
                                color: Colors.blue.shade700,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.blue.shade700.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completion Rate Trends',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Survey completion percentage over time',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 2 == 0) {
                                      return Text(
                                        '${value.toInt()}/1/2024',
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}%',
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  const FlSpot(0, 80),
                                  const FlSpot(1, 85),
                                  const FlSpot(2, 80),
                                  const FlSpot(3, 92),
                                  const FlSpot(4, 88),
                                  const FlSpot(5, 75),
                                  const FlSpot(6, 95),
                                  const FlSpot(7, 90),
                                ],
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String change) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
}

// Data Exports Screen
class DataExportsScreen extends StatelessWidget {
  const DataExportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade300, Colors.blue.shade600],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADMIN DASHBOARD',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Client Satisfaction Survey Management System',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              // Stats
              LayoutBuilder(
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
                      _buildStatCard('2,847', '+12.5% from last month'),
                      _buildStatCard('12', '3 published this week'),
                      _buildStatCard('87.3%', '+2.1% from last month'),
                      _buildStatCard('4.2/5', '+0.3 from last month'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Export History
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              const Text(
                                'Export History',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Manage your data exports and download files',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                            label: const Text('New Export'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
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
                              decoration: InputDecoration(
                                hintText: 'Search exports...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.filter_list),
                            label: const Text('Filter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Export items
                      _buildExportItem(
                        'Q4 2024 Client Satisfaction Report',
                        'Jan 22, 2024, 06:30 PM',
                        'PDF',
                        'Q4 2024 Client Satisfaction S...',
                        'completed',
                        Colors.green,
                        '2.4 MB',
                        5,
                        'Feb 22, 2024, 06:30 PM',
                      ),
                      const SizedBox(height: 12),
                      _buildExportItem(
                        'Department Feedback Data Export',
                        'Jan 21, 2024, 10:15 PM',
                        'CSV',
                        'Department Feedback Survey',
                        'completed',
                        Colors.green,
                        '856 KB',
                        12,
                        'Feb 21, 2024, 10:15 PM',
                      ),
                      const SizedBox(height: 12),
                      _buildExportItem(
                        'Service Quality Raw Data',
                        'Jan 22, 2024, 04:45 PM',
                        'JSON',
                        'Service Quality Assessment',
                        'processing',
                        Colors.orange,
                        '-',
                        0,
                        'Never',
                      ),
                      const SizedBox(height: 12),
                      _buildExportItem(
                        'Annual Review Analytics',
                        'Jan 21, 2024, 12:20 AM',
                        'XLSX',
                        'Annual Client Review',
                        'failed',
                        Colors.red,
                        '-',
                        0,
                        'Never',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Quick Export Templates
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Export Templates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pre-configured export options for common use cases',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return Row(
                              children: [
                                Expanded(child: _buildTemplateCard('Weekly Summary (CSV)', 'Complete response data for the last 7 days', Colors.green, Icons.description)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTemplateCard('Monthly Report (PDF)', 'Formatted analytics report for monthly review', Colors.red, Icons.picture_as_pdf)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTemplateCard('Raw Data (JSON)', 'Complete dataset with all metadata', Colors.purple, Icons.data_object)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildTemplateCard('Weekly Summary (CSV)', 'Complete response data for the last 7 days', Colors.green, Icons.description),
                                const SizedBox(height: 16),
                                _buildTemplateCard('Monthly Report (PDF)', 'Formatted analytics report for monthly review', Colors.red, Icons.picture_as_pdf),
                                const SizedBox(height: 16),
                                _buildTemplateCard('Raw Data (JSON)', 'Complete dataset with all metadata', Colors.purple, Icons.data_object),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String change) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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

  Widget _buildExportItem(
    String title,
    String date,
    String format,
    String survey,
    String status,
    Color statusColor,
    String size,
    int downloads,
    String expires,
  ) {
    IconData formatIcon;
    Color formatColor;
    
    switch (format) {
      case 'PDF':
        formatIcon = Icons.picture_as_pdf;
        formatColor = Colors.red;
        break;
      case 'CSV':
        formatIcon = Icons.description;
        formatColor = Colors.green;
        break;
      case 'JSON':
        formatIcon = Icons.data_object;
        formatColor = Colors.purple;
        break;
      case 'XLSX':
        formatIcon = Icons.table_chart;
        formatColor = Colors.blue;
        break;
      default:
        formatIcon = Icons.insert_drive_file;
        formatColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(formatIcon, color: formatColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: formatColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              format,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: formatColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              survey,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'completed'
                      ? Icons.check_circle
                      : status == 'processing'
                          ? Icons.refresh
                          : Icons.error,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 60,
            child: Text(
              size,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 30,
            child: Text(
              downloads.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: Text(
              expires,
              style: TextStyle(
                fontSize: 12,
                color: expires == 'Never' ? Colors.grey : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (status == 'completed') ...[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {},
              color: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
            ),
          ] else if (status == 'processing') ...[
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
            ),
          ],
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {},
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(String title, String description, Color color, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}