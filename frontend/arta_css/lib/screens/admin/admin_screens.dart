import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/export_service.dart';
// HTTP services for cross-platform compatibility (no Firebase dependency)
import '../../services/feedback_service_http.dart';
import '../../services/survey_config_service.dart';
import '../../services/survey_questions_service.dart';
import '../../services/qr_code_service.dart';
import '../../services/audit_log_service_http.dart';
import '../../services/auth_services_http.dart';
import '../../services/push_notification_service_stub.dart';
// Native notifications: stub for web, native implementation for desktop
import '../../services/native_notification_service_stub.dart'
    if (dart.library.io) '../../services/native_notification_service_native.dart';
import '../../utils/admin_theme.dart';
import '../../widgets/audit_log_viewer.dart';
import '../../widgets/survey_question_editor.dart';
import '../user_side/landing_page.dart';

// THEME CONSTANTS - Re-exported from AdminTheme for backwards compatibility
final Color brandBlue = AdminTheme.brandBlue;
final Color brandRed = AdminTheme.brandRed;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            final isMediumScreen = constraints.maxWidth < 900;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card - responsive padding
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       RichText(
                        text: TextSpan(
                          style: AdminTheme.headingLarge(
                            color: Colors.white,
                          ).copyWith(fontSize: isSmallScreen ? 20 : 24),
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
                        style: AdminTheme.bodyMedium(
                          color: Colors.white,
                        ).copyWith(fontSize: isSmallScreen ? 12 : 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Responsive layout - stack on small/medium screens
                if (isMediumScreen)
                  Column(
                    children: [
                      // Configuration sections
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
                      const SizedBox(height: 24),
                      _buildAccessPointCard(context),
                      const SizedBox(height: 24),
                      _buildLivePreviewCard(context),
                      const SizedBox(height: 24),
                      const SurveyQuestionEditor(),
                    ],
                  )
                else
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
                            const SizedBox(height: 24),
                            const SurveyQuestionEditor(),
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
            );
          },
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
                      style: AdminTheme.headingSmall(
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
                      style: AdminTheme.bodyXS(
                        color: brandRed,
                        fontWeight: FontWeight.bold,
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
                  style: AdminTheme.bodyMedium(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AdminTheme.bodySmall(
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
    final GlobalKey qrKey = GlobalKey();
    
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
                  style: AdminTheme.headingSmall(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: RepaintBoundary(
                key: qrKey,
                child: Container(
                  width: 180,
                  height: 180,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: QrCodeService.surveyUrl,
                    version: QrVersions.auto,
                    size: 164,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'ID: ${QrCodeService.surveyId}',
                style: AdminTheme.bodyXS(color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Generating QR Code image...')),
                      );
                      
                      try {
                        final imageBytes = await QrCodeService.captureWidgetAsImage(qrKey);
                        if (imageBytes != null) {
                          await QrCodeService.downloadQrCode(imageBytes);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('QR Code downloaded successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          throw Exception('Failed to capture QR code image');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Download failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preparing print document...')),
                      );
                      
                      try {
                        final imageBytes = await QrCodeService.captureWidgetAsImage(qrKey);
                        if (imageBytes != null) {
                          await QrCodeService.printQrCode(imageBytes);
                        } else {
                          throw Exception('Failed to capture QR code image');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Print failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
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
                Text('Direct Link:', style: AdminTheme.bodySmall(color: Colors.grey.shade600)),
                SelectableText(
                  QrCodeService.surveyUrl.replaceFirst('https://', ''),
                  style: AdminTheme.linkText(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status:', style: AdminTheme.bodySmall(color: Colors.grey.shade600)),
                Text('Active', style: AdminTheme.bodySmall(color: Colors.green, fontWeight: FontWeight.bold)),
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
      color: Colors.blue.shade50.withValues(alpha: 0.3),
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
                  style: AdminTheme.headingSmall(
                    color: brandBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'See how the survey looks on mobile devices before publishing changes.',
              style: AdminTheme.bodySmall(
                color: brandBlue.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MobilePreviewScreen()),
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
        title: Text('Survey Preview', style: AdminTheme.headingMedium(color: Colors.black87)),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 5))],
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
                                   Text('CITY GOVERNMENT OF VALENZUELA', style: AdminTheme.bodySmall(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                   Text('Service Excellence Office', style: AdminTheme.bodyXS(color: Colors.grey.shade500)),
                                 ],
                               )
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Survey Header
                          Text(title, style: AdminTheme.headingLarge(color: Colors.black87).copyWith(fontSize: 28)),
                          const SizedBox(height: 8),
                          Text(
                            'Your feedback is important to us. Please help us improve our services by answering the following questions.',
                            style: AdminTheme.bodyMedium(color: Colors.grey.shade600),
                          ),
                          const Divider(height: 48),

                          Text("Citizen's Charter (CC)", style: AdminTheme.headingMedium(color: brandBlue)),
                          const SizedBox(height: 16),
                          _buildPreviewItem(1, 'CC1: Do you know about the Citizen\'s Charter?', ['Yes, aware before my transaction', 'Yes, but only saw it today', 'No, not aware']),
                          _buildPreviewItem(2, 'CC2: Did you see the Citizen\'s Charter?', ['Yes, it was easy to see', 'Yes, but hard to see', 'No, did not see it']),
                          _buildPreviewItem(3, 'CC3: Was the Citizen\'s Charter helpful?', ['Yes, very helpful', 'Somewhat helpful', 'No, not helpful']),

                          const Divider(height: 48),
                          Text("Service Quality Dimensions (SQD)", style: AdminTheme.headingMedium(color: brandBlue)),
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
                              child: Text('SUBMIT FEEDBACK', style: AdminTheme.headingXS(color: Colors.white)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("This is a preview of how the survey appears to citizens.", style: AdminTheme.bodyMedium(color: Colors.grey.shade600)),
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
          Text(question, style: AdminTheme.bodyLarge(color: Colors.black87, fontWeight: FontWeight.w600)),
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
                Text(opt, style: AdminTheme.bodyMedium(color: Colors.grey.shade800)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// Mobile Preview Screen - Shows actual survey in a mobile device frame
// Uses a nested Navigator to keep navigation contained within the preview
class MobilePreviewScreen extends StatefulWidget {
  const MobilePreviewScreen({super.key});

  @override
  State<MobilePreviewScreen> createState() => _MobilePreviewScreenState();
}

class _MobilePreviewScreenState extends State<MobilePreviewScreen> {
  final GlobalKey<NavigatorState> _nestedNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(
          'Mobile Preview',
          style: AdminTheme.headingMedium(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Reset preview to start
              _nestedNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset Preview'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Mobile device frame
            Container(
              width: 375, // iPhone width
              height: 667, // iPhone height
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                // Nested Navigator to contain all survey navigation
                child: MediaQuery(
                  data: const MediaQueryData(size: Size(351, 643)), // Inner frame size
                  child: Navigator(
                    key: _nestedNavigatorKey,
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        builder: (context) => const LandingScreen(isPreviewMode: true),
                        settings: settings,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'This preview shows exactly how the survey appears on mobile devices.',
              style: AdminTheme.bodyMedium(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Interact with it to test the full survey flow.',
              style: AdminTheme.bodySmall(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Detailed Analytics Screen
class DetailedAnalyticsScreen extends StatefulWidget {
  /// When true, shows as standalone page with AppBar and background
  /// When false (default), shows as embedded screen within dashboard
  final bool isStandalone;
  
  const DetailedAnalyticsScreen({super.key, this.isStandalone = false});

  @override
  State<DetailedAnalyticsScreen> createState() => _DetailedAnalyticsScreenState();
}

class _DetailedAnalyticsScreenState extends State<DetailedAnalyticsScreen> {
  // Date filter state
  DateTimeRange? _selectedDateRange;
  String _activeFilter = 'all'; // 'all', 'thisMonth', 'thisWeek', 'custom'
  
  // Region and service filter state
  String? _selectedRegion;
  String? _selectedService;
  
  // Radar chart hover state
  int? _touchedRadarIndex;
  Offset? _radarMousePosition;
  
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
    // Start real-time listener if not already listening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackService = context.read<FeedbackServiceHttp>();
      if (!feedbackService.isListening) {
        feedbackService.startRealtimeUpdates();
      }
    });
  }

  // Set This Month filter
  void _setThisMonthFilter() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    setState(() {
      _selectedDateRange = DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth);
      _activeFilter = 'thisMonth';
    });
  }

  // Set This Week filter
  void _setThisWeekFilter() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    setState(() {
      _selectedDateRange = DateTimeRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      );
      _activeFilter = 'thisWeek';
    });
  }

  // Show advanced filter dialog
  Future<void> _showAdvancedFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AdvancedFilterDialog(
        currentDateRange: _selectedDateRange,
        currentRegion: _selectedRegion,
        currentService: _selectedService,
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedDateRange = result['dateRange'] as DateTimeRange?;
        _selectedRegion = result['region'] as String?;
        _selectedService = result['service'] as String?;
        // Determine filter status
        final hasAnyFilter = _selectedDateRange != null || 
            (_selectedRegion != null && _selectedRegion!.isNotEmpty) || 
            (_selectedService != null && _selectedService!.isNotEmpty);
        _activeFilter = hasAnyFilter ? 'custom' : 'all';
      });
    }
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedRegion = null;
      _selectedService = null;
      _activeFilter = 'all';
    });
  }

  // Get filter button text
  String _getFilterButtonText() {
    // Count active filters
    int filterCount = 0;
    if (_selectedDateRange != null) filterCount++;
    if (_selectedRegion != null && _selectedRegion!.isNotEmpty) filterCount++;
    if (_selectedService != null && _selectedService!.isNotEmpty) filterCount++;
    
    if (filterCount == 0) {
      switch (_activeFilter) {
        case 'thisMonth':
          return 'This Month';
        case 'thisWeek':
          return 'This Week';
        default:
          return 'All Time';
      }
    } else if (filterCount == 1) {
      if (_selectedDateRange != null) {
        final start = '${_selectedDateRange!.start.month}/${_selectedDateRange!.start.day}';
        final end = '${_selectedDateRange!.end.month}/${_selectedDateRange!.end.day}';
        return '$start - $end';
      } else if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
        return _selectedRegion!;
      } else if (_selectedService != null && _selectedService!.isNotEmpty) {
        return _selectedService!;
      }
    }
    return '$filterCount Filters Active';
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
    return Consumer<FeedbackServiceHttp>(
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

    // Body content
    final bodyContent = isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - responsive
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
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
                                  style: AdminTheme.headingLarge(
                                    color: Colors.white,
                                  ).copyWith(fontSize: isSmallScreen ? 20 : 24),
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
                                style: AdminTheme.bodyMedium(
                                  color: Colors.white,
                                ).copyWith(fontSize: isSmallScreen ? 12 : 14),
                              ),
                            ],
                          ),
                          // Filter buttons - wrap on smaller screens
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Clear filter button (shows when filter is active)
                              if (_activeFilter != 'all')
                                IconButton(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: 'Clear filter',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.shade100,
                                    foregroundColor: Colors.red.shade700,
                                  ),
                                ),
                              // This Month button
                              OutlinedButton.icon(
                                onPressed: _setThisMonthFilter,
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  _activeFilter == 'thisMonth' 
                                      ? (isSmallScreen ? '✓' : 'This Month ✓') 
                                      : (isSmallScreen ? 'Month' : 'This Month')
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _activeFilter == 'thisMonth' ? Colors.blue.shade50 : Colors.white,
                                  foregroundColor: _activeFilter == 'thisMonth' ? Colors.blue.shade700 : null,
                                  side: _activeFilter == 'thisMonth' ? BorderSide(color: Colors.blue.shade400, width: 2) : null,
                                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 12 : 16),
                                ),
                              ),
                              // This Week button
                              OutlinedButton.icon(
                                onPressed: _setThisWeekFilter,
                                icon: const Icon(Icons.date_range, size: 16),
                                label: Text(
                                  _activeFilter == 'thisWeek' 
                                      ? (isSmallScreen ? '✓' : 'This Week ✓') 
                                      : (isSmallScreen ? 'Week' : 'This Week')
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _activeFilter == 'thisWeek' ? Colors.blue.shade50 : Colors.white,
                                  foregroundColor: _activeFilter == 'thisWeek' ? Colors.blue.shade700 : null,
                                  side: _activeFilter == 'thisWeek' ? BorderSide(color: Colors.blue.shade400, width: 2) : null,
                                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 12 : 16),
                                ),
                              ),
                              // Advanced Filter button
                              ElevatedButton.icon(
                                onPressed: _showAdvancedFilterDialog,
                                icon: const Icon(Icons.filter_list, size: 16),
                                label: Text(
                                  _activeFilter == 'custom' 
                                      ? (isSmallScreen ? 'Custom' : _getFilterButtonText()) 
                                      : (isSmallScreen ? 'Custom' : 'Custom Range')
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _activeFilter == 'custom' ? Colors.green.shade600 : Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20, vertical: isSmallScreen ? 12 : 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
            
                // Highlights - responsive grid
                LayoutBuilder(
                  builder: (context, highlightConstraints) {
                    if (highlightConstraints.maxWidth > 900) {
                      return Row(
                        children: [
                          Expanded(child: _buildHighlightCard('Top Performing Service', topService, 'Score: ${topServiceScore.toStringAsFixed(1)}/5.0', Colors.green)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildHighlightCard('Needs Attention', needsAttention, 'Score: ${needsAttentionScore.toStringAsFixed(1)}/5.0', Colors.amber)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildHighlightCard('Strongest Dimension', strongestSQD, 'Score: ${strongestSQDScore.toStringAsFixed(1)}/5.0', Colors.blue)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildHighlightCard('Top Performing Service', topService, 'Score: ${topServiceScore.toStringAsFixed(1)}/5.0', Colors.green),
                          const SizedBox(height: 16),
                          _buildHighlightCard('Needs Attention', needsAttention, 'Score: ${needsAttentionScore.toStringAsFixed(1)}/5.0', Colors.amber),
                          const SizedBox(height: 16),
                          _buildHighlightCard('Strongest Dimension', strongestSQD, 'Score: ${strongestSQDScore.toStringAsFixed(1)}/5.0', Colors.blue),
                        ],
                      );
                    }
                  },
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
                        Text('Automated Performance Analysis', style: AdminTheme.headingSmall()),
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Service Quality Dimensions (SQD) Breakdown', style: AdminTheme.headingMedium(color: Colors.black87)),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const DetailedAnalyticsScreen(isStandalone: true)),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('View Detailed Analysis'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, sqdConstraints) {
                      final crossAxisCount = sqdConstraints.maxWidth > 1200 ? 3 : sqdConstraints.maxWidth > 700 ? 2 : 1;
                      // Calculate aspect ratio dynamically
                      final cardWidth = (sqdConstraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
                      final targetHeight = 130.0; // Target height for SQD cards
                      final aspectRatio = (cardWidth / targetHeight).clamp(1.8, 3.5);
                      
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: aspectRatio,
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
                    Text('Visual SQD Analysis (Radar)', style: AdminTheme.headingSmall()),
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
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                return MouseRegion(
                                  onHover: (event) {
                                    setState(() => _radarMousePosition = event.localPosition);
                                  },
                                  onExit: (_) {
                                    setState(() {
                                      _touchedRadarIndex = null;
                                      _radarMousePosition = null;
                                    });
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      RadarChart(
                                        RadarChartData(
                                          radarShape: RadarShape.polygon,
                                          ticksTextStyle: const TextStyle(color: Colors.transparent),
                                          gridBorderData: BorderSide(color: Colors.grey.shade200),
                                          titlePositionPercentageOffset: 0.2,
                                          titleTextStyle: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                                          tickCount: 5,
                                          radarBorderData: const BorderSide(color: Colors.transparent),
                                          radarBackgroundColor: Colors.transparent,
                                          borderData: FlBorderData(show: false),
                                          radarTouchData: RadarTouchData(
                                            enabled: true,
                                            touchSpotThreshold: 20,
                                            touchCallback: (FlTouchEvent event, RadarTouchResponse? response) {
                                              if (response == null || response.touchedSpot == null) {
                                                if (_touchedRadarIndex != null) {
                                                  setState(() => _touchedRadarIndex = null);
                                                }
                                                return;
                                              }
                                              // Only respond to first dataset (actual data, not scale helpers)
                                              if (response.touchedSpot!.touchedDataSetIndex == 0) {
                                                final newIndex = response.touchedSpot!.touchedRadarEntryIndex;
                                                if (_touchedRadarIndex != newIndex) {
                                                  setState(() => _touchedRadarIndex = newIndex);
                                                }
                                              }
                                            },
                                          ),
                                          dataSets: [
                                            RadarDataSet(
                                              fillColor: brandRed.withValues(alpha: 0.4),
                                              borderColor: brandRed,
                                              entryRadius: 3,
                                              dataEntries: sqdData.map((e) => RadarEntry(value: e['score'] as double)).toList(),
                                            ),
                                            // Add invisible dataset at 0 and 5 to fix the scale
                                            RadarDataSet(
                                              fillColor: Colors.transparent,
                                              borderColor: Colors.transparent,
                                              entryRadius: 0,
                                              dataEntries: List.generate(sqdData.length, (_) => const RadarEntry(value: 0)),
                                            ),
                                            RadarDataSet(
                                              fillColor: Colors.transparent,
                                              borderColor: Colors.transparent,
                                              entryRadius: 0,
                                              dataEntries: List.generate(sqdData.length, (_) => const RadarEntry(value: 5)),
                                            ),
                                          ],
                                          getTitle: (index, angle) {
                                            return RadarChartTitle(text: sqdData[index]['code']);
                                          },
                                        ),
                                      ),
                                      // Custom tooltip overlay following cursor
                                      if (_touchedRadarIndex != null && _touchedRadarIndex! < sqdData.length && _radarMousePosition != null)
                                        Positioned(
                                          left: (_radarMousePosition!.dx + 260 > constraints.maxWidth)
                                              ? _radarMousePosition!.dx - 260
                                              : _radarMousePosition!.dx + 16,
                                          top: (_radarMousePosition!.dy + 100 > constraints.maxHeight)
                                              ? _radarMousePosition!.dy - 100
                                              : _radarMousePosition!.dy + 8,
                                          child: IgnorePointer(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade800,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${sqdData[_touchedRadarIndex!]['code']}: ${sqdData[_touchedRadarIndex!]['title']}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${(sqdData[_touchedRadarIndex!]['score'] as double).toStringAsFixed(2)} / 5.00',
                                                    style: TextStyle(
                                                      color: (sqdData[_touchedRadarIndex!]['score'] as double) >= 4.5
                                                          ? Colors.greenAccent
                                                          : ((sqdData[_touchedRadarIndex!]['score'] as double) >= 4.0
                                                              ? Colors.amberAccent
                                                              : Colors.redAccent),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  SizedBox(
                                                    width: 220,
                                                    child: Text(
                                                      sqdData[_touchedRadarIndex!]['desc'] as String,
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.85),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
              ],
            );
          },
        ),
      );

    // Return appropriate scaffold based on standalone mode
    if (widget.isStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detailed Analytics'),
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brandBlue,
                brandBlue.withValues(alpha: 0.8),
                const Color(0xFF1a4d80),
              ],
            ),
          ),
          child: bodyContent,
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: bodyContent,
    );
      },
    );
  }

  Widget _buildSQDCard(Map<String, dynamic> data) {
    double score = data['score'];
    Color scoreColor = score >= 4.5 ? Colors.green : (score >= 4.0 ? Colors.amber : Colors.red);
    Color bgColor = scoreColor.withValues(alpha: 0.1);

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
                child: Text(score.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: scoreColor)),
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.analytics, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AdminTheme.bodySmall(color: Colors.grey.shade600)),
                Text(value, style: AdminTheme.headingSmall()),
                Text(sub, style: AdminTheme.bodySmall(color: color, fontWeight: FontWeight.w500)),
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
        style: AdminTheme.analysisText(color: Colors.grey.shade800),
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
                Text('Satisfaction by Service', style: AdminTheme.headingSmall()),
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
                Text('Respondent Profile', style: AdminTheme.headingSmall()),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
    } catch (e) {
      if (!mounted) return;
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

// Advanced Filter Dialog
class _AdvancedFilterDialog extends StatefulWidget {
  final DateTimeRange? currentDateRange;
  final String? currentRegion;
  final String? currentService;
  
  const _AdvancedFilterDialog({this.currentDateRange, this.currentRegion, this.currentService});
  
  @override
  State<_AdvancedFilterDialog> createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends State<_AdvancedFilterDialog> {
  DateTimeRange? _dateRange;
  String? _selectedRegion;
  String? _selectedService;
  
  @override
  void initState() {
    super.initState();
    _dateRange = widget.currentDateRange;
    _selectedRegion = widget.currentRegion;
    _selectedService = widget.currentService;
  }
  
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: brandBlue),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.filter_alt, color: brandBlue),
          const SizedBox(width: 12),
          Text('Advanced Filter', style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, color: brandBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dateRange != null
                            ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                            : 'Select date range',
                        style: TextStyle(
                          color: _dateRange != null ? Colors.black87 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            if (_dateRange != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => setState(() => _dateRange = null),
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear date range'),
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
              ),
            ],
            const SizedBox(height: 24),
            
            // Region filter
            Text('Region', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Consumer<SurveyQuestionsService>(
              builder: (context, questionsService, _) {
                final regions = questionsService.regions;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedRegion,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_on, color: brandBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'All Regions',
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('All Regions')),
                    ...regions.map((r) => DropdownMenuItem(value: r, child: Text(r))),
                  ],
                  onChanged: (value) => setState(() => _selectedRegion = value),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Service filter
            Text('Service Type', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Consumer<SurveyQuestionsService>(
              builder: (context, questionsService, _) {
                final services = questionsService.services;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedService,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.miscellaneous_services, color: brandBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'All Services',
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('All Services')),
                    ...services.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (value) => setState(() => _selectedService = value),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _dateRange = null;
              _selectedRegion = null;
              _selectedService = null;
            });
          },
          child: Text('Clear All', style: TextStyle(color: Colors.red.shade600)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'dateRange': _dateRange,
            'region': _selectedRegion,
            'service': _selectedService,
          }),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply Filter'),
        ),
      ],
    );
  }
}

