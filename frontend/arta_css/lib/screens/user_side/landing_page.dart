import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/survey_config_service.dart';
import 'user_profile.dart';
import '../../widgets/smooth_scroll_view.dart';

class LandingScreen extends StatefulWidget {
  final bool isPreviewMode;
  
  const LandingScreen({super.key, this.isPreviewMode = false});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  
  // --- ARTA Text Animation Controllers ---
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  Timer? _hoverTimer; 

  // --- Button Hover State ---
  bool _isHoveringButton = false;

  final List<String> _carouselImages = [
    'assets/bg1.png',
    'assets/bg2.png',
    'assets/bg3.png',
  ];

  @override
  void initState() {
    super.initState();
    
    // Preload survey configuration from cache for instant access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SurveyConfigService>();
      }
    });
    
    // Precache carousel images for smooth loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        for (final imagePath in _carouselImages) {
          precacheImage(AssetImage(imagePath), context);
        }
        // Precache background image
        precacheImage(const AssetImage('assets/city_bg2.png'), context);
      }
    });
    
    // Initialize ARTA Text Animation
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.fastOutSlowIn,
    );

    // Auto-slide carousel
    // Auto-slide carousel
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentPage = (_currentPage + 1) % _carouselImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _expandController.dispose();
    _hoverTimer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fixed Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/city_bg2.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Content
          Positioned.fill(
            child: SafeArea(
              child: isMobile 
                ? SmoothScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: _buildMobileLayout(context),
                  )
                : Center(
                    // === DESKTOP RESPONSIVE FIX ===
                    // This ensures that if the screen is zoomed (125%), 
                    // the content scales down to fit instead of scrolling.
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _buildDesktopLayout(context),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ PRIVACY DIALOG ------------------
  void _showPrivacyDialog(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 600 ? 450.0 : size.width * 0.9;
    
    // Capture the navigator before opening dialog to ensure we use the correct navigator
    // (important for nested navigators like in Mobile Preview)
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003366),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Data Privacy Notice",
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Republic Act No. 10173 - Data Privacy Act of 2012",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "In accordance with the Data Privacy Act of 2012 (Republic Act No. 10173), I hereby consent to the collection, processing, and storage of my personal data by the City Government of Valenzuela for the purpose of the ARTA Feedback Analytics System.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "I understand that:",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPrivacyPoint(
                          "Collection",
                          "My personal information is collected to verify my identity and validate my feedback on government services.",
                        ),
                        const SizedBox(height: 10),
                        _buildPrivacyPoint(
                          "Usage",
                          "The data will be used solely for service improvement, analytics, and legitimate government concerns in compliance with ARTA regulations.",
                        ),
                        const SizedBox(height: 10),
                        _buildPrivacyPoint(
                          "Protection",
                          "My data will be kept confidential and secured against unauthorized access, disclosure, or misuse through appropriate technical and organizational measures.",
                        ),
                        const SizedBox(height: 10),
                        _buildPrivacyPoint(
                          "Rights",
                          "I have the right to access, correct, or request the deletion of my data, subject to legal limitations and retention requirements.",
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "By proceeding, I confirm that I have read and understood this privacy notice and voluntarily submit my information.",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Buttons at the bottom of scrollable content
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              child: Text(
                                "I Disagree",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003366),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(dialogContext).pop(); // Close dialog
                                navigator.push(
                                  MaterialPageRoute(builder: (_) => UserProfileScreen(isPreviewMode: widget.isPreviewMode)),
                                );
                              },
                              child: Text(
                                "I Agree",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildPrivacyPoint(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF003366),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------ MOBILE LAYOUT ------------------
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildImageCarousel(true),
        const SizedBox(height: 20),
        _buildTextCard(context, true),
      ],
    );
  }

  // ------------------ DESKTOP LAYOUT ------------------
  Widget _buildDesktopLayout(BuildContext context) {
    // New Split-Card Layout
    return Container(
      width: 1200,
      constraints: const BoxConstraints(minHeight: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
      ),
      clipBehavior: Clip.antiAlias, // Clips content to rounded corners
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side (Text + Button)
            Expanded(
              flex: 5,
              child: _buildTextCard(context, false, withCardDecoration: false),
            ),
            
            // Right side (Carousel)
            Expanded(
              flex: 4,
              child: Container(
                 color: const Color(0xFF003366), // Fallback/Basic background
                 child: _buildImageCarousel(false, withCardDecoration: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ TEXT CARD ------------------
  Widget _buildTextCard(BuildContext context, bool isMobile, {bool withCardDecoration = true}) {
    // If we want card decoration, we use the white container style.
    // If not (merged layout), we just use transparent or minimal styling.
    
    // Desktop in new layout has no internal decoration, just padding.
    // Mobile keeps the card look.
    
    final decoration = withCardDecoration 
      ? BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [BoxShadow(blurRadius: 18, color: Colors.black12)],
        )
      : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40), // Reduced padding to prevent clipping
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically in split view
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Logo & Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Long-press on logo to access admin login
              GestureDetector(
                onLongPress: () {
                  Navigator.pushNamed(context, '/admin/login');
                },
                child: CircleAvatar(
                  radius: isMobile ? 24 : 32,
                  backgroundImage: const AssetImage('assets/city_logo.png'),
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CITY GOVERNMENT OF VALENZUELA",
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 14 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003366),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      "HELP US SERVE YOU BETTER!",
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 30 : 60),

          // --- HOVER ANIMATION FOR ARTA ---
          MouseRegion(
            onEnter: (_) {
              _hoverTimer?.cancel();
              _expandController.forward();
            },
            onExit: (_) {
              _hoverTimer = Timer(const Duration(milliseconds: 600), () {
                 if (mounted) {
                   _expandController.reverse();
                 }
              });
            },
            cursor: SystemMouseCursors.click,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "ARTA",
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 48 : 80,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003366),
                      height: 1.0,
                    ),
                  ),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    axis: Axis.horizontal,
                    axisAlignment: -1.0, 
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        "| Anti-Red Tape Authority",
                        style: GoogleFonts.montserrat(
                          fontSize: isMobile ? 16 : 24,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF003366),
                        ),
                        softWrap: false,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Text(
            "CLIENT SATISFACTION FORM",
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 1.5,
            ),
          ),
          
          SizedBox(height: isMobile ? 16 : 30),
          
          Text(
            "We want to hear about your recently concluded transaction with us. "
            "Your feedback is valuable to improve our service.",
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
          
          SizedBox(height: isMobile ? 30 : 60),
          
          // --- TAKE SURVEY BUTTON ---
          Align(
            alignment: isMobile ? Alignment.center : Alignment.centerLeft,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHoveringButton = true),
              onExit: (_) => setState(() => _isHoveringButton = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedScale(
                scale: _isHoveringButton ? 1.05 : 1.0, 
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: SizedBox(
                  width: isMobile ? double.infinity : 220,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isHoveringButton 
                          ? const Color(0xFF004C99) 
                          : const Color(0xFF003366),
                      elevation: _isHoveringButton ? 10 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      _showPrivacyDialog(context);
                    },
                    child: Text(
                      "TAKE SURVEY",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ IMAGE CAROUSEL ------------------
  Widget _buildImageCarousel(bool isMobile, {bool withCardDecoration = true}) {
    final decoration = withCardDecoration
      ? BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [BoxShadow(blurRadius: 15, color: Colors.black26)],
        )
      : null;

    return Container(
      height: isMobile ? 250 : null, 
      decoration: decoration,
      clipBehavior: withCardDecoration ? Clip.antiAlias : Clip.none,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.asset(
                _carouselImages[_currentPage],
                key: ValueKey<String>(_carouselImages[_currentPage]),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }

}


