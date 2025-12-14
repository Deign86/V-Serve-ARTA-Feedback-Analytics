import 'package:flutter/material.dart';
import '../../services/survey_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/survey_config_service.dart';
import '../../services/survey_questions_service.dart';
import '../../services/offline_queue.dart';
import '../../widgets/offline_queue_widget.dart';
import '../../widgets/survey_progress_bar.dart';
import 'sqd.dart';
import 'suggestions.dart'; // ThankYouScreen is defined here
import '../../widgets/smooth_scroll_view.dart';

class CitizenCharterScreen extends StatefulWidget {
  final bool isPreviewMode;
  
  const CitizenCharterScreen({super.key, this.isPreviewMode = false});

  @override
  State<CitizenCharterScreen> createState() => _CitizenCharterScreenState();
}

class _CitizenCharterScreenState extends State<CitizenCharterScreen> {
  late ScrollController _scrollController;
  final Set<String> _errorFields = {};
  final Map<String, GlobalKey> _questionKeys = {
    'CC1': GlobalKey(),
    'CC2': GlobalKey(),
    'CC3': GlobalKey(),
  };

  String? cc1Answer;
  String? cc2Answer;
  String? cc3Answer;

  // Get options from the questions service
  List<String> get cc1Options => context.read<SurveyQuestionsService>().getCcQuestion('CC1')?.options ?? 
    SurveyQuestionsService.defaultCcQuestions[0].options;
  
  List<String> get cc2Options => context.read<SurveyQuestionsService>().getCcQuestion('CC2')?.options ?? 
    SurveyQuestionsService.defaultCcQuestions[1].options;
  
  List<String> get cc3Options => context.read<SurveyQuestionsService>().getCcQuestion('CC3')?.options ?? 
    SurveyQuestionsService.defaultCcQuestions[2].options;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Initialize from provider
    final surveyData = context.read<SurveyProvider>().surveyData;
    final questionsService = context.read<SurveyQuestionsService>();
    
    final cc1Opts = questionsService.getCcQuestion('CC1')?.options ?? 
        SurveyQuestionsService.defaultCcQuestions[0].options;
    final cc2Opts = questionsService.getCcQuestion('CC2')?.options ?? 
        SurveyQuestionsService.defaultCcQuestions[1].options;
    final cc3Opts = questionsService.getCcQuestion('CC3')?.options ?? 
        SurveyQuestionsService.defaultCcQuestions[2].options;
    
    // CC1
    if (surveyData.cc0Rating != null) {
      // Find the option string that corresponds to the rating
      // 1-based index in options
      if (surveyData.cc0Rating! >= 1 && surveyData.cc0Rating! <= cc1Opts.length) {
        cc1Answer = cc1Opts[surveyData.cc0Rating! - 1];
      }
    }
    
    // CC2
    if (surveyData.cc1Rating != null) {
       if (surveyData.cc1Rating! >= 1 && surveyData.cc1Rating! <= cc2Opts.length) {
        cc2Answer = cc2Opts[surveyData.cc1Rating! - 1];
      }
    }
    
