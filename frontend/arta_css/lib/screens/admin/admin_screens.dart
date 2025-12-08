import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/export_service.dart';
import '../../services/feedback_service.dart';
import '../../services/survey_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// THEME CONSTANTS
const String fontHeading = 'Montserrat';
const String fontBody = 'Poppins';
final Color brandBlue = Colors.blue.shade900;
final Color brandRed = Colors.red.shade900;

// ARTA Configuration Screen
class ArtaConfigurationScreen extends StatefulWidget {
  const ArtaConfigurationScreen({super.key});

  @override
  State<ArtaConfigurationScreen> createState() => _ArtaConfigurationScreenState();
}

class _ArtaConfigurationScreenState extends State<ArtaConfigurationScreen> {
  @override
  Widget build(BuildContext context) {
    final configService = Provider.of<SurveyConfigService>(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show dashboard background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      children: const <TextSpan>[
                        TextSpan(
                          text: 'ARTA Survey ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Configuration',
                          style: TextStyle(color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage the standard Client Satisfaction Measurement (CSM) form.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Configuration
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'Core Survey Sections',
                        isMandatory: true,
                        children: [
                          _buildToggleItem(
                            'Citizen\'s Charter (CC) Questions',
                            'CC1 (Awareness), CC2 (Visibility), CC3 (Helpfulness)',
                            configService.ccEnabled,
                            (v) => configService.setCcEnabled(v),
                          ),
                          const Divider(),
                          _buildToggleItem(
                            'Service Quality Dimensions (SQD)',
                            'SQD0 to SQD8 (Likert Scale Rating)',
                            configService.sqdEnabled,
                            (v) => configService.setSqdEnabled(v),
                          ),
                          const Divider(),
                          _buildToggleItem(
                            'Client Demographics',
                            'Client Type, Gender, Age, Region, Service Availed',
                            configService.demographicsEnabled,
                            (v) => configService.setDemographicsEnabled(v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Custom Modules',
                        children: [
                          _buildToggleItem(
                            'CGOV Additional Questions',
                            'Include optional questions specific to Valenzuela City programs.',
                            configService.cgovQuestionsEnabled,
                            (v) => configService.setCgovQuestionsEnabled(v),
                          ),
                          const Divider(),
                          _buildToggleItem(
                            'Suggestions Box',
                            'Allow free-text feedback at the end of the survey.',
                            configService.suggestionsEnabled,
                            (v) => configService.setSuggestionsEnabled(v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: 'Deployment Settings',
                        children: [
                          _buildToggleItem(
                            'Kiosk Mode',
                            'Auto-reset survey after submission (for tablets at City Hall).',
                            configService.kioskMode,
                            (v) => configService.setKioskMode(v),
                            icon: Icons.tablet_mac,
                            activeColor: Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column: Preview & Access
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildAccessPointCard(context),
                      const SizedBox(height: 24),
                      _buildLivePreviewCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children, bool isMandatory = false}) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isMandatory ? Icons.description_outlined : Icons.settings_suggest_outlined, color: brandRed, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: fontHeading,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (isMandatory)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Mandatory',
                      style: TextStyle(
                        fontFamily: fontBody,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: brandRed,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged, {IconData? icon, Color? activeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: fontBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: fontBody,
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor ?? Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessPointCard(BuildContext context) {
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
            Row(
              children: [
                Icon(Icons.qr_code_2, color: Colors.black87, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Access Point',
                  style: TextStyle(
                    fontFamily: fontHeading,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 180,
                height: 180,
                color: Colors.grey.shade100,
                child: Icon(Icons.qr_code, size: 100, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'ID: ARTA-VAL-2024-Q1',
                style: TextStyle(fontFamily: fontBody, fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading QR Code...')));
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending to printer...')));
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Direct Link:', style: TextStyle(fontFamily: fontBody, fontSize: 12, color: Colors.grey.shade600)),
                Text('valenzuela.gov.ph/arta-survey', style: TextStyle(fontFamily: fontBody, fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status:', style: TextStyle(fontFamily: fontBody, fontSize: 12, color: Colors.grey.shade600)),
                Text('Active', style: TextStyle(fontFamily: fontBody, fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade50),
      ),
      color: Colors.blue.shade50.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility_outlined, color: brandBlue, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Live Preview',
                  style: TextStyle(
                    fontFamily: fontHeading,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: brandBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'See how the survey looks on mobile devices before publishing changes.',
              style: TextStyle(
                fontFamily: fontBody,
                fontSize: 12,
                color: brandBlue.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SurveyDetailScreen(title: 'ARTA Client Satisfaction Survey')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Open Preview', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Updated SurveyDetailScreen content to match ARTA
class SurveyDetailScreen extends StatelessWidget {
  final String title;
  const SurveyDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Light blue-grey background
      appBar: AppBar(
        title: Text('Survey Preview', style: TextStyle(fontFamily: fontHeading, color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 700,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    // Decorative Header
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: brandRed,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Branding
                          Row(
                            children: [
                               CircleAvatar(backgroundColor: brandBlue, radius: 20, child: const Icon(Icons.account_balance, color: Colors.white, size: 20)),
                               const SizedBox(width: 16),
                                Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text('CITY GOVERNMENT OF VALENZUELA', style: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
                                   Text('Service Excellence Office', style: TextStyle(fontFamily: fontBody, fontSize: 10, color: Colors.grey.shade500)),
                                 ],
                               )
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Survey Header
                          Text(title, style: TextStyle(fontFamily: fontHeading, fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text(
                            'Your feedback is important to us. Please help us improve our services by answering the following questions.',
                            style: TextStyle(fontFamily: fontBody, fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const Divider(height: 48),

                          Text("Citizen's Charter (CC)", style: TextStyle(fontFamily: fontHeading, fontSize: 18, fontWeight: FontWeight.bold, color: brandBlue)),
                          const SizedBox(height: 16),
                          _buildPreviewItem(1, 'CC1: Do you know about the Citizen\'s Charter?', ['Yes, aware before my transaction', 'Yes, but only saw it today', 'No, not aware']),
                          _buildPreviewItem(2, 'CC2: Did you see the Citizen\'s Charter?', ['Yes, it was easy to see', 'Yes, but hard to see', 'No, did not see it']),
                          _buildPreviewItem(3, 'CC3: Was the Citizen\'s Charter helpful?', ['Yes, very helpful', 'Somewhat helpful', 'No, not helpful']),

                          const Divider(height: 48),
                          Text("Service Quality Dimensions (SQD)", style: TextStyle(fontFamily: fontHeading, fontSize: 18, fontWeight: FontWeight.bold, color: brandBlue)),
                          const SizedBox(height: 16),
                          _buildPreviewItem(4, 'SQD0: I am satisfied with the service that I availed.', []), // Empty list for rating
                          _buildPreviewItem(5, 'SQD1: I spent a reasonable amount of time for my transaction.', []),
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: null, // Disabled for preview
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('SUBMIT FEEDBACK', style: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("This is a preview of how the survey appears to citizens.", style: TextStyle(fontFamily: fontBody, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewItem(int index, String question, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(fontFamily: fontBody, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          if (options.isEmpty)
             Row(children: List.generate(5, (index) => Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.star_border, color: Colors.amber, size: 30))))
          else
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(opt, style: TextStyle(fontFamily: fontBody, fontSize: 14, color: Colors.grey.shade800)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// Detailed Analytics Screen
class DetailedAnalyticsScreen extends StatefulWidget {
  const DetailedAnalyticsScreen({super.key});

  @override
  State<DetailedAnalyticsScreen> createState() => _DetailedAnalyticsScreenState();
}

class _DetailedAnalyticsScreenState extends State<DetailedAnalyticsScreen> {
  // SQD metadata
  static const List<Map<String, String>> _sqdMetadata = [
    {'code': 'SQD0', 'title': 'Satisfaction', 'desc': 'I am satisfied with the service that I availed'},
    {'code': 'SQD1', 'title': 'Time', 'desc': 'I spent a reasonable amount of time for my transaction'},
    {'code': 'SQD2', 'title': 'Requirements', 'desc': 'The office followed the transaction requirements'},
    {'code': 'SQD3', 'title': 'Procedure', 'desc': 'The steps were easy and simple'},
    {'code': 'SQD4', 'title': 'Information', 'desc': 'I easily found information about my transaction'},
    {'code': 'SQD5', 'title': 'Cost', 'desc': 'I paid a reasonable amount of fees'},
    {'code': 'SQD6', 'title': 'Fairness', 'desc': 'I feel the office was fair to everyone'},
    {'code': 'SQD7', 'title': 'Courtesy', 'desc': 'I was treated courteously by the staff'},
    {'code': 'SQD8', 'title': 'Outcome', 'desc': 'I got what I needed from the government office'},
  ];

  @override
  void initState() {
    super.initState();
    // Ensure data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedbackService>().fetchAllFeedbacks();
    });
  }

  List<Map<String, dynamic>> _getSQDDataWithScores(Map<String, double> sqdAverages) {
    return _sqdMetadata.map((meta) {
      final code = meta['code']!;
      final score = sqdAverages[code] ?? 0.0;
      return {
        'code': code,
        'title': meta['title']!,
        'desc': meta['desc']!,
        'score': score,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedbackService>(
      builder: (context, feedbackService, child) {
        final stats = feedbackService.dashboardStats;
        final isLoading = feedbackService.isLoading;
        
        final overallScore = stats?.avgSatisfaction ?? 0.0;
        final topService = stats?.topPerformingService ?? 'N/A';
        final topServiceScore = stats?.topPerformingServiceScore ?? 0.0;
        final needsAttention = stats?.needsAttentionService ?? 'N/A';
        final needsAttentionScore = stats?.needsAttentionServiceScore ?? 0.0;
        final strongestSQD = stats?.strongestSQD ?? 'N/A';
        final strongestSQDScore = stats?.strongestSQDScore ?? 0.0;
        final sqdData = _getSQDDataWithScores(stats?.sqdAverages ?? {});
        final clientTypeDistribution = stats?.clientTypeDistribution ?? {};
        final serviceBreakdown = stats?.serviceBreakdown ?? {};

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for dashboard background
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded( // Added Expanded to allow column to take space
                     child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                       RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            children: const <TextSpan>[
                              TextSpan(
                                text: 'DETAILED ',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'ANALYTICS',
                                style: TextStyle(color: Colors.amber),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deep dive into customer satisfaction metrics and segmentation.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                  ),),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('This Month'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list, size: 16),
                        label: const Text('Advanced Filter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Highlights
            Row(
              children: [
                Expanded(child: _buildHighlightCard('Top Performing Service', topService, 'Score: ${topServiceScore.toStringAsFixed(1)}/5.0', Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildHighlightCard('Needs Attention', needsAttention, 'Score: ${needsAttentionScore.toStringAsFixed(1)}/5.0', Colors.amber)),
                const SizedBox(width: 16),
                Expanded(child: _buildHighlightCard('Strongest Dimension', strongestSQD, 'Score: ${strongestSQDScore.toStringAsFixed(1)}/5.0', Colors.blue)),
              ],
            ),
            const SizedBox(height: 24),

            // Automated Analysis
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
                      children: [
                        Icon(Icons.auto_awesome, color: brandBlue, size: 20),
                        const SizedBox(width: 12),
                        Text('Automated Performance Analysis', style: TextStyle(fontFamily: fontHeading, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAnalysisText(
                      'Executive Summary',
                      'The overall customer satisfaction index for the current period stands at ${overallScore.toStringAsFixed(1)} out of 5.0. The data indicates that the majority of constituents are "Very Satisfied" with the services provided by the City Government of Valenzuela.',
                    ),
                    const SizedBox(height: 12),
                    _buildAnalysisText(
                      'Service Level Analysis',
                      'Among the key service areas, $topService is leading with exceptional satisfaction scores of ${topServiceScore.toStringAsFixed(1)}. Conversely, $needsAttention recorded the lowest score of ${needsAttentionScore.toStringAsFixed(1)}.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SQD Breakdown Grid (New Implementation)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Service Quality Dimensions (SQD) Breakdown', style: TextStyle(fontFamily: fontHeading, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('View Detailed Analysis'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1200 ? 3 : constraints.maxWidth > 800 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.2, // Adjusted for card content
                        ),
                        itemCount: sqdData.length,
                        itemBuilder: (context, index) {
                          final data = sqdData[index];
                          return _buildSQDCard(data);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: brandBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Score interpretation: 5 - Strongly Agree, 1 - Strongly Disagree. ARTA compliance requires detailed tracking of all 9 dimensions (SQD0-SQD8).',
                        style: TextStyle(fontSize: 12, color: brandBlue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Charts Row
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1000) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSatisfactionByServiceCard(serviceBreakdown)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildRespondentProfileCard(clientTypeDistribution)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildSatisfactionByServiceCard(serviceBreakdown),
                      const SizedBox(height: 24),
                      _buildRespondentProfileCard(clientTypeDistribution),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Radar Chart
             Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visual SQD Analysis (Radar)', style: TextStyle(fontFamily: fontHeading, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 400,
                      child: sqdData.isEmpty || sqdData.every((e) => (e['score'] as double) == 0)
                          ? Center(
                              child: Text(
                                'No data available',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            )
                          : RadarChart(
                        RadarChartData(
                          radarShape: RadarShape.polygon,
                          ticksTextStyle: const TextStyle(color: Colors.transparent),
                          gridBorderData: BorderSide(color: Colors.grey.shade200),
                          titlePositionPercentageOffset: 0.2,
                          titleTextStyle: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                          tickCount: 5,
                          // ticksBorderData removed
                          radarBorderData: const BorderSide(color: Colors.transparent),
                          radarBackgroundColor: Colors.transparent,
                          dataSets: [
                            RadarDataSet(
                              fillColor: brandRed.withOpacity(0.4),
                              borderColor: brandRed,
                              entryRadius: 3,
                              dataEntries: sqdData.map((e) => RadarEntry(value: e['score'] as double)).toList(),
                            ),
                          ],
                          getTitle: (index, angle) {
                             return RadarChartTitle(text: sqdData[index]['code']);
                          },
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
    );
      },
    );
  }

  Widget _buildSQDCard(Map<String, dynamic> data) {
    double score = data['score'];
    Color scoreColor = score >= 4.5 ? Colors.green : (score >= 4.0 ? Colors.amber : Colors.red);
    Color bgColor = scoreColor.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['code'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
                child: Text(score.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: scoreColor)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(data['desc'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          LinearProgressIndicator(
            value: score / 5,
            backgroundColor: Colors.grey.shade100,
            color: brandBlue,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.analytics, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontFamily: fontBody, fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: TextStyle(fontFamily: fontHeading, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(sub, style: TextStyle(fontFamily: fontBody, fontSize: 12, color: color, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisText(String title, String content) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontFamily: fontBody, fontSize: 13, color: Colors.grey.shade800, height: 1.5),
        children: [
          TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: content),
        ],
      ),
    );
  }

  Widget _buildSatisfactionByServiceCard(Map<String, double> serviceBreakdown) {
    // Sort by score descending and take top 5
    final sortedServices = serviceBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topServices = sortedServices.take(5).toList();
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: brandBlue, size: 20),
                const SizedBox(width: 12),
                Text('Satisfaction by Service', style: TextStyle(fontFamily: fontHeading, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            if (topServices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No service data available',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              )
            else
              ...topServices.map((entry) => _buildBarRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, textAlign: TextAlign.end, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Container(height: 20, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(
                  widthFactor: val / 5,
                  child: Container(height: 20, decoration: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.circular(4))),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(val.toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildRespondentProfileCard(Map<String, int> clientTypeDistribution) {
    final total = clientTypeDistribution.values.fold(0, (a, b) => a + b);
    final hasData = total > 0;
    
    // Define colors for different client types
    final colors = <String, Color>{
      'Citizen': brandBlue,
      'Business': brandRed,
      'Government': Colors.green,
    };
    
    // Build pie chart sections
    final sections = <PieChartSectionData>[];
    final legends = <Widget>[];
    
    if (hasData) {
      var colorIndex = 0;
      final colorList = [brandBlue, brandRed, Colors.green, Colors.purple, Colors.orange];
      
      for (final entry in clientTypeDistribution.entries) {
        final color = colors[entry.key] ?? colorList[colorIndex % colorList.length];
        sections.add(
          PieChartSectionData(
            value: entry.value.toDouble(),
            color: color,
            radius: 40,
            showTitle: false,
          ),
        );
        legends.add(_buildLegendItem('${entry.key} (${entry.value})', color));
        if (clientTypeDistribution.entries.toList().indexOf(entry) < clientTypeDistribution.length - 1) {
          legends.add(const SizedBox(width: 16));
        }
        colorIndex++;
      }
    }
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              children: [
                Icon(Icons.pie_chart, color: brandRed, size: 20),
                const SizedBox(width: 12),
                Text('Respondent Profile', style: TextStyle(fontFamily: fontHeading, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
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
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (hasData)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: legends,
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
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}

// Simple simulation wrappers for other screens to keep code clean
class SurveyAnalyticsScreen extends StatelessWidget {
  final String title;
  const SurveyAnalyticsScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics: $title'), backgroundColor: brandBlue),
      body: const Center(child: Text("Analytics Graph Simulation")),
    );
  }
}

class AddUserScreen extends StatelessWidget {
  final String? existingName;
  const AddUserScreen({super.key, this.existingName});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(existingName ?? "Add User")));
}

class UserDetailScreen extends StatelessWidget {
  final String name;
  final String email;
  const UserDetailScreen({super.key, required this.name, required this.email});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(name)));
}

class ExportPreviewScreen extends StatelessWidget {
  final String filePath;
  const ExportPreviewScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Preview')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Saved file:\n$filePath',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File located at: $filePath')));
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Show Path'),
            ),
          ],
        ),
      ),
    );
  }
}

class ExportProcessScreen extends StatefulWidget {
  final String templateName;
  const ExportProcessScreen({super.key, required this.templateName});
  @override
  State<ExportProcessScreen> createState() => _ExportProcessScreenState();
}

class _ExportProcessScreenState extends State<ExportProcessScreen> {
  double _progress = 0.0;
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  Future<void> _startExport() async {
    // Simulate progress and perform a CSV export with sample data
    final rows = [
      ['id', 'name', 'score'],
      ['1', 'Alice', '95'],
      ['2', 'Bob', '82'],
      ['3', 'Carlos', '77'],
    ];

    for (var i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      setState(() => _progress = i / 5);
    }

    try {
      final path = await ExportService.exportCsv(widget.templateName, rows);
      setState(() => _savedPath = path);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Export: ${widget.templateName}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Text(_savedPath == null ? 'Preparing export...' : 'Saved: $_savedPath'),
              const SizedBox(height: 12),
              if (_savedPath != null)
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExportPreviewScreen(filePath: _savedPath!))),
                  child: const Text('Open Preview'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _exportFormat = 'csv';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _exportFormat = prefs.getString('exportFormat') ?? 'csv';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setString('exportFormat', _exportFormat);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
            const SizedBox(height: 8),
            const Text('Default Export Format', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(title: const Text('CSV'), value: 'csv', groupValue: _exportFormat, onChanged: (v) => setState(() => _exportFormat = v!)),
            RadioListTile<String>(title: const Text('JSON'), value: 'json', groupValue: _exportFormat, onChanged: (v) => setState(() => _exportFormat = v!)),
            RadioListTile<String>(title: const Text('PDF'), value: 'pdf', groupValue: _exportFormat, onChanged: (v) => setState(() => _exportFormat = v!)),
            const SizedBox(height: 16),
            Row(children: [
              ElevatedButton(onPressed: _savePrefs, child: const Text('Save')),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _loadPrefs, child: const Text('Reload')),
            ])
          ],
        ),
      ),
    );
  }
}
