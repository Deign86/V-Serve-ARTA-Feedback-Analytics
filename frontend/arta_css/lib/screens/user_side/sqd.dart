import 'package:flutter/material.dart';
import '../../services/survey_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/offline_queue_stub.dart';
import '../../services/survey_questions_service.dart';
import '../../widgets/offline_queue_widget.dart';
import '../../widgets/smooth_scroll_view.dart';
import '../../widgets/survey_progress_bar.dart';
import '../../services/survey_config_service.dart';
import 'suggestions.dart'; // ThankYouScreen is defined here

class SQDScreen extends StatefulWidget {
  final bool isPreviewMode;
  
  const SQDScreen({super.key, this.isPreviewMode = false});

  @override
  State<SQDScreen> createState() => _SQDScreenState();
}

class _SQDScreenState extends State<SQDScreen> {
  late ScrollController _scrollController;
  final Set<int> _errorIndices = {};
  final Map<int, GlobalKey> _questionKeys = {};

  List<int?> answers = List<int?>.filled(9, null);

  // Get questions from the service dynamically
  List<Map<String, dynamic>> _getQuestions(BuildContext context) {
    final questionsService = context.read<SurveyQuestionsService>();
    return questionsService.sqdQuestions.map((q) => {
      'label': q.label,
      'question': q.question,
    }).toList();
  }

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
    
    // Initialize from provider
    final surveyData = context.read<SurveyProvider>().surveyData;
      
    answers[0] = surveyData.sqd0Rating;
    answers[1] = surveyData.sqd1Rating;
    answers[2] = surveyData.sqd2Rating;
    answers[3] = surveyData.sqd3Rating;
    answers[4] = surveyData.sqd4Rating;
    answers[5] = surveyData.sqd5Rating;
    answers[6] = surveyData.sqd6Rating;
    answers[7] = surveyData.sqd7Rating;
    answers[8] = surveyData.sqd8Rating;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns true if all SQD questions have been answered
  bool get _isFormComplete {
    return answers.every((answer) => answer != null);
  }

  bool _validateForm() {
    _errorIndices.clear();
    for (int i = 0; i < answers.length; i++) {
      if (answers[i] == null) {
        _errorIndices.add(i);
      }
    }
    return _errorIndices.isEmpty;
  }
  
