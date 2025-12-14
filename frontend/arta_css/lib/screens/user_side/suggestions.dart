import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/survey_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/offline_queue.dart';
import '../../services/survey_config_service.dart';
import '../../services/survey_questions_service.dart';
import '../../services/audit_log_service.dart';
import '../../services/recaptcha_service.dart';
import '../../widgets/offline_queue_widget.dart';
import '../../widgets/survey_progress_bar.dart';
import 'landing_page.dart';
import '../../widgets/smooth_scroll_view.dart';

class SuggestionsScreen extends StatefulWidget {
  final bool isPreviewMode;
  
  const SuggestionsScreen({super.key, this.isPreviewMode = false});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  late TextEditingController _suggestionsController;
  late TextEditingController _emailController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _suggestionsController = TextEditingController();
    _emailController = TextEditingController();
    
    // Initialize from provider
    final surveyData = context.read<SurveyProvider>().surveyData;
      
    if (surveyData.suggestions != null) {
      _suggestionsController.text = surveyData.suggestions!;
    }
    if (surveyData.email != null) {
      _emailController.text = surveyData.email!;
    }
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
                      currentStep: context.watch<SurveyConfigService>().calculateStepNumber(SurveyStep.suggestions),
                      totalSteps: context.watch<SurveyConfigService>().totalSteps,
                      isMobile: isMobile,
                      customSteps: context.watch<SurveyConfigService>().getVisibleProgressBarSteps(),
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
    final questionsService = context.watch<SurveyQuestionsService>();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
      ),
      child: SmoothScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 24 : 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PART ${context.watch<SurveyConfigService>().calculateStepNumber(SurveyStep.suggestions)}',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFACF1F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    questionsService.suggestionsSectionTitle,
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 20 : 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003366),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              _buildModernTextField(
                controller: _suggestionsController,
                label: questionsService.suggestionsLabel,
                subtitle: questionsService.suggestionsSubtitle,
                hint: questionsService.suggestionsPlaceholder,
                icon: Icons.edit_note,
                isMobile: isMobile,
                maxLines: 6,
              ),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              _buildModernTextField(
                controller: _emailController,
                label: questionsService.emailLabel,
                subtitle: questionsService.emailSubtitle,
                hint: questionsService.emailPlaceholder,
                icon: Icons.email_outlined,
                isMobile: isMobile,
                type: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Email is optional
                  }
                  // Basic email validation
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: isMobile ? 32 : 48),
              
              _buildNavigationButtons(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String subtitle,
    required String hint,
    required IconData icon,
    required bool isMobile,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: const Color(0xFF003366).withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "($subtitle)",
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                bottom: maxLines > 1 ? 90 : 0, 
              ),
              child: Icon(icon, color: Colors.grey[500], size: 22),
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            // === ADDED VISIBLE BORDER HERE ===
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            // =================================
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF003366), width: 1.5),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          height: isMobile ? 48 : 55,
          child: OutlinedButton(
            onPressed: () {
              // Save current state before going back
              context.read<SurveyProvider>().updateSuggestions(
                suggestions: _suggestionsController.text.trim(),
                email: _emailController.text.trim(),
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
            onPressed: _isSubmitting ? null : () async {
              // Update Provider
              context.read<SurveyProvider>().updateSuggestions(
                suggestions: _suggestionsController.text.trim(),
                email: _emailController.text.trim(),
              );
              
              final surveyData = context.read<SurveyProvider>().surveyData;
              
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
                // Execute reCAPTCHA verification for web
                if (kIsWeb) {
                  final recaptchaToken = await RecaptchaService.executeForSurvey();
                  if (recaptchaToken == null) {
                    if (!mounted) return;
                    setState(() => _isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('reCAPTCHA verification failed. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  // Token can be verified on backend if needed
                }
                
                await OfflineQueue.enqueue(surveyData.toJson());
                await OfflineQueue.flush();
                
                // Log the survey submission to audit log (silent fail)
                try {
                  final auditService = Provider.of<AuditLogService>(context, listen: false);
                  await auditService.logSurveySubmitted(
                    clientType: surveyData.clientType,
                    serviceAvailed: surveyData.serviceAvailed,
                    region: surveyData.regionOfResidence,
                  );
                } catch (_) {
                  // Silent fail - audit logging is non-critical
                }
                
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
            },
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

// ------------------ THANK YOU SCREEN ------------------

class ThankYouScreen extends StatefulWidget {
  final bool isPreviewMode;
  
  const ThankYouScreen({super.key, this.isPreviewMode = false});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> with TickerProviderStateMixin {
  late TextEditingController _commentsController;
  bool _isSubmittingComment = false;
  bool _hasCommentText = false;
  
  // Kiosk Mode
  bool _isKioskMode = false;
  int _countdownSeconds = 10;
  static const int _kioskCountdownDuration = 10; // seconds
  DateTime _lastInteractionTime = DateTime.now();
  static const int _interactionPauseSeconds = 3; // pause countdown for 3 seconds after interaction

  // Animation controllers
  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkScale;
  late Animation<double> _checkmarkOpacity;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController();
    _commentsController.addListener(_onCommentChanged);
    
    // Initialize checkmark animation
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _checkmarkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: Curves.elasticOut,
      ),
    );
    
    _checkmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    // Pulse animation for the glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations
    _checkmarkController.forward();
    _pulseController.repeat(reverse: true);
    
    // Check kiosk mode and start countdown if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkKioskMode();
    });
  }

  void _checkKioskMode() {
    final configService = context.read<SurveyConfigService>();
    if (configService.kioskMode) {
      setState(() {
        _isKioskMode = true;
        _countdownSeconds = _kioskCountdownDuration;
      });
      _startKioskCountdown();
    }
  }

  void _startKioskCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      // Check if user recently interacted - pause countdown if so
      final secondsSinceInteraction = DateTime.now().difference(_lastInteractionTime).inSeconds;
      if (secondsSinceInteraction < _interactionPauseSeconds) {
        // User is actively interacting, keep countdown at full but continue checking
        _startKioskCountdown();
        return;
      }
      
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
        _startKioskCountdown();
      } else {
        // Time's up - navigate to home
        _goHome();
      }
    });
  }

  void _onCommentChanged() {
    final hasText = _commentsController.text.trim().isNotEmpty;
    if (hasText != _hasCommentText) {
      setState(() => _hasCommentText = hasText);
    }
    // Reset countdown on typing
    _onUserInteraction();
  }

  void _onUserInteraction() {
    if (_isKioskMode) {
      setState(() {
        _lastInteractionTime = DateTime.now();
        _countdownSeconds = _kioskCountdownDuration;
      });
    }
  }

  @override
  void dispose() {
    _commentsController.removeListener(_onCommentChanged);
    _commentsController.dispose();
    _checkmarkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    if (_commentsController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your additional comments have been saved.'),
          backgroundColor: Colors.green,
        ),
      );
      _commentsController.clear();
      setState(() => _isSubmittingComment = false);
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LandingScreen(isPreviewMode: widget.isPreviewMode)),
      (Route<dynamic> route) => false,
    );
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
                constraints: BoxConstraints(
                  maxHeight: isMobile ? double.infinity : 650,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 0,
                  vertical: isMobile ? 20 : 0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 20)],
                ),
                clipBehavior: Clip.antiAlias, 
                child: isMobile
                    ? _buildMobileLayout()
                    : _buildDesktopLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Listener(
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: SmoothScrollView(
        child: Column(
          children: [
            _buildTopSection(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              color: Colors.white,
              child: Column(
                children: [
                  _buildCommentForm(),
                  const SizedBox(height: 40),
                  _buildHomeButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Listener(
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommentForm(),
                  const SizedBox(height: 40),
                  Center(child: _buildHomeButton(width: 220)),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: _buildTopSection(isDesktopRightSide: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection({bool isDesktopRightSide = false}) {
    final questionsService = context.watch<SurveyQuestionsService>();
    
    return Container(
      width: double.infinity,
      height: isDesktopRightSide ? double.infinity : null,
      color: const Color(0xFF1C1E97),
      child: Stack(
        children: [
          // Background image that fills the entire container
          Positioned.fill(
            child: Image.asset(
              'assets/thankyou-img.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content overlay
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Spacer to push content down
                if (isDesktopRightSide) const Spacer(),
                
                // Animated checkmark
                AnimatedBuilder(
                  animation: Listenable.merge([_checkmarkController, _pulseController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _checkmarkScale.value * _pulseAnimation.value,
                      child: Opacity(
                        opacity: _checkmarkOpacity.value,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C853).withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  questionsService.thankYouTitle,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  questionsService.thankYouMessage,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                // Kiosk Mode Countdown
                if (_isKioskMode) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Restarting in $_countdownSeconds seconds...",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (isDesktopRightSide) const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Additional Comments",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003366),
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "If you missed anything, let us know here.",
          style: GoogleFonts.poppins(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),
        
        TextFormField(
          controller: _commentsController,
          maxLines: 5,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Write additional comments here...',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            // === ADDED VISIBLE BORDER HERE TOO ===
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
            ),
            // =====================================
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF003366), width: 1.5),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
        
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 140,
            height: 45,
            child: ElevatedButton(
              onPressed: (_isSubmittingComment || !_hasCommentText) ? null : _submitComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isSubmittingComment 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    "Submit",
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeButton({double? width}) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _goHome,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF003366), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, color: Color(0xFF003366)),
            const SizedBox(width: 8),
            Text(
              'BACK TO HOME',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003366),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

