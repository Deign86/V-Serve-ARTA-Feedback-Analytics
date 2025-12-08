import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_profile.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

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
    // We set a specific width for the FittedBox to calculate aspect ratio against
    return SizedBox(
      width: 1300, // Ideal width
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side (Text + Button)
            Expanded(
              flex: 3,
              child: _buildTextCard(context, false),
            ),
            const SizedBox(width: 60),
            // Right side (Carousel)
            Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: _buildImageCarousel(false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ TEXT CARD ------------------
  Widget _buildTextCard(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 50),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Logo & Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: isMobile ? 24 : 36,
                backgroundImage: const AssetImage('assets/city_logo.png'),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CITY GOVERNMENT OF VALENZUELA",
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 14 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003366),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      "HELP US SERVE YOU BETTER!",
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 30 : 50),
          
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "ARTA",
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 48 : 90,
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
                        fontSize: isMobile ? 18 : 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF003366),
                      ),
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            "CLIENT SATISFACTION FORM",
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 1.5,
            ),
          ),
          
          SizedBox(height: isMobile ? 16 : 24),
          
          Text(
            "We want to hear about your recently concluded transaction with us. "
            "Your feedback is valuable to improve our service.",
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 18,
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
          
          SizedBox(height: isMobile ? 30 : 50),
          
          // --- TAKE SURVEY BUTTON (With Hover Animation) ---
          Align(
            alignment: isMobile ? Alignment.center : Alignment.centerRight,
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
                        SmoothPageRoute(page: const UserProfileScreen())
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
  Widget _buildImageCarousel(bool isMobile) {
    return Container(
      height: isMobile ? 250 : null, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(blurRadius: 15, color: Colors.black26)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PageView.builder(
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
        color: isActive ? const Color(0xFF003366) : Colors.white.withOpacity(0.8),
        boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
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