  void _scrollToFirstError() {
    if (_errorIndices.isNotEmpty) {
      final firstErrorIndex = _errorIndices.first;
      final key = _questionKeys[firstErrorIndex];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.2, // Position slightly below the top
        );
      }
    }
  }

  void _scrollToNextQuestion(int currentIndex, int totalQuestions) {
    // Only scroll if there's a next question
    if (currentIndex < totalQuestions - 1) {
      final nextIndex = currentIndex + 1;
      // Ensure the key exists for the next question
      if (!_questionKeys.containsKey(nextIndex)) {
        _questionKeys[nextIndex] = GlobalKey();
      }
      final key = _questionKeys[nextIndex];
      // Add a small delay to let the UI update before scrolling
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.15, // Position near the top
          );
        }
      });
    }
  }

  bool _isSubmitting = false;

    void _onNextPressed() async {
    if (_validateForm()) {
      // Clear errors
      setState(() {
        _errorIndices.clear();
      });

      // Update Provider
      context.read<SurveyProvider>().updateSQD(
        sqd0: answers[0],
        sqd1: answers[1],
        sqd2: answers[2],
        sqd3: answers[3],
        sqd4: answers[4],
        sqd5: answers[5],
        sqd6: answers[6],
        sqd7: answers[7],
        sqd8: answers[8],
      );
      
      final surveyData = context.read<SurveyProvider>().surveyData;
      
      // Check if suggestions are enabled
      final configService = context.read<SurveyConfigService>();
      
      if (configService.suggestionsEnabled) {
        // Go to suggestions screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SuggestionsScreen(isPreviewMode: widget.isPreviewMode)),
        );
      } else {
        // Skip suggestions - submit directly and go to thank you
        setState(() => _isSubmitting = true);
        
        // Skip database submission in preview mode
        if (widget.isPreviewMode) {
          if (!mounted) return;
          context.read<SurveyProvider>().resetSurvey();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ThankYouScreen(isPreviewMode: widget.isPreviewMode)),
          );
          return;
        }
        
        try {
          await OfflineQueue.enqueue(surveyData.toJson());
          await OfflineQueue.flush();
          
          if (!mounted) return;
          
          context.read<SurveyProvider>().resetSurvey();
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ThankYouScreen()),
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
      setState(() {}); // Trigger rebuild to show errors
      _scrollToFirstError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer the highlighted questions before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final configService = context.watch<SurveyConfigService>();
    // Calculate current step dynamically
    final currentStep = configService.calculateStepNumber(SurveyStep.sqd);
    final totalSteps = configService.totalSteps;

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
                    SurveyProgressBar(
                      currentStep: currentStep,
                      totalSteps: totalSteps,
                      isMobile: isMobile,
                      customSteps: configService.getVisibleProgressBarSteps(),
                    ),
                    SizedBox(height: isMobile ? 16 : 24),
                    Expanded(child: _buildFormCard(isMobile)),
                  ],
                ),
              ),
            ),
          ),
          // Offline Queue Banner (shows only when needed)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OfflineQueueBanner(),
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
            fontSize: isMobile ? 14 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'HELP US SERVE YOU BETTER!',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 10 : 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isMobile) {
    final configService = context.watch<SurveyConfigService>();
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
            child: SmoothScrollView(
              controller: _scrollController,
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
                          'PART ${configService.calculateStepNumber(SurveyStep.sqd)}',
                          style: GoogleFonts.montserrat(
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFACF1F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.watch<SurveyQuestionsService>().sqdSectionTitle,
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
                  
                  // Questions List - Using questions from the service
                  Builder(
                    builder: (context) {
                      final questions = _getQuestions(context);
                      return Column(
                        children: List.generate(
                          questions.length,
                          (i) => _sqdQuestion(isMobile, i, questions),
                        ),
                      );
                    },
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isVeryNarrow = constraints.maxWidth < 340;
                final buttonWidth = isVeryNarrow ? 100.0 : (isMobile ? 140.0 : 180.0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      height: isMobile ? 48 : 55,
                      child: OutlinedButton(
                        onPressed: () {
                          // Save current state before going back
                          context.read<SurveyProvider>().updateSQD(
                            sqd0: answers[0],
                            sqd1: answers[1],
                            sqd2: answers[2],
                            sqd3: answers[3],
                            sqd4: answers[4],
                            sqd5: answers[5],
                            sqd6: answers[6],
                            sqd7: answers[7],
                            sqd8: answers[8],
                          );
                          Navigator.of(context).maybePop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF003366), width: 2),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: isMobile ? 16 : 18,
                              color: const Color(0xFF003366),
                            ),
                            SizedBox(width: isVeryNarrow ? 2 : (isMobile ? 4 : 8)),
                            Text(
                              isVeryNarrow ? 'BACK' : 'PREVIOUS',
                              style: GoogleFonts.montserrat(
                                fontSize: isVeryNarrow ? 10 : (isMobile ? 12 : 14),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF003366),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      height: isMobile ? 48 : 55,
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || !_isFormComplete) ? null : _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          disabledBackgroundColor: Colors.grey.shade400,
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
                                isVeryNarrow ? 'NEXT' : 'NEXT PAGE',
                                style: GoogleFonts.montserrat(
                                  fontSize: isVeryNarrow ? 10 : (isMobile ? 12 : 14),
                                  fontWeight: FontWeight.bold,
                                  color: _isFormComplete ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sqdQuestion(bool isMobile, int index, List<Map<String, dynamic>> questions) {
    // Generate key if needed
    if (!_questionKeys.containsKey(index)) {
      _questionKeys[index] = GlobalKey();
    }
    
    final bool hasError = _errorIndices.contains(index);
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
          onTap: () {
            final wasAlreadyAnswered = answers[index] != null;
            setState(() {
              answers[index] = optIdx;
              _errorIndices.remove(index); // Clear error on select
            });
            // Auto-scroll to next question only on first answer (not when changing)
            if (!wasAlreadyAnswered) {
              _scrollToNextQuestion(index, questions.length);
            }
          },
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
      key: _questionKeys[index],
      padding: EdgeInsets.only(bottom: isMobile ? 32 : 48),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(hasError ? 12 : 0),
        decoration: BoxDecoration(
          color: hasError ? Colors.red.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: hasError ? Border.all(color: Colors.red, width: 2) : null,
        ),
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

                  child: emojiRow,
                ),
              )
            : emojiRow,
        ],
      ),
      ),
    );
  }
}