// Audit Log Screen - For viewing administrator action logs
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  @override
  void initState() {
    super.initState();
    // Start real-time updates when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auditService = context.read<AuditLogServiceHttp>();
      auditService.startRealtimeUpdates();
    });
  }

  @override
  void dispose() {
    // Note: Don't stop updates here as it may still be needed
    // The service will manage its own lifecycle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const AuditLogViewer(),
      ),
    );
  }
}

// Settings Screen - For managing system settings including push notifications
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = false;
  bool _isLoading = false;
  String _permissionStatus = 'unknown';
  
  // Platform-specific services
  final _pushService = PushNotificationService.instance;
  final _nativeService = NativeNotificationService.instance;
  
  // Determine which service to use based on platform
  bool get _isDesktop => !kIsWeb;
  bool get _isSupported => _isDesktop ? _nativeService.isSupported : _pushService.isSupported;
  bool get _hasPermission => _isDesktop ? _nativeService.hasPermission : _pushService.hasPermission;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isDesktop) {
        await _nativeService.initialize();
        setState(() {
          _pushNotificationsEnabled = _nativeService.isEnabled;
          _permissionStatus = _nativeService.permissionStatus;
        });
      } else {
        await _pushService.initialize();
        setState(() {
          _pushNotificationsEnabled = _pushService.isEnabled;
          _permissionStatus = _pushService.permissionStatus ?? 'unknown';
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _togglePushNotifications(bool enabled) async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthServiceHttp>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (_isDesktop) {
        // Desktop native notifications
        if (enabled) {
          final success = await _nativeService.enableNotifications(
            currentUser?.id ?? 'unknown',
            currentUser?.email ?? 'unknown@example.com',
          );
          
          if (success) {
            setState(() {
              _pushNotificationsEnabled = true;
              _permissionStatus = _nativeService.permissionStatus;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Desktop notifications enabled successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to enable desktop notifications'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          await _nativeService.disableNotifications(currentUser?.id ?? 'unknown');
          setState(() => _pushNotificationsEnabled = false);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Desktop notifications disabled'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // Web push notifications
        if (enabled) {
          final success = await _pushService.enableNotifications(
            currentUser?.id ?? 'unknown',
            currentUser?.email ?? 'unknown@example.com',
          );
          
          if (success) {
            setState(() {
              _pushNotificationsEnabled = true;
              _permissionStatus = _pushService.permissionStatus ?? 'granted';
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Push notifications enabled successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _pushService.permissionStatus == 'denied'
                        ? 'Notification permission denied. Please enable in browser settings.'
                        : 'Failed to enable push notifications',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          await _pushService.disableNotifications(currentUser?.id ?? 'unknown');
          setState(() => _pushNotificationsEnabled = false);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Push notifications disabled'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _testNotification() async {
    try {
      if (_isDesktop) {
        await _nativeService.showLocalNotification(
          title: '🔔 Test Notification',
          body: 'This is a test notification from V-Serve. Desktop notifications are working!',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test notification sent! Check your desktop.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        await _pushService.showLocalNotification(
          title: '🔔 Test Notification',
          body: 'This is a test notification from V-Serve. Push notifications are working!',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test notification sent! Check your browser.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Use platform-aware helper getters instead of direct service access
    final notificationTitle = _isDesktop ? 'Desktop Notifications' : 'Push Notifications';
    final notificationDesc = _isDesktop 
        ? 'Receive native desktop notifications for high-severity alerts'
        : 'Receive instant browser notifications for high-severity alerts';
    final supportTitle = _isDesktop ? 'Platform Support' : 'Browser Support';
    final supportDesc = _isSupported
        ? (_isDesktop ? 'Your system supports native notifications' : 'Your browser supports push notifications')
        : (_isDesktop ? 'Desktop notifications not available on this platform' : 'Push notifications not supported in this browser');
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AdminTheme.headingLarge(
                        color: Colors.white,
                      ).copyWith(fontSize: 24),
                      children: const <TextSpan>[
                        TextSpan(
                          text: 'System ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Settings',
                          style: TextStyle(color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure notification preferences and system behavior.',
                    style: AdminTheme.bodyMedium(
                      color: Colors.white,
                    ).copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Push Notifications Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: brandBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: brandBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notificationTitle,
                              style: AdminTheme.headingMedium(
                                color: brandBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notificationDesc,
                              style: AdminTheme.bodyMedium(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Browser Support Status
                  _buildSettingRow(
                    icon: _isDesktop ? Icons.computer : Icons.web,
                    title: supportTitle,
                    subtitle: supportDesc,
                    trailing: Icon(
                      _isSupported ? Icons.check_circle : Icons.cancel,
                      color: _isSupported ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Permission Status
                  _buildSettingRow(
                    icon: Icons.security,
                    title: 'Permission Status',
                    subtitle: _getPermissionDescription(_permissionStatus),
                    trailing: Icon(
                      _getPermissionIcon(_permissionStatus),
                      color: _getPermissionColor(_permissionStatus),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Enable/Disable Toggle
                  _buildSettingRow(
                    icon: Icons.notifications,
                    title: 'Enable Notifications',
                    subtitle: 'Get notified when high/critical severity events occur',
                    trailing: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: _pushNotificationsEnabled,
                            onChanged: _isSupported ? _togglePushNotifications : null,
                            activeThumbColor: brandBlue,
                          ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Test Notification Button
                  if (_pushNotificationsEnabled && _hasPermission)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _testNotification,
                        icon: const Icon(Icons.send),
                        label: const Text('Send Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About Alert Notifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Push notifications are triggered for HIGH and CRITICAL severity events, including:\n'
                                '• Failed login attempts\n'
                                '• User account deletions\n'
                                '• Feedback data deletions\n'
                                '• User role/status changes',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
  
  String _getPermissionDescription(String status) {
    switch (status) {
      case 'granted':
        return 'Permission granted - notifications can be sent';
      case 'denied':
        return 'Permission denied - enable in browser settings';
      case 'default':
        return 'Permission not yet requested';
      default:
        return 'Permission status unknown';
    }
  }
  
  IconData _getPermissionIcon(String status) {
    switch (status) {
      case 'granted':
        return Icons.check_circle;
      case 'denied':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }
  
  Color _getPermissionColor(String status) {
    switch (status) {
      case 'granted':
        return Colors.green;
      case 'denied':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
