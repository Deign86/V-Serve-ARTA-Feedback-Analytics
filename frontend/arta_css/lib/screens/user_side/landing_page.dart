import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_profile.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // --- ARTA Text Animation Controllers ---
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  Timer? _hoverTimer; 

  // --- Button Hover State ---
  bool _isHoveringButton = false;

  final List<String> _carouselImages = [
    'assets/nai_1.jpg',
    'assets/nai_2.jpg',
    'assets/nai_3.png',
  ];

  @override
  void initState() {
    super.initState();
    
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
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && mounted) {
        int nextPage = (_currentPage + 1) % _carouselImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
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
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const UserProfileScreen())
                      );
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
            child: PageView.builder(
              controller: _pageController,
              itemCount: _carouselImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  _carouselImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _carouselImages.length,
                (index) => _buildDot(index == _currentPage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isActive ? 16 : 10,
      height: isActive ? 16 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF003366) : Colors.white.withValues(alpha: 0.8),
        boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
      ),
    );
  }
}


