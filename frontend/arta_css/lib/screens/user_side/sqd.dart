import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/survey_data.dart';
import '../../services/offline_queue.dart';
import '../../services/survey_config_service.dart';
import 'suggestions.dart';

class SQDScreen extends StatefulWidget {
  final SurveyData surveyData;
  
  const SQDScreen({
    super.key,
    required this.surveyData,
  });

  @override
  State<SQDScreen> createState() => _SQDScreenState();
}

class _SQDScreenState extends State<SQDScreen> {
  late ScrollController _scrollController;

  List<int?> answers = List<int?>.filled(9, null);

  final List<Map<String, dynamic>> questions = [
    {
      'label': 'SQD 0',
      'question': 'I am satisfied with the service that I availed.',
    },
    {
      'label': 'SQD 1',
      'question': 'I spent a reasonable amount of time for my transaction.',
    },
    {
      'label': 'SQD 2',
      'question':
          'The office followed the transaction\'s requirements and steps based on the information provided.',
    },
    {
      'label': 'SQD 3',
      'question':
          'The steps (including payment) I needed to do for my transaction were easy and simple.',
    },
    {
      'label': 'SQD 4',
      'question':
          'I easily found information about my transaction from the office or its website.',
    },
    {
      'label': 'SQD 5',
      'question':
          'I paid a reasonable amount of fees for my transaction. (If service was free, mark the \'N/A\' column)',
    },
    {
      'label': 'SQD 6',
      'question':
          'I feel the office was fair to everyone, or \'walang palakasan\', during my transaction.',
    },
    {
      'label': 'SQD 7',
      'question':
          'I was treated courteously by the staff, and (if asked for help) the staff was helpful.',
    },
    {
      'label': 'SQD 8',
      'question':
          'I got what I needed from the government office, or (if denied) denial of request was sufficiently explained to me.',
    },
  ];

  final List<String> emojis = [
    'assets/emojis/strongly_disagree.png',
    'assets/emojis/disagree.png',
    'assets/emojis/neutral.png',
    'assets/emojis/agree.png',
    'assets/emojis/strongly_agree.png',
    'N/A', // text-only option
  ];

  final List<String> labels = [
    'Strongly Disagree',
    'Disagree',
    'Neither Agree nor Disagree',
    'Agree',
    'Strongly Agree',
    'Not Applicable',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    for (final ans in answers) {
      if (ans == null) return false;
    }
    return true;
  }

  bool _isSubmitting = false;

