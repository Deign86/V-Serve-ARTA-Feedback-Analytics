import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_services.dart';
import '../../../widgets/role_based_widget.dart';
import '../../../models/user_model.dart'; // adjust if different
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_screens.dart';
import '../../services/export_service.dart';

// NOTE: This file provides screens (LoginScreen, DashboardScreen, etc.)
// and no longer contains its own `main()` or a top-level `MaterialApp`.
// The app should use the single top-level `MaterialApp` defined in `main.dart`.

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
              Colors.red.shade900,
              Colors.blue.shade900,
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
                        child: Icon(
                          Icons.account_balance,
                          size: 50,
                          color: brandRed,
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
                        'ARTA FEEDBACK SYSTEM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      RichText(
                        text: TextSpan(
                          text: 'Welcome back, ',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: 'Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: brandRed,
                              ),
                            ),
                            const TextSpan(text: '!'),
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
                            backgroundColor: brandBlue,
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
    const ArtaConfigurationScreen(),
    const UserManagementScreen(),
    const DetailedAnalyticsScreen(),
    const DataExportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

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
                color: Colors.black.withOpacity(0.1), // Very subtle overlay
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
    ); // end Scaffold
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
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // Transparent to show background
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
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
                        brandBlue
                      ),
                      _buildStatCard(
                        'AVG. SATISFACTION',
                        '4.7/5',
                        '+0.1 from last month',
                        Icons.star,
                        Colors.amber.shade50,
                        Colors.amber.shade800
                      ),
                      _buildStatCard(
                        'COMPLETION RATE',
                        '98.2%',
                        '+0.5% from last month',
                        Icons.check_circle,
                        Colors.green.shade50,
                        Colors.green
                      ),
                      _buildStatCard(
                        'NEGATIVE FEEDBACK',
                        '1.2%',
                        '-0.3% from last month',
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
          ],
        ),
      ),
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

  Widget _buildWeeklyTrendsCard() {
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
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 65, color: brandBlue)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 78, color: brandBlue)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 52, color: brandBlue)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 90, color: brandBlue)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 85, color: brandBlue)]),
                    BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 45, color: brandBlue)]),
                    BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 38, color: brandBlue)]),
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
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: 65,
                      title: 'Very Satisfied\n65%',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 25,
                      title: 'Satisfied\n25%',
                      color: Colors.blue,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 8,
                      title: 'Neutral\n8%',
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 2,
                      title: 'Dissatisfied\n2%',
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
  const UserManagementScreen({Key? key}) : super(key: key);

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
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Filter logic
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
                color: color.withOpacity(0.1),
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
    final _formKey = GlobalKey<FormState>();
    String name = '';
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
                  key: _formKey,
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
                        value: selectedRole,
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
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
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
}

// Data Exports Screen
class DataExportsScreen extends StatelessWidget {
  const DataExportsScreen({Key? key}) : super(key: key);

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
                       _buildExportCard(context, 'ARTA Compliance Report', 'PDF Format', Icons.picture_as_pdf, Colors.red, isPdf: true),
                       _buildExportCard(context, 'Raw Data Export', 'CSV Format', Icons.table_chart, Colors.green),
                       _buildExportCard(context, 'Executive Summary', 'DOCX Format', Icons.description, Colors.blue, isDocx: true),
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
                                'Latest survey submissions',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
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
                      // Table Rows
                      _buildRespondentRow('10234', 'Jan 24, 2024', 'Citizen', 'Business Permit', 'Aware', 5),
                      _buildRespondentRow('10235', 'Jan 24, 2024', 'Business', 'Tax Declaration', 'Aware', 4),
                      _buildRespondentRow('10236', 'Jan 23, 2024', 'Citizen', 'Social Services', 'Not Aware', 5),
                      _buildRespondentRow('10237', 'Jan 23, 2024', 'Government', 'Health Cert', 'Aware', 5),
                      _buildRespondentRow('10238', 'Jan 23, 2024', 'Citizen', 'Engineering', 'Aware', 3),
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

  Widget _buildExportCard(BuildContext context, String title, String sub, IconData icon, Color color, {bool isPdf = false, bool isDocx = false}) {
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
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
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
                onPressed: () {
                  if (isPdf) {
                    _showPdfExportDialog(context);
                  } else if (isDocx) {
                    _simulateDocxExport(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generating $title...')));
                  }
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Generate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export PDF Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description, color: Colors.red),
              title: const Text('ARTA Compliance Report'),
              subtitle: const Text('Standard format for ARTA submission'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Compliance Report...')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Detailed Analysis'),
              subtitle: const Text('Full breakdown of SQD and comments'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Detailed Analysis...')));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _simulateDocxExport(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Generating Executive Summary (DOCX)..."),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close progress dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Successful'),
          content: const Text('The Executive Summary has been generated successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
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