    // CC3
    if (surveyData.cc2Rating != null) {
       if (surveyData.cc2Rating! >= 1 && surveyData.cc2Rating! <= cc3Opts.length) {
        cc3Answer = cc3Opts[surveyData.cc2Rating! - 1];
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns true if all required CC questions are answered
  bool get _isFormComplete {
    // CC1 is always required
    if (cc1Answer == null) return false;
    
    // CC2 and CC3 are required
    if (cc2Answer == null) return false;
    if (cc3Answer == null) return false;
    
    return true;
  }

  bool _validateForm() {
    _errorFields.clear();
    
    // Validate CC1
    if (cc1Answer == null) {
      _errorFields.add('CC1');
    }

    // Validate CC2 & CC3 based on CC1
    if (cc1Answer != null && cc1Answer!.startsWith('4.')) {
      // If "I do not know", enforce N/A Selection
      // Find N/A options dynamically (last option in each list typically)
      final cc2NaOption = cc2Options.lastWhere(
        (o) => o.toLowerCase().contains('not applicable') || o.toLowerCase().contains('n/a'),
        orElse: () => cc2Options.last,
      );
      final cc3NaOption = cc3Options.lastWhere(
        (o) => o.toLowerCase().contains('not applicable') || o.toLowerCase().contains('n/a'),
        orElse: () => cc3Options.last,
      );
      if (cc2Answer != cc2NaOption) _errorFields.add('CC2');
      if (cc3Answer != cc3NaOption) _errorFields.add('CC3');
    } else {
      // Normal flow - require answers if strictly enforcing
      // Note: The original logic implicitly required them unless CC1 was 4.
      // So if CC1 is NOT 4, we require CC2 and CC3.
      if (cc2Answer == null) _errorFields.add('CC2');
      if (cc3Answer == null) _errorFields.add('CC3');
    }

    return _errorFields.isEmpty;
  }

  void _scrollToFirstError() {
    if (_errorFields.isNotEmpty) {
      // Order of fields to check
      final order = ['CC1', 'CC2', 'CC3'];
      for (final key in order) {
        if (_errorFields.contains(key)) {
          final globalKey = _questionKeys[key];
          if (globalKey?.currentContext != null) {
            Scrollable.ensureVisible(
              globalKey!.currentContext!,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: 0.2, 
            );
            return; // Scroll to first one found only
          }
        }
      }
    }
  }

  void _scrollToNextQuestion(String currentCode) {
    // Define the order of questions
    final questionOrder = ['CC1', 'CC2', 'CC3'];
    final currentIndex = questionOrder.indexOf(currentCode);
    
    // Only scroll if there's a next question
    if (currentIndex >= 0 && currentIndex < questionOrder.length - 1) {
      final nextCode = questionOrder[currentIndex + 1];
      final key = _questionKeys[nextCode];
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

  void _onNextPressed() async {
    if (_validateForm()) {
      setState(() => _errorFields.clear());
      
      final cc0Rating = cc1Answer != null ? int.tryParse(cc1Answer!.substring(0, 1)) : null;
      final cc1Rating = cc2Answer != null ? int.tryParse(cc2Answer!.substring(0, 1)) : null;
      final cc2Rating = cc3Answer != null ? int.tryParse(cc3Answer!.substring(0, 1)) : null;
      
      // Update Provider
      context.read<SurveyProvider>().updateCC(
        cc0: cc0Rating,
        cc1: cc1Rating,
        cc2: cc2Rating,
      );
      
      final surveyData = context.read<SurveyProvider>().surveyData;
      
      // Check which sections are enabled
      final configService = context.read<SurveyConfigService>();
      
      if (configService.sqdEnabled) {
        // Go to SQD
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SQDScreen(isPreviewMode: widget.isPreviewMode)),
        );
      } else if (configService.suggestionsEnabled) {
        // Skip SQD, go to Suggestions
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SuggestionsScreen(isPreviewMode: widget.isPreviewMode)),
        );
      } else {
        // All remaining sections disabled - submit directly
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      setState(() {});
      _scrollToFirstError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all required questions correctly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final configService = context.watch<SurveyConfigService>();
    final currentStep = configService.calculateStepNumber(SurveyStep.citizenCharter);
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
                    horizontal: isMobile ? 12 : 40, vertical: isMobile ? 16 : 24),
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
                          'PART ${configService.calculateStepNumber(SurveyStep.citizenCharter)}',
                          style: GoogleFonts.montserrat(
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFACF1F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.watch<SurveyQuestionsService>().ccSectionTitle,
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
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD), // Very light blue
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
                          'Please select the option that best describes your experience with the Citizen\'s Charter (CC). If you answer "I do not know what a CC is" (Option 4) in CC1, please select "Not Applicable" for CC2 and CC3.',
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
                  
                  // CC1
                  Builder(
                    builder: (context) {
                      final questionsService = context.watch<SurveyQuestionsService>();
                      final cc1Question = questionsService.getCcQuestion('CC1');
                      return _ccCard(
                        code: 'CC1',
                        question: cc1Question?.question ?? 'Which of the following best describes your awareness of a CC?',
                        options: cc1Options,
                        selectedValue: cc1Answer,
                        onChanged: (val) {
                           final wasAlreadyAnswered = cc1Answer != null;
                           setState(() {
                             cc1Answer = val;
                             _errorFields.remove('CC1');
                           });
                           // Auto-scroll to next question only on first answer
                           if (!wasAlreadyAnswered) {
                             _scrollToNextQuestion('CC1');
                           }
                        },
                        isMobile: isMobile,
                      );
                    },
                  ),
                  
                  SizedBox(height: isMobile ? 32 : 48),
                  
                  // CC2
                  Builder(
                    builder: (context) {
                      final questionsService = context.watch<SurveyQuestionsService>();
                      final cc2Question = questionsService.getCcQuestion('CC2');
                      return _ccCard(
                        code: 'CC2',
                        question: cc2Question?.question ?? 'If aware of CC (answered 1-3 in CC1), would you say that the CC of this office was ...?',
                        options: cc2Options,
                        selectedValue: cc2Answer,
                        onChanged: (val) {
                           final wasAlreadyAnswered = cc2Answer != null;
                           setState(() {
                             cc2Answer = val;
                             _errorFields.remove('CC2');
                           });
                           // Auto-scroll to next question only on first answer
                           if (!wasAlreadyAnswered) {
                             _scrollToNextQuestion('CC2');
                           }
                        },
                        isMobile: isMobile,
                      );
                    },
                  ),
                  
                  SizedBox(height: isMobile ? 32 : 48),
                  
                  // CC3
                  Builder(
                    builder: (context) {
                      final questionsService = context.watch<SurveyQuestionsService>();
                      final cc3Question = questionsService.getCcQuestion('CC3');
                      return _ccCard(
                        code: 'CC3',
                        question: cc3Question?.question ?? 'If aware of CC (answered codes 1-3 in CC1), how much did the CC help you in your transaction?',
                        options: cc3Options,
                        selectedValue: cc3Answer,
                        onChanged: (val) {
                           setState(() {
                             cc3Answer = val;
                             _errorFields.remove('CC3');
                           });
                        },
                        isMobile: isMobile,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation Area
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
                    onPressed: () {
                      // Save current state before going back
                      final cc0Rating = cc1Answer != null ? int.tryParse(cc1Answer!.substring(0, 1)) : null;
                      final cc1Rating = cc2Answer != null ? int.tryParse(cc2Answer!.substring(0, 1)) : null;
                      final cc2Rating = cc3Answer != null ? int.tryParse(cc3Answer!.substring(0, 1)) : null;
                      
                      context.read<SurveyProvider>().updateCC(
                        cc0: cc0Rating,
                        cc1: cc1Rating,
                        cc2: cc2Rating,
                      );
                      Navigator.of(context).maybePop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF003366), width: 2),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: isMobile ? 16 : 18,
                          color: const Color(0xFF003366),
                        ),
                        SizedBox(width: isMobile ? 4 : 8),
                        Text(
                          'PREVIOUS',
                          style: GoogleFonts.montserrat(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF003366),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: isMobile ? 140 : 180,
                  height: isMobile ? 48 : 55,
                  child: ElevatedButton(
                    onPressed: _isFormComplete ? _onNextPressed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      disabledBackgroundColor: Colors.grey.shade400,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'NEXT PAGE',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: _isFormComplete ? Colors.white : Colors.grey.shade600,
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

  // --- NEW CARD STYLE WIDGET ---
  Widget _ccCard({
    required String code,
    required String question,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onChanged,
    required bool isMobile,
  }) {
    final hasError = _errorFields.contains(code);
    return Padding(
      key: _questionKeys[code],
      padding: EdgeInsets.zero,
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
                code,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFACF1F),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF003366),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: isMobile ? 16 : 24),
        
        // Options List (Converted to clickable cards)
        ...options.map((option) {
          final isSelected = selectedValue == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onChanged(option),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF003366).withValues(alpha: 0.05) 
                      : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF003366) : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected 
                      ? [] 
                      : [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    // Custom Radio Circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFF003366) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF003366) : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: isSelected 
                          ? const Icon(Icons.check, size: 16, color: Colors.white) 
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Option Text
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 13 : 15,
                          color: isSelected ? const Color(0xFF003366) : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        ],
      ),
      ),
    );
  }
}

