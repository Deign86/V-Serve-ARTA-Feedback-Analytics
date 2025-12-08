import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/survey_data.dart';
import '../../services/offline_queue.dart';
import '../../services/survey_config_service.dart';

class SuggestionsScreen extends StatefulWidget {
  final SurveyData surveyData;
  
  const SuggestionsScreen({
    super.key,
    required this.surveyData,
  });

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  late TextEditingController _suggestionsController;
  late TextEditingController _emailController;
  bool _isSubmitting = false;
  bool _hasSubmitted = false; // Guard against duplicate submissions

  @override
  void initState() {
    super.initState();
    _suggestionsController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _suggestionsController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final configService = Provider.of<SurveyConfigService>(context);
    final currentStep = configService.getStepNumber(SurveyStep.suggestions);
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
                height:
                    MediaQuery.of(context).size.height -
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
          backgroundImage: AssetImage('assets/city_logo.png'),
        ),
        SizedBox(height: isMobile ? 7 : 10),
        Text(
          'CITY GOVERNMENT OF VALENZUELA',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'HELP US SERVE YOU BETTER!',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 10 : 12,
            color: Colors.white70,
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
              color: isActive || isCompleted
                  ? const Color(0xFF0099FF)
                  : Colors.grey.shade300,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black12)],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PART 3: SUGGESTIONS (OPTIONAL)',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003366),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 32),
              _buildSuggestionsField(isMobile),
              SizedBox(height: isMobile ? 24 : 32),
              _buildEmailField(isMobile),
              SizedBox(height: isMobile ? 32 : 48),
              _buildNavigationButtons(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions on how we can further improve our services (Optional)',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Color(0XFF1C1E97)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: TextField(
            controller: _suggestionsController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Write your suggestions here...',
              hintStyle: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey.shade600,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address (Optional)',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Color(0XFF1C1E97)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email address here...',
              hintStyle: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey.shade600,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 10 : 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: isMobile ? 140 : 180,
          height: isMobile ? 44 : 50,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF003366)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              'PREVIOUS PAGE',
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
          height: isMobile ? 44 : 50,
          child: ElevatedButton(
            onPressed: (_isSubmitting || _hasSubmitted) ? null : () async {
              // Guard against duplicate submissions
              if (_hasSubmitted) {
                debugPrint('Survey already submitted, ignoring duplicate submission attempt');
                return;
              }
              
              // Collect Part 4 data
              final finalData = widget.surveyData.copyWith(
                suggestions: _suggestionsController.text.trim().isEmpty 
                    ? null 
                    : _suggestionsController.text.trim(),
                email: _emailController.text.trim().isEmpty 
                    ? null 
                    : _emailController.text.trim(),
              );
              
              debugPrint('=== SUBMITTING SURVEY ===');
              debugPrint('Survey data: ${finalData.toJson()}');
              
              setState(() {
                _isSubmitting = true;
                _hasSubmitted = true; // Mark as submitted to prevent duplicates
              });
              
              try {
                // Save complete survey data to offline queue (will sync to Firestore)
                debugPrint('Enqueueing data...');
                await OfflineQueue.enqueue(finalData.toJson());
                debugPrint('Data enqueued successfully');
                
                // Try to flush immediately (will fail silently if offline)
                debugPrint('Attempting to flush to Firestore...');
                final flushed = await OfflineQueue.flush();
                debugPrint('Flush completed. Items saved: $flushed');
                
                if (!mounted) return;
                
                // Navigate to thank you screen - use pushAndRemoveUntil to clear the survey stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const ThankYouScreen()),
                  (route) => route.isFirst, // Keep only the landing page
                );
              } catch (e, stackTrace) {
                debugPrint('ERROR saving survey: $e');
                debugPrint('Stack trace: $stackTrace');
                
                if (!mounted) return;
                
                setState(() {
                  _isSubmitting = false;
                  _hasSubmitted = false; // Allow retry on error
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving survey: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
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
                    'SUBMIT SURVEY',
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

//THANK YOU WIDGET

class ThankYouScreen extends StatefulWidget {
  const ThankYouScreen({super.key});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  int _kioskCountdown = 10; // Countdown seconds for kiosk mode
  bool _isKioskMode = false;

  @override
  void initState() {
    super.initState();
    // Check kiosk mode after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkKioskMode();
    });
  }

  void _checkKioskMode() {
    final configService = Provider.of<SurveyConfigService>(context, listen: false);
    if (configService.kioskMode) {
      setState(() {
        _isKioskMode = true;
      });
      _startKioskCountdown();
    }
  }

  void _startKioskCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_kioskCountdown > 1) {
        setState(() {
          _kioskCountdown--;
        });
        _startKioskCountdown();
      } else {
        // Auto-navigate back to landing page
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    // Clear the navigation stack and go to landing page
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
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
                width: isMobile ? double.infinity : 900,
                height: isMobile ? double.infinity : 500,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    // Comments Section
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 24 : 40,
                            vertical: isMobile ? 32 : 48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Additional Comments:",
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                                fontSize: isMobile ? 16 : 18,
                              ),
                            ),
                            SizedBox(height: isMobile ? 12 : 18),
                            // Gradient border for TextField
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade600,
                                    Color(0XFF1C1E97),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                child: TextField(
                                  maxLines: 6,
                                  decoration: InputDecoration(
                                    hintText: 'Write your comments here...',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.all(isMobile ? 16 : 22),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 24 : 32),
                            Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: isMobile ? double.infinity : 180,
                                    height: isMobile ? 40 : 50,
                                    child: ElevatedButton(
                                      onPressed: _navigateToHome,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF003366),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: Text(
                                        _isKioskMode ? 'START NEW SURVEY' : 'BACK TO HOME',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: isMobile ? 11 : 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isKioskMode) ...[
                                    SizedBox(height: 12),
                                    Text(
                                      'Auto-reset in $_kioskCountdown seconds...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Thank You Section
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF1C1E97),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24,
                            vertical: isMobile ? 24 : 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Spacer(),
                            Text(
                              "THANK YOU",
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 24 : 32,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isMobile ? 10 : 16),
                            Text(
                              "FOR YOUR FEEDBACK!",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: isMobile ? 12 : 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Spacer(),
                          ],
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
  }
}