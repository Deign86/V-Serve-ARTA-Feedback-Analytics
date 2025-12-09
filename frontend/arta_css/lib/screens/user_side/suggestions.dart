import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/survey_data.dart';
import '../../services/offline_queue.dart';
import 'landing_page.dart';

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
                    _buildProgressBar(isMobile, 4, 4),
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                    'SUGGESTIONS',
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
                label: 'SUGGESTIONS',
                subtitle: 'How can we further improve our services?',
                hint: 'Write your suggestions here...',
                icon: Icons.edit_note,
                isMobile: isMobile,
                maxLines: 6,
              ),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              _buildModernTextField(
                controller: _emailController,
                label: 'EMAIL ADDRESS',
                subtitle: 'Optional - for feedback replies',
                hint: 'Enter your email address...',
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
            onPressed: _isSubmitting ? null : () async {
              final finalData = widget.surveyData.copyWith(
                suggestions: _suggestionsController.text.trim().isEmpty 
                    ? null 
                    : _suggestionsController.text.trim(),
                email: _emailController.text.trim().isEmpty 
                    ? null 
                    : _emailController.text.trim(),
              );
              
              setState(() => _isSubmitting = true);
              
              try {
                await OfflineQueue.enqueue(finalData.toJson());
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
  const ThankYouScreen({super.key});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  late TextEditingController _commentsController;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController();
  }

  @override
  void dispose() {
    _commentsController.dispose();
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
      SmoothPageRoute(page: const LandingScreen()),
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
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
          child: _buildTopSection(isDesktopRightSide: true),
        ),
      ],
    );
  }

  Widget _buildTopSection({bool isDesktopRightSide = false}) {
    return Container(
      width: double.infinity,
      height: isDesktopRightSide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      color: const Color(0xFF1C1E97),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 80),
          const SizedBox(height: 24),
          Text(
            "THANK YOU",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "FOR YOUR FEEDBACK!",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
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
              onPressed: _isSubmittingComment ? null : _submitComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
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

// === SMOOTH PAGE ROUTE HELPER ===
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