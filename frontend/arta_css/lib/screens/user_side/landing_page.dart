import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_profile.dart'; // Make sure this matches your file name

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
  Timer? _hoverTimer; // Delay timer for ARTA text

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
          
          // 2. Scrollable Content on Top
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 40,
                    vertical: isMobile ? 20 : 40,
                  ),
                  child: isMobile 
                      ? _buildMobileLayout(context) 
                      : _buildDesktopLayout(context),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1430),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side (Text + Button)
            Expanded(
              flex: 3,
              child: _buildTextCard(context, false),
            ),
            const SizedBox(width: 40),
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
          
          // --- HOVER ANIMATION FOR ARTA (Delay + Smooth Slide) ---
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
                scale: _isHoveringButton ? 1.05 : 1.0, // Scale up 5%
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack, // A little bounce effect
                child: SizedBox(
                  width: isMobile ? double.infinity : 220,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // Animate Color from Deep Blue to Lighter Blue
                      backgroundColor: _isHoveringButton 
                          ? const Color(0xFF004C99) 
                          : const Color(0xFF003366),
                      elevation: _isHoveringButton ? 10 : 5, // Lift effect
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      // OLD: Navigator.pushNamed(context, '/profile');
  
                      // NEW: Smooth Custom Transition
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

// === ADD THIS CLASS AT THE BOTTOM OF THE FILE ===

class SmoothPageRoute extends PageRouteBuilder {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 1. Define the slide (From Right to Left)
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            
            // 2. Define the curve (Smooth, luxurious feel)
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            // 3. Combine Slide + Fade for extra smoothness
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation, 
                child: child
              ),
            );
          },
          // 4. Match the speed of your other animations
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 600),
        );
}