  void _onNextPressed() async {
    if (_isFormValid()) {
      final updatedData = widget.surveyData.copyWith(
        sqd0Rating: answers[0],
        sqd1Rating: answers[1],
        sqd2Rating: answers[2],
        sqd3Rating: answers[3],
        sqd4Rating: answers[4],
        sqd5Rating: answers[5],
        sqd6Rating: answers[6],
        sqd7Rating: answers[7],
        sqd8Rating: answers[8],
      );
      
      // Check if suggestions are enabled
      final configService = context.read<SurveyConfigService>();
      
      if (configService.suggestionsEnabled) {
        // Go to suggestions screen
        Navigator.push(
          context,
          SmoothPageRoute(page: SuggestionsScreen(surveyData: updatedData)),
        );
      } else {
        // Skip suggestions - submit directly and go to thank you
        setState(() => _isSubmitting = true);
        
        try {
          await OfflineQueue.enqueue(updatedData.toJson());
          await OfflineQueue.flush();
          
          if (!mounted) return;
          
          Navigator.pushReplacement(
            context,
            SmoothPageRoute(page: const ThankYouScreen()),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final currentStep = 3; 
    final totalSteps = 4;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/city_bg2.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Center(
              child: Container(
                width: isMobile ? double.infinity : 1200,
                height: MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).padding.top +
                        MediaQuery.of(context).padding.bottom +
                        50),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 40,
                  vertical: isMobile ? 16 : 24,
                ),
                child: Column(
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildProgressBar(isMobile, currentStep, totalSteps),
                    SizedBox(height: isMobile ? 16 : 24),
                    Expanded(child: _buildFormCard(isMobile)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        CircleAvatar(
          radius: isMobile ? 16 : 22,
          backgroundImage: const AssetImage('assets/city_logo.png'),
          backgroundColor: Colors.white,
        ),
        SizedBox(height: isMobile ? 7 : 10),
        Text(
          'CITY GOVERNMENT OF VALENZUELA',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'HELP US SERVE YOU BETTER!',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 10 : 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isMobile, int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        final isActive = index == current - 1;
        final isCompleted = index < current - 1;
        return Expanded(
          child: Container(
            height: isMobile ? 6 : 8,
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? const Color(0xFF0099FF)
                  : isCompleted
                      ? const Color(0xFF36A0E1)
                      : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFormCard(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 24 : 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Area
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PART 3',
                          style: GoogleFonts.montserrat(
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFACF1F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SQD',
                        style: GoogleFonts.montserrat(
                          fontSize: isMobile ? 20 : 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003366),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isMobile ? 16 : 24),
                  
                  // Instruction Box
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF003366), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'INSTRUCTIONS',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF003366),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'For SQD 0-8, please select the option that best corresponds to your answer.',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 32),
                  
                  // Questions List
                  ...List.generate(
                    questions.length,
                    (i) => _sqdQuestion(isMobile, i),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation Area
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 40),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: isMobile ? 140 : 180,
                  height: isMobile ? 48 : 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF003366), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'PREVIOUS',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003366),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isMobile ? 140 : 180,
                  height: isMobile ? 48 : 55,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onNextPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'NEXT PAGE',
                            style: GoogleFonts.montserrat(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sqdQuestion(bool isMobile, int index) {
    final q = questions[index];

    final List<Color> borderColors = [
      Colors.red,
      Colors.deepOrange,
      Colors.amber,
      Colors.lightGreen,
      Colors.green,
      Colors.grey,
    ];
    final List<Color> bgColors = [
      Colors.red.shade50,
      Colors.orange.shade50,
      Colors.yellow.shade50,
      Colors.lightGreen.shade50,
      Colors.green.shade50,
      Colors.grey.shade100,
    ];

    // 1. DEFINE THE ROW CONTENT
    Widget emojiRow = Row(
      // On Desktop: Center the emojis. On Mobile: Start (for scroll).
      mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: List.generate(emojis.length, (optIdx) {
        final bool selected = answers[index] == optIdx;
        final bool isNA = optIdx == 5;
        
        return GestureDetector(
          onTap: () => setState(() => answers[index] = optIdx),
          child: AnimatedScale(
            scale: selected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isMobile ? 55 : 110,
              height: isMobile ? 75 : 130,
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 4 : 8,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected ? bgColors[optIdx] : Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                border: Border.all(
                  color: selected ? borderColors[optIdx] : Colors.grey.shade300,
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: borderColors[optIdx].withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: isNA
                        ? Center(
                            child: Text(
                              'N/A',
                              style: GoogleFonts.montserrat(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14 : 28,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              emojis[optIdx],
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Center(
                        child: Text(
                          labels[optIdx],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 8 : 12,
                            color: isNA ? Colors.red.shade700 : Colors.black87,
                            fontWeight: isNA || selected ? FontWeight.w600 : FontWeight.w500,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 32 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF003366),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  q['label'], 
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFACF1F),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q['question'],
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 14 : 16,
                    color: const Color(0xFF003366),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 2. THE RESPONSIVE SELECTION AREA
          // On Desktop: Just the Row (Centered). On Mobile: Scrollable.
          isMobile 
            ? Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: emojiRow,
                ),
              )
            : emojiRow,
        ],
      ),
    );
  }
}

class SmoothPageRoute extends PageRouteBuilder {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 600),
        );
}